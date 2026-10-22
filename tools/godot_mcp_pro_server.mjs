#!/usr/bin/env node
/**
 * Godot MCP Pro — Node.js WebSocket MCP Server & CLI Bridge
 * Connects AI Assistants (via MCP stdio) and CLI directly to the Godot MCP Pro Editor Plugin
 * over WebSocket ports 6505-6509 (MCP) and 6510-6514 (CLI).
 */

import http from "node:http";
import crypto from "node:crypto";
import readline from "node:readline";

const WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
const MCP_BASE_PORT = parseInt(process.env.GODOT_MCP_PORT || "6505", 10);
const MCP_MAX_PORT = 6509;
const CLI_BASE_PORT = 6510;
const CLI_MAX_PORT = 6514;

// Parse RFC 6455 WebSocket frames from buffer
function parseWsFrames(buffer) {
  const frames = [];
  let offset = 0;

  while (offset + 2 <= buffer.length) {
    const byte0 = buffer[offset];
    const byte1 = buffer[offset + 1];
    const fin = (byte0 & 0x80) !== 0;
    const opcode = byte0 & 0x0f;
    const masked = (byte1 & 0x80) !== 0;
    let payloadLen = byte1 & 0x7f;
    let headerLen = 2;

    if (payloadLen === 126) {
      if (offset + 4 > buffer.length) break;
      payloadLen = buffer.readUInt16BE(offset + 2);
      headerLen = 4;
    } else if (payloadLen === 127) {
      if (offset + 10 > buffer.length) break;
      payloadLen = Number(buffer.readBigUInt64BE(offset + 2));
      headerLen = 10;
    }

    const maskLen = masked ? 4 : 0;
    const totalFrameLen = headerLen + maskLen + payloadLen;
    if (offset + totalFrameLen > buffer.length) break;

    let payload = Buffer.from(
      buffer.subarray(offset + headerLen + maskLen, offset + totalFrameLen)
    );
    if (masked) {
      const maskKey = buffer.subarray(offset + headerLen, offset + headerLen + 4);
      for (let i = 0; i < payload.length; i++) {
        payload[i] ^= maskKey[i & 3];
      }
    }

    frames.push({ fin, opcode, payload });
    offset += totalFrameLen;
  }

  return { frames, remaining: buffer.subarray(offset) };
}

// Encode RFC 6455 WebSocket frame (server -> client, unmasked)
function encodeWsFrame(opcode, payloadBuffer) {
  const len = payloadBuffer.length;
  let header;
  if (len < 126) {
    header = Buffer.alloc(2);
    header[0] = 0x80 | opcode;
    header[1] = len;
  } else if (len < 65536) {
    header = Buffer.alloc(4);
    header[0] = 0x80 | opcode;
    header[1] = 126;
    header.writeUInt16BE(len, 2);
  } else {
    header = Buffer.alloc(10);
    header[0] = 0x80 | opcode;
    header[1] = 127;
    header.writeBigUInt64BE(BigInt(len), 2);
  }
  return Buffer.concat([header, payloadBuffer]);
}

class GodotWebSocketBridge {
  constructor(basePort, maxPort) {
    this.basePort = basePort;
    this.maxPort = maxPort;
    this.port = null;
    this.server = null;
    this.clients = new Set();
    this.nextRpcId = 1;
    this.pending = new Map(); // id -> { resolve, reject, timer }
    this.waiters = []; // functions waiting for first client connection
    this.heartbeatInterval = null;
  }

  async start() {
    for (let p = this.basePort; p <= this.maxPort; p++) {
      try {
        await this._listenOnPort(p);
        this.port = p;
        break;
      } catch (err) {
        if (p === this.maxPort) {
          throw new Error(`No available port in range ${this.basePort}-${this.maxPort}: ${err.message}`);
        }
      }
    }

    this.heartbeatInterval = setInterval(() => {
      this.broadcastJson({ jsonrpc: "2.0", method: "ping", params: {} });
    }, 10000);
    if (this.heartbeatInterval.unref) this.heartbeatInterval.unref();

    return this.port;
  }

  _listenOnPort(port) {
    return new Promise((resolve, reject) => {
      const srv = http.createServer(async (req, res) => {
        if (req.method === "GET" && req.url === "/status") {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ ok: true, port: this.port, connectedClients: this.clients.size }));
          return;
        }
        if (req.method === "POST" && req.url === "/rpc") {
          let body = "";
          req.on("data", (c) => (body += c));
          req.on("end", async () => {
            try {
              const { method, params, timeoutMs } = JSON.parse(body || "{}");
              const result = await this.callGodot(method, params || {}, timeoutMs || 15000);
              res.writeHead(200, { "Content-Type": "application/json" });
              res.end(JSON.stringify({ ok: true, result }));
            } catch (err) {
              res.writeHead(200, { "Content-Type": "application/json" });
              res.end(JSON.stringify({ ok: false, error: err }));
            }
          });
          return;
        }
        res.writeHead(404);
        res.end();
      });

      srv.on("upgrade", (req, socket, head) => {
        const key = req.headers["sec-websocket-key"];
        if (!key) {
          socket.destroy();
          return;
        }
        const accept = crypto.createHash("sha1").update(key + WS_GUID).digest("base64");
        socket.write(
          "HTTP/1.1 101 Switching Protocols\r\n" +
            "Upgrade: websocket\r\n" +
            "Connection: Upgrade\r\n" +
            `Sec-WebSocket-Accept: ${accept}\r\n\r\n`
        );
        socket.setNoDelay(true);
        this._attachClient(socket, head);
      });

      const onError = (err) => {
        srv.close();
        reject(err);
      };
      srv.once("error", onError);

      srv.listen(port, "127.0.0.1", () => {
        srv.removeListener("error", onError);
        this.server = srv;
        resolve(port);
      });
    });
  }

  _attachClient(socket, head) {
    const client = {
      socket,
      buffer: head && head.length > 0 ? Buffer.from(head) : Buffer.alloc(0),
      fragments: [],
    };
    this.clients.add(client);

    while (this.waiters.length > 0) {
      const w = this.waiters.shift();
      w();
    }

    const processBuffer = () => {
      const { frames, remaining } = parseWsFrames(client.buffer);
      client.buffer = remaining;
      for (const frame of frames) {
        if (frame.opcode === 0x8) {
          // Close
          try {
            socket.write(encodeWsFrame(0x8, Buffer.alloc(0)));
          } catch {}
          socket.end();
          return;
        } else if (frame.opcode === 0x9) {
          // Ping -> Pong
          try {
            socket.write(encodeWsFrame(0xA, frame.payload));
          } catch {}
        } else if (frame.opcode === 0xA) {
          // Pong
        } else if (frame.opcode === 0x1 || frame.opcode === 0x0) {
          client.fragments.push(frame.payload);
          if (frame.fin) {
            const fullPayload = Buffer.concat(client.fragments).toString("utf8");
            client.fragments = [];
            this._onClientMessage(client, fullPayload);
          }
        }
      }
    };

    if (client.buffer.length > 0) {
      processBuffer();
    }

    socket.on("data", (chunk) => {
      client.buffer = Buffer.concat([client.buffer, chunk]);
      processBuffer();
    });

    const cleanup = () => {
      this.clients.delete(client);
    };
    socket.on("close", cleanup);
    socket.on("error", cleanup);
  }

  _onClientMessage(client, text) {
    let msg;
    try {
      msg = JSON.parse(text);
    } catch {
      return;
    }

    if (msg.method === "ping") {
      if (msg.id !== undefined && msg.id !== null) {
        this._sendJson(client, { jsonrpc: "2.0", id: msg.id, result: { pong: true } });
      } else {
        this._sendJson(client, { jsonrpc: "2.0", method: "pong", params: {} });
      }
      return;
    }

    if (msg.method === "pong") {
      return;
    }

    if (msg.id !== undefined && msg.id !== null && this.pending.has(msg.id)) {
      const entry = this.pending.get(msg.id);
      this.pending.delete(msg.id);
      clearTimeout(entry.timer);
      if (msg.error) {
        entry.reject(msg.error);
      } else {
        entry.resolve(msg.result);
      }
    }
  }

  _sendJson(client, obj) {
    try {
      const buf = Buffer.from(JSON.stringify(obj), "utf8");
      client.socket.write(encodeWsFrame(0x1, buf));
      return true;
    } catch {
      return false;
    }
  }

  broadcastJson(obj) {
    for (const client of this.clients) {
      this._sendJson(client, obj);
    }
  }

  async waitForConnection(timeoutMs = 6000) {
    if (this.clients.size > 0) return true;
    return new Promise((resolve) => {
      const timer = setTimeout(() => {
        const idx = this.waiters.indexOf(onConnect);
        if (idx !== -1) this.waiters.splice(idx, 1);
        resolve(false);
      }, timeoutMs);
      const onConnect = () => {
        clearTimeout(timer);
        resolve(true);
      };
      this.waiters.push(onConnect);
    });
  }

  async callGodot(method, params = {}, timeoutMs = 15000) {
    if (this.clients.size === 0) {
      const connected = await this.waitForConnection(4500);
      if (!connected || this.clients.size === 0) {
        throw {
          code: -32000,
          message:
            `Godot Editor is not connected to MCP Pro WebSocket (port ${this.port}). ` +
            `Please open the project in Godot Editor with the 'Godot MCP Pro' plugin enabled.`,
        };
      }
    }

    const client = this.clients.values().next().value;
    const id = this.nextRpcId++;

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject({
          code: -32002,
          message: `Timeout waiting for Godot Editor response to '${method}' (${timeoutMs}ms)`,
        });
      }, timeoutMs);

      this.pending.set(id, { resolve, reject, timer });
      const sent = this._sendJson(client, {
        jsonrpc: "2.0",
        id,
        method,
        params: params || {},
      });
      if (!sent) {
        clearTimeout(timer);
        this.pending.delete(id);
        reject({ code: -32003, message: `Failed to send '${method}' to Godot Editor` });
      }
    });
  }

  stop() {
    if (this.heartbeatInterval) clearInterval(this.heartbeatInterval);
    for (const client of this.clients) {
      try {
        client.socket.destroy();
      } catch {}
    }
    this.clients.clear();
    if (this.server) {
      this.server.close();
    }
  }
}

// Tool Definitions for Godot MCP Pro (Lite/UI-focused set + generic command runner)
const TOOLS = [
  // Project Tools
  {
    name: "get_project_info",
    description: "Get project metadata, Godot version, viewport size, and autoloads",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_filesystem_tree",
    description: "Get recursive file tree of the Godot project with optional filtering",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string", description: "Base directory (default res://)" },
        filter: { type: "string", description: "Glob filter e.g. *.tscn or *.gd" },
        max_depth: { type: "integer", description: "Max recursion depth" },
      },
    },
  },
  {
    name: "search_files",
    description: "Fuzzy/glob file search in project",
    inputSchema: {
      type: "object",
      properties: { query: { type: "string" }, file_type: { type: "string" } },
      required: ["query"],
    },
  },
  {
    name: "search_in_files",
    description: "Search content in project files",
    inputSchema: {
      type: "object",
      properties: { query: { type: "string" }, file_pattern: { type: "string" } },
      required: ["query"],
    },
  },
  {
    name: "get_project_settings",
    description: "Read project.godot settings",
    inputSchema: {
      type: "object",
      properties: { section: { type: "string" }, key: { type: "string" } },
    },
  },
  {
    name: "set_project_setting",
    description: "Set a project setting via Godot Editor API",
    inputSchema: {
      type: "object",
      properties: { key: { type: "string" }, value: { type: "string" } },
      required: ["key", "value"],
    },
  },

  // Scene Tools
  {
    name: "get_scene_tree",
    description: "Get live scene tree hierarchy of the currently open scene in Godot Editor",
    inputSchema: {
      type: "object",
      properties: { max_depth: { type: "integer" } },
    },
  },
  {
    name: "get_scene_file_content",
    description: "Read raw .tscn file content",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"],
    },
  },
  {
    name: "create_scene",
    description: "Create a new scene file (.tscn)",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        root_type: { type: "string" },
        root_name: { type: "string" },
        force: { type: "boolean" },
      },
      required: ["path"],
    },
  },
  {
    name: "open_scene",
    description: "Open a scene file in the Godot Editor",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"],
    },
  },
  {
    name: "save_scene",
    description: "Save the currently open scene to disk",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
    },
  },
  {
    name: "play_scene",
    description: "Run scene in Godot (mode: 'main', 'current', or custom scene path)",
    inputSchema: {
      type: "object",
      properties: { mode: { type: "string" }, scene_path: { type: "string" } },
    },
  },
  {
    name: "stop_scene",
    description: "Stop the currently running scene in Godot",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "add_scene_instance",
    description: "Instance a scene (.tscn) as a child node in the current scene",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string" },
        parent_path: { type: "string" },
        name: { type: "string" },
      },
      required: ["scene_path"],
    },
  },
  {
    name: "get_scene_exports",
    description: "List @export variables of all scripted nodes in a scene file",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
    },
  },

  // Node Tools
  {
    name: "add_node",
    description: "Add a node with type and properties to the edited scene (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        type: { type: "string", description: "Godot class name or script class_name" },
        parent_path: { type: "string", description: "Parent node path (default '.')" },
        name: { type: "string", description: "Node name" },
        properties: { type: "object", description: "Initial property dictionary" },
      },
      required: ["type"],
    },
  },
  {
    name: "delete_node",
    description: "Delete a node from the edited scene (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" } },
      required: ["node_path"],
    },
  },
  {
    name: "duplicate_node",
    description: "Duplicate a node and its children",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" }, new_name: { type: "string" } },
      required: ["node_path"],
    },
  },
  {
    name: "move_node",
    description: "Move/reparent or reorder a node in the scene tree",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        new_parent_path: { type: "string" },
        index: { type: "integer" },
      },
      required: ["node_path"],
    },
  },
  {
    name: "rename_node",
    description: "Rename a node in the edited scene",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" }, new_name: { type: "string" } },
      required: ["node_path", "new_name"],
    },
  },
  {
    name: "update_property",
    description: "Set any property on a node in the edited scene (auto type parsing, UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        property: { type: "string" },
        value: { description: "Value to set (string, number, boolean, or Vector2/Color string)" },
      },
      required: ["node_path", "property", "value"],
    },
  },
  {
    name: "get_node_properties",
    description: "Get all inspector properties of a node in the edited scene",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        category_filter: { type: "string" },
      },
      required: ["node_path"],
    },
  },
  {
    name: "set_anchor_preset",
    description: "Set Control anchor preset (e.g. full_rect, center, top_wide)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        preset: { type: "string" },
        keep_offsets: { type: "boolean" },
      },
      required: ["node_path", "preset"],
    },
  },
  {
    name: "connect_signal",
    description: "Connect a signal between two nodes in the edited scene",
    inputSchema: {
      type: "object",
      properties: {
        source_path: { type: "string" },
        signal_name: { type: "string" },
        target_path: { type: "string" },
        method_name: { type: "string" },
      },
      required: ["source_path", "signal_name", "target_path", "method_name"],
    },
  },
  {
    name: "disconnect_signal",
    description: "Disconnect a signal connection between two nodes",
    inputSchema: {
      type: "object",
      properties: {
        source_path: { type: "string" },
        signal_name: { type: "string" },
        target_path: { type: "string" },
        method_name: { type: "string" },
      },
      required: ["source_path", "signal_name", "target_path", "method_name"],
    },
  },
  {
    name: "get_editor_selection",
    description: "Get nodes currently selected in the Godot Editor Scene dock",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "select_nodes",
    description: "Select and inspect nodes in the Godot Editor Scene dock / Inspector",
    inputSchema: {
      type: "object",
      properties: {
        node_paths: { type: "array", items: { type: "string" } },
        inspect: { type: "boolean" },
      },
      required: ["node_paths"],
    },
  },
  {
    name: "clear_editor_selection",
    description: "Clear the Scene dock selection",
    inputSchema: { type: "object", properties: {} },
  },

  // Theme & UI Tools
  {
    name: "set_theme_color",
    description: "Set a theme color override on a Control node",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        name: { type: "string" },
        color: { type: "string" },
      },
      required: ["node_path", "name", "color"],
    },
  },
  {
    name: "set_theme_constant",
    description: "Set a theme constant override on a Control node",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        name: { type: "string" },
        value: { type: "integer" },
      },
      required: ["node_path", "name", "value"],
    },
  },
  {
    name: "set_theme_font_size",
    description: "Set a theme font size override on a Control node",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        name: { type: "string" },
        font_size: { type: "integer" },
      },
      required: ["node_path", "name", "font_size"],
    },
  },
  {
    name: "set_theme_stylebox",
    description: "Configure a StyleBoxFlat override on a Control node (bg_color, corner_radius, border_width, content_margin, etc.)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        name: { type: "string" },
        bg_color: { type: "string" },
        border_color: { type: "string" },
        border_width: { type: "integer" },
        corner_radius: { type: "integer" },
        content_margin: { type: "integer" },
      },
      required: ["node_path", "name"],
    },
  },
  {
    name: "setup_control",
    description: "Configure Control/Container layout (anchors, size flags, custom_minimum_size, margins) in one call",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        anchor_preset: { type: "string" },
        custom_minimum_size: { type: "string" },
        size_flags_horizontal: { type: "integer" },
        size_flags_vertical: { type: "integer" },
      },
      required: ["node_path"],
    },
  },
  {
    name: "get_theme_info",
    description: "Get all theme overrides and resolved theme values of a Control node",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" } },
      required: ["node_path"],
    },
  },

  // Script Tools
  {
    name: "list_scripts",
    description: "List all scripts in the project with class info",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "read_script",
    description: "Read GDScript content",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"],
    },
  },
  {
    name: "create_script",
    description: "Create a new GDScript file",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" }, content: { type: "string" } },
      required: ["path", "content"],
    },
  },
  {
    name: "edit_script",
    description: "Edit an existing GDScript file",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        content: { type: "string" },
        replacements: { type: "array", items: { type: "object" } },
      },
      required: ["path"],
    },
  },
  {
    name: "attach_script",
    description: "Attach a script to a node in the edited scene",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" }, script_path: { type: "string" } },
      required: ["node_path", "script_path"],
    },
  },
  {
    name: "validate_script",
    description: "Validate GDScript syntax",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"],
    },
  },
  {
    name: "reload_open_scripts",
    description: "Reload open scripts from disk in Godot 4.7+",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_open_scripts",
    description: "List scripts currently open in the Godot Script Editor",
    inputSchema: { type: "object", properties: {} },
  },

  // Editor Tools
  {
    name: "get_editor_errors",
    description: "Get script errors, warnings, and stack traces from the Godot Editor",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_output_log",
    description: "Get the Godot Editor Output panel content",
    inputSchema: {
      type: "object",
      properties: { lines: { type: "integer" } },
    },
  },
  {
    name: "clear_output",
    description: "Clear the Godot Editor Output panel",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_editor_screenshot",
    description: "Capture a screenshot of the Godot Editor viewport",
    inputSchema: {
      type: "object",
      properties: { viewport: { type: "string", description: "'2d', '3d', or 'full'" } },
    },
  },
  {
    name: "get_game_screenshot",
    description: "Capture a screenshot of the running game",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "execute_editor_script",
    description: "Run arbitrary GDScript code inside the Godot Editor context",
    inputSchema: {
      type: "object",
      properties: { code: { type: "string" } },
      required: ["code"],
    },
  },
  {
    name: "get_signals",
    description: "Get all signals of a node along with active connections",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" } },
      required: ["node_path"],
    },
  },
  {
    name: "reload_project",
    description: "Rescan filesystem and reload scripts in the Godot Editor",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "reload_plugin",
    description: "Reload the Godot MCP Pro plugin",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_unsaved_state",
    description: "Report open scenes and scripts with unsaved changes",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "save_all",
    description: "Save all open scenes and modified script buffers",
    inputSchema: { type: "object", properties: {} },
  },

  // Runtime & Input Tools
  {
    name: "get_game_scene_tree",
    description: "Get scene tree of the currently running game",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_game_node_properties",
    description: "Get properties of a node in the running game",
    inputSchema: {
      type: "object",
      properties: { node_path: { type: "string" } },
      required: ["node_path"],
    },
  },
  {
    name: "set_game_node_property",
    description: "Set a property on a node in the running game",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string" },
        property: { type: "string" },
        value: {},
      },
      required: ["node_path", "property", "value"],
    },
  },
  {
    name: "execute_game_script",
    description: "Run GDScript in the running game context",
    inputSchema: {
      type: "object",
      properties: { code: { type: "string" } },
      required: ["code"],
    },
  },
  {
    name: "find_ui_elements",
    description: "Find visible UI elements in the running game",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "click_button_by_text",
    description: "Click a Button in the running game by its text label",
    inputSchema: {
      type: "object",
      properties: { text: { type: "string" } },
      required: ["text"],
    },
  },
  {
    name: "simulate_mouse_click",
    description: "Simulate mouse click at viewport position in the running game",
    inputSchema: {
      type: "object",
      properties: {
        x: { type: "number" },
        y: { type: "number" },
        button: { type: "string" },
      },
      required: ["x", "y"],
    },
  },
  {
    name: "simulate_key",
    description: "Simulate keyboard key press in the running game",
    inputSchema: {
      type: "object",
      properties: {
        key: { type: "string" },
        duration: { type: "number" },
      },
      required: ["key"],
    },
  },

  // Batch & Headless Tools
  {
    name: "batch_add_nodes",
    description: "Add an entire node tree hierarchy in one call",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: { type: "string" },
        nodes: { type: "array", items: { type: "object" } },
      },
      required: ["nodes"],
    },
  },
  {
    name: "batch_set_property",
    description: "Set a property across all nodes of a given type in the scene",
    inputSchema: {
      type: "object",
      properties: {
        node_type: { type: "string" },
        property: { type: "string" },
        value: {},
      },
      required: ["node_type", "property", "value"],
    },
  },
  {
    name: "run_headless_scene",
    description: "Run a scene in a separate headless Godot process",
    inputSchema: {
      type: "object",
      properties: { scene_path: { type: "string" }, timeout: { type: "number" } },
      required: ["scene_path"],
    },
  },
  {
    name: "run_headless_script",
    description: "Run an extends SceneTree script with godot --headless --script",
    inputSchema: {
      type: "object",
      properties: { script_path: { type: "string" }, timeout: { type: "number" } },
      required: ["script_path"],
    },
  },
  {
    name: "call_godot_command",
    description: "Call any of the 187 Godot MCP Pro editor commands by method name and params dictionary",
    inputSchema: {
      type: "object",
      properties: {
        method: { type: "string", description: "Any command registered in command_router.gd" },
        params: { type: "object", description: "Command parameters dictionary" },
      },
      required: ["method"],
    },
  },
];

async function tryHttpRpc(port, method, params) {
  return new Promise((resolve) => {
    const payload = Buffer.from(JSON.stringify({ method, params }), "utf8");
    const req = http.request(
      {
        hostname: "127.0.0.1",
        port,
        path: "/rpc",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": payload.length,
        },
        timeout: 15000,
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          try {
            resolve(JSON.parse(data));
          } catch {
            resolve(null);
          }
        });
      }
    );
    req.on("error", () => resolve(null));
    req.on("timeout", () => {
      req.destroy();
      resolve(null);
    });
    req.write(payload);
    req.end();
  });
}

async function runCliMode(args) {
  const method = args[0];
  if (!method || method === "--help" || method === "-h") {
    console.log("Usage: node tools/godot_mcp_pro_server.mjs --cli <method> [json_params]");
    console.log("Example: node tools/godot_mcp_pro_server.mjs --cli get_scene_tree '{}'");
    process.exit(0);
  }
  const rawJson = args.slice(1).join(" ").trim();
  const params = rawJson ? JSON.parse(rawJson) : {};

  // First try existing persistent server on 6505..6509 for instant 0ms response
  for (let p = MCP_BASE_PORT; p <= MCP_MAX_PORT; p++) {
    const fast = await tryHttpRpc(p, method, params);
    if (fast && fast.ok) {
      console.log(JSON.stringify(fast.result, null, 2));
      process.exit(0);
    }
  }

  const bridge = new GodotWebSocketBridge(CLI_BASE_PORT, CLI_MAX_PORT);
  await bridge.start();
  try {
    const connected = await bridge.waitForConnection(5000);
    if (!connected) {
      console.error(`Error: Godot Editor did not connect to CLI port ${bridge.port} within 5s.`);
      process.exit(1);
    }
    const result = await bridge.callGodot(method, params, 15000);
    console.log(JSON.stringify(result, null, 2));
    bridge.stop();
    process.exit(0);
  } catch (err) {
    console.error(JSON.stringify(err, null, 2));
    bridge.stop();
    process.exit(1);
  }
}

async function runDaemonMode() {
  const bridge = new GodotWebSocketBridge(MCP_BASE_PORT, MCP_MAX_PORT);
  const port = await bridge.start();
  console.log(`[Godot MCP Pro] Persistent WebSocket & HTTP Bridge listening on 127.0.0.1:${port}`);
}

async function runMcpServer() {
  const bridge = new GodotWebSocketBridge(MCP_BASE_PORT, MCP_MAX_PORT);
  await bridge.start();

  const sendMcp = (msg) => {
    process.stdout.write(JSON.stringify(msg) + "\n");
  };

  const rl = readline.createInterface({
    input: process.stdin,
    terminal: false,
  });

  rl.on("line", async (line) => {
    const trimmed = line.trim();
    if (!trimmed) return;
    let req;
    try {
      req = JSON.parse(trimmed);
    } catch {
      return;
    }

    const { id, method, params } = req;
    if (id === undefined || id === null) {
      // Notification (e.g. notifications/initialized)
      return;
    }

    if (method === "initialize") {
      sendMcp({
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion: (params && params.protocolVersion) || "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "godot-mcp-pro", version: "1.17.1" },
        },
      });
      return;
    }

    if (method === "ping") {
      sendMcp({ jsonrpc: "2.0", id, result: {} });
      return;
    }

    if (method === "tools/list") {
      sendMcp({
        jsonrpc: "2.0",
        id,
        result: { tools: TOOLS },
      });
      return;
    }

    if (method === "tools/call") {
      const toolName = params?.name;
      const toolArgs = params?.arguments || {};
      const actualMethod = toolName === "call_godot_command" ? toolArgs.method : toolName;
      const actualParams = toolName === "call_godot_command" ? toolArgs.params || {} : toolArgs;

      try {
        const res = await bridge.callGodot(actualMethod, actualParams, 20000);
        // If screenshot returned base64 image, format appropriately or return JSON
        if (res && typeof res === "object" && res.image_base64) {
          const { image_base64, ...meta } = res;
          sendMcp({
            jsonrpc: "2.0",
            id,
            result: {
              content: [
                { type: "text", text: JSON.stringify(meta, null, 2) },
                { type: "image", data: image_base64, mimeType: "image/png" },
              ],
            },
          });
        } else {
          sendMcp({
            jsonrpc: "2.0",
            id,
            result: {
              content: [{ type: "text", text: JSON.stringify(res, null, 2) }],
            },
          });
        }
      } catch (err) {
        sendMcp({
          jsonrpc: "2.0",
          id,
          result: {
            isError: true,
            content: [{ type: "text", text: JSON.stringify(err, null, 2) }],
          },
        });
      }
      return;
    }

    sendMcp({
      jsonrpc: "2.0",
      id,
      error: { code: -32601, message: `Method not found: ${method}` },
    });
  });

  rl.on("close", () => {
    bridge.stop();
    process.exit(0);
  });
}

const cliIdx = process.argv.indexOf("--cli");
if (cliIdx !== -1) {
  runCliMode(process.argv.slice(cliIdx + 1));
} else if (process.argv.includes("--daemon")) {
  runDaemonMode();
} else {
  runMcpServer();
}

from pathlib import Path
import json
import urllib.request

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parent.parent

def rpc(method,params=None):
    body=json.dumps({'method':method,'params':params or {},'timeoutMs':20000}).encode()
    req=urllib.request.Request('http://127.0.0.1:6505/rpc',body,{'Content-Type':'application/json'})
    with urllib.request.urlopen(req,timeout=25) as r:result=json.load(r)
    print(method,json.dumps(result,ensure_ascii=False))
    if not result.get('ok') or 'error' in result.get('result',{}):
        raise RuntimeError(result)
    return result

if __name__=='__main__':
    rpc('get_unsaved_state')
    rpc('reload_project')
    rpc('create_script',{'path':'res://app/iron_mine_card.gd','content':(ROOT/'iron_mine_card.gd').read_text(encoding='utf-8')})
    original=(PROJECT/'app/main.gd').read_bytes()
    backup=ROOT/'flowgame_main_before_mine_B.gd.bak'
    if not backup.exists():backup.write_bytes(original)
    rpc('edit_script',{'path':'res://app/main.gd','replacements':[
        {'search':'const MachineCardScene = preload("res://app/machine_card.tscn")',
         'replace':'const MachineCardScene = preload("res://app/machine_card.tscn")\nconst IronMineCard = preload("res://app/iron_mine_card.gd")'},
        {'search':'var card: GraphNode = MachineCardScene.instantiate()',
         'replace':'var card: GraphNode = IronMineCard.new() if kind == "iron_mine" else MachineCardScene.instantiate()'},
        {'search':'\t\tview.node.update_from_sim(sim, id)',
         'replace':'\t\tif view.node.has_method("set_simulation_playback"):\n\t\t\tview.node.set_simulation_playback(paused, time_scale)\n\t\tview.node.update_from_sim(sim, id)'},
        {'search':'var coal_mine := _add_card("coal_mine", Vector2(20, 230))',
         'replace':'var coal_mine := _add_card("coal_mine", Vector2(20, 310))'},
    ]})
    rpc('validate_script',{'path':'res://app/iron_mine_card.gd'})
    rpc('validate_script',{'path':'res://app/main.gd'})

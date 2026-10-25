extends RefCounted
## Orthogonal router for one canvas link at a time, inside a region around its two ends.
## Lines run on a sparse grid made of the card edges (pushed out so a line clears the card),
## the port stubs and the region's border, with extra lines a line width apart on either
## side so parallel lines get lanes. A* finds the cheapest path: length, plus a cost
## per bend, plus a heavy cost for lying on top of another link's line. Cards are walls.

## Cost of one bend, in line widths.
const BEND := 2.0
## Cost per px of running on top of another link's line.
const OVERLAP := 40.0
## Lanes added on each side of a port stub's grid line, one line width apart.
const LANES := 2
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

var _xs: PackedFloat32Array
var _ys: PackedFloat32Array
var _nx := 0
var _ny := 0
var _blocked: PackedByteArray
## Unit runs that would lie on another line: (y * nx + x) for x..x+1, (x * ny + y) for y..y+1.
var _h_bad: PackedByteArray
var _v_bad: PackedByteArray

## The route from the output at `a` to the input at `b` as its corner points, or [] when
## there is none inside `region`. `walls` are card rects already grown by the clearance;
## `runs` are [p, q] segments of the lines this one may not lie on.
func route(a: Vector2, b: Vector2, walls: Array[Rect2], runs: Array, region: Rect2,
		width: float, stub: float) -> PackedVector2Array:
	var start := Vector2(a.x + stub, a.y)
	var goal := Vector2(b.x - stub, b.y)
	if not region.has_point(start) or not region.has_point(goal):
		return PackedVector2Array()
	var xs := {}
	var ys := {}
	for x in [region.position.x, region.end.x]:
		xs[snappedf(x, 0.5)] = true
	for y in [region.position.y, region.end.y]:
		ys[snappedf(y, 0.5)] = true
	# Lines along the cards get one lane more on each side; the stubs get LANES.
	for wall in walls:
		for x in [wall.position.x, wall.end.x]:
			_add_lanes(xs, x, width, 1)
		for y in [wall.position.y, wall.end.y]:
			_add_lanes(ys, y, width, 1)
	_add_lanes(xs, start.x, width, LANES)
	_add_lanes(xs, goal.x, width, LANES)
	_add_lanes(ys, a.y, width, LANES)
	_add_lanes(ys, b.y, width, LANES)
	_xs = _inside(xs, region.position.x, region.end.x)
	_ys = _inside(ys, region.position.y, region.end.y)
	_nx = _xs.size()
	_ny = _ys.size()
	_blocked = PackedByteArray()
	_blocked.resize(_nx * _ny)
	for wall in walls:
		# Grid points strictly inside the wall.
		for yi in range(_after(_ys, wall.position.y), _before(_ys, wall.end.y)):
			for xi in range(_after(_xs, wall.position.x), _before(_xs, wall.end.x)):
				_blocked[yi * _nx + xi] = 1
	_h_bad = PackedByteArray()
	_h_bad.resize(_nx * _ny)
	_v_bad = PackedByteArray()
	_v_bad.resize(_nx * _ny)
	for run in runs:
		_mark(run[0], run[1], width)
	var path := _search(Vector2i(_xs.find(snappedf(start.x, 0.5)), _ys.find(snappedf(a.y, 0.5))),
		Vector2i(_xs.find(snappedf(goal.x, 0.5)), _ys.find(snappedf(b.y, 0.5))), width)
	if path.is_empty():
		return PackedVector2Array()
	var cells: Array[Vector2] = [a]
	for cell in path:
		cells.append(Vector2(_xs[cell.x], _ys[cell.y]))
	cells.append(b)
	# Keep only the bends.
	var points := PackedVector2Array([a])
	for k in range(1, cells.size() - 1):
		var prev := cells[k - 1]
		var here := cells[k]
		var next := cells[k + 1]
		if is_equal_approx(prev.x, here.x) != is_equal_approx(here.x, next.x):
			points.append(here)
	points.append(b)
	return points

func _add_lanes(set: Dictionary, at: float, width: float, lanes: int) -> void:
	for lane in range(-lanes, lanes + 1):
		set[snappedf(at + lane * width, 0.5)] = true

static func _inside(set: Dictionary, lo: float, hi: float) -> PackedFloat32Array:
	var list := PackedFloat32Array()
	for v in set:
		if v >= lo and v <= hi:
			list.append(v)
	list.sort()
	return list

## First index with coords[i] > v, and first index with coords[i] >= v.
static func _after(coords: PackedFloat32Array, v: float) -> int:
	return coords.bsearch(v + 0.25, true)

static func _before(coords: PackedFloat32Array, v: float) -> int:
	return coords.bsearch(v - 0.25, true)

## Marks the unit runs of the grid that would lie on the segment p-q.
func _mark(p: Vector2, q: Vector2, width: float) -> void:
	if p.is_equal_approx(q):
		return
	var near := width - 0.5
	if is_equal_approx(p.y, q.y):
		var x0 := minf(p.x, q.x) - width * 0.5
		var x1 := maxf(p.x, q.x) + width * 0.5
		for yi in range(_after(_ys, p.y - near), _before(_ys, p.y + near)):
			for xi in range(maxi(_before(_xs, x0) - 1, 0), mini(_before(_xs, x1), _nx - 1)):
				if _xs[xi + 1] > x0 + 0.25 and _xs[xi] < x1 - 0.25:
					_h_bad[yi * _nx + xi] = 1
	else:
		var y0 := minf(p.y, q.y) - width * 0.5
		var y1 := maxf(p.y, q.y) + width * 0.5
		for xi in range(_after(_xs, p.x - near), _before(_xs, p.x + near)):
			for yi in range(maxi(_before(_ys, y0) - 1, 0), mini(_before(_ys, y1), _ny - 1)):
				if _ys[yi + 1] > y0 + 0.25 and _ys[yi] < y1 - 0.25:
					_v_bad[xi * _ny + yi] = 1

## A* over the cells, each remembering the heading it was reached with (a bend is priced
## from that heading). Leaves `start` heading right; arriving at `goal` sideways costs a
## bend into the input. Returns the cells on the way, both ends included, or [].
func _search(start: Vector2i, goal: Vector2i, width: float) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	if start.x < 0 or start.y < 0 or goal.x < 0 or goal.y < 0:
		return none
	if _blocked[start.y * _nx + start.x] or _blocked[goal.y * _nx + goal.x]:
		return none
	var bend := BEND * width
	var goal_at := Vector2(_xs[goal.x], _ys[goal.y])
	var cells := _nx * _ny
	var cost := PackedFloat32Array()
	cost.resize(cells)
	cost.fill(INF)
	var from := PackedInt32Array()
	from.resize(cells)
	from.fill(-1)
	var heading := PackedByteArray()
	heading.resize(cells)
	var closed := PackedByteArray()
	closed.resize(cells)
	var heap := _Heap.new()
	var first := start.y * _nx + start.x
	var last := goal.y * _nx + goal.x
	cost[first] = 0.0
	heap.push(_dist(start, goal_at), first)
	while not heap.empty():
		var cell := heap.pop()
		if closed[cell]:
			continue
		closed[cell] = 1
		if cell == last:
			break
		var at := Vector2i(cell % _nx, cell / _nx)
		var here: float = cost[cell]
		var came: int = heading[cell]
		for turn: int in [0, 1, 3]:
			var h: int = (came + turn) % 4
			var dir := DIRS[h]
			var next := at + dir
			if next.x < 0 or next.y < 0 or next.x >= _nx or next.y >= _ny:
				continue
			var key := next.y * _nx + next.x
			if _blocked[key] or closed[key]:
				continue
			var step := absf(_xs[next.x] - _xs[at.x]) + absf(_ys[next.y] - _ys[at.y])
			var price := here + step + (bend if turn != 0 else 0.0)
			var low := Vector2i(mini(at.x, next.x), mini(at.y, next.y))
			var bad: int = _h_bad[low.y * _nx + low.x] if dir.y == 0 else _v_bad[low.x * _ny + low.y]
			if bad:
				price += step * OVERLAP
			if key == last and h != 0:
				price += bend
			if price < cost[key]:
				cost[key] = price
				from[key] = cell
				heading[key] = h
				heap.push(price + _dist(next, goal_at), key)
	if not closed[last]:
		return none
	var path: Array[Vector2i] = []
	var c := last
	while c >= 0:
		path.push_front(Vector2i(c % _nx, c / _nx))
		c = from[c]
	return path

func _dist(cell: Vector2i, goal: Vector2) -> float:
	return absf(_xs[cell.x] - goal.x) + absf(_ys[cell.y] - goal.y)

## Binary min-heap of (priority, value).
class _Heap:
	var _p := PackedFloat32Array()
	var _v := PackedInt32Array()

	func empty() -> bool:
		return _v.is_empty()

	func push(priority: float, value: int) -> void:
		_p.append(priority)
		_v.append(value)
		var i := _v.size() - 1
		while i > 0:
			var up := (i - 1) / 2
			if _p[up] <= _p[i]:
				break
			_swap(i, up)
			i = up

	func pop() -> int:
		var top := _v[0]
		var last := _v.size() - 1
		_swap(0, last)
		_p.resize(last)
		_v.resize(last)
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < last and _p[l] < _p[m]:
				m = l
			if r < last and _p[r] < _p[m]:
				m = r
			if m == i:
				break
			_swap(i, m)
			i = m
		return top

	func _swap(a: int, b: int) -> void:
		var p := _p[a]
		_p[a] = _p[b]
		_p[b] = p
		var v := _v[a]
		_v[a] = _v[b]
		_v[b] = v

extends GraphEdit
## Production graph with orthogonal (step) connection lines instead of bezier curves.

## Horizontal run out of an output port / into an input port before the first bend.
const STUB := 20.0

func _get_connection_line(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var stub := STUB * zoom
	if to_position.x - from_position.x >= stub * 2.0:
		# Forward link: out, one vertical step at the midpoint, in.
		var mid_x := roundf((from_position.x + to_position.x) * 0.5)
		return PackedVector2Array([from_position, Vector2(mid_x, from_position.y),
			Vector2(mid_x, to_position.y), to_position])
	# Backward link: leave right, cross over at mid height, enter from the left.
	var mid_y := roundf((from_position.y + to_position.y) * 0.5)
	var out_x := from_position.x + stub
	var in_x := to_position.x - stub
	return PackedVector2Array([from_position, Vector2(out_x, from_position.y), Vector2(out_x, mid_y),
		Vector2(in_x, mid_y), Vector2(in_x, to_position.y), to_position])

class_name Nav
## Floor graph navigation: WalkFloors are nodes, StairFlights are edges.
## next_step(from, to) tells an NPC what to do right now:
##   {"walk": x}                       walk along the current floor to x
##   {"stairs": flight, "end": "a"|"b", "x": entry_x}   go to a flight end and take it


static func floor_at(tree: SceneTree, p: Vector2) -> WalkFloor:
	var best: WalkFloor = null
	var best_d := INF
	for n in tree.get_nodes_in_group("walkfloor"):
		var f := n as WalkFloor
		if f and f.contains(p):
			var d := absf(p.y - f.top_y())
			if d < best_d:
				best = f
				best_d = d
	return best


static func next_step(tree: SceneTree, from: Vector2, to: Vector2) -> Dictionary:
	var sf := floor_at(tree, from)
	var tf := floor_at(tree, to)
	if sf == null or tf == null or sf == tf:
		return {"walk": to.x}
	# BFS over floors
	var edges := {}  # floor -> Array of [flight, my_end, other_floor]
	for n in tree.get_nodes_in_group("stairs"):
		var fl := n as StairFlight
		if fl == null:
			continue
		var fa := floor_at(tree, fl.ga())
		var fb := floor_at(tree, fl.gb())
		if fa == null or fb == null:
			continue
		if not edges.has(fa):
			edges[fa] = []
		if not edges.has(fb):
			edges[fb] = []
		edges[fa].append([fl, "a", fb])
		edges[fb].append([fl, "b", fa])
	var prev := {sf: null}
	var queue := [sf]
	while not queue.is_empty():
		var cur = queue.pop_front()
		if cur == tf:
			break
		for e in edges.get(cur, []):
			if not prev.has(e[2]):
				prev[e[2]] = [cur, e]
				queue.append(e[2])
	if not prev.has(tf):
		return {"walk": to.x}
	# walk back to find the first edge
	var node = tf
	var first_edge = null
	while prev[node] != null:
		first_edge = prev[node][1]
		node = prev[node][0]
	var fl2: StairFlight = first_edge[0]
	var end: String = first_edge[1]
	var entry := fl2.ga() if end == "a" else fl2.gb()
	return {"stairs": fl2, "end": end, "x": entry.x}


## How many floors apart two points are (sound travels through the stairwell).
static func vertical_floors(a: Vector2, b: Vector2) -> float:
	return absf(a.y - b.y) / 560.0

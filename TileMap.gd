extends TileMap

const OverlayForest = preload("res://Assets/Overlay/OverlayForest.tscn")
const OverlayGras = preload("res://Assets/Overlay/OverlayGras.tscn")
const OverlayHill = preload("res://Assets/Overlay/OverlayHill.tscn")
const OverlayTown = preload("res://Assets/Overlay/OverlayTown.tscn")
const OverlayWater = preload("res://Assets/Overlay/OverlayWater.tscn")

const OverlayPedestrian = preload("res://Assets/Overlay/OverlayPedestrian.tscn")
const OverlayBicycle = preload("res://Assets/Overlay/OverlayBicycle.tscn")
const OverlayVehicle = preload("res://Assets/Overlay/OverlayVehicle.tscn")

var objectmap = TileMap
const BORDER_MIN = Vector2(-1,-1)
const BORDER_MAX = Vector2(20,13)

var Current_Agent = -1
var Alternative_Paths = []
var Final_Path = []
var Overlay_Map = []
var Overlay_Map_Objects = []
var Overlap_Map = []

func _ready(): pass

func connect_agentmap(tilemap: Object):
	objectmap = tilemap

# --- DEBUG

func get_mouse_coord():
	return world_to_map(get_global_mouse_position()/2) # /2 because Scale=2.0

func get_tile_terrain_name() -> String:
	if (get_cellv(get_mouse_coord()) == -1) : return "Blank"
	return tile_set.tile_get_name(get_cellv(get_mouse_coord()))

# --- Overlay

func get_instance_by_agent():
	match Current_Agent:
		Constants.AGENT.PEDESTRIAN: return OverlayPedestrian.instance()
		Constants.AGENT.BICYCLE: return OverlayBicycle.instance()
		Constants.AGENT.VEHICLE: return OverlayVehicle.instance()
	return OverlayGras.instance()

func clear_overlay():
	Overlay_Map = []
	Overlay_Map_Objects = []
	Overlap_Map = []
	for _i in range(get_child_count()): remove_child(get_child(0))

func remove_object_by_id(id: int):
	for tile in objectmap.get_used_cells_by_id(id): objectmap.set_cellv(tile, -1)

func place_object_by_id(id: int, location: Vector2):
	objectmap.set_cellv(location, id)

func place_object(type: int, agent: bool):
	var mouse_coord = get_mouse_coord()
	if is_within_border(mouse_coord):
		if agent:
			if not get_cellv(mouse_coord) in [-1, Constants.TERRAIN.WATER]:
				remove_object_by_id(type)
				objectmap.set_cellv(mouse_coord, type)
		else:
			set_cellv(mouse_coord, type)

func place_overlay(tile_coord: Vector2):
	var offsetY = 0
	for i in Overlay_Map.size():
		if Overlay_Map[i] == tile_coord:
			var offset = Overlay_Map_Objects[i].get_offset()
			Overlay_Map_Objects[i].set_offset(Vector2(offset.x-(offsetY/2), offset.y-8))
			offsetY += 8
	var overlay_tile = get_instance_by_agent()
	overlay_tile.position = map_to_world(tile_coord)
	overlay_tile.modulate = Color(0,0,0)
	overlay_tile.scale = Vector2(0.5, 0.5)
	overlay_tile.set_offset(Vector2(32+(offsetY/2),24+offsetY))
	if is_within_border(tile_coord):
		Overlay_Map.append(tile_coord)
		Overlay_Map_Objects.append(overlay_tile)
		add_child(overlay_tile)

func add_overlap_agent(index: int, list: Array) -> Array:
	for i in Overlap_Map.size():
		if (index < Overlap_Map[i].size()):
			list.append(Overlap_Map[i][index])
	return list

func delete_overlap_agent(index: int, list: Array) -> Array:
	for i in Overlap_Map.size():
		if (index < Overlap_Map[i].size()):
			list.erase(Overlap_Map[i][index])
	return list

# --- Path Finder

func find_path() -> Array:
	clear_overlay()
	
	var agent_goal_coord = create_coord_pairs()
	if agent_goal_coord.empty(): return []
	
	var complete_navigation_paths = Array()
	for current_pair in agent_goal_coord:
		Current_Agent = objectmap.get_cellv(current_pair[0])
		var route = best_first_search(current_pair[0], current_pair[1])
		if route:
			#var trunc_route = truncate_correction(route)
			#if trunc_route.size() < route.size() && trunc_route.back() == current_pair[1]: route = trunc_route
			for i in range(route.size()) : place_overlay(route[i])
			Overlap_Map.append(route)
		
		complete_navigation_paths.append(route)
		Constants.activate_route(Current_Agent)
	return complete_navigation_paths

# Best First Search
func best_first_search(current_tile: Vector2, goal_tile: Vector2) -> Array:
	var list_visited_tiles = [ current_tile ]
	Final_Path = [ current_tile ]
	Alternative_Paths = [ Vector2() ]
	var alternative_paths_exist = false
	var backtrack = -2
	var skipped_tiles = []
	var distance_to_goal = calculate_distance( current_tile, goal_tile )
	var shortest_path = distance_to_goal + 1 #it includes the start tile
	
	var overlap_index = 0
	
	while distance_to_goal > 0:
		overlap_index += 1
		list_visited_tiles = add_overlap_agent(overlap_index, list_visited_tiles)
		var next_step = find_next_step(current_tile, goal_tile, list_visited_tiles)
		list_visited_tiles = delete_overlap_agent(overlap_index, list_visited_tiles)
		
		if next_step.x != INF : #we actually found the next step
			var next_tile = current_tile + offset_neighbors[get_offset_parity(current_tile)][next_step.y]
			if next_step.z != -1 :
				var alternative_tile = current_tile + offset_neighbors[get_offset_parity(current_tile)][next_step.z]
				Alternative_Paths.append(alternative_tile)
				alternative_paths_exist = true
			else:
				Alternative_Paths.append(Vector2()) # to ensure that Alternative_Paths and list_visited_tiles have an equal size
			distance_to_goal = next_step.x
			current_tile = next_tile
			list_visited_tiles.append(current_tile)
			Final_Path.append(current_tile)
			backtrack = -2
		else:
			current_tile = list_visited_tiles[backtrack]
			backtrack -= 1
			skipped_tiles.append(Final_Path[-1])
			Final_Path.remove( Final_Path.size()-1 )
			Alternative_Paths.remove( Alternative_Paths.size()-1 )
			if Final_Path.size() == 0:
				print("We cant reach it")
				break

	check_for_shortcuts()
	
	if alternative_paths_exist && shortest_path != Final_Path.size() :
		var check_all_paths = true
		while check_all_paths:
			check_all_paths = false
			for i in range(Alternative_Paths.size()-2) :
				if Alternative_Paths[i] != Vector2() :
					var alternate_list_tiles_checked = Final_Path.slice(0, i+1, 1, false)
					var alternate_list_paths_checked = Alternative_Paths.slice(0, i-1, 1, false)
					var tiles_to_remove = 2
					for j in range(skipped_tiles.size()) :
						alternate_list_tiles_checked.append(skipped_tiles[j])
						tiles_to_remove += 1
					current_tile = alternate_list_tiles_checked[i-1]
					distance_to_goal = offsetY_distance(current_tile, goal_tile)
					var old_length = Final_Path.size()
					var new_length = i
					
					while distance_to_goal > 0 && new_length < old_length - 1 :
						list_visited_tiles = add_overlap_agent(overlap_index, list_visited_tiles)
						var next_step = find_next_step(current_tile, goal_tile, alternate_list_tiles_checked)
						list_visited_tiles = delete_overlap_agent(overlap_index, list_visited_tiles)
						
						if next_step.x != INF : #we actually found the next step
							var next_tile = current_tile + offset_neighbors[get_offset_parity(current_tile)][next_step.y]
							if next_step.z != -1 :
								var alternative_tile = current_tile + offset_neighbors[get_offset_parity(current_tile)][next_step.z]
								alternate_list_paths_checked.append(alternative_tile)
							else:
								alternate_list_paths_checked.append(Vector2()) # to ensure that Alternative_Paths and list_visited_tiles have an equal size
							distance_to_goal = next_step.x
							current_tile = next_tile
							alternate_list_tiles_checked.append(current_tile)
							new_length += 1
						else:
							break
					if distance_to_goal == 0:
						check_all_paths = true
						for _i in range(tiles_to_remove) :
							alternate_list_tiles_checked.remove(i)
						Alternative_Paths = alternate_list_paths_checked
						Final_Path = alternate_list_tiles_checked
						check_for_shortcuts()
						break
						
	return Final_Path

func bug1_correction(route: Array) -> Array:
	var last_neighbor_index = 1
	var neighbors = get_all_tile_neighbors(route[0])
	for i in range(route.size()-1, -1, -1):
		if route[i] in neighbors: 
			last_neighbor_index = i
			break;
	if last_neighbor_index == 1: return route
	
	var corrected_array = [route[0]]
	corrected_array.append_array(route.slice(last_neighbor_index, route.size()-1, 1, false))
	print("[Bug1] Changing neighbor from ", route[1], " to ", route[last_neighbor_index])
	print("Before: ",route)
	print("After: ", corrected_array)
	return corrected_array

func truncate_correction(route: Array) -> Array:
	var trunc_route = truncation(route)
	var routeA = best_first_search(trunc_route[0], trunc_route[1])
	var routeB = best_first_search(trunc_route[1], trunc_route[2])
	routeA.erase(routeA.back())
	trunc_route = bug1_correction(routeA + routeB)
	return trunc_route

func check_for_shortcuts():
	var ii = 0
	while true:
		if Final_Path.size() - ii <= 2 :
			break
		else:
			if offsetY_distance(Final_Path[ii], Final_Path[ii+2]) == 1:
				Final_Path.remove(ii+1)
				Alternative_Paths.remove(ii+1)
			else:
				ii += 1

# return: Vector3(Distance-To-Goal, Neighbor-Direction-Index, If-Branching-Path)
func find_next_step(current_tile: Vector2, goal_tile: Vector2, list_visited_tiles: Array) -> Vector3:
	var adjacent_tile = Vector3(INF, INF, -1)
	var adjacent_cost = INF
	var temporal_distance = INF
	var next_tile = Vector2()
	var tile_distance = 0
	var distance_cost = calculate_distance_cost(next_tile)
	var alternative_tile = -1
	var neighboring_tiles = offset_neighbors[get_offset_parity(current_tile)]
	var tile_considered = true
	
	for i in range( neighboring_tiles.size() ):
		next_tile = current_tile + neighboring_tiles[i]
		if list_visited_tiles.has(next_tile): tile_considered = false
		if not is_traversable(next_tile): tile_considered = false
		if tile_considered:
			tile_distance = offsetY_distance(next_tile, goal_tile)
			distance_cost = calculate_distance_cost(next_tile)
			if tile_distance < adjacent_tile.x :
				if distance_cost < adjacent_cost:
					distance_cost = adjacent_cost
					adjacent_tile.x = tile_distance
					adjacent_tile.y = i
				else:
					temporal_distance = tile_distance
					alternative_tile = i
			elif tile_distance == adjacent_tile.x :
				temporal_distance = tile_distance
				adjacent_tile.z = i
		else: tile_considered = true
	if alternative_tile != -1:
		if temporal_distance == adjacent_tile.x :
			adjacent_tile.z = alternative_tile
	if adjacent_tile.z != -1:
		if temporal_distance != adjacent_tile.x :
			adjacent_tile.z = -1
		else:
			var firstChoice = current_tile + neighboring_tiles[adjacent_tile.y]
			var secondChoice = current_tile + neighboring_tiles[adjacent_tile.z]
			if calculate_distance_cost(firstChoice) > calculate_distance_cost(secondChoice):
				alternative_tile = adjacent_tile.z
				adjacent_tile.z = adjacent_tile.y
				adjacent_tile.y = alternative_tile
	if not adjacent_tile:
		print("Debug: ", current_tile)
	return adjacent_tile

# --- Helper

func truncation(array: Array) -> Array:
	var trunc_array = []
	trunc_array.append(array.front())
	trunc_array.append(array[floor(array.size()/2)])
	trunc_array.append(array.back())
	return trunc_array

func is_within_border(tile: Vector2) -> bool:
	return tile.x > BORDER_MIN.x && tile.y > BORDER_MIN.y && tile.x < BORDER_MAX.x && tile.y < BORDER_MAX.y

func is_traversable(target_tile: Vector2) -> bool:
	var tiletype = get_cellv(target_tile)
	if Current_Agent == 2:
		return not tiletype in [Constants.TERRAIN.WATER, Constants.TERRAIN.HILL, -1]
	else:
		return not tiletype in [Constants.TERRAIN.WATER, -1]

func create_coord_pairs() -> Array:
	var agent_goal_pairs = Array()
	if objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN) and objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN_G):
		agent_goal_pairs.append([objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN)[0], objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN_G)[0]])
	if objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE) and objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE_G):
		agent_goal_pairs.append([objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE)[0], objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE_G)[0]])
	if objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE) and objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE_G):
		agent_goal_pairs.append([objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE)[0], objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE_G)[0]])
	return agent_goal_pairs

func calculate_distance(start: Vector2, end: Vector2) -> float:
	var distance_x = end.x - start.x
	var distance_y = end.y - start.y
	if sign(distance_x) == sign(distance_y):
		return abs(distance_x + distance_y)
	else:
		return max(abs(distance_x), abs(distance_y))

# --- Offset Helpers

func get_offset_parity(tile):
	return int(tile.x) & 1

const offset_neighbors = [
	# EVEN COLUMN
	[ Vector2(1,0), Vector2(1,-1), Vector2(0,-1),
	Vector2(-1,-1), Vector2(-1,0), Vector2(0,1)],
	# ODD COLUMN
	[ Vector2(1,1), Vector2(1,0), Vector2(0,-1),
	Vector2(-1,0), Vector2(-1,1), Vector2(0,1)],
]

func get_tile_neighbor(tile, direction):
	var parity = get_offset_parity(tile)
	var diff = offset_neighbors[parity][direction]
	return Vector2(tile.x + diff[0], tile.y + diff[1])

func get_all_tile_neighbors(tile: Vector2) -> Array:
	var neighboring_tiles = offset_neighbors[get_offset_parity(tile)]
	var neighbors = []
	for i in range(neighboring_tiles.size()):
		neighbors.append(tile + neighboring_tiles[i])
	return neighbors

func offsetY_to_arial(tile):
	tile.y = (tile.y - (floor( tile.x/2) ))
	return tile

func offsetY_distance(a,b):
	var ac = offsetY_to_arial(a)
	var bc = offsetY_to_arial(b)
	return calculate_axial_distance(ac, bc)

func calculate_axial_distance(a, b):
	return (
		abs(a.x - b.x) + 
		abs(a.x + a.y - b.x - b.y) + 
		abs(a.y - b.y)
		) / 2

func calculate_distance_cost(tile: Vector2) -> int:
	match get_cellv(tile):
		Constants.TERRAIN.GRAS: 
			return 1
		Constants.TERRAIN.FOREST: 
			match Current_Agent:
				Constants.AGENT.PEDESTRIAN: return 2
				Constants.AGENT.BICYCLE: return 2
				Constants.AGENT.VEHICLE: return 2
		Constants.TERRAIN.HILL: 
			match Current_Agent:
				Constants.AGENT.PEDESTRIAN: return 3
				Constants.AGENT.BICYCLE: return 3
				Constants.AGENT.VEHICLE: return 99
		Constants.TERRAIN.TOWN:
			match Current_Agent:
				Constants.AGENT.PEDESTRIAN: return 1
				Constants.AGENT.BICYCLE: return 1
				Constants.AGENT.VEHICLE: return 1
	return 99

# --- Step by Step

func prepare_step_by_step(paths: Array, agents: Array):
	clear_overlay()
	objectmap.clear()
	reset_step_positions(paths, agents)

func reset_step_positions(paths: Array, agents: Array):
	var path_pedestrian = false
	var path_bicycle = false
	var path_vehicle = false
	for agent in agents:
		match agent:
			0: path_pedestrian = true
			1: path_bicycle = true
			2: path_vehicle = true
	for i in range(paths.size()) :
		if path_pedestrian:
			objectmap.set_cellv(paths[i].front(), Constants.AGENT.PEDESTRIAN)
			objectmap.set_cellv(paths[i].back(), Constants.AGENT.PEDESTRIAN_G)
			path_pedestrian = false
		elif path_bicycle:
			objectmap.set_cellv(paths[i].front(), Constants.AGENT.BICYCLE)
			objectmap.set_cellv(paths[i].back(), Constants.AGENT.BICYCLE_G)
			path_bicycle = false
		elif path_vehicle:
			objectmap.set_cellv(paths[i].front(), Constants.AGENT.VEHICLE)
			objectmap.set_cellv(paths[i].back(), Constants.AGENT.VEHICLE_G)
			path_vehicle = false

func step_forward(count: int, paths: Array, agents: Array):
	var path_pedestrian = false
	var path_bicycle = false
	var path_vehicle = false
	for agent in agents:
		match agent:
			0: path_pedestrian = true
			1: path_bicycle = true
			2: path_vehicle = true
	for i in range(paths.size()) :
		if path_pedestrian:
			if (paths[i].size() > count):
				remove_object_by_id(0)
				objectmap.set_cellv(paths[i][count], Constants.AGENT.PEDESTRIAN)
			path_pedestrian = false
		elif path_bicycle:
			if (paths[i].size() > count):
				remove_object_by_id(1)
				objectmap.set_cellv(paths[i][count], Constants.AGENT.BICYCLE)
			path_bicycle = false
		elif path_vehicle:
			if (paths[i].size() > count):
				remove_object_by_id(2)
				objectmap.set_cellv(paths[i][count], Constants.AGENT.VEHICLE)
			path_vehicle = false

func step_backward(count: int, paths: Array, agents: Array):
	var path_pedestrian = false
	var path_bicycle = false
	var path_vehicle = false
	for agent in agents:
		match agent:
			0: path_pedestrian = true
			1: path_bicycle = true
			2: path_vehicle = true
	for i in range(paths.size()) :
		if path_pedestrian:
			if (paths[i].size() > count):
				remove_object_by_id(0)
				objectmap.set_cellv(paths[i][count], Constants.AGENT.PEDESTRIAN)
				if (paths[i].size()-2 == count):
					objectmap.set_cellv(paths[i][count+1], Constants.AGENT.PEDESTRIAN_G)
			path_pedestrian = false
		elif path_bicycle:
			if (paths[i].size() > count):
				remove_object_by_id(1)
				objectmap.set_cellv(paths[i][count], Constants.AGENT.BICYCLE)
				if (paths[i].size()-2 == count):
					objectmap.set_cellv(paths[i][count+1], Constants.AGENT.BICYCLE_G)
			path_bicycle = false
		elif path_vehicle:
			if (paths[i].size() > count):
				remove_object_by_id(2)
				objectmap.set_cellv(paths[i][count], Constants.AGENT.VEHICLE)
				if (paths[i].size()-2 == count):
					objectmap.set_cellv(paths[i][count+1], Constants.AGENT.VEHICLE_G)
			path_vehicle = false

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

func _ready(): pass

func connect_agentmap(tilemap: Object):
	objectmap = tilemap

# --- DEBUG

func get_mouse_coord():
	return world_to_map(get_global_mouse_position()/2) # /2 because Scale=2.0

func get_tile_terrain_name() -> String:
	var tile_type = tile_set.tile_get_name(get_cellv(get_mouse_coord()))
	if tile_type: return tile_type
	return "Blank"

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
	for _i in range(get_child_count()): remove_child(get_child(0))

func remove_object_by_id(id: int):
	for tile in objectmap.get_used_cells_by_id(id): objectmap.set_cellv(tile, -1)

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

func get_overlay_by_tile(type: int) -> Object:
	match type:
		Constants.TERRAIN.FOREST:	return OverlayForest.instance()
		Constants.TERRAIN.GRAS:  	return OverlayGras.instance()
		Constants.TERRAIN.HILL:  	return OverlayHill.instance()
		Constants.TERRAIN.TOWN:  	return OverlayTown.instance()
		Constants.TERRAIN.WATER: 	return OverlayWater.instance()
	return OverlayGras.instance()

# --- Path Finder

func find_path() -> Array:
	clear_overlay()
	
	var agent_goal_coord = create_coord_pairs()
	print("Found coord-pairs: ", agent_goal_coord)
	if agent_goal_coord.empty(): return []
	
	var complete_navigation_paths = Array()
	for current_pair in agent_goal_coord:
		
		var current_tile = current_pair[0]
		var goal_tile = current_pair[1]
		
		Current_Agent = objectmap.get_cellv(current_tile)
		var list_visited_tiles = [ current_tile ]
		Final_Path = [ current_tile ]
		Alternative_Paths = [ Vector2() ]
		var alternative_paths_exist = false
		var backtrack = -2
		var skipped_tiles = []
		var distance_to_goal = calculate_distance( current_tile, goal_tile )
		var shortest_path = distance_to_goal + 1 #it includes the start tile
		
		print("Axial Distance: ",calculate_axial_distance(current_tile, goal_tile))
		print("Offset Distance: ", offsetY_distance(current_tile, goal_tile))
		
		while distance_to_goal > 0:
			var next_step = find_next_step(current_tile, goal_tile, list_visited_tiles)
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
							var next_step = find_next_step(current_tile, goal_tile, alternate_list_tiles_checked)
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
							
		Final_Path = bug1_correction(Final_Path)
		
		for i in range(Final_Path.size()) :
			place_overlay(Final_Path[i])
		
		complete_navigation_paths.append(Final_Path)
	return complete_navigation_paths

func bug1_correction(route: Array) -> Array:
	var neighbor_count = 0
	var neighboring_tiles = offset_neighbors[get_offset_parity(route[0])]
	var last_neighbor_found = Vector2()
	for i in range( neighboring_tiles.size() ):
		var adjacent_tile = route[0] + neighboring_tiles[i]
		if route.has(adjacent_tile):
			neighbor_count += 1
			last_neighbor_found = adjacent_tile
	if neighbor_count > 1:
		var corrected_array = [route[0]]
		corrected_array.append_array(route.slice(route.find(last_neighbor_found), route.size()-1, 1, false))
		print("[Bug1] Changing neighbor from ", route[1], " to ", last_neighbor_found)
		print("Before: ",route)
		print("After: ", corrected_array)
		return corrected_array
		
	else:
		print("No correction needed")
		return route

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
	var temporal_distance = INF
	var next_tile = Vector2()
	var tile_distance = 0
	var neighboring_tiles = offset_neighbors[get_offset_parity(current_tile)]
	
	for i in range( neighboring_tiles.size() ):
		next_tile = current_tile + neighboring_tiles[i]
		if not (list_visited_tiles.has(next_tile) || is_not_traversable(next_tile)):
			tile_distance = offsetY_distance(next_tile, goal_tile)
			if tile_distance < adjacent_tile.x :
				adjacent_tile.x = tile_distance
				adjacent_tile.y = i
			elif tile_distance == adjacent_tile.x :
				temporal_distance = tile_distance
				adjacent_tile.z = i
	if adjacent_tile.z != -1:
		if temporal_distance != adjacent_tile.x :
			adjacent_tile.z = -1
	return adjacent_tile

# --- Helper

func is_within_border(tile: Vector2) -> bool:
	return tile.x > BORDER_MIN.x && tile.y > BORDER_MIN.y && tile.x < BORDER_MAX.x && tile.y < BORDER_MAX.y

func is_not_traversable(target_tile: Vector2) -> bool:
	var tiletype = get_cellv(target_tile)
	return [Constants.TERRAIN.WATER, -1].has(tiletype)
	#return tiletype != Constants.TERRAIN.WATER || tiletype != -1

func create_coord_pairs() -> Array:
	var agent_goal_pairs = Array()
	if objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN) and objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN_G):
		agent_goal_pairs.append([objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN)[0], objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN_G)[0]])
	if objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE) and objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE_G):
		agent_goal_pairs.append([objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE)[0], objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE_G)[0]])
	if objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE) and objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE_G):
		agent_goal_pairs.append([objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE)[0], objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE_G)[0]])
	return agent_goal_pairs

func extract_goals():
	var pedestrian = objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN_G)
	var bicycle = objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE_G)
	var vehicle = objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE_G)
	return { "pedestrian": pedestrian, "bicycle": bicycle, "vehicle": vehicle }

func extract_agents():
	var pedestrian = objectmap.get_used_cells_by_id(Constants.AGENT.PEDESTRIAN)
	var bicycle = objectmap.get_used_cells_by_id(Constants.AGENT.BICYCLE)
	var vehicle = objectmap.get_used_cells_by_id(Constants.AGENT.VEHICLE)
	return { "pedestrian": pedestrian, "bicycle": bicycle, "vehicle": vehicle }

func get_agent_by_id(id: int):
	return objectmap.get_used_cells_by_id(id)

func calculate_distance(start: Vector2, end: Vector2) -> float:
	var distance_x = end.x - start.x
	var distance_y = end.y - start.y
	if sign(distance_x) == sign(distance_y):
		return abs(distance_x + distance_y)
	else:
		return max(abs(distance_x), abs(distance_y))

# --- Axial Helper

var axial_direction_vectors = [ Vector2(1,0), Vector2(1,-1), Vector2(0,-1),Vector2(-1,0), Vector2(-1,1), Vector2(0,1) ]

func axial_direction(direction) -> Vector2:
	return axial_direction_vectors[direction]

func axial_add(tile, vector) -> Vector2:
	return Vector2(tile.x + vector.x, tile.y + vector.y)

func axial_neighbor(tile, direction) -> Vector2:
	return axial_add(tile, axial_direction(direction))

func calculate_axial_distance(a, b):
	return (
		abs(a.x - b.x) + 
		abs(a.x + a.y - b.x - b.y) + 
		abs(a.y - b.y)
		) / 2

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

func offsetY_to_arial(tile):
	tile.y = (tile.y - (floor( tile.x/2) ))
	return tile

func offsetY_distance(a,b):
	var ac = offsetY_to_arial(a)
	var bc = offsetY_to_arial(b)
	return calculate_axial_distance(ac, bc)

# --- DEBUG
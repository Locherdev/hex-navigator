extends Node2D

const OverlayForest = preload("res://Assets/Overlay/OverlayForest.tscn")
onready var tilemap = $TileMap
onready var agentmap = $ObjectMap

var selected_leftclick = -1
var selected_rightclick = -1

var paths = []
var active_agents = []
var mode = -1
var step_by_step = 0
var highest_step = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap.connect_agentmap(agentmap)
	reset_UI_highlight()
	print("-- HexSimulator v0.1b started.")

func _process(_delta):
	detect_UI()
	
	if mode == 0:
		if Input.is_action_pressed("leftclick"):
			tilemap.place_object(selected_leftclick, false)
		if Input.is_action_pressed("rightclick"):
			tilemap.place_object(-1, false)
	elif mode == 1:
		if (Input.is_action_just_released("leftclick")):
			tilemap.clear_overlay()
			tilemap.place_object(selected_leftclick, true)
		if (Input.is_action_just_released("rightclick")):
			tilemap.clear_overlay()
			tilemap.place_object(selected_rightclick, true)
	if tilemap.is_within_border(tilemap.get_mouse_coord()):
		Constants.set_label($AnalyticLayer/ControlBox/gridInfo, tilemap.get_tile_terrain_name()+": " + str(tilemap.get_mouse_coord()))
	else: Constants.set_label($AnalyticLayer/ControlBox/gridInfo, "")
	
	if Input.is_action_just_released("wheelclick"):
			print(tilemap.best_first_search(Vector2(6,3), Vector2(0,9)))

func detect_UI():
	if (Input.is_action_just_released("leftclick")):
		if Constants.creator_objects.has(tilemap.get_mouse_coord()): 
			reset_UI_highlight()
		match tilemap.get_mouse_coord():
			Constants.creator_gras:
				mode = 0
				selected_leftclick = Constants.TERRAIN.GRAS
				$AnalyticLayer/TerrainBox/TerrainTiles/Gras.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Gras")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Terrain Tile\nCan be walked on by any agent")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place tile\nErase tile")
			Constants.creator_hill:
				mode = 0
				selected_leftclick = Constants.TERRAIN.HILL
				$AnalyticLayer/TerrainBox/TerrainTiles/Hill.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Hill")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Terrain Tile\nNot accessible by vehicle")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place tile\nErase tile")
			Constants.creator_forest:
				mode = 0
				selected_leftclick = Constants.TERRAIN.FOREST
				$AnalyticLayer/TerrainBox/TerrainTiles/Forest.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Forest")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Terrain Tile\nNot accessible by vehicle")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place tile\nErase tile")
			Constants.creator_town:
				mode = 0
				selected_leftclick = Constants.TERRAIN.TOWN
				$AnalyticLayer/TerrainBox/TerrainTiles/Town.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Town")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Terrain Tile\nCan be walked on by any agent")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place tile\nErase tile")
			Constants.creator_water:
				mode = 0
				selected_leftclick = Constants.TERRAIN.WATER
				$AnalyticLayer/TerrainBox/TerrainTiles/Water.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Water")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Terrain Tile\nNot accessible by any agent")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place tile\nErase tile")
			Constants.creator_pedestrian:
				mode = 1
				selected_leftclick = Constants.AGENT.PEDESTRIAN
				selected_rightclick = Constants.AGENT.PEDESTRIAN_G
				$AnalyticLayer/AgentBox/AgentTiles/Pedestrian.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Pedestrian")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Agent Tile\nCan access every terrain\nbut water.")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place agent\nPlace goal")
			Constants.creator_bicycle:
				mode = 1
				selected_leftclick = Constants.AGENT.BICYCLE
				selected_rightclick = Constants.AGENT.BICYCLE_G
				$AnalyticLayer/AgentBox/AgentTiles/Bicycle.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Bicycle")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Agent Tile\nCan access every terrain\nbut water.")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place agent\nPlace goal")
			Constants.creator_vehicle:
				mode = 1
				selected_leftclick = Constants.AGENT.VEHICLE
				selected_rightclick = Constants.AGENT.VEHICLE_G
				$AnalyticLayer/AgentBox/AgentTiles/Vehicle.modulate = Color(1, 1, 1)
				Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "Vehicle")
				Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "Agent Tile\nCan access every terrain\nbut hill and water.")
				Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "Place agent\nPlace goal")
			Constants.creator_clear:
				agentmap.clear()
				tilemap.clear_overlay()

func reset_UI_highlight():
	for i in range(0, $AnalyticLayer/TerrainBox/TerrainTiles.get_child_count()):
		$AnalyticLayer/TerrainBox/TerrainTiles.get_child(i).modulate = Color(0.5, 0.5, 0.5)
	for i in range(0, $AnalyticLayer/AgentBox/AgentTiles.get_child_count()):
		$AnalyticLayer/AgentBox/AgentTiles.get_child(i).modulate = Color(0.5, 0.5, 0.5)
	Constants.set_label($AnalyticLayer/InfoBox/RouteInfo, "")
	Constants.set_label($AnalyticLayer/InfoBox/RouteInfo2, "")
	Constants.set_label($AnalyticLayer/InfoBox/RouteInfo3, "")
	Constants.set_label($AnalyticLayer/InfoBox/TitleLabel2, "")
	Constants.set_label($AnalyticLayer/InfoBox/TileInfo, "")
	Constants.set_label($AnalyticLayer/ControlBox/ControlInfo2, "")
	$AnalyticLayer/StartBox/Buttons/BackwardButton.disabled = true
	$AnalyticLayer/StartBox/Buttons/ForwardButton.disabled = true
	$AnalyticLayer/StartBox/Buttons/StepByStepButton.disabled = true

func analyze_paths() :
	for i in range(paths.size()) :
		if Constants.route_pedestrian:
			Constants.route_result(0, $AnalyticLayer/InfoBox/RouteInfo, str(paths[i].size()-1))
			active_agents.append(Constants.AGENT.PEDESTRIAN)
		elif Constants.route_bicycle:
			Constants.route_result(1, $AnalyticLayer/InfoBox/RouteInfo2, str(paths[i].size()-1))
			active_agents.append(Constants.AGENT.BICYCLE)
		elif Constants.route_vehicle:
			Constants.route_result(2, $AnalyticLayer/InfoBox/RouteInfo3, str(paths[i].size()-1))
			active_agents.append(Constants.AGENT.VEHICLE)

# --- Buttons ---
func _best_first_search():
	Constants.reset_route_results()
	mode = 2
	reset_UI_highlight()
	paths = tilemap.find_path()
	active_agents = []
	analyze_paths()
	if (paths): $AnalyticLayer/StartBox/Buttons/StepByStepButton.disabled = false

func step_by_step():
	$AnalyticLayer/StartBox/Buttons/ForwardButton.disabled = false
	$AnalyticLayer/StartBox/Buttons/BackwardButton.disabled = true
	step_by_step = 0
	highest_step = get_highest_step()
	tilemap.prepare_step_by_step(paths, active_agents)

func step_forward():
	step_by_step += 1
	$AnalyticLayer/StartBox/Buttons/BackwardButton.disabled = false
	tilemap.step_forward(step_by_step, paths, active_agents)
	if (step_by_step == highest_step): 
		$AnalyticLayer/StartBox/Buttons/ForwardButton.disabled = true


func step_backward():
	step_by_step -= 1
	$AnalyticLayer/StartBox/Buttons/ForwardButton.disabled = false
	tilemap.step_backward(step_by_step, paths, active_agents)
	if (step_by_step == 0): 
		$AnalyticLayer/StartBox/Buttons/BackwardButton.disabled = true


# --- DEBUG ---

func get_highest_step() -> int:
	var highest = 0
	for i in range(paths.size()) :
		if (paths[i].size()-1 > highest):
			highest = paths[i].size()-1
	return highest



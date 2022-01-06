extends Node2D

const OverlayForest = preload("res://Assets/Overlay/OverlayForest.tscn")
onready var tilemap = $TileMap
onready var agentmap = $ObjectMap
onready var tile_info = $debugLabel

var selected_leftclick = -1
var selected_rightclick = -1

var paths = []
var mode = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap.connect_agentmap(agentmap)
	reset_UI_highlight()
	print("-- HexSimulator v0.1a started.")

func _process(_delta):
	detect_UI()
	
	if mode == 0:
		if Input.is_action_pressed("leftclick"):
			tilemap.place_object(selected_leftclick, false)
		if Input.is_action_pressed("rightclick"):
			tilemap.place_object(-1, false)
	elif mode == 1:
		if (Input.is_action_just_released("leftclick")):
			tilemap.place_object(selected_leftclick, true)
		if (Input.is_action_just_released("rightclick")):
			tilemap.place_object(selected_rightclick, true)
		if (Input.is_action_just_released("start")):
			paths = tilemap.find_path()
			analyze_paths(paths)
		if (Input.is_action_just_released("wheelclick")):
			paths = tilemap.bug1_correction(paths)
			
	if tilemap.is_within_border(tilemap.get_mouse_coord()):
		tile_info.text = tilemap.get_tile_terrain_name()+": " + str(tilemap.get_mouse_coord())
	else: tile_info.text = ""

func detect_UI():
	if (Input.is_action_just_released("leftclick")):
		tilemap.clear_overlay()
		if Constants.creator_objects.has(tilemap.get_mouse_coord()): reset_UI_highlight()
		match tilemap.get_mouse_coord():
			Constants.creator_gras:
				mode = 0
				selected_leftclick = Constants.TERRAIN.GRAS
				$AnalyticLayer/TerrainBox/TerrainTiles/Gras.modulate = Color(1, 1, 1)
			Constants.creator_hill:
				mode = 0
				selected_leftclick = Constants.TERRAIN.HILL
				$AnalyticLayer/TerrainBox/TerrainTiles/Hill.modulate = Color(1, 1, 1)
			Constants.creator_forest:
				mode = 0
				selected_leftclick = Constants.TERRAIN.FOREST
				$AnalyticLayer/TerrainBox/TerrainTiles/Forest.modulate = Color(1, 1, 1)
			Constants.creator_town:
				mode = 0
				selected_leftclick = Constants.TERRAIN.TOWN
				$AnalyticLayer/TerrainBox/TerrainTiles/Town.modulate = Color(1, 1, 1)
			Constants.creator_water:
				mode = 0
				selected_leftclick = Constants.TERRAIN.WATER
				$AnalyticLayer/TerrainBox/TerrainTiles/Water.modulate = Color(1, 1, 1)
			Constants.creator_pedestrian:
				mode = 1
				selected_leftclick = Constants.AGENT.PEDESTRIAN
				selected_rightclick = Constants.AGENT.PEDESTRIAN_G
				$AnalyticLayer/AgentBox/AgentTiles/Pedestrian.modulate = Color(1, 1, 1)
			Constants.creator_bicycle:
				mode = 1
				selected_leftclick = Constants.AGENT.BICYCLE
				selected_rightclick = Constants.AGENT.BICYCLE_G
				$AnalyticLayer/AgentBox/AgentTiles/Bicycle.modulate = Color(1, 1, 1)
			Constants.creator_vehicle:
				mode = 1
				selected_leftclick = Constants.AGENT.VEHICLE
				selected_rightclick = Constants.AGENT.VEHICLE_G
				$AnalyticLayer/AgentBox/AgentTiles/Vehicle.modulate = Color(1, 1, 1)

func reset_UI_highlight():
	for i in range(0, $AnalyticLayer/TerrainBox/TerrainTiles.get_child_count()):
		$AnalyticLayer/TerrainBox/TerrainTiles.get_child(i).modulate = Color(0.5, 0.5, 0.5)
	for i in range(0, $AnalyticLayer/AgentBox/AgentTiles.get_child_count()):
		$AnalyticLayer/AgentBox/AgentTiles.get_child(i).modulate = Color(0.5, 0.5, 0.5)

func analyze_paths(paths: Array) :
	for i in range(paths.size()) :
		for j in range(paths[i].size()) :
			print("Step ",j,": ",paths[i][j])

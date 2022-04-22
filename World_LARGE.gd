extends Node2D

onready var tilemap = $TileMap
onready var agentmap = $ObjectMap
onready var camera = $Camera2D

const MAX = 1000
const CAM_SPEED = 100
const MOUSE_CAM_RADIUS = 100

func _ready():
	camera.make_current()
	tilemap.connect_agentmap(agentmap, MAX, MAX)
	camera.position = Vector2(640, 340)

func _process(_delta):
	if Input.is_action_just_released("rightclick"):
		camera.position = get_global_mouse_position()
	#if Input.is_action_just_released("wheelclick"):
		#print("Secondary Pathfind")
		#tilemap.find_path()

func _preparation():
	tilemap.clear()
	agentmap.clear()
	for y in MAX:
		for x in MAX:
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			tilemap.set_cellv(Vector2(x,y), rng.randi_range(0,4))
	tilemap.set_cellv(Vector2(20,20), Constants.TERRAIN.TOWN)
	tilemap.set_cellv(Vector2(MAX-20,MAX-20), Constants.TERRAIN.TOWN)
	agentmap.set_cellv(Vector2(20,20), Constants.AGENT.PEDESTRIAN)
	agentmap.set_cellv(Vector2(MAX-20,MAX-20), Constants.AGENT.PEDESTRIAN_G)
	
func camera_movement(delta):
	var mouse_position = get_global_mouse_position()
	var mouse_delta = mouse_position - global_position
	if (mouse_delta.length() >= MOUSE_CAM_RADIUS):
		position += (mouse_delta / MOUSE_CAM_RADIUS) * CAM_SPEED * delta

func _on_CreateMap_pressed():_preparation()
func _on_FindPath_pressed(): tilemap.breath_first_search()
func _on_Exit_pressed(): get_tree().change_scene("res://TitleScreen.tscn")

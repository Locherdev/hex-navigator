extends Node

enum TERRAIN { FOREST, GRAS, HILL, TOWN, WATER }
enum AGENT { PEDESTRIAN, BICYCLE, VEHICLE, BICYCLE_G, PEDESTRIAN_G, VEHICLE_G }

const creator_gras = Vector2(21,3)
const creator_hill = Vector2(22,3)
const creator_forest = Vector2(23,3)
const creator_town = Vector2(24,3)
const creator_water = Vector2(25,3)
const creator_clear = Vector2(21,6)
const creator_pedestrian = Vector2(22,6)
const creator_bicycle = Vector2(23,6)
const creator_vehicle = Vector2(24,6)
const creator_objects = [creator_gras, creator_hill, creator_forest, creator_town, creator_water, creator_clear, creator_pedestrian, creator_bicycle, creator_vehicle]

var route_pedestrian = false
var route_bicycle = false
var route_vehicle = false

func set_label(object: Object, text: String):
	object.text = text

func reset_route_results():
	route_pedestrian = false
	route_bicycle = false
	route_vehicle = false

func activate_route(agent: int):
	match agent:
		0: route_pedestrian = true
		1: route_bicycle = true
		2: route_vehicle = true
		_: print("Warning: activate_route() output = ",agent)

func route_result(agent: int, object: Object, distance: String):
	var agentName = ""
	match agent:
		0: 
			agentName = "Pedestrian"
			route_pedestrian = false
		1: 
			agentName = "Bicycle"
			route_bicycle = false
		2: 
			agentName = "Vehicle"
			route_vehicle = false
	object.text = agentName + ": Distance to goal is " + distance + "x tiles."

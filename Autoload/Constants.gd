extends Node

enum TERRAIN { FOREST, GRAS, HILL, TOWN, WATER }
enum AGENT { PEDESTRIAN, BICYCLE, VEHICLE, BICYCLE_G, PEDESTRIAN_G, VEHICLE_G }

const creator_gras = Vector2(21,3)
const creator_hill = Vector2(22,3)
const creator_forest = Vector2(23,3)
const creator_town = Vector2(24,3)
const creator_water = Vector2(25,3)
const creator_pedestrian = Vector2(22,6)
const creator_bicycle = Vector2(23,6)
const creator_vehicle = Vector2(24,6)
const creator_objects = [creator_gras, creator_hill, creator_forest, creator_town, creator_water, creator_pedestrian, creator_bicycle, creator_vehicle]

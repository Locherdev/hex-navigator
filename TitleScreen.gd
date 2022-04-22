extends Control

const normalOP = "res://World.tscn"
const stressedOP = "res://World_LARGE.tscn"

func _on_NormalOperation_pressed(): get_tree().change_scene(normalOP)
func _on_StressedOperation_pressed(): get_tree().change_scene(stressedOP)
func _on_Exit_pressed(): get_tree().quit()

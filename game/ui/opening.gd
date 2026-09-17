extends Control

signal opening_finished

const LINES: Array[String] = [
	"EXODUS YEAR 0",
	"ARKSHIPS: 6",
	"HUMAN POPULATION: 2,700,000",
	"ESTIMATED JOURNEY: 550 YEARS",
	"",
	"You will not reach the destination.",
	"Your descendants might.",
]

func _ready() -> void:
	_play()

func _play() -> void:
	await get_tree().create_timer(0.6).timeout
	for line in LINES:
		$Lines.text = line
		$Lines.visible = line != ""
		await get_tree().create_timer(1.1).timeout
	opening_finished.emit()

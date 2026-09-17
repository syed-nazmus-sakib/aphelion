class_name MigrationProjectile
extends RefCounted

var position: Vector2
var velocity: Vector2
var hostile: bool
var damage: float
var radius: float = 5.0
var expired: bool = false

func _init(origin: Vector2, direction: Vector2, is_hostile: bool, power: float = 1.0) -> void:
	position = origin
	velocity = direction
	hostile = is_hostile
	damage = power

func step(delta: float) -> void:
	position += velocity * delta
	expired = position.y < -40.0 or position.y > 840.0 or position.x < -40.0 or position.x > 1320.0

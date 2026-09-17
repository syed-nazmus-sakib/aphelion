class_name MigrationEnemy
extends RefCounted

enum Kind { DRONE, RAIDER, STRIKER, ELITE }
var kind: Kind
var position: Vector2
var origin: Vector2
var health: float
var age: float = 0.0
var cooldown: float = 1.8
var radius: float = 20.0
var alive: bool = true

func _init(type: Kind, start: Vector2) -> void:
	kind = type
	position = start
	origin = start
	health = [2.0, 3.0, 4.0, 32.0][kind]
	if kind == Kind.ELITE:
		radius = 44.0

func step(delta: float, target: Vector2) -> Array[MigrationProjectile]:
	age += delta
	cooldown -= delta
	match kind:
		Kind.DRONE:
			position = origin + Vector2(sin(age * 1.5) * 72.0, age * 20.0)
		Kind.RAIDER:
			position += Vector2(clampf(target.x - position.x, -130.0, 130.0), 48.0) * delta
		Kind.STRIKER:
			position += Vector2(sin(age * 3.0) * 60.0, 100.0) * delta
		Kind.ELITE:
			position = Vector2(640.0 + sin(age * 0.75) * 350.0, minf(180.0, origin.y + age * 90.0))
	var shots: Array[MigrationProjectile] = []
	if cooldown <= 0.0 and position.y > 20.0:
		cooldown = 1.0 if kind == Kind.ELITE else 2.6
		var direction: Vector2 = (target - position).normalized() * 230.0
		if kind == Kind.ELITE:
			for angle in [-0.45, -0.22, 0.0, 0.22, 0.45]:
				shots.append(MigrationProjectile.new(position, direction.rotated(angle), true))
		else:
			shots.append(MigrationProjectile.new(position, direction, true))
	return shots

func hit(power: float) -> bool:
	if not alive:
		return false
	health -= power
	alive = health > 0.0
	return not alive

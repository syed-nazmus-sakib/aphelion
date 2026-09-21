class_name MigrationInterceptor
extends RefCounted

var position: Vector2 = Vector2(640, 570)
var health: float = 8.0
var invulnerability: float = 0.0
var cooldown: float = 0.0
var boost_charge: float = 1.0
var fire_interval: float = 0.18

func step(delta: float, movement: Vector2, firing: bool, boosting: bool) -> Array[MigrationProjectile]:
	invulnerability = maxf(0.0, invulnerability - delta)
	cooldown -= delta
	var boost: bool = boosting and boost_charge > 0.0
	boost_charge = clampf(boost_charge + delta * (-0.8 if boost else 0.3), 0.0, 1.0)
	position += movement.limit_length() * (600.0 if boost else 330.0) * delta
	position = position.clamp(Vector2(24, 310), Vector2(1256, 650))
	var shots: Array[MigrationProjectile] = []
	if firing and cooldown <= 0.0 and health > 0.0:
		cooldown = fire_interval
		shots.append(MigrationProjectile.new(position + Vector2(0, -22), Vector2(0, -750), false))
	return shots

func hit() -> bool:
	if invulnerability > 0.0 or health <= 0.0:
		return false
	health -= 1.0
	invulnerability = 1.5
	return true

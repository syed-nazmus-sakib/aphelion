class_name CombatArena
extends Node2D

signal finished(result: CombatResult)

const ARENA_SIZE: Vector2 = Vector2(1280, 800)
const ARK_Y: float = 700.0

var player: MigrationInterceptor
var enemies: Array[MigrationEnemy] = []
var projectiles: Array[MigrationProjectile] = []
var waves: MigrationWaves
var wave_cooldown: float = 1.0
var elapsed: float = 0.0
var finished_flag: bool = false
var paused: bool = false
var breach_damage: float = 0.0
var kills: int = 0
var starting_hull: float
var rng: RandomNumberGenerator

func setup(hull: float, readiness: float, seed_value: int) -> void:
	player = MigrationInterceptor.new()
	player.fire_interval = maxf(0.1, 0.2 - readiness * 0.001)
	starting_hull = hull
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value

func _ready() -> void:
	if player == null:
		setup(100.0, 50.0, 1)

func step(delta: float, movement: Vector2, firing: bool, boosting: bool) -> void:
	if finished_flag or paused:
		return
	elapsed += delta
	_spawn_waves(delta)
	for shot in player.step(delta, movement, firing, boosting):
		projectiles.append(shot)
	var target: Vector2 = player.position
	for enemy in enemies:
		if not enemy.alive:
			continue
		for shot in enemy.step(delta, target):
			projectiles.append(shot)
	_step_projectiles(delta)
	_cleanup()
	_check_end()

func _spawn_waves(delta: float) -> void:
	if not waves:
		waves = MigrationWaves.new()
	wave_cooldown -= delta
	var living: int = 0
	for enemy in enemies:
		if enemy.alive:
			living += 1
	if living == 0 and wave_cooldown <= 0.0:
		if waves.index >= MigrationWaves.TOTAL:
			return
		for enemy in waves.next_wave():
			enemies.append(enemy)
		wave_cooldown = 3.0

func _step_projectiles(delta: float) -> void:
	for shot in projectiles:
		shot.step(delta)
		if shot.expired:
			continue
		if shot.hostile:
			if player.health > 0.0 and shot.position.distance_to(player.position) < 14.0:
				player.hit()
				shot.expired = true
			elif shot.position.y > ARK_Y:
				breach_damage += shot.damage * 0.2
				shot.expired = true
		elif player.health > 0.0:
			for enemy in enemies:
				if enemy.alive and shot.position.distance_to(enemy.position) < enemy.radius + 12.0:
					if enemy.hit(1.0):
						kills += 1
					shot.expired = true
					break

func _cleanup() -> void:
	var living: Array[MigrationEnemy] = []
	for enemy in enemies:
		if enemy.alive and enemy.position.y < ARK_Y + 30.0:
			living.append(enemy)
		elif enemy.alive:
			breach_damage += 2.5
	enemies = living
	var active: Array[MigrationProjectile] = []
	for shot in projectiles:
		if not shot.expired:
			active.append(shot)
	projectiles = active

func _check_end() -> void:
	if player != null and player.health <= 0.0:
		var total_breach: float = breach_damage + 6.0
		_finish(CombatResult.new(false, minf(100.0, total_breach), int(total_breach * 30.0), kills, int(kills * 6)))
		return
	if breach_damage > 0.0 and float(starting_hull) - breach_damage <= 0.0:
		_finish(CombatResult.new(false, minf(100.0, breach_damage), int(breach_damage * 30.0), kills, int(kills * 6)))
		return
	var living: int = 0
	for enemy in enemies:
		if enemy.alive:
			living += 1
	if waves and waves.index >= MigrationWaves.TOTAL and living == 0:
		_finish(CombatResult.new(true, breach_damage, int(breach_damage * 30.0), kills, int(kills * 6)))

func _finish(result: CombatResult) -> void:
	if finished_flag:
		return
	finished_flag = true
	finished.emit(result)

func apply_player_damage() -> void:
	if player.hit():
		if player.health <= 0.0:
			_finish(CombatResult.new(false, breach_damage + 8.0, int((breach_damage + 8.0) * 30.0), kills, int(kills * 6)))

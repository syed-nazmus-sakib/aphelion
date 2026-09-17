class_name MigrationWaves
extends RefCounted

const TOTAL: int = 4
var index: int = 0

func next_wave() -> Array[MigrationEnemy]:
	index += 1
	var enemies: Array[MigrationEnemy] = []
	for column in range(8):
		var kind: MigrationEnemy.Kind = MigrationEnemy.Kind.DRONE
		if index >= 2 and column % 3 == 0:
			kind = MigrationEnemy.Kind.RAIDER
		if index >= 3 and column % 3 == 1:
			kind = MigrationEnemy.Kind.STRIKER
		enemies.append(MigrationEnemy.new(kind, Vector2(210 + column * 120, -50 - (column % 2) * 60)))
	if index == TOTAL:
		enemies.append(MigrationEnemy.new(MigrationEnemy.Kind.ELITE, Vector2(640, -200)))
	return enemies

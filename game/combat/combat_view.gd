class_name CombatView
extends Node2D

signal combat_finished(result: CombatResult)
signal retreat_requested

const SIZE: Vector2 = Vector2(1280, 800)

var arena: CombatArena = null
var result: CombatResult = null
var over: bool = false

var stars_far: Array[Vector2] = []
var stars_mid: Array[Vector2] = []
var stars_near: Array[Vector2] = []
var explosions: Array = []
var flashes: Array = []
var shake: float = 0.0
var time: float = 0.0
var prev_enemy_count: int = 0
var prev_proj_count: int = 0
var blink: float = 0.0

var hud: CanvasLayer = null
var lbl_status: Label = null
var lbl_warn: Label = null
var lbl_hint: Label = null
var pause_panel: Control = null
var end_panel: Control = null
var end_title: Label = null
var end_body: Label = null

func setup(hull: float, readiness: float, seed_value: int) -> void:
	arena = CombatArena.new()
	arena.setup(hull, readiness, seed_value)
	add_child(arena)
	arena.finished.connect(_on_arena_finished)
	_seed_stars(seed_value)

func _ready() -> void:
	if arena == null:
		setup(100.0, 60.0, 1)
	_build_hud()
	set_process(true)

func _seed_stars(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	stars_far.clear()
	stars_mid.clear()
	stars_near.clear()
	for i in range(110):
		stars_far.append(Vector2(rng.randf() * SIZE.x, rng.randf() * SIZE.y))
	for i in range(70):
		stars_mid.append(Vector2(rng.randf() * SIZE.x, rng.randf() * SIZE.y))
	for i in range(36):
		stars_near.append(Vector2(rng.randf() * SIZE.x, rng.randf() * SIZE.y))

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	lbl_status = Label.new()
	lbl_status.position = Vector2(24, 12)
	lbl_status.add_theme_font_size_override("font_size", 17)
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.9, 0.94))
	hud.add_child(lbl_status)
	lbl_warn = Label.new()
	lbl_warn.position = Vector2(24, 38)
	lbl_warn.add_theme_font_size_override("font_size", 17)
	lbl_warn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	hud.add_child(lbl_warn)
	lbl_hint = Label.new()
	lbl_hint.anchor_left = 1.0
	lbl_hint.anchor_right = 1.0
	lbl_hint.offset_left = -560.0
	lbl_hint.offset_right = -24.0
	lbl_hint.offset_top = 12.0
	lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_hint.add_theme_font_size_override("font_size", 14)
	lbl_hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.72))
	lbl_hint.text = "WASD/Arrows move · Space/Mouse fire · Shift boost · Esc pause"
	hud.add_child(lbl_hint)
	pause_panel = _make_center_panel("PAUSED", "Esc to resume · combat time is frozen.")
	pause_panel.visible = false
	hud.add_child(pause_panel)
	end_panel = CenterContainer.new()
	end_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_panel.visible = false
	var inner := PanelContainer.new()
	inner.custom_minimum_size = Vector2(560, 0)
	end_panel.add_child(inner)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	inner.add_child(vb)
	end_title = Label.new()
	end_title.add_theme_font_size_override("font_size", 30)
	vb.add_child(end_title)
	end_body = Label.new()
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_body.custom_minimum_size = Vector2(520, 0)
	vb.add_child(end_body)
	var btn := Button.new()
	btn.text = "RETURN TO FLEET"
	btn.pressed.connect(func() -> void: combat_finished.emit(result))
	vb.add_child(btn)
	hud.add_child(end_panel)

func _make_center_panel(title: String, body: String) -> Control:
	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	var p := PanelContainer.new()
	wrap.add_child(p)
	var vb := VBoxContainer.new()
	p.add_child(vb)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	vb.add_child(t)
	var b := Label.new()
	b.text = body
	vb.add_child(b)
	return wrap

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if over:
			return
		arena.paused = not arena.paused
		pause_panel.visible = arena.paused
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if arena == null:
		return
	time += delta
	blink += delta
	if not over and not arena.paused and not arena.finished_flag:
		var mv := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			mv.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			mv.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			mv.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			mv.y += 1.0
		var firing: bool = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var boosting: bool = Input.is_physical_key_pressed(KEY_SHIFT)
		var kills_before: int = arena.kills
		var breach_before: float = arena.breach_damage
		var php_before: float = arena.player.health
		arena.step(delta, mv, firing, boosting)
		if arena.kills > kills_before:
			var dead_pos := _last_kill_pos()
			_spawn_explosion(dead_pos, 34.0)
			shake = minf(1.0, shake + 0.25)
		if arena.breach_damage > breach_before:
			_spawn_flash(Vector2(arena.player.position.x, 700.0))
			shake = minf(1.0, shake + 0.35)
		if arena.player.health < php_before:
			_spawn_explosion(arena.player.position, 26.0)
			shake = minf(1.0, shake + 0.5)
	# ambient star scroll + shake decay even when paused (subtle)
	_scroll_stars(delta * (0.0 if arena.paused else 1.0))
	shake = maxf(0.0, shake - delta * 1.6)
	_tick_fx(delta)
	_update_hud()
	queue_redraw()

func _last_kill_pos() -> Vector2:
	# approximate: use newest explosion anchor near player shots; fallback to player aim point
	return arena.player.position + Vector2(0, -180)

func _scroll_stars(scale: float) -> void:
	for i in range(stars_far.size()):
		stars_far[i].y += 12.0 * scale * get_process_delta_time()
		if stars_far[i].y > SIZE.y:
			stars_far[i].y = 0.0
	for i in range(stars_mid.size()):
		stars_mid[i].y += 30.0 * scale * get_process_delta_time()
		if stars_mid[i].y > SIZE.y:
			stars_mid[i].y = 0.0
	for i in range(stars_near.size()):
		stars_near[i].y += 70.0 * scale * get_process_delta_time()
		if stars_near[i].y > SIZE.y:
			stars_near[i].y = 0.0

func _spawn_explosion(pos: Vector2, size: float) -> void:
	explosions.append({"pos": pos, "age": 0.0, "life": 0.55, "size": size})
	flashes.append({"pos": pos, "age": 0.0, "life": 0.18})

func _spawn_flash(pos: Vector2) -> void:
	flashes.append({"pos": pos, "age": 0.0, "life": 0.25})

func _tick_fx(delta: float) -> void:
	for i in range(explosions.size() - 1, -1, -1):
		explosions[i]["age"] = float(explosions[i]["age"]) + delta
		if float(explosions[i]["age"]) >= float(explosions[i]["life"]):
			explosions.remove_at(i)
	for i in range(flashes.size() - 1, -1, -1):
		flashes[i]["age"] = float(flashes[i]["age"]) + delta
		if float(flashes[i]["age"]) >= float(flashes[i]["life"]):
			flashes.remove_at(i)

func _update_hud() -> void:
	if arena == null or arena.player == null:
		return
	var wave_no: int = mini(arena.waves.index + 1 if arena.waves else 1, 4)
	var living: int = 0
	for e in arena.enemies:
		if e.alive:
			living += 1
	lbl_status.text = "HULL %.0f  ·  WAVE %d/4  ·  HOSTILES %d  ·  KILLS %d  ·  INTERCEPTOR %d  ·  BOOST %d%%" % [
		maxf(0.0, arena.starting_hull - arena.breach_damage),
		wave_no, living, arena.kills,
		maxi(0, int(arena.player.health)), int(arena.player.boost_charge * 100.0)]
	var threat: bool = false
	for e in arena.enemies:
		if e.alive and e.position.y > 480.0:
			threat = true
			break
	if not threat:
		for s in arena.projectiles:
			if s.hostile and s.position.y > 600.0:
				threat = true
				break
	if threat and fmod(blink, 0.8) < 0.5:
		lbl_warn.text = "!! ARKSHIP THREAT — INTERCEPT !!"
	else:
		lbl_warn.text = ""

func _on_arena_finished(r: CombatResult) -> void:
	if over:
		return
	over = true
	result = r
	_spawn_explosion(arena.player.position, 60.0)
	end_title.text = "ARKSHIP HELD" if r.victory else "LINE BROKEN"
	end_title.add_theme_color_override("font_color", Color(0.55, 0.95, 0.75) if r.victory else Color(1.0, 0.5, 0.45))
	end_body.text = "Kills %d · Hull damage %.1f · Casualties %d · Salvage %d materials.\nThe fleet remembers." % [r.kills, r.hull_damage, r.casualties, r.salvage]
	end_panel.visible = true

func _draw() -> void:
	var off := Vector2.ZERO
	if shake > 0.01:
		off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 9.0
	draw_set_transform(off, 0.0, Vector2.ONE)
	# background
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.012, 0.02, 0.045))
	# radar grid (subtle)
	for gx in range(0, 1281, 160):
		draw_line(Vector2(gx, 0) + off * 0.0, Vector2(gx, SIZE.y), Color(0.1, 0.16, 0.24, 0.35), 1.0)
	for gy in range(0, 801, 160):
		draw_line(Vector2(0, gy), Vector2(SIZE.x, gy), Color(0.1, 0.16, 0.24, 0.3), 1.0)
	# stars
	for s in stars_far:
		draw_circle(s, 1.2, Color(0.5, 0.6, 0.75, 0.6))
	for s in stars_mid:
		draw_circle(s, 1.8, Color(0.65, 0.75, 0.88, 0.8))
	for s in stars_near:
		draw_circle(s, 2.4, Color(0.85, 0.92, 1.0))
	# defensive line
	draw_dashed_line(Vector2(0, 660), Vector2(SIZE.x, 660), Color(0.3, 0.7, 0.8, 0.4), 2.0, 12.0)
	_draw_arkship()
	_draw_enemies()
	_draw_projectiles()
	_draw_player()
	# fx
	for f in flashes:
		var t: float = 1.0 - float(f["age"]) / float(f["life"])
		draw_circle(f["pos"], 26.0 * t + 8.0, Color(1.0, 0.85, 0.5, 0.5 * t))
	for e in explosions:
		var k: float = float(e["age"]) / float(e["life"])
		var radius: float = float(e["size"]) * (0.4 + k)
		draw_arc(e["pos"], radius, 0.0, TAU, 24, Color(1.0, 0.6, 0.3, 0.8 * (1.0 - k)), 3.0)
		draw_circle(e["pos"], radius * 0.4 * (1.0 - k), Color(1.0, 0.8, 0.55, 0.6 * (1.0 - k)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_arkship() -> void:
	var y0: float = 700.0
	var hull_frac: float = 1.0
	if arena != null:
		hull_frac = clampf((arena.starting_hull - arena.breach_damage) / maxf(1.0, arena.starting_hull), 0.0, 1.0)
	# main hull bar
	draw_rect(Rect2(Vector2(40, y0 + 52), Vector2(1200 * hull_frac, 10)), Color(0.35, 0.8, 0.85))
	draw_rect(Rect2(Vector2(40, y0 + 52), Vector2(1200, 10)), Color(0.4, 0.5, 0.6, 0.5), false, 1.0)
	# hull body: elongated ark silhouette
	var pts := PackedVector2Array([
		Vector2(240, y0 + 10), Vector2(400, y0), Vector2(880, y0),
		Vector2(1040, y0 + 10), Vector2(1040, y0 + 34), Vector2(880, y0 + 44),
		Vector2(400, y0 + 44), Vector2(240, y0 + 34)])
	draw_colored_polygon(pts, Color(0.13, 0.2, 0.3))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.75, 0.85, 0.8), 2.0)
	# district lights
	for i in range(7):
		var dx: float = 420.0 + i * 60.0
		var on: float = 0.5 + 0.5 * sin(time * 2.0 + i)
		draw_circle(Vector2(dx, y0 + 22), 5.0, Color(0.55, 0.9, 0.95, 0.35 + 0.4 * on))
	var lbl := "ASTERIA — HULL %d%%" % int(hull_frac * 100.0)
	draw_string(ThemeDB.fallback_font, Vector2(40, y0 + 44), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 0.82, 0.9))

func _draw_player() -> void:
	if arena == null or arena.player == null:
		return
	var p := arena.player.position
	if arena.player.health <= 0.0:
		return
	# invulnerability blink
	if arena.player.invulnerability > 0.0 and fmod(blink * 12.0, 2.0) < 1.0:
		return
	# engine glow
	draw_circle(p + Vector2(0, 14), 9.0, Color(0.3, 0.7, 1.0, 0.35))
	var body := PackedVector2Array([p + Vector2(0, -18), p + Vector2(-13, 12), p + Vector2(0, 5), p + Vector2(13, 12)])
	draw_colored_polygon(body, Color(0.75, 0.92, 1.0))
	draw_polyline(body + PackedVector2Array([body[0]]), Color(0.2, 0.5, 0.7), 2.0)
	# boost trail
	if arena.player.boost_charge < 0.99:
		draw_line(p + Vector2(0, 14), p + Vector2(0, 34), Color(0.4, 0.8, 1.0, 0.5), 3.0)
	# health pips
	for i in range(int(arena.player.health)):
		draw_circle(Vector2(p.x - 18.0 + i * 9.0, p.y + 24.0), 3.0, Color(0.5, 0.95, 0.7))

func _draw_enemies() -> void:
	if arena == null:
		return
	for e in arena.enemies:
		if not e.alive:
			continue
		match e.kind:
			MigrationEnemy.Kind.DRONE:
				_diamond(e.position, 16.0, Color(1.0, 0.45, 0.4), Color(0.5, 0.1, 0.1))
			MigrationEnemy.Kind.RAIDER:
				_arrow(e.position, 17.0, Color(1.0, 0.6, 0.25))
			MigrationEnemy.Kind.STRIKER:
				_needle(e.position, Color(1.0, 0.3, 0.55))
			MigrationEnemy.Kind.ELITE:
				_hex(e.position, 40.0, Color(0.9, 0.25, 0.5), e.health / 16.0)

func _diamond(pos: Vector2, r: float, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r, 0), pos + Vector2(0, r), pos + Vector2(-r, 0)])
	draw_colored_polygon(pts, fill.darkened(0.35))
	draw_polyline(pts + PackedVector2Array([pts[0]]), edge, 2.0)
	draw_circle(pos, 3.5, Color(1.0, 0.9, 0.8))

func _arrow(pos: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([pos + Vector2(0, r), pos + Vector2(-r, -r * 0.6), pos + Vector2(0, -r * 0.3), pos + Vector2(r, -r * 0.6)])
	draw_colored_polygon(pts, col.darkened(0.4))
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, 2.0)

func _needle(pos: Vector2, col: Color) -> void:
	var pts := PackedVector2Array([pos + Vector2(0, 18), pos + Vector2(-7, -12), pos + Vector2(0, -18), pos + Vector2(7, -12)])
	draw_colored_polygon(pts, col.darkened(0.3))
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, 2.0)
	# warning glow when diving low
	if pos.y > 480.0:
		draw_arc(pos, 24.0, 0.0, TAU, 20, Color(1.0, 0.3, 0.3, 0.7), 2.0)

func _hex(pos: Vector2, r: float, col: Color, frac: float) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a: float = TAU * i / 6.0 + 0.3
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col.darkened(0.45))
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, 3.0)
	draw_circle(pos, 8.0, Color(1.0, 0.8, 0.85))
	# health bar
	draw_rect(Rect2(pos + Vector2(-40, -58), Vector2(80 * clampf(frac, 0.0, 1.0), 6)), Color(1.0, 0.35, 0.5))
	draw_rect(Rect2(pos + Vector2(-40, -58), Vector2(80, 6)), Color(1, 1, 1, 0.4), false, 1.0)

func _draw_projectiles() -> void:
	if arena == null:
		return
	for s in arena.projectiles:
		if s.expired:
			continue
		if s.hostile:
			draw_line(s.position - s.velocity.normalized() * 14.0, s.position, Color(1.0, 0.45, 0.3), 3.0)
			draw_circle(s.position, 4.0, Color(1.0, 0.7, 0.4))
		else:
			draw_line(s.position - s.velocity.normalized() * 20.0, s.position, Color(0.45, 0.9, 1.0, 0.9), 3.0)
			draw_circle(s.position, 3.0, Color(0.8, 1.0, 1.0))

extends Control

const BG = Color("17132f")
const PAPER = Color("ffedc1")
const INK = Color("2c1c32")
const MUTED = Color("785367")
const GREEN = Color("7237ba")
const DARK_GREEN = Color("623094")
const SAGE = Color("c5a3e8")
const CLAY = Color("a55245")
const PEACH = Color("ffe4a5")
const LINE = Color("3c2143")
const GOLD = Color("ffc54e")
const BODY = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const HEADING = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const LOGO_FONT = preload("res://assets/fonts/Logo.tres")
const NIGHT = preload("res://assets/art/night-library-web.png")
const UI_ATLAS = preload("res://assets/atlases/game-atlas.png")
const ICON_ATLAS = preload("res://assets/atlases/game-atlas.png")
const AVATAR_ATLAS = preload("res://assets/atlases/game-atlas.png")
const DECOR_ATLAS = preload("res://assets/atlases/game-atlas.png")
const Surface = preload("res://scripts/png_surface.gd")
var regions: Dictionary = {}
var texture_cache: Dictionary = {}
var skin_cache: Dictionary = {}
var profile_accent = 0

var page: Control
var modal: Control
var screen = "loading"
var category = "Mutfak"
var mode = "solo"
var level_index = 0
var step = 1
var typed = ""
var fixed: Dictionary = {0: true}
var hint_open = false
var input_locked = false
var coins_label: Label
var slots: Control
var feedback: Label
var balance_label: Label
var name_field: LineEdit
var name_preview: Label
var avatar_choice = 0
var edit_profile = false
var tutorial = false
var party_names: Array[String] = []
var party_scores: Array[int] = [0, 0]
var party_turn = 0
var party_round = 0
var time_left = 60
var turn_score = 0
var race_score = 0
var ghost_score = 0
var clock_label: Label
var race_label: Label
var round_timer: Timer
var rng = RandomNumberGenerator.new()
var sound_player: AudioStreamPlayer
var sounds: Dictionary = {}
var save_timer: Timer
var screen_generation = 0

func _ready() -> void:
	rng.randomize()
	regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/atlases/regions.json"))
	Engine.max_fps = 60
	OS.low_processor_usage_mode = true
	get_tree().auto_accept_quit = true
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	for pair in [["tap", 520.0, 0.035], ["correct", 780.0, 0.14], ["wrong", 180.0, 0.12]]:
		sounds[pair[0]] = _tone(pair[1], pair[2])
	round_timer = Timer.new()
	round_timer.wait_time = 1.0
	round_timer.timeout.connect(_tick)
	add_child(round_timer)
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.4
	save_timer.timeout.connect(func(): Profile.save())
	add_child(save_timer)
	show_loading()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST] and is_instance_valid(save_timer):
		Profile.save()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)

func atlas(group: String, index: int) -> AtlasTexture:
	var key = group + str(index)
	if texture_cache.has(key):
		return texture_cache[key]
	var source = {"surfaces": UI_ATLAS, "icons": ICON_ATLAS, "avatars": AVATAR_ATLAS, "decor": DECOR_ATLAS, "categories": ICON_ATLAS, "keys": UI_ATLAS}[group]
	var region = regions[group][index]
	var texture = AtlasTexture.new()
	texture.atlas = source
	texture.region = Rect2(region[0], region[1], region[2], region[3])
	texture.filter_clip = true
	texture_cache[key] = texture
	return texture

func png_skin(index: int) -> StyleBoxTexture:
	if skin_cache.has(index):
		return skin_cache[index]
	var skin = StyleBoxTexture.new()
	skin.texture = atlas("surfaces", index) if index < 4 else atlas("keys", index - 4)
	skin.set_meta("source_scale", 3.0 if index < 4 else 6.0)
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skin.set_texture_margin(edge, 72 if index >= 4 else 54 if index == 0 else 42)
	skin_cache[index] = skin
	return skin

func logo(y: float, second_color: Color = GOLD) -> void:
	var first = label("Sözden", 38, y, 404, 95, 67, PAPER, true)
	first.add_theme_font_override("font", LOGO_FONT)
	first.add_theme_constant_override("outline_size", 16)
	first.add_theme_color_override("font_outline_color", BG)
	first.rotation = -0.045
	var second = label("Söze", 60, y + 83, 365, 101, 77, second_color, true)
	second.add_theme_font_override("font", LOGO_FONT)
	second.add_theme_constant_override("outline_size", 16)
	second.add_theme_color_override("font_outline_color", BG)
	second.rotation = -0.045
	picture(atlas("decor", 2), 190, y + 184, 100, 64)

func _tone(hz: float, duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples = PackedByteArray()
	var count = int(22050 * duration)
	samples.resize(count * 2)
	for i in count:
		var envelope = sin(PI * float(i) / count) * 0.12
		samples.encode_s16(i * 2, int(sin(TAU * hz * i / 22050) * 32760 * envelope))
	stream.data = samples
	return stream

func sound(which: String) -> void:
	if Profile.data.sound:
		sound_player.stream = sounds[which]
		sound_player.play()

func rect(node: Control, x: float, y: float, w: float, h: float, parent: Node = null) -> Control:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)
	(parent if parent != null else page).add_child(node)
	return node

func style(color: Color, border: Color = LINE, radius: int = 18, shadow: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.28, 0.24, 0.16, 0.10)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, 3)
	return s

func panel(x: float, y: float, w: float, h: float, color: Color = PAPER, parent: Node = null, _radius: int = 18) -> Panel:
	var p = Surface.new()
	var skin_index = 3 if color == SAGE else 1 if color == GREEN or color == BG else 0
	if w <= 60 and h <= 70:
		skin_index = 5 if color == SAGE else 4
	p.skin = png_skin(skin_index)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect(p, x, y, w, h, parent)
	return p

func label(text: String, x: float, y: float, w: float, h: float, font_size: int = 18, color: Color = INK, center: bool = false, title: bool = false, parent: Node = null) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", HEADING if title else BODY)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect(l, x, y, w, h, parent)
	return l

func paragraph(text: String, x: float, y: float, w: float, h: float, font_size: int = 17, color: Color = MUTED, center: bool = true, parent: Node = null) -> Label:
	var l = label(text, x, y, w, h, font_size, color, center, false, parent)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func icon(kind: String, x: float, y: float, s: float = 26, _color: Color = DARK_GREEN, parent: Node = null) -> Control:
	var map = {"back":0, "home":1, "book":2, "leaf":3, "cup":4, "people":5, "user":6, "check":7, "arrow":8, "lock":9, "coin":10, "bulb":11, "trophy":12, "gear":13, "star":14, "chat":15, "delete":0}
	if kind in ["paw", "globe", "box", "crown"]:
		return picture(atlas("categories", ["paw", "globe", "box", "crown"].find(kind)), x, y, s, s, parent)
	if kind == "party":
		return picture(atlas("decor", 3), x, y, s, s, parent)
	if kind == "chain":
		return picture(atlas("decor", 2), x, y, s, s, parent)
	return picture(atlas("icons", map.get(kind, 2)), x, y, s, s, parent)

func picture(texture: Texture2D, x: float, y: float, w: float, h: float, parent: Node = null) -> TextureRect:
	var p = TextureRect.new()
	p.texture = texture
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect(p, x, y, w, h, parent)
	return p

func button(text: String, x: float, y: float, w: float, h: float, action: Callable, color: Color = GREEN, parent: Node = null, small: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font", BODY)
	b.add_theme_font_size_override("font_size", 20 if small else 24)
	var text_color = PAPER if color == GREEN or color == BG or color == CLAY else INK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, text_color)
	b.add_theme_color_override("font_disabled_color", MUTED)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		sound("tap")
		action.call()
	)
	rect(b, x, y, w, h, parent)
	var surface = Surface.new()
	surface.name = "Surface"
	var skin_index = 1 if color == GREEN or color == BG or color == CLAY else 3 if color == SAGE else 2
	if w < 90 and h < 61:
		skin_index = 5 if color == SAGE else 4
	surface.skin = png_skin(skin_index)
	surface.show_behind_parent = true
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect(surface, 0, 0, w, h, b)
	b.button_down.connect(func(): surface.self_modulate = Color(0.83, 0.79, 0.95))
	b.button_up.connect(func(): surface.self_modulate = Color.WHITE)
	b.mouse_entered.connect(func(): surface.self_modulate = Color(1.08, 1.04, 1.12))
	b.mouse_exited.connect(func(): surface.self_modulate = Color.WHITE)
	return b

func text_button(text: String, x: float, y: float, w: float, h: float, action: Callable, parent: Node = null) -> Button:
	var b = button(text, x, y, w, h, action, BG, parent, true)
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", MUTED)
	b.get_node("Surface").hide()
	return b

func clear(next_screen: String) -> void:
	screen_generation += 1
	if is_instance_valid(page):
		page.hide()
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.queue_free()
	if is_instance_valid(modal):
		modal.queue_free()
	modal = null
	screen = next_screen
	page = Control.new()
	page.size = Vector2(480, 900)
	add_child(page)
	var background = picture(NIGHT, 0, 0, 480, 900)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if next_screen in ["levels", "together", "party_setup", "party_handoff", "race_lobby", "profile", "party_result", "race_result", "countdown"]:
		panel(22, 90, 436, 710)
	elif next_screen == "game":
		panel(20, 128, 440, 568)
		panel(9, 698, 462, 196, BG)
	coins_label = null
	feedback = null
	if Profile.data.motion:
		page.modulate.a = 0
		create_tween().bind_node(page).tween_property(page, "modulate:a", 1.0, 0.18)
	queue_redraw()

func header(title_text: String, back: Callable = show_home) -> void:
	panel(15, 20, 450, 62)
	button("", 24, 28, 46, 46, back, PAPER)
	icon("back", 35, 39, 24)
	label(title_text, 82, 28, 245, 46, 22, INK, false, true)
	coin_pill(348, 30)

func coin_pill(x: float, y: float) -> void:
	panel(x, y, 108, 42, Color("f5e8c9"), null, 21)
	icon("coin", x + 11, y + 9, 24, GOLD)
	coins_label = label(str(Profile.data.gold), x + 43, y + 3, 57, 36, 18, INK, true)

func nav(selected: String) -> void:
	panel(15, 811, 450, 73, PAPER, null, 23)
	var tabs = [["home", "Ana Sayfa", show_home], ["book", "Bölümler", show_levels], ["people", "Birlikte", show_together], ["user", "Profilim", show_profile_page]]
	for i in tabs.size():
		var x = 22 + i * 111
		var chosen = tabs[i][0] == selected
		if chosen:
			panel(x + 19, 819, 65, 33, SAGE, null, 15)
		text_button("", x, 816, 106, 63, tabs[i][2])
		icon(tabs[i][0], x + 39, 822, 25, DARK_GREEN if chosen else MUTED)
		label(tabs[i][1], x, 852, 106, 23, 13, DARK_GREEN if chosen else MUTED, true)

func show_loading() -> void:
	clear("loading")
	logo(232, Color("c6a0f0"))
	var bar = Surface.new()
	bar.skin = png_skin(6)
	rect(bar, 90, 812, 300, 28)
	var progress = Control.new()
	progress.clip_contents = true
	rect(progress, 90, 812, 0, 28)
	var fill = Surface.new()
	fill.skin = png_skin(7)
	rect(fill, 0, 0, 300, 28, progress)
	label("Yükleniyor…", 40, 848, 400, 32, 21, PAPER, true)
	var t = create_tween().bind_node(page)
	t.tween_property(progress, "size:x", 300.0, 1.2)
	t.tween_callback(func():
		if Profile.data.name.is_empty():
			show_create_profile()
		elif not Profile.data.get("profile_ready", false):
			show_avatar_select()
		elif not Profile.data.tutorial:
			start_tutorial()
		else:
			show_home()
	)

func show_create_profile(edit: bool = false) -> void:
	clear("create_profile")
	edit_profile = edit
	avatar_choice = Profile.data.avatar
	panel(38, 190, 404, 421)
	label("Profilini Düzenle" if edit else "Hoş Geldin!", 58, 225, 364, 65, 42, INK, true, true)
	paragraph("Oyuna başlamak için\nadını yaz.", 70, 310, 340, 72, 25, INK)
	name_field = field(Profile.data.name, "Kullanıcı adın…", 72, 411, 336, 61, 16)
	name_field.focus_entered.connect(show_name_keyboard)
	name_field.text_submitted.connect(func(_value): _save_name())
	name_field.text_changed.connect(func(value):
		if is_instance_valid(name_preview):
			name_preview.text = value if not value.is_empty() else "Adın burada görünecek"
	)
	feedback = label("", 55, 479, 370, 34, 18, CLAY, true)
	button("Devam Et", 72, 528, 336, 62, _save_name)
	picture(atlas("decor", 0), 55, 625, 370, 259)

func field(value: String, placeholder: String, x: float, y: float, w: float, h: float, max_length: int = 16, parent: Node = null) -> LineEdit:
	var f = LineEdit.new()
	f.text = value
	f.placeholder_text = placeholder
	f.max_length = max_length
	f.virtual_keyboard_enabled = false
	f.add_theme_font_override("font", BODY)
	f.add_theme_font_size_override("font_size", 22)
	f.add_theme_color_override("font_color", INK)
	f.add_theme_color_override("caret_color", GREEN)
	f.add_theme_color_override("font_placeholder_color", MUTED)
	var box = StyleBoxEmpty.new()
	box.content_margin_left = 18
	box.content_margin_right = 18
	f.add_theme_stylebox_override("normal", box)
	f.add_theme_stylebox_override("focus", box)
	rect(f, x, y, w, h, parent)
	var background = Surface.new()
	background.skin = png_skin(4)
	background.show_behind_parent = true
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect(background, 0, 0, w, h, f)
	return f

func _save_name() -> void:
	var value = name_field.text.strip_edges()
	if not WordRules.valid_name(value):
		feedback.text = "2–16 harf kullan; sayı ve simge ekleme."
		return
	Profile.data.name = value
	show_avatar_select(edit_profile)

func show_avatar_select(edit: bool = false) -> void:
	clear("avatar_select")
	edit_profile = edit
	panel(36, 94, 408, 708)
	label("Profilini Oluştur", 50, 122, 380, 62, 38, INK, true, true)
	label("Sana en uygun avatarı seç.", 50, 188, 380, 35, 22, INK, true)
	for i in 9:
		var x = 74 + (i % 3) * 111
		var y = 243 + (i / 3) * 112
		var b = button("", x, y, 104, 104, func():
			avatar_choice = i
			Profile.data.avatar = i
			show_avatar_select(edit)
		, SAGE if avatar_choice == i else PAPER)
		picture(atlas("avatars", i), 6, 6, 92, 92, b)
		if i == avatar_choice:
			icon("check", 76, 76, 24, PAPER, b)
	label("Rengini Seç", 55, 591, 370, 40, 28, INK, true, true)
	var colors = [Color("a16aef"), GOLD, Color("dec8f2"), Color("f29a73")]
	for i in 4:
		var x = 91 + i * 81
		var b = button("", x, 649, 54, 48, func():
			profile_accent = i
			Profile.data.accent = i
			show_avatar_select(edit)
		, SAGE if int(Profile.data.get("accent", 1)) == i else PAPER)
		var swatch = picture(atlas("icons", 10), 8, 5, 38, 38, b)
		swatch.self_modulate = colors[i]
	button("Kaydet" if edit else "Başla", 72, 724, 336, 62, func():
		Profile.data.avatar = avatar_choice
		Profile.data.profile_ready = true
		Profile.save()
		if edit:
			show_profile_page()
		else:
			start_tutorial()
	)

func show_home() -> void:
	round_timer.stop()
	tutorial = false
	clear("home")
	button("", 27, 26, 62, 62, show_profile_page, PAPER)
	avatar(33, 32, 50)
	label(Profile.data.name, 105, 34, 190, 43, 24, PAPER)
	coin_pill(298, 36)
	button("", 416, 34, 43, 43, show_profile_page, PAPER)
	icon("gear", 423, 41, 29)
	var accent = [Color("c399f4"), GOLD, Color("dec8f2"), Color("ffad78")][int(Profile.data.get("accent", 1))]
	logo(171, accent)
	var items = [["Tek Oyunculu", "user", func(): start_level(Profile.next_level())], ["Çok Oyunculu", "people", show_race_lobby], ["Parti Modu", "party", show_party_setup]]
	for i in items.size():
		var y = 481 + i * 95
		button(items[i][0], 40, y, 400, 77, items[i][2], PAPER)
		icon(items[i][1], 65, y + 20, 37)
	button("Kategoriler", 40, 794, 194, 77, show_categories, BG)
	button("Ayarlar", 246, 794, 194, 77, show_profile_page, BG)
	icon("book", 57, 811, 30)
	icon("gear", 267, 811, 30)

func avatar(x: float, y: float, s: float, parent: Node = null) -> void:
	picture(atlas("avatars", int(Profile.data.avatar)), x, y, s, s, parent)

func show_categories() -> void:
	clear("categories")
	header("Kategoriler")
	panel(26, 109, 428, 676)
	label("Kelimelerin dünyasına gir.", 47, 136, 386, 43, 26, INK, true, true)
	var categories = [["Hepsi", "Tüm kelimeler", "chain"], ["Günlük Yaşam", "Ev, okul, küçük hikâyeler…", "home"], ["Mutfak", "Yemekler, içecekler…", "cup"], ["Hayvanlar", "Patiler, kanatlar, dostlarımız…", "paw"], ["Ülkeler & Şehirler", "Yollar, şehirler, meydanlar…", "globe"], ["Eşyalar", "Ev eşyaları, araçlar…", "box"], ["Doğa", "Bitkiler, hava durumu…", "leaf"]]
	for i in categories.size():
		var row = categories[i]
		var y = 197 + i * 79
		button("", 43, y, 394, 71, func():
			category = row[0]
			show_levels()
		, PAPER)
		icon(row[2], 57, y + 16, 38)
		label("Yiyecek & İçecek" if row[0] == "Mutfak" else row[0], 111, y + 5, 309, 32, 25)
		label(row[1], 111, y + 34, 306, 29, 17, MUTED)
	nav("book")

func show_levels() -> void:
	round_timer.stop()
	clear("levels")
	header("Kelime yolculuğu")
	paragraph("Her bölüm yeni bir bağlantı.\nBir öncekini tamamla, sıradaki açılsın.", 35, 95, 410, 62)
	var cats = ["Mutfak", "Doğa", "Günlük Yaşam"]
	for i in 3:
		button(cats[i], 25 + i * 147, 180, 137, 46, func():
			category = cats[i]
			show_levels()
		, GREEN if category == cats[i] else PAPER, null, true)
	icon("cup" if category == "Mutfak" else "leaf" if category == "Doğa" else "home", 30, 253, 30)
	label(category + " hikâyeleri", 73, 248, 335, 40, 25, INK, false, true)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rect(scroll, 24, 308, 432, 475)
	var content = Control.new()
	content.custom_minimum_size = Vector2(418, 8 * 91)
	scroll.add_child(content)
	var row = 0
	for i in Profile.levels.size():
		var level = Profile.levels[i]
		if category != "Hepsi" and level.category != category:
			continue
		var complete = level.id in Profile.data.completed
		var unlocked = Profile.unlock(i)
		var y = row * 91
		button("", 4, y + 4, 410, 78, func():
			if unlocked:
				start_level(i)
			else:
				toast("Önce bir önceki bölümü tamamla.")
		, PAPER if unlocked else Color("eee9df"), content)
		panel(18, y + 18, 48, 48, SAGE if complete else PEACH, content, 15)
		if unlocked and not complete:
			label("%02d" % [i + 1], 18, y + 21, 48, 41, 20, CLAY, true, false, content)
		else:
			icon("check" if complete else "lock", 30, y + 29, 24, DARK_GREEN if complete else MUTED, content)
		label(level.title, 83, y + 12, 305, 33, 17, INK if unlocked else MUTED, false, false, content)
		label("Tamamlandı  ·  +25 altın" if complete else "%d kelime  ·  +25 altın" % level.words.size(), 83, y + 44, 290, 25, 13, MUTED, false, false, content)
		row += 1
	nav("book")

func start_tutorial() -> void:
	tutorial = true
	mode = "tutorial"
	level_index = 0
	step = 1
	typed = ""
	fixed = {0: true}
	hint_open = true
	show_game()

func start_level(index: int) -> void:
	tutorial = false
	mode = "solo"
	level_index = index
	step = 1
	typed = ""
	fixed = {0: true}
	hint_open = false
	var state = Profile.data.active.get(Profile.levels[index].id, {})
	if state is Dictionary and int(state.get("step", 1)) >= 1 and int(state.get("step", 1)) < Profile.levels[index].words.size():
		step = int(state.get("step", 1))
		typed = str(state.get("typed", ""))
		fixed = {0: true}
		for key in state.get("fixed", [0]):
			var pos = int(key)
			if pos >= 0 and pos < current_word().length():
				fixed[pos] = true
		hint_open = bool(state.get("hint", false))
	show_game()

func current_level() -> Dictionary:
	return Profile.levels[level_index]

func current_word() -> String:
	return current_level().words[step]

func persist_active() -> void:
	if mode != "solo":
		return
	Profile.data.active[current_level().id] = {"step": step, "fixed": fixed.keys(), "typed": typed, "hint": hint_open}
	save_timer.start()

func show_game() -> void:
	input_locked = false
	clear("game")
	header("İlk kelimelerin" if tutorial else "Bölüm %02d" % [level_index + 1], leave_game)
	var status_strip = Surface.new()
	status_strip.skin = png_skin(4)
	rect(status_strip, 24, 85, 432, 60 if mode == "race" else 39)
	if mode == "party":
		label("%s  ·  Tur %d / 3" % [party_names[party_turn], party_round + 1], 30, 86, 315, 33, 20, INK)
		clock_label = label("%d sn" % time_left, 344, 87, 100, 33, 22, CLAY, true)
	elif mode == "race":
		label("ANTRENMAN · YEREL DEMO", 28, 87, 285, 27, 15, INK)
		clock_label = label("%d sn" % time_left, 349, 85, 97, 33, 22, GOLD, true)
		race_label = label("Sen: %d  ·  Tilki: %d" % [race_score, ghost_score], 30, 115, 338, 29, 18, DARK_GREEN)
		text_button("Mesaj", 375, 113, 75, 30, show_messages)
	else:
		label("ÖĞRETİCİ" if tutorial else current_level().category.to_upper(), 40, 88, 285, 28, 17, INK)
		label("%d / %d bağlantı" % [step, current_level().words.size() - 1], 298, 88, 142, 28, 17, INK, true)
	label(current_level().title, 29, 146, 422, 39, 25, INK, true, true)
	var y_start = 204
	var words = current_level().words
	var card_h = 48 if words.size() == 5 else 66
	var gap = 16 if words.size() == 5 else 22
	for i in words.size():
		var y = y_start + i * (card_h + gap)
		var active = i == step
		panel(48, y, 384, card_h, SAGE if i <= step else PAPER, null, 15)
		if i < step:
			label(words[i], 84, y + 4, 302, card_h - 8, 24, DARK_GREEN, true)
			icon("check", 397, y + card_h / 2 - 11, 22, DARK_GREEN)
		elif active:
			slots = Control.new()
			rect(slots, 64, y + 8, 352, card_h - 16)
			_draw_slots()
		else:
			label(words[i][0] + "  " + "· ".repeat(words[i].length() - 1).strip_edges(), 75, y + 4, 330, card_h - 8, 21 if words[i].length() <= 8 else 17, MUTED, true)
		if i < words.size() - 1:
			if i < step - 1:
				label(current_level().links[i], 45, y + card_h, 390, gap, 11, DARK_GREEN, true)
			else:
				var arrow = icon("arrow", 233, y + card_h + 1, 14, LINE)
				arrow.pivot_offset = Vector2(7, 7)
				arrow.rotation = PI / 2
	feedback = label("", 24, 599, 432, 27, 15, CLAY, true)
	var help_text = "Önceki kelimeyle bir tamlama oluştur."
	if tutorial:
		help_text = ["", "ÇAY + ?  >  Çay kaşığı. KAŞIK yaz!", "KAŞIK + ?  >  Kaşık oyunu. OYUN yaz!", "OYUN + ?  >  Oyun havası. HAVA yaz!"][step]
	elif hint_open:
		help_text = current_level().hints[step]
	panel(26, 538, 428, 57, PEACH, null, 15)
	icon("bulb", 39, 552, 25, CLAY)
	paragraph(help_text, 77, 542, 360, 49, 18, INK, false)
	if mode == "solo" or tutorial:
		button("Harf al  ·  " + ("Ücretsiz" if tutorial else "20"), 28, 637, 205, 48, buy_letter, PAPER, null, true)
		button("İpucu  ·  " + ("Ücretsiz" if tutorial else "10"), 247, 637, 205, 48, buy_hint, PAPER, null, true)
	else:
		label("İlk harf bizden, gerisi senden.", 30, 644, 420, 27, 16, MUTED, true)
	keyboard()

func _draw_slots() -> void:
	for child in slots.get_children():
		child.free()
	var word = current_word()
	var w = minf(36.0, (344.0 - (word.length() - 1) * 4) / word.length())
	var left = (352 - (w + 4) * word.length() + 4) / 2
	var cursor = 0
	var active_pos = -1
	for i in word.length():
		var value = ""
		var locked = fixed.has(i)
		if locked:
			value = word[i]
		elif cursor < typed.length():
			value = typed[cursor]
			cursor += 1
		elif active_pos < 0:
			active_pos = i
		var x = left + i * (w + 4)
		panel(x, 0, w, slots.size.y - 2, SAGE if i == active_pos else PAPER, slots, 6)
		var l = label(value, x, 0, w, slots.size.y - 4, 26 if word.length() < 10 else 22, DARK_GREEN if locked else INK, true, false, slots)
		l.tooltip_text = "Açık harf" if locked else ""

func keyboard(parent: Node = null, name_entry: bool = false) -> void:
	var rows = ["QWERTYUIOPĞÜ", "ASDFGHJKLŞİ", "ZXCVBNMÖÇ"]
	for row in rows.size():
		var chars: String = rows[row]
		var key_w = 33.5
		var gap = 4.0
		var total = chars.length() * (key_w + gap) - gap
		var left = (480 - total) / 2
		for i in chars.length():
			var character = chars[i]
			button(character, left + i * (key_w + gap), 706 + row * 46, key_w, 41, func():
				if name_entry:
					name_character(character)
				else:
					type_character(character)
			, PAPER, parent, true)
	button("", 19, 849, 67, 40, func():
		if name_entry:
			name_field.text = name_field.text.left(maxi(0, name_field.text.length() - 1))
			name_field.text_changed.emit(name_field.text)
		else:
			backspace()
	, PAPER, parent)
	icon("delete", 39, 855, 24, INK, parent)
	if name_entry:
		button("Boşluk", 96, 849, 180, 40, func(): name_character(" "), PAPER, parent, true)
	else:
		label("TÜRKÇE Q", 95, 853, 185, 31, 15, PAPER, true, false, parent)
	button("Tamam" if name_entry else "Kontrol et", 290, 848, 171, 42, func():
		if name_entry:
			name_field.release_focus()
			close_modal()
		else:
			submit()
	, GREEN, parent, true)

func name_character(character: String) -> void:
	if name_field.text.length() >= 16:
		return
	name_field.text += character
	name_field.caret_column = name_field.text.length()
	name_field.text_changed.emit(name_field.text)

func show_name_keyboard() -> void:
	if screen not in ["create_profile", "party_setup"]:
		return
	close_modal()
	modal = Control.new()
	modal.size = Vector2(480, 900)
	add_child(modal)
	var dim = ColorRect.new()
	dim.color = Color(0.24, 0.23, 0.18, 0.32)
	rect(dim, 0, 0, 480, 900, modal)
	panel(12, 410, 456, 480, PAPER, modal, 24)
	label("Sana nasıl seslenelim?", 30, 440, 420, 46, 27, INK, true, true, modal)
	name_preview = label(name_field.text if not name_field.text.is_empty() else "Adın burada görünecek", 28, 515, 424, 70, 28, DARK_GREEN, true, false, modal)
	label("2–16 harf · Türkçe Q klavye", 40, 611, 400, 35, 14, MUTED, true, false, modal)
	keyboard(modal, true)

func type_character(character: String) -> void:
	if screen != "game" or input_locked or is_instance_valid(modal):
		return
	var remaining = current_word().length() - fixed.size()
	if typed.length() >= remaining:
		return
	typed += character
	_draw_slots()
	feedback.text = ""
	persist_active()
	if typed.length() == remaining:
		submit()

func backspace() -> void:
	if screen == "game" and not input_locked and not is_instance_valid(modal):
		typed = typed.left(maxi(typed.length() - 1, 0))
		_draw_slots()
		feedback.text = ""
		persist_active()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(modal):
			close_modal()
		elif screen == "game":
			leave_game()
		return
	if screen != "game" or is_instance_valid(modal):
		return
	if event.keycode == KEY_BACKSPACE:
		backspace()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		submit()
	elif event.unicode > 0:
		var value = WordRules.upper_tr(String.chr(event.unicode))
		if value in WordRules.LETTERS:
			type_character(value)
	get_viewport().set_input_as_handled()

func submit() -> void:
	if screen != "game" or input_locked or is_instance_valid(modal):
		return
	var answer = WordRules.compose(current_word(), fixed, typed)
	if answer.length() < current_word().length():
		feedback.text = "Bütün boşlukları dolduralım."
		return
	if answer.replace("Â", "A") != current_word().replace("Â", "A"):
		sound("wrong")
		feedback.text = "Bu bağlantı olmadı. Bir daha deneyelim!"
		if Profile.data.motion:
			var t = create_tween().bind_node(page)
			t.tween_property(slots, "position:x", 57.0, 0.05)
			t.tween_property(slots, "position:x", 71.0, 0.06)
			t.tween_property(slots, "position:x", 64.0, 0.05)
		return
	input_locked = true
	sound("correct")
	feedback.add_theme_color_override("font_color", DARK_GREEN)
	feedback.text = current_level().links[step - 1] + "  ·  Harika bağlantı!"
	if mode == "party":
		turn_score += 100
	if mode == "race":
		race_score += 100
	var generation = screen_generation
	var t = get_tree().create_timer(0.45)
	t.timeout.connect(func():
		if screen != "game" or screen_generation != generation:
			return
		step += 1
		typed = ""
		fixed = {0: true}
		hint_open = tutorial
		if step >= current_level().words.size():
			finish_chain()
		else:
			persist_active()
			show_game()
	)

func buy_letter() -> void:
	if input_locked:
		return
	var positions = WordRules.hidden_positions(current_word(), fixed)
	if positions.is_empty():
		return
	if not tutorial and Profile.data.gold < WordRules.LETTER_COST:
		toast("Harf için 20 altın gerekiyor. Bölüm tamamlayarak kazanabilirsin.")
		return
	if not tutorial:
		Profile.data.gold -= WordRules.LETTER_COST
	fixed[positions[rng.randi_range(0, positions.size() - 1)]] = true
	typed = ""
	persist_active()
	Profile.save()
	show_game()
	if fixed.size() == current_word().length():
		submit()

func buy_hint() -> void:
	if input_locked:
		return
	if hint_open:
		toast("İpucun zaten konuşma balonunda. Bir kez daha ücret alınmaz.")
		return
	if not tutorial and Profile.data.gold < WordRules.HINT_COST:
		toast("İpucu için 10 altın gerekiyor.")
		return
	if not tutorial:
		Profile.data.gold -= WordRules.HINT_COST
	hint_open = true
	persist_active()
	Profile.save()
	show_game()

func finish_chain() -> void:
	if tutorial:
		Profile.data.tutorial = true
		Profile.save()
		show_complete(0)
	elif mode == "party":
		finish_party_turn(true)
	elif mode == "race":
		level_index = (level_index + 1) % Profile.levels.size()
		step = 1
		show_game()
	else:
		var reward = Profile.reward(current_level().id)
		show_complete(reward)

func show_complete(reward: int) -> void:
	clear("complete")
	picture(atlas("decor", 1), 78, 167, 324, 301)
	panel(35, 478, 410, 77)
	label("Öğretici Tamamlandı!" if tutorial else "Bölüm Tamamlandı!", 47, 487, 386, 54, 34, INK, true, true)
	icon("coin", 153, 590, 41)
	label("100 altının hazır!" if tutorial else "+%d" % reward, 205, 579, 220, 66, 32, PAPER)
	button("Yolculuğa Başla" if tutorial else "Sonraki Bölüm", 42, 688, 396, 67, func():
		if tutorial:
			show_home()
		elif level_index + 1 < Profile.levels.size():
			start_level(level_index + 1)
		else:
			show_categories()
	)
	icon("arrow", 382, 709, 24)
	button("Ana Menüye Dön", 42, 773, 396, 62, show_home, BG)
	icon("home", 66, 789, 29)
	confetti()

func confetti() -> void:
	if not Profile.data.motion:
		return
	for i in 34:
		var p = ColorRect.new()
		p.color = [GREEN, CLAY, GOLD, Color("dac6a4")][i % 4]
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect(p, rng.randf_range(20, 460), rng.randf_range(-170, -20), rng.randf_range(4, 8), rng.randf_range(7, 12))
		p.rotation = rng.randf_range(0, PI)
		var t = create_tween().bind_node(page).set_parallel(true)
		t.tween_property(p, "position:y", rng.randf_range(500, 900), rng.randf_range(2.0, 3.8))
		t.tween_property(p, "rotation", rng.randf_range(3, 12), 3.8)
		t.tween_property(p, "modulate:a", 0.0, 3.8)
		t.chain().tween_callback(p.queue_free)

func show_together() -> void:
	round_timer.stop()
	clear("together")
	header("Oyun Modu Seç")
	var modes = [["Tek Oyunculu", "Kendine oyna.\nBölümleri tamamla.", "book", func(): start_level(Profile.next_level())], ["Çok Oyunculu", "Diğer oyuncularla yarış.\nŞimdilik yerel antrenman.", "people", show_race_lobby], ["Parti Modu", "Telefonu sırayla paylaş.\nArkadaşınla birlikte oyna.", "party", show_party_setup]]
	for i in modes.size():
		var row = modes[i]
		var y = 180 + i * 195
		button("", 35, y, 410, 167, row[3], SAGE if i == 0 else PAPER)
		icon(row[2], 54, y + 39, 82)
		label(row[0], 154, y + 21, 266, 44, 29, INK, false, true)
		paragraph(row[1], 154, y + 73, 256, 72, 22, INK, false)
	nav("people")

func show_party_setup() -> void:
	clear("party_setup")
	header("Parti hazırlığı", show_together)
	icon("people", 208, 119, 64)
	label("İki arkadaş, bir telefon", 25, 215, 430, 50, 28, INK, true, true)
	paragraph("Her oyuncuya tur başına 60 saniye.\n3 tur sonunda en çok puanı toplayan kazanır.", 35, 279, 410, 73, 16)
	label("1. OYUNCU", 44, 391, 390, 28, 12, MUTED)
	var first = field(Profile.data.name, "Birinci oyuncu", 42, 429, 396, 59)
	label("2. OYUNCU", 44, 522, 390, 28, 12, MUTED)
	var second = field("", "Arkadaşının adı", 42, 560, 396, 59)
	for entry in [first, second]:
		entry.focus_entered.connect(func():
			name_field = entry
			show_name_keyboard()
		)
		entry.text_changed.connect(func(value):
			if is_instance_valid(name_preview):
				name_preview.text = value
		)
	feedback = label("", 38, 637, 404, 50, 15, CLAY, true)
	button("Hazırız, başlayalım   >", 42, 709, 396, 62, func():
		if not WordRules.valid_name(first.text) or not WordRules.valid_name(second.text):
			feedback.text = "İki oyuncu için de 2–16 harflik ad yaz."
			return
		if WordRules.upper_tr(first.text.strip_edges()) == WordRules.upper_tr(second.text.strip_edges()):
			feedback.text = "Oyuncuları ayırt etmek için farklı adlar seç."
			return
		party_names.assign([first.text.strip_edges(), second.text.strip_edges()])
		party_scores.assign([0, 0])
		party_round = 0
		party_turn = 0
		show_party_handoff()
	)
	paragraph("Her doğru kelime 100 puan. Zinciri bitirirsen\nkalan her saniye için 2 puan daha kazanırsın.", 42, 803, 396, 62, 14)

func show_party_handoff() -> void:
	round_timer.stop()
	clear("party_handoff")
	label("TUR %d / 3" % [party_round + 1], 30, 99, 420, 35, 14, MUTED, true)
	picture(atlas("avatars", int(Profile.data.avatar)), 158, 193, 164, 198)
	label("Sıra sende, " + party_names[party_turn], 24, 421, 432, 61, 27, INK, true, true)
	paragraph("Telefonu al, rahatça yerleş.\nHazır olduğunda süre başlayacak.", 38, 505, 404, 76)
	label("%s  %d  ·  %d  %s" % [party_names[0], party_scores[0], party_scores[1], party_names[1]], 25, 615, 430, 48, 20, DARK_GREEN, true)
	button("Hazırım   >", 42, 725, 396, 62, func(): countdown("party"))
	text_button("Partiden ayrıl", 100, 812, 280, 36, func(): confirm_exit(show_together))

func countdown(next_mode: String) -> void:
	clear("countdown")
	label("Bir nefes al…", 30, 235, 420, 60, 30, INK, true, true)
	var number = label("3", 30, 335, 420, 170, 112, GREEN, true, true)
	label("Kelimeler seni bekliyor.", 30, 556, 420, 35, 18, MUTED, true)
	var t = create_tween().bind_node(page)
	for value in ["3", "2", "1"]:
		t.tween_callback(func():
			number.text = value
			sound("tap")
		)
		t.tween_interval(0.8)
	t.tween_callback(func():
		mode = next_mode
		tutorial = false
		level_index = party_round * 2 + party_turn if next_mode == "party" else 0
		step = 1
		typed = ""
		fixed = {0: true}
		hint_open = false
		time_left = 60 if next_mode == "party" else 90
		turn_score = 0
		race_score = 0
		ghost_score = 0
		show_game()
		round_timer.start()
	)

func _tick() -> void:
	if screen != "game" or mode not in ["party", "race"]:
		return
	# Multiplayer turns cannot be paused by opening an overlay.
	time_left -= 1
	if is_instance_valid(clock_label):
		clock_label.text = "%d sn" % time_left
	if mode == "race":
		if time_left % 11 == 0:
			ghost_score += 100
		if is_instance_valid(race_label):
			race_label.text = "Sen: %d  ·  Tilki: %d" % [race_score, ghost_score]
	if time_left <= 0:
		round_timer.stop()
		if mode == "party":
			finish_party_turn(false)
		else:
			show_race_result()

func finish_party_turn(completed: bool) -> void:
	round_timer.stop()
	if completed:
		turn_score += time_left * 2
	party_scores[party_turn] += turn_score
	if party_turn == 0:
		party_turn = 1
		show_party_handoff()
	else:
		party_turn = 0
		party_round += 1
		if party_round == 3:
			show_party_result()
		else:
			show_party_handoff()

func show_party_result() -> void:
	clear("party_result")
	icon("trophy", 204, 114, 72, GOLD)
	var winner = "Dostluk kazandı!" if party_scores[0] == party_scores[1] else party_names[0 if party_scores[0] > party_scores[1] else 1] + " kazandı!"
	label(winner, 20, 251, 440, 65, 31, INK, true, true)
	label("Üç tur, bir sürü güzel bağlantı.", 35, 330, 410, 42, 17, MUTED, true)
	for i in 2:
		panel(42, 414 + i * 100, 396, 78, SAGE if party_scores[i] == party_scores.max() else PAPER)
		label(party_names[i], 65, 431 + i * 100, 235, 44, 22)
		label(str(party_scores[i]), 302, 431 + i * 100, 110, 44, 26, DARK_GREEN, true)
	button("Bir parti daha   >", 42, 691, 396, 62, show_party_setup)
	text_button("Ana sayfaya dön", 80, 784, 320, 45, show_home)
	confetti()

func show_race_lobby() -> void:
	clear("race_lobby")
	header("Kelime yarışı", show_together)
	icon("trophy", 206, 129, 68, GOLD)
	label("Tatlı bir rekabete hazır mısın?", 15, 228, 450, 50, 25, INK, true, true)
	panel(30, 323, 420, 222, PAPER)
	label("ODA KODUYLA BULUŞ", 50, 346, 380, 31, 12, MUTED, true)
	var code = field("", "A B C D E F", 65, 395, 350, 60, 6)
	code.editable = false
	button("Oda oluştur", 51, 478, 180, 46, func(): pass, PAPER, null, true).disabled = true
	button("Odaya katıl", 249, 478, 180, 46, func(): pass, PAPER, null, true).disabled = true
	paragraph("Çevrimiçi bağlantı henüz etkin değil.\nOda kodu, canlı skor ve arkadaş mesajları\nbağlantı eklendiğinde açılacak.", 40, 565, 400, 100, 16)
	button("Tilki ile antrenman   >", 42, 712, 396, 62, func(): countdown("race"))
	paragraph("90 saniyelik yerel demo. Tilki'nin puanı\nörnek olarak artar; gerçek bir rakip değildir.", 42, 796, 396, 67, 14)

func show_race_result() -> void:
	clear("race_result")
	picture(atlas("avatars", int(Profile.data.avatar)), 153, 123, 174, 208)
	label("Güzel bir antrenmandı!", 20, 372, 440, 59, 29, INK, true, true)
	paragraph("Bir sonraki bağlantı daha da hızlı gelecek.", 32, 445, 416, 57)
	panel(42, 544, 396, 97, SAGE)
	label("Sen  %d     ·     Tilki  %d" % [race_score, ghost_score], 60, 567, 360, 50, 24, DARK_GREEN, true)
	button("Yeniden antrenman   >", 42, 712, 396, 62, func(): countdown("race"))
	text_button("Birlikte menüsüne dön", 70, 800, 340, 45, show_together)

func show_messages() -> void:
	var box = open_modal("Kısa bir selam", "Bunlar yerel demo mesajlarıdır.\nBaşka bir oyuncuya gönderilmez.")
	for i in 3:
		var message = ["Bol şans!", "Güzel bağlantı!", "İyi oyundu!"][i]
		button(message, 26, 177 + i * 59, 340, 48, func():
			close_modal()
			toast("Sen: " + message)
		, PAPER, box, true)
	text_button("Kapat", 45, 359, 300, 43, close_modal, box)

func show_profile_page() -> void:
	round_timer.stop()
	clear("profile")
	header("Senin hikâyen")
	panel(185, 115, 110, 110, SAGE, null, 55)
	avatar(195, 123, 90)
	label(Profile.data.name, 25, 245, 430, 51, 33, INK, true, true)
	label("Meraklı kelime gezgini", 25, 302, 430, 33, 16, MUTED, true)
	text_button("Profilimi düzenle", 120, 347, 240, 43, func(): show_create_profile(true))
	panel(30, 428, 420, 107)
	icon("book", 65, 448, 28)
	label(str(Profile.data.completed.size()), 106, 438, 110, 41, 29, DARK_GREEN, true)
	label("tamamlanan bölüm", 44, 490, 190, 26, 13, MUTED, true)
	icon("coin", 270, 448, 28, GOLD)
	label(str(Profile.data.gold), 310, 438, 110, 41, 29, INK, true)
	label("biriken altın", 260, 490, 157, 26, 13, MUTED, true)
	button("Sesler  ·  " + ("Açık" if Profile.data.sound else "Kapalı"), 30, 575, 420, 57, func():
		Profile.data.sound = not Profile.data.sound
		Profile.save()
		show_profile_page()
	, PAPER, null, true)
	button("Hareketler  ·  " + ("Açık" if Profile.data.motion else "Azaltılmış"), 30, 648, 420, 57, func():
		Profile.data.motion = not Profile.data.motion
		Profile.save()
		show_profile_page()
	, PAPER, null, true)
	text_button("Öğreticiyi tekrar oyna", 90, 731, 300, 42, start_tutorial)
	label("Türkçe  ·  Sözden Söze v1.0", 25, 779, 430, 23, 12, MUTED, true)
	nav("user")

func leave_game() -> void:
	if input_locked:
		return
	if mode in ["party", "race"]:
		confirm_exit(show_together)
	else:
		persist_active()
		var box = open_modal("Bir çay molası?", "Kaldığın yer ve açtığın harfler kaydedildi." if not tutorial else "Öğreticiye daha sonra yeniden başlayabilirsin.")
		button("Oyuna devam", 25, 202, 342, 57, close_modal, GREEN, box)
		button("Ana sayfaya dön", 25, 282, 342, 57, func():
			if tutorial and not Profile.data.tutorial:
				Profile.data.tutorial = true
				Profile.save()
			show_home()
		, PAPER, box)

func confirm_exit(action: Callable) -> void:
	var box = open_modal("Bu turdan ayrılalım mı?", "Bu maçın puanları saklanmayacak.\nSüre, sen karar verirken de ilerler.")
	button("Oyunda kal", 25, 202, 342, 57, close_modal, GREEN, box)
	button("Ayrıl", 25, 282, 342, 57, func():
		round_timer.stop()
		action.call()
	, PAPER, box)

func open_modal(title_text: String, body: String) -> Control:
	close_modal()
	modal = Control.new()
	modal.size = Vector2(480, 900)
	add_child(modal)
	var dim = ColorRect.new()
	dim.color = Color(0.24, 0.23, 0.18, 0.44)
	rect(dim, 0, 0, 480, 900, modal)
	var box = panel(44, 245, 392, 420, PAPER, modal, 24)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	label(title_text, 19, 30, 354, 59, 26, INK, true, true, box)
	paragraph(body, 25, 100, 342, 74, 16, MUTED, true, box)
	return box

func close_modal() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
	modal = null

func toast(message: String) -> void:
	var p = panel(24, 98, 432, 80, PEACH)
	paragraph(message, 15, 7, 402, 66, 15, INK, true, p)
	var t = create_tween().bind_node(p)
	t.tween_interval(3.1)
	t.tween_property(p, "modulate:a", 0.0, 0.2)
	t.tween_callback(func():
		if is_instance_valid(p):
			p.queue_free()
	)

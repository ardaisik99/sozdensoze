extends SceneTree

var checks = 0
var failures: Array[String] = []
var profile: Node
var game: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAILED: " + message)

func solve_word() -> void:
	game.typed = ""
	var word = game.current_word()
	for i in word.length():
		if not game.fixed.has(i):
			game.type_character(word[i].replace("Â", "A"))
	await create_timer(0.51).timeout

func run() -> void:
	profile = root.get_node("Profile")
	# Never write the player's real profile during automated tests.
	profile.save_path = "user://integration-test.json"
	profile.data = {"version":1,"name":"","avatar":0,"accent":1,"gold":100,"completed":[],"active":{},"tutorial":false,"sound":false,"motion":false}
	check(WordRules.upper_tr("çay kaşığı i ı ö ü ş ğ") == "ÇAY KAŞIĞI İ I Ö Ü Ş Ğ", "Turkish casing preserves dotted and dotless I")
	check(WordRules.valid_name("Çağrı"), "Turkish player names accepted")
	check(not WordRules.valid_name("A") and not WordRules.valid_name("Ali123"), "Invalid names rejected")
	check(WordRules.compose("KAŞIK", {0:true, 2:true}, "Z") == "KZŞ", "Revealed positions consume no input")
	check(WordRules.compose("KAŞIK", {0:true, 2:true}, "AIK".left(1) + "IK") == "KAŞIK", "Mixed revealed and typed letters compose correctly")
	check(profile.levels.size() == 33, "33 authored levels loaded")
	var ids = {}
	for level in profile.levels:
		check(not ids.has(level.id), "Unique level id: " + level.id)
		ids[level.id] = true
		check(level.words.size() in [4,5], "4 or 5 words: " + level.id)
		check(level.hints.size() == level.words.size() and level.links.size() == level.words.size()-1, "Hint/link coverage: " + level.id)
		for word in level.words:
			for character in word:
				check(character in WordRules.LETTERS + "Â", "Keyboard can enter " + character)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	check(game.screen == "loading", "Boot opens loading screen")
	await create_timer(1.35).timeout
	check(game.screen == "create_profile", "First launch requests profile")
	game.name_field.text = "D"
	game._save_name()
	check(game.screen == "create_profile", "Invalid profile cannot advance")
	game.name_field.text = "Çağrı"
	game._save_name()
	check(game.screen == "avatar_select", "Name proceeds to nine-avatar selection")
	for child in game.page.get_children():
		if child is Button and child.text == "Başla":
			child.pressed.emit()
			break
	check(game.tutorial and game.step == 1, "Profile advances into interactive tutorial")
	for i in 3:
		await solve_word()
	check(game.screen == "complete" and profile.data.tutorial, "Tutorial completion is persistent")
	check(profile.data.gold == 100, "Tutorial preserves initial 100 gold")
	game.show_home()
	check(game.screen == "home", "Tutorial can reach main menu")
	game.show_levels()
	check(profile.unlock(0) and not profile.unlock(1), "Sequential level unlocking")
	game.start_level(0)
	game.type_character("A")
	game.type_character("A")
	game.type_character("A")
	game.type_character("A")
	check(game.step == 1 and not game.input_locked, "Wrong guesses do not advance")
	game.backspace()
	check(game.typed.length() == 3, "Backspace clears only entered letters")
	game.typed = ""
	game.buy_hint()
	check(profile.data.gold == 90 and game.hint_open, "Hint charges 10 gold")
	game.buy_hint()
	check(profile.data.gold == 90, "Same hint cannot be charged twice")
	game.buy_letter()
	check(profile.data.gold == 70 and game.fixed.size() == 2, "Letter charges 20 gold and opens one letter")
	game.type_character("A")
	game.persist_active()
	profile.save()
	var original_fixed = game.fixed.keys()
	game.show_home()
	game.start_level(0)
	check(game.hint_open and game.fixed.keys() == original_fixed and game.typed == "A", "Resume preserves hints, reveals and input")
	for i in 3:
		await solve_word()
	check(game.screen == "complete" and profile.data.gold == 95, "First clear awards 25 gold")
	check(profile.unlock(1), "Completion unlocks next level")
	game.start_level(0)
	for i in 3:
		await solve_word()
	check(profile.data.gold == 95, "Replay cannot farm completion gold")
	check(not profile.data.active.has("mutfak-01"), "Replay completion clears active save")
	profile.data.gold = 0
	game.start_level(1)
	game.buy_letter()
	game.buy_hint()
	check(profile.data.gold == 0 and game.fixed.size() == 1 and not game.hint_open, "Insufficient funds cannot buy helpers")
	# Enter every answer through the same input path as the actual keyboard.
	for idx in range(1, profile.levels.size()):
		game.start_level(idx)
		for i in range(1, profile.levels[idx].words.size()):
			await solve_word()
		check(game.screen == "complete", "Solvable level: " + profile.levels[idx].id)
	check(profile.data.completed.size() == 33, "All 33 chains playable end to end")
	profile.data.name = "Çağrı"
	profile.data.avatar = 2
	profile.save()
	profile.data.name = "temporary"
	profile.load_profile()
	check(profile.data.name == "Çağrı" and profile.data.avatar == 2 and profile.data.completed.size() == 33, "Profile save/load round trip")
	# Corruption recovery uses the atomic previous-save backup.
	profile.save()
	var corrupt = FileAccess.open(profile.save_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	profile.data.name = "temporary"
	profile.load_profile()
	check(profile.data.name == "Çağrı", "Corrupt primary save recovers from backup")
	game.party_names.assign(["Çağrı", "Deniz"])
	game.party_scores.assign([0,0])
	game.party_round = 0
	game.party_turn = 0
	for turn in 6:
		game.mode = "party"
		game.tutorial = false
		game.level_index = turn
		game.step = 1
		game.typed = ""
		game.fixed = {0:true}
		game.time_left = 60
		game.turn_score = 0
		game.show_game()
		for i in range(1, profile.levels[turn].words.size()):
			await solve_word()
	check(game.screen == "party_result" and game.party_scores == [1260,1260], "Party plays six turns and handles a draw")
	game.mode = "race"
	game.tutorial = false
	game.level_index = 0
	game.step = 1
	game.typed = ""
	game.fixed = {0:true}
	game.time_left = 90
	game.race_score = 0
	game.ghost_score = 0
	game.show_game()
	game.show_messages()
	check(is_instance_valid(game.modal), "Local race quick messages open")
	game.close_modal()
	for tick in 90:
		game._tick()
	check(game.screen == "race_result" and game.ghost_score > 0, "Race countdown ends and reports local ghost score")
	game.show_race_lobby()
	game.show_profile_page()
	check(game.screen == "profile", "Profile and race lobby render")
	game.queue_free()
	await process_frame
	for path in [profile.save_path, profile.save_path + ".backup", profile.save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("CHECKS: %d | FAILURES: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

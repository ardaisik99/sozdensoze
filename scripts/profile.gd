extends Node

const PATH = "user://profile.json"
var save_path = PATH
var data: Dictionary = {
	"version": 1, "name": "", "avatar": 0, "accent": 1, "gold": 100,
	"completed": [], "active": {}, "tutorial": false, "profile_ready": false,
	"sound": true, "motion": true
}
var levels: Array = []

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	if parsed is Array:
		levels = parsed
	load_profile()

func load_profile() -> void:
	for path in [save_path, save_path + ".backup"]:
		if not FileAccess.file_exists(path):
			continue
		var parser = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK:
			continue
		var parsed = parser.data
		if parsed is Dictionary and parsed.get("version") == 1:
			for key in data.keys():
				if parsed.has(key) and typeof(parsed[key]) == typeof(data[key]):
					data[key] = parsed[key]
			# JSON numbers deserialize as float; validate the currency separately.
			data.gold = maxi(0, int(parsed.get("gold", 100)))
			data.avatar = clampi(int(parsed.get("avatar", 0)), 0, 8)
			data.accent = clampi(int(parsed.get("accent", 1)), 0, 3)
			data.profile_ready = bool(parsed.get("profile_ready", parsed.get("tutorial", false)))
			data.completed = data.completed.filter(func(id): return id is String)
			if path != save_path:
				DirAccess.copy_absolute(path, save_path)
			return

func save() -> bool:
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, save_path + ".backup")
	return DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK

func next_level() -> int:
	for i in levels.size():
		if not levels[i].id in data.completed:
			return i
	return 0

func unlock(index: int) -> bool:
	if index <= 0:
		return true
	if levels[index].id in data.completed:
		return true
	for previous in range(index - 1, -1, -1):
		if levels[previous].category == levels[index].category:
			return levels[previous].id in data.completed
	return true

func reward(level_id: String) -> int:
	if level_id in data.completed:
		data.active.erase(level_id)
		save()
		return 0
	data.completed.append(level_id)
	data.gold += WordRules.LEVEL_REWARD
	data.active.erase(level_id)
	save()
	return WordRules.LEVEL_REWARD

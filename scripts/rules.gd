class_name WordRules
extends RefCounted

const LETTERS = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZQWX"
const LETTER_COST = 20
const HINT_COST = 10
const LEVEL_REWARD = 25

static func upper_tr(value: String) -> String:
	return value.replace("i", "İ").replace("ı", "I").to_upper()

static func valid_name(value: String) -> bool:
	var clean = value.strip_edges()
	if clean.length() < 2 or clean.length() > 16:
		return false
	for character in upper_tr(clean):
		if not character in LETTERS + " -":
			return false
	return true

static func compose(word: String, fixed: Dictionary, entered: String) -> String:
	var answer = ""
	var cursor = 0
	for i in word.length():
		if fixed.has(i):
			answer += word[i]
		elif cursor < entered.length():
			answer += entered[cursor]
			cursor += 1
	return answer

static func hidden_positions(word: String, fixed: Dictionary) -> Array[int]:
	var positions: Array[int] = []
	for i in word.length():
		if not fixed.has(i):
			positions.append(i)
	return positions

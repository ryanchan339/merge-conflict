extends SceneTree
## Run with: godot --headless --path . --script tests/story_test.gd
## Exhaustively checks authored paths without starting the 3D scene.

const Story = preload("res://content/story.gd")
const STAT_NAMES: Array[String] = ["delivery", "quality", "trust", "energy"]
const REQUIRED_CARDS: Array[String] = [
	"welcome", "standup", "mentor", "feature", "review", "intern",
	"manager", "manager_scope", "kitchen", "incident", "debrief"
]
const DAY_SEQUENCE: Array[String] = [
	"standup", "mentor", "feature", "review", "intern", "manager", "kitchen", "incident"
]
const ENDINGS: Array[String] = [
	"INTERNSHIP ENDED EARLY", "NO RETURN OFFER", "RETURN OFFER", "UPLEVELED RETURN OFFER"
]

var failures: Array[String] = []
var cards: Dictionary = {}
var outcome_counts: Dictionary = {}
var representatives: Dictionary = {}
var path_count: int = 0
var checks: int = 0


func _initialize() -> void:
	for card_id in REQUIRED_CARDS:
		cards[card_id] = Story.card(card_id)
	_test_schema()
	_test_effect_separation_and_clamping()
	_test_evaluation_boundaries()
	if failures.is_empty():
		_walk_day(0, {"delivery": 35, "quality": 45, "trust": 50, "energy": 75}, {}, [])
		_check(path_count == 13122, "Expected all 13,122 complete decision paths; got %d." % path_count)
		for outcome in ENDINGS:
			_check(int(outcome_counts.get(outcome, 0)) > 0, "Unreachable ending: %s" % outcome)
	print("Story test: %d checks; %d complete decision paths." % [checks, path_count])
	for outcome in ENDINGS:
		print("  %s: %d paths; example %s" % [outcome, int(outcome_counts.get(outcome, 0)), str(representatives.get(outcome, {}))])
	if failures.is_empty():
		print("PASS: schemas, effects, clamping, evaluation boundaries, and all four endings.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL: %d failures." % failures.size())
		quit(1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _test_schema() -> void:
	_check(Story.card("missing_card").is_empty(), "Unknown cards must resolve safely to an empty dictionary.")
	for card_id in REQUIRED_CARDS:
		var current: Dictionary = cards[card_id]
		_check(not current.is_empty(), "Missing required card: %s" % card_id)
		for key in ["eyebrow", "title", "speaker", "body"]:
			_check(typeof(current.get(key)) == TYPE_STRING and not str(current.get(key, "")).is_empty(), "%s.%s must be a nonempty string." % [card_id, key])
		_check(typeof(current.get("choices")) == TYPE_ARRAY, "%s.choices must be an array." % card_id)
		var choices: Array = current.get("choices", [])
		_check(choices.size() >= 1 and choices.size() <= 3, "%s must have 1–3 choices." % card_id)
		for index in choices.size():
			var choice: Dictionary = choices[index]
			var location: String = "%s choice %d" % [card_id, index + 1]
			for key in ["label", "hint", "feedback", "next"]:
				_check(typeof(choice.get(key)) == TYPE_STRING, "%s.%s must be a string." % [location, key])
			_check(not str(choice.get("label", "")).is_empty(), "%s needs a label." % location)
			_check(str(choice.get("label", "")).length() <= 90, "%s label exceeds 90 characters." % location)
			_check(str(choice.get("hint", "")).length() <= 140, "%s hint exceeds 140 characters." % location)
			_check(typeof(choice.get("effects")) == TYPE_DICTIONARY, "%s.effects must be a dictionary." % location)
			var next_card: String = choice.get("next", "")
			_check(next_card.is_empty() or not Story.card(next_card).is_empty(), "%s points to missing card %s." % [location, next_card])
			for key in choice.get("effects", {}):
				var effect: Variant = choice["effects"][key]
				if key in STAT_NAMES:
					_check(typeof(effect) == TYPE_INT, "%s meter %s needs an integer, not a boolean." % [location, key])
					_check(int(effect) >= -20 and int(effect) <= 20, "%s meter %s exceeds the authored ±20 range." % [location, key])
				else:
					_check(typeof(effect) == TYPE_BOOL, "%s flag %s must be boolean." % [location, key])
	var schedule: Array = Story.day_schedule()
	_check(schedule.size() >= 8, "The schedule should cover the whole day.")
	for item in schedule:
		_check(item is Dictionary and item.has("time") and item.has("title"), "Schedule entries need time and title.")


func _apply_effects(stats: Dictionary, flags: Dictionary, effects: Dictionary) -> Dictionary:
	var changed_stats: Dictionary = stats.duplicate()
	var changed_flags: Dictionary = flags.duplicate()
	for key in effects:
		var value: Variant = effects[key]
		if typeof(value) == TYPE_BOOL:
			changed_flags[key] = value
		elif key in STAT_NAMES:
			changed_stats[key] = clampi(int(changed_stats.get(key, 0)) + int(value), 0, 100)
	return {"stats": changed_stats, "flags": changed_flags}


func _test_effect_separation_and_clamping() -> void:
	var initial_stats: Dictionary = {"delivery": 99, "quality": 1, "trust": 50, "energy": 75}
	var initial_flags: Dictionary = {"tested": true}
	var result: Dictionary = _apply_effects(initial_stats, initial_flags, {
		"delivery": 20, "quality": -20, "trust": -20, "energy": -20,
		"clarified": true, "tested": false, "review_context": true
	})
	_check(result["stats"] == {"delivery": 100, "quality": 0, "trust": 30, "energy": 55}, "Meter effects must clamp independently to 0–100.")
	_check(result["flags"] == {"tested": false, "clarified": true, "review_context": true}, "Boolean effects must remain flags, including false and review_context.")
	_check(initial_stats["delivery"] == 99 and initial_stats["quality"] == 1, "Effect simulation must not mutate its starting meters.")
	_check(initial_flags["tested"] == true, "Effect simulation must not mutate its starting flags.")
	_check(not result["stats"].has("clarified") and not result["stats"].has("review_context"), "Boolean flags must never create numeric meters.")
	for value in result["stats"].values():
		_check(typeof(value) == TYPE_INT, "Meter values must remain integers.")


func _expect_ending(stats: Dictionary, flags: Dictionary, expected: String, context: String) -> void:
	var evaluation: Dictionary = Story.ending(stats, flags)
	_check(evaluation.get("subtitle", "") == expected, "%s: expected %s, got %s." % [context, expected, evaluation.get("subtitle", "missing")])
	for key in ["title", "subtitle", "body", "color"]:
		_check(typeof(evaluation.get(key)) == TYPE_STRING and not str(evaluation.get(key, "")).is_empty(), "Ending %s needs nonempty %s." % [expected, key])


func _test_evaluation_boundaries() -> void:
	var earned_flags: Dictionary = {"clarified": true, "tested": true}
	_expect_ending({"delivery": 100, "quality": 100, "trust": 19}, earned_flags, ENDINGS[0], "Trust below 20 overrides otherwise excellent work")
	_expect_ending({"delivery": 0, "quality": 0, "trust": 20}, {}, ENDINGS[1], "Trust at 20 avoids the fired outcome")
	_expect_ending({"delivery": 45, "quality": 40, "trust": 40}, {}, ENDINGS[2], "Exact return-offer boundary")
	_expect_ending({"delivery": 44, "quality": 40, "trust": 40}, {}, ENDINGS[1], "Delivery one below return-offer boundary")
	_expect_ending({"delivery": 45, "quality": 39, "trust": 40}, {}, ENDINGS[1], "Quality one below return-offer boundary")
	_expect_ending({"delivery": 45, "quality": 40, "trust": 39}, {}, ENDINGS[1], "Trust one below return-offer boundary")
	_expect_ending({"delivery": 65, "quality": 65, "trust": 65}, earned_flags, ENDINGS[3], "Exact uplevel boundary")
	_expect_ending({"delivery": 64, "quality": 65, "trust": 65}, earned_flags, ENDINGS[2], "Delivery one below uplevel boundary")
	_expect_ending({"delivery": 65, "quality": 64, "trust": 65}, earned_flags, ENDINGS[2], "Quality one below uplevel boundary")
	_expect_ending({"delivery": 65, "quality": 65, "trust": 64}, earned_flags, ENDINGS[2], "Trust one below uplevel boundary")
	_expect_ending({"delivery": 100, "quality": 100, "trust": 100}, {"tested": true}, ENDINGS[2], "High meters cannot substitute for clarifying requirements")
	_expect_ending({"delivery": 100, "quality": 100, "trust": 100}, {"clarified": true}, ENDINGS[2], "High meters cannot substitute for testing")
	_expect_ending({"delivery": 100, "quality": 100, "trust": 100}, {"clarified": false, "tested": true}, ENDINGS[2], "Explicit false clarification is not achievement")
	_expect_ending({"delivery": 100, "quality": 100, "trust": 100}, {"clarified": true, "tested": false}, ENDINGS[2], "Explicit false testing is not achievement")
	_expect_ending({"delivery": 65, "quality": 65, "trust": 65, "energy": 0}, earned_flags, ENDINGS[3], "Low final energy alone does not revoke earned achievements")
	_expect_ending({"delivery": 65, "quality": 65, "trust": 65, "energy": 100}, earned_flags, ENDINGS[3], "Energy is not a hidden evaluation threshold")


func _walk_day(stage: int, stats: Dictionary, flags: Dictionary, history: Array) -> void:
	if stage == DAY_SEQUENCE.size():
		path_count += 1
		var result: Dictionary = Story.ending(stats, flags)
		var outcome: String = result.get("subtitle", "")
		_check(outcome in ENDINGS, "A complete day returned an unknown ending: %s" % outcome)
		outcome_counts[outcome] = int(outcome_counts.get(outcome, 0)) + 1
		if not representatives.has(outcome):
			representatives[outcome] = {"choices": history.duplicate(), "stats": stats.duplicate(), "flags": flags.duplicate()}
		return
	_walk_card(DAY_SEQUENCE[stage], stage, stats, flags, history, [])


func _walk_card(card_id: String, stage: int, stats: Dictionary, flags: Dictionary, history: Array, chain: Array) -> void:
	_check(not chain.has(card_id), "Dialogue next links must not form an infinite cycle: %s" % card_id)
	if chain.has(card_id):
		return
	var chained: Array = chain.duplicate()
	chained.append(card_id)
	var choices: Array = cards[card_id]["choices"]
	for index in choices.size():
		var choice: Dictionary = choices[index]
		var state: Dictionary = _apply_effects(stats, flags, choice["effects"])
		var next_history: Array = history.duplicate()
		next_history.append("%s:%d" % [card_id, index + 1])
		for key in STAT_NAMES:
			_check(int(state["stats"][key]) >= 0 and int(state["stats"][key]) <= 100, "Out-of-range meter after %s choice %d." % [card_id, index + 1])
		for key in state["flags"]:
			_check(typeof(state["flags"][key]) == TYPE_BOOL, "A path converted flag %s into a non-boolean." % key)
			_check(not state["stats"].has(key), "A path inserted flag %s into the numeric meters." % key)
		var next_card: String = choice.get("next", "")
		if next_card.is_empty():
			_walk_day(stage + 1, state["stats"], state["flags"], next_history)
		else:
			_walk_card(next_card, stage, state["stats"], state["flags"], next_history, chained)

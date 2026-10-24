extends Node3D

const OfficeScene = preload("res://scripts/office.gd")
const PlayerController = preload("res://scripts/player.gd")
const GameHUD = preload("res://scripts/hud.gd")
const Story = preload("res://content/story.gd")

const STAGES: Array[String] = ["standup", "mentor", "feature", "review_info", "review", "intern", "manager", "kitchen", "incident", "exit"]
const STAGE_TARGETS: Dictionary = {"standup":"standup", "mentor":"mentor", "feature":"desk", "review_info":"mentor", "review":"desk", "intern":"intern", "manager":"manager", "kitchen":"kitchen", "incident":"desk", "exit":"exit"}
const TIMES: Array[String] = ["09:05", "09:30", "10:00", "11:15", "11:30", "13:00", "14:30", "15:15", "15:17", "17:00"]
const OBJECTIVES: Dictionary = {
	"standup":["Make your first standup", "Find the team huddle in the meeting area."],
	"mentor":["Find out what you're actually building", "Ask Maya at her desk about the coffee-order feature."],
	"feature":["Prompt your very confident AI assistant", "Return to your desk. Give the assistant a useful brief."],
	"review_info":["Your review has a question", "Find Maya. Apparently “works on my machine” needs evidence."],
	"review":["Finish the code review", "Return to your desk and decide how thoroughly to test."],
	"intern":["Sam has a small emergency", "Visit the other intern. Their “quick question” has a stack trace."],
	"manager":["Time for your 1:1", "Visit Jordan's office. Discuss the project and your progress."],
	"kitchen":["Take a well-earned coffee break", "Head to the kitchenette. Choose how to spend your energy."],
	"incident":["SEV-1 · Get back to your desk", "Coffee orders are duplicating. Sprint with Shift, then press E at your desk."],
	"exit":["Your final day is in the books", "Head to the elevator for your internship evaluation."]
}

var office: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var stats: Dictionary = {"delivery":35, "quality":45, "trust":50, "energy":75}
var flags: Dictionary = {}
var evidence: Array = []
var stage_index: int = -1
var current_card: Dictionary = {}
var current_card_id: String = ""
var pending_next: String = ""
var pending_advance: bool = false
var ambient: bool = false
var paused: bool = false
var finished: bool = false
var incident_active: bool = false
var incident_seconds: float = 45.0
var incident_penalties: int = 0
var incident_reached: bool = false
var sound: AudioStreamPlayer
var capture_mode: bool = false
var test_mode: bool = false

func _ready() -> void:
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	office = OfficeScene.new()
	add_child(office)
	player = PlayerController.new()
	add_child(player)
	player.position = office.spawn_position
	player.interacted.connect(_interact)
	hud = GameHUD.new()
	add_child(hud)
	hud.choice_selected.connect(_choose)
	hud.continue_pressed.connect(_continue)
	hud.resume_pressed.connect(_resume)
	hud.restart_pressed.connect(_restart)
	hud.quit_pressed.connect(_quit)
	sound = AudioStreamPlayer.new()
	add_child(sound)
	_update_hud()
	_open_card("welcome")
	if capture_mode:
		_capture_sequence.call_deferred()
	if test_mode:
		_smoke_test.call_deferred()

func _process(delta: float) -> void:
	if not is_instance_valid(hud) or not is_instance_valid(player):
		return
	hud.set_focus(player.focused_label if player.enabled else "")
	if stage_index >= 0:
		var target_id: String = str(STAGE_TARGETS[STAGES[stage_index]])
		var target: Vector3 = office.target_position(target_id)
		hud.set_distance(player.global_position.distance_to(target))
		hud.minimap.player_position = player.global_position
		hud.minimap.player_yaw = player.rotation.y
		hud.minimap.target_position = target
		hud.minimap.target_id = target_id
		hud.minimap.target_text = office.target_label(target_id).to_upper()
		hud.minimap.queue_redraw()
	if incident_active and not paused and player.enabled:
		incident_seconds = maxf(0, incident_seconds - delta)
		hud.set_incident(incident_seconds, true)
		if incident_seconds <= 0:
			incident_active = false
			incident_penalties += 1
			stats.trust = maxi(0, int(stats.trust) - 10)
			flags["late_incident"] = true
			_update_hud()
			_open_custom({"eyebrow":"ON-CALL UPDATE", "title":"Maya bought you some time.", "speaker":"#incident-coffee", "body":"The timer ran out, so Maya disabled new coffee orders. Nobody is paying twice anymore, but the office is now aggressively decaffeinated.\n\nYou can still resolve the incident. Get to your desk and choose a fix. [b]−10 team trust[/b]", "choices":[{"label":"Get to the desk and fix it", "hint":"The day is recoverable.", "effects":{}, "feedback":"", "next":""}]}, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if finished:
				return
			if paused:
				_resume()
			elif not hud.is_modal_open():
				paused = true
				player.set_active(false)
				hud.show_pause()
			get_viewport().set_input_as_handled()

func _interact(id: String) -> void:
	if hud.is_modal_open() or finished or stage_index < 0:
		return
	var stage: String = STAGES[stage_index]
	if id == str(STAGE_TARGETS[stage]):
		if stage == "exit":
			_finish_day()
		elif stage == "review_info":
			_open_custom({"eyebrow":"CODE REVIEW · CR-012", "title":"One tap. Zero purchases?", "speaker":"Maya · senior engineer", "body":"“The AI wrote a wonderfully confident explanation. I would now like it to write a wonderfully correct feature.”\n\nMaya points to a requirement: [b]Save must never place an order or charge money. Guests must sign in. Repeated taps should still save only one favorite.[/b]\n\n“Test a signed-in person, a guest, and someone tapping twice. We save favorites here, not surprise purchases.”", "choices":[{"label":"Got it. One favorite, no payment—even on a double tap.", "hint":"Take Maya's review notes back to your desk.", "effects":{"review_context":true}, "feedback":"Maya adds a test checklist to your ticket. It is shorter than the AI's explanation by approximately eleven paragraphs.", "next":""}]})
		else:
			if stage == "incident":
				incident_active = false
				incident_reached = true
				hud.set_incident(incident_seconds, false)
			_open_card(stage)
		return
	var chatter: Dictionary = {
		"desk":["Your desk", "Your AI assistant is displaying [b]“Thinking…”[/b]. It has been thinking about lunch for seven minutes.\n\nFollow the current objective first; the desk will still be here."],
		"mentor":["Maya · senior engineer", "“A good question usually saves more time than a very confident guess. Anyway, what are you working on?”\n\nMaya gestures toward your current task."],
		"manager":["Jordan · engineering manager", "“My door is always open. Except when it's closed, which is most of the time because we have an open-door strategy meeting.”\n\nYour scheduled 1:1 is on the day's agenda."],
		"standup":["The team huddle", "A whiteboard says [b]THIS MEETING COULD HAVE BEEN A MESSAGE[/b]. Someone has scheduled a meeting to discuss the whiteboard."],
		"kitchen":["The kitchenette", "The coffee machine is labeled [b]CRITICAL INFRASTRUCTURE[/b]. The toaster has requested a promotion."],
		"intern":["Sam · fellow intern", "“I have seventeen tabs open and I think at least one of them is documentation.”\n\nSam waves encouragingly. You should probably finish your current task."],
		"exit":["The elevator", "Your badge works. Your internship is still in progress.\n\nFinish the current objective before heading home."]
	}
	var lines: Array = chatter.get(id, ["Office", "There is probably a meeting about this."])
	_open_custom({"eyebrow":"AROUND THE OFFICE", "title":lines[0], "speaker":"SMALL BATCH · FLOOR 04", "body":lines[1], "choices":[{"label":"Back to it", "hint":"Follow the objective and the teal dot on the floor map.", "effects":{}, "feedback":"", "next":""}]}, true)

func _open_card(id: String) -> void:
	current_card_id = id
	current_card = Story.card(id)
	ambient = false
	pending_next = ""
	pending_advance = false
	player.set_active(false)
	hud.show_card(current_card)
	_play_tone(520.0, 0.055, 0.07)

func _open_custom(card: Dictionary, is_ambient: bool = false) -> void:
	current_card_id = "custom"
	current_card = card
	ambient = is_ambient
	pending_next = ""
	pending_advance = false
	player.set_active(false)
	hud.show_card(card)

func _choose(index: int) -> void:
	var choices: Array = current_card.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if current_card_id == "welcome":
		hud.hide_modal()
		_set_stage(0)
		player.set_active(true)
		return
	var effects: Dictionary = choice.get("effects", {})
	for key: String in effects:
		if stats.has(key) and not effects[key] is bool:
			stats[key] = clampi(int(stats[key]) + int(effects[key]), 0, 100)
		else:
			flags[key] = effects[key]
	if not ambient:
		evidence.append({"task":str(current_card.get("title", "")), "decision":str(choice.get("label", "")), "feedback":str(choice.get("feedback", ""))})
	pending_next = str(choice.get("next", ""))
	pending_advance = not ambient
	_update_hud()
	var feedback: String = str(choice.get("feedback", ""))
	if feedback.is_empty():
		_continue()
	else:
		var changes: PackedStringArray = []
		for key: String in ["delivery", "quality", "trust", "energy"]:
			if effects.has(key) and int(effects[key]) != 0:
				var value: int = int(effects[key])
				changes.append(("+" if value > 0 else "") + str(value) + " " + key.capitalize())
		if not changes.is_empty():
			feedback += "\n\n[color=#087f81]" + "   ·   ".join(changes) + "[/color]"
		hud.show_feedback(feedback)
		_play_tone(650.0, 0.06, 0.06)

func _continue() -> void:
	if not pending_next.is_empty():
		var next_id: String = pending_next
		pending_next = ""
		_open_card(next_id)
		return
	hud.hide_modal()
	if pending_advance:
		pending_advance = false
		_set_stage(stage_index + 1)
	player.set_active(not finished)

func _set_stage(index: int) -> void:
	stage_index = clampi(index, 0, STAGES.size()-1)
	_update_hud()
	if STAGES[stage_index] == "incident":
		incident_active = true
		incident_seconds = 45.0
		hud.set_incident(incident_seconds, true)
		_play_alarm()
	else:
		hud.set_incident(incident_seconds, false)

func _update_hud() -> void:
	if not is_instance_valid(hud):
		return
	player.energy = int(stats.energy)
	if stage_index < 0:
		hud.set_status(stats, "09:00", "FINAL DAY · CLOCKING IN")
		hud.set_objective("Welcome to Small Batch", "Your badge says intern. Your calendar says otherwise.")
	else:
		var stage: String = STAGES[stage_index]
		var objective: Array = OBJECTIVES[stage]
		hud.set_status(stats, TIMES[stage_index], "FINAL DAY · " + str(stage_index+1).pad_zeros(2) + "/10")
		var detail: String = str(objective[1])
		if stage == "incident" and int(stats.energy) < 25:
			detail += " Low energy: your sprint is slower."
		hud.set_objective(str(objective[0]), detail)

func _finish_day() -> void:
	finished = true
	incident_active = false
	player.set_active(false)
	hud.set_incident(0, false)
	var result: Dictionary = Story.ending(stats, flags)
	hud.show_ending(result, stats, evidence)
	var file := FileAccess.open("user://last_evaluation.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"stats":stats, "flags":flags, "result":result, "evidence":evidence}, "\t"))
	_play_tone(780.0, 0.22, 0.07)

func _resume() -> void:
	paused = false
	hud.hide_modal()
	player.set_active(true)

func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _quit() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().quit()

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	if capture_mode or test_mode:
		return
	var sample_rate: int = 22050
	var frames: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i: int in frames:
		var envelope: float = sin(PI * float(i) / float(frames))
		var value: int = int(sin(TAU * frequency * float(i) / sample_rate) * envelope * volume * 32767)
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	sound.stream = stream
	sound.play()

func _play_alarm() -> void:
	if capture_mode or test_mode:
		return
	_play_tone(880.0, 0.22, 0.13)
	await get_tree().create_timer(0.28).timeout
	if is_inside_tree() and incident_active:
		_play_tone(620.0, 0.28, 0.12)

func _capture_sequence() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	await _save_capture("01-welcome")
	_choose(0)
	player.rotation.y = 0.0
	await get_tree().create_timer(0.3).timeout
	await _save_capture("02-office")
	_open_card("feature")
	await _save_capture("03-feature")
	hud.hide_modal()
	player.set_active(false)
	_set_stage(8)
	await _save_capture("04-incident")
	stats = {"delivery":80, "quality":85, "trust":85, "energy":65}
	flags = {"clarified":true,"tested":true}
	_finish_day()
	await _save_capture("05-evaluation")
	get_tree().quit()

func _save_capture(filename: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_viewport().get_texture().get_image()
	var error: Error = screenshot.save_png("res://artifacts/" + filename + ".png")
	print("CAPTURE ", filename, " ", error)

func _smoke_test() -> void:
	await get_tree().process_frame
	var failures: Array[String] = []
	_choose(0)
	for step: int in STAGES.size() - 1:
		var stage: String = STAGES[stage_index]
		var target_id: String = str(STAGE_TARGETS[stage])
		_interact(target_id)
		var guard: int = 0
		while hud.is_modal_open() and guard < 8:
			if not pending_next.is_empty() or pending_advance:
				_continue()
			else:
				var choices: Array = current_card.get("choices", [])
				if choices.is_empty():
					failures.append("No choices at " + stage)
					break
				_choose(0)
			guard += 1
		if stage_index != step+1:
			failures.append("Stage progression failed: " + stage)
	_interact("exit")
	if not finished:
		failures.append("Ending not reached")
	for id: String in ["desk","mentor","manager","standup","kitchen","intern","exit"]:
		if not office.interaction_positions.has(id):
			failures.append("Missing target " + id)
	print("SMOKE TEST ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	print("FINAL STATS ", stats, " FLAGS ", flags)
	get_tree().quit(0 if failures.is_empty() else 1)

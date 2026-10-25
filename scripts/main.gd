extends Node3D

const OfficeScene = preload("res://scripts/office.gd")
const PlayerController = preload("res://scripts/player.gd")
const GameHUD = preload("res://scripts/hud.gd")
const Story = preload("res://content/story.gd")
const Workstation = preload("res://scripts/workstation.gd")
const PocketPhone = preload("res://scripts/phone.gd")

const STAGES: Array[String] = ["standup", "mentor", "feature", "review_info", "review", "intern", "manager", "kitchen", "incident", "exit"]
const STAGE_TARGETS: Dictionary = {"standup":"standup", "mentor":"desk", "feature":"desk", "review_info":"desk", "review":"desk", "intern":"desk", "manager":"manager", "kitchen":"kitchen", "incident":"desk", "exit":"exit"}
const TIMES: Array[String] = ["09:05", "09:30", "10:00", "11:15", "11:30", "13:00", "14:30", "15:15", "15:17", "17:00"]
const OBJECTIVES: Dictionary = {
	"standup":["Join standup", "Meeting area, back right."],
	"mentor":["Check your computer", "Maya sent you a Slack message."],
	"feature":["Check your computer", "Your feature ticket is ready."],
	"review_info":["Check your computer", "There is an update on your change request."],
	"review":["Check your computer", "Your change request needs a decision."],
	"intern":["Check your computer", "Sam sent you a Slack message."],
	"manager":["Meet Jordan", "Your 1:1 is in the manager's office."],
	"kitchen":["Make a coffee", "Take a cup. Brew. Drink."],
	"incident":["Get to your desk", "Shift to run. Coffee checkout is down."],
	"exit":["Head home", "Your evaluation is at the elevator."]
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
var computer: Node
var phone: CanvasLayer
var seated: bool = false
var seating: bool = false
var camera_tween: Tween
var decision_open: bool = false
var card_on_computer: bool = false
var cup_state: String = "none"
var held_cup: Node3D
var held_liquid: MeshInstance3D
var coffee_brewing: bool = false
var coffee_drank: bool = false
var coffee_boosted: bool = false
var phone_scrolls: int = 0
var phone_minutes: int = 0
var conversation_id: String = ""
var manager_sitting: bool = false
var office_rewards: Dictionary = {}
var web_drag_look: bool = false
var awaiting_person: String = ""
var pending_visit: String = ""
var work_card_id: String = ""
var work_stage_index: int = -1

func _ready() -> void:
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	office = OfficeScene.new()
	add_child(office)
	player = PlayerController.new()
	add_child(player)
	player.position = office.spawn_position
	player.interacted.connect(_interact)
	player.use_held_item.connect(_drink_coffee)
	hud = GameHUD.new()
	add_child(hud)
	hud.choice_selected.connect(_choose)
	hud.continue_pressed.connect(_continue)
	hud.resume_pressed.connect(_resume)
	hud.restart_pressed.connect(_restart)
	hud.quit_pressed.connect(_quit)
	computer = Workstation.new()
	add_child(computer)
	computer.setup(office.monitor_surface, player.camera)
	computer.choice_selected.connect(_choose)
	computer.continue_pressed.connect(_continue)
	computer.close_requested.connect(_stand_up)
	computer.phone_requested.connect(_open_phone)
	computer.task_requested.connect(_desk_work)
	computer.app_requested.connect(_desk_app)
	computer.sandbox_action.connect(_sandbox_action)
	computer.notification_received.connect(func(app: String, title: String) -> void:
		if not seated:
			hud.toast(app.capitalize() + " · " + title)
	)
	phone = PocketPhone.new()
	add_child(phone)
	phone.closed.connect(_phone_closed)
	phone.scrolled.connect(_phone_scrolled)
	_build_held_cup()
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
	var focus_text: String = player.focused_label if player.enabled else ""
	if OS.has_feature("web") and player.enabled and not hud.is_modal_open():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not web_drag_look:
			web_drag_look = true
			player.drag_look = true
			hud.toast("Use arrow keys or hold the right mouse button to look.")
	if player.enabled and focus_text.is_empty() and cup_state == "held_full":
		focus_text = "F  ·  Drink coffee"
	hud.set_focus(focus_text)
	if stage_index >= 0:
		var target_id: String = awaiting_person if not awaiting_person.is_empty() else str(STAGE_TARGETS[STAGES[stage_index]])
		var target: Vector3 = office.target_position(target_id)
		hud.set_distance(player.global_position.distance_to(target))
		hud.minimap.player_position = player.global_position
		hud.minimap.player_yaw = player.rotation.y
		hud.minimap.target_position = target
		hud.minimap.target_id = target_id
		hud.minimap.target_text = office.target_label(target_id).to_upper()
		hud.minimap.queue_redraw()
	if incident_active and not paused and not hud.is_modal_open():
		incident_seconds = maxf(0, incident_seconds - delta)
		hud.set_incident(incident_seconds, true)
		if incident_seconds <= 0:
			incident_active = false
			incident_penalties += 1
			stats.trust = maxi(0, int(stats.trust) - 10)
			flags["late_incident"] = true
			_update_hud()
			if phone.is_open():
				phone.close_phone()
			hud.toast("Maya paused orders. −10 trust. Get to your desk.")

func _input(event: InputEvent) -> void:
	if not is_instance_valid(phone):
		return
	if phone.is_open():
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
			phone.close_phone()
			get_viewport().set_input_as_handled()
		return
	if seated and not hud.is_modal_open():
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
			_stand_up()
			get_viewport().set_input_as_handled()
		elif not seating and computer.forward_input(event):
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if finished:
				return
			if paused:
				_resume()
			elif not hud.is_modal_open() and not seated and not phone.is_open():
				paused = true
				player.set_active(false)
				hud.show_pause()
			get_viewport().set_input_as_handled()

func _interact(id: String) -> void:
	if hud.is_modal_open() or finished or stage_index < 0 or seated:
		return
	if id == "intern" and flags.get("promised_sam", false) and not flags.get("kept_promise", false) and not flags.get("broke_promise", false) and stage_index >= 6:
		_start_conversation("intern")
		_open_card("promise_help", true)
		return
	if id == "desk":
		_sit_down()
		return
	if id == "phone":
		_sit_down(true)
		return
	if id in ["fridge", "drawer", "cup", "coffee_machine"]:
		_use_kitchen_object(id)
		return
	if id == "hr":
		_start_conversation("hr")
		if bool(flags.get("hr_resolved", false)):
			_open_custom({"title":"Your report is on file.", "speaker":"Alex · People Operations", "body":"“We have recorded your concern. You can get back to your day; you do not need to file it again.”", "choices":[{"label":"Thank you for following up.", "effects":{}, "feedback":"", "next":""}]}, true)
		else:
			_open_card("hr_complaint", true)
		return
	if id == "manager_seat":
		if STAGES[stage_index] == "manager":
			_start_conversation("manager")
			_open_card("manager")
		else:
			hud.toast("Jordan will be ready for your scheduled 1:1.")
		return
	if id in ["printer", "vending_machine", "snack", "water_cooler", "whiteboard", "water_plant"]:
		_use_office_object(id)
		return
	var stage: String = STAGES[stage_index]
	if not awaiting_person.is_empty() and id == awaiting_person:
		awaiting_person = ""
		_start_conversation(id)
		_open_card("mentor" if stage == "mentor" else ("review_context" if stage == "review_info" else "intern_help"))
		_update_hud()
		return
	if id == "kitchen" and stage == "kitchen":
		if coffee_drank:
			_open_card("kitchen")
		else:
			hud.toast("Grab a cup, use the machine, then F to drink.")
		return
	if id == str(STAGE_TARGETS[stage]):
		if id in ["standup", "mentor", "intern", "manager"]:
			_start_conversation(id)
		if stage == "exit":
			_finish_day()
		else:
			if stage == "incident":
				incident_active = false
				incident_reached = true
				hud.set_incident(incident_seconds, false)
			_open_card(stage)
		return
	var chatter: Dictionary = {"mentor":"Maya: “Clear questions. Small changes. More coffee.”", "manager":"Jordan: “Let's catch up at your 1:1.”", "standup":"This meeting could have been a message.", "kitchen":"A perfectly normal dependency on coffee.", "intern":"Sam: “Seventeen tabs. One might be documentation.”", "exit":"Finish your task before heading home."}
	for person: String in ["mentor", "manager", "intern"]:
		chatter[person] = _memory_line(str({"mentor":"Maya", "manager":"Jordan", "intern":"Sam"}[person]))
	if id in ["mentor", "manager", "standup", "intern"]:
		_start_conversation(id)
		_open_custom({"title":"A quick catch-up.", "speaker":office.target_label(id), "body":str(chatter[id]), "choices":[{"label":"I'll let you get back to work.", "effects":{}, "feedback":"", "next":""}]}, true)
	else:
		hud.toast(str(chatter.get(id, "Back to it.")))

func _open_card(id: String, is_ambient: bool = false) -> void:
	current_card_id = id
	current_card = Story.card(id)
	if id == "manager":
		current_card["body"] += "\n\n" + _memory_line("Jordan")
	ambient = is_ambient
	pending_next = ""
	pending_advance = false
	decision_open = true
	card_on_computer = seated
	if card_on_computer and not is_ambient:
		work_card_id = id
		work_stage_index = stage_index
	player.set_active(false)
	if card_on_computer:
		computer.show_card(current_card)
	else:
		hud.show_card(current_card)
	_play_tone(520.0, 0.055, 0.07)

func _open_custom(card: Dictionary, is_ambient: bool = false) -> void:
	current_card_id = "custom"
	current_card = card
	ambient = is_ambient
	pending_next = ""
	pending_advance = false
	decision_open = true
	card_on_computer = false
	player.set_active(false)
	hud.show_card(card)

func _choose(index: int) -> void:
	if not decision_open:
		return
	var choices: Array = current_card.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if current_card_id == "review" and index == 0 and not flags.get("sandbox_complete", false):
		computer.show_sandbox()
		return
	if current_card_id == "feature":
		for key: String in ["checked_member", "checked_guest", "checked_double", "sandbox_complete", "sandbox_patch", "lab_guest_guard", "lab_write_target", "lab_deduplicate"]:
			flags.erase(key)
	if current_card_id == "intern" and index == 1:
		flags["promised_sam"] = true
	if current_card_id == "promise_help" and index == 0:
		flags["kept_promise"] = true

	decision_open = false
	if current_card_id == "welcome":
		hud.hide_modal()
		_set_stage(0)
		player.set_active(true)
		return
	var previous_stats: Dictionary = stats.duplicate()
	var effects: Dictionary = choice.get("effects", {})
	for key: String in effects:
		if stats.has(key) and not effects[key] is bool:
			stats[key] = clampi(int(stats[key]) + int(effects[key]), 0, 100)
		else:
			flags[key] = effects[key]
	phone_minutes += int(choice.get("minutes", 0))
	pending_visit = str(choice.get("visit", ""))
	if not ambient or current_card_id.begins_with("hr_") or current_card_id in ["interruptions", "promise_help"]:
		evidence.append({"task":str(current_card.get("title", "")), "decision":str(choice.get("label", "")), "feedback":str(choice.get("feedback", ""))})
	pending_next = str(choice.get("next", ""))
	pending_advance = not ambient
	_update_hud()
	var changes: Dictionary = {}
	for key: String in stats:
		var change: int = int(stats[key]) - int(previous_stats[key])
		if change != 0:
			changes[key] = change
	var feedback: String = str(choice.get("feedback", ""))
	if feedback.is_empty() and changes.is_empty():
		_continue()
	else:
		if card_on_computer:
			computer.show_feedback(feedback, changes)
		else:
			hud.show_feedback(feedback, changes)
		_play_tone(650.0, 0.06, 0.06)

func _continue() -> void:
	if not pending_next.is_empty():
		var next_id: String = pending_next
		pending_next = ""
		_open_card(next_id, ambient)
		return
	if not pending_visit.is_empty():
		awaiting_person = pending_visit
		pending_visit = ""
		pending_advance = false
		hud.hide_modal()
		if seated:
			_stand_up()
		_update_hud()
		hud.toast("Go talk to %s, then return to your computer." % ("Maya" if awaiting_person == "mentor" else "Sam"))
		return
	hud.hide_modal()
	_end_conversation()
	if pending_advance:
		pending_advance = false
		_set_stage(stage_index + 1)
	if seated:
		computer.show_desktop(str(OBJECTIVES[STAGES[stage_index]][0]))
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		player.set_active(not finished)

func _set_stage(index: int) -> void:
	awaiting_person = ""
	pending_visit = ""
	work_card_id = ""
	work_stage_index = -1
	stage_index = clampi(index, 0, STAGES.size()-1)
	if stage_index == 3:
		flags["interruptions_started"] = true
	if stage_index >= 5 and flags.get("interruptions_started", false) and not flags.get("interruptions_done", false):
		flags["interruptions_done"] = true
		flags["missed_interruptions"] = true
		stats.delivery = maxi(0, int(stats.delivery) - 4)
		stats.trust = maxi(0, int(stats.trust) - 3)
		evidence.append({"task":"Competing requests", "decision":"You left all three requests unanswered.", "feedback":"Maya repaired the build. Sam missed rehearsal, and Jordan waited. Delivery -4; Trust -3."})
	if stage_index == 9 and flags.get("promised_sam", false) and not flags.get("kept_promise", false) and not flags.get("broke_promise", false):
		flags["broke_promise"] = true
		stats.trust = maxi(0, int(stats.trust) - 5)
		evidence.append({"task":"A promise to Sam", "decision":"You left without checking back.", "feedback":"Sam remembers the missed promise. Trust -5."})
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
	if is_instance_valid(computer) and stage_index >= 0:
		computer.set_work_state(STAGES[stage_index], flags, awaiting_person)
	if stage_index < 0:
		hud.set_status(stats, "09:00", "FINAL DAY · CLOCKING IN")
		hud.set_objective("Your final day", "")
	else:
		var stage: String = STAGES[stage_index]
		var objective: Array = OBJECTIVES[stage]
		var base_parts: PackedStringArray = TIMES[stage_index].split(":")
		var minutes: int = mini(1439, int(base_parts[0]) * 60 + int(base_parts[1]) + phone_minutes)
		var clock_text: String = "%02d:%02d" % [minutes / 60, minutes % 60]
		hud.set_status(stats, clock_text, "FINAL DAY")
		var detail: String = str(objective[1])
		if stage == "kitchen":
			var coffee_steps: Dictionary = {"none":"Take a cup from the counter.", "held":"Use the coffee machine.", "machine":"Let it brew.", "filled":"Pick up your coffee.", "held_full":"F to drink."}
			detail = str(coffee_steps.get(cup_state, "Take a break."))
		if stage == "incident" and int(stats.energy) < 25:
			detail += " Low energy: your sprint is slower."
		hud.set_objective(str(objective[0]), detail)
		if not awaiting_person.is_empty():
			hud.set_objective("Talk to Maya" if awaiting_person == "mentor" else "Talk to Sam", "You chose to ask in person.")

func _finish_day() -> void:
	finished = true
	incident_active = false
	player.set_active(false)
	hud.set_incident(0, false)
	_update_hud()
	var result: Dictionary = Story.ending(stats, flags)
	hud.show_ending(result, stats, evidence)
	if not capture_mode and not test_mode:
		var file := FileAccess.open("user://last_evaluation.json", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"stats":stats, "flags":flags, "result":result, "evidence":evidence}, "\t"))
	_play_tone(780.0, 0.22, 0.07)

func _start_conversation(id: String) -> void:
	conversation_id = id
	manager_sitting = id == "manager"
	player.set_active(false)
	player.camera_locked = true
	held_cup.visible = false
	hud.set_conversation(true)
	var face: Vector3 = office.conversation_position(id)
	var eye: Vector3 = player.camera.global_position
	if manager_sitting:
		eye = office.manager_seat_eye
	var forward: Vector3 = (face - eye).normalized()
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var aim: Vector3 = face + right * eye.distance_to(face) * 0.25
	var target := Transform3D(Basis.IDENTITY, eye).looking_at(aim, Vector3.UP)
	if is_instance_valid(camera_tween):
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(player.camera, "global_transform", target, 0.36)
	camera_tween.tween_property(player.camera, "fov", 61.0, 0.36)
	office.face_person(id, eye)

func _end_conversation() -> void:
	if conversation_id.is_empty():
		return
	if is_instance_valid(camera_tween):
		camera_tween.kill()
	var face: Vector3 = office.conversation_position(conversation_id)
	if manager_sitting:
		player.global_position = office.manager_stand_position
	var direction: Vector3 = face - player.global_position
	player.rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
	player.camera.position = Vector3(0, 1.66, 0)
	player.camera.rotation = Vector3.ZERO
	player.camera.fov = 78.0
	player.camera_locked = false
	conversation_id = ""
	manager_sitting = false
	held_cup.visible = cup_state in ["held", "held_full"]
	hud.set_conversation(false)

func _use_office_object(id: String) -> void:
	match id:
		"printer":
			if office.printer_jammed:
				office.clear_printer()
				_office_reward("printer", {"quality":3}, 3)
				hud.toast("You cleared the jam. The printer resumes its one job.")
			else:
				office.print_page()
				hud.toast("Your page says: this could have been a PDF.")
		"vending_machine":
			if office.snack_available:
				hud.toast("Your snack is waiting in the tray.")
			else:
				office.dispense_snack()
				hud.toast("Your snack has passed the deployment pipeline.")
		"snack":
			if office.snack_available:
				office.take_snack()
				_office_reward("snack", {"energy":6}, 2)
				hud.toast("You ate the snack. No sprint planning required.")
		"water_cooler":
			office.use_water_cooler()
			_office_reward("water", {"energy":4}, 1)
			hud.toast("You drank some water. Your kidneys approve.")
		"whiteboard":
			office.update_whiteboard()
			_office_reward("whiteboard", {"quality":2}, 2)
			hud.toast("You moved the mystery ticket into Needs clarification.")
		"water_plant":
			office.water_plant()
			_office_reward("plant", {"energy":3}, 1)
			hud.toast("You watered the office plant. Its performance review improves.")
	_update_hud()

func _office_reward(id: String, effects: Dictionary, minutes: int) -> void:
	if office_rewards.has(id):
		return
	office_rewards[id] = true
	phone_minutes += minutes
	for key: String in effects:
		stats[key] = clampi(int(stats[key]) + int(effects[key]), 0, 100)

func _sit_down(pick_up_phone: bool = false) -> void:
	if seated or finished:
		return
	seated = true
	seating = true
	player.set_active(false)
	player.camera_locked = true
	held_cup.visible = false
	hud.set_seated(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var target: Transform3D = Transform3D(Basis.IDENTITY, office.seat_eye).looking_at(office.seat_look, Vector3.UP)
	if is_instance_valid(camera_tween):
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(player.camera, "global_transform", target, 0.42)
	camera_tween.tween_property(player.camera, "fov", 53.0, 0.42)
	camera_tween.finished.connect(func() -> void:
		if not seated:
			return
		seating = false
		computer.set_active(true)
		if pick_up_phone:
			computer.show_desktop(str(OBJECTIVES[STAGES[stage_index]][0]))
			_open_phone()
		else:
			computer.show_desktop(str(OBJECTIVES[STAGES[stage_index]][0]))
	, CONNECT_ONE_SHOT)

func _stand_up() -> void:
	if not seated:
		return
	if pending_advance:
		_continue()
		if not seated:
			return
	if phone.is_open():
		phone.close_phone()
	if is_instance_valid(camera_tween):
		camera_tween.kill()
	seated = false
	seating = false
	decision_open = false
	card_on_computer = false
	computer.set_active(false)
	computer.show_desktop(str(OBJECTIVES[STAGES[stage_index]][0]))
	player.global_position = office.stand_position
	player.rotation = Vector3.ZERO
	player.camera.position = Vector3(0, 1.66, 0)
	player.camera.rotation = Vector3.ZERO
	player.camera.fov = 78.0
	player.camera_locked = false
	held_cup.visible = cup_state in ["held", "held_full"]
	hud.set_seated(false)
	player.set_active(true)

func _desk_work() -> void:
	if not seated or seating or phone.is_open():
		return
	if pending_advance:
		_continue()
		return
	var stage: String = STAGES[stage_index]
	if not awaiting_person.is_empty():
		_open_card("waiting_maya" if awaiting_person == "mentor" else "waiting_sam", true)
		return
	if stage in ["mentor", "feature", "review_info", "review", "intern", "incident"]:
		if stage == "incident":
			incident_active = false
			incident_reached = true
			hud.set_incident(0, false)
		if work_stage_index == stage_index and not work_card_id.is_empty():
			_open_card(work_card_id)
		else:
			var card_id: String = str({"mentor":"inbox_mentor", "review_info":"review_notice"}.get(stage, stage))
			if stage == "review" and bool(flags.get("early_merge", false)):
				card_id = "review_followup"
			_open_card(card_id)
	else:
		decision_open = false
		computer.show_desktop(str(OBJECTIVES[stage][0]))

func _desk_app(app: String) -> void:
	if not seated or seating or phone.is_open():
		return
	var stage: String = STAGES[stage_index]
	if app == "source":
		computer.show_source()
		return
	if app == "tests":
		computer.show_test_runner()
		return
	if app == "sandbox":
		computer.show_sandbox()
		return
	if app == "triage":
		_open_card("interruptions", true)
		return
	if app.begins_with("notice:"):
		app = str({"notice:slack":("triage" if stage == "review_info" and not flags.get("interruptions_done", false) else "dm:" + ("Sam" if stage == "intern" else "Maya")), "notice:ai":"ai_task", "notice:changes":"cr:104"}.get(app, "task"))
	if app == "triage":
		_open_card("interruptions", true)
		return
	if app == "task" or (app == "ai_task" and stage == "feature" and work_card_id != "push_cr") or (app == "dm:Maya" and stage == "mentor") or (app == "dm:Sam" and stage == "intern"):
		_desk_work()
	elif app == "cr:104" and (stage in ["review_info", "review", "incident"] or (stage == "feature" and work_card_id == "push_cr")):
		_desk_work()
	elif app.begins_with("dm:"):
		computer.show_slack(app.trim_prefix("dm:"), false)
	elif app == "ai_task":
		computer.show_ai_task_history()
	elif app == "slack":
		computer.show_slack()
	elif app == "changes":
		computer.show_change_request()
	elif app == "cr:104":
		computer.show_cr_detail(104)
	else:
		computer.show_ai_idle()

func _sandbox_action(action: String) -> void:
	if action.begins_with("pass:"):
		flags["checked_" + action.trim_prefix("pass:")] = true
	elif action.begins_with("edit:"):
		var parts: PackedStringArray = action.split(":")
		flags["lab_" + parts[1]] = parts[2] if parts[1] == "write_target" else parts[2] == "true"
		for scenario: String in ["member", "guest", "double"]:
			flags.erase("checked_" + scenario)
	elif action == "patch":
		flags["sandbox_patch"] = true
		for scenario: String in ["member", "guest", "double"]:
			flags.erase("checked_" + scenario)
	flags["sandbox_complete"] = bool(flags.get("checked_member", false)) and bool(flags.get("checked_guest", false)) and bool(flags.get("checked_double", false))
	_update_hud()

func _memory_line(person: String) -> String:
	if person == "Maya":
		if flags.get("early_merge", false):
			return "Maya: ‘I remember that early merge. Attach evidence this time; confidence isn't a test result.’"
		if flags.get("clarified", false):
			return "Maya: ‘You asked about the guest case before building. That made this easier to review.’"
		if flags.get("prioritized_meeting", false):
			return "Maya: ‘I had to unstick the demo build while you were in that meeting. Please tell us when you're leaving it blocked.’"
		if flags.get("missed_interruptions", false):
			return "Maya: ‘I covered the demo build while everyone waited. Next time, please answer the triage thread.’"
		return "Maya: ‘Send me the exact behavior you checked, and I'll review it.’"
	if person == "Sam":
		if flags.get("kept_promise", false):
			return "Sam: ‘You came back like you promised. Next time I get stuck, I'm asking you first.’"
		if flags.get("broke_promise", false):
			return "Sam: ‘I waited for you. A clear no would've helped me plan.’"
		if flags.get("helped", false) or flags.get("prioritized_sam", false):
			return "Sam: ‘Thanks for making time when I was stuck. I owe you a demo rehearsal.’"
		return "Sam: ‘Seventeen tabs. One might be documentation.’"
	if flags.get("honest", false):
		return "Jordan remembers: ‘You were honest about being blocked at standup. Keep giving me that kind of update.’"
	if flags.get("optimistic", false):
		return "Jordan remembers: ‘At standup you said it was almost done. That made the later delays a surprise.’"
	return "Jordan: ‘I'd rather hear about a problem early than discover it at the demo.’"

func _open_phone() -> void:
	if not seated or seating or phone.is_open():
		return
	computer.set_active(false)
	office.set_phone_visible(false)
	phone.open_phone()

func _phone_closed() -> void:
	office.set_phone_visible(true)
	if seated:
		computer.set_active(true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		player.set_active(not finished and not hud.is_modal_open())

func _phone_scrolled(count: int) -> void:
	phone_scrolls += count
	phone_minutes += count * 2
	if phone_scrolls % 5 == 0:
		stats.delivery = maxi(0, int(stats.delivery) - 2)
		hud.toast("Ten minutes vanished. The algorithm thanks you.")
	_update_hud()

func _use_kitchen_object(id: String) -> void:
	match id:
		"fridge":
			var opened: bool = office.toggle_fridge()
			hud.toast("Cold water. Suspiciously old lunch." if opened else "Fridge closed.")
		"drawer":
			var opened: bool = office.toggle_drawer()
			hud.toast("Spare cups. No spare deadlines." if opened else "Drawer closed.")
		"cup":
			if cup_state == "none":
				cup_state = "held"
				office.set_cup_state("held")
				held_cup.visible = true
				held_liquid.visible = false
				hud.toast("Cup acquired. Find the coffee machine.")
			elif cup_state == "filled":
				_take_coffee()
			elif cup_state in ["held", "held_full"]:
				hud.toast("Already holding a cup.")
		"coffee_machine":
			if coffee_brewing:
				hud.toast("Brewing…")
			elif cup_state == "filled":
				_take_coffee()
			elif cup_state == "held":
				_start_brewing()
			elif cup_state == "held_full":
				hud.toast("F to drink your coffee.")
			else:
				hud.toast("Take a cup from the counter first.")
	_update_hud()

func _take_coffee() -> void:
	cup_state = "held_full"
	office.set_cup_state("held")
	held_cup.visible = true
	held_liquid.visible = true
	hud.toast("Coffee ready. F to drink.")
	_update_hud()

func _start_brewing() -> void:
	coffee_brewing = true
	cup_state = "machine"
	held_cup.visible = false
	office.set_cup_state("machine")
	office.set_coffee_brewing(true)
	hud.toast("Brewing…")
	_update_hud()
	await get_tree().create_timer(2.8).timeout
	if not is_inside_tree():
		return
	coffee_brewing = false
	cup_state = "filled"
	office.set_cup_state("filled")
	office.set_coffee_brewing(false)
	hud.toast("Ready. Pick up your coffee.")
	_update_hud()
	_play_tone(720.0, 0.07, 0.05)

func _drink_coffee() -> void:
	if cup_state != "held_full" or hud.is_modal_open() or seated:
		return
	cup_state = "none"
	coffee_drank = true
	held_cup.visible = false
	office.set_cup_state("counter")
	if not coffee_boosted:
		stats.energy = mini(100, int(stats.energy) + 12)
		coffee_boosted = true
	_update_hud()
	hud.toast("Human infrastructure restored.")
	if STAGES[stage_index] == "kitchen":
		_open_card("kitchen")

func _build_held_cup() -> void:
	held_cup = Node3D.new()
	held_cup.name = "Held coffee cup"
	player.camera.add_child(held_cup)
	held_cup.position = Vector3(0.35, -0.35, -0.62)
	held_cup.rotation_degrees = Vector3(0, -15, -8)
	var ceramic := StandardMaterial3D.new()
	ceramic.albedo_color = Color("ed9c7d")
	ceramic.roughness = 0.55
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.085
	cylinder.bottom_radius = 0.07
	cylinder.height = 0.18
	mesh.mesh = cylinder
	mesh.material_override = ceramic
	held_cup.add_child(mesh)
	var handle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.035
	ring.outer_radius = 0.06
	handle.mesh = ring
	handle.material_override = ceramic
	handle.position.x = 0.09
	handle.rotation_degrees.x = 90
	held_cup.add_child(handle)
	held_liquid = MeshInstance3D.new()
	var surface := CylinderMesh.new()
	surface.top_radius = 0.07
	surface.bottom_radius = 0.07
	surface.height = 0.006
	var coffee := StandardMaterial3D.new()
	coffee.albedo_color = Color("453127")
	held_liquid.mesh = surface
	held_liquid.material_override = coffee
	held_liquid.position.y = 0.086
	held_cup.add_child(held_liquid)
	held_cup.visible = false

func _resume() -> void:
	paused = false
	hud.hide_modal()
	player.set_active(true)

func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _quit() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if OS.has_feature("web"):
		_restart()
	else:
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
	var ignore_file := FileAccess.open("res://artifacts/.gdignore", FileAccess.WRITE)
	if ignore_file != null:
		ignore_file.close()
	await _save_capture("01-welcome")
	_choose(0)
	player.rotation.y = 0.0
	await get_tree().create_timer(0.3).timeout
	await _save_capture("02-office")
	_set_stage(6)
	_interact("manager_seat")
	await get_tree().create_timer(0.5).timeout
	await _save_capture("10-manager-meeting")
	_choose(0)
	_continue()
	_choose(0)
	_continue()
	player.global_position = Vector3(1.1, 0, -7.2)
	_interact("hr")
	await get_tree().create_timer(0.5).timeout
	await _save_capture("11-hr-complaint")
	_choose(2)
	_continue()
	_choose(0)
	_continue()
	_set_stage(1)
	_sit_down()
	await get_tree().create_timer(0.5).timeout
	await _save_capture("16-desktop")
	_desk_work()
	await _save_capture("12-slack-ticket")
	_stand_up()
	_set_stage(2)
	_sit_down()
	await get_tree().create_timer(0.6).timeout
	_desk_work()
	await _save_capture("03-computer")
	_choose(1)
	await _save_capture("04-computer-feedback")
	_continue()
	await _save_capture("13-draft-change-request")
	_choose(0)
	_continue()
	computer.show_slack()
	await _save_capture("14-slack-inbox")
	_desk_work()
	await _save_capture("15-review-comments")
	_open_phone()
	await get_tree().create_timer(0.4).timeout
	await _save_capture("05-phone")
	phone.close_phone()
	_stand_up()
	_set_stage(7)
	player.set_active(false)
	var fridge_target: Vector3 = office.target_position("fridge")
	player.position = Vector3(fridge_target.x + 2.2, 0, fridge_target.z - 1.4)
	player.camera.look_at(fridge_target)
	office.toggle_fridge()
	office.toggle_drawer()
	await get_tree().create_timer(0.5).timeout
	await _save_capture("06-kitchen")
	_use_kitchen_object("cup")
	_use_kitchen_object("coffee_machine")
	var machine_target: Vector3 = office.target_position("coffee_machine")
	player.position = Vector3(machine_target.x + 2.1, 0, machine_target.z + 1.4)
	player.camera.look_at(machine_target)
	await get_tree().create_timer(0.8).timeout
	await _save_capture("07-coffee")
	await get_tree().create_timer(1.8).timeout
	_use_kitchen_object("cup")
	_drink_coffee()
	_choose(0)
	_continue()
	await _save_capture("08-pager")
	_set_stage(9)
	stats = {"delivery":80, "quality":85, "trust":85, "energy":65}
	flags = {"clarified":true,"tested":true}
	_finish_day()
	await _save_capture("09-evaluation")
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
		if stage == "kitchen":
			_interact("cup")
			_interact("coffee_machine")
			await get_tree().create_timer(2.9).timeout
			_interact("coffee_machine")
			_drink_coffee()
		else:
			_interact(target_id)
		if seating:
			await get_tree().create_timer(0.5).timeout
		if seated:
			_desk_work()
		var guard: int = 0
		while (hud.is_modal_open() or decision_open or pending_advance or not awaiting_person.is_empty()) and guard < 16:
			if not awaiting_person.is_empty() and not decision_open and not hud.is_modal_open():
				_interact(awaiting_person)
			elif not pending_next.is_empty() or pending_advance:
				_continue()
			else:
				var choices: Array = current_card.get("choices", [])
				if choices.is_empty():
					failures.append("No choices at " + stage)
					break
				if current_card_id == "review" and not flags.get("sandbox_complete", false):
					_sandbox_action("patch")
					for scenario: String in ["member", "guest", "double"]:
						_sandbox_action("pass:" + scenario)
				_choose(0)
			guard += 1
		if seated:
			_stand_up()
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

extends SceneTree
## Integration coverage for real mouse clicks on a 3D monitor and the phone input path.

var game: Node3D
var failures: Array[String] = []
var checks: int = 0
var completed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0).timeout.connect(_timeout)
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await _frames(5)
	await _tap(KEY_1)
	_check(game.stage_index == 0 and game.player.enabled, "Real numeric input clocks in")
	_check(not _contains_old_instructions(game.hud), "Walking HUD omits the old decision footer and global control instructions")
	_check(not game.hud.minimap.visible, "The old always-on minimap is hidden")
	_check(game.hud._stats_panel.is_visible_in_tree(), "All four meter values remain visible while walking")
	_check(game.hud._root.theme.default_font.resource_path == "res://assets/fonts/Inter.ttf", "The HUD uses the bundled OFL font")

	# Only the assignment is arranged directly; seating and task completion use real input.
	game._set_stage(2)
	var target: Vector3 = game.office.target_position("desk")
	var found: bool = await _stand_near("desk", target)
	_check(found, "A clear floor vantage sees the desk through the player's ray")
	if not found:
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	_check(game.seated and not game.seating and game.computer.active, "E sits down and enables the physical computer")
	_check(game.player.camera.global_position.distance_to(game.office.seat_eye) < 0.025, "Seated camera reaches the office seat position")
	var aim: Vector3 = (game.office.monitor_surface.global_position - game.player.camera.global_position).normalized()
	_check((-game.player.camera.global_basis.z).dot(aim) > 0.999, "Seated camera looks at the center of the actual monitor")
	_check(not game.hud._objective.visible and not game.hud._clock.visible, "Seating hides the walking HUD")
	_check(game.hud._stats_panel.is_visible_in_tree(), "Seating keeps the four meter values visible")
	_check(game.computer._root.theme.default_font.resource_path == "res://assets/fonts/Inter.ttf", "The physical desktop uses the bundled font")
	_check(not game.computer._window.visible and game.computer._menu_app.text == "Finder", "Sitting down starts on the macOS-inspired desktop")
	_check(game.computer._dock_buttons.size() == 6 and game.computer._dock_buttons["changes"].icon is Texture2D, "The dock contains six actual app icons")
	_check(game.computer._app_unread["ai"] > 0, "A feature assignment creates a BatchGPT notification badge")
	_check(game.computer._dock_badges["ai"].visible and game.computer._desktop_badges["ai"].visible, "The assigned app has a red dot on desktop and dock")
	game._set_stage(1)
	_check(game.computer._thread_has_task("slack", "Maya"), "The assignment marks Maya's DM")
	await _click_monitor_button(game.computer._slack_button)
	await _click_monitor_button(_find_button(game.computer._window, "Maya"))
	_check(game.current_card_id == "inbox_mentor" and game.card_on_computer, "Maya DM opens her actionable message directly")
	_check(game.computer._dock_badges["slack"].visible, "Reading Maya's DM keeps its task dot until the task is resolved")
	var draft_stats: Dictionary = game.stats.duplicate(true)
	var reply_label: String = game.computer._slack_reply_text(1)
	await _click_monitor_button(_find_button(game.computer._window, reply_label))
	_check(game.computer._slack_draft.text == reply_label and not game.computer._slack_send.disabled, "Slack suggestions fill a reply composer and enable Send")
	_check(game.stats == draft_stats and not game.computer._feedback, "Drafting a Slack reply does not submit the task")
	await _click_monitor_button(game.computer._slack_send)
	_check(game.computer._messages.back()["sender"].begins_with("You") and game.computer._messages.back()["text"] == reply_label, "Send posts the selected reply into the actual DM history")
	await _click_monitor_button(_find_button(game.computer._window, "Continue working."))
	_check(game.current_card_id == "mentor", "Sending the question opens Maya's follow-up in the conversation")
	game.evidence.clear()
	game._set_stage(2)
	_check(not game.computer._dock_badges["slack"].visible and game.computer._thread_has_task("ai", "Save favorites (task)"), "Task dots move to BatchGPT when the assignment changes")
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.computer._app == "ai" and game.computer._accent == Color("158173"), "The feature opens in BatchGPT's green chat workspace")
	var default_window_size: Vector2 = game.computer._window.size
	await _click_monitor_button(_find_button(game.computer._window, "Zoom this window."))
	_check(game.computer._window.size.x > default_window_size.x, "The green traffic light zooms the app window")
	await _click_monitor_button(_find_button(game.computer._window, "Zoom this window."))
	await _click_monitor_button(_find_button(game.computer._window, "Minimize this window."))
	_check(not game.computer._window.visible, "The yellow traffic light minimizes back to the desktop")
	var before_desktop_key: Dictionary = game.stats.duplicate(true)
	await _tap(KEY_1)
	_check(game.stats == before_desktop_key, "Number keys on the desktop cannot choose a hidden app option")
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.computer.is_card_open() and game.current_card_id == "feature", "Feature appears inside the monitor")
	await _click_monitor_button(_find_button(game.computer._window, "Close this window."))
	_check(not game.computer._window.visible and game.computer._menu_app.text == "Finder", "The visible X closes an unanswered app window to the desktop")
	var before_closed_key: Dictionary = game.stats.duplicate(true)
	await _tap(KEY_1)
	_check(game.stats == before_closed_key and game.stage_index == 2, "Closing an unanswered prompt makes no decision and blocks hidden choices")
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.current_card_id == "feature" and game.computer._window.visible, "The unchosen feature draft reopens after closing with X")
	var decision_copy: String = ""
	for label: Node in game.computer._window.find_children("*", "RichTextLabel", true, false):
		decision_copy += str(label.text)
	_check(not decision_copy.contains(str(game.current_card["decision"])), "Choices appear without a redundant question explaining the available options")

	var lab = load("res://content/engineering_lab.gd")
	var broken: Array = lab.suite({"guest_guard":false, "write_target":"orders", "deduplicate":false})
	_check(not broken[0]["passed"] and not broken[1]["passed"] and not broken[2]["passed"], "The actual ordering bug fails all three executable tests")
	var partial: Array = lab.suite({"guest_guard":true, "write_target":"orders", "deduplicate":false})
	_check(partial[1]["passed"] and not partial[0]["passed"], "Adding only the guest guard fixes that case without hiding the purchase bug")
	# History and free chat must never advance the assigned work.
	var browsing_stats: Dictionary = game.stats.duplicate(true)
	await _click_monitor_button(_find_button(game.computer._window, "New chat"))
	_check(is_instance_valid(game.computer._chat_input), "New chat has an actual text composer")
	await _click_monitor_button(game.computer._chat_input)
	for character: String in "test save 123":
		var typed := InputEventKey.new()
		typed.pressed = true
		typed.unicode = character.unicode_at(0)
		Input.parse_input_event(typed)
		await process_frame
	_check(game.computer._chat_input.text == "test save 123", "Monitor forwards typed letters and numbers into the AI composer")
	await _click_monitor_button(_find_button(game.computer._window, "Send"))
	await create_timer(0.6).timeout
	var chat_index: int = game.computer._active_chat
	_check(game.computer._chats[chat_index]["messages"].size() == 2, "Typed prompt gets a local assistant response")
	var first_reply: String = game.computer._chats[chat_index]["last_reply"]
	game.computer._chat_input.text = "test save 123"
	await _click_monitor_button(_find_button(game.computer._window, "Send"))
	await create_timer(0.6).timeout
	_check(game.computer._chats[chat_index]["last_reply"] != first_reply, "Random replies avoid repeating the last answer")
	await _click_monitor_button(game.computer._dock_buttons["changes"])
	await _click_monitor_button(_find_button(game.computer._window, "Open CR #101"))
	_check(game.computer._selected_cr == 101, "Historical change requests open independently")
	await _click_monitor_button(_find_button(game.computer._window, "Files changed"))
	_check(game.computer._cr_tab == "Files changed", "CR files tab opens its own diff")
	await _click_monitor_button(_find_button(game.computer._window, "Checks"))
	_check(game.computer._cr_tab == "Checks", "CR checks tab opens its own results")
	_check(game.stats == browsing_stats and game.stage_index == 2, "Browsing and free chats do not change workday stats")
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))

	var before: Dictionary = game.stats.duplicate(true)
	var options: Array = game.current_card.get("choices", [])
	var wanted: String = str(options[1].get("label", ""))
	var selected: Button = _find_button(game.computer._window, wanted)
	_check(is_instance_valid(selected), "The safe AI prompt is an actual monitor Button")
	if not is_instance_valid(selected):
		_finish()
		return
	await _click_monitor_button(selected)
	_check(bool(game.flags.get("clear_prompt", false)), "Clicking the physical prompt records clear_prompt")
	_check(int(game.stats.delivery) == int(before.delivery) + 14, "Prompt click applies delivery exactly once")
	_check(int(game.stats.quality) == int(before.quality) + 15, "Prompt click applies quality exactly once")
	_check(int(game.stats.trust) == int(before.trust) + 5, "Prompt click applies trust exactly once")
	_check(int(game.stats.energy) == int(before.energy) - 6, "Prompt click applies energy exactly once")
	var feedback_labels: Array[String] = []
	for label: Node in game.computer._window.find_children("*", "Label", true, false):
		feedback_labels.append(str(label.text))
	_check("Delivery +14" in feedback_labels and "Quality +15" in feedback_labels and "Trust +5" in feedback_labels and "Energy -6" in feedback_labels, "Physical monitor feedback displays the gains and loss from the clicked prompt")
	_check(game.evidence.size() == 1 and not game.decision_open and game.pending_advance, "One click submits one decision and opens feedback")
	var applied: Dictionary = game.stats.duplicate(true)
	var next: Button = _find_button(game.computer._window, "Continue working.")
	_check(is_instance_valid(next), "Feedback has a real Continue button on the screen")
	if not is_instance_valid(next):
		_finish()
		return
	await _click_monitor_button(_find_button(game.computer._window, "Close this window."))
	_check(not game.computer._window.visible and game.stats == applied, "X closes a submitted update without applying its effects again")
	await _click_monitor_button(game.computer._slack_button)
	_check(game.computer._app == "slack" and game.computer._window.visible, "Closing feedback does not force that old update to reopen when another app is chosen")
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.stage_index == 2 and game.current_card_id == "push_cr", "After building, the monitor opens a draft CR instead of skipping submission")
	_check(not bool(game.flags.get("cr_submitted", false)), "Draft CR is not submitted before its Push button is clicked")
	var leave_draft: Button = _find_button(game.computer._root, "Stand up from my desk.")
	await _click_monitor_button(leave_draft)
	await _stand_near("desk", game.office.target_position("desk"))
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.current_card_id == "push_cr" and game.stats == applied, "Returning to the desk resumes the draft without farming AI-prompt effects")
	_check(game.computer._app == "changes" and game.computer._accent == Color("238449"), "Changes uses its own repository workspace and green review accent")
	await _click_monitor_button(_find_button(game.computer._window, "I'll push CR #104 and request Maya's review."))
	_check(bool(game.flags.get("cr_submitted", false)), "The physical Push button submits CR #104")
	await _click_monitor_button(_find_button(game.computer._window, "Continue working."))
	_check(game.stage_index == 3 and not game.computer.is_card_open(), "Submitting the CR unlocks the review notification")
	_check(game.stats == applied and game.evidence.size() == 2, "Submission preserves feature effects and records its own action once")
	var stand: Button = _find_button(game.computer._root, "Stand up from my desk.")
	await _click_monitor_button(stand)
	_check(not game.seated and game.player.enabled and not game.computer.active, "Physical Stand up button restores walking")
	_check(game.player.global_position.distance_to(game.office.stand_position) < 0.1, "Standing returns the body to a clear floor position")
	var standing: Vector3 = game.player.global_position
	_key(KEY_S, true)
	await _frames(18)
	_key(KEY_S, false)
	await _frames(5)
	_check(game.player.global_position.distance_to(standing) > 0.5, "The body moves again after standing")

	# Pick up the real desk prop, then scroll the feed through both supported input paths.
	var phone_target: Vector3 = game.office.target_position("phone")
	var phone_found: bool = await _stand_near("phone", phone_target)
	_check(phone_found, "The physical desk phone is reachable by the interaction ray")
	if not phone_found:
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	_check(game.seated and game.phone.is_open(), "E picks up the phone and opens its screen")
	_check(not game.office._phone_root.visible, "Picking up the phone hides its desk prop")
	_check(game.hud._stats_panel.is_visible_in_tree() and game.hud._stats_layer.layer > game.phone.layer, "The four meter values stay above the open phone")
	var original_post: int = game.phone._post_index
	var original_minutes: int = game.phone_minutes
	await _tap(KEY_DOWN)
	_check(game.phone._post_index != original_post and game.phone_minutes == original_minutes + 2, "Down arrow changes the feed post and spends two minutes")
	var after_arrow: int = game.phone._post_index
	var wheel := InputEventMouseButton.new()
	wheel.position = root.get_final_transform() * game.phone._screen.get_global_rect().get_center()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	Input.parse_input_event(wheel)
	await process_frame
	wheel.pressed = false
	Input.parse_input_event(wheel)
	await process_frame
	_check(game.phone._post_index != after_arrow and game.phone_minutes == original_minutes + 4, "Mouse wheel changes the next post and spends another two minutes")
	await _tap(KEY_ESCAPE)
	_check(not game.phone.is_open() and game.office._phone_root.visible, "Escape puts the phone back on the desk")
	_check(game.seated and game.computer.active, "Closing the phone returns input to the seated computer")
	await _click_monitor_button(game.computer._slack_button)
	_check(game.computer._app == "slack" and game.computer._accent == Color("68406e") and game.computer._slack_badge.visible, "Slack keeps a task dot while the triage requests remain unresolved")
	await _click_monitor_button(_find_button(game.computer._window, "# reviews"))
	_check(game.computer._slack_channel == "# reviews", "Slack's channel sidebar opens the selected review feed")
	var slack_copy: String = ""
	for label: Node in game.computer._window.find_children("*", "RichTextLabel", true, false):
		slack_copy += str(label.text)
	_check(slack_copy.contains("two comments"), "Slack shows the received CR-review message in its actual message feed")
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.current_card_id == "review_notice" and game.card_on_computer, "Opening the message leads to actionable review comments on the computer")
	var review_copy: String = ""
	for label: Node in game.computer._window.find_children("*", "Label", true, false):
		review_copy += str(label.text)
	_check(review_copy.contains("Original description") and review_copy.contains("Maya requested changes") and review_copy.contains("double"), "The active CR shows the original change and Maya's inline review comments")
	await _click_monitor_button(_find_button(game.computer._window, "I'll ask Maya in person before I merge anything."))
	await _click_monitor_button(_find_button(game.computer._window, "Continue working."))
	_check(not game.seated and game.awaiting_person == "mentor" and game.stage_index == 3, "Choosing to ask stands up and routes the assignment to Maya without advancing")
	await _stand_near("desk", game.office.target_position("desk"))
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.current_card_id == "waiting_maya" and not bool(game.flags.get("cr_merged", false)), "Returning early cannot bypass the chosen conversation or merge the CR")
	await _click_monitor_button(_find_button(game.computer._window, "I'll go talk to Maya now."))
	await _click_monitor_button(game.computer._slack_send)
	var maya_found: bool = await _stand_near("mentor", game.office.target_position("mentor"))
	_check(maya_found, "Maya is physically reachable for the requested review clarification")
	await _tap(KEY_E)
	_check(game.current_card_id == "review_context" and game.conversation_id == "mentor", "E starts the review clarification face to face")
	await _tap(KEY_1)
	await _tap(KEY_ENTER)
	_check(game.stage_index == 4 and bool(game.flags.get("review_context", false)), "Clarification unlocks testing and the merge decision")
	await _stand_near("desk", game.office.target_position("desk"))
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	await _click_monitor_button(_find_button(game.computer._window, "I'll test all three cases, then merge CR #104."))
	_check(not game.flags.get("cr_merged", false), "The safe merge opens playable checks before merging")
	await _click_monitor_button(_find_button(game.computer._window, "Save favorite"))
	await _click_monitor_button(_find_button(game.computer._window, "Save favorite"))
	_check(game.computer._sandbox_result.contains("BUG"), "Two rapid taps expose the duplicate favorite bug")
	await _click_monitor_button(_find_button(game.computer._window, "Edit Save behavior"))
	await _click_monitor_button(_find_button(game.computer._window, "Add guest guard: if user_id.is_empty(): return sign_in"))
	await _click_monitor_button(_find_button(game.computer._window, "Change write: orders.append(drink) → favorites.append(drink)"))
	await _click_monitor_button(_find_button(game.computer._window, "Add repeat guard: if seen_requests.has(request_id): return already_saved"))
	await _click_monitor_button(_find_button(game.computer._window, "Run test suite"))
	_check(game.computer._lab_report.size() == 3 and game.flags.get("sandbox_complete", false), "The displayed GDScript tests execute against the edited source")
	await _click_monitor_button(_find_button(game.computer._window, "Open source"))
	await _click_monitor_button(_find_button(game.computer._window, "Open app preview"))
	await _click_monitor_button(_find_button(game.computer._window, "Save favorite"))
	await _click_monitor_button(_find_button(game.computer._window, "Save favorite"))
	await _click_monitor_button(_find_button(game.computer._window, "Sign out"))
	await _click_monitor_button(_find_button(game.computer._window, "Save favorite"))
	_check(game.flags.get("sandbox_complete", false) and game.computer._sandbox_orders == 0, "All three actual preview checks pass without charging anyone")
	await _click_monitor_button(_find_button(game.computer._window, "Back to CR #104"))
	await _click_monitor_button(_find_button(game.computer._window, "I'll test all three cases, then merge CR #104."))
	_check(bool(game.flags.get("cr_merged", false)) and bool(game.flags.get("tested", false)) and game.computer._cr_status == "Merged", "The reviewed merge records tests and updates the CR status")
	await _click_monitor_button(_find_button(game.computer._window, "Continue working."))
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.stage_index == 5 and game.current_card_id == "intern" and game.card_on_computer, "Sam's next help request arrives as a Slack task on the monitor")
	game._stand_up()
	game.flags = {"cr_submitted":true}
	game._set_stage(3)
	await _stand_near("desk", game.office.target_position("desk"))
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	await _click_monitor_button(_find_button(game.computer._window, "I'll merge now and deal with the comments later."))
	await _click_monitor_button(_find_button(game.computer._window, "Continue working."))
	await _click_monitor_button(_find_button(game.computer._root, "Open my task."))
	_check(game.stage_index == 4 and game.current_card_id == "review_followup" and bool(game.flags.get("early_merge", false)), "An early merge leads to a follow-up task instead of pretending review happened")
	game.flags.erase("interruptions_done")
	game._desk_app("triage")
	_check(game.current_card_id == "interruptions", "The triage channel opens simultaneous meeting, build, and teammate requests")
	await _click_monitor_button(_find_button(game.computer._window, "I'll fix the demo build first and ask Jordan to move the meeting."))
	await _click_monitor_button(game.computer._slack_send)
	_check(game.flags.get("prioritized_build", false) and game.flags.get("interruptions_done", false), "Sending a priority decision resolves competing requests with consequences")
	game.flags["promised_sam"] = true
	game.flags.erase("kept_promise")
	game.flags.erase("broke_promise")
	game._stand_up()
	game.hud.hide_modal()
	game._set_stage(6)
	game._interact("intern")
	_check(game.current_card_id == "promise_help", "Sam recalls an outstanding promise when visited later")
	game._choose(0)
	_check(game.flags.get("kept_promise", false) and game._memory_line("Sam").contains("came back"), "Keeping the promise changes Sam's later dialogue")
	game.hud.hide_modal()
	game.hud.set_conversation(true)
	game.hud.show_card({"title":"Let's discuss the feature.", "body":"Maya asks what you learned.", "choices":[{"label":"I checked the guest and signed-in cases."}]})
	await process_frame
	_check(game.hud._modal.position.x >= game.hud._root.size.x * 0.49 and game.hud._dim.color.a < 0.15, "Conversation cards leave the person visible on the left")
	var conversation_x: float = game.hud._modal.position.x
	game.hud.show_feedback("Maya appreciates your careful testing.")
	_check(is_equal_approx(game.hud._modal.position.x, conversation_x), "Conversation feedback retains the right-hand layout")
	_check(game.hud._stats_panel.is_visible_in_tree(), "Dialogue and feedback retain the persistent meter values")
	for key: String in ["delivery", "quality", "trust", "energy"]:
		_check(game.hud._stat_values[key].text == str(int(game.stats[key])), "The persistent %s value matches game state" % key)
	var original_hud_size: Vector2 = game.hud._root.size
	game.hud._root.size = Vector2(960, 900)
	game.hud.set_conversation(true)
	_check(game.hud._modal.position.x < 200 and game.hud._dim.color.a > 0.6, "Narrow conversation layouts return to a centered modal")
	game.hud._root.size = original_hud_size
	game.hud.set_conversation(false)
	game.hud.hide_modal()
	_finish()


func _click_monitor_button(button: Control) -> void:
	if not is_instance_valid(button):
		_check(false, "Requested monitor button exists")
		return
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await _frames(3)
	var pixel: Vector2 = button.get_global_rect().get_center()
	var viewport_size: Vector2 = Vector2(game.computer._viewport.size)
	var quad: QuadMesh = game.office.monitor_surface.mesh as QuadMesh
	var uv: Vector2 = pixel / viewport_size
	var local := Vector3((uv.x - 0.5) * quad.size.x, (0.5 - uv.y) * quad.size.y, 0)
	var world: Vector3 = game.office.monitor_surface.to_global(local)
	# parse_input_event enters before the root viewport's stretch transform, like OS input.
	var point: Vector2 = root.get_final_transform() * game.player.camera.unproject_position(world)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	var mouse := InputEventMouseButton.new()
	mouse.position = point
	mouse.global_position = point
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await process_frame
	mouse.button_mask = 0
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await process_frame
	await process_frame


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node.text == text or str(node.get_meta("action_text", "")) == text or node.tooltip_text == text):
		return node
	for child: Node in node.get_children():
		var found: Button = _find_button(child, text)
		if is_instance_valid(found):
			return found
	return null


func _contains_old_instructions(node: Node) -> bool:
	if node is Label or node is RichTextLabel or node is Button:
		var text: String = str(node.text)
		if text.contains("MAKE YOUR CALL") or text.contains("W A S D   MOVE") or text.contains("SHIFT   HUSTLE"):
			return true
	for child: Node in node.get_children():
		if _contains_old_instructions(child):
			return true
	return false


func _stand_near(id: String, target: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.78
	for index in range(24):
		var angle: float = TAU * float(index) / 24.0
		var position := Vector3(target.x + sin(angle) * 2.0, 0.06, target.z + cos(angle) * 2.0)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, position + Vector3(0, 0.9, 0))
		query.exclude = [game.player.get_rid()]
		if not game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue
		game.player.global_position = position
		game.player.velocity = Vector3.ZERO
		game.player.camera.look_at(target, Vector3.UP)
		await _frames(8)
		if game.player.focused_id == id and game.player.is_on_floor():
			return true
	return false


func _tap(code: Key) -> void:
	_key(code, true)
	await process_frame
	_key(code, false)
	await process_frame


func _key(code: Key, pressed: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = pressed
	Input.parse_input_event(key)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, description: String) -> void:
	checks += 1
	print("PASS " if condition else "FAIL ", description)
	if not condition:
		failures.append(description)


func _timeout() -> void:
	if not completed:
		_check(false, "Desk integration test completed before its timeout")
		_finish()


func _finish() -> void:
	if completed:
		return
	completed = true
	_key(KEY_W, false)
	_key(KEY_S, false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("DESK INTERACTION TEST ", "PASS" if failures.is_empty() else "FAIL", " (", checks, " checks; ", failures.size(), " failures)")
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

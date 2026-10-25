extends RefCounted
## Authored, accessible scenarios for the Small Batch internship prototype.
## Integer effects change a meter; boolean effects record an evaluation fact.


static func card(id: String) -> Dictionary:
	var cards: Dictionary = {
		"welcome": {
			"eyebrow": "SMALL BATCH / FINAL INTERNSHIP DAY",
			"title": "Your final internship day",
			"speaker": "People Operations · automated enthusiasm",
			"body": "It is your last day as a software engineering intern at Small Batch. Ship a reliable coffee-app feature and show the team they can trust you to earn a return offer. Use WASD to walk, the mouse to look, and E to interact.",
			"decision": "Are you ready to clock in and join the morning standup?",
			"choices": [
				_choice("I’m ready to clock in.", "", {}, "Your badge works, an encouraging start.", "")
			]
		},
		"standup": {
			"eyebrow": "09:00 / DAILY STANDUP",
			"title": "Give your standup update",
			"speaker": "Jordan · engineering manager",
			"body": "At the morning meeting, Jordan asks whether your Save feature is on track. You have not started because the ticket never says whether Save remembers a drink or buys it. Your update will set the team’s expectations.",
			"decision": "How will you explain your progress and the unclear requirement?",
			"choices": [
				_choice("I’m blocked, so I’ll clarify the ticket with Maya.", "", {"delivery": 6, "quality": 3, "trust": 10, "honest": true}, "Jordan appreciates a clear problem and a plan.", ""),
				_choice("Everything is on track and almost definitely done.", "", {"delivery": 3, "trust": -12, "energy": -4, "optimistic": true}, "Jordan marks it green, making your confidence a commitment.", ""),
				_choice("This ticket is confusing, and somebody should fix it.", "", {"trust": -5, "energy": -2}, "Jordan suggests that somebody could be you.", "")
			]
		},
		"mentor": {
			"eyebrow": "MAYA'S DESK / REQUIREMENTS",
			"title": "Clarify the Save feature",
			"speaker": "Maya · senior engineer",
			"body": "Maya knows how the coffee app should work. You need to understand what Save does and what happens when someone is not signed in before you build the feature.",
			"decision": "Will you ask about those exact rules, request a full explanation, or ask for something to copy?",
			"choices": [
				_choice("Does Save only remember favorites, and what about guests?", "", {"delivery": 4, "quality": 10, "trust": 7, "clarified": true}, "Maya confirms that guests sign in and Save never charges.", ""),
				_choice("Could you explain how the whole system works?", "", {"quality": 6, "energy": -8, "clarified": true}, "You get the answer and seven migrations of backstory.", ""),
				_choice("Please tell me what to paste because I’m in a hurry.", "", {"delivery": 5, "quality": -5, "trust": -10, "clarified": false}, "Maya shares the rules with one eyebrow raised.", "")
			]
		},
		"feature": {
			"eyebrow": "YOUR DESK / FEATURE WORK",
			"title": "Give the AI clear instructions",
			"speaker": "BatchGPT · confidently available",
			"body": "Your ticket is to let signed-in users save a favorite drink without buying it. Guests should be asked to sign in. BatchGPT can build the feature, but it will follow the instructions you give it.",
			"decision": "What instructions will you give the AI before it writes the change?",
			"choices": [
				_choice("Please build a great Save button with immaculate vibes.", "", {"delivery": 10, "quality": -14, "trust": -3, "energy": -3, "vague_prompt": true}, "BatchGPT adds accidental purchases and calls them proactive delight.", ""),
				_choice("Save favorites without buying, and test signed-out users.", "", {"delivery": 14, "quality": 15, "trust": 5, "energy": -6, "clear_prompt": true}, "The AI makes a small change with a useful checklist.", ""),
				_choice("Please add a social feed, coins, and a coffee metaverse.", "", {"delivery": -8, "quality": -8, "energy": -14, "overbuilt": true}, "Thirty-four screens later, one sells a virtual lid.", "")
			]
		},
		"review": {
			"eyebrow": "YOUR DESK / CODE REVIEW",
			"title": "Decide whether to merge",
			"speaker": "Maya · reviewing your change",
			"body": "Maya wants proof that Save remembers one favorite, charges nobody, and asks guests to sign in. Your change is ready to merge into the app, but those checks have not been confirmed.",
			"decision": "Will you test the three cases first, merge immediately, or trust the AI’s approval?",
			"choices": [
				_choice("I’ll check all three cases and fix any failures.", "", {"delivery": 6, "quality": 15, "trust": 8, "energy": -8, "tested": true}, "You catch a double-tap bug and earn Maya’s approval.", ""),
				_choice("I’ll ship now because the happy path looked happy.", "", {"delivery": 13, "quality": -16, "trust": -9, "tested": false}, "The feature ships with a fresh collection of follow-up tickets.", ""),
				_choice("I’ll ask the AI to approve its own work.", "", {"delivery": 8, "quality": -10, "trust": -6, "energy": -2, "tested": false}, "BatchGPT awards itself five stars; Maya requests evidence.", "")
			]
		},
		"intern": {
			"eyebrow": "SAM'S DESK / TEAMWORK",
			"title": "Sam needs help before the demo",
			"speaker": "Sam · fellow intern",
			"body": "Sam says a discount is being applied twice, making some coffee prices negative. He needs a second pair of eyes before the demo, but helping him will take time away from your own work.",
			"decision": "Will you help Sam now, offer help later, or send him to the AI?",
			"choices": [
				_choice("I can spend ten minutes checking the discount with you.", "", {"delivery": -4, "quality": 4, "trust": 10, "energy": -6, "helped": true}, "You save Sam’s demo and the concept of money.", ""),
				_choice("I’ll check in after my demo; Maya can help you now.", "", {"delivery": 8, "trust": 2, "helped": false}, "Sam understands the boundary and asks Maya for help.", ""),
				_choice("I can’t help, but the AI might be less wrong this time.", "", {"delivery": 5, "trust": -12, "helped": false}, "Sam’s smile leaves before you do.", "")
			]
		},
		"manager": {
			"eyebrow": "JORDAN'S OFFICE / 1:1",
			"title": "Explain a mistaken announcement",
			"speaker": "Jordan · engineering manager",
			"body": "You accidentally sent “THE BEANS HAVE ESCAPED” to the whole company instead of a test channel. During your 1:1, Jordan asks who sent it. Executives are now checking the doors.",
			"decision": "Will you admit the mistake, try to erase it quietly, or blame the AI?",
			"choices": [
				_choice("I sent it; I’ll apologize and use a test channel next time.", "", {"delivery": 4, "quality": 5, "trust": 12, "disclosed": true}, "Jordan thanks you for confirming that the beans remain contained.", "manager_scope"),
				_choice("I’ll delete it quietly before anyone notices.", "", {"delivery": 2, "trust": -14, "energy": -5, "disclosed": false}, "The notification is already in the company newsletter.", "manager_scope"),
				_choice("I think the AI sent it because technology is mysterious.", "", {"trust": -20, "quality": -4, "disclosed": false}, "Jordan reminds you that you clicked Send.", "manager_scope")
			]
		},
		"manager_scope": {
			"eyebrow": "JORDAN'S OFFICE / PICK YOUR SCOPE",
			"title": "Choose what to finish",
			"speaker": "Jordan · keeping the demo alive",
			"body": "Jordan needs a reliable Save button for the afternoon demo. An executive also wants a feature that guesses people’s moods from their calendars and recommends coffee. You only have enough time to finish one.",
			"decision": "Will you finish the essential Save feature or gamble on the impressive extra?",
			"choices": [
				_choice("I’ll finish Save and put the mood engine on a future slide.", "", {"delivery": 12, "quality": 6, "trust": 6, "essential_scope": true}, "Jordan celebrates the disruptive technology of finishing something.", ""),
				_choice("I’ll build the mood engine to impress the executives.", "", {"delivery": -6, "quality": -5, "trust": -3, "energy": -12, "essential_scope": false}, "It recommends six espressos for any meeting containing “alignment.”", "")
			]
		},
		"kitchen": {
			"eyebrow": "KITCHENETTE / ENERGY CHECK",
			"title": "Rest or keep working",
			"speaker": "Sam · near the emergency biscuits",
			"body": "You have made your coffee and finally stepped away from the desk. The demo could use more polish, but you are tired after working most of the day. Sam offers an energy drink called Runtime Exception.",
			"decision": "Will you take a proper break, work late, or rely on the energy drink?",
			"choices": [
				_choice("I’ll take a proper break and finish on time.", "", {"energy": 18, "quality": 3, "rested": true}, "Your brain returns from its unpaid break.", ""),
				_choice("I’ll skip the break and stay late to polish the demo.", "", {"delivery": 8, "energy": -18, "rested": false}, "Your slides gain polish while your shoulders lose mobility.", ""),
				_choice("I’ll drink Runtime Exception and file a request for rest.", "", {"delivery": 3, "energy": -6, "rested": false}, "The can’s serving size is one regret.", "")
			]
		},
		"incident": {
			"eyebrow": "SEV-1 / COFFEE CHECKOUT",
			"title": "Stop the duplicate charges",
			"speaker": "Maya · incident lead",
			"body": "A new checkout release creates extra paid orders when purchase confirmations fail. Automatic retries are charging customers again; the previous version worked. Your Save feature is unrelated, and Maya needs you to stop the duplicate charges.",
			"decision": "Will you restore the old checkout, retry the failures, or shut down the entire app?",
			"choices": [
				_choice("I’ll restore the old checkout and test one purchase.", "", {"delivery": 12, "quality": 10, "trust": 12, "energy": -5, "incident_resolved": true}, "One coffee now means one charge; Maya organizes refunds.", ""),
				_choice("I’ll retry those confirmations three more times.", "", {"delivery": -12, "quality": -15, "trust": -16, "energy": -8, "incident_resolved": false}, "Customers receive triplets before Maya stops the retries.", ""),
				_choice("I’ll shut down the whole app.", "", {"delivery": -5, "quality": -6, "trust": -7, "energy": -5, "incident_resolved": false}, "The charges stop, along with everyone’s afternoon.", "")
			]
		},
		"inbox_mentor": {
			"eyebrow":"SLACK / DIRECT MESSAGE", "title":"Maya assigned you a feature", "speaker":"Maya · Slack",
			"body":"Maya sent you the Save favorites ticket on Slack. Its description only says “make it intuitive,” so you still do not know whether Save remembers a drink or places an order. Starting now means making an assumption.",
			"decision": "Will you ask Maya in person, send her a Slack question, or build from your best guess?",
			"choices":[
				{"label":"I'll walk over and clarify the ticket with Maya.", "hint":"", "effects":{}, "feedback":"Your ticket stays open. Maya is at her desk.", "next":"", "visit":"mentor"},
				_choice("I'll send Maya a focused question on Slack.", "", {}, "Maya is typing. Mercifully, this is a real answer.", "mentor"),
				_choice("I'll guess the requirements and start building.", "", {"delivery":5,"quality":-5,"trust":-10,"clarified":false}, "You turn an unclear sentence into a very confident assumption.", "")
			]
		},
		"push_cr": {
			"eyebrow":"CHANGES / DRAFT CR #104", "title":"Send your change for review", "speaker":"Changes · CR #104",
			"body":"The AI has produced your proposed update to the app. Before you add it to the live version, Maya needs to review it. Pushing change request CR #104 will send her the draft and ask for feedback.",
			"decision": "Are you ready to send CR #104 to Maya for review?",
			"choices":[_choice("I'll push CR #104 and request Maya's review.", "", {"cr_submitted":true}, "CR #104 is open. Maya receives a review request on Slack.", "")]
		},
		"review_notice": {
			"eyebrow":"CHANGES / REVIEW COMMENTS", "title":"Respond to Maya’s review comments", "speaker":"Maya · CR #104",
			"body":"Maya reviewed CR #104 and asked for proof that Save cannot charge customers and behaves safely when a guest taps twice. Her comments are still unresolved, but the app will let you merge anyway.",
			"decision": "Will you ask Maya first, check the cases yourself, or merge with her questions unanswered?",
			"choices":[
				{"label":"I'll ask Maya in person before I merge anything.", "hint":"", "effects":{}, "feedback":"You leave the CR open and head to Maya's desk.", "next":"", "visit":"mentor"},
				_choice("I'll read the comments and check the cases here.", "", {"review_context":true}, "The review checklist is ready. Check it before you merge.", ""),
				_choice("I'll merge now and deal with the comments later.", "", {"delivery":8,"quality":-10,"trust":-8,"early_merge":true,"cr_merged":true,"tested":false}, "CR #104 is merged with unresolved comments. Maya posts a very precise question mark.", "")
			]
		},
		"review_context": {
			"eyebrow":"MAYA'S DESK / REVIEW CLARIFICATION", "title":"Maya explains the required checks", "speaker":"Maya · senior engineer",
			"body":"You asked Maya about her comments. She confirms that Save must remember one favorite, never charge money, and ask guests to sign in, even if they tap twice. She attaches those rules to your change request.",
			"decision": "Will you return to the computer and check your change against these rules?",
			"choices":[_choice("I'll return to my computer and check those cases.", "", {"review_context":true}, "Maya's clarification is attached to CR #104.", "")]
		},
		"review_followup": {
			"eyebrow":"CHANGES / MERGED WITH OPEN COMMENTS", "title":"Repair an early merge", "speaker":"Maya · CR #104",
			"body":"You merged CR #104 before answering Maya’s review comments. The change is already in the app, and Maya still needs proof that guests and double-taps behave correctly. You can test it now and send a follow-up fix.",
			"decision": "Will you check the missed cases or mark the comments resolved without testing?",
			"choices":[
				_choice("I'll test the missed cases and post a follow-up fix.", "", {"quality":6,"trust":3,"energy":-5,"tested":true}, "You post the checks and a follow-up patch. Maya appreciates the recovery, not the original merge.", ""),
				_choice("I'll mark the comments resolved without checking.", "", {"delivery":3,"trust":-3,"tested":false}, "The comments are closed. The questions are not.", "")
			]
		},
		"intern_help": {
			"eyebrow":"SAM'S DESK / FOLLOW-UP", "title":"Finish helping Sam", "speaker":"Sam · fellow intern",
			"body":"You came over to help Sam and found that the same discount was being applied twice. Removing the duplicate fixes the negative prices. Sam will submit the repair for review so Finance can breathe again.",
			"decision": "Will you return to your own work after Sam sends the follow-up?",
			"choices":[_choice("I'll head back after you send the review request.", "", {}, "Sam thanks you and pushes the follow-up CR.", "")]
		},
		"waiting_maya": {
			"eyebrow":"SLACK / PENDING CONVERSATION", "title":"Your question for Maya is still pending", "speaker":"Slack · saved task",
			"body":"You chose to speak with Maya before continuing. Your draft and review comments are saved on this computer, but you have not asked her yet. She is waiting at her desk.",
			"decision": "Will you go to Maya’s desk to get the answer before continuing?",
			"choices":[{"label":"I'll go talk to Maya now.", "hint":"", "effects":{}, "feedback":"", "next":"", "visit":"mentor"}]
		},
		"waiting_sam": {
			"eyebrow":"SLACK / PENDING CONVERSATION", "title":"Sam is waiting for your help", "speaker":"Slack · saved task",
			"body":"You offered to help Sam in person, but you have not visited him yet. His duplicate discount is still producing negative coffee prices. Your own work is saved here while you help.",
			"decision": "Will you go to Sam’s desk and help him check the discount?",
			"choices":[{"label":"I'll go help Sam now.", "hint":"", "effects":{}, "feedback":"", "next":"", "visit":"intern"}]
		},
		"hr_complaint": {
			"eyebrow": "PEOPLE OPERATIONS / OPEN DOOR",
			"title": "Explain your workplace concern",
			"speaker": "Alex · People Operations",
			"body": "You came to Alex in People Operations to report a workplace problem. Alex needs to know what happened before deciding how to follow up. The form has no remaining space for general existential dread.",
			"decision": "Which problem would you like to report?",
			"choices": [
				_hr_choice("I’d like to report missing food from the fridge.", {}, "Alex opens the fridge-related section of the form.", "hr_coffee", 0),
				_hr_choice("I’m concerned about how Sam is treated in meetings.", {}, "Alex asks what you have noticed and what Sam wants.", "hr_meeting", 0),
				_hr_choice("I’m worried about pressure to work unsafe hours.", {}, "Alex reaches for the notebook labeled Actual Human Limits.", "hr_crunch", 0)
			]
		},
		"hr_coffee": {
			"eyebrow": "PEOPLE OPERATIONS / FRIDGE CASE",
			"title": "Report food missing from the fridge",
			"speaker": "Alex · People Operations",
			"body": "Your labeled oat milk has disappeared from the office fridge several times. You do not know who took it, but you can describe when it happened and what you would like to change.",
			"decision": "Will you document the losses, ask for a general reminder, or accuse the whole floor?",
			"choices": [
				_hr_choice("I have dates and labels; can we set a shared rule?", {"delivery": -3, "trust": 8, "energy": -2, "hr_resolved": true, "hr_filed": true, "hr_coffee": true, "hr_documented": true}, "Alex arranges a shared shelf, disrupting the anonymous milk economy.", "", 6),
				_hr_choice("Could you post a reminder without naming anyone?", {"delivery": -1, "trust": 4, "energy": 1, "hr_resolved": true, "hr_filed": true, "hr_coffee": true, "hr_anonymous": true}, "Alex posts a reminder, and your milk joins a functioning civilization.", "", 3),
				_hr_choice("I’ll accuse the whole floor; somebody knows something.", {"delivery": -2, "trust": -9, "energy": -4, "hr_resolved": true, "hr_filed": true, "hr_coffee": true, "hr_broad_accusations": true}, "Alex asks for specifics while six innocent lunches acquire alibis.", "", 4)
			]
		},
		"hr_meeting": {
			"eyebrow": "PEOPLE OPERATIONS / MEETING CONDUCT",
			"title": "Report how Sam is treated",
			"speaker": "Alex · People Operations",
			"body": "A teammate interrupts Sam in meetings and takes credit for his fixes. Sam asked you to raise the issue with Alex. A useful report could help him; a public confrontation could make the situation harder.",
			"decision": "Will you share examples privately, request meeting rules, or confront the teammate publicly?",
			"choices": [
				_hr_choice("I’ll share examples with Sam’s permission.", {"delivery": -4, "trust": 10, "energy": -3, "hr_resolved": true, "hr_filed": true, "hr_meeting": true, "hr_supported_sam": true, "hr_documented": true}, "Alex schedules a private follow-up and makes space for Sam’s account.", "", 8),
				_hr_choice("Can we set turn-taking rules without naming Sam?", {"delivery": -2, "trust": 6, "energy": -1, "hr_resolved": true, "hr_filed": true, "hr_meeting": true, "hr_anonymous": true}, "Alex suggests a meeting moderator, a revolutionary upgrade from loudest-person routing.", "", 5),
				_hr_choice("I’ll confront them in the company-wide channel.", {"delivery": -3, "trust": -10, "energy": -6, "hr_resolved": true, "hr_filed": true, "hr_meeting": true, "hr_public_escalation": true}, "Alex redirects the discussion from spectators to a private fact-check.", "", 4)
			]
		},
		"hr_crunch": {
			"eyebrow": "PEOPLE OPERATIONS / WORKLOAD",
			"title": "Ask for a safer workload",
			"speaker": "Alex · People Operations",
			"body": "An afternoon request has turned into pressure to work until midnight. Sam is exhausted, and you nearly tripped while carrying hot coffee. Alex asks whether this is an emergency or a routine expectation.",
			"decision": "Will you document the hours, ask for a firm stopping time, or make a promise you cannot keep?",
			"choices": [
				_hr_choice("I’ll document the hours and ask for a safer plan.", {"delivery": -5, "trust": 8, "energy": 8, "hr_resolved": true, "hr_filed": true, "hr_crunch": true, "hr_documented": true, "hr_boundary": true}, "Alex works with Jordan on scope and coverage instead of a midnight loyalty test.", "", 10),
				_hr_choice("Can you help me set a clear stopping time?", {"delivery": -2, "trust": 4, "energy": 5, "hr_resolved": true, "hr_filed": true, "hr_crunch": true, "hr_boundary": true}, "Alex helps you agree on a stopping time that exists on an actual clock.", "", 5),
				_hr_choice("I’ll promise tonight, then quietly do nothing.", {"delivery": 2, "trust": -8, "energy": -3, "hr_resolved": true, "hr_filed": false, "hr_crunch": true, "hr_avoided": true}, "Alex recommends an honest boundary before your teammates plan around a promise.", "", 2)
			]
		},
		"debrief": {
			"eyebrow": "17:00 / FINAL EVALUATION",
			"title": "See your internship evaluation",
			"speaker": "Jordan · your internship review",
			"body": "Jordan has reviewed what you shipped, how carefully you checked it, and whether the team could rely on you. Your decisions today determine whether you leave with a return offer.",
			"decision": "Are you ready to see the result of your final day?",
			"choices": [
				_choice("I’m ready to see my evaluation.", "", {}, "Your evaluation is ready.", "")
			]
		}
	}
	for choice: Dictionary in cards["feature"]["choices"]:
		choice["next"] = "push_cr"
	for choice: Dictionary in cards["review"]["choices"]:
		choice["effects"]["cr_merged"] = true
	cards["review"]["choices"][0]["label"] = "I'll test all three cases, then merge CR #104."
	cards["review"]["choices"][1]["label"] = "I'll merge now because the happy path looked happy."
	cards["review"]["choices"][2]["label"] = "I'll ask the AI to approve and merge its own work."
	cards["review"]["choices"][0]["feedback"] = "You fix the double-tap bug, attach passing checks, and merge CR #104. Maya approves."
	cards["intern"]["speaker"] = "Sam · Slack direct message"
	cards["intern"]["choices"][0]["visit"] = "intern"
	for card_id: String in ["inbox_mentor", "mentor", "intern", "waiting_maya", "waiting_sam"]:
		cards[card_id]["app"] = "slack"
	for card_id: String in ["push_cr", "review_notice", "review", "review_followup", "incident"]:
		cards[card_id]["app"] = "changes"
	cards["feature"]["app"] = "ai"
	cards["interruptions"] = {
		"app":"slack", "title":"Three things at once", "speaker":"# triage · Incoming",
		"body":"Jordan: My planning meeting starts in five minutes.\nChanges bot: The demo build is red. Nobody can preview the app.\nSam: I need that demo environment to rehearse. Could you help?",
		"choices":[
			_choice("I'll fix the demo build first and ask Jordan to move the meeting.", "", {"interruptions_done":true,"prioritized_build":true,"quality":6,"delivery":3,"energy":-5}, "The demo build turns green. Sam can rehearse. Jordan moves the meeting and appreciates the specific update.", ""),
			_choice("I'll join the meeting. The build and rehearsal will have to wait.", "", {"interruptions_done":true,"prioritized_meeting":true,"trust":3,"delivery":-6,"energy":-3}, "You make the meeting. Sam loses his rehearsal slot while the demo environment remains blocked.", ""),
			_choice("I'll help Sam rehearse locally and leave the meeting and build for later.", "", {"interruptions_done":true,"prioritized_sam":true,"trust":5,"quality":-3,"delivery":-3,"energy":-5}, "Sam gets a rehearsal. Jordan notices the missed meeting, and Maya has to repair the shared demo build.", "")]
	}
	cards["promise_help"] = {"title":"Sam remembers your promise", "speaker":"Sam · fellow intern", "body":"You said you would check in after the demo. Sam kept the failing discount example open for you.", "choices":[_choice("Let's check that discount together now.", "", {"kept_promise":true,"helped":true,"trust":8,"quality":3,"energy":-5}, "You find the duplicated discount. Sam remembers that you came back when you said you would.", ""), _choice("I'm sorry. I can't make time today.", "", {"broke_promise":true,"trust":-5}, "Sam closes the example. Next time, he says, he would rather hear a clear no.", "")]}
	return cards.get(id, {})


static func _choice(label: String, hint: String, effects: Dictionary, feedback: String, next_card: String) -> Dictionary:
	return {"label": label, "hint": hint, "effects": effects, "feedback": feedback, "next": next_card}


static func _hr_choice(label: String, effects: Dictionary, feedback: String, next_card: String, minutes: int) -> Dictionary:
	var choice: Dictionary = _choice(label, "", effects, feedback, next_card)
	choice["minutes"] = minutes
	return choice


static func ending(stats: Dictionary, flags: Dictionary) -> Dictionary:
	var delivery: int = int(stats.get("delivery", 0))
	var quality: int = int(stats.get("quality", 0))
	var trust: int = int(stats.get("trust", 0))
	if trust < 20:
		return {
			"title": "Badge access: discontinued.",
			"subtitle": "INTERNSHIP ENDED EARLY",
			"body": "Repeated risky decisions cost the team’s trust, so Jordan ends the internship. Your next attempt starts with a useful lesson: explain mistakes early, then help repair them.",
			"color": "#f08b87"
		}
	if delivery >= 65 and quality >= 65 and trust >= 65 and bool(flags.get("clarified", false)) and bool(flags.get("tested", false)):
		return {
			"title": "You exceeded the job description.",
			"subtitle": "UPLEVELED RETURN OFFER",
			"body": "You clarified the problem, checked your work, and earned the team’s confidence. Jordan offers a role above the standard graduate level, complete with a desk plant that has fewer dependencies than the app.",
			"color": "#e9c77b"
		}
	if delivery >= 45 and quality >= 40 and trust >= 40:
		return {
			"title": "See you after graduation.",
			"subtitle": "RETURN OFFER",
			"body": "Your delivery, care, and teamwork earned a place at Small Batch. Your offer includes a mentor and an optimistic promise that the coffee machine will finish updating.",
			"color": "#88d4b0"
		}
	return {
		"title": "Experience, minus the offer.",
		"subtitle": "NO RETURN OFFER",
		"body": "You finished the internship, but your results did not earn an offer this time. Jordan’s advice for your next attempt: clarify the task, check the result, and speak up early.",
		"color": "#b1b6d5"
	}


static func day_schedule() -> Array:
	return [
		{"time": "09:00", "title": "Daily standup"},
		{"time": "09:30", "title": "Clarify with Maya"},
		{"time": "10:00", "title": "Build your feature"},
		{"time": "11:30", "title": "Code review"},
		{"time": "13:00", "title": "Check in with Sam"},
		{"time": "14:00", "title": "1:1 with Jordan"},
		{"time": "15:00", "title": "Kitchenette break"},
		{"time": "15:15", "title": "Unexpected incident"},
		{"time": "17:00", "title": "Final evaluation"}
	]

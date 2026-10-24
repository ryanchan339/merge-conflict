extends RefCounted
## Authored, accessible scenarios for the Small Batch internship prototype.
## Integer effects change a meter; boolean effects record an evaluation fact.


static func card(id: String) -> Dictionary:
	var cards: Dictionary = {
		"welcome": {
			"eyebrow": "SMALL BATCH / FINAL INTERNSHIP DAY",
			"title": "Your career is brewing.",
			"speaker": "People Operations · automated enthusiasm",
			"body": "Your final day. Ship the coffee feature. Earn the offer.\n\nWASD to move. E or click to interact.\n\nFind the standup circle.",
			"choices": [
				_choice("I’m ready to clock in.", "", {}, "Your badge works, an encouraging start.", "")
			]
		},
		"standup": {
			"eyebrow": "09:00 / DAILY STANDUP",
			"title": "Yesterday, today, mild panic.",
			"speaker": "Jordan · engineering manager",
			"body": "Jordan: “How is the coffee favorites feature?”\n\nThe ticket says “make it intuitive.” You still don’t know whether Save should also buy coffee.",
			"choices": [
				_choice("I’m blocked, so I’ll clarify the ticket with Maya.", "", {"delivery": 6, "quality": 3, "trust": 10, "honest": true}, "Jordan appreciates a clear problem and a plan.", ""),
				_choice("Everything is on track and almost definitely done.", "", {"delivery": 3, "trust": -12, "energy": -4, "optimistic": true}, "Jordan marks it green, making your confidence a commitment.", ""),
				_choice("This ticket is confusing, and somebody should fix it.", "", {"trust": -5, "energy": -2}, "Jordan suggests that somebody could be you.", "")
			]
		},
		"mentor": {
			"eyebrow": "MAYA'S DESK / REQUIREMENTS",
			"title": "Ask a human.",
			"speaker": "Maya · senior engineer",
			"body": "Maya removes one headphone.\n\n[b]Save remembers a favorite; it never buys coffee.[/b] Only signed-in people can save. Guests must see a sign-in message.\n\nHow do you ask for help?",
			"choices": [
				_choice("Does Save only remember favorites, and what about guests?", "", {"delivery": 4, "quality": 10, "trust": 7, "clarified": true}, "Maya confirms that guests sign in and Save never charges.", ""),
				_choice("Could you explain how the whole system works?", "", {"quality": 6, "energy": -8, "clarified": true}, "You get the answer and seven migrations of backstory.", ""),
				_choice("Please tell me what to paste because I’m in a hurry.", "", {"delivery": 5, "quality": -5, "trust": -10, "clarified": false}, "Maya shares the rules with one eyebrow raised.", "")
			]
		},
		"feature": {
			"eyebrow": "YOUR DESK / FEATURE WORK",
			"title": "Prompt. Hope. Verify.",
			"speaker": "BatchGPT · confidently available",
			"body": "Tell BatchGPT what to build.\n\n[b]Save favorites, never place orders or charge money.[/b] Guests should see “Sign in to save.”\n\nIts avatar is a mug wearing a smaller mug.",
			"choices": [
				_choice("Please build a great Save button with immaculate vibes.", "", {"delivery": 10, "quality": -14, "trust": -3, "energy": -3, "vague_prompt": true}, "BatchGPT adds accidental purchases and calls them proactive delight.", ""),
				_choice("Save favorites without buying, and test signed-out users.", "", {"delivery": 14, "quality": 15, "trust": 5, "energy": -6, "clear_prompt": true}, "The AI makes a small change with a useful checklist.", ""),
				_choice("Please add a social feed, coins, and a coffee metaverse.", "", {"delivery": -8, "quality": -8, "energy": -14, "overbuilt": true}, "Thirty-four screens later, one sells a virtual lid.", "")
			]
		},
		"review": {
			"eyebrow": "YOUR DESK / CODE REVIEW",
			"title": "Looks good. What if…",
			"speaker": "Maya · reviewing your change",
			"body": "Maya: “Check the awkward cases.”\n\n[b]Signed in:[/b] Save remembers, never charges.\n[b]Guest:[/b] Ask them to sign in.\n[b]Double tap:[/b] One favorite, no payment.\n\nThe Ship button looks temptingly large.",
			"choices": [
				_choice("I’ll check all three cases and fix any failures.", "", {"delivery": 6, "quality": 15, "trust": 8, "energy": -8, "tested": true}, "You catch a double-tap bug and earn Maya’s approval.", ""),
				_choice("I’ll ship now because the happy path looked happy.", "", {"delivery": 13, "quality": -16, "trust": -9, "tested": false}, "The feature ships with a fresh collection of follow-up tickets.", ""),
				_choice("I’ll ask the AI to approve its own work.", "", {"delivery": 8, "quality": -10, "trust": -6, "energy": -2, "tested": false}, "BatchGPT awards itself five stars; Maya requests evidence.", "")
			]
		},
		"intern": {
			"eyebrow": "SAM'S DESK / TEAMWORK",
			"title": "Two interns. One deadline.",
			"speaker": "Sam · fellow intern",
			"body": "Sam: “My discount runs twice. Coffee costs minus three dollars.”\n\nFinance has concerns. Sam needs a second pair of eyes, but your own demo needs work.",
			"choices": [
				_choice("I can spend ten minutes checking the discount with you.", "", {"delivery": -4, "quality": 4, "trust": 10, "energy": -6, "helped": true}, "You save Sam’s demo and the concept of money.", ""),
				_choice("I’ll check in after my demo; Maya can help you now.", "", {"delivery": 8, "trust": 2, "helped": false}, "Sam understands the boundary and asks Maya for help.", ""),
				_choice("I can’t help, but the AI might be less wrong this time.", "", {"delivery": 5, "trust": -12, "helped": false}, "Sam’s smile leaves before you do.", "")
			]
		},
		"manager": {
			"eyebrow": "JORDAN'S OFFICE / 1:1",
			"title": "About the escaped beans…",
			"speaker": "Jordan · engineering manager",
			"body": "Jordan: “Who sent everyone [b]THE BEANS HAVE ESCAPED[/b]?”\n\nYou did: wrong notification channel. Three executives are checking the doors.\n\nOwn it, or attempt a quiet cleanup?",
			"choices": [
				_choice("I sent it; I’ll apologize and use a test channel next time.", "", {"delivery": 4, "quality": 5, "trust": 12, "disclosed": true}, "Jordan thanks you for confirming that the beans remain contained.", "manager_scope"),
				_choice("I’ll delete it quietly before anyone notices.", "", {"delivery": 2, "trust": -14, "energy": -5, "disclosed": false}, "The notification is already in the company newsletter.", "manager_scope"),
				_choice("I think the AI sent it because technology is mysterious.", "", {"trust": -20, "quality": -4, "disclosed": false}, "Jordan reminds you that you clicked Send.", "manager_scope")
			]
		},
		"manager_scope": {
			"eyebrow": "JORDAN'S OFFICE / PICK YOUR SCOPE",
			"title": "One tiny extra feature.",
			"speaker": "Jordan · keeping the demo alive",
			"body": "Jordan needs a reliable Save button.\n\nAn executive also wants a coffee mood engine that reads calendars. You have time for one: polish the essentials, or gamble on a flashy demo.",
			"choices": [
				_choice("I’ll finish Save and put the mood engine on a future slide.", "", {"delivery": 12, "quality": 6, "trust": 6, "essential_scope": true}, "Jordan celebrates the disruptive technology of finishing something.", ""),
				_choice("I’ll build the mood engine to impress the executives.", "", {"delivery": -6, "quality": -5, "trust": -3, "energy": -12, "essential_scope": false}, "It recommends six espressos for any meeting containing “alignment.”", "")
			]
		},
		"kitchen": {
			"eyebrow": "KITCHENETTE / ENERGY CHECK",
			"title": "Hydrate your human infrastructure.",
			"speaker": "Sam · near the emergency biscuits",
			"body": "The coffee machine is updating: 4%. It has been stuck since Tuesday.\n\nTake a break, work late, or replace rest with an energy drink called [b]Runtime Exception[/b]?",
			"choices": [
				_choice("I’ll take a proper break and finish on time.", "", {"energy": 18, "quality": 3, "rested": true}, "Your brain returns from its unpaid break.", ""),
				_choice("I’ll skip the break and stay late to polish the demo.", "", {"delivery": 8, "energy": -18, "rested": false}, "Your slides gain polish while your shoulders lose mobility.", ""),
				_choice("I’ll drink Runtime Exception and file a request for rest.", "", {"delivery": 3, "energy": -6, "rested": false}, "The can’s serving size is one regret.", "")
			]
		},
		"incident": {
			"eyebrow": "SEV-1 / COFFEE CHECKOUT",
			"title": "Double espresso. Double charge.",
			"speaker": "Maya · incident lead",
			"body": "[b]New checkout release:[/b] A purchase succeeds, but its confirmation gets lost. Automatic retries create extra paid orders.\n\nThe old version worked. Your Save feature is unrelated.\n\nMaya: “Stop the duplicate charges.”",
			"choices": [
				_choice("I’ll restore the old checkout and test one purchase.", "", {"delivery": 12, "quality": 10, "trust": 12, "energy": -5, "incident_resolved": true}, "One coffee now means one charge; Maya organizes refunds.", ""),
				_choice("I’ll retry those confirmations three more times.", "", {"delivery": -12, "quality": -15, "trust": -16, "energy": -8, "incident_resolved": false}, "Customers receive triplets before Maya stops the retries.", ""),
				_choice("I’ll shut down the whole app.", "", {"delivery": -5, "quality": -6, "trust": -7, "energy": -5, "incident_resolved": false}, "The charges stop, along with everyone’s afternoon.", "")
			]
		},
		"hr_complaint": {
			"eyebrow": "PEOPLE OPERATIONS / OPEN DOOR",
			"title": "Please describe the situation.",
			"speaker": "Alex · People Operations",
			"body": "Alex: “What brings you in?”\n\nThe form asks what happened, who it affects, and what would help. The drop-down for existential dread is currently full.",
			"choices": [
				_hr_choice("I’d like to report missing food from the fridge.", {}, "Alex opens the fridge-related section of the form.", "hr_coffee", 0),
				_hr_choice("I’m concerned about how Sam is treated in meetings.", {}, "Alex asks what you have noticed and what Sam wants.", "hr_meeting", 0),
				_hr_choice("I’m worried about pressure to work unsafe hours.", {}, "Alex reaches for the notebook labeled Actual Human Limits.", "hr_crunch", 0)
			]
		},
		"hr_coffee": {
			"eyebrow": "PEOPLE OPERATIONS / FRIDGE CASE",
			"title": "The milk has vanished.",
			"speaker": "Alex · People Operations",
			"body": "Your labeled oat milk keeps disappearing. The fridge contains six anonymous apologies and no milk.\n\nAlex: “What happened, and how would you like us to handle it?”",
			"choices": [
				_hr_choice("I have dates and labels; can we set a shared rule?", {"delivery": -3, "trust": 8, "energy": -2, "hr_resolved": true, "hr_filed": true, "hr_coffee": true, "hr_documented": true}, "Alex arranges a shared shelf, disrupting the anonymous milk economy.", "", 6),
				_hr_choice("Could you post a reminder without naming anyone?", {"delivery": -1, "trust": 4, "energy": 1, "hr_resolved": true, "hr_filed": true, "hr_coffee": true, "hr_anonymous": true}, "Alex posts a reminder, and your milk joins a functioning civilization.", "", 3),
				_hr_choice("I’ll accuse the whole floor; somebody knows something.", {"delivery": -2, "trust": -9, "energy": -4, "hr_resolved": true, "hr_filed": true, "hr_coffee": true, "hr_broad_accusations": true}, "Alex asks for specifics while six innocent lunches acquire alibis.", "", 4)
			]
		},
		"hr_meeting": {
			"eyebrow": "PEOPLE OPERATIONS / MEETING CONDUCT",
			"title": "Sam deserves a turn.",
			"speaker": "Alex · People Operations",
			"body": "A teammate talks over Sam and takes credit for Sam’s fixes. Sam asked you to mention it.\n\nAlex opens a notebook, visibly relieved that this complaint contains an actual example.",
			"choices": [
				_hr_choice("I’ll share examples with Sam’s permission.", {"delivery": -4, "trust": 10, "energy": -3, "hr_resolved": true, "hr_filed": true, "hr_meeting": true, "hr_supported_sam": true, "hr_documented": true}, "Alex schedules a private follow-up and makes space for Sam’s account.", "", 8),
				_hr_choice("Can we set turn-taking rules without naming Sam?", {"delivery": -2, "trust": 6, "energy": -1, "hr_resolved": true, "hr_filed": true, "hr_meeting": true, "hr_anonymous": true}, "Alex suggests a meeting moderator, a revolutionary upgrade from loudest-person routing.", "", 5),
				_hr_choice("I’ll confront them in the company-wide channel.", {"delivery": -3, "trust": -10, "energy": -6, "hr_resolved": true, "hr_filed": true, "hr_meeting": true, "hr_public_escalation": true}, "Alex redirects the discussion from spectators to a private fact-check.", "", 4)
			]
		},
		"hr_crunch": {
			"eyebrow": "PEOPLE OPERATIONS / WORKLOAD",
			"title": "Optional has acquired quotation marks.",
			"speaker": "Alex · People Operations",
			"body": "An afternoon request has become “optional” midnight work. Sam is exhausted, and you nearly tripped carrying hot coffee.\n\nAlex: “Is this deadline an emergency, or a habit wearing a pager?”",
			"choices": [
				_hr_choice("I’ll document the hours and ask for a safer plan.", {"delivery": -5, "trust": 8, "energy": 8, "hr_resolved": true, "hr_filed": true, "hr_crunch": true, "hr_documented": true, "hr_boundary": true}, "Alex works with Jordan on scope and coverage instead of a midnight loyalty test.", "", 10),
				_hr_choice("Can you help me set a clear stopping time?", {"delivery": -2, "trust": 4, "energy": 5, "hr_resolved": true, "hr_filed": true, "hr_crunch": true, "hr_boundary": true}, "Alex helps you agree on a stopping time that exists on an actual clock.", "", 5),
				_hr_choice("I’ll promise tonight, then quietly do nothing.", {"delivery": 2, "trust": -8, "energy": -3, "hr_resolved": true, "hr_filed": false, "hr_crunch": true, "hr_avoided": true}, "Alex recommends an honest boundary before your teammates plan around a promise.", "", 2)
			]
		},
		"debrief": {
			"eyebrow": "17:00 / FINAL EVALUATION",
			"title": "Take a tested seat.",
			"speaker": "Jordan · your internship review",
			"body": "Jordan has your evaluation.\n\nWhat shipped? What broke? Could the team trust you?\n\nTime to find out what your day earned.",
			"choices": [
				_choice("I’m ready to see my evaluation.", "", {}, "Your evaluation is ready.", "")
			]
		}
	}
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

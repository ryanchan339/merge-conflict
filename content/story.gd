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
				_choice("Clock in.", "", {}, "Your badge works, an encouraging start.", "")
			]
		},
		"standup": {
			"eyebrow": "09:00 / DAILY STANDUP",
			"title": "Yesterday, today, mild panic.",
			"speaker": "Jordan · engineering manager",
			"body": "Jordan: “How is the coffee favorites feature?”\n\nThe ticket says “make it intuitive.” You still don’t know whether Save should also buy coffee.",
			"choices": [
				_choice("I’m blocked; I’ll clarify the ticket with Maya.", "", {"delivery": 6, "quality": 3, "trust": 10, "honest": true}, "Jordan appreciates a clear problem and a plan.", ""),
				_choice("All on track! Almost basically essentially done.", "", {"delivery": 3, "trust": -12, "energy": -4, "optimistic": true}, "Jordan marks it green, making your confidence a commitment.", ""),
				_choice("The ticket is confusing; somebody should fix it.", "", {"trust": -5, "energy": -2}, "Jordan suggests that somebody could be you.", "")
			]
		},
		"mentor": {
			"eyebrow": "MAYA'S DESK / REQUIREMENTS",
			"title": "Ask a human.",
			"speaker": "Maya · senior engineer",
			"body": "Maya removes one headphone.\n\n[b]Save remembers a favorite; it never buys coffee.[/b] Only signed-in people can save. Guests must see a sign-in message.\n\nHow do you ask for help?",
			"choices": [
				_choice("Save remembers, never buys; what about guests?", "", {"delivery": 4, "quality": 10, "trust": 7, "clarified": true}, "Maya confirms that guests sign in and Save never charges.", ""),
				_choice("Explain the whole system from the beginning?", "", {"quality": 6, "energy": -8, "clarified": true}, "You get the answer and seven migrations of backstory.", ""),
				_choice("Just tell me what to paste; I’m busy.", "", {"delivery": 5, "quality": -5, "trust": -10, "clarified": false}, "Maya shares the rules with one eyebrow raised.", "")
			]
		},
		"feature": {
			"eyebrow": "YOUR DESK / FEATURE WORK",
			"title": "Prompt. Hope. Verify.",
			"speaker": "BatchGPT · confidently available",
			"body": "Tell BatchGPT what to build.\n\n[b]Save favorites, never place orders or charge money.[/b] Guests should see “Sign in to save.”\n\nIts avatar is a mug wearing a smaller mug.",
			"choices": [
				_choice("Build Save; make it good, you know the vibe.", "", {"delivery": 10, "quality": -14, "trust": -3, "energy": -3, "vague_prompt": true}, "BatchGPT adds accidental purchases and calls them proactive delight.", ""),
				_choice("Save only; no buying; handle guests; check both.", "", {"delivery": 14, "quality": 15, "trust": 5, "energy": -6, "clear_prompt": true}, "The AI makes a small change with a useful checklist.", ""),
				_choice("Add favorites, coins, a feed, and a coffee metaverse.", "", {"delivery": -8, "quality": -8, "energy": -14, "overbuilt": true}, "Thirty-four screens later, one sells a virtual lid.", "")
			]
		},
		"review": {
			"eyebrow": "YOUR DESK / CODE REVIEW",
			"title": "Looks good. What if…",
			"speaker": "Maya · reviewing your change",
			"body": "Maya: “Check the awkward cases.”\n\n[b]Signed in:[/b] Save remembers, never charges.\n[b]Guest:[/b] Ask them to sign in.\n[b]Double tap:[/b] One favorite, no payment.\n\nThe Ship button looks temptingly large.",
			"choices": [
				_choice("Check all three cases and fix failures.", "", {"delivery": 6, "quality": 15, "trust": 8, "energy": -8, "tested": true}, "You catch a double-tap bug and earn Maya’s approval.", ""),
				_choice("Ship now; the happy path looked happy.", "", {"delivery": 13, "quality": -16, "trust": -9, "tested": false}, "The feature ships with a fresh collection of follow-up tickets.", ""),
				_choice("Ask the AI to approve its own work.", "", {"delivery": 8, "quality": -10, "trust": -6, "energy": -2, "tested": false}, "BatchGPT awards itself five stars; Maya requests evidence.", "")
			]
		},
		"intern": {
			"eyebrow": "SAM'S DESK / TEAMWORK",
			"title": "Two interns. One deadline.",
			"speaker": "Sam · fellow intern",
			"body": "Sam: “My discount runs twice. Coffee costs minus three dollars.”\n\nFinance has concerns. Sam needs a second pair of eyes, but your own demo needs work.",
			"choices": [
				_choice("Spend ten minutes checking the discount together.", "", {"delivery": -4, "quality": 4, "trust": 10, "energy": -6, "helped": true}, "You save Sam’s demo and the concept of money.", ""),
				_choice("My demo comes first; ask Maya, then I’ll check in.", "", {"delivery": 8, "trust": 2, "helped": false}, "Sam understands the boundary and asks Maya for help.", ""),
				_choice("Can’t help; ask the AI to be less wrong.", "", {"delivery": 5, "trust": -12, "helped": false}, "Sam’s smile leaves before you do.", "")
			]
		},
		"manager": {
			"eyebrow": "JORDAN'S OFFICE / 1:1",
			"title": "About the escaped beans…",
			"speaker": "Jordan · engineering manager",
			"body": "Jordan: “Who sent everyone [b]THE BEANS HAVE ESCAPED[/b]?”\n\nYou did: wrong notification channel. Three executives are checking the doors.\n\nOwn it, or attempt a quiet cleanup?",
			"choices": [
				_choice("My mistake; I’ll correct it and use a test channel.", "", {"delivery": 4, "quality": 5, "trust": 12, "disclosed": true}, "Jordan thanks you for confirming that the beans remain contained.", "manager_scope"),
				_choice("I’ll delete it quietly before anyone notices.", "", {"delivery": 2, "trust": -14, "energy": -5, "disclosed": false}, "The notification is already in the company newsletter.", "manager_scope"),
				_choice("Probably the AI; technology is mysterious.", "", {"trust": -20, "quality": -4, "disclosed": false}, "Jordan reminds you that you clicked Send.", "manager_scope")
			]
		},
		"manager_scope": {
			"eyebrow": "JORDAN'S OFFICE / PICK YOUR SCOPE",
			"title": "One tiny extra feature.",
			"speaker": "Jordan · keeping the demo alive",
			"body": "Jordan needs a reliable Save button.\n\nAn executive also wants a coffee mood engine that reads calendars. You have time for one: polish the essentials, or gamble on a flashy demo.",
			"choices": [
				_choice("Finish Save; put the mood engine on a future slide.", "", {"delivery": 12, "quality": 6, "trust": 6, "essential_scope": true}, "Jordan celebrates the disruptive technology of finishing something.", ""),
				_choice("Build the mood engine; executives love surprises.", "", {"delivery": -6, "quality": -5, "trust": -3, "energy": -12, "essential_scope": false}, "It recommends six espressos for any meeting containing “alignment.”", "")
			]
		},
		"kitchen": {
			"eyebrow": "KITCHENETTE / ENERGY CHECK",
			"title": "Hydrate your human infrastructure.",
			"speaker": "Sam · near the emergency biscuits",
			"body": "The coffee machine is updating: 4%. It has been stuck since Tuesday.\n\nTake a break, work late, or replace rest with an energy drink called [b]Runtime Exception[/b]?",
			"choices": [
				_choice("Water, snack, real break; wrap up on time.", "", {"energy": 18, "quality": 3, "rested": true}, "Your brain returns from its unpaid break.", ""),
				_choice("Skip the break and stay late polishing.", "", {"delivery": 8, "energy": -18, "rested": false}, "Your slides gain polish while your shoulders lose mobility.", ""),
				_choice("Drink Runtime Exception; rest is a feature request.", "", {"delivery": 3, "energy": -6, "rested": false}, "The can’s serving size is one regret.", "")
			]
		},
		"incident": {
			"eyebrow": "SEV-1 / COFFEE CHECKOUT",
			"title": "Double espresso. Double charge.",
			"speaker": "Maya · incident lead",
			"body": "[b]New checkout release:[/b] A purchase succeeds, but its confirmation gets lost. Automatic retries create extra paid orders.\n\nThe old version worked. Your Save feature is unrelated.\n\nMaya: “Stop the duplicate charges.”",
			"choices": [
				_choice("Restore old checkout; test one purchase.", "", {"delivery": 12, "quality": 10, "trust": 12, "energy": -5, "incident_resolved": true}, "One coffee now means one charge; Maya organizes refunds.", ""),
				_choice("Retry the confirmations harder, maybe three times.", "", {"delivery": -12, "quality": -15, "trust": -16, "energy": -8, "incident_resolved": false}, "Customers receive triplets before Maya stops the retries.", ""),
				_choice("Shut down the whole app.", "", {"delivery": -5, "quality": -6, "trust": -7, "energy": -5, "incident_resolved": false}, "The charges stop, along with everyone’s afternoon.", "")
			]
		},
		"debrief": {
			"eyebrow": "17:00 / FINAL EVALUATION",
			"title": "Take a tested seat.",
			"speaker": "Jordan · your internship review",
			"body": "Jordan has your evaluation.\n\nWhat shipped? What broke? Could the team trust you?\n\nTime to find out what your day earned.",
			"choices": [
				_choice("Open my evaluation.", "", {}, "Your evaluation is ready.", "")
			]
		}
	}
	return cards.get(id, {})


static func _choice(label: String, hint: String, effects: Dictionary, feedback: String, next_card: String) -> Dictionary:
	return {"label": label, "hint": hint, "effects": effects, "feedback": feedback, "next": next_card}


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

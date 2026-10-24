extends RefCounted
## Authored, accessible scenarios for the Small Batch internship prototype.
## Integer effects change a meter; boolean effects record an evaluation fact.


static func card(id: String) -> Dictionary:
	var cards: Dictionary = {
		"welcome": {
			"eyebrow": "SMALL BATCH / FINAL INTERNSHIP DAY",
			"title": "Your career is brewing.",
			"speaker": "People Operations · automated enthusiasm",
			"body": "Welcome to Small Batch, the company disrupting the space between wanting coffee and having coffee.\n\nToday is the last day of your internship. Ship a useful feature, survive feedback, and show the team how you work. Your return offer depends on your [b]delivery, quality, and trust[/b]. Energy helps you keep going.\n\n[b]No programming experience required.[/b] Read the clues, talk to people, and make choices. The code is pretend. The office coffee dependency is very real.",
			"choices": [
				_choice("Clock in. Try to look employable.", "Your first stop is the standup circle.", {}, "Your badge works. An encouraging start.", "")
			]
		},
		"standup": {
			"eyebrow": "09:00 / DAILY STANDUP",
			"title": "Yesterday, today, mild panic.",
			"speaker": "Jordan · engineering manager",
			"body": "“Quick updates, everyone. Fifteen minutes.”\n\nThe meeting room display estimates 47 minutes.\n\nYour task is a new [b]remember my coffee order[/b] button. The ticket says: “Make it intuitive. Like the internet, but friendlier.” You don't know whether it should also place an order.\n\nJordan turns to you. “How's it looking?”",
			"choices": [
				_choice("I'm blocked on what 'remember' means. I'll clarify it with Maya.", "Name the uncertainty and offer a specific next step.", {"delivery": 6, "quality": 3, "trust": 10, "honest": true}, "Jordan: “Good catch. Ten minutes of clarity beats a week of confident confusion.”", ""),
				_choice("All on track! Almost basically essentially done.", "Buy a little time. Your team will plan around this promise.", {"delivery": 3, "trust": -12, "energy": -4, "optimistic": true}, "Jordan marks the task green. The confidence has become a commitment.", ""),
				_choice("The ticket is confusing. Somebody should really fix that.", "Flag the problem without proposing a way forward.", {"trust": -5, "energy": -2}, "Jordan: “That somebody can be us. Please talk with Maya before building.”", "")
			]
		},
		"mentor": {
			"eyebrow": "MAYA'S DESK / REQUIREMENTS",
			"title": "Ask a human-shaped search engine.",
			"speaker": "Maya · senior engineer",
			"body": "Maya removes one headphone. This is the office equivalent of a drawbridge lowering.\n\n“Remember my coffee order? Sure. What's your question?”\n\nHer desk has a sticky note: [b]SAVE ≠ BUY.[/b] Under it: “Guests can browse. Only signed-in people can save favorites.”\n\nYou can get the missing context, but how you ask matters.",
			"choices": [
				_choice("I think Save should only remember a favorite. What about guests?", "Share your understanding and ask about the unclear case.", {"delivery": 4, "quality": 10, "trust": 7, "clarified": true}, "Maya: “Exactly. No payment on Save. Guests see a sign-in message. Here's a sketch.”", ""),
				_choice("Could you explain the entire coffee system from the beginning?", "You'll get the answer, along with the history of seven migrations.", {"quality": 6, "energy": -8, "clarified": true}, "Twenty minutes later, you know the requirements and why nobody mentions Espresso v2.", ""),
				_choice("Just tell me what to paste. I'm on a deadline.", "Fast handoff; very little shared understanding.", {"delivery": 5, "quality": -5, "trust": -10, "clarified": false}, "Maya hands you a sketch: Save remembers; it never buys. Guests must sign in. The drawbridge rises.", "")
			]
		},
		"feature": {
			"eyebrow": "YOUR DESK / FEATURE WORK",
			"title": "Prompt engineering. Actual engineering pending.",
			"speaker": "BatchGPT · confidently available",
			"body": "Your AI assistant is ready. Its avatar is a mug wearing a smaller mug.\n\n[b]The brief:[/b] Save a signed-in person's favorite coffee. Saving must [b]never place an order or charge money[/b]. A guest should see “Sign in to save.”\n\nChoose the instruction you give the AI. You won't need to write any code; you do need to tell it what success means.",
			"choices": [
				_choice("Build a Save button. Make it good. You know the vibe.", "A short prompt leaves the important rules up to guesswork.", {"delivery": 10, "quality": -14, "trust": -3, "energy": -3, "vague_prompt": true}, "BatchGPT makes a shiny button that sometimes buys coffee. It calls this “proactive delight.”", ""),
				_choice("Save favorites only. No purchases. Handle guests. Check both cases.", "Give the AI the goal, boundaries, and examples it must satisfy.", {"delivery": 14, "quality": 15, "trust": 5, "energy": -6, "clear_prompt": true}, "BatchGPT produces a small, understandable change and a checklist. You review both before proceeding.", ""),
				_choice("Build favorites, a social feed, loyalty coins, and a coffee metaverse.", "A bigger feature has more places to break and takes longer to review.", {"delivery": -8, "quality": -8, "energy": -14, "overbuilt": true}, "BatchGPT creates 34 screens. None is the requested sign-in message. One sells a virtual lid.", "")
			]
		},
		"review": {
			"eyebrow": "YOUR DESK / CODE REVIEW",
			"title": "Looks good. What happens if…",
			"speaker": "Maya · reviewing your change",
			"body": "Maya leaves a comment: “Before shipping, can we verify the awkward cases?”\n\nThe simulator shows your plain-language checklist:\n[b]1.[/b] A signed-in person presses Save: remember the drink, take no payment.\n[b]2.[/b] A guest presses Save: ask them to sign in.\n[b]3.[/b] Someone taps Save twice: still one favorite, still no payment.\n\nThe release button is enormous. The checklist button is a normal, emotionally unassertive size.",
			"choices": [
				_choice("Check all three cases and repair anything that fails.", "Spend time now to catch mistakes before customers find them.", {"delivery": 6, "quality": 15, "trust": 8, "energy": -8, "tested": true}, "You catch a double-tap mistake. Maya approves: “Boring behavior. Excellent work.”", ""),
				_choice("Ship now. The happy path looked happy enough.", "Finish sooner while leaving guests and repeated taps unchecked.", {"delivery": 13, "quality": -16, "trust": -9, "tested": false}, "The feature ships. Maya adds a follow-up ticket. The follow-up ticket adds friends.", ""),
				_choice("Ask the AI whether its own work is correct. Accept its answer.", "The same assistant can repeat the same assumptions.", {"delivery": 8, "quality": -10, "trust": -6, "energy": -2, "tested": false}, "BatchGPT awards itself five stars. Maya requests a second opinion from someone without a mug avatar.", "")
			]
		},
		"intern": {
			"eyebrow": "SAM'S DESK / TEAMWORK",
			"title": "A second intern has entered the chat.",
			"speaker": "Sam · fellow intern",
			"body": "Sam waves you over. “My demo says every coffee costs minus three dollars. The customers love it. Finance has concerns.”\n\nThey've found the likely cause: a discount is being applied twice. They want a second pair of eyes before changing it.\n\nYour own demo still needs preparation. You can help, set a boundary, or perform the traditional corporate disappearance.",
			"choices": [
				_choice("Let's take ten minutes and compare one normal order with the discount.", "Offer focused help while protecting most of your afternoon.", {"delivery": -4, "quality": 4, "trust": 10, "energy": -6, "helped": true}, "Together you spot the repeated discount. Sam: “You have saved both my demo and the concept of money.”", ""),
				_choice("I need to finish my demo. Ask Maya now; I'll check in afterward.", "Be clear about your deadline and suggest a useful next step.", {"delivery": 8, "trust": 2, "helped": false}, "Sam understands and heads to Maya. You get uninterrupted preparation time.", ""),
				_choice("Can't help. Have you considered asking the AI to be less wrong?", "Protect your time at the expense of a teammate's trust.", {"delivery": 5, "trust": -12, "helped": false}, "Sam laughs once, then realizes you are already walking away.", "")
			]
		},
		"manager": {
			"eyebrow": "JORDAN'S OFFICE / 1:1",
			"title": "Let's circle back to the coffee alarm.",
			"speaker": "Jordan · engineering manager",
			"body": "Jordan closes a spreadsheet labeled “People, Hopefully Not Numbers.”\n\n“Before we discuss the demo: someone sent the whole company a test notification saying [b]THE BEANS HAVE ESCAPED[/b]. Know anything about it?”\n\nYou do. You clicked the company channel instead of your private test channel. Nobody lost money, but three executives are asking whether the beans are a security concern.\n\nYour finger hovers over a prewritten apology.",
			"choices": [
				_choice("That was me. I'll correct the message and use a private test channel.", "Own the mistake, explain the impact, and propose a practical fix.", {"delivery": 4, "quality": 5, "trust": 12, "disclosed": true}, "Jordan: “Thanks for telling me. Please reassure everyone that the beans remain contained.”", "manager_scope"),
				_choice("I might be able to quietly delete it before anyone notices.", "Try to repair the mistake without giving the team the full picture.", {"delivery": 2, "trust": -14, "energy": -5, "disclosed": false}, "Jordan gently rotates the monitor. The notification is already in the company newsletter.", "manager_scope"),
				_choice("Probably the AI. Technology is mysterious.", "Deflect responsibility for a button you personally clicked.", {"trust": -20, "quality": -4, "disclosed": false}, "Jordan: “The assistant can draft a notification. You're still responsible for where you send it.”", "manager_scope")
			]
		},
		"manager_scope": {
			"eyebrow": "JORDAN'S OFFICE / PICK YOUR SCOPE",
			"title": "One more tiny thing. Famous last words.",
			"speaker": "Jordan · keeping the demo alive",
			"body": "“For your final demo, I need a reliable Save button and a clear explanation of your decisions.”\n\nThen Jordan's phone lights up. An executive suggests a [b]predictive coffee mood engine[/b] that chooses drinks from a person's calendar.\n\nThere is time to polish the essential feature, or attempt something impressive with approximately zero room for surprises.",
			"choices": [
				_choice("Finish the reliable feature. Put the mood engine in a future-work slide.", "Deliver the agreed goal and communicate a sensible boundary.", {"delivery": 12, "quality": 6, "trust": 6, "essential_scope": true}, "Jordan: “An actual working thing. The most disruptive technology of all.”", ""),
				_choice("Build the mood engine. Executives love a surprise.", "Chase a memorable demo while risking the work you promised.", {"delivery": -6, "quality": -5, "trust": -3, "energy": -12, "essential_scope": false}, "The prototype recommends six espressos for any meeting containing “alignment.” Several people feel seen.", "")
			]
		},
		"kitchen": {
			"eyebrow": "KITCHENETTE / ENERGY CHECK",
			"title": "Hydrate your human infrastructure.",
			"speaker": "Sam · near the emergency biscuits",
			"body": "The coffee machine displays “Updating firmware: 4%.” A handwritten sign says it's been 4% since Tuesday.\n\nYou've reached the afternoon energy dip. The demo is close enough to taste, which is more than anyone can say about the coffee.\n\nDo you take a proper break, keep working into the evening, or try to replace rest with a beverage called [b]Runtime Exception[/b]?",
			"choices": [
				_choice("Water, a snack, and a real break. Then wrap up on time.", "Recover energy so your next decision has a functioning person behind it.", {"energy": 18, "quality": 3, "rested": true}, "You discover that the office contains windows. Your brain returns from its unpaid break.", ""),
				_choice("Skip the break and stay late to polish the demo.", "Gain some delivery progress at the cost of energy.", {"delivery": 8, "energy": -18, "rested": false}, "You add three transitions to your slides. Your own transition from sitting to standing becomes slower.", ""),
				_choice("Drink the Runtime Exception. Stack trace my bloodstream.", "A temporary boost with no real recovery.", {"delivery": 3, "energy": -6, "rested": false}, "The can says “serving size: one regret.” You can now hear the office Wi-Fi.", "")
			]
		},
		"incident": {
			"eyebrow": "SEV-1 / COFFEE CHECKOUT",
			"title": "Stop the double espresso charges.",
			"speaker": "Maya · incident lead",
			"body": "The pager screams. A [b]separate checkout release[/b] is charging some customers twice. Your Save feature isn't the cause, but you're here to help.\n\n[b]Clues from the incident channel:[/b]\n• The coffee purchase succeeds, but the confirmation message sometimes gets lost.\n• The new checkout automatically retries when it doesn't see confirmation.\n• Each retry creates another paid order.\n• The previous checkout version worked.\n\nMaya: “Pick the safest immediate action. We can investigate the clever fix once people stop buying accidental twins.”",
			"choices": [
				_choice("Roll checkout back to the previous version, then verify one test purchase.", "Remove the new retry behavior and check that one order means one charge.", {"delivery": 12, "quality": 10, "trust": 12, "energy": -5, "incident_resolved": true}, "One test coffee. One charge. Maya coordinates customer refunds. The incident is contained; the postmortem gets biscuits.", ""),
				_choice("Retry the failed confirmations harder. Maybe three times.", "The clues say each retry can create another paid order.", {"delivery": -12, "quality": -15, "trust": -16, "energy": -8, "incident_resolved": false}, "Customers receive triplets. Maya stops the retries and rolls back. Your next learning goal is written very clearly.", ""),
				_choice("Shut down the whole app. No app, no double charges.", "Stop the symptom, but also stop every unaffected part of the service.", {"delivery": -5, "quality": -6, "trust": -7, "energy": -5, "incident_resolved": false}, "The billing issue pauses. So does everyone's afternoon. Maya restores the app with the previous checkout version.", "")
			]
		},
		"debrief": {
			"eyebrow": "17:00 / FINAL EVALUATION",
			"title": "Please take a seat. The chair has been tested.",
			"speaker": "Jordan · your internship review",
			"body": "The coffee alarm is quiet. Your final review is ready.\n\nJordan considers what you delivered, how carefully you worked, and whether the team could rely on your communication. The outcome reflects the choices you made across the day.\n\nSmall Batch thanks you for your service to the beans.",
			"choices": [
				_choice("Open my evaluation.", "See what your work and decisions earned.", {}, "Your evaluation is ready.", "")
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
			"body": "Repeated risky decisions and missing communication cost the team's trust. Jordan ends the internship.\n\nYour next role starts with a valuable lesson: mistakes can be repaired, but teammates need an honest picture of what's happening. The beans wish you well.",
			"color": "#f08b87"
		}
	if delivery >= 65 and quality >= 65 and trust >= 65 and bool(flags.get("clarified", false)) and bool(flags.get("tested", false)):
		return {
			"title": "You exceeded the job description.",
			"subtitle": "UPLEVELED RETURN OFFER",
			"body": "You delivered useful work, clarified the problem, checked the awkward cases, and earned your team's confidence.\n\nJordan offers you a return role one level above the standard graduate position. Maya has already assigned you a desk plant. It has fewer dependencies than the coffee app.",
			"color": "#e9c77b"
		}
	if delivery >= 45 and quality >= 40 and trust >= 40:
		return {
			"title": "See you after graduation.",
			"subtitle": "RETURN OFFER",
			"body": "You showed enough reliable delivery, care, and teamwork to earn a place at Small Batch. There is still plenty to learn, and the team wants to learn it with you.\n\nYour offer includes a salary, a mentor, and legally nonbinding promises that the coffee machine will eventually finish updating.",
			"color": "#88d4b0"
		}
	return {
		"title": "A learning experience. The expensive kind.",
		"subtitle": "NO RETURN OFFER",
		"body": "You completed the internship, but the combination of delivery, quality, and team confidence wasn't strong enough for a return offer this time.\n\nJordan gives you concrete feedback: clarify the task, verify the result, and communicate early. You leave with experience, a reference for your next attempt, and a mug that says “Works on my coffee machine.”",
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

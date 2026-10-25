extends RefCounted
## Fictional office history and local, randomized BatchGPT replies.

static func messages() -> Array[Dictionary]:
	return [
		{"sender":"Jordan · #engineering", "time":"Yesterday 09:02", "text":"Welcome back. Tomorrow is the intern demo. Please keep the demo smaller than the slide deck."},
		{"sender":"Maya · Direct message", "time":"Yesterday 09:14", "text":"Nice work on CR #101. Small fixes are easier to review than surprise coffee ecosystems."},
		{"sender":"You · Maya", "time":"Yesterday 09:17", "text":"Thanks! Next time I will check the guest case before declaring victory."},
		{"sender":"Maya · Direct message", "time":"Yesterday 09:19", "text":"That sentence is worth keeping. Ask me when a ticket is unclear."},
		{"sender":"Sam · Direct message", "time":"Yesterday 11:10", "text":"Do we have a staging environment for the coffee machine? Asking before I press this button."},
		{"sender":"You · Sam", "time":"Yesterday 11:12", "text":"The machine says production only. I respect its confidence."},
		{"sender":"Sam · Direct message", "time":"Yesterday 11:13", "text":"I have chosen water. My first successful risk assessment."},
		{"sender":"Maya · #reviews", "time":"Yesterday 13:40", "text":"CR #102 merged: the printer no longer pages an engineer when it needs paper. A historic day."},
		{"sender":"Jordan · Direct message", "time":"Yesterday 16:45", "text":"Your final-day 1:1 is tomorrow afternoon. Bring an example of something you learned, including anything that went wrong."},
		{"sender":"You · Jordan", "time":"Yesterday 16:47", "text":"I have several examples. I will curate."},
		{"sender":"Pager bot · #incidents", "time":"Last Tuesday 15:05", "text":"RESOLVED: kitchenette health check was reporting no beans. The monitor was pointed at a bagel."},
		{"sender":"Maya · #incidents", "time":"Last Tuesday 15:12", "text":"Postmortem action: name the sensors. Please do not deploy a bagel classifier."},
		{"sender":"Sam · #engineering", "time":"Today 08:41", "text":"CR #103 is ready for another look. Guest checkout is almost boring, which I am told is the goal."}
	]

static func change_requests() -> Array[Dictionary]:
	return [
		{"id":103, "title":"Hide subscription controls from guest checkout", "author":"Sam", "branch":"sam/guest-checkout", "status":"Open", "added":24, "removed":8, "files":2, "comments":[["Maya", "The guest screen looks better. Please also check the keyboard path."], ["Sam", "Added the missing check. Ready for another review."]], "diff":"  Guest checkout\n+ Show a sign-in reminder\n- Offer a recurring coffee subscription\n+ Keep one-time checkout available", "checks":["Guest view: passed", "Keyboard navigation: passed", "Signed-in checkout: passed"]},
		{"id":102, "title":"Stop the printer from paging engineers", "author":"Maya", "branch":"maya/printer-health", "status":"Merged", "added":18, "removed":31, "files":3, "comments":[["Jordan", "Why was paper a severity-one dependency?"], ["Maya", "The alert has been moved to the office supplies channel."], ["You", "Tested with an empty tray. Nobody ran."]], "diff":"  Printer alerts\n- Page the on-call engineer when paper is low\n+ Notify office supplies\n+ Keep actual network failures in monitoring", "checks":["Empty tray: passed", "Offline printer: passed", "No accidental page: passed"]},
		{"id":101, "title":"Fix the duplicate welcome discount", "author":"You", "branch":"intern/one-discount", "status":"Merged", "added":9, "removed":6, "files":1, "comments":[["Maya", "Good small change. What happens for a guest?"], ["You", "Guests see the normal price. I added the missing check."], ["Maya", "Approved. One discount is enough disruption."]], "diff":"  Welcome offer\n- Apply the welcome discount twice\n+ Apply the offer once per person\n+ Show normal prices to guests", "checks":["New account: passed", "Repeat visit: passed", "Guest price: passed"]},
		{"id":100, "title":"Put the office kettle on a blockchain", "author":"You", "branch":"intern/kettle-ledger", "status":"Closed", "added":483, "removed":2, "files":12, "comments":[["Jordan", "What problem does this solve?"], ["You", "The AI said decentralization would reduce steeping time."], ["Maya", "Closing this. The kettle can remain a kettle."]], "diff":"  Kettle roadmap\n+ Verify each cup using a distributed ledger\n+ Introduce a tea token\n- Make hot water immediately", "checks":["Boils water: not demonstrated", "Business case: missing", "Closed without merging"]}
	]

static func chats() -> Array[Dictionary]:
	return [
		{"title":"Why is staging purple?", "messages":[{"role":"user", "text":"Why did staging turn purple after my change?"}, {"role":"assistant", "text":"First check whether the theme flag changed. If not, I recommend calling it a brand refresh while you investigate."}, {"role":"user", "text":"It was the theme flag."}, {"role":"assistant", "text":"Excellent. We have eliminated ghosts from this particular incident."}]},
		{"title":"Name the coffee app", "messages":[{"role":"user", "text":"Suggest a sensible name for an office coffee app."}, {"role":"assistant", "text":"Small Batch. My alternatives include BeanOS, Brewdential, and a name that requires a subscription to pronounce."}]},
		{"title":"Yesterday's discount fix", "messages":[{"role":"user", "text":"How should I check that a discount only runs once?"}, {"role":"assistant", "text":"Try a new account, a repeat visit, and a guest. Check the final price each time. Please resist solving this by adding a third discount."}]}
	]

static func reply(prompt: String, previous: String = "") -> String:
	var lower: String = prompt.to_lower()
	var pool: Array[String] = [
		"Start with the smallest useful version, check one example, and ask a human about any missing detail. I have generously omitted the 47-step transformation roadmap.",
		"I would write down the goal, try one small step, and verify the result before doing more. Confidence is not a substitute for a working button, although I have plenty of it.",
		"My recommendation is a clear question followed by a tiny experiment. If that fails, we can schedule a meeting with a name containing the word alignment.",
		"Here is a practical first step: explain what a successful result looks like, then check whether your change actually produces it. I will be here, sounding certain."
	]
	if lower.contains("coffee") or lower.contains("espresso") or lower.contains("tea"):
		pool = ["I recommend one coffee and one glass of water. Scaling horizontally to six espressos is not a sustainable architecture.", "Keep the coffee simple: select a drink, confirm once, and charge once. A second charge is not a loyalty feature.", "Try a small batch before serving the whole office. This advice applies equally to coffee and software, which is excellent reuse.", "The optimal brew is the one you can explain to the next person. My more ambitious proposal involves a mug that requests code review."]
	elif lower.contains("code") or lower.contains("bug") or lower.contains("test") or lower.contains("merge") or lower.contains("save") or lower.contains("prompt"):
		pool = ["Check the normal case, a signed-out person, and a repeated action. Make a small change, attach the results, and request a human review before merging.", "I would reproduce the problem once, change the smallest relevant behavior, and run the same example again. Naming the test final_final_v2 is optional.", "Write the expected behavior first. If Save should remember a favorite, explicitly say that it must never place an order. I otherwise have far too many ideas.", "Draft a focused change request, explain what changed, and check the awkward cases. I can suggest a fix, but approving my own work would be a spectacular conflict of interest."]
	elif lower.contains("manager") or lower.contains("meeting") or lower.contains("standup") or lower.contains("deadline"):
		pool = ["Give a clear update: what is done, what is blocked, and what you will do next. Optimism should come with an expiry date.", "Ask which outcome matters most and agree on a smaller scope. My alternative is a 90-slide deck, so this is me showing restraint.", "Be specific about the problem and suggest one next step. If the meeting needs another meeting, check whether anyone has tried a message.", "State the deadline, the remaining work, and the tradeoff honestly. Quietly replacing sleep with confidence does not create more time."]
	var index: int = randi_range(0, pool.size() - 1)
	if pool[index] == previous:
		index = (index + 1) % pool.size()
	return pool[index]

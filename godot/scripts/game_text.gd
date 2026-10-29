extends RefCounted
const NAMES = ["رامین", "برهان", "ممد"]
const INTRO_DESCRIPTION = (
	"رامین پشت میزها کمین می‌کند، برهان دورت می‌زند "
	+ "و ممد با صداهای الکی گولت می‌زند! هر سه را پیدا کن "
	+ "و سیبیل را دقیق روی لبشان بنشان."
)
const CONTROLS = (
	"حرکت: \u2066WASD\u2069 · دویدن: \u2066SHIFT\u2069"
	+ " · جست‌وجو: \u2066E\u2069 · شلیک: \u2066CLICK\u2069"
)
const INITIAL_HINT = "خانه را بگرد؛ سه نفر مخفی شده‌اند!"


static func number(value: Variant) -> String:
	var result := str(value)
	for i in range(10):
		result = result.replace(str(i), "۰۱۲۳۴۵۶۷۸۹"[i])
	return result


static func phase_copy(phase: String, score: int, caught: int) -> Dictionary:
	match phase:
		"paused":
			return {
				"title": "یه لحظه استراحت!",
				"description": "شکار هنوز تمام نشده. هر وقت آماده بودی ادامه بده.",
				"eyebrow": "GAME PAUSED",
				"action": "ادامه بازی",
			}
		"won":
			return {
				"title": "هر سه نفر سیبیل‌دار شدند!",
				"description":
				(
					"هر سه شخصیت را گرفتی! امتیاز نهایی: "
					+ number(score)
					+ ". آماده‌ای یک بار دیگر دنبالشـان بگردی؟"
				),
				"eyebrow": "ALL THREE CAPTURED",
				"action": "دوباره بازی کن",
			}
		_:
			return {
				"title": "وقت تمام شد!",
				"description":
				(
					"توانستی "
					+ number(caught)
					+ " نفر از ۳ نفر را بگیری. امتیاز: "
					+ number(score)
					+ ". در دور بعدی جای مخفی‌شدن‌ها عوض می‌شود."
				),
				"eyebrow": "TIME IS UP",
				"action": "یک فرصت دیگر",
			}

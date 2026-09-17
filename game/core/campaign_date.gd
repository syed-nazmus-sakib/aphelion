class_name CampaignDate
extends RefCounted

const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12

var day: int = 0


static func from_total_days(total: int) -> CampaignDate:
	var d := CampaignDate.new()
	d.day = maxi(0, total)
	return d


func total_days() -> int:
	return day


func advance(days: int) -> void:
	day = maxi(0, day + days)


func year() -> int:
	return day / (DAYS_PER_MONTH * MONTHS_PER_YEAR)


func month() -> int:
	return (day % (DAYS_PER_MONTH * MONTHS_PER_YEAR)) / DAYS_PER_MONTH + 1


func day_of_month() -> int:
	return day % DAYS_PER_MONTH + 1


func label() -> String:
	return "Exodus Year %d, Month %d, Day %d" % [year(), month(), day_of_month()]


func short_label() -> String:
	return "Y%d M%02d D%02d" % [year(), month(), day_of_month()]


func to_dict() -> Dictionary:
	return {"day": day}


static func from_dict(data: Dictionary) -> CampaignDate:
	if not data is Dictionary or not data.has("day"):
		return null
	var v = data.get("day")
	if not (v is int or v is float):
		return null
	return from_total_days(int(v))

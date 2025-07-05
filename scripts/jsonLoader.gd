extends Node

static func loadJson(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Can't open JSON : %s" % path)
		return []
	var data = file.get_as_text()
	file.close()
	
	var parseResult = JSON.parse_string(data)
	return parseResult

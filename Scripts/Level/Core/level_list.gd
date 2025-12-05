extends Resource
class_name LevelList

static var _level_lists_cache: Dictionary = {}
static var _tutorial_levels_cache: Array = []
static var _basic_levels_cache: Array = []

static func get_level_lists() -> Dictionary:
	if _level_lists_cache.is_empty():
		_level_lists_cache = {
			"Tutorial": [
				load("uid://dg4aqqbs2gsyq"), # Tutorial Basic
				load("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
				load("uid://co1t4pi0rj21"), # Tutorial Wolf
			],
			"Basic": [
				load("uid://bkcegcx75ii7n"), # Basic Level 1
				load("uid://c7au3pqv2hj36"), # Basic Level 2 
				load("uid://iew70rv7tmwc"),  # Basic Level 3
				# load("uid://dsq2p8lnac1qg"), # Basic Level Test
				load("uid://mxj4p352jd5k"), # Basic Level 4
			],
		}
	return _level_lists_cache

static func get_tutorial_levels() -> Array:
	if _tutorial_levels_cache.is_empty():
		_tutorial_levels_cache = [
			load("uid://dg4aqqbs2gsyq"), # Tutorial Basic
			load("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
			load("uid://co1t4pi0rj21"), # Tutorial Wolf
		]
	return _tutorial_levels_cache

static func get_basic_levels() -> Array:
	if _basic_levels_cache.is_empty():
		_basic_levels_cache = [
			load("uid://bkcegcx75ii7n"), # Basic Level 1
			load("uid://c7au3pqv2hj36"), # Basic Level 2 
			load("uid://iew70rv7tmwc"),  # Basic Level 3
			# load("uid://dsq2p8lnac1qg"), # Basic Level 4
			load("uid://mxj4p352jd5k"), # Basic Level 4
		]
	return _basic_levels_cache

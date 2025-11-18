extends Resource
class_name LevelList


static var LEVEL_LISTS: Dictionary[String, Array] = {
	"Tutorial": [
		preload("uid://dg4aqqbs2gsyq"), # Tutorial Basic
		preload("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
		# preload("uid://co1t4pi0rj21"), # Tutorial Wolf
	],
	"Basic": [
		preload("uid://bkcegcx75ii7n"), # Basic Level 1
		preload("uid://c7au3pqv2hj36"), # Basic Level 2 
		preload("uid://iew70rv7tmwc"),  # Basic Level 3
		# preload("uid://dsq2p8lnac1qg"), # Basic Level Test
		preload("uid://mxj4p352jd5k"), # Basic Level 5
	],
}

static var TUTORIAL_LEVELS: Array[Resource] = [
	preload("uid://dg4aqqbs2gsyq"), # Tutorial Basic
	preload("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
	preload("uid://co1t4pi0rj21"), # Tutorial Wolf
]

static var BASIC_LEVELS: Array[Resource] = [
	preload("uid://bkcegcx75ii7n"), # Basic Level 1
	preload("uid://c7au3pqv2hj36"), # Basic Level 2 
	preload("uid://iew70rv7tmwc"),  # Basic Level 3
	preload("uid://dsq2p8lnac1qg"), # Basic Level 4
	preload("uid://mxj4p352jd5k"), # Basic Level 5
]

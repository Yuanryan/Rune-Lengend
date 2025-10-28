extends Resource
class_name LevelList


static var LEVEL_LISTS: Dictionary[String, Array] = {
    "Tutorial": [
        preload("uid://dg4aqqbs2gsyq"), # Tutorial Basic
        preload("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
    ],
    "Basic": [
        preload("uid://bkcegcx75ii7n"), # Basic Level 1
        preload("uid://c7au3pqv2hj36"), # Basic Level 2 
        preload("uid://iew70rv7tmwc"),  # Basic Level 3
    ],
}
# static var level_lists: Dictionary[String, Array] = {
#     "Tutorial": [
#         preload("uid://dg4aqqbs2gsyq"), # Tutorial Basic
#         preload("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
#     ],
#     "Basic": [
#         preload("uid://bkcegcx75ii7n"), # Basic Level 1
#         preload("uid://c7au3pqv2hj36"), # Basic Level 2 
#         preload("uid://iew70rv7tmwc"),  # Basic Level 3
#     ],
# }



static var TUTORIAL_LEVELS: Array[Resource] = [
    preload("uid://dg4aqqbs2gsyq"), # Tutorial Basic
    preload("uid://dyev0ja3pu1j0"), # Tutorial Rabbit
]

static var BASIC_LEVELS: Array[Resource] = [
    preload("uid://bkcegcx75ii7n"), # Basic Level 1
    preload("uid://c7au3pqv2hj36"), # Basic Level 2 
    preload("uid://iew70rv7tmwc"),  # Basic Level 3
]






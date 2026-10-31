class_name Blocks

const AIR: int = 0
const GRASS: int = 1
const DIRT: int = 2
const STONE: int = 3
const COBBLESTONE: int = 4
const PLANKS: int = 5
const LOG: int = 6
const LEAVES: int = 7
const SAND: int = 8
const GLASS: int = 9
const BEDROCK: int = 10
const WATER: int = 11

enum Face { TOP, BOTTOM, EAST, WEST, SOUTH, NORTH }

const DEFS: Dictionary = {
	AIR: {
		"name": "air", "opaque": false, "solid": false,
		"tile_top": -1, "tile_bottom": -1, "tile_side": -1
	},
	GRASS: {
		"name": "grass", "opaque": true, "solid": true,
		"tile_top": 0, "tile_bottom": 2, "tile_side": 1
	},
	DIRT: {
		"name": "dirt", "opaque": true, "solid": true,
		"tile_top": 2, "tile_bottom": 2, "tile_side": 2
	},
	STONE: {
		"name": "stone", "opaque": true, "solid": true,
		"tile_top": 3, "tile_bottom": 3, "tile_side": 3
	},
	COBBLESTONE: {
		"name": "cobblestone", "opaque": true, "solid": true,
		"tile_top": 4, "tile_bottom": 4, "tile_side": 4
	},
	PLANKS: {
		"name": "planks", "opaque": true, "solid": true,
		"tile_top": 5, "tile_bottom": 5, "tile_side": 5
	},
	LOG: {
		"name": "log", "opaque": true, "solid": true,
		"tile_top": 7, "tile_bottom": 7, "tile_side": 6
	},
	LEAVES: {
		"name": "leaves", "opaque": false, "solid": true,
		"tile_top": 8, "tile_bottom": 8, "tile_side": 8
	},
	SAND: {
		"name": "sand", "opaque": true, "solid": true,
		"tile_top": 9, "tile_bottom": 9, "tile_side": 9
	},
	GLASS: {
		"name": "glass", "opaque": false, "solid": true,
		"tile_top": 10, "tile_bottom": 10, "tile_side": 10
	},
	BEDROCK: {
		"name": "bedrock", "opaque": true, "solid": true,
		"tile_top": 11, "tile_bottom": 11, "tile_side": 11
	},
	WATER: {
		"name": "water", "opaque": false, "solid": false,
		"tile_top": 12, "tile_bottom": 12, "tile_side": 12
	}
}

const OPAQUE_BY_ID: Array[bool] = [
	false, true, true, true, true, true, true, false, true, false, true, false
]
const SOLID_BY_ID: Array[bool] = [
	false, true, true, true, true, true, true, true, true, true, true, false
]
const TILE_TOP_BY_ID: Array[int] = [
	-1, 0, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12
]
const TILE_BOTTOM_BY_ID: Array[int] = [
	-1, 2, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12
]
const TILE_SIDE_BY_ID: Array[int] = [
	-1, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12
]

static func is_opaque(id: int) -> bool:
	return id >= 0 and id < OPAQUE_BY_ID.size() and OPAQUE_BY_ID[id]

static func is_solid(id: int) -> bool:
	return id >= 0 and id < SOLID_BY_ID.size() and SOLID_BY_ID[id]

static func name_of(id: int) -> String:
	return str(_definition(id).get("name", "air"))

static func tile_for_face(id: int, face: int) -> int:
	if id < 0 or id >= TILE_TOP_BY_ID.size():
		return -1
	match face:
		Face.TOP:
			return TILE_TOP_BY_ID[id]
		Face.BOTTOM:
			return TILE_BOTTOM_BY_ID[id]
		Face.EAST, Face.WEST, Face.SOUTH, Face.NORTH:
			return TILE_SIDE_BY_ID[id]
		_:
			return -1

static func _definition(id: int) -> Dictionary:
	return DEFS.get(id, DEFS[AIR]) as Dictionary

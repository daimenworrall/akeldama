@tool
extends Resource
const Species = preload("res://features/dama/data/species_definition.gd")
const Type = preload("res://features/dama/data/type_definition.gd")
const Move = preload("res://features/dama/data/move_definition.gd")
@export var species: Array[Species] = []
@export var types: Array[Type] = []
@export var moves: Array[Move] = []

func find_species(id: String) -> Species:
	for data in species:
		if data.id == id:
			return data
	return null

func find_type(id: String) -> Type:
	for data in types:
		if data.id == id:
			return data
	return null

func find_move(id: String) -> Move:
	for data in moves:
		if data.id == id:
			return data
	return null

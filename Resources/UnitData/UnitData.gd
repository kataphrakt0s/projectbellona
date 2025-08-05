class_name UnitData extends Resource

@export var display_name: String = "Basic"
@export var unit: EntityManager.UNITS = EntityManager.UNITS.BASIC
@export var unit_type: EntityManager.UNITTYPE = EntityManager.UNITTYPE.LAND
@export var max_move_points: int = 3
@export var move_speed: float = 100.0
@export var attack_power: int = 3
@export var attack_range: int = 1
@export var description: String = "Basic ground unit."

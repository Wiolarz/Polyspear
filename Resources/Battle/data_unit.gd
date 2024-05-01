class_name DataUnit

extends Resource


@export var unit_name : String
@export var texture_path : String
@export var symbols : Array[DataSymbol] = [null,null,null,null,null,null]
@export var cost : Goods = Goods.new()

func apply_data(_unit : UnitForm) -> void:
	pass

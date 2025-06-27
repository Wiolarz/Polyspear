class_name Discount
extends Resource

enum discount_type_enum {
    NONE,
    SUBTRACT,
    DIVIDE,
    INCREASING_SUBTRACT
}

enum discount_resource_enum {
    WOOD,
    IRON,
    RUBY
}

@export var type : int = discount_type_enum.NONE

@export var resource : int = discount_resource_enum.WOOD

@export var control : int = 0

@export var value : int = 0

@export var counter : int = 0

func apply_discount(price: Goods) -> Goods:
    var wood_price : int = price.wood
    var iron_price : int = price.iron
    var ruby_price : int = price.ruby
    var is_wood : int = int(resource == discount_resource_enum.WOOD)
    var is_iron : int = int(resource == discount_resource_enum.IRON)
    var is_ruby : int = int(resource == discount_resource_enum.RUBY)
    match type:
        discount_type_enum.SUBTRACT:
            wood_price = (price.wood - value * is_wood)
            iron_price = (price.iron - value * is_iron)
            ruby_price = (price.ruby - value * is_ruby)
        discount_type_enum.DIVIDE:
            wood_price = price.wood / (1 + counter * is_wood)
            iron_price = price.iron / (1 + counter * is_iron)
            ruby_price = price.ruby / (1 + counter * is_ruby)
        discount_type_enum.INCREASING_SUBTRACT:
            wood_price = (price.wood - value * counter * is_wood)
            iron_price = (price.iron - value * counter * is_iron)
            ruby_price = (price.ruby - value * counter * is_ruby)
    return Goods.new(
        0 if price.wood == 0 else 1 if wood_price <= 0 else wood_price,
        0 if price.iron == 0 else 1 if iron_price <= 0 else iron_price,
        0 if price.ruby == 0 else 1 if ruby_price <= 0 else ruby_price
    )

func on_end_of_round() -> void:
    counter += 1

func reset_discount_counter() -> void:
    counter = 0

func copy() -> Discount:
    var new_discount = Discount.new()
    new_discount.type = type
    new_discount.resource = resource
    new_discount.control = control
    new_discount.value = value
    new_discount.counter = 0
    return new_discount
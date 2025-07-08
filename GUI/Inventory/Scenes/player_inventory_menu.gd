extends CanvasLayer
@export var unit: Unit 
@onready var item_list_container = $Panel/VBoxContainer/ScrollContainer/ItemListContainer

# Individual tab buttons
@onready var provisions_button = $Panel/VBoxContainer/CategoryTabs/ProvisionsButton
@onready var key_items_button = $Panel/VBoxContainer/CategoryTabs/KeyItemsButton
@onready var armor_button = $Panel/VBoxContainer/CategoryTabs/ArmorButton
@onready var ranged_button = $Panel/VBoxContainer/CategoryTabs/RangedButton
@onready var melee_button = $Panel/VBoxContainer/CategoryTabs/MeleeButton
@onready var all_button = $Panel/VBoxContainer/CategoryTabs/AllButton

func _ready():
	# Connect tab button presses to populate_items with appropriate category
	provisions_button.pressed.connect(func(): populate_items("Provisions"))
	key_items_button.pressed.connect(func(): populate_items("KeyItems"))
	armor_button.pressed.connect(func(): populate_items("Armor"))
	ranged_button.pressed.connect(func(): populate_items("Ranged"))
	melee_button.pressed.connect(func(): populate_items("Melee"))
	all_button.pressed.connect(func(): populate_items("All"))
		# Populate initial view
	populate_items("All")

func _on_close_button_pressed() -> void:
	queue_free()

func populate_items(category: String):
	pass

func get_items_to_display() -> void:
	pass


func _on_provisions_button_pressed() -> void:
	pass # Replace with function body.


func _on_key_items_button_pressed() -> void:
	pass # Replace with function body.


func _on_armor_button_pressed() -> void:
	pass # Replace with function body.


func _on_ranged_button_pressed() -> void:
	pass # Replace with function body.


func _on_melee_button_pressed() -> void:
	pass # Replace with function body.


func _on_all_button_pressed() -> void:
	pass # Replace with function body.

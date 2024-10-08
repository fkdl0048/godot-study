extends Area3D

var move_x = false
var move_y = false

var move_amount = 2.5
var move_speed = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label3D.hide()
	

func _on_body_entered(body: Node3D) -> void:
	$CollisionShape3D/MeshInstance3D.hide()
	var d = global_position.distance_to(body.global_position)
	if d < 2.0:
		$Label3D.text = "200"
		$Label3D.modulate = Color(1, 1, 0)
	elif d > 3.5:
		$Label3D.text = "50"
	$Label3D.show()
	var tween = create_tween().set_parallel()
	tween.tween_property($Label3D, "position", Vector3(0, 10, 0), 1.0)
	tween.tween_property($Label3D, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	$CollisionShape3D/MeshInstance3D.rotate_y(deg_to_rad(50) * delta)

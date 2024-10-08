extends CharacterBody3D

@export var pitch_speed = 1.1
@export var roll_speed = 2.5
@export var level_speed = 4.0
@export var forward_speed = 25

var roll_input = 0
var pitch_input = 0
var max_altitude = 20

func get_input(delta):
	pitch_input = Input.get_axis("pitch_down", "pitch_up")
	roll_input = Input.get_axis("roll_left", "roll_right")
	if position.y >= max_altitude and pitch_input > 0:
		position.y = max_altitude
		pitch_input = 0

func _physics_process(delta):
	
	get_input(delta)
	
	# rotate the plane up/down
	rotation.x = lerpf(rotation.x, pitch_input, pitch_speed * delta)
	# limit the max climb anglew
	rotation.x = clamp(rotation.x, deg_to_rad(-45), deg_to_rad(45))
	
	# roll the mesh left/right
	$cartoon_plane.rotation.z = lerpf($cartoon_plane.rotation.z, roll_input, roll_speed * delta)
	
	velocity = -transform.basis.z * forward_speed 
	velocity += transform.basis.x * $cartoon_plane.rotation.z / deg_to_rad(45) * forward_speed / 2.0
	
	move_and_slide()
	

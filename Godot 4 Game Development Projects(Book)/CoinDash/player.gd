extends Area2D

signal pickup ## 동전에 닿았을 때 발신할 시그널
signal hurt ## 장애물에 닿았을 때 발신할 시그널

@export var speed = 350

var velocity = Vector2.ZERO
var screensize = Vector2(480, 720)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func start():
	set_process(true)
	position = screensize / 2
	$AnimatedSprite2D.animation = "idle"

func die():
	$AnimatedSprite2D.animation = "hurt"
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	position += velocity * speed * delta
	position.x = clamp(position.x, 0, screensize.x)
	position.y = clamp(position.y, 0, screensize.y)
	
	# Animation
	if velocity.length() > 0:
		$AnimatedSprite2D.animation = "run"
	else:
		$AnimatedSprite2D.animation = "idle"
	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

func _on_area_entered(area):
	if area.is_in_group("coins"):
		area.pickup()
		pickup.emit("coin")
	if area.is_in_group("powerups"):
		area.pickup()
		pickup.emit("powerup")
	if area.is_in_group("obstacles"):
		hurt.emit()
		die()

extends DirectionalLight3D

# 회전 속도를 설정 (라디안 단위)
var rotation_speed: float = 1.0  # 1초에 한 번 회전하는 속도

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Y축을 중심으로 빛을 회전시킴 (원점 기준 회전)
	rotate_y(rotation_speed * delta)

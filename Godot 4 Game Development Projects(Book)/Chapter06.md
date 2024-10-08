## 인피니트 플라이어

이 장에선 템플런과 같은 게임을 만들 예정이다. 배우게 될 것은 다음과 같다.

- 변형을 사용해 3D 공간에서 회전 및 이동하기
- 게임 월드의 '청크'로드와 언로드
- 게임 환경과 게임 오브젝트를 랜덤으로 생성하는 방법
- 데이터 영구 저장을 위한 파일 저장과 불러오기
- `CharacterBody3D` 사용과 콜리전 감지

### 프로젝트 설정

#### 입력

마찬가지로 비행기 게임에 맞는 입력을 설정한다.

### 비행기 씬

`CharacterBody3D`노드로 시작하여 비행기(플레이어) 생성한다. 이 프로젝트는 이미 제작된 3D모델를 사용한다.

#### 콜리전 모양

추가로 항상 메시에 맞는 Collsion을 생성하기 보다, 사용자 편의성에 맞게 콜리전을 생성해야 한다. 콜리전을 다룰 땐, 스냅 기능을 사용하자.

#### 비행기 스크립트 작성

비행기의 움직임은 부드럽게 움직여야 한다. 위 아래 피치 움직임과 왼쪽 오른쪽 롤 움직임을 구현한다. 부드럽게 움직이기 하기 위해서 보간을 사용해야 한다. `lerp`라고 하며 부드럽게 변경하는 기능이다. *다른 엔진에도 존재하는 기능이다.*

```gd
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
```

`Input.get_axis`을 사용하여 위/아래 피치와 좌/우 롤을 입력 받고 있다. -1과 1의 사이값을 반환받는다. `lerp`를 사용하여 부드럽게 움직이게 하고 있다. `clamp`를 사용하여 최대 각도를 제한하고 있다. `move_and_slide`를 사용하여 이동하고 있다.

### 월드 만들기

이 프로젝트의 특징인 무한 방식의 게임의 핵심인 월드를 제작한다. 기존 유니티에서 사용하는 방식과 비슷하게 사용하며 프리팹과 씬을 객체로 사용한다는 점이 다르다.

#### 월드 오브젝트

사용하는 청크는 건물과 링이며 이를 동적으로 생성한다.

머터리얼의 세부속성은 정말 유니티 못지 않게 많다. 또한 노드의 속성을 변경하면 미리보기에서도 바로 적용된다.

*사용중에 에디터로 변경되는 모습을 다른 카메라로 바라볼 수 없다는 점이 아쉽다.*

```gd
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
```

전체적으로 코드의 느낌은 로직이 분리된다기 보다.. 객체와 씬으로 다룬다는 점에서 코드도 그 성격을 조금씩 따라가는 것 같다.

#### 청크

청크는 기본적으로 동적생성하고 시야에서 사라지면 제거한다. (풀링을 하던지) 생성되는 주기나 랜덤성은 적절한 알고리즘을 통해 난이도를 조절할 수 있도록 만든다.

```gd
extends Node3D

var buildings = [
	preload("res://buildings/building_1.tscn"),
	preload("res://buildings/building_2.tscn"),
	preload("res://buildings/building_3.tscn"),
	preload("res://buildings/building_4.tscn"),
	preload("res://buildings/building_5.tscn"),
]

var ring = preload("res://ring.tscn")

var level = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_buildings()
	add_center_buildings()
	add_rings()
	
func add_buildings() -> void:
	for side in [-1, 1]:
		var zpos = -10
		for i in 18:
			if randf() > 0.75:
				zpos -= randi_range(5, 10)
				continue
			var nb = buildings[randi_range(0, buildings.size()-1)].instantiate()
			add_child(nb)
			nb.transform.origin.z = zpos
			nb.transform.origin.x = 20 * side
			zpos -= nb.get_node("MeshInstance3D").mesh.get_aabb().size.z
			
func add_center_buildings():
	if level > 0:
		for z in range(0, -200, -20):
			if randf() > 0.8:
				var nb = buildings[0].instantiate()
				add_child(nb)
				nb.position.z = z
				nb.position.x += 8
				nb.rotation.y = PI / 2
				
func add_rings():
	for z in range(0, -200, -10):
		if randf() > 0.76:
			var nr = ring.instantiate()
			nr.position.z = z
			nr.position.y = randf_range(3, 17)
			match level:
				0: pass
				1:
					nr.move_y = true
				2:
					nr.position.x = randf_range(-10, 10)
					nr.move_y = true
				3:
					nr.position.x = randf_range(-10, 10)
					nr.move_x = true
			add_child(nr)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()

```

생명주기에 영향을 주지 않기 위해 `preload`를 사용하여 미리 로드해둔다. `add_buildings`는 빌딩을 생성하고 `add_center_buildings`는 중앙에 빌딩을 생성한다. `add_rings`는 링을 생성한다. `match`를 사용하여 레벨에 따라 다른 링을 생성한다.

`_on_visible_on_screen_notifier_3d_screen_exited()`는 화면에서 사라지면 제거한다.

### 메인 씬

전 프로젝트와 마찬가지로 태양과 환경을 설정하고 세부설정에서 빛과 그림자를 설정한다. *참고로 고도엔진은 리얼타임 라이팅을 지원한다.*

지금까지 카메라를 사용할 때, 카메라에 맞는 씬을 따로 제작하거나, Main에서 카메라를 사용했다면 이번에는 유니티의 컴포넌트와 같이 따로 tscn(씬)을 만들어서 사용하는게 아닌 카메라에 스크립트를 붙이고 인스펙터에서 사용할 내용을 export하고 있다.

```gd
extends Camera3D

@export var target_path : NodePath
@export var offset = Vector3.ZERO

var target = null

func _ready():
	if target_path:
		target = get_node(target_path)
		position = target.position + offset
		look_at(target.position)

func _physics_process(delta: float) -> void:
	if !target:
		return
	position = target.position + offset
```

이 코드의 핵심은 기존 씬 객체로 다루던 고도의 특성 *(단일 모듈성으로 따로 동작할 수 있다는 점)이 아닌 스크립트 자체의 재활성이나 Main코드 자체의 양을 줄여서 분리하여 사용할 수 있다는 점 즉, 책임을 분담하여 사용할 수 있다는 것이 매력적이다.

이 내용을 알기전에 가능한지 몰랐는데 가능하다는 점을 알게 되었다.

![CutSene gif](https://github.com/user-attachments/assets/73e7c05d-8f1f-4c49-8ac0-c245f4dff09a)

### 요약

책에서 다루는 고도엔진 프로젝트 중 마지막 프로젝트다. 2D부터 3D까지 기본적인 반복, 재사용, 게임 로직, 시그널(이벤트), 물리, 레이어, 애니메이션 등 개념을 다뤘기 때문에 현재 작업한 예제 프로젝트를 개선해보거나 책을 안보고 따라해보는 방식으로 좀 더 심화학습을 하려고 한다.

`Mentoring`을 진행하면서 멘토님과 같은 프로젝트를 진행하면서 기간안에 마무리할 수 있어서 좋았다. 12월에 진행하는 홈커밍데이에서 고도엔진관련하여 발표를 진행할 예정이다. 모바일 빌드나 추가 구현, 다른 엔진과 비교등으로 스터디에 대한 결과 보고 느낌으로..

## 3D 미니골프: 미니골프 코스를 만들며 3D로 뛰어들기

이번 장에서 배울 내용은 다음과 같다.

- 고도의 3D 에디터 탐색하기
- `Node3D`와 그 속성
- 3D 메시 가져오기와 3D 콜리전 모양 사용
- 3D 카메라 사용법
- 조명 및 환경 설정
- PBR 및 머티리얼 소개

### 3D에 대한 소개

고도의 3D는 앞서 사용한 2D와 동일한 씬, 노드, 시그널의 구조를 그대로 따라간다. 하지만 3D만의 새로운 계층의 복잡성과 가능성이 추가된다.

#### 3D 공간에서 방향 지정

프로젝트 상단의 `3D`버튼을 클릭하면 3D 프로젝트 뷰로 볼 수 있다. X(빨강), Y(초록), Z(파랑)축이 보인다. 이 축들이 만나는 지점이 원점이며 좌표는 (0, 0, 0)이다.

3D로 작업을 할 때 항상 발생하는 문제는 애플리케이션마다 방향 정위에 사용하는 규칙이 서로 다르다는 점이다. 고도가 Y가 위인 방향 정위를 사용하므로 축을 볼 때 x가 왼쪽/오른쪽을 가리키고 y는 위/아래를 가리키며 z는 앞/뒤를 가리킨다.

*유니티의 경우 고도와 동일하고, 언리얼의 경우엔 z축이 위/아래, x축이 앞/뒤, y축이 좌/우를 나타낸다. 즉 오른손 좌표계*

알아야 할 또 다른 중요한 사실은 측정 단위로 2D에서는 고도가 모든 것을 픽셀 단위로 측정하므로 화면에 그림을 그릴 때의 측정 기본 단위로도 픽셀이 적합하다. 하지만 3D 공간에서 작업할 때는 픽셀이 그다지 유용하지 않다. 두 오브젝트의 크기가 같더라도 카메라의 기준에서 화면에서 차지하는 넓이가 달라지기 때문에 범용 단위로 측정한다. **고도에서는 3D 공간에서는 미터 단위를 사용한다.**

#### 고도의 3D 에디터

- 마우스 휠 위/아래: 현재 대상 줌인/줌아웃
- 가운데 버튼 + 드래그: 현재 대상을 중심으로 카메라 궤도 돌리기
- Shift + 가운데 버튼 + 드래그: 카메라를 위/아래/좌/우로 패닝
- 오른쪽 버튼 + 드래그: 제자리에서 카메라 회전

*살짝 다른 것 빼고 유니티나 언리얼과 비슷하다.*

뷰포트의 왼쪽 상단 모서리에 있는 원근 레이블을 클릭해 카메라의 시야에 영향을 줄 수도 있다. 여기에는 `Orthogonal`과 `Perspective`가 있다. `Orthogonal`은 3D 공간을 2D로 투영한 것이며, `Perspective`는 실제 3D 공간을 투영한 것이다.

*그래픽스 관련된 내용을 공부하면 이해하기 쉽다.*

#### 3D 오브젝트 추가

모든 2D 노드가 Position과 Rotation 같은 속성을 제공하는 `Node2D`를 상속하듯이 3D 노드는 공간 속성을 제공하는 `Node3D`를 상속한다.

#### 글로벌 공간과 로컬 공간

기본적으로 기즈모 제어는 글로벌 공간에서 작동한다. 이를 변경하기 위해 로컬 공간 모드로 변환하는 T키를 눌러서 로컬 공간에서 작업할 수 있다.

#### 변형

Node3D의 인스펙터를 보면 Transgorm 섹션이 있다. 그 아래 Translation, Rotation, Scale이 있는데, 이들은 모두 2D와 마찬가지로 부모에 상대적이다. 코드에서 노드의 공간 속성을 변경할 때는 해당 노드의 `transform` 속성에 접근하게 되는데, 이는 사실 고도 `Transform3D`오브젝트다. `Transform3D`에는 **origin과 basic라는 2가지 하위 속성이 있다.** origin 속성은 바디의 위치를 나타내며, basis 속성은 바디의 로컬 좌표축을 정의하는 3개의 벡터를 포함한다. 로컬 공간 모드에 있을 때 기즈모의 세 축 화살표를 생각하면 된다.

#### 메시

`Node2D`와 마찬가지로 `Node3D` 노드에는 자체적인 크기나 모습이 없다. 2D에서는 `Sprite2D`를 추가했다면 3D에서는 일반적으로 메시(Mesh)를 추가한다. 메시란, 3차원 모양을 수학적으로 묘사하는 것이며, 꼭지점의 집합으로 구성된다. 꼭지점은 모서리(edge)라는 선으로 연결되며, 모서리 여러 개(최소 3개)가 모여 면(face)을 형성한다.

고도에서는 특정 모델이 없을 때, 직접 만들 수 있는 기능이 있다. `MeshInstance3D` 노드를 자식으로 추가허여 인스펙터에서 Mesh 속성을 살펴보면 사전 정의된 원시 모양(primitive)를 선택할 수 있다.

고도의 권장 메시 형식은 `.gltf`이다.

#### 카메라

방금 만든 정육면체 메시로 씬을 실행해보면 아무것도 보이지 않는다. 3D에서는 씬에 `Camera3D` 노드가 없으면 게임 뷰포트에 아무것도 표시되지 않는다. 카메라를 추가하면 다음과 같은 새 노드가 보일 것이다.

*카메라도 직접 생성한다는 느낌이 조금 새롭기도 하다.*

씬에서 보이는 보라색 피라미드 모양을 카메라의 frustum(절두체)라고 한다. 카메라의 뷰를 나타내며 좁게 또는 넓게 만들어서 카메라의 시야(FOV, Field of View)를 조절할 수 있다. 상단의 삼각형은 카메라의 '위'를 나타낸다.

카메라를 생성한 시점에서 카메라 절두체가 -Z축을 향하고 있다는 점을 본다면 고도의 3D 공간에서 앞쪽 방향이라는 뜻이다. 따라서 오브젝트의 전방 축을 따라 이동하려는 코드를 짤 때는 다음과 같이 `transform.basis`를 사용해야 한다.

```gd
position += -transform.basis.z * speed * delta
```

*생각보다 중요한 개념이라고 생각한다.*

### 프로젝트 설정

에셋을 설정하고, 마찬가지로 입력 추상화인 입력 맵에서 사용할 키를 등록한다. 또한, 사용자가 창 크기를 조절할 때 UI 레이아웃이 흐트러지거나 게임 화면이 왜곡되어 표시될 수 있기에 이를 방지하기 위해서 표시/창 섹션에 스트레치/모드 설정을 viewport로 변경한다.

### 코스 만들기

`Node3D`노드로 Hole이라는 씬을 만들고 저번 프로젝트와 같이 프리팹처럼 공통으로 사용하는 노드와 코드를 포함한 씬을 만들어서 확장한다. 이후 `GridMap`노드를 추가한다.

#### GridMap 이해하기

`GridMap`은 앞서 사용한 `TileMap` 노드의 3D 버전이라고 할 수 있다. 이 노드를 사용하면 메시 모음을 사용해 격자로 배치할 수 있다. 3D로 작동하기 때문에 어떤 방향으로든 메시를 쌓을 수 있다.

고도엔진의 기능으로 메시를 선택하고 `Trimesh Static Body`을 선택하면 메시의 데이터를 이용해 `StaticBody3D` 노드와 그 밑에 딸린 `CollisionShape3D` 노드를 추가한다.

*메시로 콜리전 생성도 매우 쉽게 지원을 해준다.*

#### 첫 번째 홀 그리기

GridMap자체의 `Physicis Material`을 설정하여 튕김과 마찰을 조절할 수 있다. 이후 `Camera3D`를 추가하고 씬을 실행해보면 전체적으로 화면이 어두운 것을 알 수 있다. 조명은 그 자체만으로 매우 복잡하다.

고도 3D에서는 3가지 조명 노드를 제공한다.

- `OmniLight3D`(전방위 조명): 전구처럼 모든 방향으로 발산하는 빛
- `DirectionalLight3D`(방향성 조명): 태양광처럼 먼 광원으로부터의 빛
- `SpotLight3D`(각광): 손전등이나 랜턴 비슷한 원뿔 모양의 빛을 한 지점으로 투사

개별 조명을 배치하는 것 외에도 환경광(ambient light)을 설정할 수 있다. 에디터 창에 보이는 점 세개 버튼을 누르면 아주아주 쉽게 태양과 환경을 추가할 수 있다. *이 부분에서 정말 감탄,, 직관적이고 불필요한 설정없이 아주 쉽게 설정할 수 있다.*

`WorldEnvironment`노드와 `DirectionalLight3D`노드가 자동으로 추가된다.

#### 홀 추가하기

`Area3D`를 추가하고 2D와 똑같은 사용법으로 `CollisionShape3D`를 추가한다. 자식 속성에서 새 CylinderShape3D를 선택하여 홀 모양을 만든다

`Marker3D`노드를 추가하여 공이 시작할 위치를 잡는다. *유니티에서는 GO를 활용하는데, 따로 이런 노드가 있으니 직관적이다.*

### 공 만들기

물리를 사용하는 공이기 때문에 당연히 `RigidBody3D`를 사용한다. 2D와 마찬가지로 `_integerate_forces`, `apply_central_impulse`와 같은 메서드를 사용하여 상호작용할 수 있다.

#### 공 테스트

고도에선 테스트를 위함은 아니겠지만 Rigi속성에 velocity값이 있어서 공의 움직임을 테스트할 수 있다.

#### 공 콜리전 개선

테스트하다 보면 공이 이상하게 튕기거나 벽을 통과하는 경우가 있다. 이를 개선하기 위해 **연속 콜리전 감지**라는 CCD기능을 사용할 수 있다. 이 기능을 사용하면 물리 엔진이 콜리전을 계산하는 방식이 변경된다. 일반적으로 엔진은 먼저 오브젝트를 이동한 다음 콜리전을 테스트하고 해결하는 방식으로 동작한다.

이 방식은 빠르고 대다수 일반적인 상황에서 작동한다. CCD를 사용하면 엔진은 경로에 따라 오브젝트 움직임을 투영하고 콜리전이 발생할 위치를 예측하려 한다. 이는 기본 동작보다 느리며, 특히 많은 오브젝트를 시뮬레이션 할 때 더욱 느리다.

하지만 정확성은 훨씬 뛰어나며 지금은 공이 하나 뿐인 환경이라 성능저하가 눈에 보이지 않기에 공에만 사용한다. 마찬가지로 공에도 PhysicsMaterial을 적용하여 좀 더 사실적인 움직임을 추가한다. 다만 이렇게 되면 공이 멈추지 않고 계속 이동하기 때문에 마찰도 추가한다.

- Linear/Dump
- Angular/Dump

### UI 추가하기

이 게임에서는 겨냥과 발사를 위한 UI가 필요하다.

- 겨냥: 화살표가 나와서 앞 뒤로 흔들린다. 마우스 버튼을 클릭하면 겨냥 방향이 정해진다.
- 발사: 힘바가 위아래로 움직인다. 마우스를 클릭하면 힘이 정해지고 공이 발사된다.

#### 화살표로 겨냥하기

화살표 모델을 생성하고 투명도를 위해 머터리얼을 생성해서 정의한다.

#### UI 디스플레이

기존 게임들과 마찬가지로 UI를 제작한다.

### 게임 스크립팅

#### UI 코드

```gd
extends CanvasLayer

@onready var power_bar = $MarginContainer/VBoxContainer/powerBar
@onready var shots = $MarginContainer/VBoxContainer/shots

var bar_textures = {
	"green": preload("res://assets/bar_green.png"),
	"yellow": preload("res://assets/bar_yellow.png"),
	"red": preload("res://assets/bar_red.png")
}

func update_shots(value):
	shots.text = "Shots: %s" % value

func update_power_bar(value):
	power_bar.texture_progress = bar_textures["green"]
	if value > 70:
		power_bar.texture_progress = bar_textures["red"]
	elif value > 40:
		power_bar.texture_progress = bar_textures["yellow"]
	power_bar.value = value

func show_message(text):
	$Message.text = text
	$Message.show()
	await get_tree().create_timer(2).timeout
	$Message.hide()
```

- @onready: 노드 참조를 미리 로드한다.
- bar_textures: 딕셔너리로 텍스처를 미리 로드한다.
- UI씬에 적용된 스크립트이기 때문에 UI역할에 맞는 함수만 정의한다.

#### 메인 스크립트

```gd
extends Node3D

enum {AIM, SET_POWER, SHOOT, WIN}

@export var power_speed = 100
@export var angle_speed = 1.1

var angle_change = 1
var power = 0
var power_change = 1
var shots = 0
var state = AIM
var hole_dir

func _ready() -> void:
	$Arrow.hide()
	$Ball.position = $Tee.position
	change_state(AIM)
	$UI.show_message("Get Ready!")

func change_state(new_state):
	state = new_state
	match state:
		AIM:
			$Arrow.position = $Ball.position
			$Arrow.show()
			set_start_angle()
		SET_POWER:
			power = 0
		SHOOT:
			$Arrow.hide()
			$Ball.shoot($Arrow.rotation.y, power / 15)
			shots += 1
			$UI.update_shots(shots)
		WIN:
			$Ball.hide()
			$Arrow.hide()
			$UI.show_message("Win!")

func _input(event: InputEvent) -> void:
	if event.is_action_released("click"):
		match state:
			AIM:
				change_state(SET_POWER)
			SET_POWER:
				change_state(SHOOT)

func _process(delta: float) -> void:
	match state:
		AIM:
			animate_arrow(delta)
		SET_POWER:
			animate_power(delta)

func animate_arrow(delta):
	$Arrow.rotation.y += angle_speed * angle_change * delta
	if $Arrow.rotation.y > hole_dir + PI / 2:
		angle_change = -1
	if $Arrow.rotation.y < hole_dir - PI / 2:
		angle_change = 1

func animate_power(delta):
	power += power_speed * power_change * delta
	if power >= 100:
		power_change = -1
	if power <= 0:
		power_change = 1
	$UI.update_power_bar(power)

func _on_hole_body_entered(body: Node3D) -> void:
	if body.name == "Ball":
		print("win!")
		change_state(WIN)

func _on_ball_stopped() -> void:
	if state == SHOOT:
		change_state(AIM)

func set_start_angle():
	var hole_position = Vector2($Hole.position.z, $Hole.position.x)
	var ball_position = Vector2($Ball.position.z, $Ball.position.x)
	hole_dir = (ball_position - hole_position).angle()
	$Arrow.rotation.y = hole_dir
```

- 게임이 선형적이기 때문에 (상태에 따라서 진행) Enum을 통해 상태를 정의한다.
- @export: 인스펙터에서 수정할 수 있는 변수를 정의한다.
- 상태를 시작할 때 변경하고, 클릭, 골인, 낙하 등에 따른 상태 변경등이 있다. 메인 영역에서 벗어나는 경우에는 시그널로 연결하여 현재 스크립트에서 상태를 관리할 수 있도록 처리한다
- PI를 사용하여, 고도는 라디안을 사용하기에 /2를 하면 90도가 된다. 이를 통해 속도, 각도를 통해 애니메이션을 처리한다.

#### 공 스크립트

```gd
extends RigidBody3D

signal stopped

func shoot(angle, power):
	var force = Vector3.FORWARD.rotated(Vector3.UP, angle)
	apply_central_impulse(force * power)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.linear_velocity.length() < 0.1:
		stopped.emit()
		state.linear_velocity = Vector3.ZERO
	if position.y < -20:
		get_tree().reload_current_scene()
```

- 공에 충격을 가해서 움직이게 하기 때문에 `impulse`를 사용한다.
- 공이 무한정 움직이기 때문에 일정 속도 이하로 떨어지면 멈추게 한다. (여기서 시그널 발생)

#### 카메라 개선

현재의 카메라는 고정된 위치에서 보여주기 때문에 만약 맵이 넓어진다면, 문제가 생길 것이다. 따라서 이동 카메라를 만들어서 공을 따라다니게 한다. 너무 자유로운 카메라 이동은 오히려 불편할 수 있기 때문에 짐벌을 사용하여 카메라를 공을 중심으로 회전하게 한다.

짐벌이란 물체의 수평을 유지하도록 설계된 장치로 `Node3D` 노드 두개를 사용해 짐벌을 만들 수 있다. 노드를 상속 구조로 만들고 카메라를 가장 하위 자식으로 둔 뒤 카메라가 회전할 원의 반지름을 설정한다. (position.z 값)

```gd
extends Node3D

@export var cam_speed = PI / 2
@export var zoom_speed = 0.1

var zoom = 0.2

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_zoom_in"):
		zoom -= zoom_speed
	if event.is_action_pressed("cam_zoom_out"):
		zoom += zoom_speed

func _process(delta: float) -> void:
	zoom = clamp(zoom, 0.1, 2.0)
	scale = Vector3.ONE * zoom
	var y = Input.get_axis("cam_left", "cam_right")
	rotate_y(y * cam_speed * delta)
	var x = Input.get_axis("cam_up", "cam_down")
	$GimbalInner.rotate_x(x * cam_speed * delta)
	$GimbalInner.rotation.x = clamp($GimbalInner.rotation.x, -PI / 2, -0.2)
```

- 마우스 휠 입력으로 줌인/아웃을 처리한다. Update에서 clamp를 사용하여 최소, 최대값을 설정한다.
- 오른쪽/왼쪽 액션은 루트 Node3D 노드를 y축 둘레로 회전한다.
- 위/아래 액션은 Gimbal Inner를 z축 둘레로 회전한다. 이때, Gimbal Inner의 회전을 제한하기 위해 clamp를 사용한다.

이후로 업데이트문에서 생성한 카메라 인스턴스가 공을 따라다니도록 설정한다.

#### 전체 코스 디자인

앞서 씬 상속을 다룬 것 처럼 해당 씬을 확장해 다음 스테이지를 기획할 수 있다. `씬/새 상속 씬`

### 비주얼 이펙트

씬에서 설정한 공의 모습은 되게 밋밋하다. 여기에 머터리얼을 적용할 수 있는데, 해당 용어들에 대해서 정리한다.

- **텍스처**: 텍스처는 3D 오브젝트를 감싸는 평면 2D 이미지다. 평평한 종이가 패키지이 모양에 맞춰 접혀 있는 선물 포장을 상상해보자. 텍스처는 적용할 모양에 따라 단순할 수도 복잡할 수도 있다.
- **셰이더**: 텍스처가 오브젝트의 표면에 '무엇'이 그려지는지 결정한다면, 셰이더는 **어떻게 그려지는지를 결정한다.** 벽돌 패턴의 텍스처가 있다고 할 때, 벽이 젖어 있다면 메시와 텍스처는 동일하겠지만 빛이 반사되는 방식은 매우 달라질 것이다. 이것이 셰이더의 기능이다. 빛이 오브젝트와 상호작용하는 방식을 변경해 오브젝트의 겉모습을 바꾸는 것이다.
- **머터리얼**: 고도는 **물리 기반 랜더링(physucally based rendering, PBR)**이라는 그래픽 랜더링 모델을 사용한다. PBR의 목표는 실세계에서 빛이 작동하는 방식을 정확하게 모델링하는 방식으로 그래픽을 랜더링하는 것이다. 이런 효과는 메시의 머티리얼 속성을 이용함으로써 적용된다. **머티리얼이란 기본적으로 텍스처와 셰이더를 담는 그릇이다**. 머티리얼 속성에 따라 텍스처와 셰이더효과가 적용되고 방식이 결정된다.

#### 머티리얼 추가

- **Albedo**: 이 속성은 머티리얼의 기본 색상을 정한다. 이 값을 바꾸면 공을 어떤 색으로든 만들 수 있다. 텍스처가 필요한 오브젝트로 작업하는 경우, 그 텍스처를 추가하는 곳이기도 하다.
- **Metallic**과 **Roughness**: 이 파라미터는 표면에 빛을 반사하는 방식을 제어한다. 둘 다 0에서 1로 설정할 수 있으며 메탈릭은 광휘를 제어하고, 굵기는 반사에 일정량의 번짐을 표현한다.
- **Normal Map**: 노멀 맵이란 표면의 요철과 움푹 들어간 모습을 시뮬레이션하기 위한 3D 그래픽 기법이다. 메시 자체에서 이를 모델링하면 오브젝트를 구성하는 폴리곤, 즉 면의 수가 너무 많아지기 때문에 성능 저하를 야기한다. 대신 2D 텍스처를 사용해 표면 특색에서 발생하는 빛과 그림자의 패턴을 매핑한다.

### 조명과 환경

앞서 환경광을 위해 만든 `WorldEnvironment`노드를 사용해 조명과 환경을 설정할 수 있다. 인스펙터에서 해당 노드의 디테일한 설정이 가능한데, 특정 고급 상황에서만 사용하니 필요할 때 찾아서 사용하면 된다.

- **Background**와 **Sky**: 여기에서 3D 씬의 배경 모양을 구성 설정할 수 있다. 단색이거나 텍스처일 수도 있고, 스카이박스로 설정할 수도 있다.
- **Ambient Light**: 환경광의 색상과 강도를 설정한다. 이 값은 모든 방향에서 오는 광을 나타낸다.
- **Screen Space Reflection(SSR)**, **Screen Space Ambient Occlusion(SSAO)**, **Screen Space Indirect Lighting(SSIL)**, **Signed Distance Field Global Illumination(SDFGI)**: 이런 옵션은 조명과 그림 자가 처리되는 방식을 더욱 고급스럽게 제어할 수 있다.
- **Glow**: 이 조명 기능은 빛이 주변으로 번지는 필름 효과를 시뮬레이션해 오브젝트가 빛을 발하는 듯 보이게 한다. 이는 오브젝트가 실제로 빛을 발하는 머티리얼의 Emission과는 다르다.

### 정리

![CutSene gif](https://github.com/user-attachments/assets/a8906186-4c3b-4dc7-8cdf-70d3676f3f0d)

2D 작업을 하다 3D를 해봤을 때, 고도엔진의 통일성에 대해서 되게 좋은 인상을 받았다. 직관적이고 다른 에디터의 확장 기능을 이미 다 넣어두었고 사용법도 어렵지 않다.

엔진 자체에 대한 공부도 도움이 되었지만 저자의 게임 자체에 대한 설명이나 기법도 많이 배우게 된 것 같다.
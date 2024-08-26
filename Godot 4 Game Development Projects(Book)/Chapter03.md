## 스페이스 록: 물리 엔진으로 고전 2D 아케이드 만들기

이번 프로젝트의 핵심 주제는 다음과 같다.

- 커스텀 입력 액션 사용
- `RigidBody2D`를 사용한 물리 구현
- 유한 상태 기계로 게임 로직 체계화
- 동적이고 크기 조절이 가능한 UI 구축
- 사운드 및 음악
- 파티클 효과

### 프로젝트 설정

입력 맵에서 커스텀 입력 액션을 설정할 수 있다. 이 기능을 사용하면 커스텀 이벤트를 정의하고 다양한 키, 마우스 이벤트, 기타 입력을 할당할 수 있다. 이를 통해 입력 자체를 추상화할 수 있고 더 유연하게 디자인이 가능해진다. 또한, 다른 환경의 하드웨어에서도 문제없이 동작할 수 있다.

해당 키를 눌러서 입력 액션에 추가할 수 있다. 프로젝트 -> 프로젝트 설정 -> 입력 맵 -> 키 추가

#### 리지드 바디 물리학

게임 공간에서 두 오브젝트가 교차하거나 접촉하는 시점을 파악해야 하는 경우가 많다. 이를 **콜리전 감지**라고 한다. 일반적으로는 콜리전이 감지되었을 때 뭔가가 일어나기를 바란다. 이를 **콜리전 반응**이라고 한다.

고도는 3가지 종류의 물리 바디를 제공하며, 이는 `PhysicsBody2D` 노드 유형으로 그룹화되어 있다.

- `StaticBody2D`: 정적 바디는 물리 엔진에 의해서는 움직이지 않는 바디다. 콜리전 감지에 참여는 하지만 이에 반응해 움직이지는 않는다. 이 유형의 바디는 벽이나 지면 같이 환경의 일부이거나 동적 액션이 필요하지 않은 오브젝트에 주로 사용된다.
- `RigidBody2D`: 리지드 바디는 물리 시뮬레이션을 제공하는 물리 바디다. 이는 `RigidBody2D`물리 바디의 위치를 직접 제어하지 않는다는 뜻이다. 대신 힘을 가하면 고도에 내장된 물리 엔진이 충돌, 튕김, 회전, 기타 효과를 포함한 움직임을 계산한다.
- `CharacterBody2D`: 이 바디 유형은 콜리전 감지는 제공하지만 물리는 제공하지 않는다. 모든 움직임은 코드로 구현해야 하며, 콜리전 반응 역시 사용자가 직접 구현해야 한다. 이는 사실적인 시뮬레이션이 아닌 아케이드식 물리가 필요한 플레이어에게 사용한다.

각각의 물리 노드의 특성을 이해하고 필요에 맞게 사용하는 것이 중요하다. 프로젝트 설정에서도 월드에 맞는 물리 속성을 설정할 수 있다.

*기본 설정을 제공해주고 필요시 고급 설정을 조작할 수 있다는 점에서 매우 편리하다..? 다른 엔진은 모든 사항을 오픈해놔서 알아보기 힘들 때가 많다.*

### 플레이어 우주선

우주선 씬을 만들고 스프라이트, 콜리전을 부착한다.

고도는 기본적으로 텍스처 기본 설정이 Linear로 되어있는데, 이는 텍스처를 확대할 때 픽셀을 선형 보간하는 방식이다. 이는 텍스처가 블러되어 보일 수 있으므로, 텍스처 설정에서 `Filter`를 `Nearest`로 변경하면 픽셀을 보간하지 않고 텍스처를 확대한다. 즉, 픽셀게임 같은 느낌을 줄 수 있다.

앞 프로젝트와 다르게 조금 규모가 있는 프로젝트라면 각각 따로 폴더를 두는 방식이 더 적합할 수 있다. 현재 우주선 플레이어 씬이니 Player라는 폴더에 씬과 스크립트를 넣어두는 것이 좋다.

#### 상태 기계

플레이어의 우주선은 게임 플레이중 다양한 상태가 될 수 있다. 살아 있는 상태로 플레이어가 조종하여 바위에 부딪히면 피해를 입는 상태, 무적 상태 등등

이런 상황을 처리하는 방법중 가장 일반적인 방법이 **유한 상태 기계**이다. 이는 플레이어가 어떤 상태에 있는지 추적하고, 상태가 변경될 때마다 적절한 행동을 취할 수 있게 해준다. FSM

실제로 FSM을 구현하지 않고 일반적인 골격정도만 구현해본다.

```gd
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = INIT
```

- enum은 열거형으로 상수의 집합을 나타낸다.

```gd
func _ready() -> void:
	Change_state(ALIVE)

func Change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
	state = new_state
```

#### 플레이어 컨트롤 추가

```gd
@export var engine_power = 500
@export var spin_power = 8000

var thrust = Vector2.ZERO
var rotation_dir = 0
```

우주선의 가속과 회전, 방향등을 사전에 설정하고 `export`를 사용하여 인스펙터에서 값을 조정할 수 있게 한다.

실제 우주선의 느낌을 위해선 댐핑이 전혀 없어야하지만 고전 게임의 느낌을 위해 인스펙터에서 Damp값을 조절한다.

```gd
func _process(delta: float) -> void:
	get_input()
	
func get_input():
	thrust = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")
	
func _physics_process(delta: float) -> void:
	constant_force = thrust
	constant_torque = rotation_dir * spin_power
```

`get_input`함수는 키 입력을 받아 우주선의 추력을 끄거나 킨다. `Input.get_axis`는 2개의 입력을 기반으로 값을 반환한다. 따라서 시계방향, 반시계 방향, 0 중 하나가 된다.

마지막으로 물리 바디를 사용할 때는 항상 `_physics_process`를 사용해야 한다. `_process`는 프레임마다 호출되지만 `_physics_process`는 고도의 물리 엔진이 동작하는 주기에 맞춰 호출된다. *유니티에선 FixedUpdate와 Update의 차이와 같다.*

#### 화면 휘감기

2D 고전 아케이드 게임의 또 다른 기능이 화면 휘감기다. 플레이어가 화면 한쪽을 벗어나면 반대편에 나타나는 것을 말한다. 실제로는 우주선의 위치를 즉시 변경해 반대편으로 순간이동한다.

```gd
	screensize = get_viewport_rect().size
```

- 다음 코드로 화면의 크기를 얻을 수 있다.

**`RigidBody`를 사용할 때는 `Position`을 직접 설정할 수 없다.**

```gd
	if position.x > screensize.x:
		position.x = 0
	if position.x < 0:
		position.x = screensize.x
	if position.y > screensize.y:
		position.y = 0
	if position.y < 0:
		position.y = screensize.y
```

이런 코드를 작성하면 `RigidBody`로는 제대로 동작하지 않는다. 실제로 Position이나 속도를 매 프레임 변경해서는 안되고 `_integrate_forces`를 통해 접근해야 한다.

- 해당 함수를 통해 `PhysicsDirectBodyState`를 얻을 수 있는데 이 오브젝트가 고도에서 바디 상태에 대한 유용한 정보를 담고 있는 오브젝트이다.

변형(transform)은 공간에서 옮김(translation), 회전(rotation), 크기 조정(scale)등 하나 이상의 변환을 나타내는 행렬이다. 옮김 정보는 Transform2D의 origin속성에 접근하여 얻을 수 있다.

```gd
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var xform = state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	state.transform = xform
```

- `wrapf()` 함수는 값을 받아 사용자가 선택한 최소/최댓값 사이에서 '휘감기'한다. 그래서 0미만으로 떨어진 값은 `screensize.x`가 되고, 그 반대도 마찬가지다.

#### 사격

사격을 하기 위해 총알 씬을 만든다. 영역을 지정할 Area2D와 콜리전 모양을 지정할 CollisionShape2D, 스프라이트, 노드에 대한 시그널 처리를 위한 `VisibilityNotifier2D`를 추가한다.

```gd
extends Area2D

@export var speed = 1000

var velocity = Vector2.ZERO

func start(_transform):
	transform = _transform
	velocity = transform.x * speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += velocity * delta
```

`Start`함수를 호출하여 총알을 움직인다.

```gd
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
```

`VisibilityNotifier2D`시그널을 연결하여 화면에서 사라질 때 free될 수 있게 처리한다.

```gd
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("rocks"):
		body.explode()
		queue_free()
```

`Area2D`의 `body_entered`시그널을 연결하여 충돌체크를 한다.

##### 총알 발사

이제 고도의 구조대로 생각하면 메인에서 Player위치로 부터 Bullet씬의 인스턴스를 생성하여 총알을 발사할텐데, 총알이 플레이어의 자식으로 만들면 플레이어와 같이 회전하고 움직이기 때문에 이상해진다. 게임이 실행중일 땐 메인 씬이 플레이어의 부모가 되므로, `get_parent()`, `add_child()`를 사용하여 메인 씬에 추가할 수 있다.

하지만, 그렇게 하게 되면 더이상 player씬은 독립적으로 실행할 수 없게 되고 강제적인 종속성이 발생한다. **일반적으로, 코드 작성 시 고정된 트리 레이아웃을 가정하는 것은 좋지 않다.** 이를 잘 훈련하여 모듈화된 디자인을 해야한다.

어떠한 경우에도 씬트리는 항상 존재하므로 이 게임의 경우 총알을 게임의 최상위 노드, 씬트리에 있는 루트 노드의 자식으로 만들어도 좋다.

`Marker2D`노드를 플레이어에 추가하고 이를 총구로 잡는다.

```gd
func shoot():
	if state == INVULNERABLE
		return
	can_shoot = false
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)
```

### 바위 추가

이 게임의 핵심 재미인 바위를 제작한다.

- 바위도 `RigidBody2D`를 사용한다.
- 바위끼리 충돌한다.
- 총알에 의해 부셔진 바위는 더 작은 바위로 분해된다.

#### 씬 설정

똑같이 씬을 생성하고 이미지를 설정하지만, 동적으로 크기가 다르게 생성되어야 하기에 CollisionShape2D의 설정은 그대로 둔다.

추가로 튕김은 PhysicsMaterial을 사용하여 설정할 수 있다. Bounce 1

#### 다양한 크기의 바위

```gd
func start(_position, _veclocity, _size):
	position = _position
	size = _size
	mass = 1.5 * size
	$Sprite2D.scale = Vector2.ONE * scale_factor * size
	radius = int($Sprite2D.texture.get_size().x / 2 * $Sprite2D.scale.x)
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	linear_velocity = _veclocity
	angular_velocity = randf_range(-PI, PI);
```

앞서 다룬 내용처럼 동적으로 스프라이트 크기를 조절하고 반지름을 구하여 콜리전 모양을 조절한다. (객체 생성도 함) 

*드래그앤 드롭이 가능한 대부분의 것들은 new로 생성이 가능한듯 하다*

#### 바위 인스턴스화

바위를 랜덤으로 스폰하기 위해서 수학적 식을 사용해 둘레에 따라 생성할 수 있지만, 레벨조절을 명확하게 하기 위해 Path를 사용하여 생성될 위치를 조절할 수 있다.

path을 추가하며 점을 그려 생성될 위치를 잡는다.

```gd
func _ready() -> void:
	screensize = get_viewport().get_visible_rect().size
	for i in 3:
		spawn_rock(3)

func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
```

임시로 바위 3개를 3의 크기로 생성한다. `spawn_rock`함수는 바위가 부셔진 이후 작은 바위 생성을 위해 선택적 인수를 받도록 설정하였다.

#### 폭발하는 바위

사전에 정의한 `explode`함수는 다음과 같은 역할을 해야한다.

- 바위 제거
- 폭팔 애니메이션 재생
- Main에게 작은 새 바위를 생성하라고 알림

폭발은 별도의 씬으로 만든다. 그 이유는 이후에 Player에게도 추가할 수 있기 때문이다.

스프라이트 시트를 사용하여 애니메이션을 제작한다.

```gd

func explode():
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.show()
	exploded.emit(size, radius, position, linear_velocity)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()
```

폭발 함수를 작성만들어 이펙트를 월드에 고정하고 삭제까지 처리한다.

*이부분은 근데 Explosion자체에서 처리하는게 맞지 않을까?*

*분명 그룹을 설정했는데 그룹이 날아감, 한번 에러가 출력되면 그 이후에 그룹에서 빠지는 문제인듯*

##### 작은 바위 스폰

현재 바위에서 시그널을 생성했지만, 해당 시그널은 Main에서 수신하지 못한다. 노드 탭에서 시그널을 연결할 수 없는데 이유는 동적으로 생성되기 때문이다. 따라서 spawn_rock함수에서 시그널을 연결해야 한다.

```gd
func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	r.exploded.connect(self._on_rock_exploded) // 해당 메서드 등록 동적 바인딩

func _on_rock_exploded(size, radius, pos, vel):
	if size <= 1:
		return
	for offset in [-1, 1]:
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newval = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newval)
```

### UI 제작

고도는 다양한 기기에서 동일한 기능을 지원하기 위해 `Control`노드를 제공한다. 이 게임에선 다음과 같은 기능을 가진 UI를 만들어본다.

- 시작 버튼
- 상태 메시지
- 점수
- 목숨 카운터

#### 레이아웃

- 복잡하지만 책 내용대로 따라할 것

#### UI 스크립트

UI 스크립트에서 나온 처음에 컴포넌트를 참조하는 방법은 유니티에서 캐싱하여 사용하는 방법과 비슷하다.

```gd
@onready var lives_counter = $MarginContainer/HBoxContainer/LivesCounter.get_child_count()
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var message = $VBoxContainer/StartButton
@onready var start_button = $VBoxContainer/StartButton
```

`onready` 데코레이터는 `_ready()`함수 실행과 동시에 변수값을 설정한다.

```gd
func show_message(text):
	message.text = text
	message.show()
	$Timer.start()

func update_score(value):
	score_label.text = str(value)
	
func update_lives(value):
	for item in 3:
		lives_counter[item].visible = value > item
```

각 view에 해당하는 업데이트 함수를 만들어서 사용한다.

#### 메인 씬의 UI 코드

```gd
func new_game():
	get_tree().call_group("rocks", "queue_free")
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true
```

새로운 게임을 시작할 때 바위가 남아 있다면 파괴하고 게임을 리셋한다.

```gd
func new_level():
	level += 1
	$HUD.show_message("Wave %s" % level)
	for i in level:
		spawn_rock(3)
```

레벨이 변경될 때 마다 호출될 함수다.

```gd
func _process(delta: float) -> void:
	if not playing:
		return
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()
```

Update문에서 현재 바위개수를 체크하여 레벨을 변경한다.

#### 플레이어 코드

```gd
var reset_pos = false
var lives = 0: set = set_lives

func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		Change_state(DEAD)
	else:
		Change_state(INVULNERABLE)
```

`lives`변수에 **세터**라는 것을 추가하여 `lives`값이 변경될 때마다 `set_lives`함수가 호출된다는 뜻이다. 해당 함수에 시그널을 연결하면 자동으로 시그널을 발생시킬 수 있다.


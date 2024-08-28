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

```gd
func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	Change_state(ALIVE)
```

새로운 게임이 시작될 때 Main에서 호출할 player의 함수이다. 플레이어의 상태를 초기화하기에 위치도 초기화 시켜야 하기에 `_integrate_forces`에서 위치를 초기화한다.

```gd
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false
```

시그널을 생성하고 해당 함수랑 연결하는 법은 꼭 생성하고 네이밍을 맞출필요 없이 씬탭에서 해당 씬의 시그널을 연결해서 사용할 수 있다.

### 게임 종료

플레이어가 바위에 부딪히는 것을 감지하기 위해 `Explosion`씬의 인스턴스를 `Player`에 추가하고 `visible`을 `false`로 설정한다. 이후에 Timer을 추가하여 이를 제어할 타이머를 만든다.

```gd
func Change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			dead.emit()
	state = new_state
```

FSM을 다음과 같이 업데이트한다.

```gd
func _on_invulnerability_timer_timeout() -> void:
	Change_state(ALIVE)
```

`INVULNERABLE`에서 실행한 타이머가 끝나면 `ALIVE`로 상태를 변경한다.

#### 리지드 바디 사이의 콜리전 감지

현재 우주선이 바위애 튕기는 이유는 둘 다 리지드 바디이기 때문이다. 하지만 리지드 바디가 충돌할 때 뭔가 일어나게 하고 싶다면 **접촉 모니터링(contact monitoring)**을 사용해야 한다.

사용하고 싶은 노드(RigidBody2D)에 `contact_monitor`를 체크하고 `Max contacts report`를 1로 설정한다. 이렇게 설정하면 플레이어가 다른 바디와 접촉할 때 시그널을 발산할 것이다. 노드의 `body_entered`시그널을 연결하고 다음 코드를 작성한다.

```gd
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("rocks"):
		body.explode()
		lives -= 1
		explode() # Replace with function body.

func explode() -> void:
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()
```

### 게임 일시 정지

고도에서 일시 정지는 Scene Tree의 함수이며, paused 속성을 사용해 설정할 수 있다. 이를 통해 일시 정지하게 되면 다음과 같은 일이 발생한다.

- 물리 스레드 실행 중지
- `_process`와 `_physics_process`가 어떤 노드에서도 호출되지 않음
- `_input`과 `_input_event`메서드 역시 입력이 있어도 호출되지 않음

일시 정지 모드가 트리거되면 실행 중인 게임의 모든 노드가 설정한 방식에 따라 반응한다. 이 행동은 노드 인스펙터 목록 하단에서 볼 수 있는 Process/Mode 속성을 통해 설정한다.

- `Ingerit`: 해당 노드가 부모와 동일한 모드를 사용한다.
- `Pausable`: 씬 트리가 일시 정지되면 해당 노드도 일시 정지
- `When Paused`: 해당 노드는 트리가 일시 정지된 경우에만 실행
- `Always`: 해당 노드는 항상 실행되며, 트리의 일시 정지 상태는 무시
- `Disabled`: 해당 노드는 항상 실행되지 않으며, 트리의 일시 정지 상태는 무시

*일시정지도 이렇게 미리 생각해놓고 구현해놨다니.. 매우 편리하다.*

이에 따라 일시 정지를 구현하기 위해 입력 맵에서 일시정지 액션을 만들고 이에 대한 처리를 한다.

```gd
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
		else:
			message.text = ""
			message.hide()
```

이 코드는 키를 누르른 것을 감지해 트리의 상태가 현재 상태와 반대되는 상태로 전환되게 설정한다.

그런데 지금 게임을 실행하면 문제가 하나 더 있다. 모든 노드가 일시 정지되고 거기에는 `Main`도 포함되기 때문에 더이상 `_input`을 처리하지 않게되기에 Main노드의 Process/Mode를 `Always`로 설정해야 한다.

*추가로 Main에 할당된 Player도 `Inherit`이기 때문에 `Pausable`로 변경해야 한다. 현재는 총알이 멈춘 상태로 나가는 문제가 있다.*

### 적

#### 경로 따라가기

새 씬을 생성하고 `Node`를 추가한다. 이름은 `EnemyPaths`로 변경하고 경로를 그리기 위해 `Path2D`를 추가한다. 해당 Path에 여러 점을 추가하여 경로를 만든다. (경로 자체가 하나의 씬이자 객체, 인스턴스로 동작)

#### 적 씬

적을 위한 `Area2D`를 루트 노드로 사용한다. 이후 적에 맞는 애니메이션을 할당하고 `Explosion`씬을 인스턴스로 추가한다. 발사에 맞는 타이머도 추가하여 설정한다.

#### 적 이동

```gd
@export var bullet_scene : PackedScene
@export var speed = 150
@export var rotatio_speed = 120
@export var health = 3

var follow = PathFollow2D.new()
var target = null

func _ready() -> void:
	$Sprite2D.frame = randi() % 3
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	path.add_child(follow)
	follow.loop = false
```

시작 단계에서 스프라이트를 랜덤으로 선택하고 path도 랜덤으로 선택한다. 이후 해당 경로를 loop로 설정한다. 다음 단계는 경로 끝에 도달할 적을 제거하는 것이다.

```gd
func _physics_process(delta: float) -> void:
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.global_position
	if follow.progress_ratio >= 1:
		queue_free()
```

경로의 끝은 `progress`가 전체 경로 길이보다 클 때 감지할 수 있다. 하지만 `progress_ratio`를 사용하는 편이 더 직관적인데, 이 변수는 경로 길이에 따라 0에서 1까지 변하므로 경로의 길이를 일일이 알 필요가 없기 때문이다.

#### 적 스폰

`Main`씬에 제작한 Enemy씬을 인스턴스로 가질 수 있도록 만든다. 이후 해당 씬을 생성하는 로직을 `new_level`함수에 추가한다. 이후 Timer 함수를 연결하여 지속적으로 생성될 수 있도록 한다.

```gd
func _on_enemy_timer_timeout() -> void:
	var e = enemy_scene.instantiate()
	add_child(e)
	e.target = $Player
	$EnemyTimer.start(randf_range(20, 40))
```

#### 적 사격 및 충돌

적은 플레이어에게 총을 쏘고 플레이어의 총알에 맞았을 때 반응해야 한다. 이를 위해 새로 총알을 제작하거나 플레이어의 총알을 사용하여 제작할 수 있다.

복사하여 사용하는 경우에는 특히 루트 노드의 이름 변경, 스크립트 떼기, 연결된 시그널 제거, 그룹 제거 등을 해야한다.

```gd
extends Area2D

@export var speed = 1000

func start(_pos, _dir):
	position = _pos
	rotation = _dir.angle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * speed * delta

func _on_body_entered(body: Node2D) -> void:
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
```

이렇게 기본적인 총알을 제작하고 플레이어를 향해 발사하도록 설정한다. `enemy_bullet`씬을 저장하고 `Enemy`씬에 설정해둔 속성인 Bullet Scene에 연결한다.

```gd
func shoot():
	var dir = global_position.direction_to(target.global_position)
	dir = dir.rotated(randf_range(-bullet_spread, bullet_spread))
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(global_position, dir)
```

플레이어 위치를 찾은 후 랜덤성을 주고 총알을 발사한다. `GunCooldown` 시간이 초과될 때마다 `shoot`함수를 호출한다.

```gd
func take_damage(amount):
	health -= amount
	$AnimationPlayer.play("flash")
	if health <= 0:
		explode()

func explode():
	speed = 0
	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()
```

또한 적의 `body_entered`시그널을 연결해서 적이 플레이어와 부딪히면 폭발하게 한다.

```gd
func _on_enemy_timer_timeout() -> void:
	var e = enemy_scene.instantiate()
	add_child(e)
	e.target = $Player
	$EnemyTimer.start(randf_range(20, 40))
```

추가로 총알은 현재 `Node`의 Enter만 감지하고 있기에 `Area2D`로 추가해야 한다.

### 플레이어 보호막

```gd
func set_shield(value):
	value = min(value, max_shield)
	shield = value
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		lives -= 1
		explode()
```

실드값이 변경될 때 마다 호출될 (세터로 연결) 함수로 최대값을 제한하고 HUD로 보낼 시그널에 맞게 메시지지를 보낸다. 이후 실드가 다 달면 생명을 줄인다.

```gd
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("rocks"):
		shield -= body.size * 25
		body.explode()
```

실드에 맞게 바위 크기에 따라 데미지를 주고 바위를 폭발시킨다. 나머지 젓 총알 코드도 마찬가지로 수정한다.

실드 UI를 HUD에 추가하기 위해 다음과 같은 코드를 추가한다.

```gd
var bar_textures = {
	"green": preload("res://assets/bar_green_200.png"),
	"yellow": preload("res://assets/bar_yellow_200.png"),
	"red": preload("res://assets/bar_red_200.png")
}

func update_shield(value):
	shield_bar.texture_progress = bar_textures["green"]
	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
	elif value < 0.7:
		shield_bar.texture_progress = bar_textures["yellow"]
	shield_bar.value = value
```

*preload은 유니티의 Resources.Load와 비슷한 역할을 한다.*

### 사운드 및 비주얼 이펙트

게임에서 중요한 GameExperience를 높이기 위해 사운드와 비주얼 이펙트를 추가한다.

#### 사운드와 음악

Sound를 재생하기 위해선 `AudioStreamPlayer`노드에서 로드해야 한다. 이 노드 2개를 `Player`씬에 추가하고 이름을 `LaserSound`와 `EngieSound`로 변경한다. 각 노드의 이름에 맞는 Stream속성을 추가한다.

```gd
$LaserSound.play()
```

#### 파티클

`CPUParticles2D`노드를 추구하고 이를 통해 파티클을 추가할 수 있다.

- 책 내용을 따라하자
- 개인적으론 유니티보다 더 간단하고 뎌 효과적인 것 같다. (인디게임 한정..?)

### 요약

이번 장에서는 `RigidBody2D`노드의 사용법과 고도에서 물리를 처리하는 기본적인 방법, 컨테이너를 활용한 UI, 사운드와 이펙트 등을 알아본 프로젝트였다.
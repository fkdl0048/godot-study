## 정글 점프: 2D 플랫포머의 달리기와 점프

이 장에선 **플랫포머** 게임을 만들 예정이다. 다뤄볼 주제는 다음과 같다.

- `CharacterBody2D`노드의 사용
- `Camera2D`노드의 사용
- 애니메이션과 사용자 입력을 조합해 복잡한 캐릭터 동작 만들기
- `TileMap`을 사용하는 레벨 디자인
- `ParallaxLayer`를 사용해 무한 스크롤 배경 만들기
- 씬 간 전환
- 프로젝트를 체계화하고 확장 계획하기

### 프로젝트 설정

이 프로젝트는 기본적으로 픽셀 양식의 아트 스타일을 사용하기 때문에 스프라이트를 통한 사전에 설정을 해두는 것이 좋다.

- 텍스처 필터를 `Linear`에서 `Nearest`로 텍스처 필터링을 변경한다.
- 스트레치/모드를 `canvas_items`으로, 양상을 `expand`로 설정한다.  (이미지의 품질을 유지하면서 창의 크기 조절 가능)

다음은 콜리전 레이어 설정으로 복잡한 콜리전 상호작용이 필요할 때, 시스템을 사용하여 미리 체계화를 해두는 것이 좋다.

- `Layer Names/2D 물리`에서 사용할 콜리전 레이어를 설정한다.

또한 앞서 사용한 입력 맵 영역에 대한 컨트롤러도 추가한다.

### 키네마틱 바디 소개

플랫포머에는 중력, 콜리전, 점프 등의 물리 동작이 필요하므로 캐릭터 움직임을 구현하는 데에는 `RigidBody2D`가 적합할 수 있겠다는 생각을 할 수 있지만 실제 제작하다 보면 적합하지 않다는 것을 깨닫게 된다. 이 이유는 플레이어에게는 **사실성보다 반응적 컨트롤러와 액션감이 중요하기 때문**이다. 따라서 개발자로서는 캐릭터의 움직임과 콜리전 반응을 정밀하게 제어할 수 있어야 한다. 일반적으로 키네마틱방식의 물리가 플랫폼 캐릭터에게 더 적합한 선택이다.

`CharacterBody2D`노드는 코드를 통해 직접 제어해야 하는 물리 바디를 구현하기 위해 설계되었다. 이 노드는 움직일 때 다른 바디와 콜리전을 감지하지만 중력이나 마찰 같은 전역 물리 속성의 영향을 받지 않는다. 그렇다고 중력을 비롯한 힘의 영향을 받지도 않는다는 뜻은 아니다. 해당 힘과 그 효과를 코드에서 계산해야 물리 엔진이 `CharacterBody2D`노드를 자동으로 움직이지 않는다는 뜻이다.

`CharacterBody2D`는 `RigidBody2D`와 마찬가지로 직접 `Position`값을 수정하면 안되기에 바디가 제공하는 `move_and_slide()`나 `move_and_collide()` 메서드를 사용해야 한다. 이 메서드는 주어진 벡터를 따라 바디를 이동시키다가 다른 바디와 콜리전이 감지되면 즉시 멈춘다. 그 뒤에 어떤 콜리전 반응이 일어날지에 대한 결정은 사용자의 몫이다.

#### 콜리전 반응

콜리전 반응을 처리할 때, 바디가 튕기거나 벽을 따라 미끄러지거나 부딪힌 오브젝트의 속성을 변경하고 싶을 수 있다. 콜리전 반응을 처리하는 방식은 바디를 이동하는 데 사용하는 메서드에 따라 달라진다.

##### move_and_collide()

이 메서드를 사용하면, 함수가 콜리전할 때 `KinematicCollision2D`객체를 반환한다. 이 객체는 콜리전 및 충돌하는 바디에 대한 정보가 담겨 있고 이 정보를 통해 응답을 결정할 수 있다. 콜리전 없이 이동이 성공적으로 완료되면 `null`을 반환한다.

따라서 바디가 충돌하는 오브젝트를 튕겨나게 하려면 이 메서드를 사용해 받아온 정보를 이용해 바디의 속도를 조정하면 된다.

##### move_and_slide()

슬라이딩은 콜리전 반응에서 매우 흔한 옵션으로 물론 `move_and_collide()`를 사용해 직접 구현할 수도 있지만, `move_and_slide()`를 사용하면 이동과 슬라이딩을 한 번에 처리할 수 있다. 이 메서드는 바디가 충돌하는 오브젝트 표면을 따라 자동으로 미끄러진다. 또한 슬라이딩 콜리전을 사용하면 `is_on_floor()` 같은 메서드를 사용해 표면의 방향을 감지할 수 있다.

이 프로젝트에서는 플레이어 캐릭터가 지면과 위/아래 경사면을 따라 달릴 수 있어야 하므로 `move_and_slide()`가 플레이어의 움직임에 큰 역할을 하게 된다.

### 플레이어 씬 만들기

- `CharacterBody2D`노드를 추가하고 씬 이름을 `Player`로 변경한다. 또한 `선택한 노드 그룹화` 버튼을 꼭꼭꼭 누르기!

`CharacterBody2D`노드의 인스펙터 속성을 살펴보면 `Motion Mode`같은 경우는 `Grounded`, `Floating`두 가지가 있고 `Grounded`모드는 한쪽 콜리전 방향을 바닥, 반대를 천장, 그 밖을 벽으로 간주한다. 이중 어느 것이 어느 쪽인지를 결정하는 것이 `Up Direction`이다.

#### 콜리전 레이어와 마스크

바디의 `Collision/Layer` 속성은 물리 월드에서 바디가 어떤 레이어에 기반하는지를 설정한다. `Collision/Mask` 속성은 바디가 '볼 수 있는', 상호작용할 수 있는 레이어를 할당한다.

#### AnimationPlayer에 대해

앞서 `AnimatedSprite2D`를 사용해 프레임 기반 애니메이션을 다뤘다. 해당 노드는 시각적 텍스처를 애니메이션하는데 유용하다. 노드의 다른 속성에도 애니메이션을 적용하고 싶다면 `AnimationPlayer`를 사용하면 된다. 이 노드는 한 번에 여러 노드에 영향을 줄 수 있는 애니메이션을 만들 수 있는 툴로, 그 노드들의 모든 속성을 수정할 수 있다.

#### 애니메이션

- 예제와 같이 애니메이션 5종을 제작 (*유니티 애니메이션과 동일함*)

#### 콜리전 모양

다른 바디와 마찬가지로 `CharacterBody2D`에도 콜리전의 경계를 정의하기 위해 할당된 모양이 필요하다. `CollisionShape`노드의 `RectangleShape2D`를 사용해 콜리전 모양을 정의한다.

#### 플레이어 씬 마무리

`Player`씬에 `Camera2D`노드를 추가한다. 이 노드는 플레이어가 레벨을 이용할 때 게임 창을 플레이어 중심으로 유지하기 위함이다.

#### 플레이어 상태

플레이어 캐릭터는 점프, 달리기, 웅크리기 등 다양한 동작을 할 수 있다. 이런 동작을 코딩하기는 매우 복잡하고 관리하기 어려울 수 있다. 한 가지 해결책은 불 변수를 사용하는 것이지만, 상태 자체가 많아질수록 혼동되기 쉽고 이는 스파게티 코드로 이어진다.

따라서 이런 문제는 뒤에서 다룬 상태기계로 처리하는 것이 중요하다.

#### 플레이어 스크립트

플레이어에 스크립트를 부착하면 기본적으로 템플릿 속성이 주어진다. 이는 고도에서 지원하는 기본 움직임을 의미하지만, 현재 프로젝트에는 사용하지 않는다.

```gd
extends CharacterBody2D

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300

enum {IDLE, RUN, JUMP, HURT, DEAD}
var state = IDLE

func _ready() -> void:
	change_state(IDLE)

func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			$AnimationPlayer.play("idle")
		RUN:
			$AnimationPlayer.play("run")
		HURT:
			$AnimationPlayer.play("hurt")
		JUMP:
			$AnimationPlayer.play("jump_up")
		DEAD:
			hide()
```

#### 플레이어 이동

```gd
func get_input():
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")
	
	# 모든 상태에서 일어나는 이동
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite2D.flip_h = false
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
	
	# 땅에 있을 때만 점프 가능
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	# IDLE에서 움직이면 RUN으로 변환
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	# RUN에서 가만히 있으면 IDLE로 변환
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	# 공중에 떠 있으면 점프로 변환
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)
```

여기서 점프 검사가 `is_action_pressed()`가 아닌 `is_action_just_pressed()`로 되어 있는 이유 전자는 키를 누르고 있는 동안에 계속 `true`를 반환하지만, 후자는 키를 누른 직후 프레임에서만 `true`를 반환한다. 즉, 플레이어는 점프하고 싶을 때는 매번 새로 점프키를 눌러야 한다.

```gd
func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	get_input()
	
	move_and_slide()
```

앞서 말한대로 이동에 관련된 함수이기 때문에 `_physics_process()`에서 호출해야 한다. 또한 `Up Direction`속성이 (0, -1)로 설정되어 있기 때문에 중력이 아래로 작용하도록 설정해야 한다. 또한 바닥이 현재 발 밑으로 설정된다.

#### 플레이어 체력

결국은 플레이어가 위험과 맞서야 하므로, 피해 시스템을 추가해야 한다. 플레이어는 하트 3개로 시작해 피해를 입을 때마다 하트를 잃어버릴 것이다.

```gd
func set_life(value):
	life = value
	life_changed.emit(life)
	if life <= 0:
		change_state(DEAD)
```

### 수집용 아이템

레벨을 만들기 전에 플레이어가 수집할 아이템을 만든다. 이번엔 아이템 마다 다른 씬을 만들지 않고 단일씬의 속성을 교체하여 제작한다.

#### 씬 설정

아이템은 `Area2D`와 같이 영역 노드가 잘 맞는다. 오브젝트에 접촉할 때를 감지하고 싶지만, 오브젝트의 콜리전 반응은 필요하지 않기 때문이다.

- 애니메이션의 업데이트 모드를 잘 생각하여 연속적인 경우와 비연속적인 시트를 사용할 것인지 결정한다.

#### 수집용 아이템 스크립트

- 시그널을 통한 연결 코드를 작성한다.

### 레벨 디자인

#### 타일맵 사용

- 현재 버전으론 책과 다르게 타일맵이 아닌 타일레이어를 사용해야 한다고 한다. 과거 버전은 사용을 권장하지 않지만 써본 결과 유니티 타일맵과 유사한 구조를 가지고 있다.

#### 첫 번째 레벨 디자인

씬도 상속이 가능하다. 이는 씬을 객체로 바라볼 수 있는 고도의 특징과 잘 엮어서 사용하면 객체이자 프리팹으로 동적으로 활용할 수 있다는 것을 의미한다.

#### 배경 스크롤

배경 스크롤 자체를 따로 타일링해서 구현할 필요 없이 고도는 이미 `ParallaxLayer`노드를 제공한다.

### 적 추가

#### 씬 설정

`AnimationPlayer`를 사용하여 동적으로 `texture`를 변경할 수 있기에 한 시트에 모든 애니메이션이 없어도 더 자유롭게 활용이 가능하다.

#### 적 스크립트

```gd
		if collision.get_normal().x != 0:
			facing = sign(collision.get_normal().x)
			velocity.y = -100
```

`Player`와 마찬가지로 `CharacterBody2D`노드로 구현하며 는 `move_and_slide()`를 사용해 이동함을 의미한다. 이후 이를 통해 앞의 벽, 위의 플레이어 등을 탐지한다. 여기선 앞의 장애물이 있을 때 법선 벡터의 성분을 이용해 방향을 바꾸는 코드를 작성했다.

#### 적에게 피해 주기

마찬가지로 플레이어도 Collider의 성분으로 그룹(enemies)을 판단하여 대미지를 준다.

```gd
		if collision.get_collider().is_in_group("enemies"):
			if position.y < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
```

#### 플레이어 스크립트

```gd
extends CharacterBody2D

signal life_changed
signal died

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300

enum {IDLE, RUN, JUMP, HURT, DEAD}
var state = IDLE
var life = 3: set = set_life

func _ready() -> void:
	change_state(IDLE)

func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			$AnimationPlayer.play("idle")
		RUN:
			$AnimationPlayer.play("run")
		HURT:
			$AnimationPlayer.play("hurt")
			velocity.y = -200
			velocity.x = -100 * sign(velocity.x)
			life -= 1
			await get_tree().create_timer(0.5).timeout
			change_state(IDLE)
		JUMP:
			$AnimationPlayer.play("jump_up")
		DEAD:
			died.emit()
			hide()

func get_input():	
	if state == HURT:
		return
	
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")

	# 모든 상태에서 일어나는 이동
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite2D.flip_h = false
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
	
	# 땅에 있을 때만 점프 가능
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	# IDLE에서 움직이면 RUN으로 변환
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	# RUN에서 가만히 있으면 IDLE로 변환
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	# 공중에 떠 있으면 점프로 변환
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	get_input()
	move_and_slide()
	if state == HURT:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("danger"):
			hurt()
		if collision.get_collider().is_in_group("enemies"):
			if position.y < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
			else:
				hurt()
	if state == JUMP and is_on_floor():
		change_state(IDLE)
	if state == JUMP and velocity.y > 0:
		$AnimationPlayer.play("jump_down")

func reset(_position):
	position = _position
	show()
	change_state(IDLE)
	life = 3

func set_life(value):
	life = value
	life_changed.emit(life)
	if life <= 0:
		change_state(DEAD)

func hurt():
	if state != HURT:
		change_state(HURT)
```

### 게임 UI

#### 씬 설정

마찬가지로 HUD를 작성하는데, 작성의 팁은 모듈로서 동작해야 하기에 HUD는 데이터가 아닌 View로서 동작해야 한다. 즉, UI Update관련 코드만 작성해야 한다.

```gd
extends MarginContainer

@onready var life_counter = $HBoxContainer/LifeCounter.get_children()

func update_life(value):
	for heart in life_counter.size():
		life_counter[heart].visible = value > heart
		
func update_score(value):
	$HBoxContainer/Score.text = str(value)
```

#### HUD 붙이기

책에서 나오는 노드 탭이나 씬 트리를 통해 붙이는 방법이 혼동이 되어 사용하기 어렵다면 스크립트에서도 동일한 설정을 할 수 있다.

```gd
$Player.life_changed.connect($CanvasLayer/HUD.update_life)
score_changed.connect($CanvasLayer/HUD.update_score)
```

*역시 있다...*

### 타이틀 화면

#### 씬 설정

타이틀 UI는 게임에서 동 떨어져 있기에 따로 스크립트를 넣지 않아도 되고 그냥 애니메이션으로 동작시켜도 문제없다.

### 메인 씬 설정

레벨 씬이 여러개라고 할 때 씬이 변경되어도 데이터를 알아야 할 때, Main씬이 이를 맡아서 처리할 것이다. 하지만 그전에 현재 레벨을 추적하는 방법이 필요하다. 씬 안에 있는 여러 변수로는 추적할 수 없는데, 레벨 씬이 종료되면 새로 로드된 레벨로 대체되기 때문이다. 이를 위해 **자동 로드**를 사용하는 방법이다 있다.

- 자동 로드
  - 고도에서 스크립트나 씬을 자동 로드로 구성 설정할 수 있다. 이는 엔진이 항상 자동으로 로드한다는 뜻으로 `ScreenTree`에서 현재 씬을 변경하더라도 자동 로드된 노드는 그대로 유지된다. 또한, 그렇게 자동 로드된 씬은 게임의 다른 노드에서 이름으로 참조할 수 있다.

쉽게 말해서 씬은 `Don't Destroy On Load`와 같은 기능이고, 스크립트는 싱글톤과 같은 기능이라고 생각하면 될 것 같다.

- 프로젝트 설정/애플리케이션/실행 (현재는 Global로 변경된 듯함)

### 레벨 간 전환

#### Door씬

```gd
func _on_door_entered(body):
    GameState.next_level()
```

#### 마무리 작업

### 요약

이 장에서는 `CharacterBody2D` 노드의 사용법을 알아봤고, 타일맵, 그외에 고도엔진의 여러 기술?들에 대해서 알아봤다.
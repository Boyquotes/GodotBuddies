#player.gd
extends RigidBody

onready var body = get_node("Armature");
onready var animation = get_node("AnimationPlayer");

#game Modifier
var max_speed = 5.0;
var accel = 2.0;
var deaccel = 6.0;
var jump_velocity = 12;
var moving = false;
var jumping = false;
var on_floor = false;

var linear_velocity = Vector3();
var transform_pos = Vector3();

var body_rotation = [0.0, 0.0];

func _ready():
	set_fixed_process(true);
	
func _integrate_forces(state):
	PlayerMovement(state);
	
func _fixed_process(delta):
	animationChanger();

func PlayerMovement(state):
	var lv = state.get_linear_velocity();
	var g = state.get_total_gravity();
	var delta = state.get_step();
	
	lv += g*delta # Apply gravity
	
	var up = -g.normalized() # (up is against gravity)
	var vv = up.dot(lv) # Vertical velocity
	var hv = lv - up*vv # Horizontal velocity
	
	var hdir = hv.normalized() # Horizontal direction
	var hspeed = hv.length() # Horizontal speed
	
	var floor_velocity;
	var onfloor = false;
	var dir = Vector3();
	
	var speed = max_speed;
	
	if (state.get_contact_count() > 0):
		for i in range(state.get_contact_count()):
			if (state.get_contact_local_shape(i) != 1):
				continue
			
			onfloor = true
			break

	var dir = Vector3() # Menentukan arah player sesuai tombol
	var cam_xform = get_node("cam_free/cam").get_global_transform()
	
	if (Input.is_action_pressed("forward")):
		dir += -cam_xform.basis[2]
	if (Input.is_action_pressed("backward")):
		dir += cam_xform.basis[2]
	if (Input.is_action_pressed("left")):
		dir += -cam_xform.basis[0]
	if (Input.is_action_pressed("right")):
		dir += cam_xform.basis[0]
		
	var jump_attempt = Input.is_action_pressed("jump")
	#var shoot_attempt = Input.is_action_pressed("shoot")

	var target_dir = (dir - up*dir.dot(up)).normalized();
	moving = false;
	
	if (onfloor):
		if (dir.length() > 0.1):
			hdir = target_dir;
			
			if (hspeed < speed):
				hspeed = min(hspeed+(accel*delta), speed);
			else:
				hspeed = speed;
			
			moving = true;
			
		else:
			hspeed -= deaccel*delta;
			if (hspeed < 0):
				hspeed = 0;
		
		hv = hdir*hspeed;
		
		if (not jumping and jump_attempt):
			vv = jump_velocity;
			
			jumping = true;
	else:
		var hs;
		if (dir.length() > 0.1):
			hv += target_dir*(accel*0.2)*delta;
			if (hv.length() > speed):
				hv = hv.normalized()*speed;
	
	if (jumping and vv < 0):
		jumping = false;
	
	lv = hv + up*vv;
	on_floor = onfloor;
	
	state.set_linear_velocity(lv);
	linear_velocity = lv;
	transform_pos = state.get_transform().origin;
	
	#Player menghadap ke arah sesuai input
	if (dir.length() > 0.0): #Jika direction lebih dari 0.0 float
		body_rotation[1] = -atan2(dir.x, dir.z); #fungsi sudut tengok
	#update transformasi sesuai fungsi sudut tengok
	var trans = body.get_transform();
	trans.basis = Matrix3(Quat(trans.basis).slerp(Quat(Vector3(0,1,0), body_rotation[1]), 5*delta));
	body.set_transform(trans);
		
func animationChanger():
	var hv_len = linear_velocity;
	hv_len.y = 0;
	hv_len = hv_len.length();
	print("linear velocity : ",hv_len);
	
	if (hv_len > 1):
		set_animation("run");
		return;
		
	set_animation("idle");
		
func set_animation(ani,speed = 1.0):
	if (animation.get_current_animation() != ani):
		animation.play(ani);
		print("playing animation :",ani);
	if (animation.get_speed() != speed):
		animation.set_speed(speed);
	
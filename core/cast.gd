class_name Cast
## Builds characters from a design name: Cast.make("nadia"), Cast.make("zombie_a", "zombie").


static func make(design: String, kind := "actor") -> Actor:
	var a: Actor
	match kind:
		"zombie":
			a = Zombie.new()
		"companion":
			a = Companion.new()
		_:
			a = Actor.new()
	a.name = design.capitalize().replace(" ", "")
	a.collision_layer = 0
	a.set_collision_layer_value(2, true)
	a.collision_mask = 0
	a.set_collision_mask_value(1, true)
	var d: CharacterDesign = load("res://characters/designs/%s.tres" % design)
	var h := d.leg_len() + d.torso_len + d.head_radius * 2.0
	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 28.0
	cap.height = h * 0.9
	cs.shape = cap
	cs.position = Vector2(0, -h * 0.45)
	a.add_child(cs)
	var rig := CharacterRig.new()
	rig.name = "Rig"
	rig.design = d
	a.add_child(rig)
	return a

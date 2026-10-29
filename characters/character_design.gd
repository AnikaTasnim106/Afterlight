@tool
class_name CharacterDesign
extends Resource
## Everything that makes one character look different from another.
## Proportions are in pixels at scale 1 (1080p reference). Edit the .tres
## files in characters/designs/ — CharacterRig redraws live in the editor.

@export var display_name := "Character"

@export_group("Proportions")
@export var head_radius := 50.0
@export var neck_len := 10.0
@export var torso_len := 118.0
@export var shoulder_half := 44.0
@export var hip_half := 36.0
@export var thigh := 104.0
@export var shin := 98.0
@export var upper_arm := 80.0
@export var forearm := 74.0
@export var hand_radius := 12.0
@export var arm_radius := 12.5
@export var leg_radius := 16.0
@export var shoe_len := 44.0
@export var shoe_h := 18.0
## How far the top garment hangs below the hip joint.
@export var hem_drop := 20.0
@export var hem_flare := 4.0

@export_group("Colours")
@export var skin := Color("d8a07c")
@export var skin_shade := Color("b9805f")
@export var hair := Color("231d22")
@export var top := Color("2f3a4a")
@export var top_shade := Color("232c39")
@export var top_accent := Color("e3a03c")
@export var inner := Color("6b7f86")
@export var sleeve := Color("2f3a4a")
@export var pants := Color("262c38")
@export var shoes := Color("4a3428")
@export var shoe_accent := Color("d9d2c5")
@export var eye := Color("1c1a22")
@export var mouth := Color("5a2a2a")
@export var brow := Color("231d22")

@export_group("Style")
@export_enum("messy", "bob_ponytail", "tied_back", "helmet", "neat") var hair_style := 0
@export_enum("jacket", "hoodie", "suit", "uniform", "kameez") var top_style := 0
@export var brow_width := 1.0
@export var eye_scale := 1.0
@export var blush := false
@export var freckles := false
@export var stubble := false
@export var glasses := false
@export var glasses_color := Color("1d1a20")
@export var lipstick := false
@export var mustache := false
@export var blank_eyes := false
@export var torn := false
@export var bandaged_leg := false
## Extra forward lean (elderly / hunched)
@export var posture := 0.0

@export_group("Accessories")
@export var holster := false
@export var headphones := false
@export var accessory_color := Color("2bb3a7")
@export var scarf := false
@export var scarf_color := Color("b8453a")

@export_group("Motion")
## Multiplies stride and bounce. Younger / lighter characters bounce more.
@export var bounce := 1.0
@export var walk_speed := 230.0
@export var run_speed := 470.0


func leg_len() -> float:
	return thigh + shin

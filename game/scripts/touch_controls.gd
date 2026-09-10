extends Control

var world: Node3D
var move_finger := -1
var look_finger := -1
var held_buttons: Dictionary = {}
var move_origin := Vector2.ZERO
var stick := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(clear)

func radius() -> float:
	return clampf(minf(size.x,size.y)*.12,48,86)

func joystick_center() -> Vector2:
	var r:=radius()
	return Vector2(r*1.7,size.y-r*1.65)

func buttons() -> Dictionary:
	var r:=radius()*.62
	return {"HIT":Vector2(size.x-r*1.55,size.y-r*1.8),"GUARD":Vector2(size.x-r*3.9,size.y-r*1.8),"USE":Vector2(size.x-r*1.55,size.y-r*4.15),"RESET":Vector2(size.x-r*1.55,r*1.6)}

func _draw() -> void:
	var r:=radius()
	var origin:=move_origin if move_finger>=0 else joystick_center()
	draw_circle(origin,r,Color(.03,.045,.06,.32))
	draw_arc(origin,r,0,TAU,48,Color(.88,.8,.65,.55),2,true)
	draw_circle(origin+stick*r,r*.36,Color(.88,.8,.65,.55))
	var font:=ThemeDB.fallback_font
	var font_size:=int(clampf(r*.28,15,23))
	for label in buttons():
		var center:Vector2=buttons()[label]
		draw_circle(center,r*.62,Color(.035,.045,.055,.58))
		draw_arc(center,r*.62,0,TAU,32,Color(.88,.8,.65,.65),2,true)
		var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,center+Vector2(-width/2,font_size*.35),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(.96,.9,.78))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index==move_finger:move_finger=-1;stick=Vector2.ZERO;world.player.touch_axes=Vector2.ZERO
			if event.index==look_finger:look_finger=-1
			if held_buttons.get(event.index)=="GUARD":world.guarding=false
			held_buttons.erase(event.index)
		else:
			for label in buttons():
				if event.position.distance_to(buttons()[label])<=radius()*.76:
					held_buttons[event.index]=label
					match label:
						"HIT":world.start_punch()
						"GUARD":world.guarding=world.health>0
						"USE":world.interact()
						"RESET":world.reset_scene()
					queue_redraw();return
			if event.position.x<size.x*.45 and event.position.y>size.y*.45 and move_finger<0:
				move_finger=event.index;move_origin=event.position
			elif look_finger<0:look_finger=event.index
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index==move_finger:
			stick=((event.position-move_origin)/radius()).limit_length()
			world.player.touch_axes=stick
			queue_redraw()
		elif event.index==look_finger:
			world.player.look(event.relative*900./maxf(size.y,1))

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(world):
		clear()

func clear() -> void:
	move_finger=-1;look_finger=-1;held_buttons.clear();stick=Vector2.ZERO
	world.player.touch_axes=Vector2.ZERO;world.guarding=false
	queue_redraw()

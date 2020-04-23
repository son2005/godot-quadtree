extends Node2D

var _quad_tree = null
var _screen_rect = null

var _test_rect: Rect2 = Rect2()

var _test_circle_center = Vector2()
var _test_circle_radius = 0

var _points = []
var _points_match = []

export var _total_point = 5000
export var _mouse_motion_test_flag = false
export var _circle_radius = 50
export var _rect_w = 250
export var _rect_h = 250
func _ready():
	randomize()
	
	_screen_rect = get_viewport_rect()
	_screen_rect.position.x += 1
	_screen_rect.size.x -= 1
	_screen_rect.size.y -= 1
	_quad_tree = QuadTree.new(_screen_rect, 4)
	
	for i in range(_total_point):
		var p = Vector2(randi() % int(_screen_rect.size.x), randi() % int(_screen_rect.size.y))
		_points.append(p)
		_quad_tree.insert(p)

func _unhandled_input(event):
#	if _mouse_motion_test_flag and event is InputEventMouseMotion:
#		_test_circle_center = get_global_mouse_position()
#		_test_circle_radius = _circle_radius
#		update()
	if _mouse_motion_test_flag and event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.is_pressed():
			var pos = get_global_mouse_position()
			
			# for circle
			_test_circle_center = pos
			_test_circle_radius = _circle_radius
			
			# for rect
			_test_rect = Rect2(pos.x - _rect_w / 2, pos.y - _rect_h / 2, _rect_w, _rect_h)
			update()

# https://godotengine.org/qa/3843/is-it-possible-to-draw-a-circular-arc
func draw_circle_arc( center, radius, angleFrom, angleTo, color ):
	var nbPoints = 64
	var pointsArc = []
	
	for i in range(nbPoints+1):
		var anglePoint = angleFrom + i*(angleTo-angleFrom)/nbPoints - 90
		var point = center + Vector2( cos(deg2rad(anglePoint)), sin(deg2rad(anglePoint)) )* radius
		pointsArc.push_back( point )
	
	for indexPoint in range(nbPoints):
#		printt(indexPoint, pointsArc[indexPoint], pointsArc[indexPoint+1])
		draw_line(pointsArc[indexPoint], pointsArc[indexPoint+1], color)


func test_query_circle_mouse():
	prints("=================================================================")
	draw_circle_arc(_test_circle_center, _test_circle_radius, 0, 360, Color.green)
	
	var time = OS.get_ticks_usec()
	_points_match = _quad_tree.query_circle(self, _test_circle_center, _test_circle_radius, true)
	prints("Query with quadtree takes", OS.get_ticks_usec() - time, "usec to finish!")
	
	for p in _points_match:
		draw_circle(p, 3, Color.green)
	
	# Compare with normal calculation
	time = OS.get_ticks_usec()
	var arr = []
	for p in _points:
		if _test_circle_center.distance_to(p) < _test_circle_radius:
			arr.append(p)
	prints("Normal check takes", OS.get_ticks_usec() - time, "usec to finish!")
	
	
func test_query_circle():
	_test_circle_center = Vector2(rand_range(0, _screen_rect.size.x), rand_range(0, _screen_rect.size.y))
	_test_circle_radius = _circle_radius
	test_query_circle_mouse()


func test_query_rect_mouse():
	prints("=================================================================")
	draw_rect(_test_rect, Color.green, false)
	
	var time = OS.get_ticks_usec()
	_points_match = _quad_tree.query_rect(self, _test_rect, true)
	prints("Query with quadtree takes", OS.get_ticks_usec() - time, "usec to finish!")
	
	for p in _points_match:
		draw_circle(p, 3, Color.green)
		
	# Compare with normal calculation
	time = OS.get_ticks_usec()
	var arr = []
	for p in _points:
		if _test_rect.has_point(p):
			arr.append(p)
	prints("Normal check takes", OS.get_ticks_usec() - time, "usec to finish!")


func test_query_rect():
	_test_rect = Rect2(rand_range(0, _screen_rect.size.x / 2), rand_range(0, _screen_rect.size.y / 2), _rect_w, _rect_h)
	test_query_rect_mouse()


func _draw():
	Global.count = 0
	_quad_tree.draw_test(self)
	
	# TEST
#	test_query_rect()
#	test_query_circle()

	test_query_circle_mouse()
#	test_query_rect_mouse()

	prints("Total check: ", Global.count)
	prints("Total point match:", _points_match.size())


func _on_Restart_pressed():
	Global.count = 0
	get_tree().change_scene("res://QuadTreeTest.tscn")

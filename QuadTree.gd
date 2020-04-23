extends Node

static func create_quadtree(r: Rect2, c: int):
	return load('QuadTree.gd').new(r, c)

class_name QuadTree

var _rect = Rect2()
var _center = Vector2()

var _quad_nw = null
var _quad_ne = null
var _quad_sw = null
var _quad_se = null

var _capacity = 4
var _points = []

var _half_w = 0
var _half_h = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _init(rect: Rect2, capacity = _capacity):
	_rect = rect
	_capacity = capacity
	_center = _rect.position + Vector2(_get_half_w(), _get_half_h())
	
	
func draw_test(node: Node2D, is_draw_center_point = false):
	var color = Color.blue
	node.draw_rect(_rect, color, false)
	
	# Draw center
	if is_draw_center_point:
		node.draw_circle(_center, 2, color)
	
	var color_point = Color(randf(), randf(), randf(), 1)
	for p in _points:
		node.draw_circle(p, 2, color_point)
	
	if _quad_nw:
		_quad_nw.draw_test(node)
	if _quad_ne:
		_quad_ne.draw_test(node)
	if _quad_sw:
		_quad_sw.draw_test(node)
	if _quad_se:
		_quad_se.draw_test(node)
	
	
func _get_half_w() -> float:
	# cached
	if !_half_w:
		_half_w = _rect.size.x / 2
	return _half_w
	
	
func _get_half_h() -> float:
	# cached
	if !_half_h:
		_half_h = _rect.size.y / 2
	return _half_h
	
	
func _subdivide():
	var half_w = _get_half_w()
	var half_h = _get_half_h()
	var pos_x = _rect.position.x
	var pos_y = _rect.position.y
	
	_quad_nw = create_quadtree(Rect2(pos_x, pos_y, half_w, half_h), _capacity)
	_quad_ne = create_quadtree(Rect2(pos_x + half_w, pos_y, half_w, half_h), _capacity)
	_quad_sw = create_quadtree(Rect2(pos_x, pos_y + half_h, half_w, half_h), _capacity)
	_quad_se = create_quadtree(Rect2(pos_x + half_w, pos_y + half_h, half_w, half_h), _capacity)
	
	
# http://www.jeffreythompson.org/collision-detection/circle-rect.php
func _is_circle_overlap_rect(center, radius):
	var cx = center.x
	var cy = center.y
	
	# which edge is closest?
	if cx < _rect.position.x:
		cx = _rect.position.x
	elif cx > _rect.position.x + _rect.size.x:
		cx = _rect.position.x + _rect.size.x
	if cy < _rect.position.y:
		cy = _rect.position.y
	elif cy > _rect.position.y + _rect.size.y:
		cy = _rect.position.y + _rect.size.y
		
	# distance from closest edges
	var dx = center.x - cx
	var dy = center.y - cy
	var d = sqrt(dx * dx + dy * dy)
	
	# if the distance is less than the radius, collision!
	return d <= radius
	
	
func query_rect(node: Node2D, rect: Rect2, is_debug = false):
	var arr = []
	
	if !rect.intersects(_rect):
		return arr
	
	if is_debug:
		# Draw intersect rect test
		node.draw_rect(_rect, Color.white, false)
		
	for p in _points:
		if is_debug:
			# Draw point test
			node.draw_circle(p, 3, Color.white)
			Global.count += 1
		if rect.has_point(p):
			arr.append(p)
	
	# Divided
	if _quad_nw:
		arr += _quad_nw.query_rect(node, rect, is_debug)
		arr += _quad_ne.query_rect(node, rect, is_debug)
		arr += _quad_sw.query_rect(node, rect, is_debug)
		arr += _quad_se.query_rect(node, rect, is_debug)
	
	return arr
	
	
func query_circle(node: Node2D, center: Vector2, radius, is_debug = false):
	var arr = []
	
	# Check intersect
	if !_is_circle_overlap_rect(center, radius):
		return arr
		
	if is_debug:
		# Draw intersect rect test
		node.draw_rect(_rect, Color.white, false)
		
	for p in _points:
		if is_debug:
			# Draw point test
			node.draw_circle(p, 3, Color.white)
			Global.count += 1
		if center.distance_to(p) < radius:
			arr.append(p)

	# Divided
	if _quad_nw:
		arr += _quad_nw.query_circle(node, center, radius, is_debug)
		arr += _quad_ne.query_circle(node, center, radius, is_debug)
		arr += _quad_sw.query_circle(node, center, radius, is_debug)
		arr += _quad_se.query_circle(node, center, radius, is_debug)
	
	return arr
	
	
func insert(point: Vector2):
	# Ignore objects that do not belong in this quad tree
	if !_rect.has_point(point):
		return false
		
	# If there is space in this quad tree and if doesn't have subdivisions, add the object here
	if _points.size() < _capacity and !_quad_nw:
		_points.append(point)
		return true
		
	# Otherwise, subdivide and then add the point to whichever node will accept it
	if !_quad_nw:
		_subdivide()
	
	# We have to add the points/data contained into this quad array to the new quads if we only want the last node to hold the data
	if _quad_nw.insert(point):
		return true
	if _quad_ne.insert(point):
		return true
	if _quad_sw.insert(point):
		return true
	if _quad_se.insert(point):
		return true

	# Otherwise, the point cannot be inserted for some unknown reason (this should never happen)
	return false

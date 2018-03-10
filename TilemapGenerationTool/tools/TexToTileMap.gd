tool
extends Node2D

#######
# Tool usage (see readme on github for a properly formated guide)
# Prereq: Load the tool by setting it as the script of the root node of an empty scene.
# 1st: Setup Texture and Tile Size
# 2nd: Set "Generate Tilemap" to generate the tilemap. This variable actually acts like a button, if you unset it it will delete the tilemap
# 3rd: Move the mouse over a tile + use the hotkeys to define colliders for that tile:
#		- C : Clear the tile (leaves only the sprite without rigid body or any shapes)
#		- Q : Set collider with rectangle shape covering the whole tile
#		- A : Set line collider for the left border of the tile
#		- D : Set line collider for the right border of the tile
#		- W : Set line collider for the top border of the tile
#		- S : Set line collider for the bottom border of the tile
#######

# Variables exposed through the editor
export(Texture) var texture = null setget setTexture, getTexture
export(int) var tileSize = 32 setget setTileSize, getTileSize
export(bool) var generateTilemap = false setget genTilemap, getGenTilemap
#Line and highlight color
export(Color) var lineColor = Color(1, 0, 0, 1)
export(Color) var highlightColor = Color(0, 1, 0, 0.3)

# Internal variables to handle input
var aDown = false
var wDown = false
var sDown = false
var dDown = false
var qDown = false
var cDown = false
var mouseCorrection = Vector2(16.0, 16.0)

# SegmentShape2D for the colliders
var lineShapeLeft = SegmentShape2D.new()
var lineShapeRight = SegmentShape2D.new()
var lineShapeTop = SegmentShape2D.new()
var lineShapeBottom = SegmentShape2D.new()
var rectangleShapeFull = RectangleShape2D.new()

enum ColliderType {
	Left,
	Right,
	Top,
	Bottom,
	Square
}
	
# Custom getters and setters
func getTileSize():
	return tileSize
	
func setTileSize(size):
	tileSize = size
	# Update mouse correction with new tile size
	mouseCorrection = Vector2(tileSize / 2.0, tileSize / 2.0)
	# Update line shapes distance
	lineShapeLeft.a = Vector2(-tileSize * 0.5, -tileSize * 0.5)
	lineShapeLeft.b = Vector2(-tileSize * 0.5, tileSize * 0.5)
	lineShapeRight.a = Vector2(tileSize * 0.5, -tileSize * 0.5)
	lineShapeRight.b = Vector2(tileSize * 0.5, tileSize * 0.5)
	lineShapeTop.a = Vector2(-tileSize * 0.5, -tileSize * 0.5)
	lineShapeTop.b = Vector2(tileSize * 0.5, -tileSize * 0.5)
	lineShapeBottom.a = Vector2(-tileSize * 0.5, tileSize * 0.5)
	lineShapeBottom.b = Vector2(tileSize * 0.5, tileSize * 0.5)
	
	# Update square shape (full tile)
	rectangleShapeFull.extents = Vector2(tileSize/2, tileSize/2)
	
func setTexture(newTex):
	texture = newTex
	removeGeneratedNodes()
	
func getTexture():
	return texture
	
func getGenTilemap(gen):
	return generateTilemap
	
	# Custom "hacky" getter so Generate Tilemap acts as a button for generating or deleting the tilemap
func genTilemap(generate):

	# Hack to avoid weird errors when saving or loading the scene
	if null == get_tree():
		return

	generateTilemap = generate
	if true == generateTilemap: # Initial tileset generation
		generateInitialTileset()
	else: # Remove current generated nodes
		removeGeneratedNodes()	
		
func _ready():
	# Configure default line shapes
	lineShapeLeft.a = Vector2(-tileSize * 0.5, -tileSize * 0.5)
	lineShapeLeft.b = Vector2(-tileSize * 0.5, tileSize * 0.5)
	lineShapeRight.a = Vector2(tileSize * 0.5, -tileSize * 0.5)
	lineShapeRight.b = Vector2(tileSize * 0.5, tileSize * 0.5)
	lineShapeTop.a = Vector2(-tileSize * 0.5, -tileSize * 0.5)
	lineShapeTop.b = Vector2(tileSize * 0.5, -tileSize * 0.5)
	lineShapeBottom.a = Vector2(-tileSize * 0.5, tileSize * 0.5)
	lineShapeBottom.b = Vector2(tileSize * 0.5, tileSize * 0.5)
	
	# Configure default square shape (full tile collision)
	rectangleShapeFull.extents = Vector2(16, 16)

func _process(delta):
	# Input handling
	# Avoid doing weird stuff on ctrl+key (v.g. ctrl+s to save)
	if Input.is_key_pressed(KEY_CONTROL):
		return
	
	if Input.is_key_pressed(KEY_C):
		if false == cDown:
			cDown = true
			clearChildsForCurrentTile()
	else:
		cDown = false
	if Input.is_key_pressed(KEY_A):
		if false == aDown:
			aDown = true
			setColliderForCurrentTile(ColliderType.Left)
	else:
		aDown = false
	if Input.is_key_pressed(KEY_W):
		if false == wDown:
			wDown = true
			setColliderForCurrentTile(ColliderType.Top)
	else:
		wDown = false
	if Input.is_key_pressed(KEY_S):
		if false == sDown:
			sDown = true
			setColliderForCurrentTile(ColliderType.Bottom)
	else:
		sDown = false
	if Input.is_key_pressed(KEY_D):
		if false == dDown:
			dDown = true
			setColliderForCurrentTile(ColliderType.Right)
	else:
		dDown = false
	if Input.is_key_pressed(KEY_Q):
		if false == qDown:
			qDown = true
			setColliderForCurrentTile(ColliderType.Square)
	else:
		qDown = false
		
	# Trigger a _draw call to show the grid & highlight
	update()
	
func clearChildsForCurrentTile():
	var mousePos = self.get_local_mouse_position() + mouseCorrection
	var tileName = tileNameFromCoordinates(mousePos.x / tileSize, mousePos.y / tileSize)
	if not has_node(tileName):
		return
	
	var tile = get_node(tileName)
	for child in tile.get_children():
		tile.remove_child(child)
		child.queue_free()
		
func setColliderForCurrentTile(type):
	var mousePos = self.get_local_mouse_position() + mouseCorrection
	var tileName = tileNameFromCoordinates(mousePos.x / tileSize, mousePos.y / tileSize)
	if not has_node(tileName):
		return	
	
	var tile = get_node(tileName)
	
	var rigidBody = null
	if not tile.has_node("TileRigidBody2D"):
		# Create new rigid body for the tile
		rigidBody = StaticBody2D.new()
		rigidBody.name = "TileRigidBody2D"
		tile.add_child(rigidBody)
		# Transfer ownership to editor, required for the nodes to be properly added to the scene
		rigidBody.set_owner(get_tree().get_edited_scene_root())
	else:
		rigidBody = tile.get_node("TileRigidBody2D")
	
	# You can either have lines or square but not both
	if type != ColliderType.Square:
		if rigidBody.has_node("SquareCollisionShape"):
			var collisionShape = rigidBody.get_node("SquareCollisionShape")
			rigidBody.remove_child(collisionShape)
			collisionShape.queue_free()
		
	if type == ColliderType.Left:
		if not rigidBody.has_node("LeftCollisionShape"):
			var collisionShape = CollisionShape2D.new()
			collisionShape.name = "LeftCollisionShape"
			collisionShape.shape = lineShapeLeft
			#collisionShape.transform = collisionShape.transform.scaled(Vector2(1.0, tileSize / 200.0))
			rigidBody.add_child(collisionShape)
			collisionShape.set_owner(get_tree().get_edited_scene_root())
		else:
			var collisionShape = rigidBody.get_node("LeftCollisionShape")
			rigidBody.remove_child(collisionShape)
			collisionShape.queue_free()
			
	if type == ColliderType.Right:
		if not rigidBody.has_node("RightCollisionShape"):
			var collisionShape = CollisionShape2D.new()
			collisionShape.name = "RightCollisionShape"
			collisionShape.shape = lineShapeRight
			#collisionShape.transform = collisionShape.transform.scaled(Vector2(1.0, tileSize / 200.0))
			rigidBody.add_child(collisionShape)
			collisionShape.set_owner(get_tree().get_edited_scene_root())
		else:
			var collisionShape = rigidBody.get_node("RightCollisionShape")
			rigidBody.remove_child(collisionShape)
			collisionShape.queue_free()
	
	if type == ColliderType.Top:
		if not rigidBody.has_node("TopCollisionShape"):
			var collisionShape = CollisionShape2D.new()
			collisionShape.name = "TopCollisionShape"
			collisionShape.shape = lineShapeTop
			#collisionShape.transform = collisionShape.transform.scaled(Vector2(tileSize / 200.0, 1.0))
			rigidBody.add_child(collisionShape)
			collisionShape.set_owner(get_tree().get_edited_scene_root())
		else:
			var collisionShape = rigidBody.get_node("TopCollisionShape")
			rigidBody.remove_child(collisionShape)
			collisionShape.queue_free()
	
	if type == ColliderType.Bottom:
		if not rigidBody.has_node("BottomCollisionShape"):
			var collisionShape = CollisionShape2D.new()
			collisionShape.name = "BottomCollisionShape"
			collisionShape.shape = lineShapeBottom
			#collisionShape.transform = collisionShape.transform.scaled(Vector2(tileSize / 200.0, 1.0))
			rigidBody.add_child(collisionShape)
			collisionShape.set_owner(get_tree().get_edited_scene_root())
		else:
			var collisionShape = rigidBody.get_node("BottomCollisionShape")
			rigidBody.remove_child(collisionShape)
			collisionShape.queue_free()
					
	if type == ColliderType.Square:
		if not rigidBody.has_node("SquareCollisionShape"):
			# No point in having lines + full collision, so we clear all lines first
			for child in rigidBody.get_children():
				rigidBody.remove_child(child)
				child.queue_free()
			var collisionShape = CollisionShape2D.new()
			collisionShape.name = "SquareCollisionShape"
			collisionShape.shape = rectangleShapeFull
			rigidBody.add_child(collisionShape)
			collisionShape.set_owner(get_tree().get_edited_scene_root())
		else:
			var collisionShape = rigidBody.get_node("SquareCollisionShape")
			rigidBody.remove_child(collisionShape)
			collisionShape.queue_free()	
		
func removeGeneratedNodes():
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()

func tileNameFromCoordinates(x, y):
	# Cast to int so we don't generate "float" names
	x = int(x)
	y = int(y)
	return String(x).pad_zeros(4) + "_" + String(y).pad_zeros(4)
	
func generateInitialTileset():
	if null == texture:
		print("You need to set a texture before generating a tileset!")
		return
	var tileSizeVec = Vector2(tileSize, tileSize)
	for i in range(0, texture.get_width()/tileSize):
		for j in range(0, texture.get_height()/tileSize):
			var sprite = Sprite.new()
			sprite.texture = texture
			sprite.name = tileNameFromCoordinates(i, j)
			sprite.position = Vector2(i*tileSize, j*tileSize)
			sprite.region_enabled = true
			sprite.region_rect = Rect2(sprite.position, tileSizeVec)
			sprite.show_behind_parent = true
			self.add_child(sprite)
			# Transfer ownership to editor, required for the nodes to be properly added to the scene
			sprite.set_owner(get_tree().get_edited_scene_root())
			
# Overriden method for custom draw, used for showing the grid and mouse hover node highlight
func _draw():
	if null == texture:
		return
	var offset = -tileSize/2
	# Draw grid
	for i in range(offset, texture.get_width() + offset + tileSize, tileSize):
		draw_line(Vector2(i, offset), Vector2(i, texture.get_height() + offset), lineColor)
	for j in range(offset, texture.get_height() + offset + tileSize, tileSize):
		draw_line(Vector2(offset, j), Vector2(texture.get_width() + offset, j), lineColor)
	
	# Draw tile highlight
	var mousePos = self.get_local_mouse_position() + mouseCorrection
	var tileX = int(mousePos.x / tileSize)
	var tileY = int(mousePos.y / tileSize)
	var tileName = tileNameFromCoordinates(tileX, tileY)
	if not has_node(tileName):
		return
	
	draw_rect(Rect2(tileX * tileSize + offset, tileY * tileSize + offset, tileSize, tileSize), highlightColor)

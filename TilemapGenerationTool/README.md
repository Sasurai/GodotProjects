#######
TODO : Use proper markdown to format this ^^"
# Tool usage
# Prereq: Load the tool by setting it as the script of the root node of an empty scene.
# 1st: Setup Texture and Tile Size
# 2nd: Set "Generate Tilemap" to generate the tilemap. This variable actually acts like a button, if you unset it it will delete the tilemap
# 3rd (optional advanced setting, most people should ignore this): Set custom line and rectangle shapes to be used for colliders
# 4th: Move the mouse over a tile + use the hotkeys to define colliders for that tile:
#		- C : Clear the tile (leaves only the sprite without rigid body or any shapes)
#		- Q : Set collider with rectangle shape covering the whole tile
#		- A : Set line collider for the left border of the tile
#		- D : Set line collider for the right border of the tile
#		- W : Set line collider for the top border of the tile
#		- S : Set line collider for the bottom border of the tile
#######
# TilemapGenerationTool README
The purpose of this tool is to provide an easy way to do the pre-work needed to create a tilemap from a texture. The script allows you to quickly split the texture into tiles, and to define colliders for the tiles (for each of the sides of the tile, or for the whole tile).
The actual exporting of the tilemap should be done using the usual `Scene->Conver To..->TileSet..`.
## About the project
The project includes the following things:
- `project.godot` project you can open to browse the rest of things and see the samples and the tool working.
- `tools` folder, where the actual tool is. You only need the `.gd` file, but a `.tscn` is also provided with a sample generated tilemap.
- `images` folder containing the texture used as a sample. [Source - OpenGameArt](https://opengameart.org/content/basic-map-32x32-by-silver-iv)
- `sample` folder contains the already generated `.tres` file for the tileset.
- `SampleMain.tscn` scene containing a super simple scene created using the sample tileset.

There are also a bunch of project files and this README.
## Tool usage
This instructions assume you're using the tool by copying the `.gd` script in your project. If you use the provided project you will see some of the steps are already done, and you will need to reset the already generated stuff.
- **Prerequisite**: Load the tool by setting it as the script of the root node of an empty scene.
1. Setup texture and tile size. You can also optionally change the line color and highlight color, if you think they will not be visible enough over your texture.
2.  Set "Generate Tilemap" to generate the tilemap. This variable actually acts like a button, if you unset it it will delete the tilemap, which you will need to do if you've loaded the provided project and want to generate a different tileset.
**At this point, if everything went well, you already have a scene ready for exporting**, but with no colliders.
3. Move the mouse over a tile and use the hotkeys to define colliders for that tile. The hotkeys are:

Hotkey | Action
------------ | -------------
C | Clear the tile (leaves only the sprite without rigid body or any shapes).
Q | Set collider with rectangle shape covering the whole tile.
A | Set line collider for the left border of the tile.
D | Set line collider for the right border of the tile.
W | Set line collider for the top border of the tile.
S | Set line collider for the bottom border of the tile.

**Disclaimer:** The script triggers an error on the Output that I've not managed to get rid of.
The error is related to this piece of code:
```gdscript
# Hack to avoid weird errors when saving or loading the scene
if null == get_tree():
	return
```
Which is needed to avoid really weird behaviours when saving/loading the scene.
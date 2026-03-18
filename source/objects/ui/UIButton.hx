package objects.ui;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxStringUtil;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;

using StringTools;
using utils.Files;
using utils.Paths;

class UIButton extends FlxUIButton {
	public function new(X:Float = 0, Y:Float = 0, Width:Null<Int>, Height:Null<Int>, ?Text:String, ?Size:Null<Int>, ?GraphicPath:String, ?Color:Null<FlxColor>, ?OnClick:Void->Void) {
		super(X, Y, Text, OnClick);
        
		this.label.fieldWidth = Width != null ? Width : this.width;

        if (Size != null) {
			label.setFormat(FlxAssets.FONT_DEFAULT, Size, FlxColor.BLACK);
            if (Height == null) {Height = Std.int(label.height + 6); }
        }
		if (Height == null) {Height = Std.int(this.height); }
		if (Width == null) {Width = Std.int(this.width); }

        if (GraphicPath == null) {GraphicPath = Paths.image("editor_menu/button"); }
        setSliceButton(GraphicPath, Width, Height + 10);
		if (Color != null) {color = Color; }
	}

    public function setSliceButton(GraphicPath:String, Width:Int = 80, Height:Int = 20):Void {
        if (GraphicPath == null) {GraphicPath = Paths.image("editor_menu/button"); }
        var slice_info:Array<String> = [];
        var slice:Array<Int> = [];

        var slice_text:String = GraphicPath.replace('png', "txt");
        if (slice_text.exists()) {slice_info = slice_text.getText().split('\n'); }

        if (slice_info.length > 0) {slice = FlxStringUtil.toIntArray(slice_info[0]); }

        var _bmp = getBmp(GraphicPath);
        loadGraphicSlice9([GraphicPath], Width, Height, [slice], FlxUI9SliceSprite.TILE_NONE, -1, false, Std.int(_bmp.width), Std.int(_bmp.height / 3), null);
        
        if (slice_info.length > 1) {autoCenterLabel(); _centerLabelOffset.y += Std.parseInt(slice_info[1]); }
        if (slice_info.length > 2) {labelOffsets[2].y = Std.parseInt(slice_info[2]); }
        
    }
    public function setButtonFrames(GraphicPath:String):Void {
        if (Files.getAtlas(GraphicPath) != null) {
            this.frames = Files.getAtlas(GraphicPath);

            this.animation.addByPrefix('normal', 'Idle', 24, true);
            this.animation.addByPrefix('highlight', 'Over', 24, true);
            this.animation.addByPrefix('pressed', 'Hit', 24, true);
        } else{
            var _bitMap:FlxGraphic = Files.getGraphic(GraphicPath, true);

            if (_bitMap != null) {
                this.loadGraphic(_bitMap, true, Math.floor(_bitMap.width / 3), Math.floor(_bitMap.height));

                this.animation.add('normal', [0], 0, false);
                this.animation.add('highlight', [1], 0, false);
                this.animation.add('pressed', [2], 0, false);
            }
        }
    }
}
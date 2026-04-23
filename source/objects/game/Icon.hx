package objects.game;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.FlxGraphic;
import objects.notes.StrumLine;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.FlxG;

using utils.Files;
using StringTools;

class Icon extends FlxSprite {
	public var default_scale:FlxPoint = FlxPoint.get(1, 1);

	public var isPlayer:Bool = false;
	public var curIcon:String = "";
	public var curAnim:String = "";

	public var parent:StrumLine;

	public function new(_player:Bool = false):Void {
		isPlayer = _player;
		super();
	}

	public function setIcon(char:String, ?_strum:StrumLine) {
		if (curIcon == char) { return; }
		if ( _strum != null) { parent = _strum; }
		curIcon = char;

		switch (curIcon) {
			default: {
				var path = Paths.image('icons/icon-${curIcon}');
				if (!Paths.exists(path)) {path = Paths.image('icons/icon-${curIcon}-pixel'); }
				if (!Paths.exists(path)) {path = Paths.image('icons/icon-face'); }

				if (path.getAtlas() != null) {
					this.frames = path.getAtlas();

					this.animation.addByPrefix('default', 'Default', 24, false);
					this.animation.addByPrefix('losing', 'Losing', 24, false);
					this.animation.addByPrefix('tolosing', 'toLosing', 24, false);
					this.animation.addByPrefix('todefault', 'toDefault', 24, false);
				} else {
					var _bitMap:FlxGraphic = path.getGraphic();
					if (_bitMap == null) { return; }

					this.loadGraphic(_bitMap, true, Math.floor(_bitMap.width / 2), Math.floor(_bitMap.height));

					this.animation.add('default', [0], 0, false);
					this.animation.add('losing', [1], 0, false);
				}

				antialiasing = !path.contains("pixel");
				playAnim("default", true);
				updateHitbox();
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (animation.curAnim != null && animation.finished && animation.curAnim.name != curAnim) { animation.play(curAnim); }
		if (parent != null) { playAnim(((isPlayer && parent.life > 0.4) || (!isPlayer && parent.life < (parent.max_life - 0.4))) ? 'default' : 'losing'); }
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0) {
		if (animation.getByName(AnimName) == null || (curAnim == AnimName && !Force)) { return; }
		animation.play((animation.getByName('to${AnimName}') != null && !Force) ? 'to${AnimName}' : AnimName, Force, Reversed, Frame);
		curAnim = AnimName;
	}
}

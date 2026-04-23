package objects.game;

import flixel.addons.ui.FlxUIGroup;
import objects.notes.StrumLine;
import objects.game.Alphabet;
import objects.game.LifeBar;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import states.PlayState;
import flixel.FlxSprite;
import flixel.FlxG;

class HudBar extends FlxUIGroup {
    override function get_width():Float { return lifeBar.width; }
    override function get_height():Float { return lifeBar.height; }
    
    public var grpBack:FlxUIGroup;
    public var lifeBar:LifeBar;
    public var grpFront:FlxUIGroup;

	public var borderBar:FlxSprite;
	public var alpScore:Alphabet;

	public var playerIcon:Icon;
	public var enemyIcon:Icon;

    public var strumParent:StrumLine;

    public var life(get, set):Float; 
    inline function get_life():Float { return lifeBar.value; }
    inline function set_life(_value:Float):Float { 
        lifeBar.value = _value;
        
        if (moveIcons) {
            playerIcon.x = lifeBar.x + lifeBar.width_value - (playerIcon.width * iconSpace);
            enemyIcon.x = lifeBar.x + lifeBar.width_value - enemyIcon.width + (enemyIcon.width * iconSpace);
        }

        return lifeBar.value = _value; 
    }

    public var defaultBumps:Bool = true;
    public var customBumps:Bool = false;
    public var moveIcons:Bool = true;

    public var iconSpace:Float = 0.25;
    public var iconScale:Float = 1;
    
    public var scoreScale:Float = 0.25;
    public var scoreOffset:Float = 10;

    public function new(_x:Float, _y:Float, _imageBack:String, _imageFront:String):Void {
        super(x, y);

        grpBack = new FlxUIGroup();
        
		borderBar = new FlxSprite(-5, -6).loadGraphic(_imageFront);
		borderBar.setGraphicSize(FlxG.width * 0.5);
        borderBar.updateHitbox();

        lifeBar = new LifeBar(0, 0, _imageBack, FlxColor.LIME, FlxColor.GREEN);
		lifeBar.setBarScale(borderBar.scale.x, borderBar.scale.y);
		lifeBar.flipBar = true;
        
        grpFront = new FlxUIGroup();

		playerIcon = new Icon(true);
		playerIcon.flipX = true;

		enemyIcon = new Icon();
        
		alpScore = new Alphabet(0, 0, { font: "small_numbers", scale: 0.5, text: '0' });
        alpScore.y = lifeBar.y + lifeBar.height - (alpScore.height * 0.5);
	    alpScore.x = lifeBar.x + lifeBar.width - alpScore.width - scoreOffset;
        
        add(grpBack);
		add(lifeBar);
        add(borderBar);
		add(grpFront);
		add(alpScore);        
		add(enemyIcon);
		add(playerIcon);

        life = 1;
    }

	override public function update(elapsed:Float) {
		super.update(elapsed);
        
		if (defaultBumps) {
			playerIcon.scale.x = FlxMath.lerp(playerIcon.scale.x, playerIcon.default_scale.x * iconScale, elapsed * 3.125);
			playerIcon.scale.y = FlxMath.lerp(playerIcon.scale.y, playerIcon.default_scale.y * iconScale, elapsed * 3.125);
			enemyIcon.scale.x = FlxMath.lerp(enemyIcon.scale.x, enemyIcon.default_scale.x * iconScale, elapsed * 3.125);
			enemyIcon.scale.y = FlxMath.lerp(enemyIcon.scale.y, enemyIcon.default_scale.y * iconScale, elapsed * 3.125);
		}
    }

    public function bumpIcons(_mult:Float):Void {
        if (customBumps) { return; }
        
		playerIcon.scale.x += 0.1 * _mult;
		playerIcon.scale.y += 0.1 * _mult;
		enemyIcon.scale.x += 0.1 * _mult;
		enemyIcon.scale.y += 0.1 * _mult;
    }

    public function setScore(_value:Int):Void {
	    alpScore.setScore(_value, PlayState.song.style, scoreScale);
	    alpScore.x = lifeBar.x + lifeBar.width - alpScore.width - scoreOffset;
    }

    public function setOpponent(_icon:String, _color:FlxColor):Void {
        lifeBar.setColors(_color, null);
        enemyIcon.setIcon(_icon);
        
        enemyIcon.y = lifeBar.y + (lifeBar.height / 2) - (enemyIcon.height / 2);
        
        this.life = this.life + 0;
    }

    public function setPlayer(_icon:String, _color:FlxColor, ?_strum:StrumLine):Void {
        lifeBar.setColors(null, _color);
        playerIcon.setIcon(_icon);
        
        playerIcon.y = lifeBar.y + (lifeBar.height / 2) - (playerIcon.height / 2);

        this.life = this.life + 0;

        if (_strum == null) { return; }

        strumParent = _strum;        
		enemyIcon.parent = strumParent;
		playerIcon.parent = strumParent;
    }
}
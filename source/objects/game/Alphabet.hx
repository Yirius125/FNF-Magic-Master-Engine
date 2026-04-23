package objects.game;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.addons.ui.FlxUIGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Timer;

using utils.Files;
using StringTools;

class Alphabet extends FlxUIGroup {
    public static var DEFAULT_FONT:String = "alphabet";
	public var cur_data:Array<Dynamic> = [];

    public var repMap:Map<String, String> = [
        "-" => " "
    ];

    public var textWidth:Float = 0;

    public var text:String = "";

    public var backColor:FlxColor = 0x62000000;
    public var backCoords:Array<Int> = [];
    public var backSprite:String = null;
    public var offsetBack:Float = 10;
    public var useBack:Bool = false;
    public var back:FlxSprite;

    //------| Typing Stuff |------//
    public var onType:FlxTypedSignal<String->Dynamic->Void>;
    public var isTyping:Bool = false;
    var typeSound:FlxSound;
    //-----------------------------//

    public var spaceWidth:Float = 40;
    public var xMultiplier:Float = 1;
    public var yMultiplier:Float = 1;
    public var xOffset:Float = 0;
    public var yOffset:Float = 0;

    var lastChar:AlphaCharacter = null;
    var lastFirstChar:AlphaCharacter = null;

	var curY:Float = 0;
    var curX:Float = 0;

    public function new(x:Float, y:Float, data:Dynamic) {
        if ((data is Array)) { cur_data = data; } else if ((data is String)) { cur_data = [({ text: data })]; } else { cur_data = [data]; }

		super(x, y);

        onType = new FlxTypedSignal();

        if (cur_data.length <= 0) { return; }
        
        loadText();
	}

    function doSplitWords(_text:String):Array<String> {
        var splitWords:Array<String> = _text.split("");
        for (c in splitWords) {if (repMap.exists(c)) {c.replace(c, repMap.get(c)); }}
        return splitWords;
    }

    public function setSliceBack(_image:String, _slice1:Int = 20, _slice2:Int = 20, _slice3:Int = 78, _slice4:Int = 78):Void {
        backSprite = _image;
        backCoords = [_slice1, _slice2, _slice3, _slice4];
        loadText();
    }
    
    public function setText(data:Dynamic):Void {
        if ((data is Array)) { cur_data = data; } else if ((data is String)) { cur_data = [({text: data})]; } else { cur_data = [data]; }
        if (cur_data.length <= 0) { return; }
        loadText();
    }

    public function loadText() {
        curX = useBack || backSprite != null ? offsetBack : 0;
        curY = useBack || backSprite != null ? offsetBack : 0;
        text = "";

        while (members.length > 0) { remove(members[0], true).destroy(); }

        if (timer != null) { timer.cancel(); }
        isTyping = false;

        if (cur_data == null) { return; }

        for (_dat in cur_data) {
            var cur_split:Array<String> = null;
            var cur_image:String = null;

            var cur_scale:FlxPoint = _dat.scale != null ? FlxPoint.get(_dat.scale,_dat.scale) : FlxPoint.get(1, 1);
            var cur_size:FlxPoint = _dat.size != null ? FlxPoint.get(_dat.size[0],_dat.size[1]) : null;
            var cur_color:FlxColor = _dat.color != null ? _dat.color : 0x00ffffff;
            var cur_font:String = _dat.font != null ? _dat.font : DEFAULT_FONT;
            var cur_width:Int = _dat.width != null ? _dat.width : 0;
            var cur_line:Array<String> = _dat.text != null ? _dat.text.split("\n") : [];
            var cur_animated:Bool = _dat.animated;
            var cur_center:String = _dat.center;
            var cur_bold:Bool = _dat.bold;

            if (_dat.position != null) {curX = _dat.position[0]; curY = _dat.position[1]; }
            if (_dat.rel_position != null) {curX += _dat.rel_position[0]; curY += _dat.rel_position[1]; }
            if (_dat.text != null) {cur_split = doSplitWords(_dat.text); }
            else if (_dat.image != null) {cur_image = _dat.image; }

            if (cur_split != null) {
                var _i:Int = 0;
                for (char in cur_split) {
                    switch (char) {
                        case '\n':{ if (lastFirstChar != null) { curY += lastFirstChar.height * yMultiplier; curX = 0; } cur_line.shift(); }
                        case '\t':{ curX += 2 * spaceWidth * cur_scale.x; }
                        case ' ':{ curX += spaceWidth * cur_scale.x;  text += " "; }
                        default:{
                            if (AlphaCharacter.getChars().indexOf(char.toLowerCase()) == -1) { continue; }

                            if (textWidth > 0 && (curX + 10) >= textWidth) {if (lastFirstChar != null) {curY += lastFirstChar.height * yMultiplier; curX = 0; }}
                            
                            var letter:AlphaCharacter = new AlphaCharacter(curX, curY + yOffset, cur_font);
                            letter.createChar(char, cur_bold, cur_color, cur_animated);
                            if (cur_width > 0) {letter.setGraphicSize(cur_width / cur_line[0].split("").length, 0); }
                            else {letter.scale.set(cur_scale.x, cur_scale.y); }
                            letter.updateHitbox();
                            
                            curX += (letter.width + xOffset) * xMultiplier;
                                    
                            lastChar = letter;
                            if (_i == 0) {lastFirstChar = letter; }
                
                            add(letter);
    
                            _i++;
                        }
                    }
                    text += char;
                }
            } else if (cur_image != null) {
                var _image:FlxSprite = new FlxSprite(curX, curY).loadGraphic(Paths.image(cur_image).getGraphic());
                if (cur_scale != null) {_image.scale.set(cur_scale.x, cur_scale.y); }
                if (cur_size != null) {_image.setGraphicSize(Std.int(cur_size.x), Std.int(cur_size.y)); }
                _image.updateHitbox();
                if (cur_center != null) {_image.screenCenter(FlxAxes.fromString(cur_center)); }
                _image.color = cur_color;
                curX += _image.width * xMultiplier;
                add(_image);
            }
        }
        
		calcBounds();

        if (backSprite != null) {
            if (back != null) {back.destroy(); }
            back = Magic.sliceRect(0, 0, Std.int(width + (offsetBack * 2)), Std.int(height + (offsetBack * 2)), backSprite, backCoords[0], backCoords[1], backCoords[2], backCoords[3]);
            this.insert(0, back);
        } else if (useBack) {
            if (back != null) {back.destroy(); }
            back = Magic.roundRect(0, 0, Std.int(this.width + (offsetBack * 2)), Std.int(this.height + (offsetBack * 2)), 15, 15, backColor);
            this.insert(0, back);
        }
        
		calcBounds();
    }

    var timer:FlxTimer;
    public function startText():Void {
        var cloned_data:Array<Dynamic> = cur_data.copy();
        curX = curY = 0;
        text = "";
        
        while (members.length > 0) { remove(members[0], true).destroy(); }

        isTyping = true;

        if (timer != null) {timer.cancel(); }
        timer = new FlxTimer();

        var current_item:Dynamic = null;
        var current_text:Array<String> = [];
        
        var cur_scale:FlxPoint = FlxPoint.get(1,1);
        var cur_font:String = DEFAULT_FONT;
        var cur_animated:Bool = true;
        var cur_bold:Bool = true;
        var cur_color:FlxColor = 0x00ffffff;

        var _i:Int = 0;

        timer.start(0.1,
            function(tmr:FlxTimer) {
                if (current_text.length <= 0) {
                    if (cloned_data.length <= 0) {
                        isTyping = false;
                        timer.cancel();
                        return;
                    }

                    current_item = cloned_data.shift();
                    current_text = doSplitWords(current_item.text);

                    timer.time = current_item.time;
                    
                    cur_scale = current_item.scale != null ? FlxPoint.get(current_item.scale,current_item.scale) : FlxPoint.get(1,1);
                    cur_font = current_item.font != null ? current_item.font : DEFAULT_FONT;
                    cur_animated = current_item.animated;
                    cur_bold = current_item.bold;
                    cur_color = current_item.color != null ? current_item.color : 0x00ffffff;
                    if (current_item.position != null) {curX = current_item.position[0]; curY = current_item.position[1]; }
                    if (current_item.rel_position != null) {curX += current_item.rel_position[0]; curY += current_item.rel_position[1]; }

                    if (current_item.sound != null && Paths.exists(Paths.sound(current_item.sound))) {typeSound = new FlxSound().loadEmbedded(Paths.sound(current_item.sound).getSound()); }
                }

                var cur_character:String = current_text.shift();
                
                switch (cur_character) {
                    case '\n':{if (lastFirstChar != null) {curY += lastFirstChar.height * yMultiplier; curX = 0; }}
                    case '\t':{curX += 2 * spaceWidth; }
                    case ' ':{curX += spaceWidth; text += " "; }
                    default:{
                        if (AlphaCharacter.getChars().indexOf(cur_character.toLowerCase()) != -1) {
                            if (textWidth > 0 && (curX + 10) >= textWidth) {if (lastFirstChar != null) {curY += lastFirstChar.height * yMultiplier; curX = 0; }}

                            var letter:AlphaCharacter = new AlphaCharacter(curX, curY + yOffset, cur_font);
                            letter.createChar(cur_character, cur_bold, cur_color);
                            if (!cur_animated) {letter.animation.stop(); }
                            letter.scale.set(cur_scale.x, cur_scale.y);
                            letter.updateHitbox();
                            curX += (letter.width + xOffset) * xMultiplier;
                                    
                            lastChar = letter;
                            if (_i == 0) {lastFirstChar = letter; }
                
                            add(letter);
                            if (typeSound != null) {typeSound.play(); }
                            onType.dispatch(cur_character, current_item);

                            _i++;
                        }
                    }
                }
                text += cur_character;
            }
        , 0);
        
		calcBounds();
    }
    
    public var style:String;
    public function popScore(_score:Int, _style:String, _scale:Float = 0.5):Void {
        curX = curY = 0;
        style = _style;
        text = "";

        var _current:Int = 0;
        var _lastWidth:Float = 0;
        for (_digit in '$_score'.split("")) {
            var _number:FlxSprite = new FlxSprite(_lastWidth, 0).loadGraphic(Paths.styleImage('num${_digit}', _style).getGraphic());
            _number.scale.set(_scale, _scale);
            _number.updateHitbox();
            add(_number);

            _lastWidth += ((_number.width + xOffset) * xMultiplier) - 5;

            FlxTween.tween(
                _number, 
                { y: _number.y - 35, alpha: 0, angle: FlxG.random.float(-25, 25) }, 
                0.5 + (_current * 0.2), 
                { ease: FlxEase.quadOut, onComplete: (twn:FlxTween) -> { remove(_number, true).destroy(); } }
            );

            _current++;
        }
    }
    
    public function setScore(_score:Int, _style:String, _scale:Float = 0.5):Void {
        curX = curY = 0;
        style = _style;
        text = "";

        while (members.length > 0) { remove(members[0], true).destroy(); }

        var _current:Int = 0;
        var _lastWidth:Float = 0;
        for (_digit in '$_score'.split("")) {
            var _number:FlxSprite = new FlxSprite(_lastWidth, 0).loadGraphic(Paths.styleImage('num${_digit}', _style).getGraphic());
            _number.scale.set(_scale, _scale);
            _number.updateHitbox();
            add(_number);

            _lastWidth += (_number.width + xOffset) * xMultiplier;

            _current++;
        }
    }
}

class AlphaCharacter extends FlxSprite {
    public static var alphabet:String = "abcdefghijklmnopqñrstuvwxyz";
	public static var numbers:String = "1234567890";
	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!? ";
    public static function getChars():String { return alphabet + numbers + symbols; }

    public function new(x:Float, y:Float, image:String) {
        super(x, y);
        
        var tex = Paths.image('fonts/${image}').getSparrowAtlas();
        frames = tex;
    }
    
    var reMap:Map<String, String> = [
        "." => "period",
        "'" => "apostraphie",
        "?" => "question mark",
        "/" => "forward slash",
        "!" => "exclamation point",
        " " => "space",
        "," => "comma"
    ];
    public function createChar(letter:String, isBold:Bool = false, getColor:FlxColor = 0x00ffffff, animated:Bool = true) {
        var gSymbol:String = letter; if (reMap.exists(letter)) {gSymbol = reMap.get(letter); }

        animation.addByPrefix('${letter.toUpperCase()}_bold', '${gSymbol.toUpperCase()} bold', 24, animated);
        animation.addByPrefix(letter.toLowerCase(), '${gSymbol.toLowerCase()} lowercase', 24, animated);
        animation.addByPrefix(letter.toUpperCase(), '${gSymbol.toUpperCase()} capital', 24, animated);
        animation.addByPrefix('_${letter}', gSymbol, 24, animated);

        animation.play(letter);
        if (numbers.indexOf(letter) != -1 || symbols.indexOf(letter) != -1) {animation.play('_${letter}'); }
        if (isBold) {animation.play('${letter.toUpperCase()}_bold'); }
        this.color = getColor;
        
        updateHitbox();
    }
}
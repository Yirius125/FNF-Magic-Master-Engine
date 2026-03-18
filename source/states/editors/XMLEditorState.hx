package states.editors;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUIInputText;
import objects.ui.UITabContainer;
import objects.utils.SaverFile;
import flixel.addons.ui.FlxUI;
import objects.scripts.Script;
import objects.ui.UICheckBox;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import objects.ui.UIButton;
import flixel.text.FlxText;
import openfl.events.Event;
import objects.ui.UISlider;
import lime.ui.FileDialog;
import objects.ui.UIList;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxG;
import utils.Magic;

#if desktop
import sys.FileSystem;
import sys.io.File;

import utils.Discord;
#end

using utils.Files;
using StringTools;

class XMLEditorState extends MusicBeatState {
    private static var save_file:SaverFile = null;

    private var Normal_Image_Path:String;
    private var Normal_Atlas_Path:String;
    private var Ghost_Image_Path:String;
    private var Ghost_Atlas_Path:String;
    
    var arrayFocus:Array<FlxUIInputText> = [];

    var ctnGhostMenu:UITabContainer;
    var ctnNormalMenu:UITabContainer;
    var ctnGeneralMenu:UITabContainer;
    function overlapsTabs():Bool {
        return 
            ctnGhostMenu.isOverlaping() ||
            ctnNormalMenu.isOverlaping() ||
            ctnGeneralMenu.isOverlaping()
        ;
    }

    var icon:FlxSprite;
    var ghost:FlxSprite;
    var normal:FlxSprite;
    
    var lastPosition:FlxPoint = FlxPoint.get(0, 0);
    
    var initPoint:FlxSprite;
    var middlePoint:FlxSprite;
    var finalPoint:FlxSprite;
    
    var mousePointer:FlxPoint = FlxPoint.get(0, 0);
    var mouseState:Int = -1;

    var cooldownMouse:Float = 0;

    function setMousePointer(_camPoint:Dynamic, _mousePoint:Dynamic, _inverse:Bool, _state:Int):Void { 
        mousePointer.set(
            _inverse ? _mousePoint.x + _camPoint.x : _mousePoint.x - _camPoint.x, 
            _inverse ? _mousePoint.y + _camPoint.y : _mousePoint.y - _camPoint.y
        );
        mouseState = _state;
    }

    var camFollow:FlxObject;

    override function create() {
        FlxG.sound.playMusic(Paths.music('break_song').getSound());

        #if desktop
		// Updating Discord Rich Presence
		Discord.change('Editing', '[XML Editor]');
		Magic.setWindowTitle('On XML Editor', 1);
		#end

        super.create();

        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);
        
        normal = new FlxSprite();
        normal.cameras = [camFGame];
        normal.antialiasing = false;
        add(normal);

        ghost = new FlxSprite();
        ghost.color = FlxColor.GRAY;
        ghost.cameras = [camFGame];
        ghost.antialiasing = false;
        ghost.alpha = 0.3;
        add(ghost);

        icon = new FlxSprite(5, 55);
        icon.cameras = [camHUD];
        add(icon);

        initPoint = new FlxSprite(100, 50).makeGraphic(6, 6, FlxColor.WHITE);
        initPoint.cameras = [camFGame];
        add(initPoint);
        
        middlePoint = new FlxSprite(0, 0).makeGraphic(6, 6, FlxColor.WHITE);
        middlePoint.cameras = [camFGame];
        add(middlePoint);

        finalPoint = new FlxSprite(0, 0).makeGraphic(6, 6, FlxColor.WHITE);
        finalPoint.cameras = [camFGame];
        add(finalPoint);

        ctnGeneralMenu = new UITabContainer(FlxG.width - 300, 0, 300, 150, 50, "General", 20);
        ctnGeneralMenu.camera = camHUD;
        addGeneralMenuStuff();
        add(ctnGeneralMenu);
        
        ctnNormalMenu = new UITabContainer(FlxG.width - 300, ctnGeneralMenu.height, 300, 330, 50, "Normal Sprite", 20);
        ctnNormalMenu.camera = camHUD;
        addNormalMenuStuff();
        add(ctnNormalMenu);
        
        ctnGhostMenu = new UITabContainer(0, FlxG.height - 370, 300, 320, 50, "Ghost Sprite", 20);
        ctnGhostMenu.camera = camHUD;
        addGhostMenuStuff();
        add(ctnGhostMenu);

		camFollow = new FlxObject(normal.getGraphicMidpoint().x, normal.getGraphicMidpoint().y, 1, 1);
        camFGame.follow(camFollow, LOCKON);
		add(camFollow); 
                
        FlxG.mouse.visible = true;
    }

    override function destroy() {
        FlxG.sound.music.stop();
        super.destroy();
    }

    override function update(elapsed:Float) {
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);
        var wMouse = FlxG.mouse.getWorldPosition(camFGame);

        if (cooldownMouse > 0) { cooldownMouse -= elapsed; }

        var arrayControlle = true;
        for (item in arrayFocus) {if (item.hasFocus) {arrayControlle = false; }}

        if (canControlle && arrayControlle) {  
            switch (mouseState) {
                case 0: { camFollow.setPosition(mousePointer.x - pMouse.x, mousePointer.y - pMouse.y); }
                case 1: { normal.setPosition(wMouse.x - mousePointer.x, wMouse.y - mousePointer.y); }
            }
            
            if ((FlxG.mouse.releasedRight && mouseState == 0) || (FlxG.mouse.released && mouseState > 0)) {
                switch (mouseState) {
                    case 1:{
                        var _offset = (lastPosition - normal.getPosition()).floor();
                        addOffset(Std.int(_offset.x), Std.int(_offset.y));
                        normal.setPosition(initPoint.x + 3, initPoint.y + 3);
                    }
                }
                mouseState = -1;
            } else if (mouseState == -1 && !overlapsTabs()) {
                if (FlxG.mouse.justPressedRight) { setMousePointer(camFollow, pMouse, true, 0); }
                else if (FlxG.mouse.justPressed && cooldownMouse <= 0) {
                    if (FlxG.mouse.overlaps(normal, camFGame)) { setMousePointer(lastPosition = normal.getPosition(), wMouse, false, 1); }
                } else if (FlxG.keys.pressed.SHIFT) {
                    if (FlxG.keys.justPressed.W) { addOffset(0, 10); }
                    if (FlxG.keys.justPressed.A) { addOffset(10, 0); }
                    if (FlxG.keys.justPressed.S) { addOffset(0, -10); }
                    if (FlxG.keys.justPressed.D) { addOffset(-10, 0); }

                    if (FlxG.keys.justPressed.Q) { lstGhostAnimations.change(true); }
                    if (FlxG.keys.justPressed.E) { lstGhostAnimations.change(); }
                } else {
                    if (FlxG.keys.justPressed.W) { addOffset(0, 1); }
                    if (FlxG.keys.justPressed.A) { addOffset(1, 0); }
                    if (FlxG.keys.justPressed.S) { addOffset(0, -1); }
                    if (FlxG.keys.justPressed.D) { addOffset(-1, 0); }

                    if (FlxG.keys.justPressed.Q) { lstNormalAnimations.change(true); }
                    if (FlxG.keys.justPressed.E) { lstNormalAnimations.change(); }
                }
            }

            if (FlxG.keys.pressed.SHIFT) {
                if (FlxG.mouse.wheel != 0) { camFGame.zoom += (FlxG.mouse.wheel * 0.1); }
            } else {
                if (FlxG.mouse.wheel != 0) { camFGame.zoom += (FlxG.mouse.wheel * 0.01); }
            }
            
            if (FlxG.mouse.justPressedMiddle) { camFollow.setPosition(normal.getGraphicMidpoint().x, normal.getGraphicMidpoint().y); }
        }
        
		super.update(elapsed);
    }
    
    var lstPosMode:UIList;
    private function addGeneralMenuStuff():Void {        
        var ttlCurAnim = new FlxText(0, 5, ctnGeneralMenu.display_width, "< - Current Position Mode - >", 18); ctnGeneralMenu.addBody(ttlCurAnim, 10);
        ttlCurAnim.alignment = CENTER;
        
        lstPosMode = new UIList(0, 0, ctnGeneralMenu.display_width, 20, ["Frame", "Animation", "Sprite"]); ctnGeneralMenu.addBody(lstPosMode, 10);
        lstPosMode.name = "POSITION_MODE";

        var btnSetSize:UIButton = new UIButton(0, 0, ctnGeneralMenu.display_width, null, "Set FrameSize to Frame", 16, null, null, () -> {
            if (normal.animation.curAnim == null) { return; }
            var _size = normal.frames.frames[normal.animation.curAnim.frames[normal.animation.curAnim.curFrame]].sourceSize.clone();
            switch (lstPosMode.getSelectedLabel()) {
                case "Animation":{
                    if (normal.animation.curAnim == null) { return; }
                    for (_index in normal.animation.curAnim.frames) {
                        var _frame = normal.frames.frames[_index];
                        _frame.sourceSize.set(_size.x, _size.y);
                    } 
                }
                case "Sprite":{
                    for (_animation in normal.animation.getNameList()) {
                        for (_index in normal.animation.getByName(_animation).frames) {
                            var _frame = normal.frames.frames[_index];
                            _frame.sourceSize.set(_size.x, _size.y);
                        }
                    }
                }
                
                var _curFrame = normal.animation.curAnim.curFrame;
                normal.animation.play(lstNormalAnimations.getSelectedLabel()); 
                normal.animation.pause();
                normal.animation.curAnim.curFrame = _curFrame;
            }
        }); ctnGeneralMenu.addBody(btnSetSize, 10);
    }

    var lstNormalAnimations:UIList;
    var sldNormalFrame:UISlider;
    private function addNormalMenuStuff():Void {
        var ttlFiles = new FlxText(0, 5, ctnNormalMenu.display_width, "< - Files - >", 20); ctnNormalMenu.addBody(ttlFiles, 10);
        ttlFiles.alignment = CENTER;

        var btnNormal:UIButton = new UIButton(0, 0, ctnNormalMenu.display_width, null, "Import Normal Sprite", 16, null, null, () -> {
            cooldownMouse = 0.5;
            
            var _dialog = new FileDialog();
            _dialog.onSelect.add(loadNormal);
            _dialog.browse();
        }); ctnNormalMenu.addBody(btnNormal);

        var btnSave:UIButton = new UIButton(0, 0, ctnNormalMenu.display_width, null, "Save XML", 16, null, null, () -> {
            if (save_file != null) { return; }

            var _file_name:String = Normal_Image_Path.split("\\").pop();
            var _data:String = '<TextureAtlas imagePath="${_file_name}">\n\t<!-- Created with Magic XML Editor version 2.0 -->\n';
            for (_frame in normal.frames.frames) {
                _data += '\t<SubTexture ';
                _data += 'name="${_frame.name}" ';
                _data += 'x="${_frame.frame.x}" ';
                _data += 'y="${_frame.frame.y}" ';
                _data += 'width="${_frame.frame.width}" ';
                _data += 'height="${_frame.frame.height}" ';
                _data += 'frameX="${-_frame.offset.x}" ';
                _data += 'frameY="${-_frame.offset.y}" ';
                _data += 'frameWidth="${_frame.sourceSize.x}" ';
                _data += 'frameHeight="${_frame.sourceSize.y}"';
                _data += '/>\n';
            }
            _data += '</TextureAtlas>';
            
            save_file = new SaverFile([{name: _file_name.replace(".png", ".xml"), data: _data}], {destroyOnComplete: true, onComplete: ()->{save_file = null; }});
			save_file.saveFile();
        }); ctnNormalMenu.addBody(btnSave, 10);
        
        var ttlCurAnim = new FlxText(0, 5, ctnNormalMenu.display_width, "< - Current Animation - >", 18); ctnNormalMenu.addBody(ttlCurAnim, 10);
        ttlCurAnim.alignment = CENTER;
        
        lstNormalAnimations = new UIList(0, 0, ctnNormalMenu.display_width, 20); ctnNormalMenu.addBody(lstNormalAnimations);
        lstNormalAnimations.name = "NORMAL_ANIMATION";
        
        var lblCurFrame = new FlxText(0, 0, ctnNormalMenu.display_width, "Framerate:", 12); ctnNormalMenu.addBody(lblCurFrame, 0);
        sldNormalFrame = new UISlider(10, 0, 12, ctnNormalMenu.display_width - 20, 20, false, null, null, 0, 120);
        sldNormalFrame.callback = (_value) -> {
            normal.updateHitbox();
            normal.setPosition(initPoint.x + 3, initPoint.y + 3);
            middlePoint.setPosition(normal.getGraphicMidpoint().x - 3, normal.getGraphicMidpoint().y - 3);
            finalPoint.setPosition(normal.x + normal.width - 3, normal.y + normal.height - 3);
        };
        ctnNormalMenu.addBody(sldNormalFrame);
        
        var chkFlipX:UICheckBox = new UICheckBox(0, 0, ctnNormalMenu.display_width, "Flip X", 18, false, (_check)->{normal.flipX = _check; }); ctnNormalMenu.addBody(chkFlipX, 0);
        
        var chkFlipY:UICheckBox = new UICheckBox(0, 0, ctnNormalMenu.display_width, "Flip Y", 18, false, (_check)->{normal.flipY = _check; }); ctnNormalMenu.addBody(chkFlipY, 0);
    }
    
    var lstGhostAnimations:UIList;
    var sldGhostFrame:UISlider;
    private function addGhostMenuStuff():Void {
        var ttlFiles = new FlxText(0, 5, ctnGhostMenu.display_width, "< - Files - >", 20); ctnGhostMenu.addBody(ttlFiles, 10);
        ttlFiles.alignment = CENTER;

        var btnGhost:UIButton = new UIButton(0, 0, ctnGhostMenu.display_width, null, "Import Ghost Sprite", 16, null, null, () -> {
            var _dialog = new FileDialog();
            _dialog.onSelect.add(loadGhost);
            _dialog.browse();
        }); ctnGhostMenu.addBody(btnGhost);
        
        var ttlCurAnim = new FlxText(0, 5, ctnGhostMenu.display_width, "< - Current Animation - >", 18); ctnGhostMenu.addBody(ttlCurAnim, 10);
        ttlCurAnim.alignment = CENTER;
        
        lstGhostAnimations = new UIList(0, 0, ctnGhostMenu.display_width, 20); ctnGhostMenu.addBody(lstGhostAnimations);
        lstGhostAnimations.name = "GHOST_ANIMATION";
        
        var lblCurFrame = new FlxText(0, 0, ctnGhostMenu.display_width, "Framerate:", 12); ctnGhostMenu.addBody(lblCurFrame, 0);
        sldGhostFrame = new UISlider(10, 0, 12, ctnGhostMenu.display_width - 20, 20, false, null, null, 0, 120);
        ctnGhostMenu.addBody(sldGhostFrame);
        
        var chkFlipX:UICheckBox = new UICheckBox(0, 0, ctnGhostMenu.display_width, "Flip X", 18, false, (_check)->{ghost.flipX = _check; }); ctnGhostMenu.addBody(chkFlipX, 0);
        
        var chkFlipY:UICheckBox = new UICheckBox(0, 0, ctnGhostMenu.display_width, "Flip Y", 18, false, (_check)->{ghost.flipY = _check; }); ctnGhostMenu.addBody(chkFlipY, 0);
        
        var lblAlpha = new FlxText(0, 0, ctnGhostMenu.display_width, "Alpha:", 12); ctnGhostMenu.addBody(lblAlpha, 0);
        var lstAlpha = new UISlider(10, 0, 12, ctnGhostMenu.display_width - 20, 20, false, ghost, "alpha", 0, 1); ctnGhostMenu.addBody(lstAlpha);
        lstAlpha.decimals = 1;
    }

    public function addOffset(_x:Int, _y:Int):Void {
        switch (lstPosMode.getSelectedLabel()) {
            case "Frame":{
                if (normal.animation.curAnim == null) { return; }
                var _frame = normal.frames.frames[normal.animation.curAnim.frames[normal.animation.curAnim.curFrame]];
                _frame.offset.x -= _x;
                _frame.offset.y -= _y;
                
                var _curFrame = normal.animation.curAnim.curFrame;
                normal.animation.play(lstNormalAnimations.getSelectedLabel()); 
                normal.animation.pause();
                normal.animation.curAnim.curFrame = _curFrame;
            }
            case "Animation":{
                if (normal.animation.curAnim == null) { return; }
                for (_index in normal.animation.curAnim.frames) {
                    var _frame = normal.frames.frames[_index];
                    _frame.offset.x -= _x;
                    _frame.offset.y -= _y;
                }
                
                var _curFrame = normal.animation.curAnim.curFrame;
                normal.animation.play(lstNormalAnimations.getSelectedLabel()); 
                normal.animation.pause();
                normal.animation.curAnim.curFrame = _curFrame;
            }
            case "Sprite":{
                for (_animation in normal.animation.getNameList()) {
                    for (_index in normal.animation.getByName(_animation).frames) {
                        var _frame = normal.frames.frames[_index];
                        _frame.offset.x -= _x;
                        _frame.offset.y -= _y;
                    }
                }
                
                var _curFrame = normal.animation.curAnim.curFrame;
                normal.animation.play(lstNormalAnimations.getSelectedLabel()); 
                normal.animation.pause();
                normal.animation.curAnim.curFrame = _curFrame;
            }
        }
    }

    private function loadNormal(_path:String):Void {
        if (!_path.endsWith(".png")) {trace("File is Not PNG"); return; }

        Normal_Image_Path = _path;
        Normal_Atlas_Path = _path.replace(".png", ".xml");
        var _animations:Array<String> = Normal_Atlas_Path.getXMLAnimations();

        icon.loadGraphic(Normal_Image_Path);
        icon.setGraphicSize(Std.int(FlxG.height / 8), Std.int(FlxG.height / 8));
        icon.updateHitbox();

        normal.frames = _path.getSparrowAtlas();
        for (_anim in _animations) {normal.animation.addByPrefix(_anim, _anim, 24, false); }

        camFollow.setPosition(normal.getGraphicMidpoint().x, normal.getGraphicMidpoint().y);

        lstNormalAnimations.setData(_animations);
        lstNormalAnimations.setIndex();
    }
    private function loadGhost(_path:String):Void {
        if (!_path.endsWith(".png")) {trace("File is Not PNG"); return; }

        Ghost_Image_Path = _path;
        Ghost_Atlas_Path = _path.replace(".png", ".xml");
        var _animations:Array<String> = Ghost_Atlas_Path.getXMLAnimations();

        ghost.frames = _path.getSparrowAtlas();
        for (_anim in _animations) {ghost.animation.addByPrefix(_anim, _anim, 24, false); }
        
        lstGhostAnimations.setData(_animations);
        lstGhostAnimations.setIndex();
        
        ghost.setPosition(initPoint.x + 3, initPoint.y + 3);
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
        if (id == UIList.CHANGE_EVENT && (sender is UIList)) {
            var nums:UIList = cast sender;
            var wname = nums.name;

            switch (wname) {
                default:{trace('${wname} is Working!'); }
                case "NORMAL_ANIMATION":{
                    normal.animation.play(nums.getSelectedLabel()); 
                    normal.animation.pause();
                    var _anim = normal.animation.curAnim;
                    if (_anim == null) { return; }

                    sldNormalFrame.maxValue = _anim.frames.length - 1;
                    sldNormalFrame._object = _anim;
                    sldNormalFrame.varString = "curFrame";

                    normal.updateHitbox();
                    normal.setPosition(initPoint.x + 3, initPoint.y + 3);
                    middlePoint.setPosition(normal.getGraphicMidpoint().x - 3, normal.getGraphicMidpoint().y - 3);
                    finalPoint.setPosition(normal.x + normal.width - 3, normal.y + normal.height - 3);
                }
                case "GHOST_ANIMATION":{
                    ghost.animation.play(nums.getSelectedLabel()); 
                    ghost.animation.pause();
                    var _anim = ghost.animation.curAnim;
                    if (_anim == null) { return; }
                    sldGhostFrame.maxValue = _anim.frames.length - 1;
                    sldGhostFrame._object = _anim;
                    sldGhostFrame.varString = "curFrame";
                }
            }
        }
    }
}
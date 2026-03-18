package states;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIButton;
import flixel.input.mouse.FlxMouse;
import flixel.effects.FlxFlicker;
import flixel.util.FlxGradient;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import io.newgrounds.NG;
import flixel.FlxCamera;
import utils.Magic;
import flixel.FlxG;
import haxe.Json;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class CreditsState extends MusicBeatState {
    var credits_stuff:Map<String, Array<Dynamic>> = [];
	var credits_lists:Array<Dynamic> = [];

	var background:FlxSprite;

	var alphaGroup:FlxTypedGroup<Alphabet>;
	var descalpha:Alphabet;

	var curCredit:Int = 0;

	override function create() {
		FlxG.mouse.visible = false;

        for (file in Paths.readFile('assets/data/credits.json')) {
            var file_content:DynamicAccess<Dynamic> = file.getJson();
            for (key in file_content.keys()) {
				if (credits_stuff.exists(key)) {
					for (i in cast(file_content.get(key), Array<Dynamic>)) {
						credits_stuff.get(key).push(i);
					}
				} else {
					credits_stuff.set(key, file_content.get(key));
				}
			}
        }

		#if desktop
		// Updating Discord Rich Presence
		Discord.change("In the credits", null);
		Magic.setWindowTitle('In the credits');
		#end
		
		background = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		background.setGraphicSize(FlxG.width, FlxG.height);
		background.scrollFactor.set(0, 0);
        background.color = 0xfffffd75;
		background.screenCenter();
		add(background);

		alphaGroup = new FlxTypedGroup<Alphabet>();

		var cur_height:Float = 0;
		for (cat in credits_stuff.keys()) {
			var alpha_cat:Alphabet = new Alphabet(0, cur_height, [{bold: true, scale: 0.7, text: cat}]);
			alpha_cat.screenCenter(X);
			alphaGroup.add(alpha_cat);

			credits_lists.push(
				{
					text: cat,
					skip: true
				}
			);

			cur_height += alpha_cat.height + 10;

			for (credit in credits_stuff[cat]) {
				var path_icon:String = 'credits/${credit.Icon}';
				if (!Paths.exists(Paths.image(path_icon))) {path_icon = "credits/face"; }
				var path_rol_icon:String = 'credits/${credit.Role}';

				var list_credit:Array<Dynamic> = [{color: 0x000000, scale: 0.7, text: ' ${credit.Name} '}, {image: path_icon, size: [0, 70]}];
				if (Paths.exists(Paths.image(path_rol_icon))) {list_credit.unshift({image: path_rol_icon, size: [0, 70]}); }

				var cur_credit_alp:Alphabet = new Alphabet(0, cur_height, list_credit);
				cur_credit_alp.screenCenter(X);
				alphaGroup.add(cur_credit_alp);

				cur_height += cur_credit_alp.height + 5;

				credits_lists.push(
					{
						text: credit.Name,
						color: credit.Color,
						icon: credit.Icon,
						desc: credit.Description,
						rol: credit.Role
					}
				);
			}
		}

		add(alphaGroup);
		
        var shape_1:FlxSprite = new FlxSprite(0, FlxG.height - 60).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(shape_1);
        var shape_2:FlxSprite = new FlxSprite(0, FlxG.height - 50).makeGraphic(FlxG.width, 50, FlxColor.BLACK); add(shape_2);

		descalpha = new Alphabet(0, 0, []); add(descalpha);

		changeCredit();

		super.create();
	}

	override function update(elapsed:Float):Void {
		Magic.sortMembersByY(cast alphaGroup, (FlxG.height / 2) - (alphaGroup.members[curCredit].height / 2), curCredit, 50);

		if (canControlle) {
			if (controls.check("MenuUp", JUST_PRESSED)) {changeCredit(-1); }
			if (controls.check("MenuDown", JUST_PRESSED)) {changeCredit(1); }
		}
		
        super.update(elapsed);
	}


	var cur_tween_color:FlxTween;
	function changeCredit(value:Int = 0, force:Bool = false):Void {
		curCredit += value; if (force) {curCredit = value; }

		if (curCredit >= alphaGroup.length) {curCredit = 0; }
		if (curCredit < 0) {curCredit = alphaGroup.length - 1; }

		for (i in 0...alphaGroup.members.length) {
			alphaGroup.members[i].alpha = 0.5;
			if (credits_lists[i].skip) {alphaGroup.members[i].alpha = 1; }
		}
		alphaGroup.members[curCredit].alpha = 1;

		var cur_data:Dynamic = credits_lists[curCredit];
		if (cur_data == null) { return; }

		if (cur_data.skip) {
			if (value == 0) {value = 1; }
			changeCredit(value);
			return;
		}

		descalpha.cur_data = [{text: cur_data.desc, scale: 0.5, bold: false, animated: true}]; descalpha.loadText();
		descalpha.y = FlxG.height - descalpha.height - 10; descalpha.screenCenter(X);

		if (cur_tween_color != null) {cur_tween_color.cancel(); }
		cur_tween_color = FlxTween.color(background, 0.5, background.color, FlxColor.fromString(cur_data.color), {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {cur_tween_color = null; }});
	}
}
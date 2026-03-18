import flixel.group.FlxTypedGroup;
import objects.notes.StrumLine;
import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;
import flixel.FlxG;
import haxe.Timer;
import Math;
import Type;
import Std;

preset("camP_1", [480, -3000]);
preset("camP_2", [970, 530]);
preset("initChar", 10);
preset("zoom", 0.9);

var tanksGroup:FlxTypedGroup<FlxSprite>;
var shootStrumLine:Strumline;

var tankAngle:Float = FlxG.random.int(-90, 45);
var tankSpeed:Float = FlxG.random.float(5, 7);

var background:FlxSprite = null;
var clouds:FlxSprite = null;
var mountains:FlxSprite = null;
var buildings:FlxSprite = null;
var ruins:FlxSprite = null;
var smokeLeft:FlxSprite = null;
var smokeRight:FlxSprite = null;
var watchtower:FlxSprite = null;
var tankrolling:FlxSprite = null;
var ground:FlxSprite = null;
var tank0:FlxSprite = null;
var tank1:FlxSprite = null;
var tank2:FlxSprite = null;
var tank4:FlxSprite = null;
var tank5:FlxSprite = null;
var tank3:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/sky')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/clouds')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/mountains')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/ruins')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/ruins1')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/smokeleft')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/smokeright')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/watchtower')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/rolltank')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/ground')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/tank0')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/tank3')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/tank1')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/tank2')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/tank5')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/war/tank3')});
}

function create():Void {
	background = new FlxSprite(-250, -250);
	background.loadGraphic(Files.getGraphic(Paths.image('stages/war/sky')));
	background.scale.set(1, 1);
	background.updateHitbox();
	background.scrollFactor.set(0, 0);
	push(background);

	clouds = new FlxSprite(-500, 150);
	clouds.scrollFactor.set(0.1, 0.1);
	clouds.loadGraphic(Files.getGraphic(Paths.image('stages/war/clouds')));
	push(clouds);

	mountains = new FlxSprite(-400, 100);
	mountains.scrollFactor.set(0.2, 0.2);
	mountains.loadGraphic(Files.getGraphic(Paths.image('stages/war/mountains')));
	push(mountains);

	buildings = new FlxSprite(-200, 130);
	buildings.scrollFactor.set(0.3, 0.3);
	buildings.loadGraphic(Files.getGraphic(Paths.image('stages/war/ruins')));
	push(buildings);

	ruins = new FlxSprite(-180, 500);
	ruins.scrollFactor.set(0.4, 0.4);
	ruins.loadGraphic(Files.getGraphic(Paths.image('stages/war/ruins1')));
	push(ruins);

	smokeLeft = new FlxSprite(0, 0);
	smokeLeft.scrollFactor.set(0.4, 0.4);
	smokeLeft.frames = Files.getAtlas(Paths.image('stages/war/leftsmoke'));
	smokeLeft.animation.addByPrefix('idle', 'SmokeBlurLeft');
	if (Settings.get('Animated', 'GraphicSettings')) { smokeLeft.animation.play('idle'); }
	push(smokeLeft);

	smokeRight = new FlxSprite(900, 0);
	smokeRight.scrollFactor.set(0.4, 0.4);
	smokeRight.frames = Files.getAtlas(Paths.image('stages/war/rightsmoke'));
	smokeRight.animation.addByPrefix('idle', 'SmokeRight');
	if (Settings.get('Animated', 'GraphicSettings')) { smokeRight.animation.play('idle'); }
	push(smokeRight);

	watchtower = new FlxSprite(100, 50);
	watchtower.scrollFactor.set(0.5, 0.5);
	watchtower.frames = Files.getAtlas(Paths.image('stages/war/watchtower'));
	watchtower.animation.addByPrefix('idle', 'watchtower gradient color');
	if (Settings.get('Animated', 'GraphicSettings')) { watchtower.animation.play('idle'); }
	push(watchtower);

	tankrolling = new FlxSprite(300, 300);
	tankrolling.scrollFactor.set(0.5, 0.5);
	tankrolling.frames = Files.getAtlas(Paths.image('stages/war/rolltank'));
	tankrolling.animation.addByPrefix('idle', 'BG tank w lighting instance 1');
	if (Settings.get('Animated', 'GraphicSettings')) { tankrolling.animation.play('idle'); }
	push(tankrolling);

	tanksGroup = Type.createInstance(FlxTypedGroup, []);
	push(tanksGroup);

	ground = new FlxSprite(-450, 550);
	ground.loadGraphic(Files.getGraphic(Paths.image('stages/war/ground')));
	push(ground);

	tank0 = new FlxSprite(-500, 700);
	tank0.frames = Files.getAtlas(Paths.image('stages/war/tank0'));
	tank0.animation.addByPrefix('idle', 'fg');
	if (Settings.get('Animated', 'GraphicSettings')) { tank0.animation.play('idle'); }
	tank0.scrollFactor.set(1.7, 1.5);
	push(tank0);

	tank1 = new FlxSprite(-300, 740);
	tank1.frames = Files.getAtlas(Paths.image('stages/war/tank3'));
	tank1.animation.addByPrefix('idle', 'fg');
	if (Settings.get('Animated', 'GraphicSettings')) { tank1.animation.play('idle'); }
	tank1.scrollFactor.set(2, 0.2);
	push(tank1);

	tank2 = new FlxSprite(450, 940);
	tank2.frames = Files.getAtlas(Paths.image('stages/war/tank1'));
	tank2.animation.addByPrefix('idle', 'foreground');
	if (Settings.get('Animated', 'GraphicSettings')) { tank2.animation.play('idle'); }
	tank2.scrollFactor.set(1.5, 1.5);
	push(tank2);

	tank4 = new FlxSprite(1300, 900);
	tank4.frames = Files.getAtlas(Paths.image('stages/war/tank2'));
	tank4.animation.addByPrefix('idle', 'fg');
	if (Settings.get('Animated', 'GraphicSettings')) { tank4.animation.play('idle'); }
	tank4.scrollFactor.set(1.5, 1.5);
	push(tank4);

	tank5 = new FlxSprite(1620, 700);
	tank5.frames = Files.getAtlas(Paths.image('stages/war/tank5'));
	tank5.animation.addByPrefix('idle', 'fg');
	if (Settings.get('Animated', 'GraphicSettings')) { tank5.animation.play('idle'); }
	tank5.scrollFactor.set(1.5, 1.5);
	push(tank5);

	tank3 = new FlxSprite(1000, 740);
	tank3.frames = Files.getAtlas(Paths.image('stages/war/tank3'));
	tank3.animation.addByPrefix('idle', 'fg');
	if (Settings.get('Animated', 'GraphicSettings')) { tank3.animation.play('idle'); }
	tank3.scrollFactor.set(2, 0.3);
	push(tank3);

	setGlobal();
}

function preload():Void {
    shootStrumLine = strums.members[2];
    if (!Settings.get('Animated', 'GraphicSettings')) { return; }
    if (shootStrumLine == null) { return; }

    for (n in shootStrumLine.notelist) {  
        if (!FlxG.random.bool(16)) { continue; }
        
        var new_tank:FlxSprite = new FlxSprite(500, 200 + FlxG.random.int(50, 100));
        new_tank.flipX = n.noteData == 0;
        
		new_tank.frames = Files.getAtlas(Paths.image('walk_tank', 'stages/war'));
		new_tank.animation.addByPrefix('run', 'tankman running', 24, true);
		new_tank.animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		new_tank.animation.play('run');
		new_tank.animation.curAnim.curFrame = FlxG.random.int(0, new_tank.animation.curAnim.frames.length - 1);

		new_tank.updateHitbox();
		new_tank.setGraphicSize(Std.int(0.8 * new_tank.width));
		new_tank.updateHitbox();
        
		new_tank._.endingOffset = FlxG.random.float(50, 200);
		new_tank._.tankSpeed = FlxG.random.float(0.6, 1);
		new_tank._.strumTime = n.strumTime;

        new_tank._.update = function(elpased:Float) {
            new_tank.visible = (new_tank.x > -0.5 * FlxG.width && new_tank.x < 1.2 * FlxG.width);

            if (new_tank.animation.curAnim.name == "run") {
                var speed:Float = (conductor.position - new_tank._.strumTime) * new_tank._.tankSpeed;
                
                if (new_tank.flipX) {new_tank.x = (0.02 * FlxG.width - new_tank._.endingOffset) + speed; }
                else{new_tank.x = (0.74 * FlxG.width + new_tank._.endingOffset) - speed; }
            } else if (new_tank.animation.curAnim.finished) {
                new_tank.kill();
				Timer.delay(function() {new_tank.destroy(); }, 500);
            }
    
            if (conductor.position > new_tank._.strumTime) {
                new_tank.animation.play('shot');
                if (new_tank.flipX) { new_tank.offset.x = 300; new_tank.offset.y = 200; }
            }            
        }

        tanksGroup.add(new_tank);
    }
}

function beatHit(curBeat:Int):Void {
	if (!Settings.get('Animated', 'GraphicSettings')) { return; }
	
    watchtower.animation.play('idle');
    tank0.animation.play('idle');
    tank1.animation.play('idle');
    tank2.animation.play('idle');
    tank3.animation.play('idle');
    tank4.animation.play('idle');
    tank5.animation.play('idle');
}

function update(elapsed) {
    if (!Settings.get('Animated', 'GraphicSettings')) { return; }

    tankAngle += elapsed * tankSpeed;
    tankrolling.angle = tankAngle - 90 + 15;
    tankrolling.x = 400 + (1000 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180)));
    tankrolling.y = 700 + (500 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180)));
}
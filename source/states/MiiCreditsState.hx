package states;

import states.MainMenuState.StarChecker;
import objects.WiiCustomText;
import states.MainMenuState.WiiUIBox;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import flixel.FlxObject;

typedef MiiCreditData = {
    var name:String;
    var mii:String;
    var miiOffset:Array<Float>;
    var miiPoseOffset:Array<Float>;
    var ?miiScale:Float;
    var ?miiPoseScale:Float;
    var desc:String;
    var categories:Array<String>;
}

typedef MiiCreditsFile = {
    var credits:Array<MiiCreditData>;
}

class MiiCreditsState extends MusicBeatState
{
    var credits:MiiCreditsFile;
    var miis:FlxTypedGroup<Mii>;
    var miiHoverBoxes:FlxTypedGroup<FlxSprite>;
    var buttons:Array<MiiMenuButton> = [];
    var lastCategory:String = "";
    var fade:FlxSprite;

    var miiCountText:WiiCustomText;

    var descBox:FlxSprite = null;
    var descText:WiiCustomText = null;
    function removeDesc() {
        if (descBox != null) {
            descBox.destroy();
            remove(descBox);
        }
        if (descText != null) {
            descText.destroy();
            remove(descText);
        }
    }

    function doDesc(miiName:String, desc:String) {
        removeDesc();
        descBox = new WiiUIBox();
		descBox.loadGraphic(Paths.image("wiimenu/wiiUISlice"));
		//hoverBG.scale.y = 0.5;
		descText = new WiiCustomText(0, 20, 900, miiName + "\n" + desc, 1, "wii");
		descText.color = 0xFF858585;
        if (miiName == "TheOnlyVolume") descText.size = 0.5;
        descText.regenText(true);
        descText.width = descText.fieldWidth;
        descText.screenCenter(X);

		descBox.setGraphicSize(descText.width + 40, descText.height + 20);
		descBox.updateHitbox();

        descBox.x = descText.x + (descText.width/2) - (descBox.width/2);
		descBox.y = descText.y + (descText.height/2) - (descBox.height/2);

        add(descBox);
        add(descText);
    }

    override function create()
    {
        #if DISCORD_ALLOWED
        // Updating Discord Rich Presence
        DiscordClient.changePresence("In the Menus", null);
        #end

        allowMouseControlWithKeys = true;

        var bg = new FlxSprite().loadGraphic(Paths.image('wiimenu/credits/creditsBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);
        bg.setGraphicSize(1280);
        bg.updateHitbox();
        bg.screenCenter();

        miiCountText = new WiiCustomText(125-25, 630, 100, "74", 1.5);
        miiCountText.shader = new MiiChannelTextShader();

        miis = new FlxTypedGroup<Mii>();
        miiHoverBoxes = new FlxTypedGroup<FlxSprite>();
        reloadMiis(true);

        add(miis);
        add(miiHoverBoxes);

        fade = new FlxSprite().makeGraphic(1,1,0xFF000000);
        fade.setGraphicSize(1280,720);
        fade.updateHitbox();
        add(fade);
        fade.alpha = 0;

        var exitButton = new MiiMenuButton(40, 30);
        exitButton.antialiasing = ClientPrefs.data.antialiasing;
        exitButton.loadGraphic(Paths.image('wiimenu/credits/creditsBack'));
        exitButton.onClick = function() {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MainMenuState());
            quitting = true;
            for (item in buttons) item.selected = false;
        };
        buttons.push(exitButton);
        add(exitButton);

        var creditsPopupButton = new MiiMenuButton(40, 30 + 140);
        creditsPopupButton.antialiasing = ClientPrefs.data.antialiasing;
        creditsPopupButton.loadGraphic(Paths.image('wiimenu/credits/creditsButton'));
        creditsPopupButton.onClick = function() {
            openSubState(new CreditsPopupSubstate());
            persistentUpdate = false;
            for (item in buttons) item.selected = false;
        };
        buttons.push(creditsPopupButton);
        add(creditsPopupButton);

        var memberCount = new MiiMenuButton(100, 590);
        memberCount.antialiasing = ClientPrefs.data.antialiasing;
        memberCount.loadGraphic(Paths.image('wiimenu/credits/creditsMemberCount'));
        memberCount.onClick = function() {
            trace("clicky");
        };
        buttons.push(memberCount);
        add(memberCount);

		//miiCountText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF374244);
        //miiCountText.borderSize = 2;
        add(miiCountText);

        var whistle = new MiiMenuButton(260, 590);
        whistle.antialiasing = ClientPrefs.data.antialiasing;
        whistle.loadGraphic(Paths.image('wiimenu/credits/creditsWhistle'));
        whistle.onClick = function() {
            transitioning = true;
            FlxTween.tween(fade, {alpha: 1}, 0.5);
            new FlxTimer().start(0.5, function(tmr) {
                reloadMiis();
                transitioning = false;
                FlxTween.tween(fade, {alpha: 0}, 0.5);
            });
        };
        buttons.push(whistle);
        add(whistle);

        var composers = new MiiMenuButton(910-(170*3), 590);
        composers.antialiasing = ClientPrefs.data.antialiasing;
        composers.loadGraphic(Paths.image('wiimenu/credits/creditsMusicians'));
        composers.onClick = function() {
            transitioning = true;
            FlxTween.tween(fade, {alpha: 1}, 0.5);
            new FlxTimer().start(0.5, function(tmr) {
                reloadMiis(false, "Musicians");
                transitioning = false;
                FlxTween.tween(fade, {alpha: 0}, 0.5);
            });
        };
        buttons.push(composers);
        add(composers);

        var artists = new MiiMenuButton(910-(170*2), 590);
        artists.antialiasing = ClientPrefs.data.antialiasing;
        artists.loadGraphic(Paths.image('wiimenu/credits/creditsArtists'));
        artists.onClick = function() {
            transitioning = true;
            FlxTween.tween(fade, {alpha: 1}, 0.5);
            new FlxTimer().start(0.5, function(tmr) {
                reloadMiis(false, "Artists");
                transitioning = false;
                FlxTween.tween(fade, {alpha: 0}, 0.5);
            });
        };
        buttons.push(artists);
        add(artists);

        var charters = new MiiMenuButton(910-170, 590);
        charters.antialiasing = ClientPrefs.data.antialiasing;
        charters.loadGraphic(Paths.image('wiimenu/credits/creditsCharters'));
        charters.onClick = function() {
            transitioning = true;
            FlxTween.tween(fade, {alpha: 1}, 0.5);
            new FlxTimer().start(0.5, function(tmr) {
                reloadMiis(false, "Charters");
                transitioning = false;
                FlxTween.tween(fade, {alpha: 0}, 0.5);
            });
        };
        buttons.push(charters);
        add(charters);

        var coders = new MiiMenuButton(910, 590);
        coders.antialiasing = ClientPrefs.data.antialiasing;
        coders.loadGraphic(Paths.image('wiimenu/credits/creditsCoders'));
        coders.onClick = function() {
            transitioning = true;
            FlxTween.tween(fade, {alpha: 1}, 0.5);
            new FlxTimer().start(0.5, function(tmr) {
                reloadMiis(false, "Coders");
                transitioning = false;
                FlxTween.tween(fade, {alpha: 0}, 0.5);
            });
        };
        buttons.push(coders);
        add(coders);

        var directors = new MiiMenuButton(1080, 590);
        directors.antialiasing = ClientPrefs.data.antialiasing;
        directors.loadGraphic(Paths.image('wiimenu/credits/creditsDirectors'));
        directors.onClick = function() {
            transitioning = true;
            FlxTween.tween(fade, {alpha: 1}, 0.5);
            new FlxTimer().start(0.5, function(tmr) {
                reloadMiis(false, "Directors");
                transitioning = false;
                FlxTween.tween(fade, {alpha: 0}, 0.5);
            });
        };
        buttons.push(directors);
        add(directors);


        super.create();        
    }

    var quitting:Bool = false;
    var selectedMii:Mii = null;
    var transitioning:Bool = false;
    override function update(elapsed:Float)
    {
        if (FlxG.sound.music.volume < 0.7)
        {
            FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
        }

        if(!quitting)
        {
            if (controls.BACK)
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
                quitting = true;
                for (item in buttons) item.selected = false;
                return;
            }

            if (transitioning) return;

            if (FlxG.keys.justPressed.F5) reloadMiis(true);

            if (FlxG.mouse.justPressed || controls.ACCEPT) {
                if (selectedMii != null) selectedMii.selected = false;
                removeDesc();
            }

            var hoveringMii:Bool = false;

            for (item in buttons)
            {
                if (FlxG.mouse.overlaps(item))
                {
                    hoveringMii = true;
                    if (!item.selected)
                    {
                        FlxG.sound.play(Paths.sound('wiiOptionHover'));
                        item.selected = true;
                    }
                }
                else
                {
                    item.selected = false;
                }
            }

            for (i in 0...miis.members.length) {
                var mii = miis.members[(-i + miis.members.length)-1];

                //only allow one mii to be hovered at once
                if (!hoveringMii) {
                    mii.inputCheck();
                    if (mii.hoverTime > 0) hoveringMii = true;

                    if (hoveringMii && (FlxG.mouse.justPressed || controls.ACCEPT)) {
                        mii.selected = true;
                        selectedMii = mii;

                        doDesc(mii.data.name, mii.data.desc);
                    }
                } else {
                    mii.hoverTime = 0;
                    mii.playedHoverSound = false;
                }
            }
        }

        super.update(elapsed);
    }

    function reloadMiis(reloadJson:Bool = false, ?category:String = null) {
        if (reloadJson) credits = cast Json.parse(Paths.getTextFromFile("data/miiCredits.json"));

        var catName = category == null ? "" : category;
        if (!reloadJson && lastCategory == catName) return;
        

        miiHoverBoxes.clear();
        miis.clear();

        var list:Array<MiiCreditData> = [];
        for (member in credits.credits) {
            if (category == null) {
                list.push(member);
            } else {
                if (member.categories.contains(category)) {
                    list.push(member);
                }
            }
        }

        miiCountText.text = Std.string(list.length);

        rowIndex = 0;
        colIndex = 0;
        miisLeftToAdd = list.length;
        remainingMiis = miisLeftToAdd;
        for (member in list) {
            addMii(member, 11);
            miisLeftToAdd--;
        }
        selectedMii = null;
        lastCategory = catName;
    }

    var rowIndex:Int = 0;
    var colIndex:Int = 0;
    var miisLeftToAdd:Int = 0;
    var remainingMiis:Int = 11;
    private function addMii(data:MiiCreditData, rowMax:Int) {

        var mii = new Mii(640, 280, data);
        miis.add(mii);
        miiHoverBoxes.add(mii.hoverBG);
        miiHoverBoxes.add(mii.hoverText);

        var rowLen = (rowIndex % 2 == 0 ? rowMax : rowMax+1);
        if (remainingMiis < rowLen) rowLen = remainingMiis;

        mii.y += rowIndex * 80;
        mii.x += colIndex * 80;
        mii.x -= (rowLen/2) * 80;

        colIndex++;
        if (colIndex > rowLen) {
            rowIndex++;
            colIndex = 0;
            remainingMiis = miisLeftToAdd-2;
        }
    }
}

class Mii extends FlxObject {
    var mii:FlxSprite;
    var miiPose:FlxSprite;
    var shadow:FlxSprite;
    public var data:MiiCreditData;

    var hitbox:FlxSprite;
    public var selected:Bool = false;
    override public function new(x:Float, y:Float, data:MiiCreditData) {
        super(x, y);
        this.data = data;
        mii = new FlxSprite().loadGraphic(Paths.image("wiimenu/credits/miis/"+data.mii));
        miiPose = new FlxSprite().loadGraphic(Paths.image("wiimenu/credits/miis/"+data.mii+"-pose"));
        shadow = new FlxSprite().loadGraphic(Paths.image("wiimenu/credits/mii_shadow"));
        mii.antialiasing = miiPose.antialiasing = shadow.antialiasing = ClientPrefs.data.antialiasing;
        if (data.miiScale != null) mii.scale.set(data.miiScale, data.miiScale);
        if (data.miiPoseScale != null) miiPose.scale.set(data.miiPoseScale, data.miiPoseScale);
        shadow.scale.set(0.8,0.8);
        mii.updateHitbox();
        miiPose.updateHitbox();
        shadow.updateHitbox();

        hitbox = new FlxSprite().makeGraphic(1,1,0xFFFF0000);
        hitbox.setGraphicSize(60, 140);
        hitbox.updateHitbox();
        hitbox.alpha = 0.5;

        setupHoverText(data.name, 0);
    }

    override public function destroy() {
        mii = FlxDestroyUtil.destroy(mii);
        miiPose = FlxDestroyUtil.destroy(miiPose);
        shadow = FlxDestroyUtil.destroy(shadow);
        hitbox = FlxDestroyUtil.destroy(hitbox);
        super.destroy();
    }

    override public function draw() {
        super.draw();

        hitbox.x = x - (hitbox.width/2);
        hitbox.y = y - (hitbox.height);
        //hitbox.draw();

        shadow.x = x - (shadow.width/2);
        shadow.y = y - (shadow.height/2);
        shadow.draw();

        if (!selected) {
            mii.x = x + (-mii.width/2) + data.miiOffset[0];
            mii.y = y + (-mii.height) + data.miiOffset[1];
            mii.draw();
        } else {
            miiPose.x = x + (-miiPose.width/2) + data.miiPoseOffset[0];
            miiPose.y = y + (-miiPose.height) + data.miiPoseOffset[1];
            miiPose.draw();
        }

        hoverText.x = x + (-hoverText.width/2);
        hoverText.y = -5 + hitbox.y - hoverText.height;

        hoverBG.x = hoverText.x + (hoverText.width/2) - (hoverBG.width/2);
		hoverBG.y = hoverText.y + (hoverText.height/2) - (hoverBG.height/2);
    }

    public var hoverBG:FlxSprite = null;
	public var hoverText:WiiCustomText = null;

	public var hoverTime:Float = 0;
	public var playedHoverSound:Bool = false;

    function setupHoverText(text:String, fieldWidth:Float = 0) {
		hoverBG = new WiiUIBox();
		hoverBG.loadGraphic(Paths.image("wiimenu/wiiUISlice"));
		//hoverBG.scale.y = 0.5;
		hoverText = new WiiCustomText(0, 0, fieldWidth, text, 1, "wii");
		hoverText.color = 0xFF858585;
        hoverText.regenText(true);
        //hoverText.width = hoverText.fieldWidth;

		hoverBG.setGraphicSize(hoverText.width + 40, hoverText.height + 20);
		hoverBG.updateHitbox();

        hoverBG.alpha = hoverText.alpha = 0;

		//hoverBG.alpha = 0;
		//hoverText.alpha = 0;
	}

    public function inputCheck() {
        if (FlxG.mouse.overlaps(hitbox)) {
            hoverTime += FlxG.elapsed;
        } else {
            hoverTime = 0;
        }

        if (hoverTime > 0) {

            if (hoverTime > 0.5) {
                hoverBG.alpha = hoverText.alpha = FlxMath.lerp(hoverBG.alpha, 1.0, 15*FlxG.elapsed);
                if (!playedHoverSound) {
                    FlxG.sound.play(Paths.sound("wiiHover"));
                    playedHoverSound = true;
                }
            }

        } else {
            hoverBG.alpha = hoverText.alpha = 0;
            playedHoverSound = false;
        }
    }
}

private class MiiMenuButton extends FlxSprite
{
	public var onClick:Void->Void;
	public var selected:Bool = false;

    public var doScaleOnHover:Bool = true;

	public function new(X:Float, Y:Float)
	{
		super(X, Y, null);
	}

	public var selectedScale = 1.05;
	public var unselectedScale = 1.0;

	override public function update(elapsed:Float)
	{
		if (selected)
		{
			if (doScaleOnHover)
			{
				scale.y = scale.x = FlxMath.lerp(scale.x, selectedScale, 15*elapsed);
			}
	
			if (FlxG.mouse.justPressed || Controls.instance.ACCEPT) {
				if (onClick != null) onClick();
                FlxG.sound.play(Paths.sound('wiiOptionSelect'));
			}
		}
		else
		{
			if (doScaleOnHover)
			{
				scale.y = scale.x = FlxMath.lerp(scale.x, unselectedScale, 15*elapsed);
			}
		}
        super.update(elapsed);
	}
}

class CreditsPopupSubstate extends MusicBeatSubstate {
    var popup:FlxSprite;
    var text:WiiCustomText;
    var buttons:Array<MiiMenuButton> = [];
	override public function new() {
		super();

        popup = new FlxSprite().loadGraphic(Paths.image("wiimenu/credits/creditsPopup"));
		popup.screenCenter();
		popup.antialiasing = ClientPrefs.data.antialiasing;
		add(popup);

        var beatshit = StarChecker.checkStar5();
        beatshit = true;

        text = new WiiCustomText(popup.x + 100, popup.y + 150, 1280, "Special thanks to kat21 and the\nMii Creator team!", 1.4);
        text.alignment = 'left';
        if (beatshit) text.text += "\n\n\n\n\nRewatch the end credits video?";
        text.shader = new MiiChannelTextShader();
        text.regenText(true);
        text.screenCenter(X);
        add(text);

        allowMouseControlWithKeys = true;

        if (!beatshit) {
            var yes = new MiiMenuButton(0, popup.y + 450);
            yes.loadGraphic(Paths.image("wiimenu/credits/creditsPopupButton"));
            yes.screenCenter(X);
            yes.doScaleOnHover = false;
            add(yes);

            yes.onClick = function() {
                for (item in buttons) item.selected = false;
                this._parentState.persistentUpdate = true;
				close();
            }

            var buttonText = new WiiCustomText(yes.x, yes.y + 50, yes.width, "Close", 1.75);
            buttonText.shader = new MiiChannelTextShader();
            buttonText.regenText(true);
            add(buttonText);

            buttons.push(yes);
        } else {

            {
                var yes = new MiiMenuButton(0, popup.y + 450);
                yes.loadGraphic(Paths.image("wiimenu/credits/creditsPopupButton"));
                yes.screenCenter(X);
                yes.x -= 220;
                yes.doScaleOnHover = false;
                add(yes);

                yes.onClick = function() {
                    for (item in buttons) item.selected = false;
                    this._parentState.persistentUpdate = true;
                    LoadingState.loadAndSwitchState(new EndCreditsState());
                }

                var buttonText = new WiiCustomText(yes.x, yes.y + 50, yes.width, "Yes", 1.75);
                buttonText.shader = new MiiChannelTextShader();
                buttonText.regenText(true);
                add(buttonText);

                buttons.push(yes);
            }

            {
                var no = new MiiMenuButton(0, popup.y + 450);
                no.loadGraphic(Paths.image("wiimenu/credits/creditsPopupButton"));
                no.screenCenter(X);
                no.x += 220;
                no.doScaleOnHover = false;
                add(no);

                no.onClick = function() {
                    for (item in buttons) item.selected = false;
                    this._parentState.persistentUpdate = true;
                    close();
                }

                var buttonText = new WiiCustomText(no.x, no.y + 50, no.width, "No", 1.75);
                buttonText.shader = new MiiChannelTextShader();
                buttonText.regenText(true);
                add(buttonText);

                buttons.push(no);
            }

        }

	}

	var exitTimer:Float = 0.5;
	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (exitTimer > 0) {
			exitTimer -= elapsed;
		} else {
			if (controls.BACK) {
				this._parentState.persistentUpdate = true;
				close();
                return;
			}
		}

        for (item in buttons)
        {
            if (FlxG.mouse.overlaps(item))
            {
                if (!item.selected)
                {
                    FlxG.sound.play(Paths.sound('wiiOptionHover'));
                    item.selected = true;
                }
            }
            else
            {
                item.selected = false;
            }
        }
	}
}
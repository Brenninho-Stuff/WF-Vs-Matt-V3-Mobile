package options;

import objects.WiiCustomText;
import lime.app.Application;
import options.WiiOption;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

import objects.CheckboxThingie;
import objects.AttachedText;
import options.Option;
import backend.InputFormatter;

import flixel.text.FlxText;

class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:FlxTypedGroup<WiiOption>;
	//private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	//private var grpTexts:FlxTypedGroup<AttachedText>;

	//private var descBox:FlxSprite;
	private var descText:WiiCustomText;

	public var title:String;
	public var rpcTitle:String;

	public var bgs:Array<FlxSprite> = [];

	var arrowLeft:WiiOption;
	var arrowRight:WiiOption;
	var curPage:Int = 0;

	var backButton:WiiOption;
	var confirmButton:WiiOption;

	public var confirmActive = false;

	public function new()
	{
		super();

		if(title == null) title = "Wii Funkin' Options";
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		for (i in ['optionsBG', 'optionsBorder', 'optionsVERSION'])
		{
			var bg = new FlxSprite().loadGraphic(Paths.image('wiimenu/options/'+i));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.updateHitbox();
			bg.screenCenter();
			bg.scrollFactor.set();
			add(bg);
			bg.alpha = 0; FlxTween.tween(bg, {alpha: 1}, 0.5);
			bgs.push(bg);
		}

		var titleText = new WiiCustomText(60, 50, 0, title, 2, 'wii');
		titleText.alignment = 'left';
		titleText.color = 0xFF000000;
		titleText.regenText(true);
		titleText.scrollFactor.set();
		titleText.alpha = 0; FlxTween.tween(titleText, {alpha: 1}, 0.5);
		add(titleText);
		bgs.push(titleText);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<WiiOption>();
		add(grpOptions);

		backButton = new WiiOption(0, 600, "Back", "wiiButton");
		backButton.screenCenter(X); 
		backButton.x -= 300;
		add(backButton);

		confirmButton = new WiiOption(0, 600, "Confirm", "wiiButton");
		confirmButton.screenCenter(X);
		confirmButton.x += 300;
		add(confirmButton);
		confirmButton.visible = confirmActive;

		descText = new WiiCustomText(50, 600, 1180, "", 1);
		descText.regenText(true);
		descText.scrollFactor.set();
		add(descText);

		arrowLeft = new WiiOption(0, 0, "", "wiiOptionsArrow");
		add(arrowLeft);
		arrowRight = new WiiOption(0, 0, "", "wiiOptionsArrow");
		add(arrowRight); 
		arrowRight.flipX = true;
		arrowLeft.screenCenter(); arrowLeft.x -= FlxG.width*0.25;
		arrowRight.screenCenter(); arrowRight.x += FlxG.width*0.25;

		if (optionsArray == null)
			optionsArray = [];

		for (i in 0...optionsArray.length)
		{
			var optionText:WiiOption = new WiiOption(290, 106+20, optionsArray[i].name);
			optionText.screenCenter(X);
			optionText.y += 110 * i % 4;
			optionText.x += Math.floor(i / 4) * FlxG.width;
			optionText.ID = i;
			grpOptions.add(optionText);
			optionText.alpha = 0; 
			if (i < 4)
				FlxTween.tween(optionText, {alpha: 1}, 0.5);
		}



		curSelected = 0;
		descText.text = "";
		curOption = null;
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	public var canCancel:Bool = true;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (doActuallyClose)
			return;

		/*if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}*/

		allowMouseControlWithKeys = true;

		if (controls.BACK && canCancel) {
			onCancel();
			close();
			FlxG.sound.play(Paths.sound('wiiBack'));
		}

		var maxPages:Int = Math.floor((grpOptions.members.length-1) / 4);
		arrowLeft.visible = curPage != 0;
		arrowRight.visible = curPage < maxPages;

		confirmButton.alpha = backButton.alpha = FlxMath.lerp(backButton.alpha, 1, elapsed*8);

		//mouse hover checks
		itemsUpdate();

		//update positions
		for (i in 0...grpOptions.members.length)
		{
			var optionText = grpOptions.members[i];

			var page = Math.floor(i / 4);
			var targetX:Float = 640 - (optionText.width*0.5);
			targetX += (page - curPage) * 640;

			optionText.x = FlxMath.lerp(optionText.x, targetX, elapsed*8);
			var targetAlpha:Float = curPage == page ? 1.0 : 0.0;
			optionText.alpha = FlxMath.lerp(optionText.alpha, targetAlpha, elapsed*8);
		}

		

		if (curOption == null)
			return;

		if(nextAccept <= 0)
		{
			selectItemCheck();
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function itemsUpdate()
	{
		var overlapAny = false;
		for (item in grpOptions.members)
		{
			if (FlxG.mouse.overlaps(item) && item.alpha > 0.9)
			{
				overlapAny = true;
				if (!item.selected)
				{
					FlxG.sound.play(Paths.sound('wiiOptionHover'));
					item.selected = true;
					curSelected = item.ID;
					changeSelection(0);
				}
			}
			else
			{
				item.selected = false;
			}
		}

		if (!overlapAny)
		{
			curSelected = 0;
			descText.text = "";
			curOption = null;
			confirmButton.visible = confirmActive;
			if (!backButton.visible)
				backButton.alpha = 0; //fade in
			backButton.visible = true;
		}

		for (item in [arrowLeft, arrowRight, backButton, confirmButton])
		{
			if (FlxG.mouse.overlaps(item) && item.visible)
			{
				if (!item.selected)
				{
					FlxG.sound.play(Paths.sound('wiiOptionHover'));
					item.selected = true;
				}

				if(controls.ACCEPT || FlxG.mouse.justPressed)
				{
					if (item == arrowLeft)
					{
						FlxG.sound.play(Paths.sound('wiiSelect'));
						curPage--;
					}
					else if (item == arrowRight)
					{
						FlxG.sound.play(Paths.sound('wiiSelect'));
						curPage++;
					}
						

					if (item == backButton)
					{
						onCancel();
						close();
						FlxG.sound.play(Paths.sound('wiiOptionCancel'), 0.7);
					}
					else if (item == confirmButton)
					{
						FlxG.sound.play(Paths.sound('wiiOptionSelect'), 0.7);
						onConfirm();
					}
				}
			}
			else
			{
				item.selected = false;
			}
		}
	}

	public function onConfirm()
	{
		//used in other substates!
	}

	public function onCancel() 
	{

	}

	public function selectItemCheck()
	{
		if(controls.ACCEPT || FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('wiiOptionSelect'));
			switch(curOption.type)
			{
				case "bool":
					openSubState(new WiiOptionSelectSubstate(curOption.name, ["On", "Off"], curOption.getValue() ? "On" : "Off", function(optionName)
					{
						curOption.setValue(optionName == "On");
						curOption.change();
					}));
				case "string":
					var num:Int = curOption.curOption;
					var name = curOption.options[num];
					openSubState(new WiiOptionSelectSubstate(curOption.name, curOption.options, name, function(optionName)
					{
						curOption.curOption = curOption.options.indexOf(optionName);
						curOption.setValue(optionName);
						curOption.change();
					}));
				case "int" | "float" | "percent":

					openSubState(new WiiOptionSliderSubstate(curOption.name, curOption, curOption.getValue(), function(value)
					{
						switch(curOption.type)
						{
							case 'int':
								curOption.setValue(Math.round(value));
							case 'float' | 'percent':
								curOption.setValue(FlxMath.roundDecimal(value, curOption.decimals));
						}
						curOption.change();
					}));
			}
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		else if (curSelected >= optionsArray.length)
			curSelected = 0;

		descText.text = optionsArray[curSelected].description;
		descText.y = 595;

		curOption = optionsArray[curSelected]; //shorter lol
		//FlxG.sound.play(Paths.sound('scrollMenu'));

		if (descText.text != "")
		{
			confirmButton.visible = false;
			backButton.visible = false;
		}

	}

	var doActuallyClose = false;
	override public function close()
	{
		if (doActuallyClose)
		{
			super.close();
			return;
		}

		doActuallyClose = true;
		this.persistentUpdate = false;

		for (item in grpOptions.members)
			FlxTween.tween(item, {alpha: 0}, 0.5);
		for (item in bgs)
			FlxTween.tween(item, {alpha: 0}, 0.5);
		for (item in [arrowLeft, arrowRight, backButton, confirmButton])
			FlxTween.tween(item, {alpha: 0}, 0.5);

		new FlxTimer().start(0.5, function(tmr)
		{
			close();
		});
	}
}
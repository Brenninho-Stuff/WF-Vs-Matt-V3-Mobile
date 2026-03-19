package options;

import objects.WiiCustomText;
import backend.Highscore;
import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Reset Progression'];
	private var grpOptions:FlxTypedGroup<WiiOption>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var backButton:WiiOption;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Reset Progression':
				var substate = new WiiOptionSelectSubstate("Are You Sure?", ["Reset", "Cancel"], "Cancel", function(optionName)
				{
					if (optionName == "Reset") {
						Highscore.weekCompletions.clear();
						Highscore.songCompletions.clear();
						FlxG.save.data.weekCompletions = Highscore.weekCompletions;
						FlxG.save.data.songCompletions = Highscore.songCompletions;
						FlxG.save.data.lettersRead = null;
						FlxG.save.data.seenBreakPopup = null;
						FlxG.save.flush();

						@:privateAccess
						MainMenuState.firstLoad = true;
						MusicBeatState.switchState(new states.MainMenuState());
					}
				}, function() {});
				
				openSubState(substate);
		}
	}

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		if (FlxG.save.data.corrupted != null && FlxG.save.data.corrupted) {
			options.remove("Reset Progression");
		}

		for (i in ['optionsBG', 'optionsBorder', 'optionsVERSION'])
		{
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('wiimenu/options/'+i));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.updateHitbox();
			bg.screenCenter();
			add(bg);
			bg.alpha = 0; FlxTween.tween(bg, {alpha: 1}, 1.0);
		}

		var titleText = new WiiCustomText(60, 50, 0, "Wii Funkin' Options", 2, 'wii');
		titleText.alignment = 'left';
		titleText.color = 0xFF000000;
		titleText.regenText(true);
		titleText.scrollFactor.set();
		titleText.alpha = 0; FlxTween.tween(titleText, {alpha: 1}, 0.5);
		add(titleText);

		FlxG.mouse.visible = true;
		allowMouseControlWithKeys = true;


		grpOptions = new FlxTypedGroup<WiiOption>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:WiiOption = new WiiOption(290, 106+20, options[i]);
			optionText.screenCenter(X);
			optionText.y += 110 * i % 4;
			if (Math.floor(i / 4) == 0)
				optionText.x -= 280;
			else
				optionText.x += 280;

			optionText.ID = i;
			grpOptions.add(optionText);
			optionText.alpha = 0; FlxTween.tween(optionText, {alpha: 1}, 0.5);
		}

		backButton = new WiiOption(0, 600, "Back", "wiiButton");
		backButton.screenCenter(X); 
		backButton.x -= 300;
		add(backButton);
		backButton.alpha = 0; FlxTween.tween(backButton, {alpha: 1}, 0.5);

		//changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (item in grpOptions.members)
		{
			if (FlxG.mouse.overlaps(item))
			{
				if (!item.selected)
				{
					FlxG.sound.play(Paths.sound('wiiOptionHover'));
					item.selected = true;
				}

				if((controls.ACCEPT || FlxG.mouse.justPressed) && !controls.BACK)
				{
					FlxG.sound.play(Paths.sound('wiiOptionSelect'), 0.7);
					openSelectedSubstate(item.text.text);
				}
			}
			else
			{
				item.selected = false;
			}
		}

		if (FlxG.mouse.overlaps(backButton) && backButton.alpha > 0.9)
		{
			if (!backButton.selected)
			{
				FlxG.sound.play(Paths.sound('wiiOptionHover'));
				backButton.selected = true;
			}
		}
		else
		{
			backButton.selected = false;
		}

		if (controls.BACK || (backButton.selected && (controls.ACCEPT || FlxG.mouse.justPressed))) {
			FlxG.sound.play(Paths.sound('wiiBack'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		//else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	/*function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}*/

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
package substates;

import objects.Note;
import states.MainMenuState;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.addons.transition.FlxTransitionableState;

import flixel.util.FlxStringUtil;

import states.StoryMenuState;
import states.FreeplayState;
import options.OptionsState;

import objects.StrumNote;

class WiiPauseSubState extends MusicBeatSubstate
{
	var pauseMusic:FlxSound;

    var bg:FlxSprite;
    var top:PauseOption;
    var bot:PauseOption;

    var menu:PauseOption;
    var reset:PauseOption;
    
    var wrench:FlxSprite;
    var settingsText:FlxSprite;

    var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;

    var notes:FlxTypedGroup<Note>;
    var unspawnNotes:Array<Note> = [];
    public static var loadedNotes:Array<Note> = [];
    static var song:SwagSong;
    var songSpeed:Float = 2;

    function loadPauseChart() {
        if (loadedNotes.length > 0) return; //already loaded

        if (song == null) song = Song.loadFromJson('pause', 'pause');
        var noteData = song.notes;

        //var tempCrochet = Conductor.crochet;
        //var tempStepCrochet = Conductor.stepCrochet;

        //Conductor.crochet = Conductor.calculateCrochet(song.bpm);
		//Conductor.stepCrochet = Conductor.crochet / 4;

        var lastND:Int = -1;
        for (section in noteData)
        {
            for (songNotes in section.sectionNotes)
            {
                var daStrumTime:Float = songNotes[0];
                var daNoteData:Int = Std.int(songNotes[1] % 4);
                var gottaHitNote:Bool = section.mustHitSection;

                if (songNotes[1] > 4-1)
                {
                    gottaHitNote = !section.mustHitSection;
                }

                if (PlayState.keyCount != 4) {
                    if (daNoteData != lastND) {
                        lastND = FlxG.random.int(0, PlayState.keyCount-1, [lastND]);
                    }
                    daNoteData = lastND;
                }

                var oldNote:Note;
                if (loadedNotes.length > 0)
                    oldNote = loadedNotes[Std.int(loadedNotes.length - 1)];
                else
                    oldNote = null;

                var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
                swagNote.mustPress = gottaHitNote;
                swagNote.sustainLength = songNotes[2];
                swagNote.noteType = songNotes[3];

                swagNote.scrollFactor.set();

                loadedNotes.push(swagNote);

                final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
                final floorSus:Int = Math.floor(susLength);

                if(floorSus > 0) {
                    for (susNote in 0...floorSus + 1)
                    {
                        oldNote = loadedNotes[Std.int(loadedNotes.length - 1)];

                        var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
                        sustainNote.mustPress = gottaHitNote;
                        sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
                        sustainNote.noteType = swagNote.noteType;
                        sustainNote.scrollFactor.set();
                        sustainNote.parent = swagNote;
                        loadedNotes.push(sustainNote);
                        swagNote.tail.push(sustainNote);

                        sustainNote.correctionOffset = (PlayState.multikeyWidths[PlayState.keyCount] * 0.7)*0.5;
                        if(!PlayState.isPixelStage)
                        {
                            if(oldNote.isSustainNote)
                            {
                                oldNote.scale.y = (Conductor.stepCrochet * songSpeed * 0.45) / oldNote.frameHeight;
                                //oldNote.scale.y /= playbackRate;
                                oldNote.updateHitbox();
                            }

                            if(ClientPrefs.data.downScroll)
                                sustainNote.correctionOffset = 0;
                        }
                        else if(oldNote.isSustainNote)
                        {
                            //oldNote.scale.y /= playbackRate;
                            oldNote.updateHitbox();
                        }
                    }
                }

            }
        }

        //Conductor.crochet = tempCrochet;
       // Conductor.stepCrochet = tempStepCrochet;

        loadedNotes.sort(PlayState.sortByTime);
        trace(loadedNotes.length);
    }

	override function create()
	{		
        FlxG.mouse.visible = true;
		MusicBeatState.mouseHideTimer = 5;

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false);

		FlxG.sound.list.add(pauseMusic);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

        top = new PauseOption(0, 0);
        top.antialiasing = ClientPrefs.data.antialiasing;
        top.loadGraphic(Paths.image("wiimenu/pause/pauseTop"));
        top.hoverSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/pause/pauseTopHover"));
        top.clickSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/pause/pauseTopClick"));
        top.doScaleOnHover = false;
        top.y -= top.height;
        add(top);

        top.onClick = function() {
            closeMenu();
        }

        bot = new PauseOption(0, FlxG.height);
        bot.antialiasing = ClientPrefs.data.antialiasing;
        bot.loadGraphic(Paths.image("wiimenu/pause/pauseBottom"));
        bot.hoverSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/pause/pauseBottomHover"));
        bot.clickSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/pause/pauseBottomClick"));
        bot.doScaleOnHover = false;
        add(bot);
        bot.onClick = function() {
            exiting = true;

            fadeOut(function() {
                PlayState.instance.paused = true; // For lua
                PlayState.instance.vocals.volume = 0;
                FlxTransitionableState.skipNextTransIn = true;
                //FlxTransitionableState.skipNextTransOut = true;
                MusicBeatState.switchState(new OptionsState());
                if(ClientPrefs.data.pauseMusic != 'None')
                {
                    FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
                    FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
                    FlxG.sound.music.time = pauseMusic.time;
                }
                OptionsState.onPlayState = true;
            });
        }

        menu = new PauseOption(148, 278);
        menu.antialiasing = ClientPrefs.data.antialiasing;
        menu.loadGraphic(Paths.image("wiimenu/pause/pauseReturnButton"));
        menu.clickSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/pause/pauseReturnClick"));
        menu.alpha = 0;
        add(menu);
        menu.onClick = function() {
            exiting = true;
            fadeOut(function() {
                #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
                PlayState.deathCounter = 0;
                PlayState.seenCutscene = false;
    
                Mods.loadTopMod();

                FlxTransitionableState.skipNextTransIn = true;
                //FlxTransitionableState.skipNextTransOut = true;
                if(PlayState.isStoryMode)
                    MusicBeatState.switchState(new MainMenuState());
                else 
                    MusicBeatState.switchState(new FreeplayState());

                FlxG.sound.playMusic(Paths.music('freakyMenu'));
                FlxG.sound.music.loopTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_START_TIME;
                FlxG.sound.music.endTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_END_TIME;
                PlayState.changedDifficulty = false;
                PlayState.chartingMode = false;
                FlxG.camera.followLerp = 0;
            });
        }

        if (WeekData.weeksList[PlayState.storyWeek] == "captcha" || WeekData.weeksList[PlayState.storyWeek] == "letterbomb") {
			remove(menu);
            menu.x += 10000;
		}

        reset = new PauseOption(728, 278);
        reset.antialiasing = ClientPrefs.data.antialiasing;
        reset.loadGraphic(Paths.image("wiimenu/pause/pauseRestartButton"));
        reset.clickSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/pause/pauseRestartClick"));
        reset.alpha = 0;
        add(reset);
        reset.onClick = function() {
            exiting = true;
            restartSong();
        }


        wrench = new FlxSprite(369, FlxG.height).loadGraphic(Paths.image("wiimenu/pause/pauseWrench"));
        add(wrench);

        settingsText = new FlxSprite(542, FlxG.height).loadGraphic(Paths.image("wiimenu/pause/pauseConfigureText"));
        add(settingsText);

        new FlxTimer().start(0.35, function(tmr) {
            FlxTween.tween(bg, {alpha: 0.52}, 0.35, {ease: FlxEase.linear});
            FlxTween.tween(top, {y: 0}, 0.35, {ease: FlxEase.linear});
            FlxTween.tween(bot, {y: FlxG.height - bot.height}, 0.35, {ease: FlxEase.linear});
            FlxTween.tween(menu, {alpha: 1}, 0.35, {ease: FlxEase.linear});
            FlxTween.tween(reset, {alpha: 1}, 0.35, {ease: FlxEase.linear});

            FlxTween.tween(wrench, {y: 523+30}, 0.35, {ease: FlxEase.linear});
            FlxTween.tween(settingsText, {y: 633}, 0.35, {ease: FlxEase.linear});
            
        });
        new FlxTimer().start(0.5, function(tmr) {
            FlxG.sound.play(Paths.sound('pauseOpen'), 0.5);
        });

        allowMouseControlWithKeys = true;

        loadPauseChart();

        notes = new FlxTypedGroup<Note>();
        notes.cameras = [PlayState.instance.camHUD];
        add(notes);

        for (n in loadedNotes) {
            unspawnNotes.push(n);
        }


        //strumLineNotes = new FlxTypedGroup<StrumNote>();
		//PlayState.instance.insert(PlayState.instance.members.indexOf(PlayState.instance.strumLineNotes)+1, strumLineNotes);
        //add(strumLineNotes);

		//opponentStrums = new FlxTypedGroup<StrumNote>();
		//playerStrums = new FlxTypedGroup<StrumNote>();

        //strumLineNotes.cameras = [PlayState.instance.camHUD];
		
		//generateStaticArrows(0);
		//generateStaticArrows(1);

		super.create();
	}
	
	function getPauseSong()
	{
        var songName = PauseSubState.songName;
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if(formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var cantUnpause:Float = 0.35;
    var exiting:Bool = false;
    var pauseTime:Float = 0;
    var lastPauseUpdateTime:Float = 0;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 1.0)
			pauseMusic.volume += 0.01 * elapsed;

        //loop
        if (pauseMusic.time >= 224000) {
            pauseMusic.time = 10670;
            unspawnNotes = [];
            notes.clear();
            for (n in loadedNotes) {
                unspawnNotes.push(n);
            }
            trace("loop");
        }

        if (lastPauseUpdateTime != pauseMusic.time) {
            lastPauseUpdateTime = pauseMusic.time;
            pauseTime = lastPauseUpdateTime;
        } else {
            pauseTime += 1000 * elapsed;
        }

		

        if (cantUnpause < 0 && !exiting) {
            if(controls.BACK)
            {
                closeMenu();
                return;
            }

            for (item in [top, bot, menu, reset])
            {
                if (item.overlapsPoint(FlxG.mouse.getScreenPosition(cameras[0]), false, cameras[0]))
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
            wrench.y = FlxMath.lerp(wrench.y, 523 + (bot.selected ? 0 : 30), 20 * elapsed);
        } else {
            for (item in [top, bot, menu, reset]) item.selected = false;
        }

        if (unspawnNotes[0] != null)
        {
            var time:Float = 2000;
            if(songSpeed < 1) time /= songSpeed;
            if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

            while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - pauseTime < time)
            {
                var dunceNote:Note = unspawnNotes[0];
                notes.insert(0, dunceNote);
                dunceNote.spawned = true;

                dunceNote.active = dunceNote.visible = true;
                dunceNote.canBeHit = dunceNote.wasGoodHit = false;
                if (dunceNote.clipRect != null) {
                    var swagRect = dunceNote.clipRect;
                    swagRect.x = swagRect.y = 0;
                    swagRect.width = dunceNote.frameWidth;
                    swagRect.height = dunceNote.frameHeight;
                    dunceNote.clipRect = swagRect;
                }

                var index:Int = unspawnNotes.indexOf(dunceNote);
                unspawnNotes.splice(index, 1);
            }
            super.update(elapsed);
        }

        var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
        notes.forEachAlive(function(daNote:Note)
        {
            var strumGroup:FlxTypedGroup<StrumNote> = PlayState.instance.playerStrums;
            if(!daNote.mustPress) strumGroup = PlayState.instance.opponentStrums;

            var strum:StrumNote = strumGroup.members[daNote.noteData];
            daNote.followStrumNote(strum, fakeCrochet, songSpeed, pauseTime);

            daNote.alpha = 0.3;

            if(!daNote.wasGoodHit)
            {
                daNote.canBeHit = (daNote.strumTime < pauseTime);

                if(daNote.canBeHit) {
                    daNote.wasGoodHit = true;
                    if (!daNote.isSustainNote) {
                        daNote.active = daNote.visible = false;
                        notes.remove(daNote, true);
                    }
                }
            }

            if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

            // Kill extremely late notes and cause misses
            if (pauseTime - daNote.strumTime > 350 / songSpeed)
            {
                daNote.active = daNote.visible = false;
                notes.remove(daNote, true);
            }
        });
	}

    function closeMenu() {
        exiting = true;

        notes.clear();

        FlxTween.tween(bg, {alpha: 0.0}, 0.35, {ease: FlxEase.linear});
        FlxTween.tween(top, {y: -top.height}, 0.35, {ease: FlxEase.linear});
        FlxTween.tween(bot, {y: FlxG.height}, 0.35, {ease: FlxEase.linear});
        FlxTween.tween(menu, {alpha: 0}, 0.35, {ease: FlxEase.linear});
        FlxTween.tween(reset, {alpha: 0}, 0.35, {ease: FlxEase.linear});
        FlxTween.tween(wrench, {y: FlxG.height}, 0.35, {ease: FlxEase.linear});
            FlxTween.tween(settingsText, {y: FlxG.height}, 0.35, {ease: FlxEase.linear});
        new FlxTimer().start(0.35, function(tmr) {
            close();
        });
    }

	public function restartSong(noTrans:Bool = false)
	{
        fadeOut(function() {
            PlayState.instance.paused = true; // For lua
            FlxG.sound.music.volume = 0;
            PlayState.instance.vocals.volume = 0;
            FlxTransitionableState.skipNextTransIn = true;
            //FlxTransitionableState.skipNextTransOut = true;
            MusicBeatState.resetState();
        });
	}

    function fadeOut(onComplete:Void->Void) {
        var bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
        FlxTween.tween(bg, {alpha: 1.0}, 0.6, {ease: FlxEase.linear, onComplete: function(twn) {
            notes.clear();
            onComplete();
        }});
    }

	override function destroy()
	{
		pauseMusic.destroy();
        notes.clear();

		super.destroy();
	}

    private function generateStaticArrows(player:Int):Void
    {
        var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...PlayState.keyCount)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > (PlayState.keyCount/2)-1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
    }
}


class PauseOption extends FlxSprite
{
	public var onClick:Void->Void;
	public var selected:Bool = false;
    var clickTimer:Float = 0;

    public var doScaleOnHover:Bool = true;

	public function new(X:Float, Y:Float)
	{
		super(X, Y, null);
	}

	public var selectedScale = 1.05;
	public var unselectedScale = 1.0;

    public var hoverSprite:FlxSprite;
    public var clickSprite:FlxSprite;

	override public function update(elapsed:Float)
	{
        if (clickTimer > 0) {
            clickTimer -= elapsed;
        }
		if (selected)
		{
			if (doScaleOnHover)
			{
				scale.y = scale.x = FlxMath.lerp(scale.x, selectedScale, 15*elapsed);
			}
	
			if (FlxG.mouse.justPressed || Controls.instance.ACCEPT) {
				if (onClick != null) onClick();
                clickTimer = 0.15;
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

    override public function draw() {
        if (clickTimer > 0 && clickSprite != null) {
            clickSprite.scale.x = clickSprite.scale.y = scale.x;
            clickSprite.x = x;
            clickSprite.y = y;
            clickSprite.antialiasing = antialiasing;
            clickSprite.draw();
            return;
        }
        if (selected && hoverSprite != null) {
            hoverSprite.scale.x = hoverSprite.scale.y = scale.x;
            hoverSprite.x = x;
            hoverSprite.y = y;
            hoverSprite.antialiasing = antialiasing;
            hoverSprite.draw();
            return;
        }
        super.draw();
    }

    override public function destroy() {
        if (hoverSprite != null) hoverSprite.destroy();
        if (clickSprite != null) clickSprite.destroy();
        super.destroy();
    }
}
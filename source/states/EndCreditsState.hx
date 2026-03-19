package states;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end
class EndCreditsState extends MusicBeatState {
	#if VIDEOS_ALLOWED
    var video:FlxVideoSprite;
	#end
    override public function create() {
        super.create();

        FlxG.sound.music.stop();

        var filepath:String = Paths.video("End Cutscene");

		#if VIDEOS_ALLOWED
        var video = new FlxVideoSprite();
		add(video);
		video.load(filepath);
		new FlxTimer().start(0.001, function(tmr:FlxTimer) {
			video.play();
		});
		video.bitmap.onEndReached.add(function()
		{
			video.destroy();
			remove(video);
            LoadingState.loadAndSwitchState(new MainMenuState());
			return;
		});
		#end
    }
}
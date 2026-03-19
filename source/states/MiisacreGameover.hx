package states;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;

class MiisacreGameover extends MusicBeatState {
    var video:FlxVideoSprite;
    override public function create() {
        super.create();

        var filepath:String = Paths.video("Miisacre_Death1");

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
            LoadingState.loadAndSwitchState(new PlayState());
			return;
		});
    }
	
}
#end
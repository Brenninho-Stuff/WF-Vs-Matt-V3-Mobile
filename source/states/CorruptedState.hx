package states;

import objects.WiiCustomText;
import backend.Song;
import backend.WeekData;

class CorruptedState extends MusicBeatState {
    override public function create() {
        super.create();
        Main.fpsVar.visible = false;
        WeekData.reloadWeekFiles(true);
        trace("corrupted");

        var text = new WiiCustomText(0, 0, 1280, 
            "The system files are corrupted.\nPlease refer to the Wii Operations Manual\nfor help troubleshooting."
        , 1.5, "wii");
        text.width = text.fieldWidth;
        add(text);
        text.alpha = 0;
        text.screenCenter();
        FlxTween.tween(text, {alpha: 1}, 1);

        new FlxTimer().start(5, function(tmr) {
            loadWeek("letterbomb");
        });
    }

    function loadWeek(name:String)
    {
        trace(WeekData.weeksLoaded);

        var leWeek = WeekData.weeksLoaded[name];

        WeekData.setDirectoryFromWeek(leWeek);
        PlayState.storyWeek = WeekData.weeksList.indexOf(name);
        Difficulty.loadFromWeek();

        var songArray:Array<String> = [];
        for (i in 0...leWeek.songs.length) {
            songArray.push(leWeek.songs[i][0]);
        }

        PlayState.storyPlaylist = songArray;
        PlayState.isStoryMode = true;
        PlayState.storySongNum = 0;

        var diffic = Difficulty.getFilePath(0);
        if(diffic == null) diffic = '';
        PlayState.storyDifficulty = 0;

        PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
        PlayState.campaignScore = 0;
        PlayState.campaignMisses = 0;
        LoadingState.loadAndSwitchState(new PlayState());
        Main.fpsVar.visible = ClientPrefs.data.showFPS;
        return true;
    }
}
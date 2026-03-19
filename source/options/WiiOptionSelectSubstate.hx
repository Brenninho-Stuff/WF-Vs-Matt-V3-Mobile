package options;

import objects.StrumNote;
import objects.Note;

class WiiOptionSelectSubstate extends BaseOptionsMenu
{
    var onSelect:String->Void;
    var onCancelCallback:Void->Void;
    var curSelectedName:String = "";
    var notes:FlxTypedGroup<StrumNote>;
	public function new(title:String, optionNames:Array<String>, curSelected:String, onSelect:String->Void, onCancelCallback:Void->Void = null)
	{
        this.onSelect = onSelect;
        this.onCancelCallback = onCancelCallback;
        this.title = title;
        for (o in optionNames)
        {
            var option:Option = new Option(o, "", "", "");  addOption(option); 
        }
        confirmActive = true;
		super();
        confirmActive = true;

        curSelectedName = curSelected;
        for (item in grpOptions.members)
            item.optionSelected = item.text.text == curSelectedName;

        backButton.text.text = "Cancel";
        backButton.text.width = backButton.text.fieldWidth;
        confirmButton.visible = true;

        if (title == "Note Skins") {
            notes = new FlxTypedGroup<StrumNote>();
            for (i in 0...Note.colArray.length)
            {
                var note:StrumNote = new StrumNote(900 + (160*i*0.5), 135, i, 0);
                note.scale.set(0.5, 0.5);
                note.updateHitbox();
                note.centerOffsets();
                note.centerOrigin();
                note.playAnim('static');
                notes.add(note);
            }
            add(notes);
        }
	}
    var lastNoteSkin:String = "";
    override public function selectItemCheck()
    {
        if(controls.ACCEPT || FlxG.mouse.justPressed)
        {
            FlxG.sound.play(Paths.sound('wiiSelect'));
            curSelectedName = curOption.name;
            for (item in grpOptions.members)
                item.optionSelected = item.text.text == curSelectedName;

        }

        if (notes != null) {
            if (lastNoteSkin != curSelectedName) {
                lastNoteSkin = curSelectedName;
                onChangeNoteSkin();
            }
        }
    }

    override public function onConfirm()
    {
        onSelect(curSelectedName);
        close();
    }

    override public function onCancel() 
    {
        if (onCancelCallback != null) onCancelCallback();
    }

    function onChangeNoteSkin()
    {
        notes.forEachAlive(function(note:StrumNote) {
            changeNoteSkin(note);
            note.centerOffsets();
            note.centerOrigin();
        });
    }

    function changeNoteSkin(note:StrumNote)
    {
        var skin:String = Note.defaultNoteSkin;
        var customSkin:String = skin + Note.getNoteSkinPostfix(lastNoteSkin);
        if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

        note.texture = skin; //Load texture and anims
        note.reloadNote();
        note.scale.set(0.5, 0.5);
        note.updateHitbox();
        note.playAnim('static');
    }
}
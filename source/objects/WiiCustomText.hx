package objects;

import flixel.system.FlxAssets.FlxShader;
import flixel.graphics.FlxGraphic;
import flixel.FlxObject;


typedef WiiCharacterData = {
    var character:String;
    var path:String;
    var x:Float;
    var y:Float;
    var gapOffset:Float;
    var ?graphic:FlxGraphic;
}

typedef WiiFontData = {
    var characters:Array<WiiCharacterData>;
    var lineOffset:Float;
}

class WiiCustomText extends FlxSprite {

    var loadedCharacters:Array<FlxSprite> = [];
    var deadCharacters:Array<FlxSprite> = [];

    public var lineOffset:Float = 24;
    public var spaceGap:Float = 8;
    public var newlineGap:Float = 25;
    public var size:Float = 1;
    public var text(default, set):String = "";
    function set_text(Text:String):String
    {
        text = Text;
        regenText();
        return Text;
    }
    public var fieldWidth:Float = 0;
    public var font:String = "";
    public var alignment:FlxTextAlign = FlxTextAlign.CENTER;
    public var noAA:Bool = false;

    static var fontCache:Map<String, WiiFontData> = [];
    var fontData:WiiFontData;
    
    var line:FlxSprite;
    
    override public function new(X:Float, Y:Float, fieldWidth:Float, text:String = "", size:Float = 1, font:String = "boldWii") {
        super(X, Y);
        this.fieldWidth = fieldWidth;
        this.size = size;
        applyFont(font);
        this.text = text;
        
        //line = new FlxSprite().makeGraphic(0, 0).makeGraphic(1280, 1, 0xFFFF0000);
    }

    private function loadFont(name:String, forceReload:Bool = false) {
        this.font = name;

        if (fontCache.exists(name) && !forceReload) {
            fontData = fontCache.get(name);
            return;
        }

        var info = Paths.getTextFromFile('images/fonts/'+name+"/info.txt").split("\n");

        fontData = {characters: [], lineOffset: Std.parseFloat(info[0])};
        var data = Paths.getTextFromFile('images/fonts/'+name+"/data.txt");
        for (l in data.split("\n")) {
            var d = l.split(" ");
            var char:WiiCharacterData = {character: d[0], path: d[1], x:Std.parseFloat(d[2]), y:Std.parseFloat(d[3]), gapOffset:Std.parseFloat(d[4])};
            fontData.characters.push(char);
        }
        fontCache.set(name, fontData);
    }

    public function applyFont(name:String, forceReload:Bool = false) {

        loadFont(name, forceReload);
        lineOffset = fontData.lineOffset;
        for (char in fontData.characters) {
            char.graphic = Paths.image("fonts/"+name+"/"+char.path); //reload when changing
        }
    }

    private function getCharacterData(char:String) {
        for (d in fontData.characters) {
            if (d.character == char) return d;
        }
        return null;
    }

    var _text:String = "";
    public function regenText(force:Bool = false) {

        if (_text != text || force) {
            _text = text;

            for (char in loadedCharacters) {
                deadCharacters.push(char);
            }
            loadedCharacters = [];

            width = 1;
            height = 1;
            var curX:Float = 0;
            var curY:Float = 0;
            var split = text.split("");
            split.push("\n");

            var lineCharacters:Array<FlxSprite> = [];

            for (char in split) {
                if (char == " ") {
                    curX += spaceGap*size;
                } else if (char != "\n"){
                    var data = getCharacterData(char);
                    if (data != null) {
                        var spr:FlxSprite;
                        if (deadCharacters[0] != null) {
                            spr = deadCharacters[0];
				            deadCharacters.remove(deadCharacters[0]);
                        } else {
                            spr = new FlxSprite();
                            spr.antialiasing = ClientPrefs.data.antialiasing;
                        }
                        if (noAA) spr.antialiasing = false;

                        spr.loadGraphic(data.graphic);
                        spr.scale.set(size, size); spr.updateHitbox();
                        spr.offset.set(spr.offset.x + -(curX + (data.x*size)), spr.offset.y + -(curY + (data.y*size) + ((lineOffset*size) - spr.height)));
                        spr.color = this.color;
                        spr.shader = this.shader;
                        loadedCharacters.push(spr);
                        lineCharacters.push(spr);
                        curX += (spr.width + (data.gapOffset*size));
                    } else {
                        curX += spaceGap*size;
                    }
                }

                width = Math.max(width, curX);

                if ((fieldWidth > 0 && curX > fieldWidth) || char == "\n") {
                    var leftOverWidth = fieldWidth - curX;
                    if (fieldWidth > 0) {
                        switch(alignment) {
                            case CENTER:
                                for (char in lineCharacters) char.offset.x -= leftOverWidth/2;
                            case RIGHT:
                                for (char in lineCharacters) char.offset.x -= leftOverWidth;
                            case JUSTIFY: //idk who even uses this
                            case LEFT: //do nothing cuz its already left
                        }
                    }

                    curX = 0;
                    curY += newlineGap*size;
                    
                    lineCharacters = [];
                }
            }

            height = curY;
        }
    }

    override public function draw() {
        if (visible) {
            
            /*line.setPosition(x, y + (lineOffset*size));
            line.scrollFactor.set(scrollFactor.x, scrollFactor.y);
            line.cameras = this._cameras;
            line.draw();*/
            
            for (char in loadedCharacters) {
                char.setPosition(x, y);
                char.scrollFactor.set(scrollFactor.x, scrollFactor.y);
                char.cameras = this._cameras;
                char.alpha = alpha;
                char.draw();
            }
        }
    }

    override public function destroy() {
        for (char in loadedCharacters) char.destroy();
        for (char in deadCharacters) char.destroy();
        loadedCharacters = [];
        deadCharacters = [];
        super.destroy();
    }
}

class MiiChannelTextShader extends FlxShader {
        @:glFragmentSource('
        #pragma header

        void main()
        {
            vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);
            col.r = mix(0.33 * col.a, col.r, col.r);
            col.g = mix(0.43 * col.a, col.g, col.g);
            col.b = mix(0.42 * col.a, col.b, col.b);
            gl_FragColor = col;
        }')
    public function new()
    {
        super();
    }
}
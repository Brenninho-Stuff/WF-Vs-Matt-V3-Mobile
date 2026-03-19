package options;

import flixel.util.FlxDestroyUtil;
import objects.WiiCustomText;
import flixel.FlxSprite;
import flixel.text.FlxText;

class WiiOption extends FlxSprite
{
    public var selectedSpr:FlxSprite;
    public var text:WiiCustomText;

    public var selected:Bool = false;

    public var optionSelected:Bool = false; //show red corners
    var corner0:FlxSprite;
    var corner1:FlxSprite;
    var corner2:FlxSprite;
    var corner3:FlxSprite;
    
    public function new(?X:Float = 0.0, ?Y:Float = 0.0, textString:String, imageName:String = "wiiOption")
    {
        super(X,Y);
        loadGraphic(Paths.image('wiimenu/options/'+imageName));
        selectedSpr = new FlxSprite();
        selectedSpr.loadGraphic(Paths.image('wiimenu/options/'+imageName+"Selected"));

        text = new WiiCustomText(0, 0, this.width, textString, 1.5, 'wii');
        text.color = 0xFF000000;
        text.regenText(true);
        text.width = this.width;

        antialiasing = ClientPrefs.data.antialiasing;
        selectedSpr.antialiasing = ClientPrefs.data.antialiasing;

        corner0 = new FlxSprite(); corner0.loadGraphic(Paths.image('wiimenu/options/wiiOptionCorner'));
        corner1 = new FlxSprite(); corner1.loadGraphic(Paths.image('wiimenu/options/wiiOptionCorner'));
        corner2 = new FlxSprite(); corner2.loadGraphic(Paths.image('wiimenu/options/wiiOptionCorner'));
        corner3 = new FlxSprite(); corner3.loadGraphic(Paths.image('wiimenu/options/wiiOptionCorner'));
        corner1.flipX = true;
        corner2.flipY = true;
        corner3.flipY = corner3.flipX = true;
    }

    override public function destroy() {
        FlxDestroyUtil.destroy(text);
        FlxDestroyUtil.destroy(corner0);
        FlxDestroyUtil.destroy(corner1);
        FlxDestroyUtil.destroy(corner2);
        FlxDestroyUtil.destroy(corner3);
        super.destroy();
    }

    override public function draw()
    {
        selectedSpr.setPosition(x, y);
        text.setPosition(x + (width*0.5) - (text.width*0.5), (5*scale.y) + y + (height*0.5) - (text.height*0.5));
        selectedSpr.cameras = text.cameras = corner0.cameras = corner1.cameras = corner2.cameras = corner3.cameras = cameras;
        selectedSpr.alpha = text.alpha = corner0.alpha = corner1.alpha = corner2.alpha = corner3.alpha = alpha;
        selectedSpr.flipX = flipX;


        if (!selected)
            super.draw();
        else
            selectedSpr.draw();

        if (optionSelected) //show red corners
        {
            corner0.setPosition(x - (corner0.width*0.5), y - (corner0.height*0.5));
            corner0.draw();
            corner1.setPosition(x+width - (corner1.width*0.5), y - (corner1.height*0.5));
            corner1.draw();
            corner2.setPosition(x - (corner2.width*0.5), y+height - (corner2.height*0.5));
            corner2.draw();
            corner3.setPosition(x+width - (corner3.width*0.5), y+height - (corner3.height*0.5));
            corner3.draw();
        }
       
        text.draw();
    }
}
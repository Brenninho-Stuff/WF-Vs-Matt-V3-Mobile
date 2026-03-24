package mobile.backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;

/**
 * Pause? PAUSE!!
 *
 * @author StarNova (Cream.BR)
 */
 
class PauseButton extends FlxSprite
{
    public var onClick:Void->Void;
    private var _lastTouchId:Int = -1;

    public function new(x:Float = 0, y:Float = 0, ?onClick:Void->Void) 
    {
        var posX:Float = (x == 0) ? FlxG.width - 130 : x; 
        var posY:Float = (y == 0) ? 25 : y;

        super(posX, posY);

        #if mobile
        loadGraphic(FlxGraphic.fromBitmapData(Assets.getBitmapData('assets/mobile/pauseButton.png')));
        
        antialiasing = true;
        scrollFactor.set();
        alpha = 0.7;
        scale.set(0.8, 0.8);
        updateHitbox();

        this.onClick = onClick;
        #else
        visible = false;
        active = false;
        #end
    }

    override function update(elapsed:Float) 
    {
        super.update(elapsed);

        #if mobile
        if (!visible || !active || onClick == null) return;

        for (touch in FlxG.touches.list) {
            if (touch.justPressed && touch.overlaps(this, camera)) {
                onClick();
                break;
            }
        }
        #end
    }

    /**
     * A function to create
     */
    public static function create(camera:FlxCamera, ?onClick:Void->Void):PauseButton 
    {
        var btn = new PauseButton(0, 0, onClick);
        btn.cameras = [camera];
        return btn;
    }
}

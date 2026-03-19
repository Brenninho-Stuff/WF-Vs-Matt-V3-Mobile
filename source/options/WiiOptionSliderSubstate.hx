package options;

import objects.WiiCustomText;
import flixel.input.keyboard.FlxKey;

class WiiOptionSliderSubstate extends BaseOptionsMenu
{
    var onSelect:Float->Void;
    var curValue:Float = 0;
    var option:Option;
    var isInt:Bool = false;

    var arrowLeftSlider:WiiOption;
	var arrowRightSlider:WiiOption;
    var sliderText:WiiCustomText;

    var acceptBinds:Array<FlxKey> = [];

	public function new(title:String, option:Option, curValue:Float, onSelect:Float->Void)
	{
        this.onSelect = onSelect;
        this.title = title;
        this.option = option;
        this.curValue = curValue;

        confirmActive = true;
		super();
        confirmActive = true;

        backButton.text.text = "Cancel";
        backButton.text.width = backButton.text.fieldWidth;
        confirmButton.visible = true;

        sliderText = new WiiCustomText(0, 0, 0, ""+curValue, 4, "wii");
        sliderText.screenCenter();
        add(sliderText);

        arrowLeftSlider = new WiiOption(0, 0, "", "wiiOptionsArrow");
		add(arrowLeftSlider);
		arrowRightSlider = new WiiOption(0, 0, "", "wiiOptionsArrow");
		add(arrowRightSlider); 
		arrowRightSlider.flipX = true;
		arrowLeftSlider.screenCenter(); arrowLeftSlider.x -= FlxG.width*0.2;
		arrowRightSlider.screenCenter(); arrowRightSlider.x += FlxG.width*0.2;

        //arrowLeftSlider.y = sliderText.y - arrowLeftSlider.height;
        //arrowRightSlider.y = (sliderText.y+sliderText.height)+5;

        //add here so it gets faded out
        bgs.push(sliderText);
        bgs.push(arrowLeftSlider);
        bgs.push(arrowRightSlider);

        acceptBinds = ClientPrefs.keyBinds.get("accept"); //so can also get held keys
	}

    var holdTimeSlider:Float = 0;

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (doActuallyClose)
            return;     
        
        var noInput = !FlxG.keys.anyPressed(acceptBinds) && !FlxG.mouse.pressed;
        if (noInput)
            holdTimeSlider = 0;

        for (item in [arrowLeftSlider, arrowRightSlider])
        {
            if (FlxG.mouse.overlaps(item) && item.visible)
            {
                if (!item.selected)
                {
                    FlxG.sound.play(Paths.sound('wiiOptionHover'));
                    item.selected = true;
                }

                

                
                var held = FlxG.keys.anyPressed(acceptBinds) || FlxG.mouse.pressed;
                var justPressed = FlxG.keys.anyJustPressed(acceptBinds) || FlxG.mouse.justPressed;

                if (justPressed)
                    FlxG.sound.play(Paths.sound('wiiSliderStep'), 0.7);

                if (held)
                {
                    if(holdTimeSlider > 0.5 || justPressed)
                    {
                        
                        var add:Float = (item == arrowLeftSlider ? -option.changeValue : option.changeValue);
                        var holdValue = curValue + add;
                        if(holdValue < option.minValue) holdValue = option.minValue;
                        else if (holdValue > option.maxValue) holdValue = option.maxValue;

                        switch(option.type)
                        {
                            case 'int':
                                holdValue = Math.round(holdValue);

                            case 'float' | 'percent':
                                holdValue = FlxMath.roundDecimal(holdValue, option.decimals);
                        }
                        curValue = holdValue;
                        sliderText.text = ""+curValue;
                        sliderText.screenCenter();
                    }

                    holdTimeSlider += elapsed;
                }

            }
            else
            {
                item.selected = false;
            }
        }
    }

    override public function onConfirm()
    {
        onSelect(curValue);
        close();
    }
}
package mobile.controls;

import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.Shape;
import mobile.flixel.FlxButton;
import mobile.flixel.input.FlxMobileInputManager;
import mobile.flixel.input.FlxMobileInputID;

/**
 * Hitbox... HIT
 * @author StarNova (Cream.BR)
 */
 
class MobileHitbox extends FlxMobileInputManager
{
	public var buttons:Array<FlxButton> = [];
	
	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	
	public var buttonLeft6k:FlxButton;
	public var buttonUp6k:FlxButton;
	public var buttonRight6k:FlxButton;
	public var buttonLeft6kTwo:FlxButton;
	public var buttonUp6kTwo:FlxButton;
	public var buttonRight6kTwo:FlxButton;
	
	public var buttonLeft7k:FlxButton;
	public var buttonUp7k:FlxButton;
	public var buttonRight7k:FlxButton;
	public var buttonSpace7k:FlxButton;
	public var buttonLeft7kTwo:FlxButton;
	public var buttonUp7kTwo:FlxButton;
	public var buttonRight7kTwo:FlxButton;
	
	public var buttonLeft9k:FlxButton;
	public var buttonDown9k:FlxButton;
	public var buttonUp9k:FlxButton;
	public var buttonRight9k:FlxButton;
	public var buttonSpace9k:FlxButton;
	public var buttonLeft9kTwo:FlxButton;
	public var buttonDown9kTwo:FlxButton;
	public var buttonUp9kTwo:FlxButton;
	public var buttonRight9kTwo:FlxButton;

	private final alphaTarget:Float = 0.2;
	
	private var _cachedGraphics:Map<Int, flixel.graphics.FlxGraphic> = new Map();

	public function new():Void
	{
		super();
	
		var keys:Int = PlayState.keyCount;
		var btnWidth:Int = Std.int(FlxG.width / keys);
		
		var data:Array<{color:Int, ids:Array<FlxMobileInputID>}> = [];
		
		switch (keys) {
			case 4:
				data = [
					{color: 0xFF00FF, ids: [FlxMobileInputID.hitboxLEFT, FlxMobileInputID.noteLEFT]},
					{color: 0x00FFFF, ids: [FlxMobileInputID.hitboxDOWN, FlxMobileInputID.noteDOWN]},
					{color: 0x00FF00, ids: [FlxMobileInputID.hitboxUP, FlxMobileInputID.noteUP]},
					{color: 0xFF0000, ids: [FlxMobileInputID.hitboxRIGHT, FlxMobileInputID.noteRIGHT]}
				];
			case 6:
				data = [
					{color: 0xFF00FF, ids: [FlxMobileInputID.note6k0]}, {color: 0x00FFFF, ids: [FlxMobileInputID.note6k1]},
					{color: 0x00FF00, ids: [FlxMobileInputID.note6k2]}, {color: 0xFF00FF, ids: [FlxMobileInputID.note6k3]},
					{color: 0x00FFFF, ids: [FlxMobileInputID.note6k4]}, {color: 0x00FF00, ids: [FlxMobileInputID.note6k5]}
				];
			case 7:
				data = [
					{color: 0xFF00FF, ids: [FlxMobileInputID.note7k0]}, {color: 0x00FFFF, ids: [FlxMobileInputID.note7k1]},
					{color: 0x00FF00, ids: [FlxMobileInputID.note7k2]}, {color: 0x00FF00, ids: [FlxMobileInputID.note7kSpace]},
					{color: 0xFF00FF, ids: [FlxMobileInputID.note7k3]}, {color: 0x00FFFF, ids: [FlxMobileInputID.note7k4]},
					{color: 0x00FF00, ids: [FlxMobileInputID.note7k5]}
				];
			case 9:
				data = [
					{color: 0xFF00FF, ids: [FlxMobileInputID.note9k0]}, {color: 0x00FFFF, ids: [FlxMobileInputID.note9k1]},
					{color: 0x00FF00, ids: [FlxMobileInputID.note9k2]}, {color: 0xFF0000, ids: [FlxMobileInputID.note9k3]},
					{color: 0xFF00FF, ids: [FlxMobileInputID.note9k4]}, {color: 0xFF00FF, ids: [FlxMobileInputID.note9k5]},
					{color: 0x00FFFF, ids: [FlxMobileInputID.note9k6]}, {color: 0x00FF00, ids: [FlxMobileInputID.note9k7]},
					{color: 0xFF0000, ids: [FlxMobileInputID.note9k8]}
				];
		}
		
		for (i in 0...data.length) {
			var btn:FlxButton = createHint(i * btnWidth, 0, btnWidth, FlxG.height, data[i].color, data[i].ids);
			add(btn);
			buttons.push(btn);
		}
	
		switch (keys) {
			case 4:
				buttonLeft  = buttons[0]; buttonDown  = buttons[1]; buttonUp    = buttons[2]; buttonRight = buttons[3];
			case 6:
				buttonLeft6k  = buttons[0]; buttonUp6k    = buttons[1]; buttonRight6k = buttons[2];
				buttonLeft6kTwo  = buttons[3]; buttonUp6kTwo    = buttons[4]; buttonRight6kTwo = buttons[5];
			case 7:
				buttonLeft7k  = buttons[0]; buttonUp7k    = buttons[1]; buttonRight7k = buttons[2]; buttonSpace7k = buttons[3];
				buttonLeft7kTwo  = buttons[4]; buttonUp7kTwo    = buttons[5]; buttonRight7kTwo = buttons[6];
			case 9:
				buttonLeft9k  = buttons[0]; buttonDown9k  = buttons[1]; buttonUp9k    = buttons[2]; buttonRight9k = buttons[3]; buttonSpace9k = buttons[4];
				buttonLeft9kTwo  = buttons[5]; buttonDown9kTwo  = buttons[6]; buttonUp9kTwo    = buttons[7]; buttonRight9kTwo = buttons[8];
		}
	
		scrollFactor.set();
		updateTrackedButtons();
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:FlxColor, IDs:Array<FlxMobileInputID>):FlxButton
	{
		var hint:FlxButton = new FlxButton(X, Y, IDs);
		
		// Sistema de Cache pq sim
		var graphicKey:Int = Color + Width;
		var bgGraphic:flixel.graphics.FlxGraphic = _cachedGraphics.get(graphicKey);
		
		if (bgGraphic == null) {
			var bitmap:BitmapData = new BitmapData(Width, Height, true, (Color & 0x00FFFFFF) | 0x88000000);
			bgGraphic = FlxG.bitmap.add(bitmap, false, "hitbox_" + graphicKey);
			_cachedGraphics.set(graphicKey, bgGraphic);
		}
		
		hint.loadGraphic(bgGraphic);
		hint.solid = hint.moves = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;

		var hintTween:FlxTween = null;
		hint.onDown.callback = function() {
		    if (hintTween != null) hintTween.cancel();
		    
		    hintTween = FlxTween.tween(hint, {alpha: alphaTarget}, 0.075, {
		        ease: FlxEase.circInOut,
		        onComplete: function(_) { hintTween = null; }
		    });
		}
		
		hint.onUp.callback = function() {
		    if (hintTween != null) hintTween.cancel();
		    
		    hintTween = FlxTween.tween(hint, {alpha: 0.00001}, 0.15, {
		        ease: FlxEase.circInOut,
		        onComplete: function(_) { hintTween = null; }
		    });
		}
		
		hint.onOut.callback = hint.onUp.callback;

		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		
		return hint;
	}

	/*private function createHintGraphic(Width:Int, Height:Int, Color:Int):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}*/

	override function destroy():Void
	{
		super.destroy();
		for (btn in buttons)
			FlxDestroyUtil.destroy(btn);
			
		// Cache? Talvez, mas seu cu tem mais hehehe
		for (key in _cachedGraphics.keys()) {
			var graphic = _cachedGraphics.get(key);
			FlxG.bitmap.remove(graphic);
			graphic.destroy();
		}
		_cachedGraphics.clear();
	}
}

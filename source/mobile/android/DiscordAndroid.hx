package mobile.android;

#if android
import lime.system.JNI;

class DiscordAndroid {
	private static var _init:Dynamic = null;
	private static var _update:Dynamic = null;
	private static var _shutdown:Dynamic = null;
	
	private static var initialized:Bool = false;

	public static function initialize() {
		if (initialized) return;

		try {
			if (_init == null)
				_init = JNI.createStaticMethod("network/discord/DiscordRPCHelper", "initialize", "()V");
			
			if (_init != null) {
				_init();
				initialized = true;
			}
		} catch(e:Dynamic) { 
			trace("JNI Init Error: " + e); 
		}
	}

	public static function update(details:String, state:String, ?smallImageKey:String) {
		try {
			if (!initialized) initialize();

			if (_update == null) {
				_update = JNI.createStaticMethod("network/discord/DiscordRPCHelper", "updateStatus", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
			}

			var safeDetails:String = (details != null) ? details : "";
			var safeState:String = (state != null) ? state : "";
			var safeImage:String = (smallImageKey != null) ? smallImageKey : "";

			if (_update != null) {
				_update(safeDetails, safeState, safeImage); 
			}
		} catch(e:Dynamic) { 
			trace("JNI Update Error: " + e); 
		}
	}

	public static function shutdown() {
		try {
			if (_shutdown == null)
				_shutdown = JNI.createStaticMethod("network/discord/DiscordRPCHelper", "shutdown", "()V");

			if (_shutdown != null) {
				_shutdown();
				initialized = false;
			}
		} catch(e:Dynamic) { 
			trace("JNI Shutdown Error: " + e); 
		}
	}
}
#end
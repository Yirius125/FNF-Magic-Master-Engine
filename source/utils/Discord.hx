package utils;

import Sys.sleep;
import discord_rpc.DiscordRpc;

using StringTools;

class Discord {
	public function new():Void {
		trace("Discord Client starting...");

		DiscordRpc.start({
			clientID: "999687047772115116",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});

		trace("Discord Client started!");

		while(true) {
			DiscordRpc.process();
			sleep(2);
		}

		DiscordRpc.shutdown();
		trace("Discord Client closed");
	}

    public static function init():Void {
		var DiscordDaemon = sys.thread.Thread.create(() -> {new Discord(); });
		trace("Discord Client initialized");
    }

	public static function shutdown() {
        DiscordRpc.shutdown();
		trace("Discord Client closed");
    }

    public static function change(details:String, state:Null<String>, ?small_image:String, ?has_start:Bool, ?end_time:Float):Void {
		var start_time:Float = has_start ? Date.now().getTime() : 0;
		if (end_time > 0) {end_time = start_time + end_time; }

		DiscordRpc.presence({
			largeImageText: "Magic Master Engine'",
			smallImageKey : small_image,
			largeImageKey: 'icon',
			details: details,
			state: state,
            endTimestamp : Std.int(end_time / 1000),
			startTimestamp : Std.int(start_time / 1000),
		});
    }

    private static function onReady():Void {
        DiscordRpc.presence({
			largeImageText: "Friday Night Funkin'",
			details: "✰ [ Starting Magic ] ✰",
			largeImageKey: 'icon',
			state: null,
		});
    }
	private static function onError(_code:Int, _message:String) {
        trace('Error! $_code : $_message');
    }
	private static function onDisconnected(_code:Int, _message:String) {
        trace('Disconnected! $_code : $_message');
    }
}
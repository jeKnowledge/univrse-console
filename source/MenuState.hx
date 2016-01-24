package;

import cpp.vm.Thread;
import flash.errors.Error;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;
import flixel.util.FlxTimer;
import net.Client;
import net.Commands;
import net.MessageStruct;
import net.MsgType;
import net.NetCallback;
import net.NetEvent;
import net.Server;
import openfl.Assets;
import pgr.dconsole.DC;
import sys.net.Host;
import sys.net.Socket;

/**
 * A FlxState which can be used for the game's menu.
 */
class MenuState extends FlxState
{	
	private var server:Server;
	private var unity:Client;
	private var objectIDMap:Map<Int, Objects>;
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		//Setup flixel
		FlxG.camera.bgColor = 0x000000;
		FlxG.sound.muteKeys = FlxG.sound.volumeDownKeys = FlxG.sound.volumeUpKeys = null;
		
		//Setup DConsole
		DC.showConsole();
		DC.clearConsole();
		DC.log("~~~~~~~UniVRse CONSOLE~~~~~~~", 0xC40000);
		
		displayMultiline("Hello, welcome to the command console. Type \"help\" to get started.", 0x4DF4DF);
		
		DC.registerCommand(getMeStartedFunc, "getMeStarted", "", "Get started here!", "");
	}
	
	function getMeStartedFunc(params:Array<String>) 
	{
		if (server != null) return;
		
		displayMultiline(Assets.getText("assets/data/helpIntroductionText.txt"), 0x4DF4DF);
		
		DC.registerCommand(godModeFunc, "godMode", "", "", "");
		DC.registerCommand(closeFunc, "close", "","","");
	}
	
	function godModeFunc(params:Array<String>) 
	{
		if (server != null) return;
		
		DC.clearConsole();
		DC.log("~~~~~~~UniVRse Interface Initializing~~~~~~~~", 0xD50000);
		displayMultiline(Assets.getText("assets/data/veryRealASCIILogo.txt") + "\n" + Assets.getText("assets/data/godModeInitText.txt"), 0xEE5753, createConnection);
	}
	
	function createConnection() {
		Thread.create(createServer);
		
		//Thread.create(dummyClient); //TEST
	}
	
	/*function dummyClient() 
	{
		var client = new Socket();
		client.connect(new Host("localhost"), 30303);
		client.setBlocking(false);
		var buff:String = "";
		while (true) {
			try 
			{
				var completeMessage = false;
				var message = "";
				
				buff += client.input.readLine();
				
				if (buff.charAt(buff.length - 1) == ";") {
					completeMessage = true;
					message = buff.substring(0,buff.length-1);
					buff = "";
				}
				
				if (completeMessage) {
					trace(message);
					if (message == "EXIT") break;
				}
			}catch (err:Dynamic)
			{
				//No new msgs
			}
			
		}
		client.shutdown(true, true);
		client.close();
		
	}*/
	
	function createServer() 
	{
		server = new Server();
		server.start("localhost", 30303, function() {
			server.addEventCallback(NetEvent.CLIENT_CONNECTED, unityConnected);
			server.addEventCallback(NetEvent.CLIENT_DISCONNECTED, unityDisconnected);
		});
	}
	
	function unityConnected(n:NetCallback) {
		DC.clearConsole();
		DC.log("\nUniVRse OOnity App connected!", 0x00D500);
		
		var wasConnected = false;
		
		if (unity != null) wasConnected = true;
		unity = n.client;
		objectIDMap = new Map<Int, Objects>();
		
		if (wasConnected) return;
		
		DC.log("Check out your new commands! (Remeber COMMANDS and HELP)", 0x80FF00);
		DC.registerCommand(checkIDs, "checkIDs", "ids", "Recalls IDs of created objects", Assets.getText("assets/data/checkIDsHelp.txt"));
		DC.registerCommand(letThereBe, "letThereBe", "make", "Create something!", Assets.getText("assets/data/LetThereBeHelp.txt"));
		
		server.removeEventCallback(NetEvent.CLIENT_CONNECTED, unityConnected);
	}
	
	
	function unityDisconnected(n:NetCallback) {
		DC.clearConsole();
		DC.logError("OOnity App disconnected.");
		
		//Wait for reconnection
		server.addEventCallback(NetEvent.CLIENT_CONNECTED, unityConnected);
	}
	
	function displayMultiline(text:String, color:Int = -1, finished:Void->Void = null) 
	{ 
		var lines = text.split("\n");
		var count = 0;
		new FlxTimer(0.05, function(t:FlxTimer) {
			var line = lines[count];
			if (line != "") DC.log(line, color);
			count++;
			if (count == lines.length && finished!=null) finished();
		}, lines.length);
	}
	
	
	function letThereBe(params:Array<String>):Void 
	{
		if (params.length < 4 || params.length > 5) {
			DC.logError("Incorrect arguments.");
			return;
		}
		
		var object;
		var radius;
		var angleXY;
		var angleYZ;
		var orbits;
		
		//Object string to enum
		try {
			object = Type.createEnum(Objects, Std.string(params[0]).toUpperCase());
		}catch (err:Dynamic){
			//Was not on enums
			DC.logError(Std.string(params[0]).toUpperCase() + " is not a valid object!");
			return;
		}
		
		//Other params to correct type
		try {
			radius = Std.parseFloat(params[1]);
			angleXY = Std.parseFloat(params[2]);
			angleYZ = Std.parseFloat(params[3]);
			orbits = (params.length > 4) ? Std.parseInt(params[4]) : -1;
		}catch (err:Dynamic) {
			//Other errors
			DC.logError("Invalid arguments.");
			return;
		}
		
		if (orbits!=-1 && objectIDMap.get(orbits) == null) {
			DC.logError("No object with ID " + orbits);
			return;
		}
		
		//Newly created object ID
		var createdId = FlxRandom.int();
		while (objectIDMap.get(createdId) != null) createdId = FlxRandom.int();
		
		//Finalize and send everything
		objectIDMap.set(createdId, object);
		
		var infoToSend:MessageStruct = { type: MsgType.COMMAND,
										command: Commands.LET_THERE_BE,
										object: object,
										radius: radius,
										angleXY:angleXY,
										angleYZ:angleYZ,
										orbits:orbits,
										createdID:createdId
										}
		
		
		server.sendMessage(infoToSend, unity);
		
		//"Return" new ID
		DC.log("Created " + Std.string(object) + " with ID " + createdId, 0x00FF00);
	}
	
	function checkIDs(params:Array<String>):Void 
	{
		displayMultiline(~/,/g.replace(objectIDMap.toString(), "\n"));
	}
	
	function closeFunc(params:Array<String>):Void {
		unity.socket.shutdown(true, true);
		unity.socket.close();
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		super.update();
	}
	
}
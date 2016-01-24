package net;
import cpp.net.ThreadServer;
import flixel.util.FlxRandom;
import haxe.ds.EnumValueMap;
import haxe.io.Bytes;
import net.Client;
import pgr.dconsole.DC;
import sys.net.Socket;

typedef EventDetails = {
	var client:Client;
	@:optional var message:String;
}

/**
 * ...
 * @author Miguel M.
 */
class Server extends ThreadServer<Client, ServerMessage>
{
	public static inline var CLOSING_CHAR:String = ";";
	
	public var clientMap:Map<Int, Client>;
	public var connected:Bool;
	
	private var eventMap:EnumValueMap<NetEvent, Array<NetCallback->Void>>; //Just gonna makedo event system
	
	public function new() 
	{
		super();
	}
	
	public function start(host:String = "localhost", port:Int = 30303, setupCompleteCallback:Void->Void = null) {
		clientMap = new Map<Int,Client>();
		
		connected = false;
		
		eventMap = new EnumValueMap<NetEvent, Array<NetCallback->Void>>();
		for (event in Type.allEnums(NetEvent)) eventMap.set(event, []);
		
		setupCompleteCallback();
		
		run(host, port);
	}
	
	override public function clientConnected(s:sys.net.Socket):Client 
	{
		var data = s.host();
		var newClient:Client = { host:data.host, port:data.port, id:FlxRandom.int(), socket:s };
		clientMap.set(newClient.id, newClient);
		
		trace(newClient + " has connected.");
		
		connected = true;
		dispatchEvent(NetEvent.CLIENT_CONNECTED, {client:newClient});
		
		return newClient;
	}
	
	override public function clientDisconnected(c:Client) 
	{
		clientMap.remove(c.id);
		
		trace(c + " has disconnected.");
		
		connected = false;
		dispatchEvent(NetEvent.CLIENT_DISCONNECTED, {client:c});
	}
	
	override public function readClientMessage(c:Client, buf:haxe.io.Bytes, pos:Int, len:Int):{msg:ServerMessage, bytes:Int} 
	{
		// find out if there's a full message, and if so, how long it is.
		var complete = false;
		var cpos = pos;
		while (cpos < (pos+len) && !complete)
		{
		 //check for a period/full stop (i.e.:  "." ) to signify a complete message 
		  complete = (buf.get(cpos) == 46);
		  cpos++;
		}
		
		// no full message
		if( !complete ) return null;
		
		// got a full message, return it
		var msg:String = buf.getString(pos, cpos - pos);
		
		return {msg: {string: msg}, bytes: cpos-pos};
	}

	override function clientMessage( c : Client, msg : ServerMessage )
	{
		trace(c.id + " sent: " + msg.string);
		
		dispatchEvent(NetEvent.MESSAGE_RECIEVED, { client:c, message:msg.string } );
	}
	
	public function sendMessage(msg:MessageStruct, client:Client) {
		if (!connected) {
			DC.logError("Not connected.");
			return;
		}
		
		var str = Std.string(msg) + CLOSING_CHAR;
		trace("Sending " + str + " to client " + client.id);
		
		var sentIndex:Int = 0;
		while (sentIndex < str.length) {
			var endIndex = Std.int(MathHelper.clamp(sentIndex + 10, 0, str.length)); //Send 10 chars max at a time
			
			client.socket.output.writeString(str.substring(sentIndex, endIndex));
			client.socket.output.flush();
			
			sentIndex = endIndex;
		}
	}
	
	public function sendString(msg:String, client:Client) {
		if (!connected) {
			DC.logError("Not connected.");
			return;
		}
		
		client.socket.output.writeString(msg + CLOSING_CHAR);
		client.socket.output.flush();
	}
	
	//
	// ********************************* MAKE DO EVENT SYSTEM *********************************
	//
	
	public function addEventCallback(event:NetEvent, callback:NetCallback->Void) {
		eventMap.get(event).push(callback);
	}
	
	public function removeEventCallback(event:NetEvent, callback:NetCallback->Void) {
		eventMap.get(event).remove(callback);
	}
	
	public function removeCallbackByName(event:NetEvent, callbackName:String) {
		var callbackArray = eventMap.get(event);
		var functionToRemove = Reflect.field(callbackArray, callbackName);
		
		if (functionToRemove != null) callbackArray.remove(functionToRemove);
	}
	
	private function dispatchEvent(event:NetEvent, details:EventDetails) {
		for (callback in eventMap.get(event)) {
			Reflect.callMethod(this, callback, [{event:event, client:details.client, message:details.message}]);
		}
	}
	
}
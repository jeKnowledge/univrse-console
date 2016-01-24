package net;
import sys.net.Host;
import sys.net.Socket;

/**
 * @author Miguel M.
 */
typedef Client =
{
	var port:Int;
	var host:Host;
	var socket:Socket;
	@:optional var id:Int;
}
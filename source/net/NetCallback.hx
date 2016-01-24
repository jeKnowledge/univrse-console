package net;

/**
 * @author Miguel M.
 */
typedef NetCallback =
{
	var event:NetEvent;
	var client:Client;	
	@:optional var message:String;
}
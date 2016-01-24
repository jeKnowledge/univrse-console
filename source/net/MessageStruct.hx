package net;
import net.MsgType;

/**
 * @author Miguel M.
 */
typedef MessageStruct =
{
	var type:MsgType;
	
	//Let there be params
	@:optional var command:Commands;
	@:optional var object:Objects;
	@:optional var radius:Float;
	@:optional var angleXY:Float;
	@:optional var angleYZ:Float;
	@:optional var orbits:Int;
	@:optional var createdID:Int;
}
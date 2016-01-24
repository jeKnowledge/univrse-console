package;

/**
 * ...
 * @author Miguel M.
 */
class MathHelper
{

	public function new() 
	{
		
	}
	
	
	public static function clamp(value:Float, min:Float, max:Float):Float {
		if (value < min) return min;
		if (value > max) return max;
		return value;
	}
}
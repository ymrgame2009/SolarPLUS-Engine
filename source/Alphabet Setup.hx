package ...;


class Alphabet ... {

    // Import this variable into your Alphabet.hx
    public var disntanceOffset:FlxPoint = new FlxPoint(0, 0);

    // Next you will want to find the spot where the x and y is calculated for `isMenuItem`
    // Ex. update

    override public function update(elapsed:Float):Void
    {
        // Revise this code to add distanceOffset at the end of all the math, post `+ startPosition.` for x and y.
        if (isMenuItem)
		{
			var lerpVal:Float = Math.exp(-elapsed * 9.6);
			if(changeX)
				x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x + distanceOffset.x, x, lerpVal);
			if(changeY)
				y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y + distanceOffset.y, y, lerpVal);
		}
        super.update(elapsed);
    }

    // That's it! Now you have distanceOffset!
}
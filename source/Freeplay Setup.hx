package ...;


class FreeplayState ... {

    // Import these variables into the class of your FreeplayState
    var mask:FlxSprite = null;

	public var musicPlayer:MusicPlayer;

    // under the `create` function add these things
    add(musicPlayer = new MusicPlayer());
    musicPlayer.controls = this.controls;
    musicPlayer.onUpdateUI.add(function(activate, onComplete) {
        for (song in grpSongs.members) {
            if (song == grpSongs.members[curSelected]) {
                FlxTween.tween(song.distanceOffset, {x: activate ? 245 : 0}, 2, {ease: FlxEase.circOut, onComplete: onComplete});
                continue;
            }
            FlxTween.tween(song, {alpha: activate ? 0 : 0.6}, 2, {ease: FlxEase.smoothStepOut});
        }
        for (icon in iconArray) {
            if (icon == iconArray[curSelected]) continue;
            FlxTween.tween(icon, {alpha: activate ? 0 : 1}, 1, {ease: FlxEase.smoothStepOut});
        }
        FlxTween.tween(mask, {alpha: activate ? 0.7 : 0}, 1, {ease: FlxEase.sineIn});
    });

    // Ex.    
    override public function create():Void {
        ...

        // Add the mask / bg behind the alphabet of the songs
        // Ex.
        mask = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		mask.alpha = 0;
		add(mask);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
        ...

        // Put these somewhere in front all the other stuff to make it priority to draw / the most top sprite to load
        add(musicPlayer = new MusicPlayer());
        musicPlayer.controls = this.controls;
        musicPlayer.onUpdateUI.add(function(activate, onComplete) {
            for (song in grpSongs.members) {
                if (song == grpSongs.members[curSelected]) {
                    FlxTween.tween(song.distanceOffset, {x: activate ? 245 : 0}, 2, {ease: FlxEase.circOut, onComplete: onComplete});
                    continue;
                }
                FlxTween.tween(song, {alpha: activate ? 0 : 0.6}, 2, {ease: FlxEase.smoothStepOut});
            }
            for (icon in iconArray) {
                if (icon == iconArray[curSelected]) continue;
                FlxTween.tween(icon, {alpha: activate ? 0 : 1}, 1, {ease: FlxEase.smoothStepOut});
            }
            FlxTween.tween(mask, {alpha: activate ? 0.7 : 0}, 1, {ease: FlxEase.sineIn});
        });
        ...
        super.create();
    }

    // Next you will want to find a spot that edits the scoreText
    // Ex. update

    override public function update(elapsed:Float):Void
    {
        // Should be the most top-ish code to override the main freeplay input and stuff 
        if (musicPlayer.listening) 
		{
			scoreText.text = 'Listening To: ' + songs[curSelected].songName.toUpperCase();
            super.update(elapsed);
            return;
        }

        // Find where if (space) is located
        if (space) // Under here replace EVERYTHING with just musicPlayer.load(songs[curSelected], curDifficulty);
            musicPlayer.load(songs[curSelected], curDifficulty);

        ...
    }

    // Next, Delete all `destroyFreeplayVocals` refrences from Your engine, these are no longer needed.
    // After that, remember to also remove all vocals and opponentVocals references to your psych FreeplayState (they're included in MusicPlayer by default!)
    /**
     * 
     * ```haxe
     * destroyFreeplayVocals(); // <- should remove this function in general from even freeplay
     * ```
     * 
    **/

    // Lastly, customization your setup of the music player and have fun :D!
}
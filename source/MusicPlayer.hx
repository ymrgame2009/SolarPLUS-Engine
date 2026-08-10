package;

import flixel.text.FlxText;
import flixel.*;
import flixel.group.*;
import flixel.system.*;
import flixel.util.FlxSignal;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.input.keyboard.FlxKey;
import Song;
import FreeplayState;

@:allow(FreeplayState)
class MusicPlayer extends FlxSpriteGroup 
{   
    public var onUpdateUI:FlxTypedSignal<(Bool, FlxTween->Void)->Void> = new FlxTypedSignal();
    public var controls:Controls;

    public var listening:Bool = false;
    public var finishedIntro:Bool = false;

    public var playbackRate(default, set):Float = 1;
    public var paused(get, never):Bool; 

    private function get_paused():Bool
        return !FlxG.sound.music.playing;

    private var songProgress:Float = 0;

    private var progressBar:PsychBar;
    private var progressTxt:FlxText;

    private var playbackSymbols:Array<FlxText> = [];
    private var playbackTxt:FlxText;

    private var opponentVocals:FlxSound;
    private var vocals:FlxSound;

    public function new() 
    {
        super();

        FlxG.sound.list.add(opponentVocals = new FlxSound());
        FlxG.sound.list.add(vocals = new FlxSound());

        progressTxt = new FlxText(0, 0, 500, "", 25).setFormat(Paths.font("funkin.ttf"), 25, FlxColor.WHITE, LEFT);
        progressTxt.alpha = 0;

        progressBar = new PsychBar(0, 0, 'healthBarEmpty', function() return songProgress, 0, FlxG.sound.music.length);
        progressBar.screenCenter(XY);
        progressBar.y += 100;
        progressBar.setColors(FlxColor.WHITE, FlxColor.BLACK);
        progressBar.alpha = 0;
        progressTxt.setPosition(progressBar.x, progressBar.y + 40);
        add(progressBar);
        add(progressTxt);

        for (i in 0...2)
        {
            final text:FlxText = new FlxText().setFormat(Paths.font('funkin.ttf'), 32, FlxColor.WHITE, CENTER);
            text.text = '^';
            text.flipY = (i == 1);
            text.alpha = 0;
            playbackSymbols.push(text);
            add(text);
        }
        
        playbackTxt = new FlxText(progressTxt.x + progressBar.barWidth, progressTxt.y, 0, "", 32);
        playbackTxt.setFormat(Paths.font("funkin.ttf"), 32, FlxColor.WHITE);
        playbackTxt.alpha = 0;
        add(playbackTxt);
    }

    public function updateUI(activate:Bool, onComplete:FlxTween->Void):Void {
        onUpdateUI.dispatch(activate, onComplete);
        FlxTween.tween(progressBar, {alpha: activate ? 1 : 0}, 2, {ease: FlxEase.circOut});
        FlxTween.tween(progressTxt, {alpha: activate ? 1 : 0}, 2, {ease: FlxEase.circOut});
        FlxTween.tween(playbackTxt, {alpha: activate ? 1 : 0}, 2, {ease: FlxEase.circOut});
        for (text in playbackSymbols)
            FlxTween.tween(text, {alpha: activate ? 1 : 0}, 2, {ease: FlxEase.circOut});
        progressBar.setBounds(0, activate ? FlxG.sound.music.length : Math.POSITIVE_INFINITY);
    }

    public function resync() 
    {
        if (paused || userPaused) return;
        var shouldResync:Bool = false;
        forEachSound(sound -> {
            if (shouldResync) return;
            shouldResync = (sound.length > FlxG.sound.music.time && Math.abs(FlxG.sound.music.time - sound.time) >= 25);
        }, [vocals, opponentVocals]);

        if (shouldResync)
        {
            forEachSound(sound -> sound.pause());
            forEachSound(sound -> sound.time = FlxG.sound.music.time, [vocals, opponentVocals]);
            if (!userPaused)
                forEachSound(sound -> sound.resume());
        }
    }

    private var wasPlaying:Bool = false;
    private var holdTime:Float = 0;
    private var holdPitchTime:Float = 0;
    private var userPaused:Bool = false;
    private var curTime:Float = 0;

    override public function update(elapsed:Float) {
        if (!listening) {
            super.update(elapsed);
            return;
        }

        if (!finishedIntro)
        {
            updateUI(true, null);
            userPaused = false;
            finishedIntro = true;
            return;
        }

        if (FlxG.sound.music.time >= FlxG.sound.music.length) 
        {
            forEachSound(sound -> sound.time = FlxG.sound.music.time);
            forEachSound(sound -> sound.play());
        }
        
        if (FlxG.keys.justPressed.SPACE) 
        {
            userPaused = !userPaused;
            forEachSound(sound -> (!userPaused ? sound.resume : sound.pause)());
        }
        
        if (controls.UI_LEFT_P || controls.UI_RIGHT_P) 
        {
            if (!paused && !userPaused)
            {
                wasPlaying = true;
                forEachSound(sound -> sound.pause());
            }

            curTime = FlxG.sound.music.time + ((controls.UI_LEFT_P ? -1 : 1) * 1000);
            holdTime = 0;

            final adjust:Bool = (controls.UI_LEFT_P ? curTime < FlxG.sound.music.loopTime : curTime > FlxG.sound.music.length);
            if (adjust)
                curTime = controls.UI_LEFT_P ? FlxG.sound.music.loopTime : FlxG.sound.music.length;

            forEachSound(sound -> sound.time = curTime);
        }
        
        if(controls.UI_LEFT || controls.UI_RIGHT)
        {
            holdTime += elapsed;
            if (holdTime > 0.5)
                curTime += 40000 * elapsed * (controls.UI_LEFT ? -1 : 1);
            final difference:Float = Math.abs(curTime - FlxG.sound.music.time);
            if(curTime + difference > FlxG.sound.music.length) curTime = FlxG.sound.music.length;
            else if(curTime - difference < FlxG.sound.music.loopTime) curTime = FlxG.sound.music.loopTime;

            forEachSound(sound -> sound.time = curTime);
        }

        if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
        {
            forEachSound(sound -> sound.time = curTime);
            if (wasPlaying)
            {
                forEachSound(sound -> sound.resume());
                wasPlaying = false;
            }
        }

        if (controls.UI_UP_P || controls.UI_DOWN_P)
        {
            holdPitchTime = 0;
            playbackRate += ((controls.UI_UP_P ? 1 : -1) * 0.05);
        }

        if (controls.UI_DOWN || controls.UI_UP)
        {
            holdPitchTime += elapsed;
            if (holdPitchTime > 0.6)
                playbackRate += 0.05 * (controls.UI_UP ? 1 : -1);
        }
        
        if (controls.RESET) 
        {
            playbackRate = 1;
            forEachSound(sound -> {
                sound.time = FlxG.sound.music.loopTime;
                sound.pitch = FlxG.sound.music.pitch;
            });
        }
        
        if (controls.BACK) 
        {
            userPaused = true;
            FlxG.sound.music.stop();
            playbackRate = 1;
            updateUI(false, function(t) {
                listening = false;
                finishedIntro = false;
                playbackRate = 1;
            });
            
            if (vocals != null) vocals.stop();
            if (opponentVocals != null) opponentVocals.stop();
            
            FlxG.sound.playMusic(Paths.music("freakyMenu-" + ClientPrefs.mmm));
        }

        resync();
        updateProgressInfo(elapsed);
        super.update(elapsed);
    }

    public function updateProgressInfo(elapsed:Float)
    {
        for (i in 0...2)
        {
            final sym:FlxText = playbackSymbols[i];
            sym.setPosition(playbackTxt.x + playbackTxt.width / 2 - 10, playbackTxt.y);
            sym.y += playbackTxt.height * ((i == 0) ? -1 : 1);
        }

        songProgress = FlxMath.lerp(FlxG.sound.music.time, songProgress, Math.exp(-elapsed * 15));
        var timeStr:String = FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false);
        var lengthStr:String = FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false);
        progressTxt.text = 'Time: < $timeStr / $lengthStr >';

        var rateStr:String = '';
        if (playbackRate == Math.floor(playbackRate))
            rateStr = playbackRate + '.00';
        else
        {
            rateStr = Std.string(playbackRate);
            if (rateStr.split('.')[1].length < 2)
                rateStr += '0';
        }

        playbackTxt.text = rateStr + 'x';
    }

    public function load(data:FreeplayState.SongMetadata, difficulty:Int) 
    {
        if (data == null) return;
        final name:String = data.songName.toLowerCase();
        final fullPath:String = Highscore.formatSong(name, difficulty);
        final file:SwagSong = PlayState.SONG = Song.loadFromJson(fullPath, name);
        if (file == null) return;

        FlxG.sound.music.volume = 0;
        Paths.currentModDirectory = data.folder;
        progressTxt.borderColor = (data.color == FlxColor.BLACK) ?
            FlxColor.WHITE : (data.color == FlxColor.WHITE) ? FlxColor.BLACK : FlxColor.TRANSPARENT;
        progressTxt.color = FlxColor.fromInt(data.color);
        progressBar.leftBar.color = FlxColor.fromInt(data.color);

        vocals.stop();
        vocals.loadEmbedded(null);
        opponentVocals.stop();
        opponentVocals.loadEmbedded(null);

        if (PlayState.SONG.needsVoices)
        {
            try {
                final vocalsSound:openfl.media.Sound = Paths.voices(name);
                if (vocalsSound != null && vocalsSound.length > 0)
                {
                    vocals.loadEmbedded(vocalsSound);
                    vocals.play();
                    vocals.volume = 0.7;
                }
            } catch(e:Dynamic) {
                trace('No vocals found for: ' + name);
            }
        }

        FlxG.sound.playMusic(Paths.inst(file.song), 0.7);
        resync();

        Conductor.changeBPM(PlayState.SONG.bpm);
        Conductor.mapBPMChanges(PlayState.SONG);
        listening = true;
    }

    override public function destroy():Void {
        if (vocals != null) 
        {
            FlxG.sound.list.remove(vocals);
            vocals.destroy();
        }
        if (opponentVocals != null) 
        {
            FlxG.sound.list.remove(opponentVocals);
            opponentVocals.destroy();
        }
        
        onUpdateUI.removeAll();
        super.destroy();
    }

    public function forEachSound(f:FlxSound->Void, ?filter:Array<FlxSound> = null) {
        for (sound in [FlxG.sound.music, vocals, opponentVocals]) {
            if (sound == null || (@:privateAccess sound._sound) == null || (filter != null && !filter.contains(sound))) continue;
            f(sound);
        }
    }

    function set_playbackRate(value:Float):Float 
    {
        var value:Float = FlxMath.roundDecimal(value, 2);
        if (value > 3) value = 3;
        else if (value <= 0.25) value = 0.25;
        forEachSound(sound -> sound.pitch = value);
        return playbackRate = value;
    }

}
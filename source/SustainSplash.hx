package;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import shaders.RGBPalette;

using StringTools;

class SustainSplash extends FlxSprite
{
    public var rgbShader:NoteSplash.PixelSplashShaderRef;

    public static var startCrochet:Float = 0;
    public static var frameRate:Int = 24;

    public var strumNote:StrumNote;
    public var parentNote:Note;

    var timer:FlxTimer;
    // Default skin for the hold splash
    public static var defaultNoteHoldSplash(default, never):String = 'holdCover/holdCover';

    public function new():Void
    {
        super();
        rgbShader = new NoteSplash.PixelSplashShaderRef();
        if (rgbShader != null)
            shader = rgbShader.shader;

        reloadFrames();
        scrollFactor.set();
    }

    public function reloadFrames():Void
    {
        var skin:String = defaultNoteHoldSplash + getSplashSkinPostfix();
        frames = Paths.getSparrowAtlas(skin);
        if (frames == null)
        {
            skin = defaultNoteHoldSplash;
            frames = Paths.getSparrowAtlas(skin);
        }

        if (frames != null)
        {
            if (animation.getByName('hold') == null)
                animation.addByPrefix('hold', 'hold', 24, true);
            if (animation.getByName('end') == null)
                animation.addByPrefix('end', 'end', 24, false);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (strumNote != null)
        {
            setPosition(strumNote.x, strumNote.y);
            visible = strumNote.visible;
            
            // Adjust alpha based on strumNote's alpha and ClientPrefs holdSplashAlpha
            var baseAlpha:Float = Reflect.hasField(ClientPrefs, 'holdSplashAlpha') ? Reflect.field(ClientPrefs, 'holdSplashAlpha') : 1;
            alpha = baseAlpha - (1 - strumNote.alpha);

            if (!strumNote.alive || (parentNote != null && (parentNote.wasGoodHit && parentNote.sustainLength <= 0)))
            {
                kill();
            }
        }
    }

    public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Dynamic = 1):Void
    {
        if (strum == null || daNote == null)
        {
            kill();
            return;
        }

        if (frames == null)
            reloadFrames();

        revive();
        alive = true;
        exists = true;
        visible = true;

        strumNote = strum;
        parentNote = daNote;

        var baseAlpha:Float = Reflect.hasField(ClientPrefs, 'holdSplashAlpha') ? Reflect.field(ClientPrefs, 'holdSplashAlpha') : 1;
        alpha = baseAlpha - (1 - strumNote.alpha);

        antialiasing = ClientPrefs.globalAntialiasing;
        if (PlayState.isPixelStage || !ClientPrefs.globalAntialiasing)
            antialiasing = false;

        var rate:Float = Std.isOfType(playbackRate, Float) ? playbackRate : (Std.isOfType(playbackRate, Int) ? playbackRate : 1.0);
        var remainingTime:Float = daNote.sustainLength - (Conductor.songPosition - daNote.strumTime);
        var timeThingy:Float = (remainingTime > 0 ? remainingTime : 0.1) / (rate > 0 ? rate : 1) / 1000;

        if (animation.getByName('hold') != null)
        {
            animation.play('hold', true, false, 0);
            if (animation.curAnim != null)
            {
                animation.curAnim.frameRate = 24;
                animation.curAnim.looped = true;
            }
        }

        if (ClientPrefs.enableColorShader && rgbShader != null)
            shader = rgbShader.shader;
        else
            shader = null;

        clipRect = new FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

        if (daNote.rgbShader != null && rgbShader != null)
        {
            var tempShader:RGBPalette = null;
            if ((daNote.noteSplashData == null || daNote.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
            {
                if (daNote.noteSplashData != null && !daNote.noteSplashData.useGlobalShader)
                {
                    if (daNote.noteSplashData.r != -1) daNote.rgbShader.r = daNote.noteSplashData.r;
                    if (daNote.noteSplashData.g != -1) daNote.rgbShader.g = daNote.noteSplashData.g;
                    if (daNote.noteSplashData.b != -1) daNote.rgbShader.b = daNote.noteSplashData.b;
                    tempShader = daNote.rgbShader.parent;
                }
                else if (Note.globalRgbShaders != null && Note.globalRgbShaders.length > daNote.noteData)
                {
                    tempShader = Note.globalRgbShaders[daNote.noteData];
                }
            }
            if (tempShader != null)
                rgbShader.copyValues(tempShader);
        }

        if (timer != null)
            timer.cancel();

        offset.set(PlayState.isPixelStage ? 112.5 : 110, 100);
        setPosition(strumNote.x, strumNote.y);

        timer = new FlxTimer().start(timeThingy, function(tmr:FlxTimer)
        {
            if (daNote.mustPress && animation.getByName('end') != null)
            {
                animation.play('end', true, false, 0);
                if (animation.curAnim != null)
                {
                    animation.curAnim.looped = false;
                    animation.curAnim.frameRate = 24;
                }
                clipRect = null;
                animation.finishCallback = function(animName:String)
                {
                    x = -50000;
                    kill();
                };
            }
            else
            {
                x = -50000;
                kill();
            }
        });
    }

    public static function getSplashSkinPostfix():String
    {
        return '';
    }
}
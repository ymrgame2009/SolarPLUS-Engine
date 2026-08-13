package;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import shaders.RGBPalette;

using StringTools;

typedef HoldCoverConfig = {
    holdAnim:String,
    endAnim:String,
    holdFps:Int,
    endFps:Int,
    offsets:Array<Array<Float>>
}

class SustainSplash extends FlxSprite
{
    public var rgbShader:NoteSplash.PixelSplashShaderRef;

    public static var startCrochet:Float = 0;
    public static var frameRate:Int = 24;
    public static var configs:Map<String, HoldCoverConfig> = new Map<String, HoldCoverConfig>();

    public var strumNote:StrumNote;
    public var parentNote:Note;

    var timer:FlxTimer;
    public var _configLoaded:String = null;
    public var _textureLoaded:String = null;
    // Default skin for the hold splash
    public static var defaultNoteHoldSplash(default, never):String = 'holdCover/holdCover';

    public function new():Void
    {
        super();
        rgbShader = new NoteSplash.PixelSplashShaderRef();
        if (rgbShader != null)
            shader = rgbShader.shader;

        var skin:String = defaultNoteHoldSplash + getSplashSkinPostfix();
        precacheConfig(skin);
        _configLoaded = skin;
        reloadFrames();
        scrollFactor.set();
    }

    override function destroy()
    {
        configs.clear();
        super.destroy();
    }

    public function reloadFrames():Void
    {
        var skin:String = (_textureLoaded != null) ? _textureLoaded : defaultNoteHoldSplash + getSplashSkinPostfix();
        frames = Paths.getSparrowAtlas(skin);
        if (frames == null)
        {
            skin = defaultNoteHoldSplash;
            frames = Paths.getSparrowAtlas(skin);
        }

        var config:HoldCoverConfig = precacheConfig(_configLoaded);
        var holdAnim:String = (config != null) ? config.holdAnim : 'hold';
        var endAnim:String = (config != null) ? config.endAnim : 'end';
        var holdFps:Int = (config != null && config.holdFps > 0) ? config.holdFps : 24;
        var endFps:Int = (config != null && config.endFps > 0) ? config.endFps : 24;

        if (frames != null)
        {
            if (animation.getByName('hold') == null)
                animation.addByPrefix('hold', holdAnim, holdFps, true);
            if (animation.getByName('end') == null)
                animation.addByPrefix('end', endAnim, endFps, false);
        }
    }

    public static function precacheConfig(skin:String):HoldCoverConfig
    {
        if(configs.exists(skin)) return configs.get(skin);

        var configFile:Array<String> = [];

        #if sys
        var modPngPath:String = Paths.modFolders('images/$skin.png');
        if (modPngPath != null && modPngPath.length > 0 && sys.FileSystem.exists(modPngPath))
        {
            var txtPath:String = modPngPath.substr(0, modPngPath.length - 4) + '.txt';
            if (sys.FileSystem.exists(txtPath))
            {
                var content:String = sys.io.File.getContent(txtPath).replace('\r', '');
                configFile = content.split('\n');
            }
        }
        else
        {
            var basePath:String = Paths.getPath('images/$skin.png', IMAGE);
            if (basePath != null && basePath.length > 0)
            {
                if (basePath.startsWith('file://')) basePath = basePath.substr(7);
                var colonPos = basePath.indexOf(':');
                if (colonPos > 1) basePath = basePath.substr(colonPos + 1);

                var absPath:String = sys.FileSystem.absolutePath(basePath).replace('\\', '/');
                var txtPath:String = absPath.substr(0, absPath.length - 4) + '.txt';

                if (sys.FileSystem.exists(txtPath))
                {
                    var content:String = sys.io.File.getContent(txtPath).replace('\r', '');
                    configFile = content.split('\n');
                }
            }
        }
        #end

        if(configFile.length < 10) return null;

        var holdAnim:String = StringTools.trim(configFile[0]);
        var endAnim:String = StringTools.trim(configFile[1]);
        var fpsArr:Array<String> = configFile[2].split(' ');
        var holdFps:Int = Std.parseInt(StringTools.trim(fpsArr[0]));
        var endFps:Int = Std.parseInt(StringTools.trim(fpsArr[1]));

        var offs:Array<Array<Float>> = [];
        for (i in 3...configFile.length)
        {
            var animOffs:Array<String> = configFile[i].split(' ');
            offs.push([Std.parseFloat(StringTools.trim(animOffs[0])), Std.parseFloat(StringTools.trim(animOffs[1]))]);
        }

        var config:HoldCoverConfig = {
            holdAnim: holdAnim,
            endAnim: endAnim,
            holdFps: holdFps,
            endFps: endFps,
            offsets: offs
        };
        configs.set(skin, config);
        return config;
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

        var config:HoldCoverConfig = precacheConfig(_configLoaded);
        var holdFps:Int = (config != null && config.holdFps > 0) ? config.holdFps : 24;
        var defaultOffX:Float = PlayState.isPixelStage ? 112.5 : 110;
        var defaultOffY:Float = 100;
        var noteDir:Int = daNote.noteData;
        var offArr:Array<Float> = [defaultOffX, defaultOffY];

        if (config != null && config.offsets != null && config.offsets.length > 0)
        {
            var offIdx:Int = noteDir % 4;
            if (offIdx >= 0 && offIdx < config.offsets.length)
                offArr = config.offsets[offIdx];
        }

        if (animation.getByName('hold') != null)
        {
            animation.play('hold', true, false, 0);
            if (animation.curAnim != null)
            {
                animation.curAnim.frameRate = holdFps;
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

        offset.set(offArr[0], offArr[1]);
        setPosition(strumNote.x, strumNote.y);

        timer = new FlxTimer().start(timeThingy, function(tmr:FlxTimer)
        {
            if (daNote.mustPress && animation.getByName('end') != null)
            {
                var endFps:Int = (config != null && config.endFps > 0) ? config.endFps : 24;
                animation.play('end', true, false, 0);
                if (animation.curAnim != null)
                {
                    animation.curAnim.looped = false;
                    animation.curAnim.frameRate = endFps;
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
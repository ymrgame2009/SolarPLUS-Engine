package;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import shaders.RGBPalette;

using StringTools;

typedef HoldCoverConfig = {
    holdAnim:String,
    endAnim:String,
    holdFps:Int,
    endFps:Int,
    offsets:Array<Array<Float>>,
    ?scale:Float,
    ?allowRGB:Bool,
    ?allowPixel:Bool
}

class SustainSplash extends FlxSprite
{
    public var rgbShader:NoteSplash.PixelSplashShaderRef;

    public static var startCrochet:Float = 0;
    public static var frameRate:Int = 24;
    public static var configs:Map<String, HoldCoverConfig> = new Map<String, HoldCoverConfig>();

    public var strumNote:StrumNote;
    public var parentNote:Note;

    var endTime:Float = -1;
    var playbackRate:Float = 1;
    var hasEnded:Bool = false;
    public var _configLoaded:String = null;
    public var _textureLoaded:String = null;
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
        _textureLoaded = skin;
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

        // Always remove and re-add animations so they use the correct
        // frame prefixes for the CURRENT spritesheet (important when
        // recycling splashes with different skins).
        animation.remove('hold');
        animation.remove('end');

        if (frames != null)
        {
            animation.addByPrefix('hold', holdAnim, holdFps, true);
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

        // Collect all non-empty lines after the FPS line.
        var remaining:Array<String> = [];
        for (i in 3...configFile.length)
        {
            var line:String = StringTools.trim(configFile[i]);
            if(line.length > 0) remaining.push(line);
        }

        var offs:Array<Array<Float>> = [];
        var scale:Float = 1.0;
        var allowRGB:Bool = true;
        var allowPixel:Bool = true;

        // Detect extended config: last 3 lines = (single number, bool, bool)
        var n:Int = remaining.length;
        var hasExtended:Bool = (n >= 3
            && isSingleNumber(remaining[n-3])
            && isBoolToken(remaining[n-2])
            && isBoolToken(remaining[n-1]));

        var offsetLines:Int = hasExtended ? n - 3 : n;
        for (i in 0...offsetLines)
        {
            var animOffs:Array<String> = remaining[i].split(' ');
            if(animOffs.length >= 2) {
                var ox:Float = Std.parseFloat(StringTools.trim(animOffs[0]));
                var oy:Float = Std.parseFloat(StringTools.trim(animOffs[1]));
                if(!Math.isNaN(ox) && !Math.isNaN(oy))
                    offs.push([ox, oy]);
            }
        }

        if(hasExtended)
        {
            var parsedScale:Float = Std.parseFloat(StringTools.trim(remaining[n-3]));
            if(!Math.isNaN(parsedScale) && parsedScale > 0) scale = parsedScale;
            allowRGB = parseBool(remaining[n-2]);
            allowPixel = parseBool(remaining[n-1]);
        }

        var config:HoldCoverConfig = {
            holdAnim: holdAnim,
            endAnim: endAnim,
            holdFps: holdFps,
            endFps: endFps,
            offsets: offs,
            scale: scale,
            allowRGB: allowRGB,
            allowPixel: allowPixel
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

            var baseAlpha:Float = Reflect.hasField(ClientPrefs, 'holdSplashAlpha') ? Reflect.field(ClientPrefs, 'holdSplashAlpha') : 1;
            alpha = baseAlpha - (1 - strumNote.alpha);

            if (!strumNote.alive || (parentNote != null && (parentNote.wasGoodHit && parentNote.sustainLength <= 0)))
            {
                kill();
                return;
            }

            if (endTime >= 0 && !hasEnded && Conductor.songPosition >= endTime)
            {
                hasEnded = true;
                if (parentNote != null && parentNote.mustPress && animation.getByName('end') != null)
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
        playbackRate = rate;
        hasEnded = false;
        endTime = daNote.strumTime + daNote.sustainLength;

        var config:HoldCoverConfig = precacheConfig(_configLoaded);
        var holdFps:Int = (config != null && config.holdFps > 0) ? config.holdFps : 24;

        // Old working default offset
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

        // Read allowRGB / allowPixel / scale from config
        var allowRGB:Bool = true;
        var allowPixel:Bool = true;
        var useScale:Float = 1.0;
        if(config != null)
        {
            if(config.allowRGB != null) allowRGB = config.allowRGB;
            if(config.allowPixel != null) allowPixel = config.allowPixel;
            if(config.scale != null && config.scale > 0) useScale = config.scale;
        }

        // Apply RGB shader
        if (allowRGB && ClientPrefs.enableColorShader && rgbShader != null)
            shader = rgbShader.shader;
        else
            shader = null;

        // Apply pixel blocksize
        var pixel:Float = 1;
        if (PlayState.isPixelStage && allowPixel) pixel = PlayState.daPixelZoom;
        if (rgbShader != null && rgbShader.shader != null)
            rgbShader.shader.uBlocksize.value = [pixel, pixel];

        if (daNote.rgbShader != null && rgbShader != null)
        {
            var tempShader:RGBPalette = null;
            if (allowRGB && (daNote.noteSplashData == null || daNote.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
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

        // Apply scale FIRST, then clipRect (uses frameWidth/frameHeight), then offset
        scale.set(useScale, useScale);
        updateHitbox();

        // ClipRect: only apply the -210 pixel-stage clip for the DEFAULT skin.
        // Custom hold covers may have different frame sizes/layouts, so clipping
        // them would hide the entire hold animation.
        var isDefaultSkin:Bool = (_textureLoaded == null
            || _textureLoaded == defaultNoteHoldSplash
            || _textureLoaded == defaultNoteHoldSplash + getSplashSkinPostfix());
        var clipY:Float = 0;
        if (PlayState.isPixelStage && isDefaultSkin)
            clipY = -210;
        clipRect = new FlxRect(0, clipY, frameWidth, frameHeight);

        offset.set(offArr[0], offArr[1]);
        setPosition(strumNote.x, strumNote.y);
    }

    public static function getSplashSkinPostfix():String
    {
        return '';
    }

    // ----- Helpers for extended config parsing -----

    static function isBoolToken(s:String):Bool
    {
        var v:String = StringTools.trim(s).toLowerCase();
        return v == 'true' || v == 'false';
    }

    static function parseBool(s:String):Bool
    {
        var v:String = StringTools.trim(s).toLowerCase();
        return v == 'true' || v == '1';
    }

    static function isSingleNumber(s:String):Bool
    {
        var v:String = StringTools.trim(s);
        if(v.length == 0) return false;
        if(v.indexOf(' ') >= 0) return false;
        var lv:String = v.toLowerCase();
        if(lv == 'true' || lv == 'false') return false;
        var f:Float = Std.parseFloat(v);
        return !Math.isNaN(f);
    }
}
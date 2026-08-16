package;

import flixel.math.FlxMath;
import shaders.RGBPalette;

import flixel.system.FlxAssets.FlxShader;
import flixel.graphics.frames.FlxFrame;
using StringTools;

typedef NoteSplashConfig = {
    anim:String,
    minFps:Int,
    maxFps:Int,
    offsets:Array<Array<Float>>,
    ?scale:Float,
    ?allowRGB:Bool,
    ?allowPixel:Bool
}

class NoteSplash extends FlxSprite
{
    public var rgbShader:PixelSplashShaderRef;
    private var idleAnim:String;
    private var _textureLoaded:String = null;
    private var _configLoaded:String = null;

    public static var defaultNoteSplash(default, never):String = 'noteSplashes';
    public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        var skin:String = null;
        if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
        else skin = defaultNoteSplash + getSplashSkinPostfix();
        
        rgbShader = new PixelSplashShaderRef();
        shader = rgbShader.shader;
        precacheConfig(skin);
        _configLoaded = skin;
        scrollFactor.set();
    }

    override function destroy()
    {
        configs.clear();
        super.destroy();
    }

    var maxAnims:Int = 2;
    public function setupNoteSplash(x:Float, y:Float, direction:Int = 0, ?note:Note = null, skin:String) {
        setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
        aliveTime = 0;

        var texture:String = null;
        if(note != null && note.noteSplashData.texture != null) texture = note.noteSplashData.texture;
        else if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
        else texture = defaultNoteSplash;
        
        var config:NoteSplashConfig = null;
        if(_textureLoaded != texture)
            config = loadAnims(texture);
        else
            config = precacheConfig(_configLoaded);

        // Read allowRGB / allowPixel / scale from config (default true / 1.0 if missing)
        var allowRGB:Bool = true;
        var allowPixel:Bool = true;
        var useScale:Float = 1.0;
        if(config != null)
        {
            if(config.allowRGB != null) allowRGB = config.allowRGB;
            if(config.allowPixel != null) allowPixel = config.allowPixel;
            if(config.scale != null && config.scale > 0) useScale = config.scale;
        }

        var tempShader:RGBPalette = null;
        if(allowRGB && (note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
        {
            if(note != null && !note.noteSplashData.useGlobalShader)
            {
                if(note.noteSplashData.r != -1) note.rgbShader.r = note.noteSplashData.r;
                if(note.noteSplashData.g != -1) note.rgbShader.g = note.noteSplashData.g;
                if(note.noteSplashData.b != -1) note.rgbShader.b = note.noteSplashData.b;
                tempShader = note.rgbShader.parent;
            }
            else tempShader = Note.globalRgbShaders[direction];
        }

        alpha = ClientPrefs.splashAlpha;
        if(note != null) alpha = note.noteSplashData.a;
        rgbShader.copyValues(tempShader);

        // Apply pixel blocksize based on allowPixel and pixel stage
        var pixel:Float = 1;
        if(PlayState.isPixelStage && allowPixel) pixel = PlayState.daPixelZoom;
        rgbShader.shader.uBlocksize.value = [pixel, pixel];

        if(note != null) antialiasing = note.noteSplashData.antialiasing;
        if(PlayState.isPixelStage || !ClientPrefs.globalAntialiasing) antialiasing = false;

        _textureLoaded = texture;

        var animNum:Int = FlxG.random.int(1, maxAnims);
        animation.play('note' + direction + '-' + animNum, true);
        
        // Apply scale FIRST, then set offset (updateHitbox resets offset)
        scale.set(useScale, useScale);
        updateHitbox();

        // Keep the old working offset base (10, 10), then add config offsets
        offset.set(10, 10);

        var minFps:Int = 22;
        var maxFps:Int = 26;
        if(config != null)
        {
            var animID:Int = direction + ((animNum - 1) * Note.colArray.length);
            var offs:Array<Float> = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length-1)];
            offset.x += offs[0];
            offset.y += offs[1];
            minFps = config.minFps;
            maxFps = config.maxFps;
        }
        else
        {
            offset.x += 0;
            offset.y += 0;
        }

        // Safety check to prevent freezing on frame 1 if Framerate in txt is 0 or missing
        if (minFps <= 0) minFps = 22;
        if (maxFps <= 0 || maxFps < minFps) maxFps = minFps;

        if(animation.curAnim != null)
            animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
    }

    public static function getSplashSkinPostfix()
    {
        var skin:String = '';
        return skin;
    }

    function loadAnims(skin:String, ?animName:String = null):NoteSplashConfig {
        maxAnims = 0;
        frames = Paths.getSparrowAtlas(skin);
        var config:NoteSplashConfig = null;
        if(frames == null)
        {
            skin = defaultNoteSplash + getSplashSkinPostfix();
            frames = Paths.getSparrowAtlas(skin);
            if(frames == null)
            {
                skin = defaultNoteSplash;
                frames = Paths.getSparrowAtlas(skin);
            }
        }
        config = precacheConfig(skin);
        _configLoaded = skin;

        if(animName == null)
            animName = config != null ? config.anim : 'note splash';

        while(true) {
            var animID:Int = maxAnims + 1;
            for (i in 0...Note.colArray.length) {
                if (!addAnimAndCheck('note$i-$animID', '$animName ${Note.colArray[i]} $animID', 24, false)) {
                    return config;
                }
            }
            maxAnims++;
        }
    }

    public static function precacheConfig(skin:String)
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

        if(configFile.length < 1) return null;
        
        var framerates:Array<String> = configFile[1].split(' ');

        // Collect all non-empty lines after the FPS line.
        var remaining:Array<String> = [];
        for (i in 2...configFile.length)
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

        var config:NoteSplashConfig = {
            anim: configFile[0],
            minFps: Std.parseInt(framerates[0]),
            maxFps: Std.parseInt(framerates[1]),
            offsets: offs,
            scale: scale,
            allowRGB: allowRGB,
            allowPixel: allowPixel
        };
        configs.set(skin, config);
        return config;
    }

    function addAnimAndCheck(name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
    {
        var animFrames = [];
        @:privateAccess
        animation.findByPrefix(animFrames, anim);

        if(animFrames.length < 1) return false;
    
        animation.addByPrefix(name, anim, framerate, loop);
        return true;
    }

    static var aliveTime:Float = 0;
    static var buggedKillTime:Float = 0.5;
    override function update(elapsed:Float) {
        aliveTime += elapsed;
        if((animation.curAnim != null && animation.curAnim.finished) ||
            (animation.curAnim == null && aliveTime >= buggedKillTime)) kill();

        super.update(elapsed);
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

class PixelSplashShaderRef {
    public var shader:PixelSplashShader = new PixelSplashShader();

    public function copyValues(tempShader:RGBPalette)
    {
        var enabled:Bool = false;
        if(tempShader != null)
            enabled = true;

        if(enabled)
        {
            for (i in 0...3)
            {
                shader.r.value[i] = tempShader.shader.r.value[i];
                shader.g.value[i] = tempShader.shader.g.value[i];
                shader.b.value[i] = tempShader.shader.b.value[i];
            }
            shader.mult.value[0] = tempShader.shader.mult.value[0];
        }
        else shader.mult.value[0] = 0.0;
    }

    public function new()
    {
        shader.r.value = [0, 0, 0];
        shader.g.value = [0, 0, 0];
        shader.b.value = [0, 0, 0];
        shader.mult.value = [1];

        var pixel:Float = 1;
        if(PlayState.isPixelStage) pixel = PlayState.daPixelZoom;
        shader.uBlocksize.value = [pixel, pixel];
    }
}

class PixelSplashShader extends FlxShader
{
    @:glFragmentHeader('
        #pragma header
        
        uniform vec3 r;
        uniform vec3 g;
        uniform vec3 b;
        uniform float mult;
        uniform vec2 uBlocksize;

        vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
            vec2 blocks = openfl_TextureSize / uBlocksize;
            vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
            if (!hasTransform) {
                return color;
            }

            if(color.a == 0.0 || mult == 0.0) {
                return color * openfl_Alphav;
            }

            vec4 newColor = color;
            newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
            newColor.a = color.a;
            
            color = mix(color, newColor, mult);
            
            if(color.a > 0.0) {
                return vec4(color.rgb, color.a);
            }
            return vec4(0.0, 0.0, 0.0, 0.0);
        }')

    @:glFragmentSource('
        #pragma header

        void main() {
            gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
        }')

    public function new()
    {
        super();
    }
}
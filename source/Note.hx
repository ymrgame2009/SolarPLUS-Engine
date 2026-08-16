package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import editors.ChartingState;

import flixel.addons.effects.FlxSkewedSprite;

import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette;

using StringTools;

typedef EventNote =
{
        strumTime:Float,
        event:String,
        value1:String,
        value2:String
}

typedef NoteSplashData =
{
        disabled:Bool,
        texture:String,
        useGlobalShader:Bool, // breaks r/g/b/a but makes it copy default colors for your custom note
        useRGBShader:Bool,
        antialiasing:Bool,
        r:FlxColor,
        g:FlxColor,
        b:FlxColor,
        a:Float
}

class Note extends FlxSkewedSprite
{
        public var extraData:Map<String, Dynamic> = [];

        // modchart
        public var mesh:modchart.modcharting.SustainStrip = null;
        public var z:Float = 0;

        public var strumTime:Float = 0;
        public var mustPress:Bool = false;
        public var noteData:Int = 0;
        public var canBeHit:Bool = false;
        public var tooLate:Bool = false;
        public var wasGoodHit:Bool = false;
        public var ignoreNote:Bool = false;
        public var hitByOpponent:Bool = false;
        public var noteWasHit:Bool = false;
        public var prevNote:Note;
        public var nextNote:Note;

        public var spawned:Bool = false;
        public var tail:Array<Note> = [];

        // for sustains
        public var parent:Note;
        public var blockHit:Bool = false; // only works for player

        public var sustainLength:Float = 0;
        public var isSustainNote:Bool = false;
        public var noteType(default, set):String = null;

        public var eventName:String = '';
        public var eventLength:Int = 0;
        public var eventVal1:String = '';
        public var eventVal2:String = '';

        public var inEditor:Bool = false;
        public var animSuffix:String = '';
        public var gfNote:Bool = false;
        public var earlyHitMult:Float = 0.5;
        public var lateHitMult:Float = 1;
        public var lowPriority:Bool = false;

        public static var swagWidth:Float = 160 * 0.7;
        public static final colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
        public static var defaultNoteSkin(default, never):String = 'NOTE_assets';
        private var pixelInt:Array<Int> = [0, 1, 2, 3];

        public var noteSplashData:NoteSplashData = {
                disabled: false,
                texture: null,
                antialiasing: !PlayState.isPixelStage,
                useGlobalShader: false,
                useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
                r: -1,
                g: -1,
                b: -1,
                a: ClientPrefs.splashAlpha
        };
        // Lua shit
        public var noteSplashDisabled:Bool = false;
        public var noteSplashTexture:String = null;
        public var noteSplashHue:Float = 0;
        public var noteSplashSat:Float = 0;
        public var noteSplashBrt:Float = 0;
        public var offsetX:Float = 0;
        public var offsetY:Float = 0;
        public var offsetAngle:Float = 0;
        public var multAlpha:Float = 1;
        public var multSpeed(default, set):Float = 1;

        public var copyX:Bool = true;
        public var copyY:Bool = true;
        public var copyAngle:Bool = true;
        public var copyAlpha:Bool = true;

        public var hitHealth:Float = 0.023;
        public var missHealth:Float = 0.0475;
        public var rating:String = 'unknown';
        public var ratingMod:Float = 0;
        // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
        public var ratingDisabled:Bool = false;
        public var texture(default, set):String = null;

        public var noAnimation:Bool = false;
        public var noMissAnimation:Bool = false;
        public var hitCausesMiss:Bool = false;
        public var distance:Float = 2000;

        public var hitsoundDisabled:Bool = false;

        public var rgbShader:RGBShaderReference;
        public var pixelNote:Bool = false;
        public var disableAutoColorUpdate:Bool = false;
        public var useRGBShader(default, set):Bool = true;
        public static var globalRgbShaders:Array<RGBPalette> = [];

        public var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
        public var lastNoteScaleToo:Float = 1;
        public var originalHeightForCalcs:Float = 6;

        private function set_useRGBShader(value:Bool):Bool
        {
                if (useRGBShader != value)
                {
                        useRGBShader = value;
                        if (rgbShader != null)
                                rgbShader.enabled = value;
                }
                return value;
        }

        private function set_multSpeed(value:Float):Float
        {
                resizeByRatio(value / multSpeed);
                multSpeed = value;
                return value;
        }

        public function resizeByRatio(ratio:Float)
        {
                if (isSustainNote && !animation.curAnim.name.endsWith('end'))
                {
                        scale.y *= ratio;
                        updateHitbox();
                }
        }

        private function set_texture(value:String):String
        {
                if (texture != value)
                {
                        reloadNote('', value);
                }
                texture = value;
                return value;
        }

        public function defaultRGB()
        {
                var safeData:Int = Std.int(Math.abs(noteData)) % 4;
                var arr:Array<FlxColor> = (pixelNote || PlayState.isPixelStage) ? ClientPrefs.arrowRGBPixel[safeData] : ClientPrefs.arrowRGB[safeData];
                if (safeData < arr.length)
                {
                        rgbShader.r = arr[0];
                        rgbShader.g = arr[1];
                        rgbShader.b = arr[2];
                }
        }

        private function set_noteType(value:String):String
        {
                noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
                
                noteSplashTexture = PlayState.SONG.splashSkin;
                if (noteData > -1 && noteType != value)
                {
                        switch (value)
                        {
                                case 'Hurt Note':
                                        ignoreNote = mustPress;
                                        rgbShader.r = 0xFF101010;
                                        rgbShader.g = 0xFFFF0000;
                                        rgbShader.b = 0xFF990022;

                                        noteSplashData.r = 0xFFFF0000;
                                        noteSplashData.g = 0xFF101010;
                                        noteSplashData.texture = 'HURTnoteSplashes';
                                        lowPriority = true;
                                        missHealth = isSustainNote ? 0.25 : 0.1;
                                        hitCausesMiss = true;
                                case 'Alt Animation':
                                        animSuffix = '-alt';
                                case 'No Animation':
                                        noAnimation = true;
                                        noMissAnimation = true;
                                case 'GF Sing':
                                        gfNote = true;
                        }
                        noteType = value;
                }
                return value;
        }

        public static function initializeGlobalRGBShader(noteData:Int, ?note:Note = null)
        {
                if (note == null)
                {
                        if (globalRgbShaders[noteData] == null)
                        {
                                var newRGB:RGBPalette = new RGBPalette();
                                globalRgbShaders[noteData] = newRGB;
                                var arr:Array<FlxColor> = (ClientPrefs.noteColorStyle != 'Quant-Based')
                                        ? (!PlayState.isPixelStage) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData]
                                        : ClientPrefs.quantRGB[noteData % ClientPrefs.quantRGB.length];
                                if (noteData > -1 && noteData <= arr.length)
                                {
                                        newRGB.r = arr[0];
                                        newRGB.g = arr[1];
                                        newRGB.b = arr[2];
                                }
                        }
                        return globalRgbShaders[noteData];
                }
                else
                        switch (ClientPrefs.noteColorStyle)
                        {
                                case 'Quant-Based':
                                        if (globalRgbShaders[0] == null)
                                        {
                                                var newRGB:RGBPalette = new RGBPalette();
                                                globalRgbShaders[0] = newRGB;

                                                var arr:Array<FlxColor> = (!note.pixelNote && !PlayState.isPixelStage) ? ClientPrefs.arrowRGB[3] : ClientPrefs.arrowRGBPixel[3];
                                                if (noteData > -1)
                                                {
                                                        newRGB.r = arr[0];
                                                        newRGB.g = arr[1];
                                                        newRGB.b = arr[2];
                                                }
                                        }
                                        return globalRgbShaders[0];
                                case 'Grayscale', 'Rainbow', 'Char-Based':
                                        if (globalRgbShaders[0] == null)
                                        {
                                                var newRGB:RGBPalette = new RGBPalette();
                                                globalRgbShaders[0] = newRGB;
                                                if (noteData > -1)
                                                {
                                                        newRGB.r = 0xFFA0A0A0;
                                                        newRGB.g = FlxColor.WHITE;
                                                        newRGB.b = 0xFF424242;
                                                }
                                        }
                                        return globalRgbShaders[0];
                                default:
                                        if (globalRgbShaders[noteData] == null)
                                        {
                                                var newRGB:RGBPalette = new RGBPalette();
                                                globalRgbShaders[noteData] = newRGB;

                                                var arr:Array<FlxColor> = (!note.pixelNote && !PlayState.isPixelStage) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData];
                                                if (noteData > -1 && noteData <= arr.length)
                                                {
                                                        newRGB.r = arr[0];
                                                        newRGB.g = arr[1];
                                                        newRGB.b = arr[2];
                                                }
                                        }
                                        return globalRgbShaders[noteData];
                        }
        }

        public static var quantDivisors:Array<Int> = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024];

        public function updateRGBColors()
        {
                if (!useRGBShader) return;
                if (rgbShader == null)
                        rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this));

                var style:String = ClientPrefs.noteColorStyle;
                var timeForColor:Float = strumTime;
                if (isSustainNote)
                {
                        if (parent != null)
                                timeForColor = parent.strumTime;
                        else if (prevNote != null)
                        {
                                var p:Note = prevNote;
                                while (p != null && p.isSustainNote)
                                        p = p.prevNote;
                                if (p != null)
                                        timeForColor = p.strumTime;
                        }
                }

                if (style == 'Rainbow')
                {
                        var rainbowTime:Float = Conductor.crochet;
                        if (rainbowTime <= 0) rainbowTime = 1000;
                        var coolColor:FlxColor = new FlxColor(0xFFFF0000);
                        coolColor.hue = (timeForColor / rainbowTime * 360) % 360;
                        rgbShader.r = coolColor;
                        rgbShader.g = FlxColor.WHITE;
                        rgbShader.b = coolColor.getDarkened(0.7);
                }
                else if (style == 'Quant-Based')
                {
                        checkNoteQuantColor();
                }
                else if (style == 'Char-Based')
                {
                        if (PlayState.instance != null)
                        {
                                var charColors:Array<Int> = [200, 100, 150];
                                var charToUse:Dynamic = gfNote ? PlayState.instance.gf : PlayState.instance.boyfriend;
                                if (charToUse != null && Reflect.hasField(charToUse, 'healthColor'))
                                        charColors = cast Reflect.field(charToUse, 'healthColor');
                                if (noteData > -1)
                                {
                                        rgbShader.r = FlxColor.fromRGB(charColors[0], charColors[1], charColors[2]);
                                        rgbShader.g = FlxColor.WHITE;
                                        rgbShader.b = rgbShader.r.getDarkened(0.7);
                                }
                        }
                        else
                                defaultRGB();
                }
                else if (style == 'Grayscale')
                {
                        var brightness:Float = rgbShader.r.brightness;
                        var gray:FlxColor = FlxColor.fromRGBFloat(brightness, brightness, brightness);
                        rgbShader.r = gray;
                        rgbShader.g = FlxColor.WHITE;
                        rgbShader.b = gray.getDarkened(0.7);
                }

                if (noteType == 'Hurt Note' && rgbShader != null)
                {
                        rgbShader.r = 0xFF101010;
                        rgbShader.g = 0xFFFF0000;
                        rgbShader.b = 0xFF990022;
                        noteSplashData.r = 0xFFFF0000;
                        noteSplashData.g = 0xFF101010;
                        noteSplashData.texture = 'HURTnoteSplashes';
                }
                else if (rgbShader != null)
                {
                        noteSplashData.r = -1;
                        noteSplashData.g = -1;
                        noteSplashData.b = -1;
                }
        }

        public function checkNoteQuantColor()
        {
                if (rgbShader == null) return;

                var timeToCheck:Float = strumTime;
                if (isSustainNote)
                {
                        if (parent != null)
                                timeToCheck = parent.strumTime;
                        else if (prevNote != null)
                        {
                                var p:Note = prevNote;
                                while (p != null && p.isSustainNote)
                                        p = p.prevNote;
                                if (p != null)
                                        timeToCheck = p.strumTime;
                        }
                }

                var stepTime:Float = Conductor.stepCrochet;
                if (stepTime <= 0) stepTime = 150;

                var quantIndex:Int = 0;
                for (i in 0...quantDivisors.length)
                {
                        var divisor:Int = quantDivisors[i];
                        var quantTime:Float = stepTime * 4 / divisor;
                        var nearest:Float = Math.round(timeToCheck / quantTime) * quantTime;
                        if (Math.abs(timeToCheck - nearest) < 2.0)
                        {
                                quantIndex = i;
                                break;
                        }
                }

                if (ClientPrefs.quantRGB != null && quantIndex < ClientPrefs.quantRGB.length)
                {
                        var arr:Array<FlxColor> = ClientPrefs.quantRGB[quantIndex];
                        if (arr != null && arr.length >= 3)
                        {
                                rgbShader.r = arr[0];
                                rgbShader.g = arr[1];
                                rgbShader.b = arr[2];
                        }
                }
        }

        public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
        {
                super();
                if (prevNote == null)
                        prevNote = this;
                this.prevNote = prevNote;
                isSustainNote = sustainNote;
                this.inEditor = inEditor;

                if (isSustainNote && prevNote != null)
                {
                        parent = prevNote.isSustainNote ? prevNote.parent : prevNote;
                }

                if (PlayState.isPixelStage) pixelNote = true;
                x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
                y -= 2000;
                this.strumTime = strumTime;
                if (!inEditor)
                        this.strumTime += ClientPrefs.noteOffset;
                this.noteData = noteData;
                if (noteData > -1)
                {
                        texture = '';
                        x += swagWidth * (noteData);
                        if (!isSustainNote && noteData > -1 && noteData < 4)
                        {
                                var animToPlay:String = '';
                                animToPlay = colArray[noteData % 4];
                                animation.play(animToPlay + 'Scroll');
                        }
                        if (ClientPrefs.enableColorShader)
                        {
                                try
                                {
                                        var style:String = ClientPrefs.noteColorStyle;
                                        if (style != null && style != 'Normal')
                                        {
                                                var indep:RGBPalette = new RGBPalette();
                                                rgbShader = new RGBShaderReference(this, indep);
                                        }
                                        else
                                        {
                                                rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this));
                                        }
                                }
                                catch (e)
                                {
                                }
                        }
                        else
                                useRGBShader = false;
                }

                if (prevNote != null)
                        prevNote.nextNote = this;
                if (isSustainNote && prevNote != null)
                {
                        alpha = (ClientPrefs.longnotet);
                        multAlpha = (ClientPrefs.longnotet);
                        hitsoundDisabled = true;
                        if (ClientPrefs.downScroll)
                                flipY = true;
                        offsetX += width / 2;
                        copyAngle = false;

                        animation.play(colArray[noteData % 4] + 'holdend');
                        updateHitbox();

                        offsetX -= width / 2;
                        if (pixelNote)
                                offsetX += 30;
                        if (prevNote.isSustainNote)
                        {
                                prevNote.animation.play(colArray[prevNote.noteData % 4] + 'hold');
                                prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
                                if (PlayState.instance != null)
                                {
                                        prevNote.scale.y *= PlayState.instance.songSpeed;
                                }

                                if (pixelNote)
                                {
                                        prevNote.scale.y *= 1.19;
                                        prevNote.scale.y *= (6 / height);
                                }
                                prevNote.updateHitbox();
                        }

                        if (pixelNote)
                        {
                                scale.y *= PlayState.daPixelZoom;
                                updateHitbox();
                        }
                }
                else if (!isSustainNote)
                {
                        earlyHitMult = 1;
                }
                x += offsetX;
                if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
                        rgbShader.enabled = useRGBShader = false;

                if (useRGBShader && ClientPrefs.noteColorStyle != null && ClientPrefs.noteColorStyle != 'Normal')
                {
                        updateRGBColors();
                }
        }

        function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '')
        {
                if (prefix == null)
                        prefix = '';
                if (texture == null)
                        texture = '';
                if (suffix == null)
                        suffix = '';
                var skin:String = texture;
                if(texture.length < 1) {
                        skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
                        if(skin == null || skin.length < 1)
                                skin = defaultNoteSkin;
                }

                var animName:String = null;
                if (animation.curAnim != null)
                {
                        animName = animation.curAnim.name;
                }

                var skinPostfix:String = getNoteSkinPostfix();
                var arraySkin:Array<String> = skin.split('/');
                arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;
                var lastScaleY:Float = scale.y;
                var blahblah:String = arraySkin.join('/');

                if (pixelNote)
                {
                        if (isSustainNote)
                        {
                                loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
                                width = width / 4;
                                height = height / 2;
                                originalHeightForCalcs = height;
                                loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
                        }
                        else
                        {
                                loadGraphic(Paths.image('pixelUI/' + blahblah));
                                width = width / 4;
                                height = height / 5;
                                loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
                        }
                        setGraphicSize(Std.int(width * PlayState.daPixelZoom));
                        loadPixelNoteAnims();
                        antialiasing = false;

                        if (isSustainNote)
                        {
                                offsetX += lastNoteOffsetXForPixelAutoAdjusting;
                                lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
                                offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
                        }
                }
                else
                {
                        frames = Paths.getSparrowAtlas(blahblah);
                        loadNoteAnims();
                        antialiasing = ClientPrefs.globalAntialiasing;
                }
                if (isSustainNote)
                {
                        scale.y = lastScaleY;
                }
                updateHitbox();
                if (animName != null)
                        animation.play(animName, true);
                if (inEditor)
                {
                        setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
                        updateHitbox();
                }
        }

        function loadNoteAnims()
        {
                animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');
                if (isSustainNote)
                {
                        animation.addByPrefix('purpleholdend', 'pruple end hold');
                        animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end');
                        animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece');
                }

                setGraphicSize(Std.int(width * 0.7));
                updateHitbox();
        }

        function loadPixelNoteAnims()
        {
                if (isSustainNote)
                {
                        animation.add(colArray[noteData] + 'holdend', [pixelInt[noteData] + 4]);
                        animation.add(colArray[noteData] + 'hold', [pixelInt[noteData]]);
                }
                else
                {
                        animation.add(colArray[noteData] + 'Scroll', [pixelInt[noteData] + 4]);
                }
        }

        public static function getNoteSkinPostfix()
        {
                var skin:String = '';
                if (ClientPrefs.noteSkin != 'Default')
                        skin = '-' + ClientPrefs.noteSkin.trim().toLowerCase().replace(' ', '_');
                return skin;
        }

        override function update(elapsed:Float)
        {
                super.update(elapsed);

                var style:String = ClientPrefs.noteColorStyle;
                if (style != null && style != 'Normal' && useRGBShader && !disableAutoColorUpdate)
                {
                        if (isSustainNote && parent != null && parent.rgbShader != null)
                        {
                                rgbShader.r = parent.rgbShader.r;
                                rgbShader.g = parent.rgbShader.g;
                                rgbShader.b = parent.rgbShader.b;
                        }
                        else
                        {
                                updateRGBColors();
                        }
                }

                if (mustPress)
                {
                        if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
                                && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
                                canBeHit = true;
                        else
                                canBeHit = false;

                        if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
                                tooLate = true;
                }
                else
                {
                        canBeHit = false;
                        if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
                        {
                                if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
                                        wasGoodHit = true;
                        }
                }

                if (tooLate && !inEditor)
                {
                        if (alpha > 0.3)
                                alpha = 0.3;
                }
        }
}
package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import shaders.RGBPalette.RGBShaderReference;
import flixel.util.FlxColor;
import flixel.addons.effects.FlxSkewedSprite;

using StringTools;

class StrumNote extends FlxSkewedSprite
{
        public var rgbShader:RGBShaderReference;

        private var colorSwap:ColorSwap;

        public var resetAnim:Float = 0;

        private var noteData:Int = 0;

        public var direction:Float = 90; // plan on doing scroll directions soon -bb
        public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
        public var sustainReduce:Bool = true;

        private var player:Int;

        // From JS Engine
        public var ogNoteskin:String = null;
        public var notes_angle:Null<Float> = null;

        public var texture(default, set):String = null;

        private function set_texture(value:String):String
        {
                if (texture != value)
                {
                        texture = (value != null ? value : "NOTE_assets" + Note.getNoteSkinPostfix());
                        reloadNote();
                }
                return value;
        }

        public var useRGBShader:Bool = true;

        public function getAngle():Float
        {
                return (notes_angle == null ? angle : notes_angle);
        }

        public function new(x:Float, y:Float, leData:Int, player:Int)
        {
                rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
                rgbShader.enabled = false;
                if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
                        useRGBShader = false;

                var safeData:Int = Std.int(Math.abs(leData)) % 4;
                var arr:Array<FlxColor> = ClientPrefs.arrowRGB[safeData];
                if (PlayState.isPixelStage)
                        arr = ClientPrefs.arrowRGBPixel[safeData];

                noteData = leData;
                this.player = player;
                this.noteData = leData;
                super(x, y);

                if (safeData < arr.length)
                {
                        @:bypassAccessor
                        {
                                rgbShader.r = arr[0];
                                rgbShader.g = arr[1];
                                rgbShader.b = arr[2];
                        }
                }

                var skin:String = 'NOTE_assets';
                if (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
                        skin = PlayState.SONG.arrowSkin;
                else
                        skin = Note.defaultNoteSkin;
                texture = skin; // Load texture and anims
                ogNoteskin = skin;

                scrollFactor.set();
        }

        public function updateNoteSkin(noteskin:String)
        {
                if (texture == "noteskins/" + noteskin || noteskin == ogNoteskin || texture == noteskin)
                        return; // if the noteskin to change to is the same as before then don't update it
                if (noteskin != null && noteskin.length > 0)
                        texture = "noteskins/" + noteskin;
                else
                        texture = "NOTE_assets" + Note.getNoteSkinPostfix();
        }

        public function reloadNote()
        {
                var lastAnim:String = null;
                if (animation.curAnim != null)
                        lastAnim = animation.curAnim.name;

                if (PlayState.isPixelStage)
                {
                        loadGraphic(Paths.image('pixelUI/' + texture));
                        width = width / 4;
                        height = height / 5;
                        loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

                        antialiasing = false;
                        setGraphicSize(Std.int(width * PlayState.daPixelZoom));

                        animation.add('green', [6]);
                        animation.add('red', [7]);
                        animation.add('blue', [5]);
                        animation.add('purple', [4]);
                        switch (Math.abs(noteData) % 4)
                        {
                                case 0:
                                        animation.add('static', [0]);
                                        animation.add('pressed', [4, 8], 12, false);
                                        animation.add('confirm', [12, 16], 24, false);
                                case 1:
                                        animation.add('static', [1]);
                                        animation.add('pressed', [5, 9], 12, false);
                                        animation.add('confirm', [13, 17], 24, false);
                                case 2:
                                        animation.add('static', [2]);
                                        animation.add('pressed', [6, 10], 12, false);
                                        animation.add('confirm', [14, 18], 12, false);
                                case 3:
                                        animation.add('static', [3]);
                                        animation.add('pressed', [7, 11], 12, false);
                                        animation.add('confirm', [15, 19], 24, false);
                        }
                }
                else
                {
                        frames = Paths.getSparrowAtlas(texture);
                        animation.addByPrefix('green', 'arrowUP');
                        animation.addByPrefix('blue', 'arrowDOWN');
                        animation.addByPrefix('purple', 'arrowLEFT');
                        animation.addByPrefix('red', 'arrowRIGHT');

                        antialiasing = ClientPrefs.globalAntialiasing;
                        setGraphicSize(Std.int(width * 0.7));

                        switch (Math.abs(noteData) % 4)
                        {
                                case 0:
                                        animation.addByPrefix('static', 'arrowLEFT');
                                        animation.addByPrefix('pressed', 'left press', 24, false);
                                        animation.addByPrefix('confirm', 'left confirm', 24, false);
                                case 1:
                                        animation.addByPrefix('static', 'arrowDOWN');
                                        animation.addByPrefix('pressed', 'down press', 24, false);
                                        animation.addByPrefix('confirm', 'down confirm', 24, false);
                                case 2:
                                        animation.addByPrefix('static', 'arrowUP');
                                        animation.addByPrefix('pressed', 'up press', 24, false);
                                        animation.addByPrefix('confirm', 'up confirm', 24, false);
                                case 3:
                                        animation.addByPrefix('static', 'arrowRIGHT');
                                        animation.addByPrefix('pressed', 'right press', 24, false);
                                        animation.addByPrefix('confirm', 'right confirm', 24, false);
                        }
                }
                updateHitbox();

                if (lastAnim != null)
                {
                        playAnim(lastAnim, true);
                }
        }

        public function postAddedToGroup()
        {
                playAnim('static');
                x += Note.swagWidth * noteData;
                x += 50;
                x += ((FlxG.width / 2) * player);
                ID = noteData;
        }

        override function update(elapsed:Float)
        {
                if (resetAnim > 0)
                {
                        resetAnim -= elapsed;
                        if (resetAnim <= 0)
                        {
                                playAnim('static');
                                resetAnim = 0;
                        }
                }
                if(animation.curAnim != null){ //my bad i was upset
                if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage)
                {
                        centerOrigin();
                        // }
                }
        }
                super.update(elapsed);
        }

        public function playAnim(anim:String, ?force:Bool = false, ?r:FlxColor, ?g:FlxColor, ?b:FlxColor)
        {
                animation.play(anim, force);
                if (animation.curAnim != null)
                {
                        centerOffsets();
                        centerOrigin();
                }
                if (useRGBShader)
                {
                        rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
                        if (r != null && g != null && b != null) updateRGBColors(r, g, b);
                }
                else if (!useRGBShader && rgbShader != null)
                        rgbShader.enabled = false;
        }

        public function updateRGBColors(?r:FlxColor, ?g:FlxColor, ?b:FlxColor)
        {
                if (rgbShader != null && useRGBShader)
                {
                        rgbShader.r = r;
                        rgbShader.g = g;
                        rgbShader.b = b;
                }
        }

        public function resetRGB()
        {
                if (rgbShader != null && animation.curAnim != null && animation.curAnim.name == 'static')
                {
                        var style:String = ClientPrefs.noteColorStyle;
                        if (style == 'Grayscale')
                        {
                                rgbShader.r = 0xFFA0A0A0;
                                rgbShader.g = FlxColor.WHITE;
                                rgbShader.b = 0xFF424242;
                        }
                        else if (style == 'Quant-Based' || style == 'Rainbow' || style == 'Char-Based')
                        {
                                rgbShader.r = 0xFFF9393F;
                                rgbShader.g = 0xFFFFFFFF;
                                rgbShader.b = 0xFF651038;
                        }
                        rgbShader.enabled = false;
                }
        }
}

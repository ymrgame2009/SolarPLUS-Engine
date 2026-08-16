package options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import lime.system.Clipboard;
import flixel.util.FlxGradient;
import StrumNote;
import Note;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

using StringTools;

class NotesSubState extends MusicBeatSubstate
{
        private static var deafaultArrowcolor:Array<Array<FlxColor>> = [
                [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
                [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
                [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
                [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
        ];

        // Quant names (from JS Engine)
        var quantNames:Array<String> = [
                '4th', '8th', '12th', '16th',
                '24th', '32nd', '48th', '64th',
                '96th', '128th', '192nd', '256th',
                '384th', '512th', '768th', '1024th',
                '1536th', '2048th', '3072nd', '6144th'
        ];

        var onModeColumn:Bool = true;
        var curSelectedMode:Int = 0;
        var curSelectedNote:Int = 0;
        var onPixel:Bool = false;
        var dataArray:Array<Array<FlxColor>>;

        var hexTypeLine:FlxSprite;
        var hexTypeNum:Int = -1;
        var hexTypeVisibleTimer:Float = 0;

        var copyButton:FlxSprite;
        var pasteButton:FlxSprite;

        var colorGradient:FlxSprite;
        var colorGradientSelector:FlxSprite;
        var colorPalette:FlxSprite;
        var colorWheel:FlxSprite;
        var colorWheelSelector:FlxSprite;

        var alphabetR:Alphabet;
        var alphabetG:Alphabet;
        var alphabetB:Alphabet;
        var alphabetHex:Alphabet;

        var modeBG:FlxSprite;
        var notesBG:FlxSprite;

        var tipTxt:FlxText;

        public function new()
        {
                super();
                cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

                #if DISCORD_ALLOWED
                DiscordClient.changePresence("Note Colors Menu", null);
                #end

                PlayState.isPixelStage = false;

                if (ClientPrefs.darkmode)
                {
                        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image("aboutMenu", "preload"));
                        bg.color = 0xFFea71fd;
                        bg.screenCenter();
                        bg.antialiasing = ClientPrefs.globalAntialiasing;
                        add(bg);
                }
                else
                {
                        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
                        bg.color = 0xFFea71fd;
                        bg.screenCenter();
                        bg.antialiasing = ClientPrefs.globalAntialiasing;
                        add(bg);
                }

                var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
                grid.velocity.set(40, 40);
                grid.alpha = 0;
                FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
                add(grid);

                modeBG = new FlxSprite(215, 85).makeGraphic(315, 115, FlxColor.BLACK);
                modeBG.visible = false;
                modeBG.alpha = 0.4;
                add(modeBG);

                notesBG = new FlxSprite(140, 190).makeGraphic(480, 125, FlxColor.BLACK);
                notesBG.visible = false;
                notesBG.alpha = 0.4;
                add(notesBG);

                if (ClientPrefs.noteColorStyle == 'Quant-Based')
                {
                        notesBG.makeGraphic(2400, 125, FlxColor.BLACK);
                }

                modeNotes = new FlxTypedGroup<FlxSprite>();
                add(modeNotes);
                myNotes = new FlxTypedGroup<StrumNote>();
                add(myNotes);
                noteTxts = new FlxTypedGroup<FlxText>();
                add(noteTxts);

                var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
                bg.alpha = 0.25;
                add(bg);
                var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
                bg.alpha = 0.25;
                add(bg);

                copyButton = new FlxSprite(760, 50).loadGraphic(Paths.image('noteColorMenu/copy'));
                copyButton.alpha = 0.6;
                add(copyButton);

                pasteButton = new FlxSprite(1180, 50).loadGraphic(Paths.image('noteColorMenu/paste'));
                pasteButton.alpha = 0.6;
                add(pasteButton);

                colorGradient = FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
                colorGradient.setPosition(780, 200);
                add(colorGradient);

                colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10, FlxColor.WHITE);
                colorGradientSelector.offset.y = 5;
                add(colorGradientSelector);

                colorPalette = new FlxSprite(820, 580).loadGraphic(Paths.image('noteColorMenu/palette', null));
                colorPalette.scale.set(20, 20);
                colorPalette.updateHitbox();
                colorPalette.antialiasing = false;
                add(colorPalette);

                colorWheel = new FlxSprite(860, 200).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
                colorWheel.setGraphicSize(360, 360);
                colorWheel.updateHitbox();
                add(colorWheel);
                colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
                colorWheelSelector.offset.set(8, 8);
                colorWheelSelector.alpha = 0.6;
                add(colorWheelSelector);

                var txtX = 980;
                var txtY = 90;
                alphabetR = makeColorAlphabet(txtX - 100, txtY);
                add(alphabetR);
                alphabetG = makeColorAlphabet(txtX, txtY);
                add(alphabetG);
                alphabetB = makeColorAlphabet(txtX + 100, txtY);
                add(alphabetB);
                alphabetHex = makeColorAlphabet(txtX, txtY - 55);
                add(alphabetHex);
                hexTypeLine = new FlxSprite(0, 20).makeGraphic(5, 62, FlxColor.WHITE);
                hexTypeLine.visible = false;
                add(hexTypeLine);

                spawnNotes();
                updateNotes(true);
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

                var tipX = 20;
                var tipY = 660;
                tipTxt = new FlxText(tipX, tipY, 0, "", 16);
                tipTxt.setFormat(Paths.font("funkin.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                tipTxt.borderSize = 2;
                add(tipTxt);
                updateTipText();

                FlxG.mouse.visible = true;
        }

        function updateTipText()
        {
                tipTxt.text = "Press RELOAD to Reset the selected Note Part." + "\nPress CTRL to switch between Normal and Pixel mode.";
        }

        var _storedColor:FlxColor;
        var changingNote:Bool = false;
        var holdingOnObj:FlxSprite;
        var allowedTypeKeys:Map<FlxKey, String> = [
                ZERO => '0',
                ONE => '1',
                TWO => '2',
                THREE => '3',
                FOUR => '4',
                FIVE => '5',
                SIX => '6',
                SEVEN => '7',
                EIGHT => '8',
                NINE => '9',
                NUMPADZERO => '0',
                NUMPADONE => '1',
                NUMPADTWO => '2',
                NUMPADTHREE => '3',
                NUMPADFOUR => '4',
                NUMPADFIVE => '5',
                NUMPADSIX => '6',
                NUMPADSEVEN => '7',
                NUMPADEIGHT => '8',
                NUMPADNINE => '9',
                A => 'A',
                B => 'B',
                C => 'C',
                D => 'D',
                E => 'E',
                F => 'F'
        ];

        override function update(elapsed:Float)
        {
                if (controls.BACK)
                {
                        FlxG.mouse.visible = false;
                        FlxG.sound.play(Paths.sound('cancelMenu'));
                        close();
                        return;
                }

                if (FlxG.keys.justPressed.CONTROL)
                {
                        onPixel = !onPixel;
                        spawnNotes();
                        updateNotes(true);
                        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                }

                if (hexTypeNum > -1)
                {
                        var keyPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
                        hexTypeVisibleTimer += elapsed;
                        var changed:Bool = false;
                        if (changed = FlxG.keys.justPressed.LEFT)
                                hexTypeNum--;
                        else if (changed = FlxG.keys.justPressed.RIGHT)
                                hexTypeNum++;
                        else if (allowedTypeKeys.exists(keyPressed))
                        {
                                var curColor:String = alphabetHex.text;
                                var newColor:String = curColor.substring(0, hexTypeNum) + allowedTypeKeys.get(keyPressed) + curColor.substring(hexTypeNum + 1);

                                var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
                                setShaderColor(colorHex);
                                _storedColor = getShaderColor();
                                updateColors();

                                hexTypeNum++;
                                changed = true;
                        }
                        else if (FlxG.keys.justPressed.ENTER)
                                hexTypeNum = -1;

                        var end:Bool = false;
                        if (changed)
                        {
                                if (hexTypeNum > 5)
                                {
                                        hexTypeNum = -1;
                                        end = true;
                                        hexTypeLine.visible = false;
                                }
                                else
                                {
                                        if (hexTypeNum < 0)
                                                hexTypeNum = 0;
                                        else if (hexTypeNum > 5)
                                                hexTypeNum = 5;
                                        centerHexTypeLine();
                                        hexTypeLine.visible = true;
                                }
                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                        }
                        if (!end)
                                hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
                }
                else
                {
                        var add:Int = 0;
                        if (controls.UI_LEFT_P)
                                add = -1;
                        else if (controls.UI_RIGHT_P)
                                add = 1;

                        if (controls.UI_UP_P || controls.UI_DOWN_P)
                        {
                                onModeColumn = !onModeColumn;
                                modeBG.visible = onModeColumn;
                                notesBG.visible = !onModeColumn;
                        }

                        if (add != 0)
                        {
                                if (onModeColumn)
                                        changeSelectionMode(add);
                                else
                                        changeSelectionNote(add);
                        }
                        hexTypeLine.visible = false;
                }

                var generalMoved:Bool = (FlxG.mouse.justMoved);
                var generalPressed:Bool = (FlxG.mouse.justPressed);
                if (generalMoved)
                {
                        copyButton.alpha = 0.6;
                        pasteButton.alpha = 0.6;
                }

                if (pointerOverlaps(copyButton))
                {
                        copyButton.alpha = 1;
                        if (generalPressed)
                        {
                                Clipboard.text = getShaderColor().toHexString(false, false);
                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                                trace('copied: ' + Clipboard.text);
                        }
                        hexTypeNum = -1;
                }
                else if (pointerOverlaps(pasteButton))
                {
                        pasteButton.alpha = 1;
                        if (generalPressed)
                        {
                                var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
                                var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
                                if (newColor != null && formattedText.length == 6)
                                {
                                        setShaderColor(newColor);
                                        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                                        _storedColor = getShaderColor();
                                        updateColors();
                                }
                                else
                                        FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
                        }
                        hexTypeNum = -1;
                }

                if (generalPressed)
                {
                        hexTypeNum = -1;
                        if (pointerOverlaps(modeNotes))
                        {
                                modeNotes.forEachAlive(function(note:FlxSprite)
                                {
                                        if (curSelectedMode != note.ID && pointerOverlaps(note))
                                        {
                                                modeBG.visible = notesBG.visible = false;
                                                curSelectedMode = note.ID;
                                                onModeColumn = true;
                                                updateNotes();
                                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                                        }
                                });
                        }
                        else if (pointerOverlaps(myNotes))
                        {
                                myNotes.forEachAlive(function(note:StrumNote)
                                {
                                        if (curSelectedNote != note.ID && pointerOverlaps(note))
                                        {
                                                modeBG.visible = notesBG.visible = false;
                                                curSelectedNote = note.ID;
                                                onModeColumn = false;
                                                bigNote.rgbShader.parent = Note.globalRgbShaders[note.ID];
                                                bigNote.shader = Note.globalRgbShaders[note.ID].shader;
                                                updateNotes();
                                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                                        }
                                });
                        }
                        else if (pointerOverlaps(colorWheel))
                        {
                                _storedColor = getShaderColor();
                                holdingOnObj = colorWheel;
                        }
                        else if (pointerOverlaps(colorGradient))
                        {
                                _storedColor = getShaderColor();
                                holdingOnObj = colorGradient;
                        }
                        else if (pointerOverlaps(colorPalette))
                        {
                                setShaderColor(colorPalette.pixels.getPixel32(Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x),
                                        Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                                updateColors();
                        }
                        else if (pointerY() >= hexTypeLine.y && pointerY() < hexTypeLine.y + hexTypeLine.height && Math.abs(pointerX() - 1000) <= 84)
                        {
                                hexTypeNum = 0;
                                for (letter in alphabetHex.letters)
                                {
                                        if (letter.x - letter.offset.x + letter.width <= pointerX())
                                                hexTypeNum++;
                                        else
                                                break;
                                }
                                if (hexTypeNum > 5)
                                        hexTypeNum = 5;
                                hexTypeLine.visible = true;
                                centerHexTypeLine();
                        }
                        else
                                holdingOnObj = null;
                }

                if (holdingOnObj != null)
                {
                        if (FlxG.mouse.justReleased)
                        {
                                holdingOnObj = null;
                                _storedColor = getShaderColor();
                                updateColors();
                                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
                        }
                        else if (generalMoved || generalPressed)
                        {
                                if (holdingOnObj == colorGradient)
                                {
                                        var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
                                        _storedColor.alpha = 1;
                                        if (_storedColor.brightness == 0)
                                                setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
                                        else
                                                setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
                                        updateColors(_storedColor);
                                }
                                else if (holdingOnObj == colorWheel)
                                {
                                        var center:FlxPoint = new FlxPoint(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
                                        var mouse:FlxPoint = pointerFlxPoint();
                                        var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
                                        var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
                                        if (sat != 0)
                                                setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
                                        else
                                                setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
                                        updateColors();
                                }
                        }
                }
                else if (controls.RESET && hexTypeNum < 0)
                {
                        var colors:Array<FlxColor> = ClientPrefs.noteColorStyle != 'Quant-Based' ? !onPixel ? deafaultArrowcolor[curSelectedNote] : ClientPrefs.defaultPixelRGB[curSelectedNote] : ClientPrefs.defaultQuantRGB[curSelectedNote % ClientPrefs.defaultQuantRGB.length];
                        if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER))
                        {
                                for (i in 0...3)
                                {
                                        var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
                                        var color = colors[i];
                                        if (ClientPrefs.noteColorStyle == 'Quant-Based' && curSelectedNote < ClientPrefs.defaultQuantRGB.length)
                                                color = ClientPrefs.defaultQuantRGB[curSelectedNote][i];
                                        switch(i)
                                        {
                                                case 0:
                                                        getShader().r = strumRGB.r = color;
                                                case 1:
                                                        getShader().g = strumRGB.g = color;
                                                case 2:
                                                        getShader().b = strumRGB.b = color;
                                        }
                                        dataArray[curSelectedNote][i] = color;
                                }
                        }
                        setShaderColor(colors[curSelectedMode]);
                        FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
                        updateColors();
                }

                // Quant mode scrolling (from JS Engine)
                if (ClientPrefs.noteColorStyle == 'Quant-Based')
                {
                        var lerpVal:Float = (1 - Math.exp(-48 * elapsed));
                        for (i in 0...myNotes.length)
                        {
                                var xIndex:Float = i;
                                if (curSelectedNote > 2 && dataArray.length > 4)
                                        xIndex -= Math.min(curSelectedNote - 2, dataArray.length - 4);
                                var xPos:Float = 150 + (120 * xIndex);
                                myNotes.members[i].x += (xPos - myNotes.members[i].x) * lerpVal;

                                // Move quant labels with notes
                                if (noteTxts.members.length > i)
                                {
                                        noteTxts.members[i].x = myNotes.members[i].x + (myNotes.members[i].width - noteTxts.members[i].width) / 2;
                                }
                        }
                        var bgXIndex:Float = Math.min(curSelectedNote, dataArray.length - 2);
                        if (dataArray.length > 4)
                        {
                                if (curSelectedNote < 2) bgXIndex = 0;
                                else bgXIndex -= 2;
                        }
                        var bgXPos:Float = 140 - (120 * bgXIndex);
                        notesBG.x += (bgXPos - notesBG.x) * lerpVal;
                }

                super.update(elapsed);
        }

        function pointerOverlaps(obj:Dynamic)
        {
                return FlxG.mouse.overlaps(obj);
        }

        function pointerX():Float
        {
                return FlxG.mouse.x;
        }

        function pointerY():Float
        {
                return FlxG.mouse.y;
        }

        function pointerFlxPoint():FlxPoint
        {
                return FlxG.mouse.getScreenPosition();
        }

        function centerHexTypeLine()
        {
                if (hexTypeNum > 0)
                {
                        var letter = alphabetHex.letters[hexTypeNum - 1];
                        hexTypeLine.x = letter.x - letter.offset.x + letter.width;
                }
                else
                {
                        var letter = alphabetHex.letters[0];
                        hexTypeLine.x = letter.x - letter.offset.x;
                }
                hexTypeLine.x += hexTypeLine.width;
                hexTypeVisibleTimer = 0;
        }

        function changeSelectionMode(change:Int = 0)
        {
                curSelectedMode += change;
                if (curSelectedMode < 0)
                        curSelectedMode = 2;
                if (curSelectedMode >= 3)
                        curSelectedMode = 0;

                modeBG.visible = true;
                notesBG.visible = false;
                updateNotes();
                FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        function changeSelectionNote(change:Int = 0)
        {
                curSelectedNote += change;
                if (curSelectedNote < 0)
                        curSelectedNote = dataArray.length - 1;
                if (curSelectedNote >= dataArray.length)
                        curSelectedNote = 0;
                modeBG.visible = false;
                notesBG.visible = true;
                bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
                bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
                updateNotes();
                FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
        {
                var text:Alphabet = new Alphabet(x, y, '', true);
                text.alignment = CENTERED;
                text.setScale(0.6);
                add(text);
                return text;
        }

        var skinNote:FlxSprite;
        var modeNotes:FlxTypedGroup<FlxSprite>;
        var myNotes:FlxTypedGroup<StrumNote>;
        var noteTxts:FlxTypedGroup<FlxText>;
        var bigNote:Note;

        public function spawnNotes()
        {
                PlayState.isPixelStage = false;
                Paths.initDefaultSkin(Note.defaultNoteSkin + Note.getNoteSkinPostfix());

                dataArray = ClientPrefs.noteColorStyle != 'Quant-Based' ? !onPixel ? ClientPrefs.arrowRGB : ClientPrefs.arrowRGBPixel : ClientPrefs.quantRGB;
                PlayState.stageUI = onPixel ? "pixel" : "normal";

                modeNotes.forEachAlive(function(note:FlxSprite)
                {
                        note.kill();
                        note.destroy();
                });
                myNotes.forEachAlive(function(note:StrumNote)
                {
                        note.kill();
                        note.destroy();
                });
                noteTxts.forEachAlive(function(txt:FlxText)
                {
                        txt.kill();
                        txt.destroy();
                });
                modeNotes.clear();
                myNotes.clear();
                noteTxts.clear();

                if (skinNote != null)
                {
                        remove(skinNote);
                        skinNote.destroy();
                }
                if (bigNote != null)
                {
                        remove(bigNote);
                        bigNote.destroy();
                }

                var res:Int = !onPixel ? 160 : 17;
                var modeGraphicName:String = !onPixel ? 'noteColorMenu/note' : 'noteColorMenu/notePixel';

                for (i in 0...3)
                {
                        var newNote:FlxSprite = new FlxSprite(230 + (100 * i), 100);
                        newNote.loadGraphic(Paths.image(modeGraphicName), true, res, res);
                        newNote.antialiasing = ClientPrefs.globalAntialiasing && !onPixel;
                        newNote.setGraphicSize(85);
                        newNote.updateHitbox();
                        newNote.animation.add('anim', [i], 24, true);
                        newNote.animation.play('anim', true);
                        newNote.ID = i;
                        modeNotes.add(newNote);
                }

                Note.globalRgbShaders = [];
                for (i in 0...dataArray.length)
                {
                        Note.initializeGlobalRGBShader(i);
                        Note.globalRgbShaders[i].r = dataArray[i][0];
                        Note.globalRgbShaders[i].g = dataArray[i][1];
                        Note.globalRgbShaders[i].b = dataArray[i][2];
                        
                        var newNote:StrumNote = new StrumNote(150 + (480 / dataArray.length * i), 200, i, 0);
                        newNote.rgbShader.r = dataArray[i][0];
                        newNote.rgbShader.g = dataArray[i][1];
                        newNote.rgbShader.b = dataArray[i][2];

                        if (onPixel)
                        {
                                var pixelImgPath:String = 'pixelUI/pixels-default';
                                if (!Paths.fileExists('images/' + pixelImgPath + '.png', IMAGE))
                                        pixelImgPath = 'pixelUI/NOTE_assets';

                                newNote.loadGraphic(Paths.image(pixelImgPath), true, 17, 17);
                                newNote.antialiasing = false;
                                var pixelFrame:Int = i % 4;
                                newNote.animation.add('static', [pixelFrame]);
                                newNote.animation.add('pressed', [pixelFrame + 4], 12, false);
                                newNote.animation.add('confirm', [pixelFrame + 8], 24, false);
                                newNote.playAnim('static');
                        }

                        newNote.useRGBShader = true;
                        newNote.setGraphicSize(102);
                        newNote.updateHitbox();
                        newNote.ID = i;

                        // Quant labels (from JS Engine)
                        if (ClientPrefs.noteColorStyle == 'Quant-Based' && i < quantNames.length)
                        {
                                var txt:FlxText = new FlxText(0, 0, 0, quantNames[i]);
                                txt.size = 12;
                                txt.color = FlxColor.WHITE;
                                txt.borderSize = 1;
                                txt.borderColor = FlxColor.BLACK;
                                txt.antialiasing = false;
                                txt.updateHitbox();
                                txt.x = newNote.x + (newNote.width - txt.width) / 2;
                                txt.y = newNote.y + newNote.height + 4;
                                noteTxts.add(txt);
                        }

                        myNotes.add(newNote);
                }

                bigNote = new Note(0, 0);
                bigNote.setPosition(250, 325);
                bigNote.pixelNote = onPixel;
                
                // Override bigNote's shader to be independent (not shared with global pool)
                var independentShader:RGBPalette = new RGBPalette();
                bigNote.rgbShader = new RGBShaderReference(bigNote, independentShader);
                // Prevent bigNote.update() from overriding our manually set colors
                bigNote.disableAutoColorUpdate = true;
                
                if (onPixel)
                {
                        var pixelImgPath:String = 'pixelUI/pixels-default';
                        if (!Paths.fileExists('images/' + pixelImgPath + '.png', IMAGE))
                                pixelImgPath = 'pixelUI/NOTE_assets';

                        bigNote.loadGraphic(Paths.image(pixelImgPath), true, 17, 17);
                        bigNote.antialiasing = false;

                        for (i in 0...dataArray.length)
                        {
                                bigNote.animation.add('note$i', [(i % 4) + 4], 24, true);
                        }
                }
                else
                {
                        @:privateAccess bigNote.reloadNote('', Note.defaultNoteSkin);
                        bigNote.antialiasing = ClientPrefs.globalAntialiasing;
                        for (i in 0...dataArray.length)
                        {
                                bigNote.animation.addByPrefix('note$i', Note.colArray[i % 4] + '0', 24, true);
                        }
                }

                bigNote.setGraphicSize(250);
                bigNote.updateHitbox();
                // Set bigNote independent shader colors
                bigNote.rgbShader.enabled = true;
                bigNote.rgbShader.r = dataArray[curSelectedNote][0];
                bigNote.rgbShader.g = dataArray[curSelectedNote][1];
                bigNote.rgbShader.b = dataArray[curSelectedNote][2];

                insert(members.indexOf(myNotes) + 1, bigNote);
                _storedColor = getShaderColor();
                
                PlayState.stageUI = "normal";
        }

        function updateNotes(?instant:Bool = false)
        {
                for (note in modeNotes)
                        note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;

                for (note in myNotes)
                {
                        var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
                        note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
                        if (note.animation.curAnim == null || note.animation.curAnim.name != newAnim)
                                note.playAnim(newAnim, true);
                        if (instant && note.animation.curAnim != null)
                                note.animation.curAnim.finish();
                }
                bigNote.animation.play('note$curSelectedNote', true);
                // Set bigNote independent shader colors from dataArray directly
                bigNote.rgbShader.enabled = true;
                bigNote.rgbShader.r = dataArray[curSelectedNote][0];
                bigNote.rgbShader.g = dataArray[curSelectedNote][1];
                bigNote.rgbShader.b = dataArray[curSelectedNote][2];
                updateColors();
        }

        function updateColors(specific:Null<FlxColor> = null)
        {
                var color:FlxColor = getShaderColor();
                var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
                alphabetR.text = Std.string(color.red);
                alphabetG.text = Std.string(color.green);
                alphabetB.text = Std.string(color.blue);
                alphabetHex.text = color.toHexString(false, false);
                for (letter in alphabetHex.letters)
                        letter.color = color;
                colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
                colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
                if (wheelColor.brightness != 0)
                {
                        var hueWrap:Float = wheelColor.hue * Math.PI / 180;
                        colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
                        colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
                }
                colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

                var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
                var globalShader:RGBPalette = getShader();
                if (curSelectedMode == 0)
                {
                        globalShader.r = strumRGB.r = color;
                }
                else if (curSelectedMode == 1)
                {
                        globalShader.g = strumRGB.g = color;
                }
                else if (curSelectedMode == 2)
                {
                        globalShader.b = strumRGB.b = color;
                }

                // Sync bigNote independent shader directly from dataArray
                if (bigNote != null && bigNote.rgbShader != null)
                {
                        bigNote.rgbShader.enabled = true;
                        bigNote.rgbShader.r = dataArray[curSelectedNote][0];
                        bigNote.rgbShader.g = dataArray[curSelectedNote][1];
                        bigNote.rgbShader.b = dataArray[curSelectedNote][2];
                }
        }

        override function destroy()
        {
                Note.globalRgbShaders = [];
                super.destroy();
        }

        function setShaderColor(value:FlxColor)
                dataArray[curSelectedNote][curSelectedMode] = value;

        function getShaderColor()
                return dataArray[curSelectedNote][curSelectedMode];

        function getShader()
                return Note.globalRgbShaders[curSelectedNote];
}
package editors;

import Note;
import StrumNote;
import SustainSplash;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUINumericStepper;
using StringTools;

typedef HoldCoverConfig = {
    holdAnim:String,
    endAnim:String,
    holdFps:Int,
    endFps:Int,
    offsets:Array<Array<Float>>
}

class HoldCoverDebugState extends MusicBeatState
{
    var config:HoldCoverConfig;
    var forceFrame:Int = -1;
    var curSelected:Int = 0;
    var maxNotes:Int = 4;

    // 0 = hold, 1 = end
    var curAnimMode:Int = 0;
    var animModeNames:Array<String> = ['hold', 'end'];

    var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

    var selection:FlxSprite;
    var notes:FlxTypedGroup<StrumNote>;
    var splashes:FlxTypedGroup<FlxSprite>;

    var imageInputText:FlxInputText;
    var holdAnimInputText:FlxInputText;
    var endAnimInputText:FlxInputText;
    var stepperHoldFps:FlxUINumericStepper;
    var stepperEndFps:FlxUINumericStepper;

    var offsetsText:FlxText;
    var curFrameText:FlxText;
    var curModeText:FlxText;
    var curAnimText:FlxText;
    var savedText:FlxText;
    var selecArr:Array<Float> = null;

    var missingTextBG:FlxSprite;
    var missingText:FlxText;

    public static final defaultTexture:String = 'holdCover/holdCover';

    override function create()
    {
        FlxG.camera.bgColor = FlxColor.fromString("#56188f");
        selection = new FlxSprite(0, 270).makeGraphic(150, 150, FlxColor.BLACK);
        selection.alpha = 0.4;
        add(selection);

        notes = new FlxTypedGroup<StrumNote>();
        add(notes);

        splashes = new FlxTypedGroup<FlxSprite>();
        add(splashes);

        for (i in 0...maxNotes)
        {
            var x = i * 220 + 240;
            var y = 290;
            var note:StrumNote = new StrumNote(x, y, i, 0);
            note.alpha = 0.75;
            note.playAnim('static');
            notes.add(note);

            var splash:FlxSprite = new FlxSprite(x, y);
            splash.shader = note.rgbShader.parent.shader;
            splash.antialiasing = ClientPrefs.globalAntialiasing;
            splashes.add(splash);
        }

        var txtx = 60;
        var txty = 640;

        // Image Name input
        var imageName:FlxText = new FlxText(txtx, txty - 140, 'Image Name:', 16);
        add(imageName);

        imageInputText = new FlxInputText(txtx, txty - 120, 360, defaultTexture, 16);
        imageInputText.callback = function(text:String, action:String)
        {
            switch(action)
            {
                case 'enter':
                    imageInputText.hasFocus = false;
                    textureName = text;
                    try {
                        loadFrames();
                    } catch(e:Dynamic) {
                        trace('ERROR! $e');
                        textureName = defaultTexture;
                        loadFrames();

                        missingText.text = 'ERROR WHILE LOADING IMAGE:\n$text';
                        missingText.screenCenter(Y);
                        missingText.visible = true;
                        missingTextBG.visible = true;
                        FlxG.sound.play(Paths.sound('cancelMenu'));

                        new FlxTimer().start(2.5, function(tmr:FlxTimer)
                        {
                            missingText.visible = false;
                            missingTextBG.visible = false;
                        });
                    }
                default:
                    trace('changed image to $text');
            }
        };
        add(imageInputText);

        // Hold Animation Prefix input
        var holdAnimLabel:FlxText = new FlxText(txtx, txty - 20, 'Hold Anim Prefix:', 16);
        add(holdAnimLabel);

        holdAnimInputText = new FlxInputText(txtx, txty, 360, '', 16);
        holdAnimInputText.callback = function(text:String, action:String)
        {
            switch(action)
            {
                case 'enter':
                    holdAnimInputText.hasFocus = false;
                default:
                    trace('changed hold anim to $text');
                    if(config != null) config.holdAnim = text;
                    reloadAnims();
            }
        };
        add(holdAnimInputText);

        // End Animation Prefix input
        var endAnimLabel:FlxText = new FlxText(txtx + 400, txty - 20, 'End Anim Prefix:', 16);
        add(endAnimLabel);

        endAnimInputText = new FlxInputText(txtx + 400, txty, 360, '', 16);
        endAnimInputText.callback = function(text:String, action:String)
        {
            switch(action)
            {
                case 'enter':
                    endAnimInputText.hasFocus = false;
                default:
                    trace('changed end anim to $text');
                    if(config != null) config.endAnim = text;
                    reloadAnims();
            }
        };
        add(endAnimInputText);

        // Framerate steppers
        add(new FlxText(txtx, txty + 30, 0, 'Hold FPS / End FPS:', 16));
        stepperHoldFps = new FlxUINumericStepper(txtx, txty + 50, 1, 24, 1, 60, 0);
        stepperHoldFps.name = 'hold_fps';
        add(stepperHoldFps);

        stepperEndFps = new FlxUINumericStepper(txtx + 60, txty + 50, 1, 24, 1, 60, 0);
        stepperEndFps.name = 'end_fps';
        add(stepperEndFps);

        // Info text displays
        curModeText = new FlxText(300, 50, 680, '', 16);
        curModeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        curModeText.scrollFactor.set();
        add(curModeText);

        curAnimText = new FlxText(300, 100, 680, '', 16);
        curAnimText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        curAnimText.scrollFactor.set();
        add(curAnimText);

        curFrameText = new FlxText(300, 150, 680, '', 16);
        curFrameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        curFrameText.scrollFactor.set();
        add(curFrameText);

        offsetsText = new FlxText(300, 200, 680, '', 16);
        offsetsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        offsetsText.scrollFactor.set();
        add(offsetsText);

        // Controls help text
        var text:FlxText = new FlxText(0, 516, FlxG.width,
            "Press SPACE to Reset animation\n
            Press ENTER twice to save to the loaded Hold Cover PNG's folder\n
            A/D change selected note - Arrow Keys to change offset (Hold shift for 10x)\n
            Ctrl + C/V - Copy & Paste offsets", 16);
        text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        text.scrollFactor.set();
        add(text);

        savedText = new FlxText(0, 340, FlxG.width, '', 24);
        savedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        savedText.scrollFactor.set();
        add(savedText);

        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        missingTextBG.alpha = 0.6;
        missingTextBG.visible = false;
        add(missingTextBG);

        missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
        missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        missingText.scrollFactor.set();
        missingText.visible = false;
        add(missingText);

        loadFrames();
        changeSelection();
        super.create();
        FlxG.mouse.visible = true;
    }

    var maxFrame:Int = 0;
    var visibleTime:Float = 0;
    var pressEnterToSave:Float = 0;
    var textureName:String = defaultTexture;
    var texturePath:String = '';
    var copiedArray:Array<Float> = null;

    override function update(elapsed:Float)
    {
        @:privateAccess
        cast(stepperHoldFps.text_field, FlxInputText).hasFocus = cast(stepperEndFps.text_field, FlxInputText).hasFocus = false;

        var notTyping:Bool = !holdAnimInputText.hasFocus && !imageInputText.hasFocus && !endAnimInputText.hasFocus;
        if(controls.BACK && notTyping)
        {
            MusicBeatState.switchState(new MasterEditorMenu());
            FlxG.sound.playMusic(Paths.music("freakyMenu-" + ClientPrefs.mmm));
            FlxG.mouse.visible = false;
        }
        super.update(elapsed);

        if(!notTyping) return;

        if (FlxG.keys.justPressed.A) changeSelection(-1);
        else if (FlxG.keys.justPressed.D) changeSelection(1);

        // Toggle between hold and end animation mode
        if (FlxG.keys.justPressed.TAB)
        {
            curAnimMode = 1 - curAnimMode;
            changeAnim();
        }

        // Offset controls
        if(selecArr != null)
        {
            var movex = 0;
            var movey = 0;
            if(FlxG.keys.justPressed.LEFT) movex = -1;
            else if(FlxG.keys.justPressed.RIGHT) movex = 1;

            if(FlxG.keys.justPressed.UP) movey = 1;
            else if(FlxG.keys.justPressed.DOWN) movey = -1;

            if(FlxG.keys.pressed.SHIFT)
            {
                movex *= 10;
                movey *= 10;
            }

            if(movex != 0 || movey != 0)
            {
                selecArr[0] -= movex;
                selecArr[1] += movey;
                updateOffsetText();
                splashes.members[curSelected].offset.set(selecArr[0], selecArr[1]);
            }
        }

        // Copy / Paste
        if(FlxG.keys.pressed.CONTROL)
        {
            if(FlxG.keys.justPressed.C)
            {
                var arr:Array<Float> = selectedArray();
                if(copiedArray == null) copiedArray = [0, 0];
                copiedArray[0] = arr[0];
                copiedArray[1] = arr[1];
            }
            else if(FlxG.keys.justPressed.V && copiedArray != null)
            {
                var offs:Array<Float> = selectedArray();
                offs[0] = copiedArray[0];
                offs[1] = copiedArray[1];
                splashes.members[curSelected].offset.set(offs[0], offs[1]);
                updateOffsetText();
            }
        }

        pressEnterToSave -= elapsed;
        if(visibleTime >= 0)
        {
            visibleTime -= elapsed;
            if(visibleTime <= 0)
                savedText.visible = false;
        }

        // Save (press ENTER twice to confirm)
        if(FlxG.keys.justPressed.ENTER)
        {
            savedText.text = 'Press ENTER again to save.';
            if(pressEnterToSave > 0)
            {
                saveFile();
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
                pressEnterToSave = 0;
                visibleTime = 3;
            }
            else
            {
                pressEnterToSave = 0.5;
                visibleTime = 0.5;
            }
            savedText.visible = true;
        }

        // Reset / switch animation
        if (FlxG.keys.justPressed.SPACE)
            changeAnim();
        else if (FlxG.keys.justPressed.W) changeAnim(1);
        else if (FlxG.keys.justPressed.S) changeAnim(-1);

        // Force frame
        var updatedFrame:Bool = false;
        if(updatedFrame = FlxG.keys.justPressed.Q) forceFrame--;
        else if(updatedFrame = FlxG.keys.justPressed.E) forceFrame++;

        if(updatedFrame)
        {
            if(forceFrame < 0) forceFrame = 0;
            else if(forceFrame >= maxFrame) forceFrame = maxFrame - 1;

            curFrameText.text = 'Force Frame: ${forceFrame+1} / $maxFrame\n(Press Q/E to change)';
            splashes.forEachAlive(function(spr:FlxSprite) {
                if(spr.animation.curAnim != null) {
                    spr.animation.curAnim.paused = true;
                    spr.animation.curAnim.curFrame = forceFrame;
                }
            });
        }
    }

    function updateOffsetText()
    {
        selecArr = selectedArray();
        offsetsText.text = 'Offsets [Dir $curSelected, ${animModeNames[curAnimMode]}]: ${selecArr.toString()}';
    }

    function loadFrames()
    {
        texturePath = textureName;
        splashes.forEachAlive(function(spr:FlxSprite) {
            spr.frames = Paths.getSparrowAtlas(texturePath);
        });

        config = readConfigDirectly(texturePath);
        if(config == null) config = readConfigDirectly(defaultTexture);

        if(config == null) {
            // Default config matching SustainSplash defaults
            var defaultOffsets:Array<Array<Float>> = [];
            for(i in 0...8) defaultOffsets.push([110, 100]); // 4 hold + 4 end
            config = {
                holdAnim: 'hold',
                endAnim: 'end',
                holdFps: 24,
                endFps: 24,
                offsets: defaultOffsets
            };
        }

        holdAnimInputText.text = config.holdAnim;
        endAnimInputText.text = config.endAnim;
        stepperHoldFps.value = config.holdFps;
        stepperEndFps.value = config.endFps;

        reloadAnims();
    }

    function getTxtPath(skin:String):String
    {
        #if sys

        var modPngPath:String = Paths.modFolders('images/$skin.png');
        if (modPngPath != null && modPngPath.length > 0 && sys.FileSystem.exists(modPngPath))
        {
            return modPngPath.substr(0, modPngPath.length - 4) + '.txt';
        }
        else
        {
            var rawPath:String = Paths.getPath('images/$skin.png', IMAGE);
            if (rawPath != null && rawPath.length > 0)
            {
                if (rawPath.startsWith('file://')) rawPath = rawPath.substr(7);
                var colonPos = rawPath.indexOf(':');
                if (colonPos > 1) rawPath = rawPath.substr(colonPos + 1);
                var absPath:String = sys.FileSystem.absolutePath(rawPath).replace('\\', '/');
                var dirPath = absPath.substr(0, absPath.lastIndexOf('/'));
                if (sys.FileSystem.exists(dirPath))
                {
                    return absPath.substr(0, absPath.length - 4) + '.txt';
                }
            }
        }
        #end
        return '';
    }

    function readConfigDirectly(skin:String):HoldCoverConfig
    {
        #if sys
        var realPath:String = getTxtPath(skin);
        if (realPath.length > 0 && sys.FileSystem.exists(realPath))
        {
            var content:String = sys.io.File.getContent(realPath).replace('\r', '');
            var lines:Array<String> = content.split('\n');

            if(lines.length < 10) return null; // Need at least 10 lines for a valid hold cover config

            var holdAnim:String = StringTools.trim(lines[0]);
            var endAnim:String = StringTools.trim(lines[1]);

            var fpsArr:Array<String> = lines[2].split(' ');
            var holdFps:Int = Std.parseInt(StringTools.trim(fpsArr[0]));
            var endFps:Int = Std.parseInt(StringTools.trim(fpsArr[1]));

            var offsets:Array<Array<Float>> = [];
            // Lines 3-6: hold offsets for directions 0..3
            // Lines 7-10: end offsets for directions 0..3
            for (i in 3...lines.length)
            {
                var animOffs:Array<String> = lines[i].split(' ');
                if(animOffs.length >= 2) {
                    offsets.push([
                        Std.parseFloat(StringTools.trim(animOffs[0])),
                        Std.parseFloat(StringTools.trim(animOffs[1]))
                    ]);
                }
            }

            trace('Successfully loaded hold cover config: $realPath');
            return {
                holdAnim: holdAnim,
                endAnim: endAnim,
                holdFps: holdFps,
                endFps: endFps,
                offsets: offsets
            };
        }
        #end
        return null;
    }

    function saveFile()
    {
        #if sys
        // Trim offsets to only the ones we need (max 8: 4 hold + 4 end)
        var maxLen:Int = 8;
        var curLen:Int = config.offsets.length;
        while(curLen > maxLen)
        {
            config.offsets.pop();
            curLen = config.offsets.length;
        }

        var strToSave = config.holdAnim + '\n' + config.endAnim + '\n';
        strToSave += config.holdFps + ' ' + config.endFps;
        for (offGroup in config.offsets)
            strToSave += '\n' + offGroup[0] + ' ' + offGroup[1];

        var path:String = getTxtPath(texturePath);
        if(path.length > 0) {
            savedText.text = 'Saved to: $path';
            sys.io.File.saveContent(path, strToSave);
        } else {
            savedText.text = 'Error: Could not resolve save path.';
        }
        #else
        savedText.text = 'Can\'t save on this platform, too bad.';
        #end
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
        {
            var nums:FlxUINumericStepper = cast sender;
            var wname = nums.name;
            switch(wname)
            {
                case 'hold_fps':
                    if(nums.value > stepperEndFps.value)
                        stepperEndFps.value = nums.value;
                case 'end_fps':
                    if(nums.value < stepperHoldFps.value)
                        stepperHoldFps.value = nums.value;
            }
            if(config != null) {
                config.holdFps = Std.int(stepperHoldFps.value);
                config.endFps = Std.int(stepperEndFps.value);
            }
        }
    }

    function reloadAnims()
    {
        splashes.forEachAlive(function(spr:FlxSprite)
        {
            if(spr.animation != null) spr.animation.destroyAnimations();
        });

        var hasHold:Bool = false;
        var hasEnd:Bool = false;

        splashes.forEachAlive(function(spr:FlxSprite)
        {
            // Add hold animation
            spr.animation.addByPrefix('hold', config.holdAnim, config.holdFps, true);
            hasHold = spr.animation.getByName('hold') != null;

            // Add end animation
            spr.animation.addByPrefix('end', config.endAnim, config.endFps, false);
            hasEnd = spr.animation.getByName('end') != null;
        });

        trace('Hold cover anims - Has hold: $hasHold, Has end: $hasEnd');
        changeAnim();
    }

    function changeAnim(change:Int = 0)
    {
        maxFrame = 0;
        forceFrame = -1;

        // Toggle mode if change is provided (W = +1, S = -1)
        if(change != 0)
        {
            curAnimMode += change;
            if(curAnimMode > 1) curAnimMode = 0;
            else if(curAnimMode < 0) curAnimMode = 1;
        }

        var modeName:String = animModeNames[curAnimMode];
        var hasAnim:Bool = splashes.members[0] != null && splashes.members[0].animation.getByName(modeName) != null;

        curModeText.text = 'Mode: ${modeName.toUpperCase()} (Press TAB or W/S to toggle)';

        if(hasAnim)
        {
            curAnimText.text = 'Playing: $modeName animation [${config.holdAnim} / ${config.endAnim}]';
            curFrameText.text = 'Force Frame Disabled\n(Press Q/E to change)';

            for (i in 0...maxNotes)
            {
                var spr:FlxSprite = splashes.members[i];
                spr.animation.play(modeName, true);

                if(spr.animation.curAnim != null) {
                    if(maxFrame < spr.animation.curAnim.numFrames)
                        maxFrame = spr.animation.curAnim.numFrames;

                    var fps:Int = curAnimMode == 0 ? config.holdFps : config.endFps;
                    if (fps <= 0) fps = 24;
                    spr.animation.curAnim.frameRate = fps;
                }

                var offs:Array<Float> = selectedArray(i);
                spr.offset.set(offs[0], offs[1]);
            }
        }
        else
        {
            curAnimText.text = 'INVALID ANIMATION: "$modeName" (prefix: ${curAnimMode == 0 ? config.holdAnim : config.endAnim})';
            curFrameText.text = '';
        }
        updateOffsetText();
    }

    function changeSelection(change:Int = 0)
    {
        var max:Int = colArray.length;
        curSelected += change;
        if(curSelected < 0) curSelected = max - 1;
        else if(curSelected >= max) curSelected = 0;

        selection.x = curSelected * 220 + 220;
        updateOffsetText();
    }

    /**
     *  Gets the offset array for a specific direction and current anim mode.
     *  Index layout: [0..3] = hold offsets (dir 0-3), [4..7] = end offsets (dir 0-3)
     */
    function selectedArray(sel:Int = -1)
    {
        if(sel < 0) sel = curSelected;
        var offsetIndex:Int = sel + (curAnimMode * colArray.length);

        if(config.offsets[offsetIndex] == null)
        {
            while(config.offsets[offsetIndex] == null)
                config.offsets.push(config.offsets[Std.int(wrap(offsetIndex, 0, config.offsets.length-1))].copy());
        }
        return config.offsets[Std.int(wrap(offsetIndex, 0, config.offsets.length-1))];
    }

    inline function wrap(value:Float, min:Float, max:Float):Float
    {
        var rangeSize:Float = max - min + 1;
        if (rangeSize == 0) return min;
        var valueMod:Float = (value - min) % rangeSize;
        if (valueMod < 0) valueMod += rangeSize;
        return min + valueMod;
    }

    override function destroy()
    {
        super.destroy();
    }
}

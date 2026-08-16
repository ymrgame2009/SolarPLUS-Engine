package editors;

import Note;
import StrumNote;
import SustainSplash;
import NoteSplash;
import flixel.text.FlxText;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUICheckBox;
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

class NoteSplashDebugState extends MusicBeatState
{
    var config:NoteSplashConfig;
    var forceFrame:Int = -1;
    var curSelected:Int = 0;
    var maxNotes:Int = 4;

    var curAnim:Int = 1;
    var maxAnims:Int = 0;

    var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

    var selection:FlxSprite;
    var notes:FlxTypedGroup<StrumNote>;
    var splashes:FlxTypedGroup<FlxSprite>;
    var splashShaders:Array<NoteSplash.PixelSplashShaderRef> = [];

    var imageInputText:FlxInputText;
    var nameInputText:FlxInputText;
    var stepperMinFps:FlxUINumericStepper;
    var stepperMaxFps:FlxUINumericStepper;
    var stepperScale:FlxUINumericStepper;
    var rgbCheckbox:FlxUICheckBox;
    var pixelCheckbox:FlxUICheckBox;

    var lastRGB:Bool = true;
    var lastPixel:Bool = true;
    var lastScale:Float = 1.0;

    var offsetsText:FlxText;
    var curFrameText:FlxText;
    var curAnimText:FlxText;
    var savedText:FlxText;
    var selecArr:Array<Float> = null;

    var missingTextBG:FlxSprite;
    var missingText:FlxText;

    public static final defaultTexture:String = 'noteSplashes';

    var maxFrame:Int = 0;
    var visibleTime:Float = 0;
    var pressEnterToSave:Float = 0;
    var textureName:String = defaultTexture;
    var texturePath:String = '';
    var copiedArray:Array<Float> = null;

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
            splash.setPosition(splash.x - Note.swagWidth * 0.95, splash.y - Note.swagWidth);

            var splashShader:NoteSplash.PixelSplashShaderRef = new NoteSplash.PixelSplashShaderRef();
            splashShader.copyValues(note.rgbShader.parent);
            splashShader.shader.uBlocksize.value = [1, 1];
            splashShaders.push(splashShader);
            splash.shader = splashShader.shader;

            splash.antialiasing = ClientPrefs.globalAntialiasing;
            splashes.add(splash);
        }

        var startX = 50;
        var startY = 540;

        add(new FlxText(startX, startY, 0, 'Image Name:', 16));
        imageInputText = new FlxInputText(startX, startY + 20, 350, defaultTexture, 16);
        imageInputText.callback = function(text:String, action:String)
        {
            switch(action) {
                case 'enter':
                    imageInputText.hasFocus = false; textureName = text;
                    try { loadFrames(); } catch(e:Dynamic) {
                        textureName = defaultTexture; loadFrames();
                        missingText.text = 'ERROR WHILE LOADING IMAGE:\n$text';
                        missingText.screenCenter(Y); missingText.visible = true; missingTextBG.visible = true;
                        FlxG.sound.play(Paths.sound('cancelMenu'));
                        new FlxTimer().start(2.5, function(tmr:FlxTimer) { missingText.visible = false; missingTextBG.visible = false; });
                    }
            }
        };
        add(imageInputText);

        add(new FlxText(startX + 400, startY, 0, 'Animation Name:', 16));
        nameInputText = new FlxInputText(startX + 400, startY + 20, 350, '', 16);
        nameInputText.callback = function(text:String, action:String)
        {
            switch(action) {
                case 'enter':
                    nameInputText.hasFocus = false;
                    if (config != null) { config.anim = text; curAnim = 1; reloadAnims(); }
                default:
                    if (config != null) { config.anim = text; curAnim = 1; reloadAnims(); }
            }
        };
        add(nameInputText);

        add(new FlxText(startX, startY + 60, 0, 'Min FPS:', 16));
        stepperMinFps = new FlxUINumericStepper(startX, startY + 80, 1, 22, 1, 60, 0);
        stepperMinFps.name = 'min_fps';
        add(stepperMinFps);

        add(new FlxText(startX + 100, startY + 60, 0, 'Max FPS:', 16));
        stepperMaxFps = new FlxUINumericStepper(startX + 100, startY + 80, 1, 26, 1, 60, 0);
        stepperMaxFps.name = 'max_fps';
        add(stepperMaxFps);

        add(new FlxText(startX + 200, startY + 60, 0, 'Scale:', 16));
        stepperScale = new FlxUINumericStepper(startX + 200, startY + 80, 0.1, 1, 0.1, 10, 1);
        stepperScale.name = 'scale';
        add(stepperScale);

        rgbCheckbox = new FlxUICheckBox(startX + 350, startY + 75, null, null, "Allow RGB", 120);
        rgbCheckbox.checked = true;
        rgbCheckbox.box.scale.set(1.4, 1.4);
        rgbCheckbox.mark.scale.set(1.4, 1.4);
        var rgbTxt:FlxText = cast rgbCheckbox.button.label; rgbTxt.size = 16; rgbTxt.offset.y -= 2;
        add(rgbCheckbox);

        pixelCheckbox = new FlxUICheckBox(startX + 500, startY + 75, null, null, "Allow Pixel", 120);
        pixelCheckbox.checked = true;
        pixelCheckbox.box.scale.set(1.4, 1.4);
        pixelCheckbox.mark.scale.set(1.4, 1.4);
        var pixelTxt:FlxText = cast pixelCheckbox.button.label; pixelTxt.size = 16; pixelTxt.offset.y -= 2;
        add(pixelCheckbox);

        offsetsText = new FlxText(300, 150, 680, '', 16);
        offsetsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(offsetsText);

        curFrameText = new FlxText(300, 100, 680, '', 16);
        curFrameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(curFrameText);

        curAnimText = new FlxText(300, 50, 680, '', 16);
        curAnimText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(curAnimText);

        var text:FlxText = new FlxText(0, 680, FlxG.width, "SPACE: Reset | ENTERx2: Save | A/D: Change Note | Arrows: Offset | Ctrl+C/V: Copy/Paste", 16);
        text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(text);

        savedText = new FlxText(0, 340, FlxG.width, '', 24);
        savedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(savedText);

        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        missingTextBG.alpha = 0.6; missingTextBG.visible = false; add(missingTextBG);

        missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
        missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        missingText.visible = false; add(missingText);

        loadFrames();
        changeSelection();
        super.create();
        FlxG.mouse.visible = true;
    }

    override function update(elapsed:Float)
    {
        @:privateAccess
        cast(stepperMinFps.text_field, FlxInputText).hasFocus = cast(stepperMaxFps.text_field, FlxInputText).hasFocus = false;
        @:privateAccess
        cast(stepperScale.text_field, FlxInputText).hasFocus = false;

        var notTyping:Bool = !nameInputText.hasFocus && !imageInputText.hasFocus;
        if(controls.BACK && notTyping)
        {
            MusicBeatState.switchState(new MasterEditorMenu());
            FlxG.sound.playMusic(Paths.music("freakyMenu-" + ClientPrefs.mmm));
            FlxG.mouse.visible = false;
        }
        super.update(elapsed);

        if(!notTyping) return;

        var curRGB:Bool = rgbCheckbox.checked;
        var curPixel:Bool = pixelCheckbox.checked;
        var curScale:Float = stepperScale.value;
        if(curRGB != lastRGB || curPixel != lastPixel || curScale != lastScale)
        {
            lastRGB = curRGB;
            lastPixel = curPixel;
            lastScale = curScale;
            if(config != null)
            {
                config.allowRGB = curRGB;
                config.allowPixel = curPixel;
                if(curScale > 0) config.scale = curScale;
            }
            applyVisualSettings();
            reapplyOffsets();
        }

        if (FlxG.keys.justPressed.A) changeSelection(-1);
        else if (FlxG.keys.justPressed.D) changeSelection(1);

        if (maxAnims < 1) return;

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
                splashes.members[curSelected].offset.set(10 + selecArr[0], 10 + selecArr[1]);
            }
        }

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
                splashes.members[curSelected].offset.set(10 + offs[0], 10 + offs[1]);
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

        if (FlxG.keys.justPressed.SPACE) changeAnim();
        else if (FlxG.keys.justPressed.W) changeAnim(1);
        else if (FlxG.keys.justPressed.S) changeAnim(-1);

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
        offsetsText.text = 'Offsets [Dir $curSelected, Anim $curAnim]: ${selecArr.toString()}';
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
            var defaultOffsets:Array<Array<Float>> = [];
            for(i in 0...20) defaultOffsets.push([0, 0]);
            config = {
                anim: 'note splash',
                minFps: 22,
                maxFps: 26,
                offsets: defaultOffsets,
                scale: 1.0,
                allowRGB: true,
                allowPixel: true
            };
        }

        // Ensure optional fields exist
        if (config.scale == null) config.scale = 1.0;
        if (config.allowRGB == null) config.allowRGB = true;
        if (config.allowPixel == null) config.allowPixel = true;

        nameInputText.text = config.anim;
        stepperMinFps.value = config.minFps;
        stepperMaxFps.value = config.maxFps;
        stepperScale.value = config.scale;
        rgbCheckbox.checked = config.allowRGB;
        pixelCheckbox.checked = config.allowPixel;
        lastScale = config.scale;
        lastRGB = config.allowRGB;
        lastPixel = config.allowPixel;

        reloadAnims();
    }

    function getTxtPath(skin:String):String
    {
        #if sys
        var modPngPath:String = Paths.modFolders('images/$skin.png');
        if (modPngPath != null && modPngPath.length > 0 && sys.FileSystem.exists(modPngPath))
            return modPngPath.substr(0, modPngPath.length - 4) + '.txt';
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
                    return absPath.substr(0, absPath.length - 4) + '.txt';
            }
        }
        #end
        return '';
    }

    function readConfigDirectly(skin:String):NoteSplashConfig
    {
        #if sys
        var realPath:String = getTxtPath(skin);
        if (realPath.length > 0 && sys.FileSystem.exists(realPath))
        {
            var content:String = sys.io.File.getContent(realPath).replace('\r', '');
            var lines:Array<String> = content.split('\n');

            if(lines.length < 2) return null;

            var framerates:Array<String> = lines[1].split(' ');
            var minFps:Int = Std.parseInt(StringTools.trim(framerates[0]));
            var maxFps:Int = Std.parseInt(StringTools.trim(framerates[1]));

            var remaining:Array<String> = [];
            for (i in 2...lines.length)
            {
                var line:String = StringTools.trim(lines[i]);
                if(line.length > 0) remaining.push(line);
            }

            var offsets:Array<Array<Float>> = [];
            var scale:Float = 1.0;
            var allowRGB:Bool = true;
            var allowPixel:Bool = true;

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
                        offsets.push([ox, oy]);
                }
            }

            if(hasExtended)
            {
                var parsedScale:Float = Std.parseFloat(StringTools.trim(remaining[n-3]));
                if(!Math.isNaN(parsedScale) && parsedScale > 0) scale = parsedScale;
                allowRGB = parseBool(remaining[n-2]);
                allowPixel = parseBool(remaining[n-1]);
            }

            trace('Loaded splash config: $realPath');
            return {
                anim: StringTools.trim(lines[0]),
                minFps: minFps,
                maxFps: maxFps,
                offsets: offsets,
                scale: scale,
                allowRGB: allowRGB,
                allowPixel: allowPixel
            };
        }
        #end
        return null;
    }

    function saveFile()
    {
        #if sys
        var maxLen:Int = maxAnims * colArray.length;
        var curLen:Int = config.offsets.length;
        while(curLen > maxLen) { config.offsets.pop(); curLen = config.offsets.length; }

        var scaleVal:Float = (config.scale != null) ? config.scale : 1.0;
        var rgbVal:String = (config.allowRGB != null && config.allowRGB) ? 'true' : 'false';
        var pixelVal:String = (config.allowPixel != null && config.allowPixel) ? 'true' : 'false';

        var strToSave = config.anim + '\n' + config.minFps + ' ' + config.maxFps;
        for (offGroup in config.offsets)
            strToSave += '\n' + offGroup[0] + ' ' + offGroup[1];
        strToSave += '\n' + scaleVal;
        strToSave += '\n' + rgbVal;
        strToSave += '\n' + pixelVal;

        var path:String = getTxtPath(texturePath);
        if(path.length > 0) {
            savedText.text = 'Saved to: $path';
            sys.io.File.saveContent(path, strToSave);
        } else {
            savedText.text = 'Error: Could not resolve save path.';
        }
        #else
        savedText.text = 'Can\'t save on this platform.';
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
                case 'min_fps': if(nums.value > stepperMaxFps.value) stepperMaxFps.value = nums.value;
                case 'max_fps': if(nums.value < stepperMinFps.value) stepperMinFps.value = nums.value;
                case 'scale': if(config != null && nums.value > 0) config.scale = nums.value;
            }
            if(config != null) {
                config.minFps = Std.int(stepperMinFps.value);
                config.maxFps = Std.int(stepperMaxFps.value);
            }
        }
    }

    /**
     * Adds animation by prefix and returns true if it was actually created.
     * Uses the same pattern as the old working code.
     */
    function addAnimAndCheck(spr:FlxSprite, name:String, prefix:String, framerate:Int, loop:Bool):Bool
    {
        spr.animation.addByPrefix(name, prefix, framerate, loop);
        return spr.animation.getByName(name) != null;
    }

    function reloadAnims()
    {
        var loopContinue:Bool = true;
        splashes.forEachAlive(function(spr:FlxSprite) {
            if(spr.animation != null) spr.animation.destroyAnimations();
        });

        maxAnims = 0;
        while(loopContinue)
        {
            var animID:Int = maxAnims + 1;
            splashes.forEachAlive(function(spr:FlxSprite)
            {
                for (i in 0...colArray.length) {
                    var animName = 'note$i-$animID';
                    var prefix = '${config.anim} ${colArray[i]} $animID';
                    if (!addAnimAndCheck(spr, animName, prefix, 24, false)) {
                        loopContinue = false;
                        return;
                    }
                }
            });
            if(loopContinue) maxAnims++;
        }
        trace('maxAnims: $maxAnims');
        changeAnim();
    }

    function applyVisualSettings()
    {
        var useScale:Float = (stepperScale != null && stepperScale.value > 0) ? stepperScale.value : 1.0;
        var useRGB:Bool = (rgbCheckbox != null) ? rgbCheckbox.checked : true;

        for (i in 0...maxNotes)
        {
            var spr:FlxSprite = splashes.members[i];
            if(spr == null) continue;

            spr.scale.set(useScale, useScale);
            spr.updateHitbox();

            var shaderRef:NoteSplash.PixelSplashShaderRef = (i < splashShaders.length) ? splashShaders[i] : null;
            if(shaderRef != null)
            {
                if(useRGB) {
                    var note:StrumNote = notes.members[i];
                    if(note != null && note.rgbShader != null && note.rgbShader.parent != null)
                        shaderRef.copyValues(note.rgbShader.parent);
                } else {
                    shaderRef.copyValues(null);
                }
                shaderRef.shader.uBlocksize.value = [1, 1];
            }
        }
    }

    function reapplyOffsets()
    {
        for (i in 0...maxNotes)
        {
            var spr:FlxSprite = splashes.members[i];
            if(spr == null) continue;
            var offs:Array<Float> = selectedArray(i);
            spr.offset.set(10 + offs[0], 10 + offs[1]);
        }
    }

    function changeAnim(change:Int = 0)
    {
        maxFrame = 0;
        forceFrame = -1;
        if (maxAnims > 0)
        {
            curAnim += change;
            if(curAnim > maxAnims) curAnim = 1;
            else if(curAnim < 1) curAnim = maxAnims;

            curAnimText.text = 'Current Animation: $curAnim / $maxAnims\n(Press W/S to change)';
            curFrameText.text = 'Force Frame Disabled\n(Press Q/E to change)';

            for (i in 0...maxNotes)
            {
                var spr:FlxSprite = splashes.members[i];
                spr.animation.play('note$i-$curAnim', true);

                if(spr.animation.curAnim != null) {
                    if(maxFrame < spr.animation.curAnim.numFrames)
                        maxFrame = spr.animation.curAnim.numFrames;

                    var minFps:Int = config.minFps;
                    var maxFps:Int = config.maxFps;
                    if (minFps <= 0) minFps = 22;
                    if (maxFps <= 0 || maxFps < minFps) maxFps = minFps;

                    spr.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
                }
            }

            applyVisualSettings();
            reapplyOffsets();
        }
        else
        {
            curAnimText.text = 'INVALID ANIMATION NAME';
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

    function selectedArray(sel:Int = -1)
    {
        if(sel < 0) sel = curSelected;
        var offsetIndex:Int = sel + ((curAnim - 1) * colArray.length);

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

    static function isBoolToken(s:String):Bool {
        var v:String = StringTools.trim(s).toLowerCase();
        return v == 'true' || v == 'false';
    }

    static function parseBool(s:String):Bool {
        var v:String = StringTools.trim(s).toLowerCase();
        return v == 'true' || v == '1';
    }

    static function isSingleNumber(s:String):Bool {
        var v:String = StringTools.trim(s);
        if(v.length == 0) return false;
        if(v.indexOf(' ') >= 0) return false;
        var lv:String = v.toLowerCase();
        if(lv == 'true' || lv == 'false') return false;
        var f:Float = Std.parseFloat(v);
        return !Math.isNaN(f);
    }

    override function destroy()
    {
        super.destroy();
    }
}
package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.sound.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

using StringTools;

class FreeplayState extends MusicBeatState
{

	    // Dummy variables to prevent breaking other states
    public static var vocals:FlxSound = null;
    public static function destroyFreeplayVocals()
    {
        if (vocals != null)
        {
            vocals.stop();
            vocals.destroy();
        }
        vocals = null;
    }

    var songs:Array<SongMetadata> = [];

    var selector:FlxText;

    private static var curSelected:Int = 0;

    var curDifficulty:Int = -1;

    private static var lastDifficultyName:String = '';

    var scoreBG:FlxSprite;
    var scoreText:FlxText;
    var diffText:FlxText;
    var lerpScore:Int = 0;
    var lerpRating:Float = 0;
    var intendedScore:Int = 0;
    var intendedRating:Float = 0;

    private var grpSongs:FlxTypedGroup<Alphabet>;
    private var curPlaying:Bool = false;

    private var iconArray:Array<HealthIcon> = [];

    var bg:FlxSprite;
    var intendedColor:Int;
    var colorTween:FlxTween;

    public var cheatText:FlxText = new FlxText(FlxG.width / 2 - 100, FlxG.height - 92, 0, "Scores won't save because of cheating", 32);

    var mask:FlxSprite = null;
    public var musicPlayer:MusicPlayer;

    override function create()
    {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        ShortcutMenuSubState.inShortcutMenu = false;

        persistentUpdate = true;
        PlayState.isStoryMode = false;
        WeekData.reloadWeekFiles(false);

        #if desktop
        DiscordClient.changePresence("In the Menus", null);
        #end

        for (i in 0...WeekData.weeksList.length)
        {
            if (weekIsLocked(WeekData.weeksList[i]))
                continue;

            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            var leSongs:Array<String> = [];
            var leChars:Array<String> = [];

            for (j in 0...leWeek.songs.length)
            {
                leSongs.push(leWeek.songs[j][0]);
                leChars.push(leWeek.songs[j][1]);
            }

            WeekData.setDirectoryFromWeek(leWeek);
            for (song in leWeek.songs)
            {
                var colors:Array<Int> = song[2];
                if (colors == null || colors.length < 3)
                {
                    colors = [146, 113, 253];
                }
                addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
            }
        }
        WeekData.loadTheFirstEnabledMod();

        if (ClientPrefs.darkmode)
        {
            bg = new FlxSprite(0, 0).loadGraphic(Paths.image("aboutMenu", "preload"));
            bg.antialiasing = ClientPrefs.globalAntialiasing;
            add(bg);
            bg.screenCenter();
        }
        else
        {
            bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
            bg.antialiasing = ClientPrefs.globalAntialiasing;
            add(bg);
            bg.screenCenter();
        }

        var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
        grid.velocity.set(40, 20);
        grid.alpha = 0;
        FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        add(grid);

        mask = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        mask.alpha = 0;
        add(mask);

        grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

        for (i in 0...songs.length)
        {
            var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
            songText.isMenuItem = true;
            songText.targetY = i - curSelected;
            songText.targetX = i + curSelected;
            if (ClientPrefs.fm)
            {
                songText.x = 320;
            }
            grpSongs.add(songText);

            var maxWidth = 980;
            if (songText.width > maxWidth)
            {
                songText.scaleX = maxWidth / songText.width;
            }

            Paths.currentModDirectory = songs[i].folder;
            var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
            icon.sprTracker = songText;

            iconArray.push(icon);
            add(icon);
        }
        WeekData.setDirectoryFromWeek();

        add(musicPlayer = new MusicPlayer());
        musicPlayer.controls = this.controls;
        musicPlayer.onUpdateUI.add(function(activate, onComplete) {
            for (song in grpSongs.members) {
                if (song == grpSongs.members[curSelected]) {
                    FlxTween.tween(song.distanceOffset, {x: activate ? 245 : 0}, 2, {ease: FlxEase.circOut, onComplete: onComplete});
                    continue;
                }
                FlxTween.tween(song, {alpha: activate ? 0 : 0.6}, 2, {ease: FlxEase.smoothStepOut});
            }
            for (icon in iconArray) {
                if (icon == iconArray[curSelected]) continue;
                FlxTween.tween(icon, {alpha: activate ? 0 : 1}, 1, {ease: FlxEase.smoothStepOut});
            }
            FlxTween.tween(mask, {alpha: activate ? 0.7 : 0}, 1, {ease: FlxEase.sineIn});
        });

        scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
        scoreText.setFormat(Paths.font("funkin.ttf"), 32, FlxColor.WHITE, RIGHT);

        scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
        scoreBG.alpha = 0.6;
        add(scoreBG);

        diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        diffText.font = scoreText.font;
        add(diffText);

        add(scoreText);

        if (curSelected >= songs.length)
            curSelected = 0;
        bg.color = songs[curSelected].color;
        intendedColor = bg.color;

        if (lastDifficultyName == '')
        {
            lastDifficultyName = CoolUtil.defaultDifficulty;
        }
        curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

        changeSelection();
        changeDiff();

        var swag:Alphabet = new Alphabet(1, 0, "swag");

        var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
        textBG.alpha = 0.6;
        add(textBG);

        #if PRELOAD_ALL
        var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
        var size:Int = 16;
        #else
        var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
        var size:Int = 18;
        #end
        var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
        text.setFormat(Paths.font("funkin.ttf"), size, FlxColor.WHITE, CENTER);
        text.scrollFactor.set();
        add(text);

        cheatText.scrollFactor.set();
        cheatText.setFormat(Paths.font("funkin.ttf"), 32, FlxColor.WHITE, CENTER);
        add(cheatText);
        cheatText.alpha = 0;

        super.create();
    }

    override function closeSubState()
    {
        changeSelection(0, false);
        persistentUpdate = true;
        super.closeSubState();
    }

    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
    {
        songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
    }

    function weekIsLocked(name:String):Bool
    {
        var leWeek:WeekData = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked
            && leWeek.weekBefore.length > 0
            && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }

    var holdTime:Float = 0;

    override function update(elapsed:Float)
    {
        var bot:Bool = ClientPrefs.gameplaySettings.get('botplay');
        var practice:Bool = ClientPrefs.gameplaySettings.get('practice');
        var modchart:Bool = ClientPrefs.gameplaySettings.get('modchart');

        if (musicPlayer.listening) 
        {
            scoreText.text = 'Listening To: ' + songs[curSelected].songName.toUpperCase();
            super.update(elapsed);
            return;
        }

        if (FlxG.sound.music.volume < 0.7)
        {
            FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
        }

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
        lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

        if (Math.abs(lerpScore - intendedScore) <= 10)
            lerpScore = intendedScore;
        if (Math.abs(lerpRating - intendedRating) <= 0.01)
            lerpRating = intendedRating;

        var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
        if (ratingSplit.length < 2)
        {
            ratingSplit.push('');
        }

        while (ratingSplit[1].length < 2)
        {
            ratingSplit[1] += '0';
        }

        if (ClientPrefs.cm)
        {
            bg.color = 0xFFfd719b;
        }

        scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
        positionHighscore();

        var upP = controls.UI_UP_P;
        var downP = controls.UI_DOWN_P;
        var accepted = controls.ACCEPT;
        var space = FlxG.keys.justPressed.SPACE;
        var ctrl = FlxG.keys.justPressed.CONTROL;

        var shiftMult:Int = 1;
        if (FlxG.keys.pressed.SHIFT)
            shiftMult = 3;

        if (bot || practice)
        {
            FlxTween.tween(cheatText, {alpha: 1}, 1);
        }
        else
        {
            FlxTween.tween(cheatText, {alpha: 0}, 1);
        }

        if (songs.length > 1 && !ShortcutMenuSubState.inShortcutMenu)
        {
            if (upP)
            {
                changeSelection(-shiftMult);
                holdTime = 0;
            }
            if (downP)
            {
                changeSelection(shiftMult);
                holdTime = 0;
            }

            if (controls.UI_DOWN || controls.UI_UP)
            {
                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                holdTime += elapsed;
                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

                if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                {
                    changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
                    changeDiff();
                }
            }

            if (FlxG.mouse.wheel != 0)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
                changeSelection(-shiftMult * FlxG.mouse.wheel, false);
                changeDiff();
            }
        }

        if (FlxG.keys.justPressed.TAB)
        {
            openSubState(new ShortcutMenuSubState());
            ShortcutMenuSubState.inShortcutMenu = true;
        }

        if (controls.UI_LEFT_P)
            changeDiff(-1);
        else if (controls.UI_RIGHT_P)
            changeDiff(1);
        else if (upP || downP)
            changeDiff();

        if (controls.BACK && !ShortcutMenuSubState.inShortcutMenu)
        {
            persistentUpdate = false;
            if (colorTween != null)
            {
                colorTween.cancel();
            }
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (ClientPrefs.fm)
            {
                MusicBeatState.switchState(new CoolMenuState());
            }
            else
            {
                MusicBeatState.switchState(new MainMenuState());
            }
        }

        if (ctrl && !ShortcutMenuSubState.inShortcutMenu)
        {
            persistentUpdate = false;
            openSubState(new GameplayChangersSubstate());
        }
        else if (space)
        {
            musicPlayer.load(songs[curSelected], curDifficulty);
        }
        else if (accepted && !ShortcutMenuSubState.inShortcutMenu)
        {
            persistentUpdate = false;
            var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
            var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

            try
            {
                PlayState.SONG = Song.loadFromJson(poop, songLowercase);
            }
            catch (e:Dynamic)
            {
                lime.app.Application.current.window.alert('Error loading song!\n$e');
                return;
            }

            trace(poop);

            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = curDifficulty;

            trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
            if (colorTween != null)
            {
                colorTween.cancel();
            }

            if (FlxG.keys.pressed.SHIFT)
            {
                LoadingState.loadAndSwitchState(new ChartingState());
            }
            else
            {
                LoadingState.loadAndSwitchState(new PlayState());
            }

            FlxG.sound.music.volume = 0;
        }
        else if (controls.RESET)
        {
            persistentUpdate = false;
            openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        super.update(elapsed);
    }

    function changeDiff(change:Int = 0)
    {
        curDifficulty += change;

        if (curDifficulty < 0)
            curDifficulty = CoolUtil.difficulties.length - 1;
        if (curDifficulty >= CoolUtil.difficulties.length)
            curDifficulty = 0;

        lastDifficultyName = CoolUtil.difficulties[curDifficulty];

        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
        intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
        #end

        PlayState.storyDifficulty = curDifficulty;
        diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
        positionHighscore();
    }

    function changeSelection(change:Int = 0, playSound:Bool = true)
    {
        if (playSound)
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curSelected += change;

        if (curSelected < 0)
            curSelected = songs.length - 1;
        if (curSelected >= songs.length)
            curSelected = 0;

        var newColor:Int = songs[curSelected].color;
        if (newColor != intendedColor)
        {
            if (colorTween != null)
            {
                colorTween.cancel();
            }
            intendedColor = newColor;
            colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
                onComplete: function(twn:FlxTween)
                {
                    colorTween = null;
                }
            });
        }

        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
        intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
        #end

        var bullShit:Int = 0;

        for (i in 0...iconArray.length)
        {
            iconArray[i].alpha = 0.6;
        }

        iconArray[curSelected].alpha = 1;

        for (item in grpSongs.members)
        {
            item.targetY = bullShit - curSelected;
            item.targetX = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;

            if (item.targetY == 0)
            {
                item.alpha = 1;
            }
            if (ClientPrefs.fm && item.targetY != 0)
            {
                item.targetX -= Std.int(Math.abs(item.targetY) * 10);
            }
        }

        Paths.currentModDirectory = songs[curSelected].folder;
        PlayState.storyWeek = songs[curSelected].week;

        CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
        var diffStr:String = WeekData.getCurrentWeek().difficulties;
        if (diffStr != null)
            diffStr = diffStr.trim();

        if (diffStr != null && diffStr.length > 0)
        {
            var diffs:Array<String> = diffStr.split(',');
            var i:Int = diffs.length - 1;
            while (i > 0)
            {
                if (diffs[i] != null)
                {
                    diffs[i] = diffs[i].trim();
                    if (diffs[i].length < 1)
                        diffs.remove(diffs[i]);
                }
                --i;
            }

            if (diffs.length > 0 && diffs[0].length > 0)
            {
                CoolUtil.difficulties = diffs;
            }
        }

        if (CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
        {
            curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
        }
        else
        {
            curDifficulty = 0;
        }

        var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
        if (newPos > -1)
        {
            curDifficulty = newPos;
        }
    }

    private function positionHighscore()
    {
        scoreText.x = FlxG.width - scoreText.width - 6;

        scoreBG.scale.x = FlxG.width - scoreText.x + 6;
        scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
        diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
        diffText.x -= diffText.width / 2;
    }
}

class SongMetadata
{
    public var songName:String = "";
    public var week:Int = 0;
    public var songCharacter:String = "";
    public var color:Int = -7179779;
    public var folder:String = "";

    public function new(song:String, week:Int, songCharacter:String, color:Int)
    {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.folder = Paths.currentModDirectory;
        if (this.folder == null)
            this.folder = '';
    }
}
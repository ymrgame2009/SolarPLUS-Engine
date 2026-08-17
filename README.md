# Solar+ Engine
Its a Solar Engine Fork

# V0.0.4:

- Hold Cover now work like Note Splash, i mean : name anim + color, or name anim only

*examples:*

**w/ Color**:

```txt
holdCover red0000
holdCoverEnd red0000
hold red0000
end red0000
```
*or*

**w/ out Color**:

```txt
holdCover0000
holdCoverEnd0000
hold0000
end0000
```

- Fix Quant-Based 🗣🔥 doesn't work when bpm changed in mid song
- Add Speech Bubble Dark (Dialogue) its work when Dark mode is on
<img width="1837" height="1033" alt="image" src="https://github.com/user-attachments/assets/33f698ec-76c8-45d9-8606-9e9175c81ff3" />

# V0.0.3:

- Add 2 checkboxes to the Note Splash Debug & Hold Cover Debug to Allow RGB or Pixel.
- Add a SCALE 🗣🔥 to the Note Splash Debug & Hold Cover Debug 

*examples:*

1- noteSplashes.txt:
```txt
note splash
22 26
0 0
0 0
0 0
0 0
0 0
0 0
0 0
0 0
1 <--- Scale
true <--- Allow RGB
true <--- Allow Pixel
```
2- holdCover.txt
```txt
hold
end
24 24
110 100
110 100
110 100
110 100
110 100
110 100
110 100
110 100
1 <--- Scale
true <--- Allow RGB
true <--- Allow Pixel
```
- Change UI Style in Note Splash Debug & Hold Cover Debug
<img width="1837" height="1032" alt="Note Splash Debug" src="https://github.com/user-attachments/assets/b6420d3f-beb8-409d-aa99-22412d0d3454" />
<img width="1832" height="1030" alt="Hold Cover Debug" src="https://github.com/user-attachments/assets/48c44e0e-a5d1-4114-9858-6caa66044863" />

- Add Note Color Style ['Normal', 'Quant-Based', 'Grayscale'] *Default : Normal*

# V0.0.2 - HOTFIX:

- Fix Hold Cover disappears and doesn't come back until the next note in Paused the game

# V0.0.2:

- Hold Cover Debug is now supported
- Add new `holdCoverInputText` in Chart Editor *Default : `holdCover/holdCover`*
- Add Jack Amount in Gameplay Changers
- Fix Version 0.6.1 to 0.0.2 *uhh idk why im forget about that Xd*

# V0.0.1:
- Note Splash Debug is now supported
- Add New MusicPlayer in FreePlay
- Fix Note Splash Order with out my script
- Add new option: Note Splash Opacity
- Remove option: Note Splashes *DON'T ASK*
- Add New HoldCover Support RGB + Pixel
- Add BotPlay in Chart Editor PlayState (Press 6 to Enable BotPlay)
- Add Note Splashes + HoldCover in Chart Editor PlayState
- Fix Note Color in Pixel Stages
- Fix Pixel Note RGB doesn't off in Strums `"disableNoteRGB": true,`

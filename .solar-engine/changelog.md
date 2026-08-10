# Enable (noteSplashes) in UE 0.5.5 + RGB + Pixel SUPPORT :

# V5:

- We made it recognize **Pixel Stage** more effectively.

- We prevented the pixel from working in all **stages**.

- It now uses:

```lua
noteSplashes-pixel

noteSplashes-nRGB-pixel

```
only within **Pixel Stage**.

- We set `antialiasing = false` within **Pixel Stage**.

- We **fixed** RGB so it copies the notes from the string and doesn't break.

**In short**:

Not Splash = Pixel image + RGB adjusted + Works only in Pixel Stage.

# Better Hold Cover FOR SOLAR ENGINE + RGB + Pixel SUPPORT:

# V6:

- We implemented the same robust **Pixel Stage** detection.

- We added a list of **pixel stage** names as a backup.

- Within **Pixel Stage**, it now forcibly turns off smoothing:

```lua
antialiasing = false
bitmap.smoothing = false

```
- We **fixed** RGB in the same way as **Note Splash**.

- `holdCoverPixelRGB` only works in **Pixel Stage** and with **RGB**.

**In short:**

Hold Cover = Pixel Stage detection adjusted + Fixed pixelation + RGB adjusted.
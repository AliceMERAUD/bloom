# Puzzle assets

Place optional graphics here. The app falls back to painted avatars/scenes if files are missing.

## Expected layout

```text
assets/puzzle/
  characters/
    {assetKey}_normal.png
    {assetKey}_walking.png
    {assetKey}_sitting.png
  scenes/
    {scenario}.png          # optional full backdrop
  tiles/
    floor_{scenario}.png
    seat_{scenario}.png
```

Examples:
- `characters/alice_sitting.png`
- `scenes/bus.png`

When PNGs are ready:
1. Add files under the folders above.
2. Declare `assets/puzzle/characters/`, `scenes/`, `tiles/` in `pubspec.yaml`.
3. Set `PuzzleAssetResolver.spritesEnabled = true`.

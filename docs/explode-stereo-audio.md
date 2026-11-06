# Explode Stereo Audio

[English](explode-stereo-audio.md) | [Русский](explode-stereo-audio_RU.md)

Author: **Andrey Novikov**. Version **1.0.1**. Requires **REAPER 7.46+**. No extensions required.

Splits selected stereo items into physically separate mono audio files. The left and right channels are extracted independently, without summing L+R or merely switching Take channel mode.

## Result

Each source track becomes a folder containing **one shared pair** of child tracks for all processed items on that track:

```text
Vocals                ← existing track, now a folder
  Vocals - L          ← left channels of all selected files, panned 100% left
  Vocals - R          ← right channels of all selected files, panned 100% right
```

If the source track is unnamed, its folder stays unnamed and its children are named `L` and `R`. Source filenames are not used to name tracks.

Each resulting L/R item pair receives a separate item group. Different fragments are not combined into one group. The script enables item grouping if it is disabled. This global REAPER option remains enabled after Undo.

Items retain their timeline positions and lengths. Mute and item lock states are copied. The new child tracks use a 0 dB pan law. The source track's volume, pan, automation, track FX and sends remain on the folder. Existing child tracks of a folder are preserved.

Processed stereo items are removed **from the project** only after all mono sources have been created successfully. Original files on disk are retained. One Undo restores the project edit. Generated files remain on disk so Redo can use them.

## Usage

- Select stereo items on one or more tracks and run `Explode Stereo Audio (Andrey Novikov)`.
- If no items are selected, the script processes stereo items on selected tracks. Selected items take priority over selected tracks.
- Multiple files on the same source track use one shared L/R pair. Each other source track receives its own pair.
- Stop playback and recording before running the script.

For Melodyne/ARA, add Melodyne to the resulting L and R tracks. Track plug-ins on the source track remain on the folder and are not automatically moved to its children. Operation with a particular Melodyne version has not been tested separately; the independence of the mono source files has been verified.

## Audio files and limitations

The script uses REAPER's native channel extraction. New files are **32-bit float mono WAV at the source sample rate**, written to the media directory chosen by REAPER for the project. Project format settings are temporarily set for extraction and restored afterward, including on failure. Sources with greater precision than 32-bit float are limited to the output format's precision.

Supported items have a file-based stereo source, **one take**, and **Channel mode: Normal**, on tracks without fixed/free item lanes.

Items with Take FX are also processed. Take FX do not contribute to the new audio files. Their chains are copied to both resulting mono takes **in bypass**, preserving plug-in settings. Re-enable the required plug-ins manually to use them again. ARA plug-ins may require a fresh analysis of the mono source; migration of an existing Melodyne analysis has not been tested separately.

Mono, MIDI, multichannel sources and other unsupported items stay in place. A message reports skipped items.

Unprocessed or unselected items remain on the source track, which becomes a folder. If extraction is cancelled or a validation check fails, the project changes are rolled back. Files already generated during the attempt are retained on disk.

## Installation through ReaPack

If `ReaScripts by Andrey Novikov` is already connected:

1. Open **Extensions → ReaPack → Synchronize packages**.
2. Open **Extensions → ReaPack → Browse packages** and search for `Explode Stereo Audio`.
3. Mark the package for installation and click **Apply**. New packages normally require installation once; subsequent versions are offered through synchronization.

Repository URL:

```text
https://raw.githubusercontent.com/andreynovikov86-cmd/ReaScripts/main/index.xml
```

Manual installation: open **Actions → Show action list → New action → Load ReaScript** and choose the Lua file.

## Validation

Tested in an isolated REAPER 7.84/macOS-arm64 instance using a synthetic stereo file, without modifying the user's project:

- Multiple items on one track: shared L/R tracks, separate pair groups, preserved positions, lengths, fades, Mute and lock states.
- Multiple selected tracks, unnamed tracks, partial item selection and overlapping items with identical start positions.
- Existing source folders, existing child tracks and nested folder closures.
- Modified playback rate and source start offset.
- Preserved track ReaEQ; Take FX chains containing JS Volume Adjustment and ReaEQ copied to both sides in bypass, with parameters retained and processing excluded from the generated files.
- Item grouping enabled when necessary; one Undo/Redo for the project edit.
- Failure on the first extraction and after a completed pair: original items restored.
- Recording, copy/FX and render format settings restored.
- 22 separate 32-bit float mono WAV files at 48 kHz. Six channel comparisons, including items with active source Take FX, matched the corresponding trimmed raw source samples exactly, with maximum error 0 and no L+R summing.

Version 1.0.1 corrects the name to `Explode Stereo Audio (Andrey Novikov)`. After the action file is renamed, an existing shortcut may need to be assigned to the new action once.

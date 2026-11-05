[English](README.md) | [Русский](README_RU.md)

# ReaScripts

REAPER Lua scripts by **Andrey Novikov**.

## 1. Render Take FX and Bypass Originals FX

[Download script](Andrey%20Novikov_Render%20Take%20FX%20and%20Bypass%20Originals%20FX.lua)

<details>
<summary>Description, installation and validation</summary>

A standalone Lua action for REAPER. It renders selected items to new audio takes with their active Take FX processing applied, then bypasses FX on the original takes. Original takes and plug-ins remain available.

- Mono audio takes render to mono; stereo audio takes render to stereo.
- Take channel modes Mono (downmix), Mono (left), and Mono (right) render to mono.
- MIDI takes and multichannel audio default to stereo output.
- Track FX are temporarily bypassed during rendering and then restored to their previous state, so their processing is excluded from the rendered audio.
- Item selection is restored. The edit uses one Undo step.
- No SWS, ReaPack, or other extensions required.

### Installation

Download `Andrey Novikov_Render Take FX and Bypass Originals FX.lua`. In REAPER, open **Actions → Show action list → New action → Load ReaScript** and select the downloaded file. Assign a shortcut if desired.

Select one or more items and run the action. The new rendered takes become active. To use an original take again, select it and re-enable its Take FX.

If a render is cancelled or fails, track FX states are restored and original Take FX are left unchanged. Any takes already rendered can be removed with Undo.

### Validation

Lua syntax and mocked REAPER API tests passed for mixed mono/stereo selections, mono channel mode, original Take FX bypass, track FX restoration, render cancellation, empty selection, and cleanup. Native audio rendering inside REAPER has not yet been verified.

</details>

## 2. Open Melodyne

[Download script](Andrey%20Novikov_Open%20Melodyne.lua)

<details>
<summary>Description and installation</summary>

Ensures an active Melodyne instance exists on every selected target, then opens only one floating Melodyne window for the whole selection.

- Selected items take priority: the action processes their active takes.
- If no items are selected, it processes selected tracks.
- Bypassed and offline instances are skipped and left unchanged.
- Searches inside FX containers, skipping bypassed and offline containers.
- Reuses an already open active Melodyne window among the selected targets; otherwise opens the first available instance.
- Closes other active Melodyne interfaces on the selected targets, including extra instances on the same target. Plug-ins remain loaded and processing.
- Windows outside the selection are left unchanged.

### Installation

Download the Lua file. In REAPER, open **Actions → Show action list → New action → Load ReaScript** and select the file. Assign a shortcut if desired.

Requires **REAPER 7.06+** and an installed Melodyne plug-in available in the FX Browser. No extensions required.

### Validation

Lua syntax and 12 mocked REAPER API scenarios passed: multiple tracks, repeated invocation, existing windows, duplicate instances, take priority, bypass/offline, containers, partial/total insertion failure, empty selection, and FX chain windows. Operation inside REAPER has not yet been verified.

</details>

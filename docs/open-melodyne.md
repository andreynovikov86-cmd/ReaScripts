# Open Melodyne

**By Andrey Novikov** · [All scripts](../README.md)

[**↓ Download script**](https://raw.githubusercontent.com/andreynovikov86-cmd/ReaScripts/main/Andrey%20Novikov_Open%20Melodyne.lua) · [Install with ReaPack](../README.md#install--update-via-reapack)

![Open Melodyne](../docs/cards/open-melodyne.svg)

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

-- @description Render Take FX and Bypass Originals FX
-- @author Andrey Novikov
-- @version 1.2
-- @about
--   By Andrey Novikov. Copyright (c) 2026 Andrey Novikov.
--   Render selected items to new takes with their Take FX baked in, then bypass
--   FX on the original active takes. Mono stays mono; stereo stays stereo.
--   Track FX states and item selection are restored. No extensions required.
-- No extensions required. One Undo restores the edit.
-- Track FX are temporarily bypassed for the native render, then restored.
-- Only FX on the original active takes are permanently bypassed.

local r = reaper
local TITLE = "Render Take FX and Bypass Originals FX — Andrey Novikov"
local project = r.EnumProjects(-1, "")

local function channels_for(take)
  if r.TakeIsMIDI(take) then return 2 end
  local channels = r.GetMediaSourceNumChannels(r.GetMediaItemTake_Source(take))
  local mode = r.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
  if channels == 1 or (mode >= 2 and mode <= 4) then return 1 end
  return 2
end

local count = r.CountSelectedMediaItems(project)
if count == 0 then
  r.defer(function() end)
  return
end

local items, tracks = {}, {}
for i = 0, count - 1 do
  local item = r.GetSelectedMediaItem(project, i)
  local take = r.GetActiveTake(item)
  if not take then
    r.ShowMessageBox("В выделении есть пустой айтем без активного тейка.\n"
      .. "Уберите его из выделения и запустите скрипт снова.", TITLE, 0)
    return
  end
  local fx = {}
  for index = 0, r.TakeFX_GetCount(take) - 1 do
    fx[#fx + 1] = {index = index, enabled = r.TakeFX_GetEnabled(take, index)}
  end
  items[#items + 1] = {
    item = item, take = take, count = r.CountTakes(item),
    channels = channels_for(take), fx = fx,
  }
  local track = r.GetMediaItemTrack(item)
  tracks[track] = r.GetMediaTrackInfo_Value(track, "I_FXEN")
end

local function select_batch(channels)
  r.SelectAllMediaItems(project, false)
  local selected = 0
  for _, entry in ipairs(items) do
    if not channels or entry.channels == channels then
      if r.ValidatePtr2(project, entry.item, "MediaItem*") then
        r.SetMediaItemSelected(entry.item, true)
        selected = selected + 1
      end
    end
  end
  return selected
end

local function validate_render(entry)
  if not r.ValidatePtr2(project, entry.item, "MediaItem*") then
    error("Не удалось найти исходный айтем после рендера.", 0)
  end
  local take = r.GetActiveTake(entry.item)
  if r.CountTakes(entry.item) <= entry.count or not take
      or take == entry.take or r.TakeIsMIDI(take) then
    error("Рендер отменён или новый аудиотейк не создан.", 0)
  end
  local channels = r.GetMediaSourceNumChannels(r.GetMediaItemTake_Source(take))
  if channels ~= entry.channels then
    error("Новый тейк не соответствует исходному формату моно/стерео.", 0)
  end
  -- Native Apply FX produces a clean take. Never keep live FX on top of
  -- the baked audio if a REAPER version happens to copy the chain.
  for index = 0, r.TakeFX_GetCount(take) - 1 do
    r.TakeFX_SetEnabled(take, index, false)
  end
end

local bypass_started = false
r.Undo_BeginBlock2(project)
r.PreventUIRefresh(1)
local ok, err = xpcall(function()
  -- Apply track/take FX supports explicit mono/stereo output. Exclude track
  -- processing for both passes so only Take FX are printed into the files.
  for track in pairs(tracks) do
    if not r.SetMediaTrackInfo_Value(track, "I_FXEN", 0) then
      error("Не удалось временно отключить трековую обработку для рендера.", 0)
    end
  end

  for _, channels in ipairs({1, 2}) do
    if select_batch(channels) > 0 then
      r.Main_OnCommandEx(channels == 1 and 40361 or 40209, 0, project)
      for _, entry in ipairs(items) do
        if entry.channels == channels then validate_render(entry) end
      end
    end
  end

  -- Disable original chains only after EVERY selected item has rendered.
  bypass_started = true
  for _, entry in ipairs(items) do
    for _, fx in ipairs(entry.fx) do
      r.TakeFX_SetEnabled(entry.take, fx.index, false)
    end
  end
end, debug.traceback)

-- Always restore the track chains, including after cancellation or failure.
for track, enabled in pairs(tracks) do
  if r.ValidatePtr2(project, track, "MediaTrack*") then
    r.SetMediaTrackInfo_Value(track, "I_FXEN", enabled)
  end
end
if not ok and bypass_started then
  for _, entry in ipairs(items) do
    if r.ValidatePtr2(project, entry.take, "MediaItem_Take*") then
      for _, fx in ipairs(entry.fx) do
        r.TakeFX_SetEnabled(entry.take, fx.index, fx.enabled)
      end
    end
  end
end
select_batch(nil)
r.PreventUIRefresh(-1)
r.Undo_EndBlock2(project, TITLE, -1)
r.UpdateArrange()

if not ok then
  r.ShowMessageBox(tostring(err) .. "\n\nFX исходных тейков не отключены."
    .. "\nЕсли часть новых тейков уже создана, отмените действие через Undo.", TITLE, 0)
end

-- @description Open Melodyne (Andrey Novikov)
-- @author Andrey Novikov
-- @version 1.1.0
-- @changelog
--   Keep only one Melodyne window open across selected tracks or takes.
--   Publish as a ReaPack package with author branding.
-- @about
--   By Andrey Novikov. REAPER 7.06+ and Melodyne required.
--   Prepare Melodyne on every selected track or active take, but open one window.
--   Bypassed and offline instances are skipped.
-- Open active Melodyne, or insert a new instance.
-- Prepare every selected target, but show only one Melodyne window.
-- Selected item takes take priority over selected tracks.
-- REAPER 7.06+; no extensions required.
local r = reaper
local targets = {}
if r.CountSelectedMediaItems(0) > 0 then
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local take = r.GetActiveTake(r.GetSelectedMediaItem(0, i))
    if take then targets[#targets + 1] = {obj = take, prefix = 'TakeFX_'} end
  end
else
  for i = 0, r.CountSelectedTracks2(0, true) - 1 do
    targets[#targets + 1] = {obj = r.GetSelectedTrack2(0, i, true), prefix = 'TrackFX_'}
  end
end

local function find(t)
  local matches = {}
  local function scan(fx)
    if not r[t.prefix .. 'GetEnabled'](t.obj, fx)
      or r[t.prefix .. 'GetOffline'](t.obj, fx) then return end
    local ok, name = r[t.prefix .. 'GetNamedConfigParm'](t.obj, fx, 'fx_name')
    if not ok or name == '' then
      local named
      named, name = r[t.prefix .. 'GetFXName'](t.obj, fx, '')
    end
    if name:lower():find('melodyne', 1, true) then
      matches[#matches + 1] = {target = t, fx = fx}
    end
    local has, count = r[t.prefix .. 'GetNamedConfigParm'](t.obj, fx, 'container_count')
    if has then
      for j = 0, (tonumber(count) or 0) - 1 do
        local valid, child = r[t.prefix .. 'GetNamedConfigParm'](t.obj, fx, 'container_item.' .. j)
        if valid and tonumber(child) then
          scan(tonumber(child))
        end
      end
    end
  end
  for fx = 0, r[t.prefix .. 'GetCount'](t.obj) - 1 do
    scan(fx)
  end
  return matches
end

if #targets == 0 then
  r.MB('Выделите трек или аудиоайтем с активным тейком.', 'Melodyne', 0)
  return
end
local failures = 0
local instances = {}
local window
r.Undo_BeginBlock()
for _, t in ipairs(targets) do
  local matches = find(t)
  if #matches == 0 then
    local fx
    if t.prefix == 'TakeFX_' then
      fx = r.TakeFX_AddByName(t.obj, 'Melodyne', -1)
    else
      fx = r.TrackFX_AddByName(t.obj, 'Melodyne', false, -1)
    end
    if fx and fx >= 0 then
      -- Hide any window automatically opened by REAPER on insertion.
      r[t.prefix .. 'Show'](t.obj, fx, 2)
      if r[t.prefix .. 'GetChainVisible'](t.obj) == fx then
        r[t.prefix .. 'Show'](t.obj, fx, 0)
      end
      matches[1] = {target = t, fx = fx}
    else
      failures = failures + 1
    end
  end
  for _, instance in ipairs(matches) do
    instances[#instances + 1] = instance
    -- Prefer a window the user already has open, before opening a new one.
    if not window and r[t.prefix .. 'GetOpen'](t.obj, instance.fx) then
      window = instance
    end
  end
end
window = window or instances[1]
for _, instance in ipairs(instances) do
  local t, fx = instance.target, instance.fx
  if instance ~= window then
    r[t.prefix .. 'Show'](t.obj, fx, 2)
  end
  -- Avoid showing Melodyne in both a chain window and a floating window.
  if r[t.prefix .. 'GetChainVisible'](t.obj) == fx then
    r[t.prefix .. 'Show'](t.obj, fx, 0)
  end
end
if window then
  local t = window.target
  r[t.prefix .. 'Show'](t.obj, window.fx, 3)
end
r.Undo_EndBlock('Open or insert Melodyne', -1)
if failures > 0 then
  r.MB('Не удалось добавить Melodyne. Проверьте, что плагин установлен и доступен в FX Browser.', 'Melodyne', 0)
end

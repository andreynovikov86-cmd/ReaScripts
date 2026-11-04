-- Open active Melodyne, or insert a new instance.
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
  local function scan(fx)
    if not r[t.prefix .. 'GetEnabled'](t.obj, fx)
      or r[t.prefix .. 'GetOffline'](t.obj, fx) then return end
    local ok, name = r[t.prefix .. 'GetNamedConfigParm'](t.obj, fx, 'fx_name')
    if not ok or name == '' then
      _, name = r[t.prefix .. 'GetFXName'](t.obj, fx, '')
    end
    if name:lower():find('melodyne', 1, true) then return fx end
    local has, count = r[t.prefix .. 'GetNamedConfigParm'](t.obj, fx, 'container_count')
    if has then
      for j = 0, (tonumber(count) or 0) - 1 do
        local valid, child = r[t.prefix .. 'GetNamedConfigParm'](t.obj, fx, 'container_item.' .. j)
        if valid and tonumber(child) then
          local found = scan(tonumber(child))
          if found then return found end
        end
      end
    end
  end
  for fx = 0, r[t.prefix .. 'GetCount'](t.obj) - 1 do
    local found = scan(fx)
    if found then return found end
  end
end

if #targets == 0 then
  r.MB('Выделите трек или аудиоайтем с активным тейком.', 'Melodyne', 0)
  return
end
local failures = 0
r.Undo_BeginBlock()
for _, t in ipairs(targets) do
  local fx = find(t)
  if not fx then
    if t.prefix == 'TakeFX_' then
      fx = r.TakeFX_AddByName(t.obj, 'Melodyne', -1)
    else
      fx = r.TrackFX_AddByName(t.obj, 'Melodyne', false, -1)
    end
  end
  if fx and fx >= 0 then
    r[t.prefix .. 'Show'](t.obj, fx, 3)
  else
    failures = failures + 1
  end
end
r.Undo_EndBlock('Open or insert Melodyne', -1)
if failures > 0 then
  r.MB('Не удалось добавить Melodyne. Проверьте, что плагин установлен и доступен в FX Browser.', 'Melodyne', 0)
end

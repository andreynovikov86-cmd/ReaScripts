-- @description Import Tracks From Project RPP
-- @version 0.2.26
-- @link https://github.com/andreynovikov86-cmd/ReaScripts
-- @changelog Move search clear control to the left inside the field; show it disabled when empty. Unchecked drag starts fresh using import options.
-- @author Andrey Novikov
-- @about
--   Source .RPP is read, not opened and not modified.
--   Requires ReaImGui 0.10+ (install via ReaPack).
--   Track grouping (the REAPER grouping matrix / VCA flags) is not imported yet.
--   Folder and send dependencies can be selected automatically and overridden manually.
--   Please test on a COPY of your destination project first.

local r = reaper

local language = r and r.GetExtState and r.GetExtState('RPPTrackImport','Language') or 'ru'
if language ~= 'en' then language = 'ru' end
local english = {
  ["Нужен ReaImGui 0.10 или новее. Установите через ReaPack."]="ReaImGui 0.10 or newer is required. Install it via ReaPack.",
  ["Импорт дорожек"]="Import tracks",
  ["Не удалось загрузить ReaImGui 0.10. Проверьте установку расширения."]="Could not load ReaImGui 0.10. Check the extension installation.",
  ["Имя файла содержит все три вида кавычек: "]="The filename contains all three quote types: ",
  ["Не удалось открыть файл проекта: "]="Could not open the project file: ",
  ["(без названия)"]="(unnamed)",
  ["Файл проекта .RPP повреждён или имеет неподдерживаемую структуру."]="The .RPP project file is damaged or uses an unsupported structure.",
  ["Ошибка чтения "]="Could not read ",
  ["Ошибка создания "]="Could not create ",
  ["Не удалось прочитать размер файла: "]="Could not read the file size: ",
  ["Ошибка записи"]="Write error",
  ["Ошибка копирования "]="Could not copy ",
  ["Не удалось установить исходный темп"]="Could not set the source tempo",
  ["Не удалось добавить точку темпа на "]="Could not add a tempo point at ",
  ["Не открыть медиа: "]="Could not open media: ",
  ["Сначала отметьте дорожки для импорта."]="Select tracks to import first.",
  ["Нет открытого проекта REAPER."]="No REAPER project is open.",
  ["Для копирования медиа сначала сохраните текущий проект .RPP"]="To copy media, save the current .RPP project first",
  ["Импорт карты темпа заменит текущие маркеры темпа/размера и может изменить положение существующих MIDI/аудио элементов. Продолжить?"]="Importing the tempo map will replace the current tempo/time signature markers and may move existing MIDI/audio items. Continue?",
  ["Замена карты темпа"]="Replace tempo map",
  ["Импорт отменён."]="Import cancelled.",
  ["Подготовка дорожек"]="Preparing tracks",
  ["Не найдено %d медиафайлов.\nПример: %s\n\nИмпортировать дорожки с отсутствующими файлами?"]="%d media files were not found.\nExample: %s\n\nImport tracks with missing files?",
  ["Отсутствующие медиафайлы"]="Missing media files",
  ["Копирование аудио: %d из %d"]="Copying audio: %d of %d",
  ["Вставка дорожек и загрузка эффектов"]="Inserting tracks and loading effects",
  ["Дорожек: %d. Пожалуйста, подождите…"]="Tracks: %d. Please wait…",
  ["Активный проект изменился. Импорт отменён."]="The active project changed. Import cancelled.",
  ["Список дорожек изменился. Повторите импорт."]="The track list changed. Please import again.",
  ["Не удалось создать дорожку "]="Could not create track ",
  ["REAPER не принял состояние дорожки: "]="REAPER rejected the track state: ",
  ["Не весь импорт завершён. Используйте Cmd+Z для отката.\n"]="Import did not finish. Use Cmd+Z to undo.\n",
  ["Импортировано дорожек: %d. Посылов пропущено: %d. Медиафайлов скопировано: %d."]="Tracks imported: %d. Sends skipped: %d. Media files copied: %d.",
  ["Подготовка импорта"]="Preparing import",
  ["Ошибка: "]="Error: ",
  ["Проект не сохранён"]="Project not saved",
  ["Перетаскивание отменено (Esc)."]="Drag cancelled (Esc).",
  ["В конец проекта"]="End of project",
  ["Дорожка "]="Track ",
  ["После: "]="After: ",
  ["Перед: "]="Before: ",
  ["В начало проекта"]="Start of project",
  ["Импорт %d дорожек: подготовка..."]="Preparing to import %d tracks...",
  ["Перенос отменён: область сброса не распознана. Попробуйте отпустить мышь в пустой части аранжировки."]="Drag cancelled: the drop area was not detected. Try releasing the mouse in an empty part of the arrange view.",
  ["авто"]="auto",
  ["Для перетаскивания в REAPER требуется js_ReaScriptAPI (ReaPack)"]="Dragging into REAPER requires js_ReaScriptAPI (ReaPack)",
  ["Дорожка: "]="Track: ",
  ["Посыл → "]="Send → ",
  ["Приём ← "]="Receive ← ",
  ["Выберите исходный проект REAPER"]="Choose the source REAPER project",
  ["АВТОМАТИЧЕСКИЙ ВЫБОР СВЯЗАННЫХ ДОРОЖЕК"]="AUTOMATIC TRACK SELECTION",
  ["Импортировать дорожки посылов"]="Include send destinations",
  ["Импортировать исходные папки дорожек"]="Include original parent folders",
  ["СОДЕРЖИМОЕ ИМПОРТА"]="IMPORT CONTENT",
  ["Аудио и MIDI"]="Audio and MIDI",
  ["Автоматизация"]="Automation",
  ["Копировать медиа в папку проекта"]="Copy media into the project folder",
  ["Дополнительно создать общую папку"]="Create an additional enclosing folder",
  ["Заменить карту темпа/размера исходной (осторожно)"]="Replace the tempo/time signature map (caution)",
  ["Импортировать выбранные дорожки"]="Import selected tracks",
  ["Сначала выберите исходный проект .RPP."]="Choose the source .RPP project first.",
  ["Формирование волн: осталось файлов %d"]="Building waveforms: %d files remaining",
  ["Ошибка волновых форм: "]="Waveform error: ",
  ["Для переноса мышью установите js_ReaScriptAPI через ReaPack."]="Install js_ReaScriptAPI via ReaPack to drag tracks into REAPER.",
  ["Закрыть (Esc)"]="Close (Esc)",
  ["ИМПОРТ ДОРОЖЕК ИЗ ДРУГОГО ПРОЕКТА"]="IMPORT TRACKS FROM ANOTHER PROJECT",
  ["Выбрать проект .RPP"]="Choose .RPP project",
  ["После выбора проекта здесь появится список дорожек."]="Tracks will appear here after you choose a project.",
  ["ДОРОЖКИ ДЛЯ ИМПОРТА"]="TRACKS TO IMPORT",
  ["Выбрать все"]="Select all",
  ["Снять выделение"]="Clear selection",
  ["Поиск дорожек..."]="Search tracks...",
  ["Очистить поиск"]="Clear search",
  ["дорожка"]="track",
  ["дорожек"]="tracks",
  ["Переместите в REAPER"]="Drag into REAPER",
  ["Импорт дорожек — выполняется"]="Importing tracks",
  ["Продолжить"]="Continue",
  ["Отмена"]="Cancel",
  ["Пожалуйста, подождите…"]="Please wait…",
  ["Импорт дорожек###import_notice"]="Import tracks###import_notice",
  ["Понятно"]="OK",
  ["Импорт отменён: активный проект изменился во время переноса."]="Import cancelled: the active project changed during the drag.",
}
local function T(text)
  return language == 'en' and (english[text] or text) or text
end
local function set_language(value)
  language = value == 'en' and 'en' or 'ru'
  r.SetExtState('RPPTrackImport','Language',language,true)
end
if not r or not r.ImGui_GetBuiltinPath then
  if r then r.MB(T('Нужен ReaImGui 0.10 или новее. Установите через ReaPack.'), T('Импорт дорожек'), 0) end
  return
end

package.path = r.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local okimgui, ImGui = pcall(function() return require('imgui')('0.10') end)
if not okimgui then
  r.MB(T('Не удалось загрузить ReaImGui 0.10. Проверьте установку расширения.'), T('Импорт дорожек'), 0)
  return
end

-- The REAPER action itself owns the shortcut. When its main window has
-- focus, REAPER launches/re-launches the action. When this docked ReaImGui
-- window has focus, keyboard input belongs to ReaImGui: mirror the CURRENT
-- assigned shortcut(s) here, never hard-code F7.
local ctx
local shortcut_chords = {}
local shortcut_last_scan = -math.huge
local function shortcut_from_description(desc)
  if type(desc) ~= 'string' or desc == '' then return nil end
  -- REAPER can prefix Global shortcuts with scope notation.
  desc = desc:gsub('^%s*%([^)]*%)%s*', '')
  -- Only keyboard shortcuts with a known representation are mirrored.
  local chord, key = 0, nil
  local parts = {}
  for part in desc:gmatch('[^+]+') do
    parts[#parts + 1] = part:match('^%s*(.-)%s*$'):lower()
  end
  for _, part in ipairs(parts) do
    if part == 'cmd' or part == 'command' or part == 'super' or part == 'win' then
      chord = chord | ImGui.Mod_Super
    elseif part == 'opt' or part == 'option' or part == 'alt' then
      chord = chord | ImGui.Mod_Alt
    elseif part == 'ctrl' or part == 'control' then
      chord = chord | ImGui.Mod_Ctrl
    elseif part == 'shift' then
      chord = chord | ImGui.Mod_Shift
    elseif not key then
      local lookup = {
        space='Space', esc='Escape', escape='Escape', enter='Enter',
        returnkey='Enter', tab='Tab', backspace='Backspace', delete='Delete',
        home='Home', ['end']='End', pageup='PageUp', pagedown='PageDown',
        up='UpArrow', down='DownArrow', left='LeftArrow', right='RightArrow',
      }
      local candidate = lookup[part] or part:upper()
      if part:match('^f%d%d?$') then candidate = part:upper() end
      key = ImGui['Key_' .. candidate]
      if not key then return nil end
    else
      return nil
    end
  end
  return key and (chord | key) or nil
end

local function refresh_shortcuts(force)
  if not (r.get_action_context and r.SectionFromUniqueID
      and r.CountActionShortcuts and r.GetActionShortcutDesc) then return end
  local now = r.time_precise()
  if not force and now - shortcut_last_scan < 1.0 then return end
  shortcut_last_scan = now
  local _, _, section_id, command_id = r.get_action_context()
  if not command_id or command_id < 0 then return end
  local section = r.SectionFromUniqueID(section_id)
  if not section then return end
  local chords, seen = {}, {}
  local count = r.CountActionShortcuts(section, command_id)
  for index = 0, math.min(count, 40) - 1 do
    local ok, desc = r.GetActionShortcutDesc(section, command_id, index)
    if ok then
      local chord = shortcut_from_description(desc)
      if chord and not seen[chord] then
        chords[#chords + 1] = chord
        seen[chord] = true
      end
    end
  end
  shortcut_chords = chords
end

-- REAPER 7.03+: a repeat of the same shortcut silently terminates this
-- deferred script. Flag 1 suppresses the REAPER task-control dialog;
-- flag 4 marks the action as active in toolbars / Action list.
-- IMPORTANT: Do not add flag 2; it would immediately reopen the window.
if r.set_action_options then r.set_action_options(1 + 4) end

local function basename(path)
  return (path:gsub('\\', '/'):match('([^/]+)$') or path)
end

local function dirname(path)
  return path:gsub('\\', '/'):match('^(.*)/[^/]*$') or ''
end

local function is_absolute(path)
  return path:match('^/') or path:match('^%a:[/\\]') or path:match('^[/\\][/\\]')
end

local function normalize(path)
  path = path:gsub('\\', '/')
  local prefix = ''
  if path:match('^%a:/') then
    prefix, path = path:sub(1, 3), path:sub(4)
  elseif path:sub(1,2) == '//' then
    prefix, path = '//', path:sub(3)
  elseif path:sub(1,1) == '/' then
    prefix, path = '/', path:sub(2)
  end
  local parts = {}
  for s in path:gmatch('[^/]+') do
    if s == '..' and #parts > 0 and parts[#parts] ~= '..' then
      parts[#parts] = nil
    elseif s == '..' and prefix == '' then
      parts[#parts + 1] = '..'
    elseif s ~= '.' and s ~= '' then
      parts[#parts + 1] = s
    end
  end
  return prefix .. table.concat(parts, '/')
end

local function abs_source_file(project_path, file_name)
  if file_name:sub(1,2) == '~/' then
    return normalize((os.getenv('HOME') or '~') .. file_name:sub(2))
  end
  if is_absolute(file_name) then return normalize(file_name) end
  return normalize(dirname(project_path) .. '/' .. file_name)
end

local function rpp_token(text)
  local start = text:find('%S')
  if not start then return nil end
  local q = text:sub(start, start)
  if q == '"' or q == "'" or q == '`' then
    local finish = text:find(q, start + 1, true)
    if not finish then return nil end
    return text:sub(start + 1, finish - 1), text:sub(finish + 1)
  end
  local finish = text:find('%s', start) or (#text + 1)
  return text:sub(start, finish - 1), text:sub(finish)
end

local function rpp_quote(text)
  for _, q in ipairs({'"', "'", '`'}) do
    if not text:find(q, 1, true) then return q .. text .. q end
  end
  error(T('Имя файла содержит все три вида кавычек: ') .. text)
end

local function resolve_source_file(source, path)
  source.file_cache = source.file_cache or {}
  if source.file_cache[path] then return source.file_cache[path] end
  local original = abs_source_file(source.path, path)
  if r.file_exists(original) then source.file_cache[path] = original; return original end
  -- Relocated projects often retain absolute paths into their OLD directory.
  -- Search only predictable locations belonging to this source project.
  -- Do not use unrelated project files or arbitrary disk-wide basename matches.
  local root, name = dirname(source.path), basename(path)
  local candidates, seen, found = {}, {}, {}
  local function add(p) candidates[#candidates+1] = normalize(p) end
  add(root .. '/' .. name)
  for _, dir in ipairs(source.media_paths or {}) do
    if dir ~= '' then add(abs_source_file(source.path, dir) .. '/' .. name) end
  end
  add(root .. '/Media Files/' .. name)
  add(root .. '/Media/' .. name)
  add(root .. '/Audio/' .. name)
  local parent = basename(dirname(path))
  if parent ~= '' then add(root .. '/' .. parent .. '/' .. name) end
  for _, candidate in ipairs(candidates) do
    if not seen[candidate] and r.file_exists(candidate) then
      seen[candidate] = true; found[#found+1] = candidate
    end
  end
  -- An ambiguous basename must be reported, never silently choose other audio.
  if #found == 1 then
    source.file_cache[path] = found[1]
    return found[1]
  end
  return original
end

local function get_track_data(path)
  local f, err = io.open(path, 'rb')
  if not f then error(T('Не удалось открыть файл проекта: ') .. tostring(err)) end
  local tracks, tempo_points, media_paths = {}, {}, {}
  local base_bpm, base_num, base_den = 120, 4, 4
  local depth, reading_track, reading_tempo = 0, nil, false
  local is_rpp = false

  for raw in f:lines() do
    local line = raw:gsub('\r$', '')
    local opens = line:match('^%s*<([%w_]+)')
    local closes = line:match('^%s*>%s*$') ~= nil
    local old_depth = depth

    if old_depth == 0 and opens == 'REAPER_PROJECT' then is_rpp = true end
    if old_depth == 1 then
      local paths = line:match('^%s*RECORD_PATH%s+(.+)')
      if paths then
        local first, rest = rpp_token(paths)
        if first then media_paths[#media_paths+1] = first end
        local second = rest and rpp_token(rest)
        if second then media_paths[#media_paths+1] = second end
      end
    end
    if old_depth == 1 and not reading_track and line:match('^%s*TEMPO%s') then
      local b, n, d = line:match('^%s*TEMPO%s+([%d%.]+)%s+(%d+)%s+(%d+)')
      if b then base_bpm, base_num, base_den = tonumber(b), tonumber(n), tonumber(d) end
    end
    if old_depth == 1 and opens == 'TEMPOENVEX' then
      reading_tempo = true
    elseif reading_tempo and old_depth == 2 and line:match('^%s*PT%s') then
      local values = {}
      for token in line:gmatch('%S+') do values[#values+1] = token end
      local pos, bpm = tonumber(values[2]), tonumber(values[3])
      if pos and bpm then
        local timesig = tonumber(values[5])
        local num, den = 0, 0
        if timesig and timesig > 0 then
          num, den = timesig % 65536, math.floor(timesig / 65536)
        end
        tempo_points[#tempo_points+1] = {
          pos=pos, bpm=bpm, shape=tonumber(values[4]) or 1,
          num=num, den=den
        }
      end
    end

    if old_depth == 1 and opens == 'TRACK' then
      reading_track = { lines = {}, name = T('(без названия)'), fd = 0,
                        index = #tracks, selected = false, manual = nil,
                        parent = nil, level = 0, end_index = nil,
                        native_color = 0, has_audio = false, has_midi = false, has_video = false,
                        source_stack = {},
                        receives = {}, send_targets = {} }
    end

    if reading_track then
      reading_track.lines[#reading_track.lines+1] = line
      if old_depth == 2 then
        -- REAPER projects can store names with double/single/backtick
        -- quotes, or without quotes (NAME Vocal). Handle all four forms.
        local name = line:match('^%s*NAME%s+(.+)%s*$')
        if name then
          name = name:gsub('%s+$', '')
          local q = name:sub(1, 1)
          if q == '"' or q == "'" or q == '`' then
            local close = name:find(q, 2, true)
            if close then name = name:sub(2, close - 1) end
          end
          reading_track.name = name
        end
        local bus_mode, fd = line:match('^%s*ISBUS%s+(-?%d+)%s+(-?%d+)')
        if fd then
          reading_track.fd = tonumber(fd)
          reading_track.is_folder = tonumber(bus_mode) == 1
          -- Usually the second number is +1 on parent tracks. For older
          -- RPP variants where it is 0, still recognize the folder opener.
          if reading_track.is_folder and reading_track.fd == 0 then reading_track.fd = 1 end
        end
        local col = line:match('^%s*PEAKCOL%s+(-?%d+)')
        if col then reading_track.native_color = tonumber(col) or 0 end
        -- AUXRECV lives on the receiving track and references the sender
        -- by its ZERO-based source-project track index.
        local from = line:match('^%s*AUXRECV%s+(-?%d+)')
        if from then reading_track.receives[#reading_track.receives+1] = tonumber(from) + 1 end
      end
      -- Classify each SOURCE when it closes. Video files can be stored
      -- in generic source blocks too, so inspect FILE extensions inside it.
      -- Folder status and own media content are independent properties.
      if opens == 'SOURCE' then
        local kind = line:match('^%s*<SOURCE%s+([%w_]+)') or ''
        reading_track.source_stack[#reading_track.source_stack+1] = {
          kind=kind:upper(), depth=old_depth+1, video=false
        }
      elseif #reading_track.source_stack > 0 then
        local file_name = line:match([=[^%s*FILE%s+["`'](.-)["`']]=])
            or line:match('^%s*FILE%s+(%S+)')
        if file_name then
          local ext = (file_name:gsub('\\', '/'):match('%.([^./]+)$') or ''):lower()
          local video_ext = {
            mov=true, mp4=true, m4v=true, mkv=true, avi=true, webm=true,
            mpg=true, mpeg=true, wmv=true, flv=true, qt=true, gif=true
          }
          if video_ext[ext] then
            reading_track.source_stack[#reading_track.source_stack].video = true
          end
        end
      end
      if closes and #reading_track.source_stack > 0 then
        local node = reading_track.source_stack[#reading_track.source_stack]
        if node.depth == old_depth then
          reading_track.source_stack[#reading_track.source_stack] = nil
          if node.kind == 'MIDI' then
            reading_track.has_midi = true
          elseif node.kind == 'VIDEO' or node.video then
            reading_track.has_video = true
          elseif node.kind ~= 'EMPTY' and node.kind ~= 'SECTION' and node.kind ~= '' then
            reading_track.has_audio = true
          end
        end
      end
    end

    if opens then depth = depth + 1 end
    if closes then depth = depth - 1 end
    if reading_tempo and depth == 1 then reading_tempo = false end
    if reading_track and depth == 1 then
      tracks[#tracks+1] = reading_track
      reading_track = nil
    end
    if depth < 0 then break end
  end
  f:close()
  if not is_rpp or depth ~= 0 then error(T('Файл проекта .RPP повреждён или имеет неподдерживаемую структуру.')) end

  -- Folder ancestry and the full subtree span are derived BEFORE filtering.
  local stack = {}
  for i, tr in ipairs(tracks) do
    tr.parent, tr.level = stack[#stack], #stack
    tr.end_index = i
    if tr.fd > 0 then
      for _ = 1, tr.fd do stack[#stack+1] = i end
    elseif tr.fd < 0 then
      for _ = 1, -tr.fd do
        local parent = table.remove(stack)
        if parent then tracks[parent].end_index = i end
      end
    end
  end
  for _, parent in ipairs(stack) do
    tracks[parent].end_index = #tracks
  end

  -- Reverse receives to the sender -> destination relation. Duplicated
  -- receives (multiple sends) do not produce duplicated selections.
  for dest_i, tr in ipairs(tracks) do
    for _, from_i in ipairs(tr.receives) do
      local sender = tracks[from_i]
      if sender and from_i ~= dest_i then
        sender._send_seen = sender._send_seen or {}
        if not sender._send_seen[dest_i] then
          sender._send_seen[dest_i] = true
          sender.send_targets[#sender.send_targets+1] = dest_i
        end
      end
    end
  end
  for _, tr in ipairs(tracks) do tr._send_seen = nil end
  return {path=path, tracks=tracks, bpm=base_bpm,
          num=base_num, den=base_den, tempo=tempo_points, media_paths=media_paths}
end

-- manual=true: explicitly checked, manual=false: explicitly excluded,
-- manual=nil: can be automatically included. Never make auto-checked
-- parents expand their entire subtree: only EXPLICIT folder clicks do that.
local function recompute_selection(source, opt)
  if not source then return end
  local tracks = source.tracks
  local queue = {}
  for _, tr in ipairs(tracks) do tr.selected = false end
  local function include(i)
    local tr = tracks[i]
    if tr and tr.manual ~= false and not tr.selected then
      tr.selected = true
      queue[#queue+1] = i
    end
  end
  for i, tr in ipairs(tracks) do
    if tr.manual == true then include(i) end
  end
  -- Explicitly selecting a folder includes its entire original subtree.
  for i, tr in ipairs(tracks) do
    if tr.manual == true and tr.fd > 0 then
      for j = i + 1, tr.end_index do include(j) end
    end
  end
  -- Add only first-level send destinations of explicitly chosen tracks,
  -- including children of a manually chosen folder. Avoid recursively
  -- expanding the entire FX-bus graph through auto-selected destinations.
  local chosen_count = #queue
  if opt.auto_sends then
    for q = 1, chosen_count do
      local tr = tracks[queue[q]]
      for _, dest_i in ipairs(tr.send_targets) do include(dest_i) end
    end
  end
  -- Both manually selected tracks and first-level send destinations can
  -- bring their ancestor folders, but AUTO parents never expand siblings.
  if opt.auto_parents then
    local included_count = #queue
    for q = 1, included_count do
      local p = tracks[queue[q]].parent
      while p do
        include(p)
        p = tracks[p].parent
      end
    end
  end
end

local function new_guid()
  return r.genGuid()
end

local function selected_tracks(source, forced_indices)
  local out = {}
  for i, tr in ipairs(source.tracks) do
    if (forced_indices and forced_indices[i]) or (not forced_indices and tr.selected) then
      out[#out+1] = {track=tr, src_i=i}
    end
  end
  return out
end

local function compute_folder_changes(source, selected, opt)
  local depths, result = {}, {}
  if opt.folders then
    local included = {}
    for _, s in ipairs(selected) do included[s.src_i] = true end
    for i, s in ipairs(selected) do
      local n = 0
      local parent = source.tracks[s.src_i].parent
      while parent do
        if included[parent] then n = n + 1 end
        parent = source.tracks[parent].parent
      end
      depths[i] = n
    end
  else
    for i = 1, #selected do depths[i] = 0 end
  end
  for i = 1, #selected do
    result[i] = (depths[i+1] or 0) - depths[i]
  end
  if opt.wrap and #selected > 0 then result[#result] = result[#result] - 1 end
  return result
end

-- Rewrite an existing track chunk, retaining settings/FX while removing
-- option-disabled blocks and replacing receive indices as needed.
local function transform_track(tr, source, target_index, maps, opt, files)
  local out, depth, skip_depth = {}, 0, 0
  local blocks, last_recv_kept = {}, false
  local source_project = source.path
  local skipped_receives = 0

  local function resolve_file(path)
    local from = resolve_source_file(source, path)
    if not r.file_exists(from) then files.missing[from] = true end
    if not opt.copy or not r.file_exists(from) then return from end
    local already = files.remap[from]
    if already then return already end
    local fn = basename(from)
    local stem, ext = fn:match('^(.*)(%.[^%.]+)$')
    stem, ext = stem or fn, ext or ''
    local dest = normalize(files.media_dir .. '/' .. fn)
    local count = 2
    while r.file_exists(dest) or files.reserved[dest] do
      dest = normalize(files.media_dir .. '/' .. stem .. '-import-' .. count .. ext)
      count = count + 1
    end
    files.reserved[dest] = true
    files.remap[from] = dest
    files.copy_jobs[#files.copy_jobs+1] = {src=from,dst=dest}
    return dest
  end

  for _, rawline in ipairs(tr.lines) do
    local line = rawline
    local opens = line:match('^%s*<([%w_]+)')
    local closes = line:match('^%s*>%s*$') ~= nil

    if skip_depth > 0 then
      if opens then skip_depth = skip_depth + 1 end
      if closes then skip_depth = skip_depth - 1 end
    else
      local is_env = opens and opens:find('ENV') ~= nil
      local aux_env = opens and opens:match('^AUX[%w_]*ENV') ~= nil
      if opens == 'ITEM' and not opt.items then
        skip_depth = 1
      elseif is_env and (not opt.automation or (aux_env and not last_recv_kept)) then
        skip_depth = 1
      else
        local keep = true
        if depth == 1 then
          if line:match('^%s*AUXRECV%s') then
            local before, srcidx, rest = line:match('^(%s*AUXRECV%s+)(%-?%d+)(.*)$')
            local mapped = srcidx and maps[tonumber(srcidx)]
            if opt.sends and mapped ~= nil then
              line = before .. mapped .. rest
              last_recv_kept = true
            else
              keep, last_recv_kept = false, false
              skipped_receives = skipped_receives + 1
            end
          elseif line:match('^%s*ISBUS%s') then
            line = '  ISBUS 0 0' -- rebuilt via I_FOLDERDEPTH after import
          elseif line:match('^%s*GROUP_FLAGS') or
                 line:match('^%s*GROUP_HIGH') then
            -- Never attach imported tracks to unrelated existing REAPER groups.
            keep = false
          elseif line:match('^%s*HWOUT%s') then
            -- Hardware outputs are intentionally NOT cloned.
            keep = false
          elseif line:match('^%s*MIDIOUT%s') then
            line = '  MIDIOUT -1'
          end
        end

        local inside_source = false
        for _, name in ipairs(blocks) do
          if name == 'SOURCE' then inside_source = true; break end
        end
        if keep and opt.items and inside_source then
          local prefix, rest = line:match('^(%s*FILE%s+)(.*)$')
          if prefix then
            local filename, suffix = rpp_token(rest)
            if filename then line = prefix .. rpp_quote(resolve_file(filename)) .. suffix end
          end
        end

        if keep then out[#out+1] = line end
        if opens then
          depth = depth + 1
          blocks[#blocks+1] = opens
        elseif closes then
          depth = depth - 1
          if #blocks > 0 then blocks[#blocks] = nil end
        end
      end
    end
  end

  -- Make fresh object identities (track, item, take, FX and envelope IDs).
  -- Keep class identifiers embedded in VST/VST3 plugin header lines intact.
  local guid_keys = {TRACKID=true, GUID=true, IGUID=true, EGUID=true, FXID=true}
  for i, line in ipairs(out) do
    local lead, key, guid, rest = line:match('^(%s*)([%w_]+)%s+({[%x%-]+})(.*)$')
    if key and guid_keys[key] then
      if not files.guid_map[guid] then files.guid_map[guid] = new_guid() end
      out[i] = lead .. key .. ' ' .. files.guid_map[guid] .. rest
    end
  end
  -- Embedded track chunks are indented inside a project; the track-state API
  -- expects the outer <TRACK> at the beginning of its own chunk.
  local outer_indent = out[1] and (out[1]:match('^(%s*)<TRACK') or '') or ''
  if outer_indent ~= '' then
    for i, line in ipairs(out) do
      if line:sub(1, #outer_indent) == outer_indent then
        out[i] = line:sub(#outer_indent + 1)
      end
    end
  end
  return table.concat(out, '\n') .. '\n', skipped_receives
end

local import_job
local function confirm_import(text, title)
  if not import_job then return r.MB(text, title, 4) == 6 end
  local question = {text=text, title=title}
  import_job.question = question
  while question.answer == nil do coroutine.yield() end
  import_job.question = nil
  return question.answer
end

local function progress(text, fraction, detail, paint_before_work)
  if not import_job then return end
  import_job.text, import_job.fraction, import_job.detail = text, fraction, detail
  coroutine.yield()
  if paint_before_work then coroutine.yield() end
end

local function copy_file(from, to, notify)
  local fin, err = io.open(from, 'rb')
  if not fin then error(T('Ошибка чтения ') .. from .. ': ' .. tostring(err)) end
  local fout, outerr = io.open(to, 'wb')
  if not fout then fin:close(); error(T('Ошибка создания ') .. to .. ': ' .. tostring(outerr)) end
  if import_job then import_job.partial = {input=fin, output=fout, path=to} end
  local size = fin:seek('end') or 0
  assert(fin:seek('set', 0), T('Не удалось прочитать размер файла: ') .. from)
  local written, last_yield = 0, r.time_precise()
  local success, copyerr = pcall(function()
    while true do
      local bytes, readerr = fin:read(1024 * 1024)
      if not bytes then
        if readerr then error(readerr) end
        break
      end
      local wrote, werr = fout:write(bytes)
      if not wrote then error(werr or T('Ошибка записи')) end
      written = written + #bytes
      if notify and r.time_precise() - last_yield >= 0.012 then
        notify(size > 0 and written/size or 0)
        last_yield = r.time_precise()
      end
    end
  end)
  local readclosed, readerr = fin:close()
  local closed, closeerr = fout:close()
  if import_job then import_job.partial = nil end
  if not success or not closed or not readclosed then
    os.remove(to)
    error(T('Ошибка копирования ') .. from .. ': ' .. tostring(copyerr or closeerr or readerr))
  end
end

local function apply_tempo(project, source)
  for i = r.CountTempoTimeSigMarkers(project)-1, 0, -1 do
    r.DeleteTempoTimeSigMarker(project, i)
  end
  local points = source.tempo
  local has_zero = false
  for _, pt in ipairs(points) do
    if math.abs(pt.pos) < 0.000001 then has_zero = true; break end
  end
  if not has_zero then
    assert(r.SetTempoTimeSigMarker(project, -1, 0, -1, -1,
      source.bpm, source.num, source.den, false), T('Не удалось установить исходный темп'))
  end
  for _, pt in ipairs(points) do
    local num, den = pt.num, pt.den
    if math.abs(pt.pos) < 0.000001 and (num == 0 or den == 0) then
      num, den = source.num, source.den
    end
    assert(r.SetTempoTimeSigMarker(project, -1, pt.pos, -1, -1,
      pt.bpm, num, den, pt.shape == 0), T('Не удалось добавить точку темпа на ') .. pt.pos)
  end
end

-- Build peak caches for newly copied files without rebuilding unrelated items.
-- Processing is incremental so long media files do not block the window.
local peak_jobs = {}
local peak_refresh = {}
local peak_notice = nil

local function refresh_imported_items(project, tracks)
  if not tracks then return end
  -- A project tab can be closed while peaks are building asynchronously.
  -- Never hand REAPER an invalid closed-project / track pointer.
  local still_open = false
  for i=0,1000 do
    local open_project = r.EnumProjects(i, '')
    if not open_project then break end
    if open_project == project then still_open = true; break end
  end
  if not still_open then return end
  for _, track in ipairs(tracks) do
    if not r.ValidatePtr2 or r.ValidatePtr2(project, track, 'MediaTrack*') then
      for i=0, r.CountTrackMediaItems(track)-1 do
        r.UpdateItemInProject(r.GetTrackMediaItem(track, i))
      end
    end
  end
  r.UpdateArrange()
end

local function queue_peak_build(project, jobs, tracks)
  if #jobs == 0 then return end
  -- Keep imported tracks grouped by destination project, even if the user
  -- switches project tabs before an earlier peak cache has finished.
  peak_refresh[#peak_refresh+1] = {project=project, tracks=tracks}
  for _, job in ipairs(jobs) do
    peak_jobs[#peak_jobs+1] = {path=job.dst, state='new'}
  end
end

local function step_peaks()
  local job = peak_jobs[1]
  if not job then return end
  local ok, err = pcall(function()
    if job.state == 'new' then
      job.src = r.PCM_Source_CreateFromFile(job.path)
      if not job.src then error(T('Не открыть медиа: ') .. job.path) end
      local needed = r.PCM_Source_BuildPeaks(job.src, 0)
      job.state = needed ~= 0 and 'run' or 'done'
    elseif job.state == 'run' then
      local remaining = r.PCM_Source_BuildPeaks(job.src, 1)
      if remaining <= 0 then
        r.PCM_Source_BuildPeaks(job.src, 2)
        job.state = 'done'
      end
    end
  end)
  if not ok then peak_notice = tostring(err); job.state='done' end
  if job.state == 'done' then
    if job.src then pcall(r.PCM_Source_Destroy, job.src) end
    table.remove(peak_jobs, 1)
    if #peak_jobs == 0 then
      for _, batch in ipairs(peak_refresh) do
        refresh_imported_items(batch.project, batch.tracks)
      end
      peak_refresh = {}
    end
  end
end

local function import_tracks(source, opt, forced_indices, insert_at)
  local selected = selected_tracks(source, forced_indices)
  if #selected == 0 then error(T('Сначала отметьте дорожки для импорта.')) end
  local project = r.EnumProjects(-1, '')
  local _, current_file = r.EnumProjects(-1, '')
  if not project then error(T('Нет открытого проекта REAPER.')) end
  if opt.copy and (not current_file or current_file == '') then
    error(T('Для копирования медиа сначала сохраните текущий проект .RPP'), 0)
  end
  if opt.tempo then
    local response = confirm_import(
      T('Импорт карты темпа заменит текущие маркеры темпа/размера и может изменить положение существующих MIDI/аудио элементов. Продолжить?'),
      T('Замена карты темпа'))
    if not response then return T('Импорт отменён.') end
  end

  local count_before = r.CountTracks(project)
  -- 0-based insertion boundary. In particular, NEVER insert a source item
  -- on an existing REAPER track: every imported source gets a NEW track.
  local insert_index = insert_at == nil and count_before
      or math.max(0, math.min(count_before, math.floor(insert_at)))
  local start_index = insert_index + (opt.wrap and 1 or 0)
  local mapping = {}
  for i, s in ipairs(selected) do mapping[s.track.index] = start_index + i - 1 end
  local changes = compute_folder_changes(source, selected, opt)
  local media_dir = opt.copy and normalize(dirname(current_file) .. '/Imported Media') or ''
  local files = {media_dir=media_dir, remap={}, reserved={}, missing={}, copy_jobs={}, guid_map={}}
  local chunks, skipped = {}, 0

  local plan_time = -math.huge
  for i, s in ipairs(selected) do
    if r.time_precise() - plan_time >= 0.012 then
      progress(T('Подготовка дорожек'), (i-1)/#selected, s.track.name)
      plan_time = r.time_precise()
    end
    local chunk, skip_count = transform_track(s.track, source, mapping[s.track.index], mapping, opt, files)
    chunks[i] = chunk
    skipped = skipped + skip_count
  end

  local missing_count, first_missing = 0, nil
  for path in pairs(files.missing) do
    missing_count = missing_count + 1
    first_missing = first_missing or path
  end
  if missing_count > 0 then
    local msg = (T('Не найдено %d медиафайлов.\nПример: %s\n\nИмпортировать дорожки с отсутствующими файлами?'))
      :format(missing_count, tostring(first_missing))
    if not confirm_import(msg, T('Отсутствующие медиафайлы')) then return T('Импорт отменён.') end
  end

  if opt.copy and #files.copy_jobs > 0 then
    -- Existing directories can return 0 on macOS; opening the destination
    -- below verifies actual write access and reports any failure precisely.
    r.RecursiveCreateDirectory(media_dir, 0)
    for i, job in ipairs(files.copy_jobs) do
      local label = (T('Копирование аудио: %d из %d')):format(i, #files.copy_jobs)
      progress(label, (i-1)/#files.copy_jobs, basename(job.src))
      copy_file(job.src, job.dst, function(part)
        progress(label, (i-1+part)/#files.copy_jobs, basename(job.src))
      end)
    end
  end

  progress(T('Вставка дорожек и загрузка эффектов'), nil,
    (T('Дорожек: %d. Пожалуйста, подождите…')):format(#selected), true)
  -- Validate after the deferred copy/prepare stages, before any project edits.
  assert(r.EnumProjects(-1, '') == project, T('Активный проект изменился. Импорт отменён.'))
  assert(r.CountTracks(project) == count_before, T('Список дорожек изменился. Повторите импорт.'))
  local imported = {}
  r.Undo_BeginBlock2(project)
  r.PreventUIRefresh(1)
  local success, err = xpcall(function()
    if opt.tempo then apply_tempo(project, source) end
    local index = insert_index
    local wrapper
    if opt.wrap then
      r.InsertTrackInProject(project, index, 0)
      wrapper = r.GetTrack(project, index)
      r.GetSetMediaTrackInfo_String(wrapper, 'P_NAME', 'Imported: ' .. basename(source.path):gsub('%.%w+$', ''), true)
      index = index + 1
    end
    for _ = 1, #selected do
      r.InsertTrackInProject(project, index, 0)
      index = index + 1
    end
    for i, s in ipairs(selected) do
      local track = r.GetTrack(project, mapping[s.track.index])
      assert(track, T('Не удалось создать дорожку ') .. tostring(i))
      imported[#imported+1] = track
      assert(r.SetTrackStateChunk(track, chunks[i], false),
        T('REAPER не принял состояние дорожки: ') .. s.track.name)
      r.SetMediaTrackInfo_Value(track, 'I_RECARM', 0)
      -- Source group IDs may conflict with unrelated groups in the destination.
      -- Remove parameter/VCA grouping until explicit group remapping is implemented.
      if r.GetSetTrackGroupMembershipEx then
        local flags = {
          'MEDIA_EDIT_LEAD', 'MEDIA_EDIT_FOLLOW',
          'VOLUME_LEAD', 'VOLUME_FOLLOW', 'VOLUME_VCA_LEAD', 'VOLUME_VCA_FOLLOW',
          'PAN_LEAD', 'PAN_FOLLOW', 'WIDTH_LEAD', 'WIDTH_FOLLOW',
          'MUTE_LEAD', 'MUTE_FOLLOW', 'SOLO_LEAD', 'SOLO_FOLLOW',
          'RECARM_LEAD', 'RECARM_FOLLOW', 'POLARITY_LEAD', 'POLARITY_FOLLOW',
          'AUTOMODE_LEAD', 'AUTOMODE_FOLLOW', 'VOLUME_REVERSE', 'PAN_REVERSE',
          'WIDTH_REVERSE', 'NO_LEAD_WHEN_FOLLOW', 'VOLUME_VCA_FOLLOW_ISPREFX'
        }
        for _, flag in ipairs(flags) do
          for offset=0, 96, 32 do
            r.GetSetTrackGroupMembershipEx(track, flag, offset, 0xFFFFFFFF, 0)
          end
        end
      end
      r.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', changes[i])
      if changes[i] > 0 then r.SetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT', 0) end
    end
    if wrapper then
      r.SetMediaTrackInfo_Value(wrapper, 'I_FOLDERDEPTH', 1)
      r.SetMediaTrackInfo_Value(wrapper, 'I_FOLDERCOMPACT', 0)
    end
    for i = 0, r.CountTracks(project)-1 do
      local track = r.GetTrack(project, i)
      r.SetTrackSelected(track, false)
    end
    for _, track in ipairs(imported) do r.SetTrackSelected(track, true) end
  end, debug.traceback)
  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock2(project, 'Import selected tracks from RPP', -1)
  if not success then error(T('Не весь импорт завершён. Используйте Cmd+Z для отката.\n') .. tostring(err)) end
  refresh_imported_items(project, imported)
  if opt.copy and #files.copy_jobs > 0 then
    queue_peak_build(project, files.copy_jobs, imported)
  end
  return (T('Импортировано дорожек: %d. Посылов пропущено: %d. Медиафайлов скопировано: %d.'))
    :format(#selected, skipped, #files.copy_jobs)
end

local source = nil
local window_open = true
local search = ''
local search_focus_pending = false
local opts = {
  items=true, automation=true, tempo=false, folders=true,
  wrap=false, sends=true, copy=false,
  -- Both auto-pick switches are enabled by default, but NO TRACK is
  -- selected until the user explicitly checks at least one.
  auto_parents=true, auto_sends=true,
}
local drag = {active=false, value=false, last=nil, frozen_visible=nil}

-- ReaImGui cannot use a native drag payload in REAPER's TCP/arrange.
-- Track the OS pointer instead. The REAPER track is only a LOCATION marker;
-- its existing items, FX and routing must never be modified by a drop.
local cross_drag = {candidate=nil, active=false, indices=nil,
  start_x=0, start_y=0, target=nil}
local pending_drop = nil
local drag_tooltip_visible = false
local message = '' -- shared with both the drop handler and the settings panel
local notice = nil
local function request_import(src, indices, index, project)
  if import_job then return end
  local options = {}
  for k,v in pairs(opts) do options[k] = v end
  indices = indices or (function()
    local set = {}
    for i,tr in ipairs(src.tracks) do if tr.selected then set[i] = true end end
    return set
  end)()
  src.file_cache = {} -- recheck disk on each import, including missing/relinked media
  import_job = {project=project or r.EnumProjects(-1,''), text=T('Подготовка импорта'),
    detail='', fraction=nil, warmup=2}
  import_job.thread = coroutine.create(function() return import_tracks(src, options, indices, index) end)
end

local function step_import()
  local job = import_job
  if not job then return end
  if job.warmup > 0 then job.warmup = job.warmup - 1; return end
  local ok, result
  if r.EnumProjects(-1, '') ~= job.project then
    ok, result = false, T('Активный проект изменился. Импорт отменён.')
  else
    ok, result = coroutine.resume(job.thread)
  end
  if not ok or coroutine.status(job.thread) == 'dead' then
    if job.partial then
      pcall(function() job.partial.input:close() end)
      pcall(function() job.partial.output:close() end)
      os.remove(job.partial.path)
    end
    import_job = nil
    message = ok and result or (T('Ошибка: ') .. tostring(result))
    if not ok then
      local text = tostring(result):gsub('^[^\n]-:%d+:%s*', '')
      text = text:match('^(.-)\nstack traceback:') or text
      local unsaved = text == T('Для копирования медиа сначала сохраните текущий проект .RPP')
      message = text
      notice = {title=unsaved and T('Проект не сохранён') or T('Импорт дорожек'), text=text}
    end
  end
end
local function global_left_down()
  return r.JS_Mouse_GetState and (r.JS_Mouse_GetState(1) & 1) ~= 0 or false
end

local function clear_drag_tooltip()
  if drag_tooltip_visible and r.TrackCtl_SetToolTip then
    r.TrackCtl_SetToolTip('', 0, 0, true)
  end
  drag_tooltip_visible = false
end

local function show_drag_tooltip(text, x, y)
  if r.TrackCtl_SetToolTip then
    r.TrackCtl_SetToolTip(text, x + 16, y + 18, true)
    drag_tooltip_visible = true
  end
end

-- Escape cancels an in-progress cross-window drag, including when the
-- pointer is over the native REAPER arrange rather than the ReaImGui dock.
-- js_ReaScriptAPI reports 255 virtual keys as a binary string (ESC = 27).
-- Never intercept the key: REAPER should retain its normal keyboard behavior.
local function escape_during_drag(ctx)
  if r.JS_VKeys_GetDown then
    local pressed = r.JS_VKeys_GetDown(-0.13)
    if type(pressed) == 'string' and #pressed >= 27
        and pressed:byte(27) == 1 then return true end
  end
  if ctx and ImGui.IsKeyPressed then
    return ImGui.IsKeyPressed(ctx, ImGui.Key_Escape)
  end
  return false
end

local function cancel_cross_drag()
  clear_drag_tooltip()
  cross_drag.candidate, cross_drag.active = nil, false
  cross_drag.indices, cross_drag.target = nil, nil
  cross_drag.proposed_index, cross_drag.proposed_since = nil, nil
  cross_drag.last_good_x, cross_drag.last_good_y, cross_drag.last_good_time = nil, nil, nil
  cross_drag.cancelled_until_release = true
  message = T('Перетаскивание отменено (Esc).')
end

local function count_drag_tracks(indices)
  local count = 0
  if indices then for _ in pairs(indices) do count = count + 1 end end
  return count
end

-- Snapshot the import set when dragging begins. An already-checked row
-- carries the current checked set; an unchecked row carries just itself
-- plus direct sends and parents enabled in the settings. An unchecked row
-- starts a fresh selection, without exclusions from an earlier checked set.
-- Restore the visible checked set after calculating this temporary payload.
local function drag_selection(src, anchor)
  local chosen = {}
  if src.tracks[anchor].selected then
    for i, tr in ipairs(src.tracks) do
      if tr.selected then chosen[i] = true end
    end
    return chosen
  end
  local previous = {}
  for i, tr in ipairs(src.tracks) do
    previous[i] = tr.manual
    tr.manual = nil
  end
  src.tracks[anchor].manual = true
  recompute_selection(src, opts)
  for i, tr in ipairs(src.tracks) do
    if tr.selected then chosen[i] = true end
  end
  for i, tr in ipairs(src.tracks) do tr.manual = previous[i] end
  recompute_selection(src, opts)
  return chosen
end

-- Use the platform converter on EVERY point. Mouse motion cannot calibrate
-- a monitor transform reliably (stationary/horizontal drags and HiDPI screens).
local function to_imgui(x, y)
  return ImGui.PointConvertNative(ctx, x, y)
end
local function inside_rect(x,y,a,b,c,d)
  return x>=math.min(a,c) and x<math.max(a,c)
     and y>=math.min(b,d) and y<math.max(b,d)
end
local function clamp(v,low,high)
  if high<low then return low end
  return math.min(high,math.max(low,v))
end

-- JS_Window_GetRect returns REAPER NATIVE screen coordinates on macOS.
-- Convert each corner once, rather than guessing which coordinate system
-- the rectangle happens to resemble at a given pointer location.
local function trackview_geometry(mx,my)
  if not (r.JS_Window_FindChildByID and r.JS_Window_GetRect and r.GetMainHwnd) then
    return nil
  end
  local hwnd=r.JS_Window_FindChildByID(r.GetMainHwnd(),1000)
  if not hwnd then return nil end
  local ok,l,t,rr,bb=r.JS_Window_GetRect(hwnd)
  if not (ok and l and t and rr and bb) then return nil end
  local x1,y1=to_imgui(l,t)
  local x2,y2=to_imgui(rr,bb)
  return {left=math.min(x1,x2),top=math.min(y1,y2),
    right=math.max(x1,x2),bottom=math.max(y1,y2),
    inside=inside_rect(mx,my,l,t,rr,bb),hwnd=hwnd}
end

-- I_TCPY is a track's Y position relative to the top of the arrange
-- viewport (REAPER API). Use that FIRST: converting I_TCPSCREENY as if
-- it were a JS_Window native coordinate produced incorrect guides on macOS.
-- Do not clamp an offscreen boundary to the bottom of the viewport: a guide
-- at the wrong place is more misleading than no guide at all.
local function track_screen_top(track, geometry)
  if not track or not geometry then return nil end
  if r.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP') == 0 then return nil end
  local relative = r.GetMediaTrackInfo_Value(track, 'I_TCPY')
  if type(relative) == 'number' and relative > -100000 and relative < 100000 then
    return geometry.top + relative
  end
  return nil
end

-- REAPER track heights are NOT uniform. I_TCPH excludes separate
-- envelope lanes, whereas I_WNDH includes them. Use the per-track values
-- afresh every frame (vertical zoom, folder collapse and track resize can
-- all change these without a project state-change notification).
local function track_visible_heights(track)
  if not track then return 0, 0 end
  local tcp = math.max(0, r.GetMediaTrackInfo_Value(track, 'I_TCPH') or 0)
  local full = math.max(tcp, r.GetMediaTrackInfo_Value(track, 'I_WNDH') or 0)
  return tcp, full
end

-- A following VISIBLE track's top is the most exact insertion boundary:
-- it accounts for varying row heights and displayed envelope lanes, unlike
-- guessing a boundary using the previous track's TCP-only height.
local function following_visible_top(project, index_zero_based, geometry, previous_top)
  for j = index_zero_based + 1, r.CountTracks(project) - 1 do
    local next_track = r.GetTrack(project, j)
    if next_track and r.GetMediaTrackInfo_Value(next_track, 'B_SHOWINTCP') ~= 0 then
      local tcp = track_visible_heights(next_track)
      local top = tcp > 1 and track_screen_top(next_track, geometry) or nil
      if top and (not previous_top or top > previous_top + 1) then
        return top
      end
    end
  end
  return nil
end

local function visible_boundary(y, geometry)
  if not (y and geometry) then return nil end
  if y >= geometry.top and y <= geometry.bottom then
    return y
  end
  return nil
end

-- A mouse drop always INSERTS new tracks. Existing tracks are used only
-- as boundaries. Guide placement comes from the SAME insertion index.
local function drop_target(x,y)
  if not (r.GetThingFromPoint and r.GetMediaTrackInfo_Value) then return nil end
  local project=r.EnumProjects(-1,'')
  if not project then return nil end
  local track,info=r.GetThingFromPoint(x,y)
  local geometry=trackview_geometry(x,y)
  local api_hit=type(info)=='string'
       and (info:match('^arrange')~=nil or info:match('^tcp')~=nil)
  if not api_hit and not (geometry and geometry.inside) then return nil end
  local count=r.CountTracks(project)
  if track and r.ValidatePtr2 and not r.ValidatePtr2(project,track,'MediaTrack*') then
    track=nil
  end
  local _,gy=to_imgui(x,y)
  local out={project=project,geometry=geometry,index=count,label=T('В конец проекта')}
  -- Only show a guide when the insertion boundary is actually visible.
  -- Clamping an offscreen boundary makes the line jump to the window edge.
  local function guide_at(screen_y)
    out.guide_y = visible_boundary(screen_y, geometry)
  end
  if track then
    local n=math.floor(r.GetMediaTrackInfo_Value(track,'IP_TRACKNUMBER') or 0)
    if n>=1 and n<=count then
      local top = track_screen_top(track, geometry)
      local tcp_h, full_h = track_visible_heights(track)
      -- Use this particular row's height, never an average/fixed height.
      local below = top and tcp_h > 1 and gy >= top + tcp_h * 0.5 or false
      out.index = n - 1 + (below and 1 or 0)
      local _, name = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
      name = (name and name ~= '') and name or (T('Дорожка ') .. n)
      out.label = (below and T('После: ') or T('Перед: ')) .. name
      if below then
        for j=n, count-1 do
          local next_track = r.GetTrack(project,j)
          if r.GetMediaTrackInfo_Value(next_track,'B_SHOWINTCP') ~= 0
              and select(1,track_visible_heights(next_track)) > 1 then
            out.index = j; break
          end
          out.index = j + 1
        end
        -- The next visible track is the real lower edge, including any
        -- envelope lanes or nonuniform TCP heights between tracks.
        local next_top = following_visible_top(project, n-1, geometry, top)
        guide_at(next_top or (top and full_h > 0 and top + full_h))
      else
        guide_at(top)
      end
      return out
    end
  end
  -- Empty space is always a valid end-of-project drop.  Find the real
  -- final track's boundary, not the greatest (possibly offscreen) height
  -- measured while looping over tracks.  The last visible track can be
  -- different from the last PROJECT track if the TCP is scrolled.
  if count == 0 then
    out.index,out.label = 0,T('В начало проекта')
    if geometry then guide_at(geometry.top + 7) end
  else
    local first = r.GetTrack(project, 0)
    local first_top = track_screen_top(first, geometry)
    if first_top and geometry and gy < first_top and first_top >= geometry.top then
      out.index,out.label = 0,T('В начало проекта')
      guide_at(first_top)
    else
      out.index,out.label = count,T('В конец проекта')
      local last = r.GetTrack(project, count - 1)
      local last_top = track_screen_top(last, geometry)
      local _, last_full_h = track_visible_heights(last)
      if last_top and last_full_h > 1 then
        guide_at(last_top + last_full_h)
      end
    end
  end
  return out
end

-- The current hit test owns BOTH the insertion index and the line.
-- Delaying index changes leaves the line on the previous track during fast drags.
local function stable_drop_target(d, proposed)
  d.target = proposed
  return proposed
end

-- Called every defer frame, even if the mouse crosses out of the docked
-- ReaImGui child. A click in filtered results still invokes Reveal; a drag
-- has to move at least 9 screen pixels before being eligible for import.
local reveal_in_full_list
local function finish_cross_drag(imgui_ctx)
  local d = cross_drag
  if not d.candidate then return end
  -- This callback is declared BEFORE the local `ctx` is created below.
  -- Always pass the valid context explicitly to avoid using a nil/global ctx.
  local x, y = r.GetMousePosition()
  local held = global_left_down()
  if escape_during_drag(imgui_ctx) then
    cancel_cross_drag()
    return
  end
  -- A mouse movement is required; merely clicking a search result must
  -- continue to navigate to that track without importing anything.
  if not d.active and ((x - d.start_x)^2 + (y - d.start_y)^2) >= 81 then
    d.active = true
    d.indices = drag_selection(source, d.candidate)
  end
  if d.active then
    local proposed = drop_target(x, y)
    -- At release, REAPER/JS may briefly return an empty hit test as focus
    -- moves from the ReaImGui dock to the arrange view.  Use the last valid
    -- target ONLY when the pointer is still essentially at the same place
    -- and the last observation is recent.  Never accept an old target if
    -- the mouse travelled away or the active project changed.
    if proposed then
      d.last_good_x, d.last_good_y = x, y
      d.last_good_time = r.time_precise()
    elseif not held and d.target and d.last_good_x and d.last_good_time then
      local delta2 = (x - d.last_good_x)^2 + (y - d.last_good_y)^2
      local age = r.time_precise() - d.last_good_time
      if delta2 <= 20*20 and age <= 0.35
          and r.EnumProjects(-1, '') == d.target.project then
        proposed = d.target
      end
    end
    -- Use exactly the displayed insertion boundary on release, not an
    -- unrelated position inferred after the mouse button was lifted.
    d.target = stable_drop_target(d, proposed)
    if held then
      -- The floating file-stack ghost is the only drag hint. Avoid the
      -- duplicate native yellow tooltip that can obscure the insertion line.
      clear_drag_tooltip()
    else
      clear_drag_tooltip()
      if d.target and source and d.indices and r.JS_Mouse_GetState then
        pending_drop = {source=source, indices=d.indices,
          index=d.target.index, project=d.target.project, stage=0,
          count=count_drag_tracks(d.indices)}
        message = (T('Импорт %d дорожек: подготовка...')):format(pending_drop.count)
      else
        message = T('Перенос отменён: область сброса не распознана. Попробуйте отпустить мышь в пустой части аранжировки.')
      end
    end
  elseif not held and source and search ~= '' then
    reveal_in_full_list(d.candidate)
  end
  if not held then
    clear_drag_tooltip()
    d.candidate, d.active, d.indices, d.target = nil, false, nil, nil
    d.proposed_index, d.proposed_since = nil, nil
    d.last_good_x, d.last_good_y, d.last_good_time = nil, nil, nil
    d.cancelled_until_release = false
  end
end

-- Navigation from a search match: clicking the ROW (not its checkbox)
-- shows the same track in the complete project tree without changing
-- any import checkbox. The short golden outline fades after two seconds.
local focus_reveal = {index=nil, scroll_pending=false, since=nil}
reveal_in_full_list = function(index)
  if not source or not source.tracks[index] then return end
  search = ''
  drag.active, drag.last, drag.frozen_visible = false, nil, nil
  focus_reveal.index = index
  focus_reveal.scroll_pending = true
  focus_reveal.since = nil
end

ctx = ImGui.CreateContext('Import Tracks From Project RPP')
local bold_font = ImGui.CreateFont('sans-serif', ImGui.FontFlags_Bold)
ImGui.Attach(ctx, bold_font)

-- Dark neutral palette based on REAPER's mixer (screenshot reference).
local colors = {
  {ImGui.Col_WindowBg,       0x222222FF},
  {ImGui.Col_ChildBg,        0x252525FF},
  {ImGui.Col_PopupBg,        0x282828FF},
  {ImGui.Col_Text,           0xE8E8E8FF},
  {ImGui.Col_TextDisabled,   0x919191FF},
  {ImGui.Col_FrameBg,        0x333333FF},
  {ImGui.Col_FrameBgHovered, 0x3D4144FF},
  {ImGui.Col_FrameBgActive,  0x494D50FF},
  {ImGui.Col_CheckMark,      0xE4C46BFF},
  {ImGui.Col_Button,         0x3A3A3AFF},
  {ImGui.Col_ButtonHovered,  0x494949FF},
  {ImGui.Col_ButtonActive,   0x555555FF},
  {ImGui.Col_Header,         0x484848FF},
  {ImGui.Col_HeaderHovered,  0x535353FF},
  {ImGui.Col_Border,         0x464646FF},
  {ImGui.Col_Separator,      0x424242FF},
  {ImGui.Col_HeaderActive,   0x5A5A5AFF},
  {ImGui.Col_TitleBg,        0x292929FF},
  {ImGui.Col_TitleBgActive,  0x343434FF},
  {ImGui.Col_TitleBgCollapsed,0x292929FF},
  {ImGui.Col_TextSelectedBg, 0x8B744B80},
  {ImGui.Col_PlotHistogram,  0xD8A43FFF},
  {ImGui.Col_PlotHistogramHovered,0xEDBB59FF},
  {ImGui.Col_ScrollbarBg,    0x242424FF},
  {ImGui.Col_ScrollbarGrab,  0x515151FF},
  {ImGui.Col_ScrollbarGrabHovered,0x686868FF},
  {ImGui.Col_ScrollbarGrabActive,0x808080FF},
  {ImGui.Col_SliderGrab,     0xD8A43FFF},
  {ImGui.Col_SliderGrabActive,0xEDBB59FF},
  {ImGui.Col_ResizeGrip,     0x77777744},
  {ImGui.Col_ResizeGripHovered,0xAAAAAA88},
  {ImGui.Col_ResizeGripActive,0xD8A43FAA},
  {ImGui.Col_Tab,            0x303030FF},
  {ImGui.Col_TabHovered,     0x4A4A4AFF},
  {ImGui.Col_TabSelected,    0x454545FF},
  {ImGui.Col_TabSelectedOverline,0xD8A43FFF},
  {ImGui.Col_TabDimmed,      0x282828FF},
  {ImGui.Col_TabDimmedSelected,0x383838FF},
  {ImGui.Col_TabDimmedSelectedOverline,0x8B744BFF},
  {ImGui.Col_NavCursor,      0xD8A43FFF},
  {ImGui.Col_NavWindowingHighlight,0xD8A43FB0},
  {ImGui.Col_NavWindowingDimBg,0x15151580},
  -- Modal dimming covers the whole native viewport, including rounded corners.
  {ImGui.Col_ModalWindowDimBg,0x00000000},
  {ImGui.Col_DockingPreview, 0xD8A43F70},
}

local roundings = {
  {ImGui.StyleVar_WindowRounding, 9},
  {ImGui.StyleVar_ChildRounding, 8},
  {ImGui.StyleVar_PopupRounding, 12},
  {ImGui.StyleVar_PopupBorderSize, 0},
  {ImGui.StyleVar_FrameRounding, 6},
  {ImGui.StyleVar_ScrollbarRounding, 6},
  {ImGui.StyleVar_GrabRounding, 5},
  {ImGui.StyleVar_TabRounding, 5},
}
local function push_theme()
  for _, pair in ipairs(colors) do ImGui.PushStyleColor(ctx, pair[1], pair[2]) end
  for _, pair in ipairs(roundings) do ImGui.PushStyleVar(ctx, pair[1], pair[2]) end
end
local function pop_theme()
  ImGui.PopStyleVar(ctx, #roundings)
  ImGui.PopStyleColor(ctx, #colors)
end

local function rgba(r8, g8, b8, a8)
  return (r8 << 24) | (g8 << 16) | (b8 << 8) | (a8 or 255)
end

-- PEAKCOL is read from serialized .RPP text, not from GetTrackColor().
-- For the file format use its stored BBGGRR byte order directly: passing
-- these bits through ColorFromNative() on macOS reverses red and blue.
-- This only affects the preview badge; the import retains the original chunk.
local function native_background(peakcol)
  if not peakcol or (peakcol & 0x1000000) == 0 then
    return 0x383838FF
  end
  local packed = peakcol & 0xFFFFFF
  local rr = packed & 0xFF
  local gg = (packed >> 8) & 0xFF
  local bb = (packed >> 16) & 0xFF
  -- Darken uniformly so white track names remain legible. Keep hue intact.
  rr = math.floor(math.min(190, rr * 0.72) + 0.5)
  gg = math.floor(math.min(190, gg * 0.72) + 0.5)
  bb = math.floor(math.min(190, bb * 0.72) + 0.5)
  return rgba(rr, gg, bb)
end

local function dl_line(dl, x1, y1, x2, y2, color, thickness)
  ImGui.DrawList_AddLine(dl, x1, y1, x2, y2, color, thickness or 1.2)
end

-- Icons occupy a shared, automatically sized column. Their horizontal
-- alignment does not change with the source track's folder nesting.
local ICON_W, ICON_GAP = 14, 3
local function draw_audio_icon(dl, x, y)
  local white = 0xE9E9E9FF
  local heights = {3, 7, 11, 6, 9, 3}
  for i, height in ipairs(heights) do
    local cx = x + 1 + (i-1)*1.8
    dl_line(dl, cx, y+6-height/2, cx, y+6+height/2, white, 1.2)
  end
end

local function draw_midi_icon(dl, x, y)
  local white = 0xE9E9E9FF
  ImGui.DrawList_AddCircleFilled(dl, x+3, y+10, 1.8, white)
  ImGui.DrawList_AddCircleFilled(dl, x+9, y+8, 1.8, white)
  dl_line(dl, x+4.6, y+9.5, x+4.6, y+2.8, white, 1.4)
  dl_line(dl, x+10.6, y+7.5, x+10.6, y+1.5, white, 1.4)
  dl_line(dl, x+4.6, y+2.8, x+10.6, y+1.5, white, 1.4)
end

local function draw_icon(dl, kind, x, y)
  local white = 0xE9E9E9FF
  if kind == 'folder' then
    -- Filled folder with distinct tab: legible at 14x12 px.
    ImGui.DrawList_AddRectFilled(dl, x+1, y+2, x+7, y+5, white, 1)
    ImGui.DrawList_AddRectFilled(dl, x+1, y+4, x+13, y+12, white, 1.6)
    dl_line(dl, x+2.5, y+5.8, x+11.5, y+5.8, 0x808080FF, 0.8)
  elseif kind == 'video' then
    ImGui.DrawList_AddRectFilled(dl, x+1, y+1, x+13, y+12, white, 1.5)
    ImGui.DrawList_AddTriangleFilled(dl,
      x+5, y+3.5, x+5, y+9.5, x+10, y+6.5, 0x292929FF)
  elseif kind == 'audio' then
    draw_audio_icon(dl, x, y)
  elseif kind == 'midi' then
    draw_midi_icon(dl, x, y)
  elseif kind == 'empty' then
    ImGui.DrawList_AddRect(dl, x+1, y+2, x+12, y+11, 0xAAAAAAFF, 1, 0, 1.0)
    dl_line(dl, x+3, y+5, x+10, y+5, white, 0.9)
    dl_line(dl, x+3, y+8, x+8, y+8, white, 0.9)
  end
end

local function track_icons(tr)
  local icons = {}
  if tr.fd > 0 or tr.is_folder then icons[#icons+1] = 'folder' end
  if tr.has_audio then icons[#icons+1] = 'audio' end
  if tr.has_midi then icons[#icons+1] = 'midi' end
  if tr.has_video then icons[#icons+1] = 'video' end
  if #icons == 0 then icons[1] = 'empty' end
  return icons
end

-- Font metrics determine the actual fitted string, not a hard-coded
-- character count. Avoid splitting multibyte Russian UTF-8 characters.
local function measured(text)
  return select(1, ImGui.CalcTextSize(ctx, text))
end

local function fitted(text, width)
  if width <= 0 then return '', text ~= '' end
  if measured(text) <= width then return text, false end
  local dots = '…'
  if measured(dots) > width then return '', true end
  local chars = {}
  local ok = pcall(function()
    for _, codepoint in utf8.codes(text) do
      chars[#chars+1] = utf8.char(codepoint)
    end
  end)
  if not ok then return dots, true end
  local lo, hi, best = 0, #chars, 0
  while lo <= hi do
    local mid = math.floor((lo+hi)/2)
    local candidate = table.concat(chars, '', 1, mid) .. dots
    if measured(candidate) <= width then
      best = mid; lo = mid + 1
    else
      hi = mid - 1
    end
  end
  return table.concat(chars, '', 1, best) .. dots, true
end

-- A direct click on a parent folder is a NEW selection decision for its
-- entire original subtree. Old manual exclusions must be forgotten here:
-- select child -> deselect child -> select parent MUST select child again.
-- Auto-picked parents are NOT expanded automatically.
local function set_manual(source_data, index, desired)
  local tracks = source_data.tracks
  local tr = tracks[index]
  if not tr then return end
  local folder = tr.fd > 0 or tr.is_folder
  local was_manually_selected = tr.manual == true
  tr.manual = desired

  -- A manually excluded parent is skipped by automatic selection. That
  -- exclusion applies until a NEW child is checked: selecting another
  -- child under the same folder must re-enable automatic parent import.
  -- Do not change anything when a child is being UNchecked or when the
  -- automatic-parent option is disabled.
  if desired and opts.auto_parents then
    local p = tr.parent
    while p do
      if tracks[p].manual == false then tracks[p].manual = nil end
      p = tracks[p].parent
    end
  end

  if folder and (desired or was_manually_selected) then
    -- Explicit folder selection is a new decision for the entire subtree.
    -- An auto-picked parent never expands siblings until explicitly checked.
    local last = math.min(#tracks, tr.end_index or index)
    for j = index + 1, last do
      tracks[j].manual = desired
    end
  end

  -- A NEW manual check of a source resets manual exclusions on its DIRECT
  -- send targets. Exclusions stay in force only until that source is picked
  -- again; selecting an unrelated track does not clear them. For a folder,
  -- descendants count as newly chosen sources as well.
  if desired and opts.auto_sends then
    local function restore_direct_sends(from_i)
      for _, dest_i in ipairs(tracks[from_i].send_targets) do
        if tracks[dest_i] and tracks[dest_i].manual == false then
          tracks[dest_i].manual = nil
        end
      end
    end
    restore_direct_sends(index)
    if folder then
      for j = index + 1, math.min(#tracks, tr.end_index or index) do
        restore_direct_sends(j)
      end
    end
  end

  -- When an AUTO-selected parent is excluded, leave the child track's
  -- explicit selection untouched; auto dependencies remain overridable.
  recompute_selection(source_data, opts)
end

local function search_lower(text)
  text = text:gsub('[A-Z]', function(ch) return string.char(ch:byte()+32) end)
  return (text:gsub('[\208\209][\128-\191]', function(ch)
    local code = utf8.codepoint(ch)
    if code >= 0x410 and code <= 0x42F then return utf8.char(code+32) end
    if code == 0x401 then return utf8.char(0x451) end
    return ch
  end))
end

local function search_visible(source_data, query)
  local visible = {}
  query = search_lower(query)
  if query == '' then
    for i = 1, #source_data.tracks do visible[i] = true end
    return visible
  end
  -- Temporarily show all tracks that WOULD be imported during a drag,
  -- without changing any persistent checkbox selections.
  if cross_drag.active and cross_drag.indices then
    for i in pairs(cross_drag.indices) do visible[i] = true end
  end
  -- Before selection, show ONLY name matches. After selection, reveal
  -- chosen tracks and direct dependencies (even manually EXCLUDED ones).
  -- Never reveal all siblings just because their parent was auto-selected.
  for i, tr in ipairs(source_data.tracks) do
    if search_lower(tr.name):find(query, 1, true) or tr.selected then
      visible[i] = true
    end
    if tr.selected and opts.auto_parents then
      local parent = tr.parent
      while parent do
        visible[parent] = true
        parent = source_data.tracks[parent].parent
      end
    end
    if tr.manual == true and opts.auto_sends then
      for _, dest_i in ipairs(tr.send_targets) do
        visible[dest_i] = true
      end
    end
  end
  return visible
end

local function draw_track_list(source_data, query)
  local row_h = math.max(21, ImGui.GetTextLineHeight(ctx) + 3)
  local row_w = math.max(1, select(1, ImGui.GetContentRegionAvail(ctx)) - 8)
  local list_x, list_y = ImGui.GetWindowPos(ctx)
  local list_w, list_h = ImGui.GetWindowSize(ctx)
  local mx, my = ImGui.GetMousePos(ctx)
  local mouse_down = ImGui.IsMouseDown(ctx, 0)
  local mouse_clicked = ImGui.IsMouseClicked(ctx, 0)
  local inside_list = mx >= list_x and mx <= list_x + list_w
      and my >= list_y + 2 and my <= list_y + list_h - 3
  if not mouse_down then
    drag.active, drag.last, drag.frozen_visible = false, nil, nil
  end
  -- Freeze the filtered row set during a press-and-drag gesture. Without
  -- this, selecting Kick adds its parent ABOVE the cursor; while LMB is
  -- still held the moved row is mistaken for a drag over the folder, which
  -- then selects every child. Reveal newly picked dependencies on release.
  local visible = (mouse_down and drag.active and drag.frozen_visible)
      or search_visible(source_data, query)
  local visible_order, visible_position = {}, {}
  local max_icons = 1
  for i, tr in ipairs(source_data.tracks) do
    if visible[i] then
      visible_order[#visible_order+1] = i
      visible_position[i] = #visible_order
      max_icons = math.max(max_icons, #track_icons(tr))
    end
  end
  local icon_col_w = max_icons * ICON_W + (max_icons-1)*ICON_GAP

  -- Allocate ONE shared right-side column for routing hints. Individual
  -- route labels must not move the arrow horizontally. Reserve another
  -- column for the optional "авто" marker only if it is needed at all.
  -- Rows without hints continue to use the whole remaining width for names.
  local any_auto, max_route_w = false, 0
  for _, i in ipairs(visible_order) do
    local tr = source_data.tracks[i]
    if tr.selected and tr.manual ~= true then any_auto = true end
    local dest_i, sender_i = tr.send_targets[1], tr.receives[1]
    local related = (dest_i and source_data.tracks[dest_i])
        or (sender_i and source_data.tracks[sender_i])
    if related then
      local tail = dest_i and #tr.send_targets > 1
          and (' +'..(#tr.send_targets-1)) or ''
      max_route_w = math.max(max_route_w, measured(related.name..tail) + 22)
    end
  end
  local shared_auto_w = any_auto and (measured(T('авто')) + 14) or 0
  local shared_route_w = 0
  if max_route_w > 0 then
    shared_route_w = math.min(max_route_w,
      math.max(34, math.min(row_w * 0.43, row_w - shared_auto_w - 96)))
  end
  local dl = ImGui.GetWindowDrawList(ctx)
  local drag_preview = cross_drag.active and cross_drag.indices or nil
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)

  for i, tr in ipairs(source_data.tracks) do
    if visible[i] then
      local x, y = ImGui.GetCursorScreenPos(ctx)
      ImGui.InvisibleButton(ctx, 'row##'..i, row_w, row_h)
      -- SetScrollHereY must be invoked on the item INSIDE the scrolling
      -- child, after switching back to the full unfiltered list. Wait for
      -- LMB release so a reflow cannot be mistaken for checkbox dragging.
      if focus_reveal.scroll_pending and focus_reveal.index == i
          and query == '' and not mouse_down then
        ImGui.SetScrollHereY(ctx, 0.5)
        focus_reveal.scroll_pending = false
        focus_reveal.since = r.time_precise()
      end
      local on_row = inside_list and mx >= x and mx <= x + row_w
          and my >= y and my < y + row_h
      local on_box = on_row and mx >= x + 12 and mx <= x + 39
      if on_row and mouse_clicked and not on_box then
        if r.JS_Mouse_GetState then
          -- A click on a search hit reveals it upon release. A drag can
          -- instead cross from this row into the arrange/TCP.
          cross_drag.candidate = i
          cross_drag.active, cross_drag.indices = false, nil
          cross_drag.target, cross_drag.proposed_index = nil, nil
          cross_drag.proposed_since, cross_drag.cancelled_until_release = nil, false
          cross_drag.last_good_x, cross_drag.last_good_y, cross_drag.last_good_time = nil, nil, nil
          cross_drag.start_x, cross_drag.start_y = r.GetMousePosition()
        elseif query ~= '' then
          -- Normal search navigation works even without js_ReaScriptAPI.
          reveal_in_full_list(i)
        end
      elseif on_box and mouse_clicked then
        local desired = not tr.selected
        drag.active, drag.value, drag.last = true, desired, i
        drag.frozen_visible = visible
        set_manual(source_data, i, desired)
      elseif on_row and mouse_down and drag.active and drag.last ~= i then
        local from, to = visible_position[drag.last], visible_position[i]
        if from and to then
          local first, last = math.min(from, to), math.max(from, to)
          for k=first, last do
            if visible_order[k] ~= drag.last then
              set_manual(source_data, visible_order[k], drag.value)
            end
          end
        else
          set_manual(source_data, i, drag.value)
        end
        drag.last = i
      end

      if i % 2 == 0 then
        ImGui.DrawList_AddRectFilled(dl, x, y, x+row_w, y+row_h, 0x292929FF)
      end
      if tr.selected then
        ImGui.DrawList_AddRectFilled(dl, x, y, x+row_w, y+row_h, 0x343A3BFF)
      elseif drag_preview and drag_preview[i] then
        -- Temporary amber highlight: these tracks are in the drag batch.
        ImGui.DrawList_AddRectFilled(dl, x, y, x+row_w, y+row_h, 0x55472BFF)
      end
      if on_row then
        ImGui.DrawList_AddRectFilled(dl, x, y, x+row_w, y+row_h, 0x41414155)
        -- The whole row is a drag handle, except for its checkbox.
        if not on_box and r.JS_Mouse_GetState then
          ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
        end
      end
      if focus_reveal.index == i and focus_reveal.since then
        local age = r.time_precise() - focus_reveal.since
        if age >= 2.0 then
          focus_reveal.index, focus_reveal.since = nil, nil
        elseif row_w > 5 then
          -- Hold briefly, then smoothly reduce the alpha during the
          -- final 0.7 s. The track stays selected only visually.
          local alpha = math.floor(230 * math.min(1, (2.0-age)/0.7) + 0.5)
          ImGui.DrawList_AddRect(dl, x+1, y+1, x+row_w-1, y+row_h-1,
            rgba(224, 180, 81, alpha), 2, 0, 1.6)
        end
      end

      local bx, by = x + 18, y + (row_h - 13)/2
      ImGui.DrawList_AddRectFilled(dl, bx, by, bx+13, by+13, 0x202020FF, 2)
      local preview_checked = drag_preview and drag_preview[i]
      ImGui.DrawList_AddRect(dl, bx, by, bx+13, by+13,
        (tr.selected or preview_checked) and 0xDAB65EFF or 0xB7B7B7FF, 2, 0, 1.4)
      if tr.selected or preview_checked then
        dl_line(dl, bx+2.5, by+6.5, bx+5.5, by+9, 0xF4D47AFF, 2.2)
        dl_line(dl, bx+5.5, by+9, bx+11, by+3, 0xF4D47AFF, 2.2)
      end

      local icon_x = x+49
      local iy = y+(row_h-13)/2
      for idx, kind in ipairs(track_icons(tr)) do
        draw_icon(dl, kind, icon_x + (idx-1)*(ICON_W+ICON_GAP), iy)
      end

      local level = tr.level
      if query ~= '' then
        level = 0
        local parent = tr.parent
        while parent do
          if visible[parent] then level = level + 1 end
          parent = source_data.tracks[parent].parent
        end
      end
      level = math.min(level, 16)
      local tree_x = icon_x + icon_col_w + 8
      for d = 1, level do
        local branch_x = tree_x + (d-1)*16
        if d < level then
          dl_line(dl, branch_x, y, branch_x, y+row_h, 0x8A8A8AFF, 1.1)
        else
          dl_line(dl, branch_x, y, branch_x, y+row_h/2, 0x9B9B9BFF, 1.3)
          dl_line(dl, branch_x, y+row_h/2, branch_x+12, y+row_h/2, 0x9B9B9BFF, 1.3)
          if tr.parent and i < source_data.tracks[tr.parent].end_index then
            dl_line(dl, branch_x, y+row_h/2, branch_x, y+row_h, 0x9B9B9BFF, 1.1)
          end
        end
      end
      local name = tr.name ~= '' and tr.name or T('(без названия)')
      local label_x = tree_x + 5 + level*16
      local _, text_h = ImGui.CalcTextSize(ctx, name)
      local text_y = y+(row_h-text_h)/2
      local right = x + row_w - 8

      -- Hints have priority, but only rows that actually have hints
      -- reserve a right-hand column. Otherwise the name can use all space.
      local dest_i, sender_i = tr.send_targets[1], tr.receives[1]
      local related = dest_i and source_data.tracks[dest_i]
      local dir = 0
      local route_full, route_color, route_tail
      if related then
        dir = 1
        route_tail = #tr.send_targets>1 and (' +'..(#tr.send_targets-1)) or ''
        route_full = related.name .. route_tail
        route_color = related.selected and 0xE3B658FF or 0x909090FF
      elseif sender_i and source_data.tracks[sender_i] then
        related = source_data.tracks[sender_i]
        dir = -1
        route_full = related.name
        route_color = related.selected and 0xAAB2B5FF or 0x909090FF
      end
      local auto = tr.selected and tr.manual ~= true
      local auto_w = auto and (measured(T('авто'))+9) or 0
      local route_w = route_full and shared_route_w or 0
      local hint_start = right - shared_auto_w - route_w
          - (shared_auto_w > 0 and route_w > 0 and 8 or 0)
      local name_right = route_w > 0 and hint_start - 7
          or (auto and right - auto_w or right)
      local name_max = math.max(0, name_right-label_x-11)
      local fitted_name, short_name = fitted(name, name_max)
      local bg_w = math.max(0, math.min(name_max+12, measured(fitted_name)+18))
      if bg_w>0 then
        ImGui.DrawList_AddRectFilled(dl, label_x, y+2, label_x+bg_w, y+row_h-2,
          native_background(tr.native_color), 4)
        if bg_w>10 then
          ImGui.DrawList_PushClipRect(dl, label_x+8, y+2,
            label_x+bg_w-3, y+row_h-2, true)
          ImGui.DrawList_AddText(dl, label_x+8, text_y, 0xFFFFFFFF, fitted_name)
          ImGui.DrawList_PopClipRect(dl)
        end
      end

      local short_hint = false
      if route_w>0 then
        local arrow_x = hint_start
        local arrow_y = y+row_h/2
        dl_line(dl, arrow_x, arrow_y, arrow_x+14, arrow_y, route_color, 1.4)
        if dir==1 then
          dl_line(dl, arrow_x+10, arrow_y-3.5, arrow_x+14, arrow_y, route_color, 1.4)
          dl_line(dl, arrow_x+10, arrow_y+3.5, arrow_x+14, arrow_y, route_color, 1.4)
        else
          dl_line(dl, arrow_x+4, arrow_y-3.5, arrow_x, arrow_y, route_color, 1.4)
          dl_line(dl, arrow_x+4, arrow_y+3.5, arrow_x, arrow_y, route_color, 1.4)
        end
        local shown
        shown, short_hint = fitted(route_full, math.max(0, route_w-19))
        ImGui.DrawList_AddText(dl, hint_start+19, text_y, route_color, shown)
      end
      if auto then
        ImGui.DrawList_AddText(dl, right-measured(T('авто')), text_y, 0xA8A8A8FF, T('авто'))
      end
      if on_row and not mouse_down and (short_name or short_hint or not r.JS_Mouse_GetState) then
        local parts={}
        if not r.JS_Mouse_GetState then
          parts[#parts+1] = T('Для перетаскивания в REAPER требуется js_ReaScriptAPI (ReaPack)')
        end
        if short_name then parts[#parts+1] = T('Дорожка: ')..name end
        if short_hint and route_full then
          parts[#parts+1] = (dir==1 and T('Посыл → ') or T('Приём ← '))..route_full
        end
        ImGui.SetTooltip(ctx, table.concat(parts, '\n'))
      end
    end
  end
  ImGui.PopStyleVar(ctx)
end

local function source_history_key(project_path)
  if not project_path or project_path == '' then return nil end
  project_path = normalize(project_path)
  local hash = 2166136261
  for i=1,#project_path do hash = ((hash ~ project_path:byte(i))*16777619) & 0xFFFFFFFF end
  return ('LastSource_%08x'):format(hash), project_path
end

local function picker_initial_path()
  local _, current_path = r.EnumProjects(-1, '')
  local key, project_path = source_history_key(current_path)
  if key then
    if r.GetExtState('RPPTrackImport',key..'_Project') == project_path then
      local last = r.GetExtState('RPPTrackImport',key)
      if last ~= '' and r.file_exists(last) then return last end
    end
    return dirname(current_path) .. '/'
  end
  local last = r.GetExtState('RPPTrackImport','LastProject')
  if last ~= '' and r.file_exists(last) then return dirname(last) .. '/' end
  return ''
end

local function remember_source(path)
  r.SetExtState('RPPTrackImport','LastProject',path,true)
  local _, current_path = r.EnumProjects(-1,'')
  local key, project_path = source_history_key(current_path)
  if key then
    r.SetExtState('RPPTrackImport',key..'_Project',project_path,true)
    r.SetExtState('RPPTrackImport',key,path,true)
  end
end

local function choose_file()
  local initial_path = picker_initial_path()
  local ok, path = r.GetUserFileName(1, T('Выберите исходный проект REAPER'), initial_path,
    'REAPER projects|*.rpp;*.RPP|All files|*.*')
  if not ok or not path or path == '' then return end
  local loaded, parsed = pcall(get_track_data, path)
  if not loaded then
    message, source = T('Ошибка: ') .. tostring(parsed), nil
    notice = {text=tostring(parsed):gsub('^[^\n]-:%d+:%s*','')}
    return
  end
  source = parsed
  recompute_selection(source, opts)
  drag.active, drag.last, drag.frozen_visible = false, nil, nil
  clear_drag_tooltip()
  cross_drag.candidate, cross_drag.active, cross_drag.indices, cross_drag.target = nil, false, nil, nil
  cross_drag.proposed_index, cross_drag.proposed_since = nil, nil
  focus_reveal.index, focus_reveal.scroll_pending, focus_reveal.since = nil, false, nil
  search = ''
  remember_source(path)
  message = ''
end

local function check(label, field)
  local changed, value = ImGui.Checkbox(ctx, label, opts[field])
  if changed then
    opts[field] = value
    if source and (field == 'auto_parents' or field == 'auto_sends') then
      recompute_selection(source, opts)
    end
  end
end

-- Measured once per frame so options remain flush with the bottom edge
-- even when the user changes window height or font scale.
local settings_height = 270

local function draw_import_settings()
  local start_y = ImGui.GetCursorPosY(ctx)
  ImGui.TextColored(ctx, 0xE0B451FF, T('АВТОМАТИЧЕСКИЙ ВЫБОР СВЯЗАННЫХ ДОРОЖЕК'))
  check(T('Импортировать дорожки посылов'), 'auto_sends')
  check(T('Импортировать исходные папки дорожек'), 'auto_parents')
  ImGui.Separator(ctx)
  ImGui.TextColored(ctx, 0xE0B451FF, T('СОДЕРЖИМОЕ ИМПОРТА'))
  check(T('Аудио и MIDI'), 'items')
  check(T('Автоматизация'), 'automation')
  check(T('Копировать медиа в папку проекта'), 'copy')
  check(T('Дополнительно создать общую папку'), 'wrap')
  check(T('Заменить карту темпа/размера исходной (осторожно)'), 'tempo')
  ImGui.Separator(ctx)

  -- Accent only for the action button; ordinary controls stay gray.
  ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xD8A43FFF)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xEDBB59FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0xBF8A2FFF)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x191919FF)
  local width = math.min(358, math.max(185, select(1, ImGui.GetContentRegionAvail(ctx))))
  ImGui.PushFont(ctx, bold_font, ImGui.GetFontSize(ctx) + 2)
  local pressed = ImGui.Button(ctx, T('Импортировать выбранные дорожки'), width, 39)
  ImGui.PopFont(ctx)
  if pressed then
    if source then
      recompute_selection(source, opts)
      request_import(source)
    else
      message = T('Сначала выберите исходный проект .RPP.')
      notice = {text=message}
    end
  end
  ImGui.PopStyleColor(ctx, 4)

  -- Keep the area below the import button empty.
  local used = ImGui.GetCursorPosY(ctx) - start_y
  settings_height = math.max(230, math.ceil(used + 12))
end

local function draw_track_browser()
  local heading_right = ImGui.GetCursorPosX(ctx) + select(1,ImGui.GetContentRegionAvail(ctx))
  local title = fitted(T('ИМПОРТ ДОРОЖЕК ИЗ ДРУГОГО ПРОЕКТА'),
    math.max(0, select(1,ImGui.GetContentRegionAvail(ctx))-42))
  ImGui.TextColored(ctx, 0xE0B451FF, title)
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, math.max(ImGui.GetCursorPosX(ctx),heading_right-32))
  if ImGui.SmallButton(ctx,language == 'ru' and 'RU##language' or 'EN##language') then
    set_language(language == 'ru' and 'en' or 'ru')
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,language == 'ru' and 'Switch to English' or 'Переключить на русский')
  end
  ImGui.Separator(ctx)
  if ImGui.Button(ctx, T('Выбрать проект .RPP'), 182, 30) then choose_file() end
  if source then
    -- Same 30-pixel row as the file picker, with the project name centered
    -- on BOTH axes inside the remaining space. Text() on its own placed the
    -- baseline too high relative to the taller button.
    ImGui.SameLine(ctx)
    local project_name = (basename(source.path):gsub('%.%w+$', ''))
    local field_w = math.max(0, select(1, ImGui.GetContentRegionAvail(ctx)) - 2)
    local field_h = 30
    if field_w > 10 then
      local x, y = ImGui.GetCursorScreenPos(ctx)
      local shown, clipped = fitted(project_name, field_w - 14)
      local tw, th = ImGui.CalcTextSize(ctx, shown)
      -- InvisibleButton owns a predictable 30-pixel region for hovering,
      -- even when the project name is shorter than that region.
      ImGui.InvisibleButton(ctx, '##project_name_field', field_w, field_h)
      local dl = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_PushClipRect(dl, x, y, x + field_w, y + field_h, true)
      ImGui.DrawList_AddText(dl,
        x + math.max(0, (field_w - tw) / 2),
        y + math.max(0, (field_h - th) / 2),
        0xE2E2E2FF, shown)
      ImGui.DrawList_PopClipRect(dl)
      if clipped and ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, project_name)
      end
    end
  else
    ImGui.TextDisabled(ctx, T('После выбора проекта здесь появится список дорожек.'))
    return
  end

  ImGui.Separator(ctx)
  ImGui.TextColored(ctx, 0xE0B451FF, T('ДОРОЖКИ ДЛЯ ИМПОРТА'))
  if ImGui.Button(ctx, T('Выбрать все')) then
    for _, tr in ipairs(source.tracks) do tr.manual = true end
    recompute_selection(source, opts)
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, T('Снять выделение')) then
    for _, tr in ipairs(source.tracks) do tr.manual = nil end
    recompute_selection(source, opts)
  end
  -- Both controls are clipped and laid out INSIDE a single rounded field.
  ImGui.SameLine(ctx)
  local available_width = ImGui.GetContentRegionAvail(ctx)
  local width = math.max(45, available_width)
  local height = ImGui.GetFrameHeight(ctx)
  local clear_width = height
  ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, 0x333333FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0x00000000)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)
  local shown = ImGui.BeginChild(ctx,'##search_field',width,height,0,
    ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoScrollWithMouse)
  if shown then
    -- Keep the clear control at the left edge, inside the shared rounded field.
    -- Reserve its width even when empty so the text never shifts while typing.
    local can_clear = search ~= ''
    local x,y = ImGui.GetCursorScreenPos(ctx)
    ImGui.BeginDisabled(ctx, not can_clear)
    local cleared = ImGui.InvisibleButton(ctx,'##clear_search',clear_width,height)
    local hovered = can_clear and ImGui.IsItemHovered(ctx)
    ImGui.EndDisabled(ctx)
    local cx,cy = x+clear_width/2, y+height/2
    local dl = ImGui.GetWindowDrawList(ctx)
    if hovered then
      ImGui.DrawList_AddCircleFilled(dl,cx,cy,height*0.33,0x505050FF,16)
      ImGui.SetTooltip(ctx,T('Очистить поиск'))
    end
    local d = math.min(3.5,height*0.19)
    local color = can_clear and 0xCFCFCFFF or 0x777777FF
    dl_line(dl,cx-d,cy-d,cx+d,cy+d,color,1.4)
    dl_line(dl,cx-d,cy+d,cx+d,cy-d,color,1.4)
    if can_clear and cleared then
      search = ''
      search_focus_pending = true
      focus_reveal.index, focus_reveal.scroll_pending, focus_reveal.since = nil, false, nil
    end
    ImGui.SameLine(ctx,0,0)
    ImGui.SetNextItemWidth(ctx, width-clear_width)
    if search_focus_pending then
      ImGui.SetKeyboardFocusHere(ctx)
      search_focus_pending = false
    end
    local changed, value = ImGui.InputTextWithHint(ctx, '##search', T('Поиск дорожек...'),
      search, ImGui.InputTextFlags_AutoSelectAll)
    if ImGui.IsItemActive(ctx) then ImGui.SetNextFrameWantCaptureKeyboard(ctx, true) end
    if changed then
      focus_reveal.index, focus_reveal.scroll_pending, focus_reveal.since = nil, false, nil
    end
    search = value
  end
  ImGui.EndChild(ctx)
  ImGui.PopStyleVar(ctx)
  ImGui.PopStyleColor(ctx,4)

  -- Track list fills available height; only it scrolls. The settings
  -- below live in another child and stay attached to the window bottom.
  local available_h = select(2, ImGui.GetContentRegionAvail(ctx))
  local list_h = math.max(80, available_h - 4)
  local visible_list = ImGui.BeginChild(ctx, 'tracklist', 0, list_h, ImGui.ChildFlags_Borders)
  if visible_list then draw_track_list(source, search) end
  ImGui.EndChild(ctx)

end

-- Draw a visible track INSERTION LINE across the arrange trackview. This
-- transparent floating window is never a drop receiver: it is only a preview
-- of the index that is passed to InsertTrackInProject on mouse release.
local function draw_drop_guide()
  local d = cross_drag
  local target = d.active and d.target
  local g = (target and target.geometry) or trackview_geometry(r.GetMousePosition())
  if not g then return end
  local width, height = g.right-g.left, g.bottom-g.top
  if width < 80 or height < 20 then return end
  local y = target and target.guide_y and clamp(target.guide_y, g.top+3, g.bottom-3)
  local flags = ImGui.WindowFlags_NoDecoration | ImGui.WindowFlags_NoDocking
      | ImGui.WindowFlags_NoInputs | ImGui.WindowFlags_NoFocusOnAppearing
      | ImGui.WindowFlags_NoSavedSettings | ImGui.WindowFlags_NoNav
      | ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoBackground
  ImGui.SetNextWindowPos(ctx, g.left, g.top, ImGui.Cond_Always)
  ImGui.SetNextWindowSize(ctx, width, height, ImGui.Cond_Always)
  ImGui.SetNextWindowBgAlpha(ctx, 0)
  local shown = ImGui.Begin(ctx,'##rpp_insert_position_guide',true,flags)
  if shown and y then
    local dl = ImGui.GetWindowDrawList(ctx)
    local left,right = g.left+5,g.right-6
    local gold = 0xF5C65FFF
    -- Only a fixed insertion line. No yellow label or frame.
    ImGui.DrawList_AddLine(dl,left,y,right,y,0x161616A0,4)
    ImGui.DrawList_AddLine(dl,left,y,right,y,gold,2.2)
    ImGui.DrawList_AddCircleFilled(dl,left+2,y,3.2,gold,12)
    ImGui.DrawList_AddCircleFilled(dl,right-2,y,3.2,gold,12)
  end
  ImGui.End(ctx)
end

-- A separate input-transparent floating ReaImGui window follows the
-- SYSTEM cursor, including when the mouse is above the native arrange.
-- It shows a stack of file sheets, like a file drag ghost. No external PNG
-- is necessary and, most importantly, the overlay never accepts drops.
local function draw_drag_ghost()
  if not (cross_drag.active and cross_drag.indices) then return end
  local native_x, native_y = r.GetMousePosition()
  local mx, my = to_imgui(native_x, native_y)
  local can_drop = cross_drag.target ~= nil
  local accent = can_drop and 0x69CE94FF or 0xE0B451FF
  local count = count_drag_tracks(cross_drag.indices)
  local flags = ImGui.WindowFlags_NoDecoration | ImGui.WindowFlags_NoDocking
      | ImGui.WindowFlags_NoInputs | ImGui.WindowFlags_NoFocusOnAppearing
      | ImGui.WindowFlags_NoSavedSettings | ImGui.WindowFlags_AlwaysAutoResize
      | ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoNav
  ImGui.SetNextWindowPos(ctx, mx + 20, my + 18, ImGui.Cond_Always)
  ImGui.SetNextWindowBgAlpha(ctx, 0.94)
  local shown = ImGui.Begin(ctx, '##rpp_drag_files_ghost', true, flags)
  if shown then
    local dl = ImGui.GetWindowDrawList(ctx)
    local x, y = ImGui.GetCursorScreenPos(ctx)
    local function sheet(dx, dy, fill, stroke)
      local sx, sy = x+dx, y+dy
      ImGui.DrawList_AddRectFilled(dl, sx, sy, sx+25, sy+32, fill, 2)
      ImGui.DrawList_AddRect(dl, sx, sy, sx+25, sy+32, stroke, 2, 0, 1.0)
      ImGui.DrawList_AddLine(dl, sx+5, sy+11, sx+19, sy+11, stroke, 1)
      ImGui.DrawList_AddLine(dl, sx+5, sy+17, sx+19, sy+17, stroke, 1)
      ImGui.DrawList_AddLine(dl, sx+5, sy+23, sx+15, sy+23, stroke, 1)
    end
    sheet(6, 5, 0x4A4A4AFF, 0x989898FF)
    sheet(3, 2, 0x575757FF, 0xB6B6B6FF)
    sheet(0, 0, 0x2F3436FF, accent)
    ImGui.DrawList_AddText(dl, x+37, y+2, 0xF0F0F0FF,
      ('%d %s'):format(count, count == 1 and T('дорожка') or T('дорожек')))
    ImGui.DrawList_AddText(dl, x+37, y+20, accent,
      can_drop and cross_drag.target.label or T('Переместите в REAPER'))
    ImGui.Dummy(ctx, 206, 36)
  end
  ImGui.End(ctx)
end

local function draw()
  ImGui.SetNextWindowDockID(ctx, -2, ImGui.Cond_FirstUseEver)
  ImGui.SetNextWindowSize(ctx, 900, 790, ImGui.Cond_FirstUseEver)
    local visible, open = ImGui.Begin(ctx, (T('Импорт дорожек')..'  |  v0.2.26###RPPTrackImport'), true, ImGui.WindowFlags_NoCollapse)
  if visible then
    ImGui.BeginDisabled(ctx, import_job ~= nil)
    local available_h = select(2, ImGui.GetContentRegionAvail(ctx))
    local top_h = math.max(160, available_h - settings_height - 7)
    local top_visible = ImGui.BeginChild(ctx, 'browser_panel', 0, top_h)
    if top_visible then draw_track_browser() end
    ImGui.EndChild(ctx)
    local settings_visible = ImGui.BeginChild(ctx, 'settings_panel', 0, 0, ImGui.ChildFlags_Borders)
    if settings_visible then draw_import_settings() end
    ImGui.EndChild(ctx)
    ImGui.EndDisabled(ctx)
    -- Handle keys AFTER the text field: an active editor owns its shortcuts.
    if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows)
        and not import_job and not notice and not cross_drag.candidate then
      if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
        window_open = false
      elseif not ImGui.IsAnyItemActive(ctx) then
        refresh_shortcuts(false)
        for _, chord in ipairs(shortcut_chords) do
          if ImGui.IsKeyChordPressed(ctx, chord) then window_open = false; break end
        end
      end
    end
  end
  ImGui.End(ctx)
  window_open = import_job ~= nil or (window_open and open)
end

-- Transparent native surface; draw the whole rounded frame ourselves.
-- A normal native popup can retain a square backing/shadow on macOS.
local modal_flags = ImGui.WindowFlags_AlwaysAutoResize | ImGui.WindowFlags_NoResize
  | ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_NoBackground
local function paint_modal_frame(title)
  local x,y = ImGui.GetWindowPos(ctx)
  local w,h = ImGui.GetWindowSize(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddRectFilled(dl,x,y,x+w,y+h,0x282828FF,12)
  ImGui.DrawList_AddRect(dl,x+0.5,y+0.5,x+w-0.5,y+h-0.5,0x464646FF,12,0,1)
  ImGui.TextColored(ctx,0xE0B451FF,title)
  ImGui.Spacing(ctx)
end

local function draw_import_progress()
  if not import_job then
    if ImGui.BeginPopupModal(ctx, (T('Импорт дорожек — выполняется')..'###import_progress'), nil,
        modal_flags) then
      ImGui.CloseCurrentPopup(ctx)
      ImGui.EndPopup(ctx)
    end
    return
  end
  ImGui.OpenPopup(ctx, (T('Импорт дорожек — выполняется')..'###import_progress'))
  ImGui.SetNextWindowBgAlpha(ctx, 1)
  ImGui.SetNextWindowSize(ctx, 470, 0, ImGui.Cond_Always)
  if ImGui.BeginPopupModal(ctx, (T('Импорт дорожек — выполняется')..'###import_progress'), nil,
      modal_flags) then
    paint_modal_frame(T('Импорт дорожек — выполняется'))
    if import_job.question then
      local question = import_job.question
      ImGui.TextColored(ctx,0xE0B451FF,question.title)
      ImGui.TextWrapped(ctx,question.text)
      ImGui.Spacing(ctx)
      if ImGui.Button(ctx,T('Продолжить'),135,28) then question.answer = true end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx,T('Отмена'),100,28) then question.answer = false end
    else
      ImGui.Text(ctx, import_job.text)
      local detail = fitted(import_job.detail or '', 430)
      ImGui.TextDisabled(ctx, detail)
      local fraction = import_job.fraction
      ImGui.ProgressBar(ctx, fraction or (-1-r.time_precise()%1000), -1, 17,
        fraction and ('%d%%'):format(math.floor(fraction*100)) or T('Пожалуйста, подождите…'))
    end
    ImGui.EndPopup(ctx)
  end
end

local function draw_notice()
  if not notice then return end
  ImGui.OpenPopup(ctx,T('Импорт дорожек###import_notice'))
  ImGui.SetNextWindowSize(ctx,430,0,ImGui.Cond_Always)
  ImGui.SetNextWindowBgAlpha(ctx,1)
  if ImGui.BeginPopupModal(ctx,T('Импорт дорожек###import_notice'),nil,
      modal_flags) then
    paint_modal_frame(T('Импорт дорожек'))
    ImGui.TextWrapped(ctx,notice.text)
    ImGui.Spacing(ctx)
    if ImGui.Button(ctx,T('Понятно'),105,28)
        or ImGui.IsKeyPressed(ctx,ImGui.Key_Escape,false) then
      notice = nil
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndPopup(ctx)
  end
end

r.atexit(function()
  clear_drag_tooltip()
  if import_job and import_job.partial then
    local part = import_job.partial
    pcall(function() part.input:close() end)
    pcall(function() part.output:close() end)
    os.remove(part.path)
  end
  if r.set_action_options then r.set_action_options(8) end -- toggle OFF
  for _, job in ipairs(peak_jobs) do
    if job.src then pcall(r.PCM_Source_Destroy, job.src) end
  end
end)

-- Closing the source REAPER tab or switching to another target project
-- must not leave pointers, guide coordinates or pending drag jobs tied to
-- the old project. The .RPP chosen for import remains available in the UI.
local last_active_project = r.EnumProjects(-1, '')
local function handle_active_project_change()
  local now = r.EnumProjects(-1, '')
  if now == last_active_project then return end
  last_active_project = now
  clear_drag_tooltip()
  cross_drag.candidate, cross_drag.active = nil, false
  cross_drag.indices, cross_drag.target = nil, nil
  cross_drag.proposed_index, cross_drag.proposed_since = nil, nil
  cross_drag.last_good_x, cross_drag.last_good_y, cross_drag.last_good_time = nil, nil, nil
  cross_drag.cancelled_until_release = true
  pending_drop = nil
  drag.active, drag.last, drag.frozen_visible = false, nil, nil
end

local function main_loop()
  handle_active_project_change()
  push_theme()
  if window_open then draw() end
  if cross_drag.candidate then finish_cross_drag(ctx) end
  if window_open then
    draw_drop_guide()
    draw_drag_ghost()
    draw_import_progress()
    draw_notice()
  end
  pop_theme()
  if pending_drop then
    local job = pending_drop
    if job.stage == 0 then
      -- One defer cycle to let REAPER paint the status before an import
      -- that may require a noticeable amount of file copying.
      job.stage = 1
    else
      pending_drop = nil
      local current_project = r.EnumProjects(-1, '')
      if current_project ~= job.project then
        message = T('Импорт отменён: активный проект изменился во время переноса.')
      else
        request_import(job.source, job.indices, job.index, job.project)
      end
    end
  end
  step_import()
  if #peak_jobs > 0 then step_peaks() end
  if window_open or import_job or #peak_jobs > 0 then r.defer(main_loop) end
end
r.defer(main_loop)

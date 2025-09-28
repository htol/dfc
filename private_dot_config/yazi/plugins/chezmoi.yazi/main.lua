--- @since 25.12.29

local should_refresh = ya.sync(function(st)
	local now = ya.time()
	if st.running or (st.last_fetch and (now - st.last_fetch) < st.ttl) then
		return false
	end
	st.running = true
	return true
end)

local done_refresh = ya.sync(function(st, ok)
	st.running = false
	if ok then st.last_fetch = ya.time() end
end)

local set_managed = ya.sync(function(st, data)
	st.managed = data
	ui.render()
end)

local get_selected = ya.sync(function(st)
	local paths = {}
	local is_managed = true
	local has_selected = false

	for _, url in pairs(cx.active.selected) do
		has_selected = true
		local path = tostring(url):gsub("/$", "")
		paths[#paths + 1] = path
		if not st.managed or not st.managed[path] then
			is_managed = false
		end
	end

	if not has_selected then
		local h = cx.active.current.hovered
		if not h then return nil, false end
		local path = tostring(h.url):gsub("/$", "")
		paths[1] = path
		is_managed = st.managed and st.managed[path] and true or false
	end

	return paths, is_managed
end)

local apply_optimistic = ya.sync(function(st, paths, should_add)
	if st.managed then
		for _, path in ipairs(paths) do
			st.managed[path] = should_add and 1 or nil
		end
		ui.render()
	end
end)

local reset_ttl = ya.sync(function(st)
	st.last_fetch = nil
end)

local function do_refresh()
	local output, err = Command("chezmoi")
		:arg({ "managed", "--path-style=absolute" })
		:stdout(Command.PIPED)
		:output()
	if not output or not output.status.success then
		return false, err
	end
	local m = {}
	for line in output.stdout:gmatch("[^\r\n]+") do
		m[line:gsub("/$", "")] = 1
	end

	local status_out = Command("chezmoi")
		:arg({ "status", "--path-style=absolute" })
		:stdout(Command.PIPED)
		:output()
	if status_out and status_out.status.success then
		for line in status_out.stdout:gmatch("[^\r\n]+") do
			local status, path = line:match("^([ %w%?]+)%s+(.+)$")
			if path and m[path] then
				m[path] = 2 -- modified state
			end
		end
	end

	set_managed(m)
	return true
end

local function setup(st, opts)
	st.managed    = nil
	st.running    = false
	st.last_fetch = nil
	opts          = opts or {}
	st.ttl        = opts.ttl   or 30
	opts.order    = opts.order or 1500

	local sign           = opts.sign           or "◆"
	local style          = opts.style          or ui.Style():fg("cyan"):bold()
	local modified_sign  = opts.modified_sign  or "M"
	local modified_style = opts.modified_style or ui.Style():fg("yellow"):bold()
	local loading_sign   = opts.loading_sign   or "…"
	local loading_style  = opts.loading_style  or ui.Style():fg("blue")

	Linemode:children_add(function(self)
		if not self._file.in_current then return "" end
		if not st.managed then
			if st.running and self._file.is_hovered then
				return ui.Line { " ", ui.Span(loading_sign):style(loading_style) }
			end
			return ""
		end
		local path = tostring(self._file.url):gsub("/$", "")
		local state = st.managed[path]
		if not state then return "" end
		
		local s, sty = sign, style
		if state == 2 then
			s, sty = modified_sign, modified_style
		end

		if self._file.is_hovered then
			return ui.Line { " ", s }
		end
		return ui.Line { " ", ui.Span(s):style(sty) }
	end, opts.order)
end

--- @type UnstableFetcher
local function fetch(_, job)
	if not should_refresh() then return false end
	local ok, err = do_refresh()
	done_refresh(ok)
	if not ok then
		return true, Err("chezmoi plugin: %s", tostring(err))
	end
	return false
end

local function entry(_, job)
	local paths, is_managed = get_selected()
	if not paths or #paths == 0 then return end

	local action = is_managed and "forget" or "add"

	if action == "forget" then
		local first_path = paths[1]
		local title = #paths == 1
			and string.format("Stop managing %s? (y/N)", first_path:match("[^/]+$") or first_path)
			or string.format("Stop managing %d files? (y/N)", #paths)

		local value, event = ya.input({ title = title, position = { "top-center", y = 3, w = 40 } })
		if event ~= 1 or not value or not value:lower():match("^y") then
			return
		end
	end

	apply_optimistic(paths, not is_managed)

	local args = { action, "--force" }
	for _, p in ipairs(paths) do
		args[#args + 1] = p
	end

	local output, err = Command("chezmoi")
		:arg(args)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output or not output.status.success then
		apply_optimistic(paths, is_managed)  -- revert
		local msg = (output and output.stderr ~= "") and output.stderr or tostring(err)
		ya.notify({ title = "chezmoi", content = msg, timeout = 5, level = "error" })
		return
	end

	ya.notify({
		title   = "chezmoi",
		content = (is_managed and "Removed " or "Added ") .. tostring(#paths) .. " file(s)",
		timeout = 2,
	})

	reset_ttl()
end

return { setup = setup, fetch = fetch, entry = entry }

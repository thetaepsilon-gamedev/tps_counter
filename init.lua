local util = {}
util.mk_broadcast_listener = function()
	local recv = {}
	local f = function(...)
		for k, f in pairs(recv) do
			f(...)
		end
	end

	return f, recv
end

--[[
local floor = math.floor
local tps_f = "%.3f"
local function fire_update_per_second(ticks, usecs)
	local ttime = floor(usecs / ticks)
	local tps = ticks * 1000000 / usecs
	minetest.chat_send_all(
		ticks .. " ticks in " .. usecs .. "μs, ~" .. ttime ..
		"μs per tick, ~" .. tps_f:format(tps) .. " ticks per second")
end
]]
local fire_update_per_second, global_listeners = util.mk_broadcast_listener()

-- the server step time varies *and* dedicated_server_step lies in singleplayer
-- (there globalstep tries to run seemingly once per frame!).
-- so instead accumulate microseconds and fire an update when we reach a certain time period.
-- longer periods obviously update less often but are a smoother measure not affected so much by jitter.

local key = "sps_counter_period_usecs"
local period = minetest.settings:get(key)
if period then
	period = assert(tonumber(period),  "expected integer for setting " .. key)
else
	period = 1000000
end

local seen_ticks = 0
local seen_usecs = 0
local function fire_update_fast(usecs)
	seen_usecs = seen_usecs + usecs
	seen_ticks = seen_ticks + 1
	if (seen_usecs > period) then
		fire_update_per_second(seen_ticks, seen_usecs)
		seen_ticks = 0
		seen_usecs = 0
	end
end

local previous = nil
local get_us_time = minetest.get_us_time
minetest.register_globalstep(function(dtime)
	-- we ignore dtime and use a more accurate timer instead here
	local utime = get_us_time()
	if previous then
		local delta = (utime - previous)
		fire_update_fast(delta)
	end
	previous = utime
end)



local mp = minetest.get_modpath("tps_counter")
-- TODO: this is useful, I should throw this in my prelude mod...
local dofilex = function(name, ...)
	local c, err = loadfile(mp .. "/" .. name)
	assert(c, err)
	return c(...)
end


global_listeners["player_hud"] = dofilex("broadcast_player_hud.lua")



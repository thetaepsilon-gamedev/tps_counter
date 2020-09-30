local huddef = {
	type="text",
	text="???",
	-- this probably will upset someone but it's mostly for diagnostics anyway so...
	z_index=9999,
	-- NB: x=-1 is "align towards left", meaning move it left to align position to *right* edge...
	-- similar story with y=1 being "align downwards".
	alignment={x=-1,y=1},
	position={x=1,y=0},
	number=16777215,
}

local hud_setup = function(player)
	return player:hud_add(huddef)
end
local hud_remove = function(player, id)
	player:hud_remove(id)
end

-- associative dictionary of players to the hud data as created by hud_setup().
local players = {}

-- code switching for singleplayer determining % of step time target:
-- in singleplayer dedicated_server_step is largely ignored for globalsteps at least.
-- so we just disable that feature in singleplayer to avoid wrong % issues.
local calc_perf = function() return "" end
if not minetest.is_singleplayer() then
	local target_usecs = assert(tonumber(minetest.settings:get("dedicated_server_step"))) * 1000000
	local perf_f = "%.1f"
	calc_perf = function(uspt)
		local r = target_usecs / uspt
		return " (" .. perf_f:format((r) * 100) .. "%)"
	end
end

local floor = math.floor
local tps_f = "%.1f"
local function hud_update(player, id, ticks, usecs)
	local uspt = floor(usecs / ticks)
	local tps = ticks * 1000000 / usecs
	local perf = calc_perf(uspt)
	local str = tps_f:format(tps) .. " TPS, " .. uspt .. "us/tick" .. perf
	player:hud_change(id, "text", str)
end

local hud_enable = function(player)
	players[player] = hud_setup(player)
end
local hud_disable = function(player)
	local data = players[player]
	if data then
		hud_remove(player, data)
		players[player] = nil
	end
end






local name_hud = "tps_hud"
local desc_hud = "Allows viewing server TPS stats in real time (may leak information about other players)"
minetest.register_privilege(name_hud, {
	description = desc_hud,
})
local cmd_hud = function(name, cmdline)
	-- this could theoretically be called on a user's behalf but without them being in-game,
	-- e.g. command blocks or certain IRC relays.
	-- so fetching the player by name may fail.
	local player = minetest.get_player_by_name(name)
	if not player then
		return false, "# that player is not currently online."
	end
	if cmdline == "on" then
		hud_enable(player)
		return true
	elseif cmdline == "off" then
		hud_disable(player)
		return true
	else
		return false, "# unrecognised argument: " .. cmdline
	end
end
minetest.register_chatcommand(name_hud, {
	description = "Controls visibility of the on-screen TPS HUD",
	params = "<on|off>",
	privs = {[name_hud] = true},
	func = cmd_hud,
})
-- clean-up of stale player handles
minetest.register_on_leaveplayer(function(player, timed_out)
	hud_disable(player)
end)






return function(...)
	for player, data in pairs(players) do
		hud_update(player, data, ...)
	end
end


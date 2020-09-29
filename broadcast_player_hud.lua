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



-- HAX
minetest.register_on_joinplayer(function(player)
	players[player] = hud_setup(player)
end)



return function(...)
	for player, data in pairs(players) do
		hud_update(player, data, ...)
	end
end


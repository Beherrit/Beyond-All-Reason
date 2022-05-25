--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Map Waterlevel",
		version = "v1",
		desc = "Implements map_waterlevel modoption or enable cheats and do /luarules waterlevel #",
		author = "Doo",
		date = "Nov 2017",
		license = "GPL",
		layer = math.huge, --higher layer is loaded last
		enabled = true,
	}
end

local PACKET_HEADER = "$wl$"
local PACKET_HEADER_LENGTH = string.len(PACKET_HEADER)

if gadgetHandler:IsSyncedCode() then

	local waterlevel = Spring.GetModOptions().map_waterlevel
	local orgFeaturePosY = {}

	function adjustFeatureHeight()
		local featuretable = Spring.GetAllFeatures()
		local x, y, z
		for i = 1, #featuretable do
			x, y, z = Spring.GetFeaturePosition(featuretable[i])
      Spring.SetFeaturePosition(featuretable[i], x,  y,  z ,true) -- snaptoground = true
		end
	end

	function adjustWaterlevel()
		-- Spring.SetMapRenderingParams({ voidWater = false})
    Spring.Echo("adjustWaterlevel: this might cause a lag spike.")
		Spring.AdjustHeightMap(0, 0, Game.mapSizeX, Game.mapSizeZ, -waterlevel)
		Spring.AdjustOriginalHeightMap(0, 0, Game.mapSizeX, Game.mapSizeZ, -waterlevel)
		Spring.AdjustSmoothMesh(0, 0, Game.mapSizeX, Game.mapSizeZ, -waterlevel)
		adjustFeatureHeight()
	end

	function gadget:Initialize()
		if Spring.GetGameFrame() == 0 and Spring.GetModOptions().map_waterlevel ~= 0 then
			waterlevel = Spring.GetModOptions().map_waterlevel
			adjustWaterlevel()
		end
	end

	function gadget:GameFrame(gf)
		-- Keeping this in forces feature recreation on frame 0, with a lag spike on init, also destroying all preexisting feature rotations.
		-- adjustFeatureHeight() -- im removing this, this is stupid. B.
		gadgetHandler:RemoveCallIn("GameFrame")
	end

	function gadget:GamePreload()
		if waterlevel ~= 0 then
			adjustFeatureHeight()
		end
	end

	function gadget:RecvLuaMsg(msg, playerID)
		if string.sub(msg, 1, PACKET_HEADER_LENGTH) ~= PACKET_HEADER then
			return
		end

		local playername, _, spec = Spring.GetPlayerInfo(playerID, false)
		local authorized = false
		for _, name in ipairs(_G.permissions.waterlevel) do
			if playername == name then
				authorized = true
				break
			end
		end

		if not (authorized or Spring.IsCheatingEnabled()) then
			return
		end

		local params = string.split(msg, ':')
		waterlevel = tonumber(params[2])
		adjustWaterlevel()
		Spring.Echo('Changed waterlevel: ' .. waterlevel)
	end

else
	-- UNSYNCED

	function gadget:Initialize()
		gadgetHandler:AddChatAction('waterlevel', waterlevel)
	end

	function gadget:Shutdown()
		gadgetHandler:RemoveChatAction('waterlevel')
	end

	function waterlevel(cmd, line, words, playerID)
		if words[1] then
			local playername = Spring.GetPlayerInfo(Spring.GetMyPlayerID(),false)
			local authorized = false
			for _,name in ipairs(SYNCED.permissions.waterlevel) do
				if playername == name then
					authorized = true
					break
				end
			end
			if authorized or Spring.IsCheatingEnabled() then
				Spring.SendLuaRulesMsg(PACKET_HEADER .. ':' .. words[1])
			end
		end
	end
end

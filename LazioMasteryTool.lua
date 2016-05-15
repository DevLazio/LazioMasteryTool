                                                                                                                                                                                                                      
-- creating the frame for the event handler
local frame = CreateFrame("FRAME", "LazioMasteryToolFrame");
local spellList = {
        	[774] = true, 		-- Rejuv
			[155777] = true,	-- Germi
        	[188550] = true,	-- LB
        	[48438] = true,		-- WG
			[8936] = true,		-- Regrowth
			[102342] = true,	-- Ironbark
			}
			
local playerName = UnitName("player");

local playersTable = {
			}	
local playerHotNumber = {
					}		
local allowedTargets = {
				}

if triggers_toggle == nil then
	triggers_toggle = true
end

frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_SAY")

local function calcAverageNumberOfHoTs()
   local total = 0;
   local nbrAffectedPlayers = 0;
   for key,value in pairs(playersTable) do
      local totalTime = 0;
      local totalValue = 0;
      for i=1,7,1 do
         totalTime = totalTime + playersTable[key][i];
         totalValue = totalValue + playersTable[key][i] * i;
      end
      if totalTime > 0 then
         total = total + (totalValue / totalTime);
		 nbrAffectedPlayers = nbrAffectedPlayers + 1;
      end
   end
   total = total / nbrAffectedPlayers;
   print('Final value ' .. total);
end

local function getNbrBuff(player)
	local i = 1;
	local  nbrBuff = 0;

	repeat
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff(player, i);
		i = i + 1;
		if spellList[spellID] and caster == 'player' then
			nbrBuff = nbrBuff + 1;
		end
	until not(spellID);

return nbrBuff;
end

-- Event handler function
local function eventHandler(self, event, ...)
	if not triggers_toggle then
		return
	end
	local playerName = UnitName("player");
	
	if (event=="COMBAT_LOG_EVENT_UNFILTERED") then
		local timestamp, type, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2 = select(1, ...)
		if (not(allowedTargets[destName])) then --on ne veut que les cibles de notre raid
			return
		end
		if (type == "SPELL_AURA_APPLIED" and sourceName == playerName) then

			local spellId, spellName, spellSchool = select(12, ...);
			
			if (spellList[spellId]) then
				playersTable[destName][playerHotNumber[destName]['currentLevel']] = playersTable[destName][playerHotNumber[destName]['currentLevel']] + timestamp - playerHotNumber[destName]['timestamp'];
				playerHotNumber[destName]['currentLevel'] = playerHotNumber[destName]['currentLevel'] + 1;
				playerHotNumber[destName]['timestamp'] = timestamp;
			end
		else if (type == "SPELL_AURA_REMOVED" and sourceName == playerName) then
			local spellId, spellName, spellSchool = select(12, ...);
			if (spellList[spellId]) then
				playersTable[destName][playerHotNumber[destName]['currentLevel']] = playersTable[destName][playerHotNumber[destName]['currentLevel']] + timestamp - playerHotNumber[destName]['timestamp'];
				playerHotNumber[destName]['currentLevel'] = playerHotNumber[destName]['currentLevel'] - 1;
				playerHotNumber[destName]['timestamp'] = timestamp;
			end
		end
		end
	else if (event == "PLAYER_REGEN_DISABLED") then --debut combat
		local nbrMembers = GetNumGroupMembers();
		local i = 1;

		while (i <= nbrMembers) do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			playersTable[name] = {
							[0] = 0,
							[1] = 0,
							[2] = 0,
							[3] = 0,
							[4] = 0,
							[5] = 0,
							[6] = 0,
							[7] = 0,
						   }
		    playerHotNumber[name] = {
							['currentLevel'] = getNbrBuff(name),
							['timestamp'] = time();
							}
			allowedTargets[name] = true;
			i = i + 1;
		end
		tprint(allowedTargets);
	else if (event == "PLAYER_REGEN_ENABLED") then
		for key,value in pairs(playersTable) do
			playersTable[key][0] = 1;
			playersTable[key][playerHotNumber[key]['currentLevel']] = playersTable[key][playerHotNumber[key]['currentLevel']] + time() - playerHotNumber[key]['timestamp'];
			
		end
		
		tprint(playersTable);
		--tprint(playerHotNumber);
		--tprint(allowedTargets);
		calcAverageNumberOfHoTs();
		local playersTable = {
			}		
		local playerHotNumber = {
					}			
		local allowedTargets = {
				}
	end
	end
	end
	
	
end
frame:SetScript("OnEvent", eventHandler);

-- Slash commands
SLASH_LAZIOMASTERYTOOL1, SLASH_LAZIOMASTERYTOOL2 = '/laziomasterytool', '/lmt';
local function handler(msg, editbox)
	if msg == 'debug' then
		-- insert here some debugging use
	else if msg == 'toggle' then
		triggers_toggle = not triggers_toggle
		if triggers_toggle then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LazioMasteryTool is now on|r")
		else if not triggers_toggle then
			DEFAULT_CHAT_FRAME:AddMessage("|cffff0000LazioMasteryTool is now off|r")
		end
		end
	end
	if msg == "help" then -- display a manual of this addon
		print("Lazio Mastery Tool commands:")
		print("toggle : enable of disable addon")
		print('dump : dump all data');
		print("help : display this help")
	end
	if msg == "dump" then -- dump data tables
		print("Dumping data :")
		tprint(playersTable);
		tprint(playerHotNumber);
	end
end
end
SlashCmdList["LAZIOMASTERYTOOL"] = handler;

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end
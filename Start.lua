local TK = ThiefsKnapsack

local function onPlayerActivated()
   EVENT_MANAGER:UnregisterForEvent(TK.name, EVENT_PLAYER_ACTIVATED)
   TK:BuildUI()
end

local function onLoaded(ev, addon)
   if(addon ~= TK.name) then return end

   EVENT_MANAGER:UnregisterForEvent(TK.name, EVENT_ADD_ON_LOADED)
   TK.saved = ZO_SavedVars:New("ThiefsKnapsackVars", 1, nil, TK.defaults)

   TK:RegisterSettings()
end

EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_ADD_ON_LOADED, onLoaded)
EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_PLAYER_ACTIVATED, onPlayerActivated)

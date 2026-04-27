Vigil = Vigil or {}

-- Ring buffer of recent events for /vigil events diagnostic.
Vigil.EventLog = Vigil.EventLog or {}
local EVENT_LOG_MAX = 30
local function logEvent(name, detail)
    local t = (GetTime and GetTime()) or 0
    Vigil.EventLog[#Vigil.EventLog + 1] = {
        time = t,
        name = name,
        detail = detail,
    }
    while #Vigil.EventLog > EVENT_LOG_MAX do
        table.remove(Vigil.EventLog, 1)
    end
end

local frame = CreateFrame("Frame", "VigilEventFrame", UIParent)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

-- UNIT_SPELLCAST_SUCCEEDED is restricted for partyN tokens in 12.0+ dungeons (see CLAUDE.md).
-- We register it ONLY for the player token and use it to broadcast our own casts to peers.
-- COMBAT_LOG_EVENT_UNFILTERED is fully restricted for party-source events; we don't register it.
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

local function scheduleDelayedBroadcast(seconds)
    if not C_Timer or not C_Timer.After then return end
    C_Timer.After(seconds, function()
        if IsInGroup and IsInGroup() then
            Vigil.Sync.Broadcast(true)  -- force, bypass throttle
        end
    end)
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Vigil" then
            Vigil.Config.Init()
            Vigil.Sync.RegisterPrefix()
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        logEvent(event)
        Vigil.Display.Create()
        Vigil.Sync.PruneRoster()
        Vigil.Sync.Broadcast(true)
        Vigil.Display.Refresh()

    elseif event == "PLAYER_ENTERING_WORLD" then
        logEvent(event)
        Vigil.Sync.PruneRoster()
        Vigil.Sync.Broadcast(true)  -- force broadcast on zone-in
        Vigil.Display.Refresh()
        -- Peers may still be on their loading screen; re-broadcast a few seconds later
        -- so they can populate our row in their UI even if they missed our first send.
        scheduleDelayedBroadcast(4)

    elseif event == "GROUP_ROSTER_UPDATE" or event == "GROUP_JOINED" or event == "GROUP_LEFT" then
        logEvent(event)
        Vigil.Sync.PruneRoster()
        Vigil.Sync.Broadcast(true)  -- force on every roster change so new members get our loadout
        Vigil.Display.Refresh()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit == "player" then
            logEvent(event)
            Vigil.Sync.Broadcast(true)
            Vigil.Display.Refresh()
        end

    elseif event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
        logEvent(event)
        Vigil.Sync.Broadcast(true)
        Vigil.Display.Refresh()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if spellID then Vigil.Sync.NotifyOwnCast(spellID) end

    elseif event == "CHAT_MSG_ADDON" then
        Vigil.Sync.OnMessage(...)
    end
end)

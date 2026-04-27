Vigil = Vigil or {}
Vigil.Config = Vigil.Config or {}

Vigil.BUILD = "0.1.30"

local DEFAULTS = {
    position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 },
    enabled = true,
    iconSize = 32,
    locked = false,
    debug = false,
}

function Vigil.Config.Init()
    VigilDB = VigilDB or {}
    for k, v in pairs(DEFAULTS) do
        if VigilDB[k] == nil then
            if type(v) == "table" then
                VigilDB[k] = {}
                for kk, vv in pairs(v) do VigilDB[k][kk] = vv end
            else
                VigilDB[k] = v
            end
        end
    end
end

local function PrintHelp()
    print("|cff7fa6ffVigil|r commands:")
    print("  /vigil           - toggle display")
    print("  /vigil show      - show display")
    print("  /vigil hide      - hide display")
    print("  /vigil lock      - lock position (disables drag)")
    print("  /vigil unlock    - unlock position (enables drag)")
    print("  /vigil reset     - reset position to center")
    print("  /vigil debug     - toggle debug prints")
    print("  /vigil version   - print loaded build")
    print("  /vigil status    - dump current state")
    print("  /vigil dump [N]  - inspect partyN (or all party slots)")
    print("  /vigil simulate  - fire a 30s test timer on each party member")
    print("  /vigil test      - toggle 4 fake party members for positioning/UI testing")
    print("  /vigil events    - dump recent event log")
end

SLASH_VIGIL1 = "/vigil"
SlashCmdList["VIGIL"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "" then
        Vigil.Display.Toggle()
    elseif msg == "show" then
        Vigil.Display.Show()
    elseif msg == "hide" then
        Vigil.Display.Hide()
    elseif msg == "lock" then
        VigilDB.locked = true
        Vigil.Display.ApplyLock()
        print("|cff7fa6ffVigil|r: locked")
    elseif msg == "unlock" then
        VigilDB.locked = false
        Vigil.Display.ApplyLock()
        print("|cff7fa6ffVigil|r: unlocked (drag to move)")
    elseif msg == "reset" then
        VigilDB.position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 }
        Vigil.Display.RestorePosition()
        print("|cff7fa6ffVigil|r: position reset")
    elseif msg == "debug" then
        VigilDB.debug = not VigilDB.debug
        print("|cff7fa6ffVigil|r: debug " .. (VigilDB.debug and "ON" or "OFF"))
    elseif msg == "version" then
        print("|cff7fa6ffVigil|r build " .. tostring(Vigil.BUILD))
    elseif msg == "status" then
        local guid = UnitGUID("player")
        local cached = guid and Vigil.Cache[guid] or nil
        local nSpells = 0
        if cached and cached.spells then
            for _ in pairs(cached.spells) do nSpells = nSpells + 1 end
        end
        local nDB = 0
        for _ in pairs(Vigil.Spells) do nDB = nDB + 1 end
        -- Count remote Vigil users we've heard from (Cache entries with specID set
        -- that aren't the player). Tells us if sync is reaching anyone.
        local nPeers = 0
        local playerGUID = UnitGUID("player")
        for g, c in pairs(Vigil.Cache) do
            if g ~= playerGUID and c.specID then nPeers = nPeers + 1 end
        end
        print(("|cff7fa6ffVigil|r build=%s db=%d cachedForMe=%d vigilPeers=%d inGroup=%s debug=%s"):format(
            tostring(Vigil.BUILD), nDB, nSpells, nPeers,
            tostring(IsInGroup and IsInGroup() or false),
            tostring(VigilDB.debug)))
    elseif msg == "dump" or msg:match("^dump %d$") then
        local function dumpUnit(u)
            if not UnitExists(u) then
                print(("|cff7fa6ffVigil|r %s: not in party"):format(u))
                return
            end
            local guid = UnitGUID(u)
            local c = guid and Vigil.Cache[guid] or nil
            if not c then
                print(("|cff7fa6ffVigil|r %s [%s]: no cache entry"):format(u, tostring(guid)))
                return
            end
            local nSpells = 0
            for _ in pairs(c.spells or {}) do nSpells = nSpells + 1 end
            local nActive, nFinished = 0, 0
            local timers = Vigil.Timers and Vigil.Timers[guid] or {}
            local now = GetTime()
            for spellID, t in pairs(timers) do
                local rem = (t.startTime + t.duration) - now
                if rem > 0 then nActive = nActive + 1 else nFinished = nFinished + 1 end
            end
            print(("|cff7fa6ffVigil|r %s [%s]"):format(u, tostring(c.name)))
            print(("  guid=%s class=%s role=%s specID=%s"):format(
                tostring(guid), tostring(c.class), tostring(c.role), tostring(c.specID)))
            print(("  spells=%d cooldowns=%d activeTimers=%d (finished=%d)"):format(
                nSpells,
                (function() local n = 0; for _ in pairs(c.cooldowns or {}) do n = n + 1 end; return n end)(),
                nActive, nFinished))
            -- list active timers
            for spellID, t in pairs(timers) do
                local rem = (t.startTime + t.duration) - now
                if rem > 0 then
                    local entry = Vigil.Spells[spellID]
                    local name = entry and entry.name or tostring(spellID)
                    print(("    %s (id=%d): %.0fs / %.0fs remaining"):format(name, spellID, rem, t.duration))
                end
            end
        end
        local idx = tonumber(msg:match("^dump (%d)$"))
        if idx then dumpUnit("party" .. idx)
        else for i = 1, 4 do dumpUnit("party" .. i) end end

    elseif msg == "simulate" then
        Vigil.Timers = Vigil.Timers or {}
        local count = 0
        local slots
        if Vigil.TestMode then
            slots = {
                { unit = "test1", guid = "test-1" },
                { unit = "test2", guid = "test-2" },
                { unit = "test3", guid = "test-3" },
                { unit = "test4", guid = "test-4" },
            }
        else
            slots = {}
            for i = 1, 4 do
                local u = "party" .. i
                if UnitExists(u) then
                    slots[#slots + 1] = { unit = u, guid = UnitGUID(u) }
                end
            end
        end
        for _, s in ipairs(slots) do
            local cached = s.guid and Vigil.Cache[s.guid] or nil
            if cached and cached.spells then
                local pickID
                for id in pairs(cached.spells) do
                    if not pickID or id < pickID then pickID = id end
                end
                if pickID then
                    Vigil.Timers[s.guid] = Vigil.Timers[s.guid] or {}
                    Vigil.Timers[s.guid][pickID] = { startTime = GetTime(), duration = 30 }
                    local entry = Vigil.Spells[pickID]
                    print(("|cff7fa6ffVigil|r simulate: %s = %s (id=%d) for 30s"):format(
                        s.unit, entry and entry.name or "?", pickID))
                    count = count + 1
                end
            end
        end
        if Vigil.Display and Vigil.Display.Refresh then Vigil.Display.Refresh() end
        if count == 0 then
            print("|cff7fa6ffVigil|r simulate: no slots with cached spells (use /vigil test or join a group with Vigil peers)")
        end

    elseif msg == "test" then
        if Vigil.TestMode then
            -- turn off
            Vigil.TestMode = false
            for guid in pairs(Vigil.Cache) do
                if type(guid) == "string" and guid:sub(1, 5) == "test-" then
                    Vigil.Cache[guid] = nil
                end
            end
            for guid in pairs(Vigil.Timers or {}) do
                if type(guid) == "string" and guid:sub(1, 5) == "test-" then
                    Vigil.Timers[guid] = nil
                end
            end
            print("|cff7fa6ffVigil|r test mode OFF")
        else
            -- turn on; populate 4 fake party members spanning the role triad
            Vigil.TestMode = true
            local TEST = {
                { guid = "test-1", unit = "test1", name = "Tankington",  class = "PALADIN",     specID = 66  },  -- Prot Pal
                { guid = "test-2", unit = "test2", name = "Healington",  class = "PRIEST",      specID = 257 },  -- Holy Priest
                { guid = "test-3", unit = "test3", name = "Frostington", class = "MAGE",        specID = 64  },  -- Frost Mage
                { guid = "test-4", unit = "test4", name = "Stabington",  class = "ROGUE",       specID = 261 },  -- Sub Rogue
            }
            for _, t in ipairs(TEST) do
                local spells, cooldowns = {}, {}
                local csv = Vigil.GetActiveSpellsForSpec(t.specID, t.class)
                if csv and csv ~= "" then
                    for idStr in csv:gmatch("([^,]+)") do
                        local id = tonumber(idStr)
                        if id then
                            spells[id] = true
                            local entry = Vigil.Spells[id]
                            if entry then cooldowns[id] = entry.baseCooldown end
                        end
                    end
                end
                Vigil.Cache[t.guid] = {
                    unit = t.unit,
                    name = t.name,
                    class = t.class,
                    specID = t.specID,
                    spells = spells,
                    cooldowns = cooldowns,
                }
            end
            print("|cff7fa6ffVigil|r test mode ON — 4 fake party members loaded")
            print("  /vigil test     - toggle off when done")
            print("  /vigil simulate - fire 30s timers on the test rows")
        end
        if Vigil.Display and Vigil.Display.Refresh then Vigil.Display.Refresh() end

    elseif msg == "events" then
        local log = Vigil.EventLog or {}
        if #log == 0 then
            print("|cff7fa6ffVigil|r events: (none)")
        else
            print(("|cff7fa6ffVigil|r events (%d, oldest first):"):format(#log))
            local now = GetTime()
            for _, e in ipairs(log) do
                local ago = now - (e.time or 0)
                if e.detail then
                    print(("  -%.1fs  %s  %s"):format(ago, e.name, tostring(e.detail)))
                else
                    print(("  -%.1fs  %s"):format(ago, e.name))
                end
            end
        end

    elseif msg == "help" or msg == "?" then
        PrintHelp()
    else
        PrintHelp()
    end
end

function Vigil_OnAddonCompartmentClick(addonName, button)
    Vigil.Display.Toggle()
end

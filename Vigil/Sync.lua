Vigil = Vigil or {}
Vigil.Sync = Vigil.Sync or {}
Vigil.Cache  = Vigil.Cache  or {}  -- [guid] = { unit, name, class, specID, role, spells={[id]=true}, cooldowns={[id]=seconds} }
Vigil.Timers = Vigil.Timers or {}  -- [guid] = { [spellID] = { startTime, duration } }

-- Sync is the SOLE tracking source in 12.0+: party-source CLEU and UNIT_SPELLCAST_SUCCEEDED
-- are silently restricted for partyN tokens. Each Vigil client broadcasts its own loadout
-- (so peers know our kit) and its own casts (so peers can start timers for us). Players
-- without Vigil get class-base icons but no timers — there is no documented event we can
-- listen to that would surface their casts.
--
-- Wire format ("VIGIL" addon prefix, PARTY channel):
--   L:specID:spellID=cd,spellID=cd,...   loadout broadcast
--   C:spellID:cd                         single cast notification
--
-- All cd values are seconds (talented when computable, base from DB otherwise).

local PREFIX = "VIGIL"
local lastLoadoutBroadcast = 0
local LOADOUT_THROTTLE = 2.0

function Vigil.Sync.RegisterPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
end

-- Walks player + party1..4, returns the unit token whose name matches sender (with or without realm).
function Vigil.ResolveUnitFromSender(sender)
    local senderName = sender and sender:match("^([^-]+)") or sender
    local units = { "player", "party1", "party2", "party3", "party4" }
    for _, u in ipairs(units) do
        if UnitExists(u) then
            local n, r = UnitName(u)
            local full = (r and r ~= "" and (n .. "-" .. r)) or n
            if n == senderName or full == sender then
                return u
            end
        end
    end
    return nil
end

function Vigil.PartyUnits()
    local units = { "player" }
    for i = 1, 4 do
        if UnitExists("party" .. i) then
            units[#units + 1] = "party" .. i
        end
    end
    return units
end

function Vigil.IsTrackedPartyGUID(guid)
    if not guid then return false end
    for _, u in ipairs(Vigil.PartyUnits()) do
        if UnitGUID(u) == guid then return u end
    end
    return false
end

local function PlayerSpecID()
    if not GetSpecialization or not GetSpecializationInfo then return nil end
    local idx = GetSpecialization()
    if not idx then return nil end
    local specID = GetSpecializationInfo(idx)
    return specID
end

-- Reads our own talented cooldown for a spell. Returns nil if API blocked or spell not found.
-- C_Spell.GetSpellCooldownDuration is AllowedWhenTainted with no SecretWhen* flag, so callable in M+.
local function MyTalentedCD(spellID)
    if not C_Spell or not C_Spell.GetSpellCooldownDuration then return nil end
    local dur = C_Spell.GetSpellCooldownDuration(spellID, true)  -- ignoreGCD
    if not dur then return nil end
    if dur.HasSecretValues and dur:HasSecretValues() then return nil end
    if not dur.GetTotalDuration then return nil end
    local secs = dur:GetTotalDuration("RealTime")
    if secs and secs > 0 then return secs end
    return nil
end

-- Always cache our own loadout locally so /vigil status is meaningful and broadcasts can read it.
-- Computes per-spell talented CDs while we're at it.
function Vigil.Sync.CacheOwnLoadout()
    local specID = PlayerSpecID()
    if not specID then return nil end

    local _, class = UnitClass("player")
    if not class then return nil end

    local spellCSV = Vigil.GetActiveSpellsForSpec(specID, class)

    local guid = UnitGUID("player")
    if not guid then return specID, spellCSV, class end

    local spells, cooldowns = {}, {}
    if spellCSV and spellCSV ~= "" then
        for idStr in spellCSV:gmatch("([^,]+)") do
            local id = tonumber(idStr)
            if id then
                spells[id] = true
                local cd = MyTalentedCD(id)
                if not cd then
                    local entry = Vigil.Spells[id]
                    cd = entry and entry.baseCooldown or nil
                end
                if cd and cd > 0 then cooldowns[id] = cd end
            end
        end
    end

    Vigil.Cache[guid] = {
        unit = "player",
        name = UnitName("player"),
        class = class,
        specID = specID,
        spells = spells,
        cooldowns = cooldowns,
    }

    return specID, spellCSV, class
end

function Vigil.Sync.Broadcast(force)
    local specID = Vigil.Sync.CacheOwnLoadout()
    if not specID then return end

    if not IsInGroup or not IsInGroup() then return end
    local now = GetTime()
    if not force and (now - lastLoadoutBroadcast) < LOADOUT_THROTTLE then return end

    local guid = UnitGUID("player")
    local cached = guid and Vigil.Cache[guid] or nil
    if not cached then return end

    local parts = {}
    for id in pairs(cached.spells) do
        local cd = (cached.cooldowns and cached.cooldowns[id])
                   or (Vigil.Spells[id] and Vigil.Spells[id].baseCooldown)
                   or 0
        parts[#parts + 1] = id .. "=" .. math.floor(cd)
    end
    table.sort(parts)  -- deterministic order

    local payload = "L:" .. specID .. ":" .. table.concat(parts, ",")
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "PARTY")
        lastLoadoutBroadcast = now
    end
end

-- Fire-and-forget cast notification. Called from the player's own UNIT_SPELLCAST_SUCCEEDED
-- handler — that event still fires for the player token (only party tokens are restricted).
function Vigil.Sync.NotifyOwnCast(spellID)
    if not spellID then return end
    local entry = Vigil.Spells[spellID]
    if not entry then return end
    if not IsInGroup or not IsInGroup() then return end

    local guid = UnitGUID("player")
    local cached = guid and Vigil.Cache[guid] or nil
    local cd = (cached and cached.cooldowns and cached.cooldowns[spellID])
               or entry.baseCooldown
               or 0
    if cd <= 0 then return end

    local payload = "C:" .. spellID .. ":" .. math.floor(cd)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "PARTY")
    end
end

local function handleLoadout(body, sender)
    local specStr, spellsBody = strsplit(":", body, 2)
    local specID = tonumber(specStr)
    if not specID then return end

    local unit = Vigil.ResolveUnitFromSender(sender)
    if not unit then return end
    local guid = UnitGUID(unit)
    if not guid then return end

    local _, class = UnitClass(unit)
    local spells, cooldowns = {}, {}
    if spellsBody and spellsBody ~= "" then
        for entry in spellsBody:gmatch("([^,]+)") do
            local idStr, cdStr = strsplit("=", entry)
            local id = tonumber(idStr)
            local cd = tonumber(cdStr)
            if id then
                spells[id] = true
                if cd and cd > 0 then cooldowns[id] = cd end
            end
        end
    end

    Vigil.Cache[guid] = {
        unit = unit,
        name = UnitName(unit),
        class = class,
        specID = specID,
        spells = spells,
        cooldowns = cooldowns,
    }

    if Vigil.Display and Vigil.Display.Refresh then
        Vigil.Display.Refresh()
    end
end

local function handleCast(body, sender)
    local idStr, cdStr = strsplit(":", body)
    local spellID = tonumber(idStr)
    local duration = tonumber(cdStr)
    if not spellID or not duration or duration <= 0 then return end

    local entry = Vigil.Spells[spellID]
    if not entry then return end

    local unit = Vigil.ResolveUnitFromSender(sender)
    if not unit then return end
    local sourceGUID = UnitGUID(unit)
    if not sourceGUID then return end

    -- Ensure cache exists (sender may not have broadcast loadout yet).
    Vigil.Cache[sourceGUID] = Vigil.Cache[sourceGUID] or {
        unit = unit,
        name = UnitName(unit),
        class = select(2, UnitClass(unit)),
        specID = nil,
        spells = {},
        cooldowns = {},
    }
    local cached = Vigil.Cache[sourceGUID]
    cached.spells[spellID] = true
    cached.cooldowns = cached.cooldowns or {}
    cached.cooldowns[spellID] = duration  -- broadcast value is authoritative for next timer
    if cached.unit ~= unit then cached.unit = unit end

    Vigil.Timers[sourceGUID] = Vigil.Timers[sourceGUID] or {}
    Vigil.Timers[sourceGUID][spellID] = {
        startTime = GetTime(),
        duration = duration,
    }

    if VigilDB and VigilDB.debug then
        print(("|cff7fa6ffVigil dbg|r recv cast: %s cast %s (%d) for %ds"):format(
            unit, entry.name or "?", spellID, math.floor(duration)))
    end

    if Vigil.Display and Vigil.Display.OnTimerStart then
        Vigil.Display.OnTimerStart(sourceGUID, spellID)
    end
end

function Vigil.Sync.OnMessage(prefix, message, channel, sender)
    if prefix ~= PREFIX then return end
    if not message or message == "" then return end

    local kind, body = strsplit(":", message, 2)
    if not body then return end
    if kind == "L" then
        handleLoadout(body, sender)
    elseif kind == "C" then
        handleCast(body, sender)
    end
end

local function isTestGUID(guid)
    return type(guid) == "string" and guid:sub(1, 5) == "test-"
end

-- Drop cache/timer entries for players no longer in the party.
-- Test entries (GUIDs prefixed "test-") are always preserved so /vigil test data survives
-- self-prune triggered by Refresh / event handlers.
function Vigil.Sync.PruneRoster()
    local liveGUIDs = {}
    for _, u in ipairs(Vigil.PartyUnits()) do
        local g = UnitGUID(u)
        if g then liveGUIDs[g] = true end
    end
    for guid in pairs(Vigil.Cache) do
        if not liveGUIDs[guid] and not isTestGUID(guid) then
            Vigil.Cache[guid] = nil
        end
    end
    if Vigil.Timers then
        for guid in pairs(Vigil.Timers) do
            if not liveGUIDs[guid] and not isTestGUID(guid) then
                Vigil.Timers[guid] = nil
            end
        end
    end
end

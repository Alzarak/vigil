Vigil = Vigil or {}
Vigil.Display = Vigil.Display or {}

local ROW_HEIGHT = 36
local ROW_GAP = 4
local ICON_GAP = 2
local LABEL_WIDTH = 90
local CATEGORY_ORDER = { "INTERRUPT", "STUN", "ROOT", "DEFENSIVE", "EXTERNAL", "HEALING" }

local rootFrame
local rows = {}                 -- [unit] = rowFrame; rowFrame.icons[spellID] = button
local iconPool = {}             -- recycled buttons
local glowSoonThreshold = 10    -- seconds remaining at which icons glow

-- ---------- frame plumbing ----------

local function NewIconButton(parent)
    local btn = table.remove(iconPool)
    if not btn then
        btn = CreateFrame("Button", nil, parent)
        btn:SetSize(32, 32)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:SetDrawBling(false)
        btn.glow = btn:CreateTexture(nil, "OVERLAY")
        btn.glow:SetAllPoints()
        btn.glow:SetBlendMode("ADD")
        btn.glow:SetColorTexture(1, 1, 0.4, 0.35)
        btn.glow:Hide()
        btn:SetScript("OnEnter", function(self)
            if not self.spellID then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local entry = Vigil.GetSpellInfo(self.spellID)
            if entry then
                GameTooltip:SetText(entry.name)
                GameTooltip:AddLine(entry.category, 0.7, 0.7, 0.7)
                local t = Vigil.Timers[self.guid] and Vigil.Timers[self.guid][self.spellID]
                if t then
                    local remaining = math.max(0, (t.startTime + t.duration) - GetTime())
                    GameTooltip:AddLine(string.format("Ready in %.0fs", remaining), 1, 1, 1)
                else
                    GameTooltip:AddLine("Ready", 0.4, 1, 0.4)
                end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    btn:SetParent(parent)
    btn:Show()
    return btn
end

local function ReleaseIconButton(btn)
    btn:Hide()
    btn:ClearAllPoints()
    btn.spellID = nil
    btn.guid = nil
    btn.glow:Hide()
    if btn.cd then btn.cd:Clear() end
    iconPool[#iconPool + 1] = btn
end

local function NewRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icons = {}
    return row
end

-- Class color for the row label.
local function ClassColor(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 1, 1, 1
end

-- ---------- public API ----------

function Vigil.Display.Create()
    if rootFrame then return rootFrame end
    rootFrame = CreateFrame("Frame", "VigilFrame", UIParent)
    rootFrame:SetSize(360, 200)
    rootFrame:SetMovable(true)
    rootFrame:SetClampedToScreen(true)
    rootFrame:RegisterForDrag("LeftButton")
    rootFrame:SetScript("OnDragStart", function(self)
        if VigilDB and not VigilDB.locked then self:StartMoving() end
    end)
    rootFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        VigilDB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)

    -- Throttled OnUpdate: glow + sweep finished timers
    local accum = 0
    rootFrame:SetScript("OnUpdate", function(self, elapsed)
        accum = accum + elapsed
        if accum < 0.2 then return end
        accum = 0
        Vigil.Display.Tick()
    end)

    Vigil.Display.RestorePosition()
    Vigil.Display.ApplyLock()
    if VigilDB and VigilDB.enabled == false then rootFrame:Hide() end
    return rootFrame
end

function Vigil.Display.RestorePosition()
    if not rootFrame then return end
    local p = (VigilDB and VigilDB.position) or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 }
    rootFrame:ClearAllPoints()
    rootFrame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

function Vigil.Display.ApplyLock()
    if not rootFrame then return end
    if VigilDB and VigilDB.locked then
        rootFrame:EnableMouse(false)
    else
        rootFrame:EnableMouse(true)
    end
end

function Vigil.Display.Show()
    if not rootFrame then Vigil.Display.Create() end
    rootFrame:Show()
    if VigilDB then VigilDB.enabled = true end
    Vigil.Display.Refresh()
end

function Vigil.Display.Hide()
    if rootFrame then rootFrame:Hide() end
    if VigilDB then VigilDB.enabled = false end
end

function Vigil.Display.Toggle()
    if not rootFrame then Vigil.Display.Create() end
    if rootFrame:IsShown() then
        Vigil.Display.Hide()
    else
        Vigil.Display.Show()
    end
end

-- Stable per-spell sort: by category order, then by spellID.
local function SortSpells(a, b)
    local ea = Vigil.GetSpellInfo(a)
    local eb = Vigil.GetSpellInfo(b)
    if not ea or not eb then return (ea ~= nil) and (eb == nil) end
    local ia, ib = 99, 99
    for i, c in ipairs(CATEGORY_ORDER) do
        if c == ea.category then ia = i end
        if c == eb.category then ib = i end
    end
    if ia ~= ib then return ia < ib end
    return a < b
end

local function GetOrCreateRow(unit)
    local row = rows[unit]
    if not row then
        row = NewRow(rootFrame)
        rows[unit] = row
    end
    return row
end

function Vigil.Display.Refresh()
    if not rootFrame then return end

    -- Self-heal #1: WoW occasionally hides custom frames during loading screens or other
    -- UI transitions. If the user wants the display visible (enabled true) and something
    -- hid the rootFrame, re-Show it. This catches the "addon hides itself on dungeon entry"
    -- bug without needing to track every possible hide trigger.
    if VigilDB and VigilDB.enabled ~= false and not rootFrame:IsShown() then
        rootFrame:Show()
    end

    -- Self-heal #2: prune cache for any GUIDs no longer in the party. Catches the case
    -- where GROUP_LEFT / GROUP_ROSTER_UPDATE didn't fire on group dissolution and stale
    -- entries persist.
    if Vigil.Sync and Vigil.Sync.PruneRoster then
        Vigil.Sync.PruneRoster()
    end

    local testMode = Vigil.TestMode == true

    -- Solo or out-of-group: clear every row aggressively and bail.
    -- Bypassed in test mode so the user can position the frame and verify behavior solo.
    if not testMode and not (IsInGroup and IsInGroup()) then
        for _, row in pairs(rows) do
            for spellID, btn in pairs(row.icons) do
                ReleaseIconButton(btn)
                row.icons[spellID] = nil
            end
            row:Hide()
        end
        return
    end

    -- Render only party members who have broadcast Vigil sync (cache entry exists).
    -- Non-Vigil party members are silently omitted — we have no real data on them.
    -- In test mode, render fake "test1..test4" slots backed by injected cache entries
    -- with predictable GUIDs (test-1 .. test-4).
    local unitOrder
    if testMode then
        unitOrder = { "test1", "test2", "test3", "test4" }
    else
        unitOrder = { "party1", "party2", "party3", "party4" }
    end

    local yOffset = -8
    for _, unit in ipairs(unitOrder) do
        local row = rows[unit]
        local guid
        if testMode then
            guid = "test-" .. unit:match("(%d+)$")
        else
            guid = UnitExists(unit) and UnitGUID(unit) or nil
        end
        local cached = guid and Vigil.Cache[guid] or nil
        if not cached then
            -- No Vigil data for this slot (empty, or party member doesn't run Vigil).
            if row then
                for spellID, btn in pairs(row.icons) do
                    ReleaseIconButton(btn)
                    row.icons[spellID] = nil
                end
                row:Hide()
            end
        else
            row = GetOrCreateRow(unit)
            row:Show()
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", rootFrame, "TOPLEFT", 4, yOffset)
            row:SetPoint("TOPRIGHT", rootFrame, "TOPRIGHT", -4, yOffset)
            yOffset = yOffset - (ROW_HEIGHT + ROW_GAP)

            local name = cached.name or UnitName(unit) or unit
            local class = cached.class or select(2, UnitClass(unit))
            row.label:SetText(name)
            row.label:SetTextColor(ClassColor(class))

            -- Compose spell list: sync-known + any active timer.
            local spellSet = {}
            if cached.spells then
                for id in pairs(cached.spells) do
                    if Vigil.Spells[id] then spellSet[id] = true end
                end
            end
            local timers = Vigil.Timers[guid]
            if timers then
                for id in pairs(timers) do
                    if Vigil.Spells[id] then spellSet[id] = true end
                end
            end

            local ordered = {}
            for id in pairs(spellSet) do ordered[#ordered + 1] = id end
            table.sort(ordered, SortSpells)

            -- Reconcile icons: release ones we no longer want, place the rest.
            for spellID, btn in pairs(row.icons) do
                if not spellSet[spellID] then
                    ReleaseIconButton(btn)
                    row.icons[spellID] = nil
                end
            end

            local size = (VigilDB and VigilDB.iconSize) or 32
            local labelW = row.label:GetStringWidth() or 0
            local x = 4 + labelW + 8
            for _, spellID in ipairs(ordered) do
                local btn = row.icons[spellID]
                if not btn then
                    btn = NewIconButton(row)
                    btn.icon:SetTexture(Vigil.GetIcon(spellID))
                    row.icons[spellID] = btn
                end
                btn.spellID = spellID
                btn.guid = guid
                btn:SetSize(size, size)
                btn:ClearAllPoints()
                btn:SetPoint("LEFT", row, "LEFT", x, 0)
                x = x + size + ICON_GAP

                local t = timers and timers[spellID]
                if t then
                    btn.cd:SetCooldown(t.startTime, t.duration)
                    btn.icon:SetDesaturated(true)
                else
                    btn.cd:Clear()
                    btn.icon:SetDesaturated(false)
                    btn.glow:Hide()
                end
            end
        end
    end
end

-- Called when a new timer starts (from Sync.OnMessage cast handler); ensures the button
-- exists and applies the cooldown sweep without a full Refresh when possible.
function Vigil.Display.OnTimerStart(guid, spellID)
    if not rootFrame then return end
    local unit
    for _, u in ipairs({"party1","party2","party3","party4"}) do
        if UnitGUID(u) == guid then unit = u; break end
    end
    if not unit then return end
    local row = rows[unit]
    -- Either reconcile fully (covers new spell case) or just update existing button.
    if not row or not row.icons[spellID] then
        Vigil.Display.Refresh()
        return
    end
    local t = Vigil.Timers[guid][spellID]
    row.icons[spellID].cd:SetCooldown(t.startTime, t.duration)
    row.icons[spellID].icon:SetDesaturated(true)
end

-- Called ~5 Hz by OnUpdate; handles glow + cleanup of finished timers.
function Vigil.Display.Tick()
    local now = GetTime()
    local needsRefresh = false
    for guid, spellMap in pairs(Vigil.Timers) do
        for spellID, t in pairs(spellMap) do
            local remaining = (t.startTime + t.duration) - now
            if remaining <= 0 then
                spellMap[spellID] = nil
                needsRefresh = true
            else
                -- glow toggle
                local unit
                for _, u in ipairs({"party1","party2","party3","party4"}) do
                    if UnitGUID(u) == guid then unit = u; break end
                end
                local row = unit and rows[unit] or nil
                local btn = row and row.icons[spellID] or nil
                if btn then
                    if remaining <= glowSoonThreshold then
                        btn.glow:Show()
                    else
                        btn.glow:Hide()
                    end
                end
            end
        end
    end
    if needsRefresh then Vigil.Display.Refresh() end
end

Vigil = Vigil or {}

Vigil.SpecID = {
    PRIEST_DISC      = 256,
    PRIEST_HOLY      = 257,
    PRIEST_SHADOW    = 258,
    DRUID_BALANCE    = 102,
    DRUID_FERAL      = 103,
    DRUID_GUARDIAN   = 104,
    DRUID_RESTO      = 105,
    PALADIN_HOLY     = 65,
    PALADIN_PROT     = 66,
    PALADIN_RET      = 70,
    SHAMAN_RESTO     = 264,
    SHAMAN_ELE       = 262,
    SHAMAN_ENH       = 263,
    MONK_BREWMASTER  = 268,
    MONK_WINDWALKER  = 269,
    MONK_MISTWEAVER  = 270,
    EVOKER_DEVASTATION = 1467,
    EVOKER_PRESERVATION = 1468,
    EVOKER_AUGMENTATION = 1473,
}

-- Schema per CLAUDE.md: name, class, spec (nil = class-wide), category, baseCooldown, icon
-- icon left nil; populated lazily via C_Spell.GetSpellTexture (AllowedWhenTainted, no SecretWhen flag).
Vigil.Spells = {
    -- ===== EXTERNALS =====
    [33206]  = { name = "Pain Suppression",     class = "PRIEST",      spec = 256,  category = "EXTERNAL",  baseCooldown = 180 },
    [62618]  = { name = "Power Word: Barrier",  class = "PRIEST",      spec = 256,  category = "EXTERNAL",  baseCooldown = 180 },
    [102342] = { name = "Ironbark",             class = "DRUID",       spec = nil,  category = "EXTERNAL",  baseCooldown = 90  },
    [97462]  = { name = "Rallying Cry",         class = "WARRIOR",     spec = nil,  category = "EXTERNAL",  baseCooldown = 180 },
    [196718] = { name = "Darkness",             class = "DEMONHUNTER", spec = nil,  category = "EXTERNAL",  baseCooldown = 300 },
    [51052]  = { name = "Anti-Magic Zone",      class = "DEATHKNIGHT", spec = nil,  category = "EXTERNAL",  baseCooldown = 120 },
    [31821]  = { name = "Aura Mastery",         class = "PALADIN",     spec = 65,   category = "EXTERNAL",  baseCooldown = 180 },
    [116849] = { name = "Life Cocoon",          class = "MONK",        spec = 270,  category = "EXTERNAL",  baseCooldown = 120 },
    [1022]   = { name = "Blessing of Protection",  class = "PALADIN",  spec = nil,      category = "EXTERNAL",  baseCooldown = 300 },
    [6940]   = { name = "Blessing of Sacrifice",   class = "PALADIN",  spec = {65, 66}, category = "EXTERNAL",  baseCooldown = 120 },
    [204018] = { name = "Blessing of Spellwarding",class = "PALADIN",  spec = 66,       category = "EXTERNAL",  baseCooldown = 180 },
    [47788]  = { name = "Guardian Spirit",      class = "PRIEST",      spec = 257,  category = "EXTERNAL",  baseCooldown = 180 },
    [374227] = { name = "Zephyr",               class = "EVOKER",      spec = nil,  category = "EXTERNAL",  baseCooldown = 120 },
    [357170] = { name = "Time Dilation",        class = "EVOKER",      spec = 1468, category = "EXTERNAL",  baseCooldown = 60  },
    [378441] = { name = "Time Stop",            class = "EVOKER",      spec = 1468, category = "EXTERNAL",  baseCooldown = 60  },

    -- ===== HEALING CDs =====
    [740]    = { name = "Tranquility",          class = "DRUID",       spec = 105,  category = "HEALING",   baseCooldown = 180 },
    [64843]  = { name = "Divine Hymn",          class = "PRIEST",      spec = 257,  category = "HEALING",   baseCooldown = 180 },
    [98008]  = { name = "Spirit Link Totem",    class = "SHAMAN",      spec = 264,  category = "HEALING",   baseCooldown = 180 },
    [115310] = { name = "Revival",              class = "MONK",        spec = 270,  category = "HEALING",   baseCooldown = 180 },
    [363534] = { name = "Rewind",               class = "EVOKER",      spec = 1468, category = "HEALING",   baseCooldown = 180 },
    [33891]  = { name = "Incarnation: Tree of Life", class = "DRUID",  spec = 105,  category = "HEALING",   baseCooldown = 180 },
    [359816] = { name = "Dream Flight",         class = "EVOKER",      spec = 1468, category = "HEALING",   baseCooldown = 120 },
    [370960] = { name = "Emerald Communion",    class = "EVOKER",      spec = 1468, category = "HEALING",   baseCooldown = 180 },
    [265202] = { name = "Holy Word: Salvation", class = "PRIEST",      spec = 257,  category = "HEALING",   baseCooldown = 720 },
    [108280] = { name = "Healing Tide Totem",   class = "SHAMAN",      spec = 264,  category = "HEALING",   baseCooldown = 180 },
    [114052] = { name = "Ascendance",           class = "SHAMAN",      spec = 264,  category = "HEALING",   baseCooldown = 180 },

    -- ===== INTERRUPTS =====
    [1766]   = { name = "Kick",                 class = "ROGUE",       spec = nil,  category = "INTERRUPT", baseCooldown = 15  },
    [2139]   = { name = "Counterspell",         class = "MAGE",        spec = nil,  category = "INTERRUPT", baseCooldown = 24  },
    [57994]  = { name = "Wind Shear",           class = "SHAMAN",      spec = nil,  category = "INTERRUPT", baseCooldown = 12  },
    [6552]   = { name = "Pummel",               class = "WARRIOR",     spec = nil,  category = "INTERRUPT", baseCooldown = 15  },
    [96231]  = { name = "Rebuke",               class = "PALADIN",     spec = nil,  category = "INTERRUPT", baseCooldown = 15  },
    [15487]  = { name = "Silence",              class = "PRIEST",      spec = 258,  category = "INTERRUPT", baseCooldown = 45  },
    [47528]  = { name = "Mind Freeze",          class = "DEATHKNIGHT", spec = nil,        category = "INTERRUPT", baseCooldown = 15  },
    [221562] = { name = "Asphyxiate",           class = "DEATHKNIGHT", spec = {250, 252}, category = "STUN",      baseCooldown = 45  },
    [183752] = { name = "Disrupt",              class = "DEMONHUNTER", spec = nil,  category = "INTERRUPT", baseCooldown = 15  },
    [351338] = { name = "Quell",                class = "EVOKER",      spec = nil,  category = "INTERRUPT", baseCooldown = 24  },
    [116705] = { name = "Spear Hand Strike",    class = "MONK",        spec = {268, 269}, category = "INTERRUPT", baseCooldown = 15 },
    [119381] = { name = "Leg Sweep",            class = "MONK",        spec = nil,  category = "STUN",      baseCooldown = 60  },
    [106839] = { name = "Skull Bash",           class = "DRUID",       spec = 103,  category = "INTERRUPT", baseCooldown = 15  },
    [78675]  = { name = "Solar Beam",           class = "DRUID",       spec = 102,  category = "INTERRUPT", baseCooldown = 60  },
    [19577]  = { name = "Intimidation",         class = "HUNTER",      spec = nil,  category = "STUN",      baseCooldown = 60  },
    [147362] = { name = "Counter Shot",         class = "HUNTER",      spec = 254,  category = "INTERRUPT", baseCooldown = 24  },
    [187707] = { name = "Muzzle",               class = "HUNTER",      spec = 255,  category = "INTERRUPT", baseCooldown = 15  },
    [187650] = { name = "Freezing Trap",        class = "HUNTER",      spec = nil,  category = "STUN",      baseCooldown = 30  },
    [122]    = { name = "Frost Nova",           class = "MAGE",        spec = nil,  category = "ROOT",      baseCooldown = 30  },
    [113724] = { name = "Ring of Frost",        class = "MAGE",        spec = nil,  category = "STUN",      baseCooldown = 45  },

    -- ===== DEFENSIVES (seed set; combat-log will catch others as cast) =====
    [45438]  = { name = "Ice Block",            class = "MAGE",        spec = nil,  category = "DEFENSIVE", baseCooldown = 240 },
    [642]    = { name = "Divine Shield",        class = "PALADIN",     spec = nil,  category = "DEFENSIVE", baseCooldown = 300 },
    [61336]  = { name = "Survival Instincts",   class = "DRUID",       spec = nil,  category = "DEFENSIVE", baseCooldown = 180 },
    [186265] = { name = "Aspect of the Turtle", class = "HUNTER",      spec = nil,  category = "DEFENSIVE", baseCooldown = 180 },
    [31224]  = { name = "Cloak of Shadows",     class = "ROGUE",       spec = nil,  category = "DEFENSIVE", baseCooldown = 120 },
    [48792]  = { name = "Icebound Fortitude",   class = "DEATHKNIGHT", spec = nil,  category = "DEFENSIVE", baseCooldown = 180 },
    [48707]  = { name = "Anti-Magic Shell",     class = "DEATHKNIGHT", spec = nil,  category = "DEFENSIVE", baseCooldown = 60  },
    [49039]  = { name = "Lichborne",            class = "DEATHKNIGHT", spec = nil,  category = "DEFENSIVE", baseCooldown = 120 },
    [55233]  = { name = "Vampiric Blood",       class = "DEATHKNIGHT", spec = 250,  category = "DEFENSIVE", baseCooldown = 90  },
    [49028]  = { name = "Dancing Rune Weapon",  class = "DEATHKNIGHT", spec = 250,  category = "DEFENSIVE", baseCooldown = 120 },
    [198589] = { name = "Blur",                 class = "DEMONHUNTER", spec = 577,  category = "DEFENSIVE", baseCooldown = 60  },
    [196555] = { name = "Netherwalk",           class = "DEMONHUNTER", spec = 577,  category = "DEFENSIVE", baseCooldown = 180 },
    [187827] = { name = "Metamorphosis",        class = "DEMONHUNTER", spec = 581,  category = "DEFENSIVE", baseCooldown = 120 },
    [263648] = { name = "Soul Barrier",         class = "DEMONHUNTER", spec = 581,  category = "DEFENSIVE", baseCooldown = 30  },
    [204021] = { name = "Fiery Brand",          class = "DEMONHUNTER", spec = 581,  category = "DEFENSIVE", baseCooldown = 60  },
    [22812]  = { name = "Barkskin",             class = "DRUID",       spec = nil,  category = "DEFENSIVE", baseCooldown = 60  },
    [363916] = { name = "Obsidian Scales",      class = "EVOKER",      spec = nil,  category = "DEFENSIVE", baseCooldown = 150 },
    [109304] = { name = "Exhilaration",         class = "HUNTER",      spec = nil,  category = "DEFENSIVE", baseCooldown = 120 },
    [110959] = { name = "Greater Invisibility", class = "MAGE",        spec = 62,   category = "DEFENSIVE", baseCooldown = 120 },
    [235219] = { name = "Cold Snap",            class = "MAGE",        spec = 64,   category = "DEFENSIVE", baseCooldown = 270 },
    [414658] = { name = "Ice Cold",             class = "MAGE",        spec = nil,  category = "DEFENSIVE", baseCooldown = 180 },
    [243435] = { name = "Fortifying Brew",      class = "MONK",        spec = nil,  category = "DEFENSIVE", baseCooldown = 420 },
    [122470] = { name = "Touch of Karma",       class = "MONK",        spec = 269,  category = "DEFENSIVE", baseCooldown = 90  },
    [633]    = { name = "Lay on Hands",         class = "PALADIN",     spec = nil,  category = "DEFENSIVE", baseCooldown = 600 },
    [31850]  = { name = "Ardent Defender",      class = "PALADIN",     spec = 66,   category = "DEFENSIVE", baseCooldown = 90  },
    [86659]  = { name = "Guardian of Ancient Kings", class = "PALADIN", spec = 66,  category = "DEFENSIVE", baseCooldown = 300 },
    [31884]  = { name = "Avenging Wrath",       class = "PALADIN",     spec = {65, 70}, category = "DEFENSIVE", baseCooldown = 120 },
    [853]    = { name = "Hammer of Justice",    class = "PALADIN",     spec = nil,  category = "STUN",      baseCooldown = 60  },
    [8122]   = { name = "Psychic Scream",       class = "PRIEST",      spec = nil,  category = "STUN",      baseCooldown = 60  },
    [2094]   = { name = "Blind",                class = "ROGUE",       spec = nil,  category = "STUN",      baseCooldown = 120 },
    [192058] = { name = "Capacitor Totem",      class = "SHAMAN",      spec = nil,  category = "STUN",      baseCooldown = 60  },
    [51514]  = { name = "Hex",                  class = "SHAMAN",      spec = nil,  category = "STUN",      baseCooldown = 30  },
    [6789]   = { name = "Mortal Coil",          class = "WARLOCK",     spec = nil,  category = "STUN",      baseCooldown = 45  },
    [5484]   = { name = "Howl of Terror",       class = "WARLOCK",     spec = nil,  category = "STUN",      baseCooldown = 40  },
    [30283]  = { name = "Shadowfury",           class = "WARLOCK",     spec = nil,  category = "STUN",      baseCooldown = 60  },
    [5246]   = { name = "Intimidating Shout",   class = "WARRIOR",     spec = nil,  category = "STUN",      baseCooldown = 90  },
    [46968]  = { name = "Shockwave",            class = "WARRIOR",     spec = 73,   category = "STUN",      baseCooldown = 40  },
    [102359] = { name = "Mass Entanglement",    class = "DRUID",       spec = nil,  category = "ROOT",      baseCooldown = 30  },
    [51485]  = { name = "Earthgrab Totem",      class = "SHAMAN",      spec = nil,  category = "ROOT",      baseCooldown = 30  },
    [109248] = { name = "Binding Shot",         class = "HUNTER",      spec = nil,  category = "ROOT",      baseCooldown = 45  },
    [19236]  = { name = "Desperate Prayer",     class = "PRIEST",      spec = nil,  category = "DEFENSIVE", baseCooldown = 90  },
    [47585]  = { name = "Dispersion",           class = "PRIEST",      spec = 258,  category = "DEFENSIVE", baseCooldown = 120 },
    [5277]   = { name = "Evasion",              class = "ROGUE",       spec = nil,  category = "DEFENSIVE", baseCooldown = 120 },
    [1856]   = { name = "Vanish",               class = "ROGUE",       spec = nil,  category = "DEFENSIVE", baseCooldown = 120 },
    [108271] = { name = "Astral Shift",         class = "SHAMAN",      spec = nil,  category = "DEFENSIVE", baseCooldown = 90  },
    [104773] = { name = "Unending Resolve",     class = "WARLOCK",     spec = nil,  category = "DEFENSIVE", baseCooldown = 180 },
    [871]    = { name = "Shield Wall",          class = "WARRIOR",     spec = 73,   category = "DEFENSIVE", baseCooldown = 180 },
    [12975]  = { name = "Last Stand",           class = "WARRIOR",     spec = 73,   category = "DEFENSIVE", baseCooldown = 180 },
    [184364] = { name = "Enraged Regeneration", class = "WARRIOR",     spec = 72,   category = "DEFENSIVE", baseCooldown = 120 },
    [118038] = { name = "Die by the Sword",     class = "WARRIOR",     spec = 71,   category = "DEFENSIVE", baseCooldown = 120 },
}

local CLASS_TO_SPECS = {}
for _, id in pairs(Vigil.SpecID) do CLASS_TO_SPECS[id] = true end

-- Returns spells that a player of `specID` (and its class) can have.
-- Includes class-wide entries (spec = nil) and entries matching the spec.
-- We don't know the player's class from specID alone here; the caller passes class.
function Vigil.GetActiveSpellsForSpec(specID, class)
    local out = {}
    for spellID, entry in pairs(Vigil.Spells) do
        if entry.class == class then
            local s = entry.spec
            local specMatch
            if s == nil then
                specMatch = true
            elseif type(s) == "number" then
                specMatch = (s == specID)
            elseif type(s) == "table" then
                for _, v in ipairs(s) do
                    if v == specID then specMatch = true; break end
                end
            end
            if specMatch then
                out[#out + 1] = spellID
            end
        end
    end
    table.sort(out)
    return table.concat(out, ",")
end

-- Lazy icon lookup. C_Spell.GetSpellTexture is AllowedWhenTainted with no SecretWhen flag.
function Vigil.GetIcon(spellID)
    local entry = Vigil.Spells[spellID]
    if not entry then return nil end
    if entry.icon then return entry.icon end
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then entry.icon = tex end
        return tex
    end
    return nil
end

function Vigil.GetSpellInfo(spellID)
    return Vigil.Spells[spellID]
end

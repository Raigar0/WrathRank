local addonName, addon = ...
local db, profile
local scores, scoreCount, scoreWeights = {}, 0, nil
local baseWeights = {}

local statKeys = {
    str = "STRENGTH", agi = "AGILITY", sta = "STAMINA", int = "INTELLECT",
    spi = "SPIRIT", ap = "ATTACK_POWER", rap = "RANGED_ATTACK_POWER",
    sp = "SPELL_POWER", hit = "HIT_RATING", crit = "CRIT_RATING",
    haste = "HASTE_RATING", exp = "EXPERTISE_RATING", arp = "ARMOR_PENETRATION_RATING",
    mp5 = "MANA_REGENERATION", def = "DEFENSE_SKILL_RATING", dodge = "DODGE_RATING",
    parry = "PARRY_RATING", block = "BLOCK_RATING", blockvalue = "BLOCK_VALUE",
    resil = "RESILIENCE_RATING", spellpen = "SPELL_PENETRATION",
    dps = "DAMAGE_PER_SECOND", ohdps = "DAMAGE_PER_SECOND", rdps = "DAMAGE_PER_SECOND",
    armor = "ARMOR", fap = "FERAL_ATTACK_POWER",
}
for key, stat in pairs(statKeys) do statKeys[key] = "ITEM_MOD_" .. stat .. "_SHORT" end

local presets = {
    strength = { str = 1, ap = .4, crit = .5, haste = .4, hit = .7, exp = .7, arp = .5, dps = 3 },
    agility = { agi = 1, ap = .45, str = .4, crit = .6, haste = .5, hit = .8, exp = .7, arp = .5, dps = 3 },
    hunter = { agi = 1, ap = .45, rap = .45, int = .3, crit = .6, haste = .4, hit = .8, arp = .5, rdps = 3 },
    caster = { sp = 1, int = .25, spi = .2, crit = .55, haste = .65, hit = .85 },
    healer = { sp = 1, int = .7, spi = .5, mp5 = .8, haste = .55, crit = .35 },
    tank = { sta = 1, armor = .08, def = .8, dodge = .6, parry = .5, block = .3, blockvalue = .25 },
    -- WoWSims Wrath gear-picker defaults (see README for sources and adaptations).
    fury = { str = 2.72, agi = 1.82, ap = 1, exp = 2.55, hit = .79, crit = 2.12, haste = 1.72,
        arp = 2.17, armor = .03, dps = 6.29, ohdps = 3.58 },
    protection = { sta = 2.336, armor = .174, def = 3.305, dodge = 2.606, parry = 2.649, block = 1.32,
        blockvalue = 1.373, str = 1.555, agi = 2.771, ap = .32, hit = 1.432, exp = 1.44,
        crit = .925, haste = .431, arp = 1.055, dps = 6.081, ohdps = 0 },
    arcane = { sp = 1, int = .55, spi = .25, crit = .4, haste = .8, hit = .85 },
    assassination = { agi = 1.86, ap = 1, str = 1.14, crit = 1.6, haste = 1.48, hit = 1.47,
        exp = .98, arp = .84, dps = 2.94, ohdps = 2.45 },
    survival = { sta = .5, agi = 2.65, ap = 1, rap = 1, int = 1.1, crit = 1.5, haste = 1.39, hit = 2,
        arp = 1.32, rdps = 6.32 },
    enhancement = { agi = 1.59, ap = 1, int = 1.48, str = 1.1, sp = 1.13, crit = 1.72, haste = 1.98,
        hit = 1.38, arp = .48, dps = 5.21, ohdps = 2.21 },
    holypaladin = { int = .38, sp = 1, spi = .34, haste = .77, crit = .69 },
    demonology = { sp = 1, int = .25, spi = .55, crit = .45, haste = .65, hit = .85 },
    feral = { agi = 2.39, str = 2.40, ap = 1, fap = 16.5 / 14, crit = 2.23, haste = 1.83,
        hit = 2.51, exp = 2.44, arp = 2.08 },
    bear = { sta = 7.3021, armor = .5187, agi = 4.4974, dodge = 2.0196, def = 1.8171,
        str = 2.3786, ap = 1, exp = 2.6597, hit = 2.9282, crit = 1.5143, haste = 2.0983, arp = 1.584 },
    dktank = { sta = 1, armor = .05, def = .8, dodge = .7, parry = .58, str = .33, agi = .6, ap = .06,
        hit = .67, exp = .67, crit = .28, haste = .21, arp = .19, dps = 3.10, ohdps = 0 },
    protpaladin = { sta = 1.14, armor = .07, str = 1, agi = .62, ap = .26, sp = .13, exp = .69,
        hit = .79, crit = .30, haste = .17, arp = .04, block = .52, blockvalue = .28, dodge = .46,
        parry = .61, def = .54, dps = 3.33, ohdps = 0 },
    retribution = { str = 2.53, agi = 1.13, int = .15, sp = .32, hit = 2.37, crit = 1.17, haste = 1.56,
        mp5 = .05, ap = 1, arp = .76, exp = 1.80, dps = 7.33, ohdps = 0 },
    shadow = { int = .11, spi = .47, sp = 1, hit = .87, crit = .74, haste = 1.65 },
    discipline = { int = 2.73, spi = 1.63, sp = 1, crit = .75, haste = .28, mp5 = 2.05 },
    unholy = { str = 3.22, agi = .62, armor = .01, ap = 1, exp = 1.13, haste = 1.85, hit = 2.72,
        crit = 1.10, arp = .77, dps = 3.10, ohdps = 1.79 },
    elemental = { int = .22, sp = 1, hit = .85, crit = .67, haste = 1.29, mp5 = .08 },
    fire = { int = .48, spi = .42, sp = 1, hit = .38, crit = .58, haste = .94, mp5 = .09 },
    affliction = { int = .18, spi = .54, sp = 1, hit = .93, crit = .53, haste = .81, sta = .01 },
    balance = { int = .43, spi = .34, sp = 1, hit = .85, crit = .82, haste = .80 },
}

-- Positions 1-3 follow the Wrath talent tabs. Optional role presets come after them.
local classes = {
    WARRIOR = {name = "Warrior", fallback = "strength", {"Arms", "strength"}, {"Fury", "fury"}, {"Protection", "protection"}},
    PALADIN = {name = "Paladin", fallback = "strength", {"Holy", "holypaladin"}, {"Protection", "protpaladin"}, {"Retribution", "retribution"}},
    HUNTER = {name = "Hunter", fallback = "hunter", {"Beast Mastery", "hunter"}, {"Marksmanship", "hunter"}, {"Survival", "survival"}},
    ROGUE = {name = "Rogue", fallback = "agility", {"Assassination", "assassination"}, {"Combat", "agility"}, {"Subtlety", "agility"}},
    PRIEST = {name = "Priest", fallback = "caster", {"Discipline", "discipline"}, {"Holy", "healer"}, {"Shadow", "shadow"}},
    DEATHKNIGHT = {name = "Death Knight", fallback = "strength", {"Blood", "strength"}, {"Frost", "strength"}, {"Unholy", "unholy"}, {"Tank (any tree)", "dktank"}},
    SHAMAN = {name = "Shaman", fallback = "caster", {"Elemental", "elemental"}, {"Enhancement", "enhancement"}, {"Restoration", "healer"}},
    MAGE = {name = "Mage", fallback = "caster", {"Arcane", "arcane"}, {"Fire", "fire"}, {"Frost", "caster"}},
    WARLOCK = {name = "Warlock", fallback = "caster", {"Affliction", "affliction"}, {"Demonology", "demonology"}, {"Destruction", "caster"}},
    DRUID = {name = "Druid", fallback = "caster", {"Balance", "balance"}, {"Feral Combat", "feral"}, {"Restoration", "healer"}, {"Feral Combat (Bear)", "bear"}},
}

local function classProfile(token, tab, className, treeName)
    local class = classes[token]
    if not class then return end
    local tree = class[tab]
    className = className or class.name
    return {
        scale = tree and ((treeName or tree[1]) .. " " .. className) or (className .. " - general"),
        weights = presets[tree and tree[2] or class.fallback],
    }
end

local function detectProfile()
    local className, classToken = UnitClass("player")
    if not classes[classToken] then return end

    local group = GetActiveTalentGroup()
    local bestTab, bestName, bestPoints = nil, nil, 0
    for tab = 1, 3 do
        local name, _, points = GetTalentTabInfo(tab, false, false, group)
        if points and points > bestPoints then
            bestTab, bestName, bestPoints = tab, name, points
        elseif points == bestPoints then
            bestTab, bestName = nil, nil
        end
    end
    return classProfile(classToken, bestTab, className, bestName)
end

local function refreshProfile(invalidateScores)
    profile = (db.auto and detectProfile()) or (db.class and classProfile(db.class, db.tree)) or db
    if invalidateScores or scoreWeights ~= profile.weights then
        scores, scoreCount = {}, 0
    end
    if scoreWeights ~= profile.weights then
        scoreWeights = profile.weights
        baseWeights = {}
        for key, weight in pairs(scoreWeights) do
            if key ~= "dps" and key ~= "ohdps" and key ~= "rdps" and key ~= "fap" then
                baseWeights[statKeys[key]] = weight
            end
        end
    end
    if addon.refreshSettings then addon.refreshSettings() end
end

local slots = {
    INVTYPE_HEAD = {1}, INVTYPE_NECK = {2}, INVTYPE_SHOULDER = {3},
    INVTYPE_CHEST = {5}, INVTYPE_ROBE = {5}, INVTYPE_WAIST = {6},
    INVTYPE_LEGS = {7}, INVTYPE_FEET = {8}, INVTYPE_WRIST = {9}, INVTYPE_HAND = {10},
    INVTYPE_FINGER = {11, 12}, INVTYPE_TRINKET = {13, 14}, INVTYPE_CLOAK = {15},
    INVTYPE_WEAPONMAINHAND = {16}, INVTYPE_2HWEAPON = {16}, INVTYPE_WEAPON = {16, 17},
    INVTYPE_WEAPONOFFHAND = {17}, INVTYPE_SHIELD = {17}, INVTYPE_HOLDABLE = {17},
    INVTYPE_RANGED = {18}, INVTYPE_RANGEDRIGHT = {18}, INVTYPE_THROWN = {18}, INVTYPE_RELIC = {18},
}
local titanSlots = {16, 17}
local slotLabels = {
    [11] = "Ring 1", [12] = "Ring 2", [13] = "Trinket 1", [14] = "Trinket 2",
    [16] = "Main hand", [17] = "Off hand", [18] = "Ranged slot",
}

local scanner = CreateFrame("GameTooltip", "WrathRankScanTooltip", UIParent, "GameTooltipTemplate")

local function numberPattern(template, placeholder)
    local first, last
    if template then first, last = template:find(placeholder, 1, true) end
    if not first then return end
    local prefix = template:sub(1, first - 1):gsub("(%p)", "%%%1")
    local suffix = template:sub(last + 1):gsub("(%p)", "%%%1")
    return "^" .. prefix .. "([%d.,]+)" .. suffix .. "$"
end

local armorPattern = numberPattern(ARMOR_TEMPLATE, "%d")
local dpsPattern = numberPattern(DPS_TEMPLATE, "%.1f")

local function baseItem(link)
    local item = link:match("|H(item:%d+[:%d%-]*)|h") or link:match("^(item:%d+[:%d%-]*)$")
    if not item then return end
    -- Zero enchant and gem fields while preserving the random suffix and scaling data.
    return (item:gsub("^(item:%d+):%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*", "%1:0:0:0:0:0"))
end

local function scoreItem(item, slot, equipType)
    local cached = scores[item]
    if cached then return slot == 17 and cached.off or cached.main end
    local stats = GetItemStats(item)
    if not stats then return end
    local dpsWeight = profile.weights[slot == 18 and "rdps" or "dps"] or 0
    local offDpsWeight = profile.weights.ohdps or dpsWeight
    local fapWeight = slot ~= 18 and (profile.weights.fap or 0) or 0
    local score = 0
    for stat, weight in pairs(baseWeights) do
        score = score + weight * (stats[stat] or 0)
    end

    local armor = (profile.weights.armor or 0) ~= 0 and not stats.ITEM_MOD_ARMOR_SHORT and armorPattern
    local isWeapon = equipType:find("WEAPON", 1, true) or slot == 18 and equipType ~= "INVTYPE_RELIC"
    local weaponDps = isWeapon and stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
    local dps = (dpsWeight ~= 0 or (slot ~= 18 and offDpsWeight ~= 0) or fapWeight ~= 0)
        and isWeapon and not weaponDps and dpsPattern
    if armor or dps then
        scanner:SetOwner(UIParent, "ANCHOR_NONE")
        scanner:ClearLines()
        scanner:SetHyperlink(item)
        local lines = scanner:NumLines()
        for index = 2, lines do
            local line = _G["WrathRankScanTooltipTextLeft" .. index]
            local label = line and line:GetText()
            if label then
                local armorValue = armor and label:match(armor)
                local dpsValue = dps and label:match(dps)
                if armorValue then
                    score = score + profile.weights.armor * (tonumber((armorValue:gsub("[.,]", ""))) or 0)
                    armor = nil
                elseif dpsValue then
                    weaponDps = tonumber((dpsValue:gsub(",", ".")))
                    dps = nil
                end
            end
            if not armor and not dps then break end
        end
        scanner:Hide()
        if lines < 2 then return end
    end
    weaponDps = weaponDps or 0
    if fapWeight ~= 0 and isWeapon then
        -- Wrath derives Feral AP from weapon DPS above the level-60 baseline.
        local feralAP = stats.ITEM_MOD_FERAL_ATTACK_POWER_SHORT or math.max(0, math.floor((weaponDps - 54.8) * 14))
        score = score + fapWeight * feralAP
    end
    if scoreCount >= 256 then scores, scoreCount = {}, 0 end
    cached = { main = score + dpsWeight * weaponDps, off = score + offDpsWeight * weaponDps }
    scores[item], scoreCount = cached, scoreCount + 1
    return slot == 17 and cached.off or cached.main
end

local function equippedItem(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return nil, nil end
    local _, _, _, _, _, _, _, _, equipType = GetItemInfo(link)
    return baseItem(link) or false, equipType
end

local function canCompare(slot, candidateType, currentType, mainType, offItem, titanGrip)
    -- shortcut: compare same-layout replacements, revisit for swaps that change the weapon setup.
    if titanGrip and currentType == "INVTYPE_2HWEAPON" then return true end
    if slot == 16 then
        if candidateType == "INVTYPE_2HWEAPON" then
            return not offItem and (not currentType or currentType == "INVTYPE_2HWEAPON")
        end
        return currentType ~= "INVTYPE_2HWEAPON"
    elseif slot == 17 then
        if mainType == "INVTYPE_2HWEAPON" then return false end
        if candidateType == "INVTYPE_WEAPON" then
            return currentType == "INVTYPE_WEAPON" or currentType == "INVTYPE_WEAPONOFFHAND"
        end
    end
    return true
end

local function compare(tooltip, label, score, equippedScore, empty)
    local delta = score - equippedScore
    if math.abs(delta) < .05 then
        tooltip:AddDoubleLine(label, empty and "Empty (same score)" or "Same score", .8, .8, .8, .8, .8, .8)
        return
    end
    local change = string.format("%+.1f pts", delta)
    if equippedScore > 0 then
        change = change .. string.format(" (%+.1f%%)", delta * 100 / equippedScore)
    elseif empty then
        change = change .. " vs empty"
    end
    if delta > 0 then
        tooltip:AddDoubleLine(label, "Upgrade " .. change, .8, .8, .8, .3, 1, .4)
    else
        tooltip:AddDoubleLine(label, "Downgrade " .. change, .8, .8, .8, 1, .45, .45)
    end
end

local annotated = {}
local function annotate(tooltip)
    if not profile or not next(profile.weights) then return end
    local _, link = tooltip:GetItem()
    if not link or annotated[tooltip] == link then return end
    local item = baseItem(link)
    if not item then return end
    local _, _, _, _, requiredLevel, _, subType, _, equipType = GetItemInfo(link)
    local itemSlots = slots[equipType]
    if not itemSlots then return end
    local titanGrip = false
    if equipType == "INVTYPE_2HWEAPON" and IsSpellKnown(46917) then
        -- The Wrath auction weapon list provides localized subclass names.
        local _, axe, _, _, _, mace, _, _, sword = GetAuctionItemSubClasses(1)
        titanGrip = subType ~= nil and (subType == axe or subType == mace or subType == sword)
        if titanGrip then itemSlots = titanSlots end
    end
    local isEquipped = tooltip:IsEquippedItem()
    local scoreSlot = itemSlots[1]
    if isEquipped and #itemSlots == 2 and scoreSlot == 16
        and link == GetInventoryItemLink("player", 17) and link ~= GetInventoryItemLink("player", 16) then
        scoreSlot = 17
    end
    local score = scoreItem(item, scoreSlot, equipType)
    if not score then return end
    annotated[tooltip] = link
    local heading = "WrathRank (" .. profile.scale .. ")"
    local displayScore = string.format("%.1f pts", score)
    if #itemSlots == 2 and itemSlots[1] == 16 and profile.weights.ohdps
        and profile.weights.ohdps ~= (profile.weights.dps or 0) then
        displayScore = displayScore .. (scoreSlot == 17 and " (off hand)" or " (main hand)")
    end
    tooltip:AddDoubleLine(heading, displayScore, .4, .8, 1, .4, .8, 1)
    if isEquipped then return end
    if requiredLevel and requiredLevel > UnitLevel("player") then
        tooltip:AddLine("Requires a higher level to equip", 1, .45, .45)
        return
    end

    local mainItem, mainType, offItem, offType
    if itemSlots[1] == 16 or itemSlots[1] == 17 then
        mainItem, mainType = equippedItem(16)
        offItem, offType = equippedItem(17)
    end
    local compared = false
    for _, slot in ipairs(itemSlots) do
        local equipped, currentType
        if slot == 16 then
            equipped, currentType = mainItem, mainType
        elseif slot == 17 then
            equipped, currentType = offItem, offType
        else
            equipped, currentType = equippedItem(slot)
        end
        if (equipped == nil or (equipped and currentType))
            and (slot ~= 17 or mainItem == nil or mainType)
            and canCompare(slot, equipType, currentType, mainType, offItem, titanGrip) then
            local candidate = score
            if slot == 17 and itemSlots[1] == 16 then candidate = scoreItem(item, slot, equipType) end
            local current = 0
            if equipped then
                current = equipped == item and candidate or scoreItem(equipped, slot, currentType)
            end
            if current and candidate then
                compare(tooltip, slotLabels[slot] or "Equipped slot", candidate, current, equipped == nil)
                compared = true
            end
        end
    end
    if not compared then tooltip:AddLine("No comparable equipped slot", .65, .65, .65) end
end

local function say(message)
    DEFAULT_CHAT_FRAME:AddMessage("WrathRank: " .. message)
end

local function parseWeight(value)
    local weight = tonumber(value)
    if weight and weight == weight and math.abs(weight) <= 1000 then return weight end
end

local function copyWeights(weights)
    local copy = {}
    for key, value in pairs(weights) do
        local weight = statKeys[key] and parseWeight(value)
        if weight and (weight ~= 0 or key == "ohdps") then copy[key] = weight end
    end
    if not copy.dps and copy.ohdps == 0 then copy.ohdps = nil end
    return copy
end

local function setScale(mode, weights, class, tree)
    db.auto = mode == "auto"
    db.class, db.tree = class, tree
    if mode ~= "auto" and mode ~= "fixed" then db.scale, db.weights = mode, copyWeights(weights) end
    refreshProfile()
end

addon.statKeys = statKeys
addon.classes = classes
addon.classProfile = classProfile
addon.detectProfile = detectProfile
addon.parseWeight = parseWeight
addon.setScale = setScale
addon.say = say
function addon.getSettings() return db, profile end

SLASH_WRATHRANK1 = "/wrathrank"
SLASH_WRATHRANK2 = "/wr"
SlashCmdList.WRATHRANK = function(message)
    local command, args = message:lower():match("^%s*(%S*)%s*(.-)%s*$")
    if (command == "" or command == "options") and args == "" then
        addon.openSettings()
    elseif command == "auto" and args == "" then
        setScale("auto")
        say("Automatic scale: " .. profile.scale)
    elseif command == "preset" and presets[args] then
        setScale(args, presets[args])
        say("Loaded " .. args .. " starter weights.")
    elseif command == "set" then
        local key, value = args:match("^(%a+)%s+(%S+)$")
        local weight = parseWeight(value)
        if not statKeys[key] or not weight then
            say("Use /wr set <stat> <weight from -1000 to 1000>. Type /wr stats for stat names.")
            return
        end
        local weights = copyWeights(profile.weights)
        weights[key] = weight
        setScale("custom", weights)
        say(key .. " = " .. weight)
    elseif command == "stats" then
        local values = {}
        for key in pairs(statKeys) do
            local weight = profile.weights[key] or (key == "ohdps" and profile.weights.dps) or 0
            values[#values + 1] = key .. "=" .. weight
        end
        table.sort(values)
        say(profile.scale .. " weights")
        for index = 1, #values, 8 do
            say(table.concat(values, ", ", index, math.min(index + 7, #values)))
        end
    elseif command == "clear" and args == "" then
        setScale("none", {})
        say("Cleared weights. Type /wr auto to resume automatic scoring.")
    else
        say("/wr opens settings. /wr auto follows your active talents. /wr preset <name> loads a fixed preset.")
        say("/wr stats lists weights. /wr set <stat> <weight> changes one. /wr clear clears all weights.")
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if event ~= "ADDON_LOADED" then
        refreshProfile(event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LEVEL_UP")
        return
    end
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    if type(WrathRankDB) ~= "table" then WrathRankDB = { auto = true, scale = "none", weights = {} } end
    db = WrathRankDB
    if type(db.scale) ~= "string" then db.scale = "none" end
    db.weights = type(db.weights) == "table" and copyWeights(db.weights) or {}
    if db.auto == nil then db.auto = db.scale == "none" end
    if not classes[db.class] or not classes[db.class][db.tree] then db.class, db.tree = nil, nil end
    refreshProfile()
    for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
        tooltip:HookScript("OnTooltipSetItem", annotate)
        tooltip:HookScript("OnTooltipCleared", function(frame) annotated[frame] = nil end)
    end
end)

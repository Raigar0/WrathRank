assert(_VERSION == "Lua 5.1")
ARMOR_TEMPLATE = "%d Armor"
DPS_TEMPLATE = "(%.1f damage per second)"
SlashCmdList = {}
UIParent = {}
local equipped = {}
local items = {}
local messages = {}
local loader
local panel, openedPanel, menuItems
local widgets = {}
local className, classToken = "Warrior", "WARRIOR"
local trees = {"Arms", "Fury", "Protection"}
local activeGroup = 1
local builds = {{18, 53, 0}, {15, 5, 51}}
local hasTitanGrip = false
local level = 80
local statReads, tooltipScans = 0, 0

function UnitLevel(unit)
    assert(unit == "player")
    return level
end

function UnitClass(unit)
    assert(unit == "player")
    return className, classToken
end
function GetActiveTalentGroup() return activeGroup end
function GetTalentTabInfo(tab, inspect, pet, group)
    assert(not inspect and not pet and group == activeGroup)
    return trees[tab], "test icon", builds[group][tab], "test background", 100
end
function IsSpellKnown(id)
    assert(id == 46917)
    return hasTitanGrip
end
function GetAuctionItemSubClasses(category)
    assert(category == 1)
    return "Axes", "Zweihandäxte", "Bows", "Guns", "Maces", "Zweihandstreitkolben", "Polearms", "Swords", "Zweihandschwerter", "Staves"
end
function InterfaceOptions_AddCategory(category) panel = category end
function InterfaceOptionsFrame_OpenToCategory(category) openedPanel = category end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_EnableDropDown(menu) menu.enabled = true end
function UIDropDownMenu_DisableDropDown(menu) menu.enabled = false end
function UIDropDownMenu_SetSelectedValue(menu, value) menu.selected = value end
function UIDropDownMenu_SetText(menu, value) menu:SetText(value) end
function UIDropDownMenu_Initialize(menu, initialize) menu.initialize = initialize end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info) menuItems[info.value] = info end

DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }

local function newTooltip()
    return {
        lines = {},
        HookScript = function(self, key, fn) self[key] = fn end,
        GetItem = function(self) return "Test Item", self.link end,
        IsEquippedItem = function(self) return self.equipped end,
        AddDoubleLine = function(self, left, right) self.lines[#self.lines + 1] = {left, right} end,
        AddLine = function(self, left) self:AddDoubleLine(left) end,
    }
end

GameTooltip = newTooltip()
ItemRefTooltip = newTooltip()

local function newWidget(name)
    local widget = {
        events = {},
        SetPoint = function() end,
        SetWidth = function() end,
        SetHeight = function() end,
        SetAutoFocus = function() end,
        ClearFocus = function() end,
        SetFocus = function() end,
        SetText = function(self, value) self.text = value end,
        GetText = function(self) return self.text end,
        Hide = function(self) self.visible = false end,
        IsVisible = function(self) return self.visible end,
        SetScript = function(self, key, fn) self[key] = fn end,
        CreateFontString = function() return newWidget() end,
    }
    if name then widgets[name] = widget end
    return widget
end

function CreateFrame(kind, name)
    if kind == "Frame" and not name then
        loader = {
            events = {},
            RegisterEvent = function(self, event) self.events[event] = true end,
            UnregisterEvent = function(self, event) self.events[event] = nil end,
            SetScript = function(self, key, fn) self[key] = fn end,
        }
        return loader
    end
    if kind ~= "GameTooltip" then return newWidget(name) end
    return {
        SetOwner = function() end,
        ClearLines = function() end,
        Hide = function() end,
        NumLines = function(self) return self.lines end,
        SetHyperlink = function(_, link)
            tooltipScans = tooltipScans + 1
            local item = assert(items[link], link)
            _G[name .. "TextLeft2"] = { GetText = function() return item.line end }
            _.lines = item.pending and 1 or 2
        end,
    }
end

function GetInventoryItemLink(_, slot) return equipped[slot] end
function GetItemInfo(link)
    local id = link:match("item:(%d+)")
    local item = items["item:" .. id]
    return "Test Item", link, 4, 100, (item and item.requiredLevel) or 80, "", item and item.subType, 1, item and item.equipType
end
function GetItemStats(link)
    statReads = statReads + 1
    return items[link] and items[link].stats
end

local function item(id, equipType, stats, line, subType)
    local link = "item:" .. id
    items[link] = { equipType = equipType, stats = stats, line = line, subType = subType }
    return link
end

local function hover(link, tooltip)
    tooltip = tooltip or GameTooltip
    tooltip.lines = {}
    tooltip.link = link
    tooltip:OnTooltipCleared()
    tooltip:OnTooltipSetItem()
    return tooltip.lines
end

local function loadAddon()
    local addon = {}
    assert(loadfile("WrathRank/WrathRank.lua"))("WrathRank", addon)
    assert(loadfile("WrathRank/Options.lua"))("WrathRank", addon)
    return addon
end

local addon = loadAddon()
loader:OnEvent("ADDON_LOADED", "OtherAddon")
assert(not GameTooltip.OnTooltipSetItem)
loader:OnEvent("ADDON_LOADED", "WrathRank")
local command = SlashCmdList.WRATHRANK

local function event(name)
    assert(loader.events[name], name)
    loader:OnEvent(name)
end

local damageRing = item(20, "INVTYPE_FINGER", { ITEM_MOD_STRENGTH_SHORT = 40, ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 40 })
local tankRing = item(21, "INVTYPE_FINGER", { ITEM_MOD_STAMINA_SHORT = 40, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 30 })
equipped[11] = tankRing
event("PLAYER_ENTERING_WORLD")
local autoRows = hover(damageRing)
assert(autoRows[1][1] == "WrathRank (Fury Warrior)")
assert(autoRows[2][2] == "Upgrade +195.6 pts")
activeGroup = 2
event("ACTIVE_TALENT_GROUP_CHANGED")
autoRows = hover(damageRing)
assert(autoRows[1][1] == "WrathRank (Protection Warrior)")
assert(autoRows[2][2]:find("Downgrade -88.2 pts", 1, true))

builds[2] = {36, 36, 0}
event("PLAYER_TALENT_UPDATE")
assert(hover(damageRing)[1][1] == "WrathRank (Warrior - general)")
builds[2] = {52, 19, 0}
event("PLAYER_TALENT_UPDATE")
assert(hover(damageRing)[1][1] == "WrathRank (Arms Warrior)")
command("set str 2")
activeGroup = 1
event("ACTIVE_TALENT_GROUP_CHANGED")
assert(hover(damageRing)[1][1] == "WrathRank (custom)")
assert(hover(damageRing)[1][2] == "100.0 pts")
command("auto")
assert(hover(damageRing)[1][2] == "195.6 pts")

className, classToken = "Schamane", "SHAMAN"
trees = {"Elementar", "Verstärkung", "Wiederherstellung"}
builds[1] = {0, 0, 51}
event("PLAYER_ENTERING_WORLD")
local spellRing = item(22, "INVTYPE_FINGER", { ITEM_MOD_SPELL_POWER_SHORT = 20, ITEM_MOD_MANA_REGENERATION_SHORT = 10 })
assert(hover(spellRing)[1][1] == "WrathRank (Wiederherstellung Schamane)")
assert(hover(spellRing)[1][2] == "28.0 pts")

local ring = item(1, "INVTYPE_FINGER", { ITEM_MOD_SPELL_POWER_SHORT = 60 })
equipped[11] = item(2, "INVTYPE_FINGER", { ITEM_MOD_SPELL_POWER_SHORT = 40 })
equipped[12] = item(3, "INVTYPE_FINGER", { ITEM_MOD_SPELL_POWER_SHORT = 80 })
command("clear")
assert(#hover(ring) == 0)
command("preset caster")
local rows = hover(ring)
assert(rows[1][2] == "60.0 pts")
assert(rows[2][1] == "Ring 1" and rows[2][2] == "Upgrade +20.0 pts (+50.0%)")
assert(rows[3][1] == "Ring 2" and rows[3][2] == "Downgrade -20.0 pts (-25.0%)")
GameTooltip:OnTooltipSetItem()
assert(#rows == 3)
command("set sp 2")
command("set sp 1e999")
command("set nonsense 3")
command("set")
assert(WrathRankDB.weights.sp == 2)
assert(hover(ring, ItemRefTooltip)[1][2] == "120.0 pts")

local trinket = item(4, "INVTYPE_TRINKET", { ITEM_MOD_SPELL_POWER_SHORT = 10 })
assert(hover(trinket)[2][2] == "Upgrade +20.0 pts vs empty")
equipped[13] = "item:999"
assert(hover(trinket)[2][1] == "Trinket 2")

local randomRing = "|cff0070dd|Hitem:1:123:456:0:0:0:-5:23:80|h[Test]|h|r"
items["item:1:0:0:0:0:0:-5:23:80"] = { stats = { ITEM_MOD_SPELL_POWER_SHORT = 50 } }
assert(hover(randomRing)[1][2] == "100.0 pts")

local twoHander = item(5, "INVTYPE_2HWEAPON", {}, "(100.0 damage per second)")
equipped[16] = item(6, "INVTYPE_WEAPON", { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 25 })
equipped[17] = item(7, "INVTYPE_WEAPONOFFHAND", {}, "(20,5 damage per second)")
command("preset strength")
rows = hover(twoHander)
assert(rows[1][2] == "300.0 pts" and rows[2][1] == "No comparable equipped slot")
local sword = item(8, "INVTYPE_WEAPON", { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 30 })
rows = hover(sword)
assert(rows[2][1] == "Main hand" and rows[2][2] == "Upgrade +15.0 pts (+20.0%)")
assert(rows[3][1] == "Off hand" and rows[3][2]:find("Upgrade +28.5 pts", 1, true))
local bow = item(9, "INVTYPE_RANGEDRIGHT", {}, "(56.5 damage per second)")
assert(hover(bow)[1][2] == "0.0 pts")
command("preset hunter")
assert(hover(sword)[1][2] == "0.0 pts")
assert(hover(bow)[1][2] == "169.5 pts")

local shield = item(10, "INVTYPE_SHIELD", { ITEM_MOD_STAMINA_SHORT = 20 }, "1000 Armor")
command("preset tank")
assert(hover(shield)[1][2] == "100.0 pts")
equipped[16] = twoHander
equipped[17] = nil
assert(hover(shield)[2][1] == "No comparable equipped slot")
assert(hover(twoHander)[2][2] == "Same score")
assert(#hover(item(11, "", {})) == 0)

className, classToken = "Warrior", "WARRIOR"
trees = {"Arms", "Fury", "Protection"}
builds[1] = {18, 53, 0}
hasTitanGrip = true
command("auto")
local axe = item(30, "INVTYPE_2HWEAPON", { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 120 }, nil, "Zweihandäxte")
equipped[17] = item(31, "INVTYPE_2HWEAPON", { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 110 }, nil, "Zweihandschwerter")
local beforeWeapons = statReads
rows = hover(axe)
assert(rows[1][2] == "754.8 pts (main hand)")
assert(rows[2][1] == "Main hand" and rows[2][2] == "Upgrade +125.8 pts (+20.0%)")
assert(rows[3][1] == "Off hand" and rows[3][2]:find("Upgrade +35.8 pts", 1, true))
assert(statReads - beforeWeapons == 3)
GameTooltip.equipped = true
rows = hover(equipped[17])
assert(#rows == 1 and rows[1][2] == "393.8 pts (off hand)")
assert(#hover(damageRing) == 1)
GameTooltip.equipped = false
local polearm = item(32, "INVTYPE_2HWEAPON", { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 130 }, nil, "Polearms")
assert(hover(polearm)[2][1] == "No comparable equipped slot")
hasTitanGrip = false
assert(hover(axe)[2][1] == "No comparable equipped slot")

command("clear")
assert(#hover(ring) == 0)
command("set sp .5")
assert(hover(ring)[1][2] == "30.0 pts")
loadAddon()
loader:OnEvent("ADDON_LOADED", "WrathRank")
assert(hover(ring)[1][2] == "30.0 pts")

WrathRankDB = { scale = "caster", weights = { sp = 3 } }
addon = loadAddon()
loader:OnEvent("ADDON_LOADED", "WrathRank")
assert(hover(ring)[1][2] == "180.0 pts")
SlashCmdList.WRATHRANK("auto")
assert(hover(ring)[1][1] == "WrathRank (Fury Warrior)")
assert(WrathRankDB.weights.sp == 3)

local classes = {
    {"Warrior", "WARRIOR", {"Arms", "Fury", "Protection"}, {{"str", 1}, {"arp", 2.17}, {"def", 3.305}}},
    {"Paladin", "PALADIN", {"Holy", "Protection", "Retribution"}, {{"int", .38}, {"block", .52}, {"str", 2.53}}},
    {"Hunter", "HUNTER", {"Beast Mastery", "Marksmanship", "Survival"}, {{"rdps", 3}, {"arp", .5}, {"rdps", 6.32}}},
    {"Rogue", "ROGUE", {"Assassination", "Combat", "Subtlety"}, {{"haste", 1.48}, {"agi", 1}, {"exp", .7}}},
    {"Priest", "PRIEST", {"Discipline", "Holy", "Shadow"}, {{"mp5", 2.05}, {"int", .7}, {"hit", .87}}},
    {"Death Knight", "DEATHKNIGHT", {"Blood", "Frost", "Unholy"}, {{"str", 1}, {"dps", 3}, {"exp", 1.13}}},
    {"Shaman", "SHAMAN", {"Elemental", "Enhancement", "Restoration"}, {{"sp", 1}, {"int", 1.48}, {"mp5", .8}}},
    {"Mage", "MAGE", {"Arcane", "Fire", "Frost"}, {{"int", .55}, {"hit", .38}, {"sp", 1}}},
    {"Warlock", "WARLOCK", {"Affliction", "Demonology", "Destruction"}, {{"hit", .93}, {"spi", .55}, {"sp", 1}}},
    {"Druid", "DRUID", {"Balance", "Feral Combat", "Restoration"}, {{"sp", 1}, {"fap", 16.5 / 14}, {"mp5", .8}}},
}
for _, class in ipairs(classes) do
    className, classToken, trees = class[1], class[2], class[3]
    for tab = 1, 3 do
        builds[1] = {5, 5, 5}
        builds[1][tab] = 51
        event("PLAYER_TALENT_UPDATE")
        local stat, weight = unpack(class[4][tab])
        local _, current = addon.getSettings()
        assert(current.weights[stat] == weight, className .. " " .. trees[tab])
        assert(hover(ring)[1][1] == "WrathRank (" .. trees[tab] .. " " .. className .. ")")
    end
end

local mace = item(33, "INVTYPE_2HWEAPON", {}, "(64.8 damage per second)")
builds[1] = {0, 51, 0}
event("PLAYER_TALENT_UPDATE")
assert(hover(mace)[1][2] == "165.0 pts")
local previousReads, previousScans = statReads, tooltipScans
assert(hover(mace)[1][2] == "165.0 pts")
assert(statReads == previousReads and tooltipScans == previousScans)
event("PLAYER_TALENT_UPDATE")
assert(hover(mace)[1][2] == "165.0 pts" and statReads == previousReads)
event("PLAYER_LEVEL_UP")
assert(hover(mace)[1][2] == "165.0 pts" and statReads > previousReads)
items[mace].requiredLevel = 80
level = 79
assert(hover(mace)[2][1] == "Requires a higher level to equip")
level = 80
local uncached = item(34, "INVTYPE_2HWEAPON", {}, "(64.8 damage per second)")
items[uncached].pending = true
assert(#hover(uncached) == 0)
items[uncached].pending = false
assert(hover(uncached)[1][2] == "165.0 pts")
local first = item(500, "INVTYPE_HEAD", {})
assert(hover(first)[1][2] == "0.0 pts")
for index = 501, 757 do hover(item(index, "INVTYPE_HEAD", {})) end
previousReads = statReads
hover(first)
assert(statReads > previousReads)

local function getChoices(menu)
    menuItems = {}
    menu.initialize()
    return menuItems
end

local function choose(menu, value)
    local info = assert(getChoices(menu)[value], tostring(value))
    info.func(nil, info.arg1)
end

local function edit(stat, value)
    local box = widgets["WrathRankWeight_" .. stat]
    box:SetText(value)
    box:OnTextChanged(true)
end

SlashCmdList.WRATHRANK("")
assert(openedPanel == panel and panel.name == "WrathRank")
panel:OnShow()
for stat in pairs(addon.statKeys) do assert(widgets["WrathRankWeight_" .. stat], stat) end
local classMenu, treeMenu = widgets.WrathRankClassMenu, widgets.WrathRankTreeMenu
assert(classMenu.selected == "auto" and not treeMenu.enabled)
for _, class in ipairs(classes) do
    choose(classMenu, class[2])
    assert(treeMenu.enabled and treeMenu.selected == nil)
    local choices = getChoices(treeMenu)
    assert(#choices == ((class[2] == "DRUID" or class[2] == "DEATHKNIGHT") and 4 or 3))
    for tab = 1, 3 do
        assert(choices[tab].text == class[3][tab])
        choose(treeMenu, tab)
        local stat, weight = unpack(class[4][tab])
        assert(tonumber(widgets["WrathRankWeight_" .. stat]:GetText()) == tonumber(tostring(weight)))
    end
end
choose(classMenu, "WARRIOR")
panel.okay()
assert(WrathRankDB.auto and messages[#messages]:find("Choose a talent tree", 1, true))
choose(classMenu, "DRUID")
choose(treeMenu, 4)
assert(classMenu.selected == "DRUID" and treeMenu.selected == 4)
assert(WrathRankDB.auto)
panel.okay()
assert(WrathRankDB.class == "DRUID" and WrathRankDB.tree == 4 and not WrathRankDB.auto)
addon = loadAddon()
loader:OnEvent("ADDON_LOADED", "WrathRank")
panel:OnShow()
classMenu, treeMenu = widgets.WrathRankClassMenu, widgets.WrathRankTreeMenu
assert(classMenu.selected == "DRUID" and treeMenu.selected == 4)
local _, fixed = addon.getSettings()
assert(fixed.weights.agi == 4.4974)
event("ACTIVE_TALENT_GROUP_CHANGED")
assert(select(2, addon.getSettings()).weights == fixed.weights)
edit("agi", "-0.6")
edit("sta", "NaN")
panel.okay()
assert(WrathRankDB.class == "DRUID" and messages[#messages]:find("Stamina needs a number", 1, true))
panel.cancel()
assert(widgets.WrathRankWeight_agi:GetText() == "4.4974")
edit("agi", "-0.6")
edit("sta", "  ")
panel.okay()
assert(WrathRankDB.scale == "custom" and WrathRankDB.weights.agi == -.6 and WrathRankDB.weights.sta == nil)
panel.default()
panel.refresh()
assert(not WrathRankDB.auto and classMenu.selected == "auto" and not treeMenu.enabled)
panel.okay()
assert(WrathRankDB.auto and WrathRankDB.weights.agi == -.6)
print("WrathRank Lua 5.1 checks passed for all 30 trees, gear scoring, cache, and settings.")

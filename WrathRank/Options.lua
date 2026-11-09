local _, addon = ...
local panel = CreateFrame("Frame", "WrathRankOptions", InterfaceOptionsFramePanelContainer)
panel.name = "WrathRank"
panel:Hide()

local fields = {
    {"str", "Strength"}, {"agi", "Agility"}, {"sta", "Stamina"}, {"int", "Intellect"},
    {"spi", "Spirit"}, {"ap", "Attack power"}, {"rap", "Ranged attack power"}, {"sp", "Spell power"},
    {"hit", "Hit rating"}, {"crit", "Critical strike"}, {"haste", "Haste rating"}, {"exp", "Expertise"},
    {"arp", "Armor penetration"}, {"mp5", "Mana per 5 sec"}, {"def", "Defense rating"}, {"dodge", "Dodge rating"},
    {"parry", "Parry rating"}, {"block", "Block rating"}, {"blockvalue", "Block value"}, {"resil", "Resilience"},
    {"spellpen", "Spell penetration"}, {"armor", "Armor"}, {"dps", "Main-hand DPS"}, {"ohdps", "Off-hand DPS"},
    {"rdps", "Ranged weapon DPS"},
    {"fap", "Feral attack power"},
}
local classLabels = { auto = "Automatic", custom = "Custom weights", none = "No weights" }
local classChoices = {}
for token, class in pairs(addon.classes) do
    classLabels[token] = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or class.name
    classChoices[#classChoices + 1] = token
end
table.sort(classChoices, function(a, b) return classLabels[a] < classLabels[b] end)
table.insert(classChoices, 1, "custom")
table.insert(classChoices, 1, "auto")

local function text(label, font, x, y)
    local line = panel:CreateFontString(nil, "ARTWORK", font)
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
    line:SetText(label)
    return line
end

text("WrathRank", "GameFontNormalLarge", 16, 14)
local active = text("", "GameFontHighlightSmall", 16, 38)
text("Class or mode", "GameFontNormalSmall", 16, 53)
text("Talent tree", "GameFontNormalSmall", 198, 53)
text("Edit a weight to make a custom scale. Blank or 0 ignores a stat.", "GameFontHighlightSmall", 16, 98)
local status = text("", "GameFontHighlightSmall", 16, 373)

local classMenu = CreateFrame("Frame", "WrathRankClassMenu", panel, "UIDropDownMenuTemplate")
classMenu:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -65)
UIDropDownMenu_SetWidth(classMenu, 142)
local treeMenu = CreateFrame("Frame", "WrathRankTreeMenu", panel, "UIDropDownMenuTemplate")
treeMenu:SetPoint("TOPLEFT", panel, "TOPLEFT", 182, -65)
UIDropDownMenu_SetWidth(treeMenu, 142)

local boxes = {}
local selectedClass, selectedTree, dirty
local function selectMode(token, tab)
    selectedClass, selectedTree = token, tab
    UIDropDownMenu_SetSelectedValue(classMenu, token)
    UIDropDownMenu_SetText(classMenu, classLabels[token])
    UIDropDownMenu_SetSelectedValue(treeMenu, tab)
    local class = addon.classes[token]
    if class then
        UIDropDownMenu_EnableDropDown(treeMenu)
        UIDropDownMenu_SetText(treeMenu, tab and class[tab][1] or "Select a tree")
    else
        UIDropDownMenu_DisableDropDown(treeMenu)
        UIDropDownMenu_SetText(treeMenu, token == "auto" and "Active talents" or "--")
    end
end

local function showWeights(token, tab, weights)
    selectMode(token, tab)
    for key, box in pairs(boxes) do
        local weight = weights[key] or (key == "ohdps" and weights.dps) or 0
        box:SetText(tostring(weight))
    end
end

local function changed(message)
    dirty = true
    status:SetText(message or "Unsaved changes")
end

for index, field in ipairs(fields) do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    local x, y = 16 + column * 182, 117 + row * 19
    text(field[2], "GameFontHighlightSmall", x, y + 4)
    local box = CreateFrame("EditBox", "WrathRankWeight_" .. field[1], panel, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", panel, "TOPLEFT", x + 115, -y)
    box:SetWidth(52)
    box:SetHeight(19)
    box:SetAutoFocus(false)
    box:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            if selectedClass ~= "custom" then selectMode("custom") end
            changed()
        end
    end)
    box:SetScript("OnEnterPressed", box.ClearFocus)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnTabPressed", function(self)
        local nextIndex = (index - 1 + (IsShiftKeyDown() and -1 or 1)) % #fields + 1
        self:ClearFocus()
        boxes[fields[nextIndex][1]]:SetFocus()
    end)
    boxes[field[1]] = box
end

local function addChoice(label, value, selected, choose)
    local info = UIDropDownMenu_CreateInfo()
    info.text, info.value, info.checked = label, value, value == selected
    info.arg1, info.func = value, choose
    UIDropDownMenu_AddButton(info)
end

local function chooseClass(_, token)
    if token == selectedClass then return end
    local saved, current = addon.getSettings()
    if token == "auto" then
        local detected = addon.detectProfile()
        showWeights(token, nil, detected and detected.weights or {})
        changed()
    elseif token == "custom" then
        showWeights(token, nil, next(saved.weights) and saved.weights or current.weights)
        changed()
    else
        showWeights(token, nil, {})
        changed("Choose a talent tree")
    end
end

UIDropDownMenu_Initialize(classMenu, function()
    for _, token in ipairs(classChoices) do addChoice(classLabels[token], token, selectedClass, chooseClass) end
end)

local function chooseTree(_, tab)
    if tab == selectedTree then return end
    local chosen = addon.classProfile(selectedClass, tab)
    showWeights(selectedClass, tab, chosen.weights)
    changed()
end

UIDropDownMenu_Initialize(treeMenu, function()
    local class = addon.classes[selectedClass]
    if not class then return end
    for tab, tree in ipairs(class) do addChoice(tree[1], tab, selectedTree, chooseTree) end
end)

function panel.refresh()
    local saved, current = addon.getSettings()
    if not saved then return end
    active:SetText("Active scale: " .. current.scale)
    if dirty then return end
    local token = saved.auto and "auto" or saved.class or (saved.scale == "none" and "none" or "custom")
    showWeights(token, saved.tree, current.weights)
end

function panel.cancel()
    dirty = false
    status:SetText("")
    panel.refresh()
end

function panel.default()
    local detected = addon.detectProfile()
    showWeights("auto", nil, detected and detected.weights or {})
    changed()
end

local function apply()
    if not dirty then return true end
    local weights = {}
    if addon.classes[selectedClass] then
        if not selectedTree then return false, "Choose a talent tree" end
        addon.setScale("fixed", nil, selectedClass, selectedTree)
    elseif selectedClass == "custom" then
        for _, field in ipairs(fields) do
            local value = boxes[field[1]]:GetText()
            local weight = value:match("^%s*$") and 0 or addon.parseWeight(value)
            if not weight then
                local message = field[2] .. " needs a number between -1000 and 1000."
                status:SetText(message)
                return false, message
            end
            weights[field[1]] = weight
        end
        addon.setScale("custom", weights)
    else
        addon.setScale(selectedClass, weights)
    end
    panel.cancel()
    status:SetText("Settings saved")
    return true
end

function panel.okay()
    local ok, message = apply()
    if not ok then addon.say(message) end
end

local function button(label, x, onClick)
    local control = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    control:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -392)
    control:SetWidth(110)
    control:SetHeight(22)
    control:SetText(label)
    control:SetScript("OnClick", onClick)
end

button("Apply", 16, apply)
button("Clear weights", 133, function()
    showWeights("none", nil, {})
    changed()
end)

panel:SetScript("OnShow", panel.refresh)
InterfaceOptions_AddCategory(panel)

function addon.refreshSettings()
    if panel:IsVisible() then panel.refresh() end
end

function addon.openSettings()
    -- The first call can populate the AddOns list when the options frame was closed.
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end

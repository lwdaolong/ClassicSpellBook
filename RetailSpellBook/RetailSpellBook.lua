-- Create the main frame
local frame = CreateFrame("Frame", "RetailSpellBookFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(550, 525)
frame:SetPoint("CENTER", UIParent, "CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Title
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlightLarge")
frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
frame.title:SetText("Class and Race Spells")

-- ScrollFrame and ScrollBar
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

local scrollChild = CreateFrame("Frame")
scrollChild:SetSize(505, 490)
scrollFrame:SetScrollChild(scrollChild)

-- Set background texture for the scroll child frame
local bgTexture = scrollChild:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints(scrollChild)
bgTexture:SetTexture("Interface\\Spellbook\\Spellbook-Page-1")

-- Function to Update the Title
local function UpdateTitle(newTitle)
    frame.title:SetText(newTitle)
end

-- Function to filter spells by specialization
local function IsSpellInSpecialization(spellID)
    local specID = GetSpecialization()
    if specID then
        local specSpells = {C_ClassTalents.GetSpellsForSpecialization(specID)}
        for _, specSpellID in ipairs(specSpells) do
            if spellID == specSpellID then
                return true
            end
        end
    end
    return false
end

-- Function to filter talent spells
local function IsTalentSpell(spellID)
    local configID = C_ClassTalents.GetActiveConfigID()
    if configID then
        local treeID = C_Traits.GetConfigTreeID(configID)
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(nodeID)
            if nodeInfo and nodeInfo.activeEntry and nodeInfo.activeEntry.spellID == spellID then
                return true
            end
        end
    end
    return false
end

-- Tab buttons
local tabs = {"Spells", "Abilities", "Talents"}
local tabFrame = CreateFrame("Frame", nil, frame)
tabFrame:SetSize(100, 300)
tabFrame:SetPoint("RIGHT", frame, "RIGHT", 90, 0)  -- Adjusted X to 90 and Y to 0

for i, tabName in ipairs(tabs) do
    local tabButton = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    tabButton:SetSize(80, 30)
    tabButton:SetPoint("TOP", tabFrame, "TOP", 0, -((i - 1) * 35))
    tabButton:SetText(tabName)
    tabButton:SetScript("OnClick", function()
        UpdateTitle(tabName)
        UpdateSpellList(tabName)
    end)
end

-- Spell List Update Function
local function UpdateSpellList(filter)
    local yOffset = -25
    local xOffset = 85  -- Start 100px to the right
    local column = 0

    -- Clear any existing children
    for i, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        if skillLineInfo then
            local numSpells = skillLineInfo.numSpellBookItems
            for spellIndex = 1, numSpells do
                local spellBookIndex = spellIndex + skillLineInfo.itemIndexOffset - 1
                local spellInfo = C_SpellBook.GetSpellBookItemInfo(spellBookIndex, Enum.SpellBookSpellBank.Player)
                if spellInfo and spellInfo.name and spellInfo.itemType ~= Enum.SpellBookItemType.FutureSpell then
                    local showSpell = false
                    if filter == "Spells" then
                        showSpell = true
                    elseif filter == "Abilities" then
                        showSpell = IsSpellInSpecialization(spellInfo.spellID)
                    elseif filter == "Talents" then
                        showSpell = IsTalentSpell(spellInfo.spellID)
                    end

                    if showSpell then
                        local spellButton = CreateFrame("Button", nil, scrollChild, "SecureActionButtonTemplate, ActionButtonTemplate")
                        spellButton:SetSize(200, 40)
                        spellButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", xOffset, yOffset)

                        local spellIcon = spellButton:CreateTexture(nil, "BACKGROUND")
                        spellIcon:SetTexture(spellInfo.iconID)
                        spellIcon:SetSize(40, 40)  -- Adjusted icon size to 40x40
                        spellIcon:SetPoint("LEFT", spellButton, "LEFT", 5, 0)

                        local spellText = spellButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        spellText:SetText(spellInfo.name)
                        spellText:SetPoint("LEFT", spellIcon, "RIGHT", 10, 0)

                        -- Set the attributes for casting the spell
                        spellButton:SetAttribute("type", "spell")
                        spellButton:SetAttribute("spell", spellInfo.spellID)

                        -- Enable drag and drop
                        spellButton:RegisterForDrag("LeftButton")
                        spellButton:SetScript("OnDragStart", function(self)
                            C_SpellBook.PickupSpellBookItem(spellBookIndex, Enum.SpellBookSpellBank.Player)
                        end)

                        -- Tooltip
                        spellButton:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetSpellBookItem(spellBookIndex, Enum.SpellBookSpellBank.Player)
                            GameTooltip:Show()
                        end)
                        spellButton:SetScript("OnLeave", function(self)
                            GameTooltip:Hide()
                        end)

                        column = column + 1
                        if column % 2 == 0 then
                            xOffset = 85  -- Offset for the new row
                            yOffset = yOffset - 50  -- Adjusted for icon size 40x40
                        else
                            xOffset = 310  -- Second column offset
                        end
                    end
                end
            end
        end
    end
end

-- Event Handler to Ensure Proper Loading
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        UpdateSpellList("Spells")
    end
end)

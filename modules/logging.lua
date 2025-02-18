---@class NercLibPrivate : NercLib
local NercLib = _G.NercLib

---@enum (key) LogLevel
local LOGGING_LEVEL_COLOR = {
    DEBUG = CreateColor(0.7, 0.8, 0.9),
    INFO = CreateColor(0.2, 0.8, 0.2),
    WARN = CreateColor(1.0, 1.0, 0.0),
    ERROR = CreateColor(1.0, 0.0, 0.0),
}
local TIMESTAMP_COLOR = CreateColor(0.5, 0.5, 0.5)

---@param addon NercLibAddon
function NercLib:AddLoggingModule(addon)
    local loggingWindow
    ---@class Logging
    local Logging = addon:GetModule("Logging")
    local Text = addon:GetModule("Text")

    local function FormatLogMessage(messageInfo)
        local color = LOGGING_LEVEL_COLOR[messageInfo.level]
        return string.format("[%s] %s", Text:WrapTextInColor(messageInfo.timestamp, TIMESTAMP_COLOR),
            Text:WrapTextInColor(messageInfo.message, color))
    end

    local function UpdateLogText()
        if not loggingWindow then
            return
        end

        print("update log text")

        local logText = ""
        local levels = loggingWindow.enabledFilters
        local levelCount = 0
        for _, _ in pairs(levels) do
            levelCount = levelCount + 1
        end

        local searchText = loggingWindow.searchFilter
        local totalLines = 0
        local startIndex = math.max(1, #loggingWindow.lines - 1000 + 1)
        for i = startIndex, #loggingWindow.lines do
            local line = loggingWindow.lines[i]
            if (levelCount == 0 or levels[line.level]) and (searchText == "" or string.find(line.message:lower(), searchText:lower())) then
                logText = logText .. FormatLogMessage(line) .. "\n"
                totalLines = totalLines + 1
            end
        end

        loggingWindow.lineCount:SetText(string.format("#%d", totalLines))
        loggingWindow.scrollChild:SetText(logText)
    end

    local function CreateLoggingWindow()
        loggingWindow = CreateFrame("Frame", nil, UIParent, "DefaultPanelTemplate")
        loggingWindow:SetSize(500, 200)
        loggingWindow:SetMovable(true)
        loggingWindow:EnableMouse(true)
        loggingWindow:RegisterForDrag("LeftButton")
        loggingWindow:SetScript("OnMouseDown", function(self)
            if not self.NineSlice.TopEdge:IsMouseOver() then
                return
            end
            self:StartMoving()
        end)
        loggingWindow:SetScript("OnMouseUp", loggingWindow.StopMovingOrSizing)
        loggingWindow:SetClampedToScreen(true)
        loggingWindow:SetFrameStrata("FULLSCREEN")
        loggingWindow:SetTitle(addon.name .. " Logging")
        loggingWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, 5)
        loggingWindow:SetResizable(true)
        loggingWindow.lines = {}

        local resizeButton = CreateFrame("Button", nil, loggingWindow)
        resizeButton:SetPoint("BOTTOMRIGHT", -3, 4)
        resizeButton:SetSize(12, 12)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        local lineCount = loggingWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lineCount:SetPoint("BOTTOMRIGHT", resizeButton, "BOTTOMLEFT", -10, 0)
        lineCount:SetText("0")
        loggingWindow.lineCount = lineCount

        local scrollFrame = CreateFrame("ScrollFrame", nil, loggingWindow, "ScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", loggingWindow, "TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -25, 20)
        loggingWindow.scrollFrame = scrollFrame

        local textBox = CreateFrame("EditBox", nil, scrollFrame)
        textBox:SetSize(scrollFrame:GetSize())
        textBox:SetMultiLine(true)
        textBox:SetAutoFocus(false)
        textBox:SetFontObject("ChatFontNormal")
        scrollFrame:SetScrollChild(textBox)
        loggingWindow.scrollChild = textBox


        resizeButton:SetScript("OnMouseDown", function(button, mouseButton)
            if mouseButton == "LeftButton" then
                loggingWindow:StartSizing("BOTTOMRIGHT")
                button:GetHighlightTexture():Hide() -- more noticeable
            end
        end)
        resizeButton:SetScript("OnMouseUp", function(button)
            loggingWindow:StopMovingOrSizing()
            button:GetHighlightTexture():Show()
            textBox:SetWidth(scrollFrame:GetWidth())
        end)
        loggingWindow:Show()


        loggingWindow.enabledFilters = {}
        -- logging filter buttons
        local lastElement
        for level, _ in pairs(LOGGING_LEVEL_COLOR) do
            local checkbox = CreateFrame("CheckButton", nil, loggingWindow)
            checkbox:SetNormalAtlas("checkbox-minimal")
            checkbox:SetPushedAtlas("checkbox-minimal")
            checkbox:SetCheckedTexture("checkmark-minimal")
            checkbox:SetSize(20, 20)
            checkbox:SetChecked(true)
            checkbox:SetScript("OnClick", function(checkBoxFrame)
                loggingWindow.enabledFilters[level] = checkBoxFrame:GetChecked()
                UpdateLogText()
            end)

            checkbox.label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
            checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
            checkbox.label:SetText(level)
            checkbox.label:SetWidth(30)
            checkbox.label:SetJustifyH("LEFT")
            loggingWindow.enabledFilters[level] = true

            if lastElement then
                checkbox:SetPoint("TOPLEFT", lastElement, "TOPRIGHT", 35, 0)
            else
                checkbox:SetPoint("BOTTOMLEFT", loggingWindow, "BOTTOMLEFT", 5, 2)
            end
            checkbox:Show()
            lastElement = checkbox
        end




        loggingWindow.searchFilter = ""
        local searchBox = CreateFrame("EditBox", nil, loggingWindow, "InputBoxInstructionsTemplate")
        searchBox:SetSize(1, 18)
        searchBox:SetAutoFocus(false)
        searchBox:SetPoint("TOPLEFT", lastElement, "TOPRIGHT", 35, 0)
        searchBox:SetPoint("RIGHT", loggingWindow.lineCount, "RIGHT", -35, 0)
        searchBox.searchIcon = searchBox:CreateTexture(nil, "ARTWORK")
        searchBox.searchIcon:SetAtlas("common-search-magnifyingglass")
        searchBox.searchIcon:SetSize(10, 10)
        searchBox.searchIcon:SetPoint("LEFT", searchBox, "LEFT", 1, -1)

        local searchBoxClearButton = CreateFrame("Button", nil, searchBox)
        searchBoxClearButton:SetSize(10, 10)
        searchBoxClearButton:SetPoint("RIGHT", searchBox, "RIGHT", -3, 0)
        searchBoxClearButton:SetNormalAtlas("common-search-clearbutton")
        searchBoxClearButton:SetHighlightAtlas("common-roundhighlight")
        searchBoxClearButton:SetScript("OnClick", function()
            searchBox:SetText("")
            loggingWindow.searchFilter = ""
            UpdateLogText()
        end)

        searchBox:SetScript("OnTextChanged", function(self)
            print("search text changed")
            local Utils = addon:GetModule("Utils")
            Utils:DebounceChange(function()
                loggingWindow.searchFilter = self:GetText()
                print("search filter: " .. loggingWindow.searchFilter)
                UpdateLogText()
            end, 1)
        end)
    end


    local loggingWindowShown = false
    local function OpenLoggingWindow()
        if not loggingWindow then
            CreateLoggingWindow()
        end
        loggingWindow:Show()
        loggingWindowShown = true
    end

    local function CloseLoggingWindow()
        if loggingWindow then
            loggingWindow:Hide()
            loggingWindowShown = false
        end
    end

    local function ToggleLoggingWindow()
        if loggingWindowShown then
            CloseLoggingWindow()
        else
            OpenLoggingWindow()
        end
    end

    local function AddLogLine(message, level)
        if not loggingWindow then
            CreateLoggingWindow()
        end
        if not level then
            level = "DEBUG"
        end
        if not LOGGING_LEVEL_COLOR[level] then
            level = "DEBUG"
        end
        table.insert(loggingWindow.lines, { message = message, level = level, timestamp = date("%H:%M:%S") })
        C_Timer.After(0.1, function()
            loggingWindow.scrollFrame.ScrollBar:ScrollToEnd()
        end)
        UpdateLogText()
    end

    local SavedVars = addon:GetModule("SavedVars")

    function Logging:EnableLogging()
        SavedVars:SetVar("logging", true)
    end

    function Logging:DisableLogging()
        SavedVars:SetVar("logging", false)
        if loggingWindow then
            loggingWindow:Hide()
        end
    end

    ---@param message string
    ---@param level LogLevel
    function Logging:Log(message, level)
        if not SavedVars:GetVar("logging") then
            if loggingWindow then
                loggingWindow:Hide()
            end
            return
        end
        AddLogLine(message, level)
    end

    local SlashCommand = addon:GetModule("SlashCommand")
    SlashCommand:AddSlashCommand("log", ToggleLoggingWindow, "Toggle logging window")
    local loggingEnabled = SavedVars:GetVar("logging")
    if loggingEnabled then
        SlashCommand:AddSlashCommand("enableLogging", function() Logging:EnableLogging() end, "Enable logging")
        SlashCommand:AddSlashCommand("disableLogging", function() Logging:DisableLogging() end, "Disable logging")
    end
end

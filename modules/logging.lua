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


---@class LogEntryFrame : Frame
---@field message FontString

---@class LogMessageInfo
---@field message string
---@field timestamp string
---@field level LogLevel

---@param addon NercLibAddon
function NercLib:AddLoggingModule(addon)
    ---@class Logging
    ---@field lines LogMessageInfo[]
    local Logging = addon:GetModule("Logging")
    Logging.lines = {}

    local Text = addon:GetModule("Text")
    local Utils = addon:GetModule("Utils")
    local SavedVars = addon:GetModule("SavedVars")
    local SlashCommand = addon:GetModule("SlashCommand")


    local function UpdateWindowData()
        if not Logging.loggingWindow then return end
        local DP = Logging.loggingWindow.DataProvider
        local searchText = Logging.loggingWindow.searchFilter
        local enabledFilters = Logging.loggingWindow.enabledFilters
        DP:Flush()
        if #Logging.lines == 0 then
            return
        end
        if #Logging.lines < 1000 then
            ---@type LogMessageInfo[]
            local filtered = {}
            -- filter by search and selected log levels
            for _, line in ipairs(Logging.lines) do
                if not searchText or string.find(line.message, searchText) then
                    if enabledFilters[line.level] then
                        table.insert(filtered, line)
                    end
                end
            end
            DP:InsertTable(filtered)
            return
        end

        -- create a list of functions that check for the search and log level filters
        local funcList = {}
        for _, line in ipairs(Logging.lines) do
            table.insert(funcList, function()
                if not searchText or string.find(line.message, searchText) then
                    if enabledFilters[line.level] then
                        DP:Insert(line)
                    end
                end
            end)
        end
        Utils:BatchExecution(funcList)
    end

    local function CreateLoggingWindow()
        local loggingWindow = CreateFrame("Frame", nil, UIParent, "DefaultPanelTemplate")
        loggingWindow:SetSize(500, 200)
        loggingWindow:SetMovable(true)
        loggingWindow:EnableMouse(true)
        loggingWindow:RegisterForDrag("LeftButton")
        loggingWindow:SetResizable(true)
        loggingWindow:SetMinResize(200, 200)
        loggingWindow:SetMovable(true)
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

        local resizeButton = CreateFrame("Button", nil, loggingWindow, "PanelResizeButtonTemplate")
        resizeButton:SetPoint("BOTTOMRIGHT", -3, 4)
        resizeButton:SetSize(12, 12)
        resizeButton:Init(self, 200, 200, GetScreenWidth(), GetScreenHeight())

        local lineCount = loggingWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lineCount:SetPoint("BOTTOMRIGHT", resizeButton, "BOTTOMLEFT", -10, 0)
        lineCount:SetText("0")
        loggingWindow.lineCount = lineCount


        local scrollBox = CreateFrame("Frame", nil, loggingWindow, "WowScrollBoxList")
        scrollBox:SetPoint("TOPLEFT", loggingWindow, "TOPLEFT", 10, -30)
        scrollBox:SetPoint("BOTTOMRIGHT", -25, 20)
        loggingWindow.scrollBox = scrollBox

        local scrollBar = CreateFrame("EventFrame", nil, loggingWindow, "MinimalScrollBar")
        scrollBar:SetPoint("TOPLEFT", loggingWindow, "TOPRIGHT", 5, -5)
        scrollBar:SetPoint("BOTTOMLEFT", loggingWindow, "BOTTOMRIGHT", 5, 5)

        loggingWindow.DataProvider = CreateDataProvider()
        local scrollView = CreateScrollBoxListLinearView()
        loggingWindow.scrollView = scrollView
        scrollView:SetDataProvider(loggingWindow.DataProvider)

        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

        ---@param frame LogEntryFrame
        ---@param messageInfo LogMessageInfo
        local function Initializer(frame, messageInfo)
            local color = LOGGING_LEVEL_COLOR[messageInfo.level]
            local logMessage = string.format("[%s] %s", Text:WrapTextInColor(messageInfo.timestamp, TIMESTAMP_COLOR),
                Text:WrapTextInColor(messageInfo.message, color))
            frame.message:SetText(logMessage)
        end

        scrollView:SetElementInitializer("NercLibLoggingListEntryTemplate", Initializer)
        loggingWindow.DataProvider:InsertTable(Logging.lines)
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
                Utils:DebounceChange(function()
                    UpdateWindowData()
                end, 0.5)()
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
        searchBox:SetTextInsets(16, 5, 0, 0)
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
        end)

        searchBox:SetScript("OnTextChanged", function(searchBoxFrame)
            loggingWindow.searchFilter = searchBoxFrame:GetText()
            Utils:DebounceChange(function()
                UpdateWindowData()
            end, 0.5)()
        end)

        Logging.loggingWindow = loggingWindow
    end


    local function AddLogLine(messageInfo)
        if not Logging.loggingWindow then return end
        table.insert(Logging.lines, messageInfo)
        Utils:DebounceChange(function()
            UpdateWindowData()
        end, 0.5)()
    end

    local loggingWindowShown = false
    local function OpenLoggingWindow()
        if not Logging.loggingWindow then
            CreateLoggingWindow()
        end
        Logging.loggingWindow:Show()
        loggingWindowShown = true
    end

    local function CloseLoggingWindow()
        if Logging.loggingWindow then
            Logging.loggingWindow:Hide()
            loggingWindowShown = false
        end
    end

    function Logging:ToggleLoggingWindow()
        if loggingWindowShown then
            CloseLoggingWindow()
        else
            OpenLoggingWindow()
        end
    end

    function Logging:EnableLogging()
        SavedVars:SetVar("logging", true)
    end

    function Logging:DisableLogging()
        SavedVars:SetVar("logging", false)
        if Logging.loggingWindow then
            Logging.loggingWindow:Hide()
        end
    end

    ---@param message string
    ---@param level LogLevel?
    function Logging:Log(message, level)
        if not SavedVars:GetVar("logging") then
            if Logging.loggingWindow then
                Logging.loggingWindow:Hide()
            end
            return
        end
        if not level or not LOGGING_LEVEL_COLOR[level] then
            level = "DEBUG"
        end
        AddLogLine({
            message = message,
            timestamp = date("%H:%M:%S"),
            level = level
        })
    end

    SlashCommand:AddSlashCommand("log", function() Logging:ToggleLoggingWindow() end, "Toggle logging window")
    local loggingEnabled = SavedVars:GetVar("logging")
    if loggingEnabled then
        SlashCommand:AddSlashCommand("enableLogging", function() Logging:EnableLogging() end, "Enable logging")
        SlashCommand:AddSlashCommand("disableLogging", function() Logging:DisableLogging() end, "Disable logging")
    end
end

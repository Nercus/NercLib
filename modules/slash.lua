---@class NercLib
local NercLib = _G.NercLib


---@param addon NercLibAddon
function NercLib:AddSlashCommandModule(addon)
    ---@class SlashCommand
    local SlashCommand = addon:GetModule("SlashCommand")
    local Text = addon:GetModule("Text")

    local commandList = {} ---@type table<string, function>
    local commandHelpStrings = {} ---@type table<string, string>

    local addedTriggers = 1
    function SlashCommand:SetSlashTrigger(trigger)
        local GLOBAL_NAME = string.format("SLASH_%s%d", addon.name:upper(), addedTriggers)
        ---@diagnostic disable-next-line: no-unknown
        _G[GLOBAL_NAME] = trigger
        addedTriggers = addedTriggers + 1
    end

    local normalColor = CreateColor(1, 0.82, 0)
    local SlashCmdList = getglobal("SlashCmdList") ---@as table<string, function>
    local helpPattern = "|A:communities-icon-notification:8:8:2:-2|a %s - %s"
    function SlashCommand:PrintHelp()
        local addonVersion = C_AddOns.GetAddOnMetadata(addon.name, "Version")
        local titleString = string.format("%s %s", addon.name, addonVersion)
        Text:PrintUnformatted(Text:WrapTextInColor(titleString, normalColor))
        for command, help in pairs(commandHelpStrings) do
            help = Text:WrapTextInColor(help, normalColor)
            local helpString = helpPattern:format(command, help)
            Text:PrintUnformatted(helpString)
        end
    end

    function SlashCommand:SetDefaultAction(func)
        commandList["default"] = func
    end

    ---parse the full msg and split into the different arguments
    ---@param msg string
    local function SlashCommandHandler(msg)
        local args = {} ---@type table<number, string>
        for word in string.gmatch(msg, "[^%s]+") do
            table.insert(args, word)
        end
        local command = args[1]
        if commandList[command] then
            pcall(commandList[command], unpack(args))
        else
            local defaultAction = commandList["default"]
            if defaultAction then
                pcall(defaultAction, unpack(args))
            end
        end
    end

    SlashCmdList["addon"] = SlashCommandHandler

    ---Add a slash command to the list
    ---@param command string
    ---@param func function
    ---@param help string
    function SlashCommand:AddSlashCommand(command, func, help)
        if addedTriggers == 1 then
            error("You must set a slash trigger before adding commands")
        end
        commandList[command] = func
        commandHelpStrings[command] = help
    end

    local helpCommandEnabled = false
    function SlashCommand:EnableHelpCommand(command, description)
        if helpCommandEnabled then
            return
        end
        helpCommandEnabled = true
        SlashCommand:AddSlashCommand(command, function()
            SlashCommand:PrintHelp()
        end, description)
    end
end

---@meta

---@class NercUtilsAddon
---@field name string the name of the addon
---@field commandList table<string, function> a list of commands and their associated functions
---@field commandHelpStrings table<string, string> a list of commands and their associated help strings
---@field debugMenuTemplate table<AnyMenuEntry[]> a list of menu templates for the debug menu
---@field tests Test[] a list of tests that have been registered
---@field defaults table<string, any> a list of default values for the addon
---@field db table<string, any> the saved variables for the addon
---@field modules table<string, table> a list of modules that have been registered
---@field L table<string, string> a list of localization strings for the addon
---@field locale AceLocale.LocaleCode the locale for the addon
local NercUtilsAddon = {}

---@alias TestExpectations {ToBe: fun(_, expected: any), ToBeTruthy: fun(), ToBeFalsy: fun(), ToBeType: fun(_, expected: type)}

---@class Test
---@field name string The name of the test
---@field Expect fun(_, value: any): TestExpectations The function to call to expect a value
---@field Run fun() The function to call to run the test


---Initializes the saved variables for the addon
function NercUtilsAddon:InitDB() end

---Retrieves the default value for a given set of keys.
---@param ... string The keys to traverse to get the default value
---@return boolean | number | string | table
function NercUtilsAddon:GetDefault(...) end

---Set the default value for a given set of keys.
---@param ... string | number | boolean | table The last element is the value to save and the rest are keys where the value should be saved
function NercUtilsAddon:SetDefault(...) end

---Save a variable to the saved variables
---@param ... string | number | boolean | table The last element is the value to save and the rest are keys where the value should be saved
function NercUtilsAddon:SetVar(...) end

---Get a variable from the saved variables
---@param ... string The keys to traverse to get the value
---@return boolean | number | string | table | nil
function NercUtilsAddon:GetVar(...) end

---Delete a variable from the saved variables
---@param ... string The keys to traverse to delete the value
function NercUtilsAddon:DeleteVar(...) end

---Migrate a variable from one set of keys to another
---@param prevKeys string | string[]
---@param newKeys string | string[]
function NercUtilsAddon:MigrateVar(prevKeys, newKeys) end

---Debug a value to DevTools
---@param ... any The value to debug
function NercUtilsAddon:Debug(...) end

---Add an addon to the whitelist of addons to load in dev mode
---@param addonName string The name of the addon to add to the whitelist
function NercUtilsAddon:AddAddonToWhitelist(addonName) end

---Add a custom action to the debug menu should be a AnyMenuEntry
---@param menuTemplate AnyMenuEntry The menu template to add the action to
function NercUtilsAddon:AddDebugCustomDebugAction(menuTemplate) end

---Get the menu generator function for a given menu template
---@param menuTemplate AnyMenuEntry[]
---@return function
function NercUtilsAddon:GetGeneratorFunction(menuTemplate) end

---Generate a menu for a given parent frame and menu template
---@param parentFrame Region The parent frame to attach the menu to
---@param menuTemplate AnyMenuEntry[] The menu template to use for the menu
---@param options? MenuOptions The options to use for the menu
function NercUtilsAddon:GenerateMenu(parentFrame, menuTemplate, options) end

---Create a new test. Example usage:
-- Addon:Test("Test addition", function(test)
--     local sum = 1 + 1
--     test:Expect(sum):ToEqual(2)
-- end)

-- Addon:Test("Test frame showable", function(test)
--    MyFrame:Show()
--    test:Expect(MyFrame:IsShown()):ToBeTruthy()
-- end)
--
-- Addon:Test("Test is value saved persistently", function(test)
--    local sum = 1 + 1
--    test:SetVar("sum", sum)
--    test:Expect(Addon:GetVar("sum")):ToEqual(2)
-- end)
---@param name string
---@param func fun(test: Test)
function NercUtilsAddon:Test(name, func) end

---Get the number of tests that have been registered
---@return number
function NercUtilsAddon:GetNumberOfTests() end

---Get all tests that have been registered
---@return Test[]
function NercUtilsAddon:GetTests() end

---Run all registered tests
---@param onUpdate fun(success: boolean, result: string)
---@param onFinish fun(testErrors: table<string, boolean>)
function NercUtilsAddon:RunTests(onUpdate, onFinish) end

---Print a formatted message to the chat
---@param ... string
function NercUtilsAddon:Print(...) end

---Print a message to the chat without formatting
---@param ... string
function NercUtilsAddon:PrintUnformatted(...) end

---Wrap text in a color
---@param text string
---@param color ColorMixin
---@return string
function NercUtilsAddon:WrapTextInColor(text, color) end

---Generate a UUID in the format of 'xxxxxxxx-xxxx'
---@param prefix? string optional prefix to add to the UUID
---@return string UUID a UUID in the format of 'xxxxxxxx-xxxx' or 'prefix-xxxxxxxx-xxxx'
function NercUtilsAddon:GenerateUUID(prefix) end

---Set a slash command trigger for the addon
---@param trigger string the slash command trigger
---@param triggerIndex number a contineous number that is used to identify the trigger
function NercUtilsAddon:SetSlashTrigger(trigger, triggerIndex) end

---Print the help message for the addon
function NercUtilsAddon:PrintHelp() end

---Set the default action for the addon when no command is provided
---@param func function the function to call when no command is provided
function NercUtilsAddon:SetDefaultAction(func) end

---Parse the full msg and split into the different arguments
---@param msg string the message to parse
function NercUtilsAddon:SlashCommandHandler(msg) end

---Add a slash command to the list
---@param command string the command to add
---@param func function the function to call when the command is used
---@param help string the help message to display when the command is used
function NercUtilsAddon:AddSlashCommand(command, func, help) end

---Remove a slash command from the list
---@param command string the command to remove
function NercUtilsAddon:RemoveSlashCommand(command) end

---Enable the help command for the addon
function NercUtilsAddon:EnableHelpCommand() end

---Debounce a function call to prevent it from being called too frequently
---@param func fun()
---@param delay number
---@param onChange? fun() a function to call when the debounced function is called
---@return function
function NercUtilsAddon:DebounceChange(func, delay, onChange) end

---Batch the execution of a list of functions with a delay between each execution
---@param funcList fun()[]
---@param onUpdate fun(progress: integer, maxProgress: integer)?
---@param onFinish fun()?
function NercUtilsAddon:BatchExecution(funcList, onUpdate, onFinish) end

---Get a specific module by name, if the module is not found, it will be created
---@generic T
---@param name `T`
---@return T
function NercUtilsAddon:GetModule(name) end

---Get the addon by name, if the addon is not found, it will be created
---@generic T
---@param addonName `T`
---@param addonTable NercUtilsAddon
---@return T
function NercUtilsAddon:GetAddon(addonName, addonTable) end

---Register an event for a function to be called when the event is fired
---@param event WowEvent the event to register for
---@param func function the function to call when the event is fired
function NercUtilsAddon:RegisterEvent(event, func) end

---Unregister an event for a given function
---@param event WowEvent the event to unregister for
---@param func function the function to unregister for
function NercUtilsAddon:UnregisterEventForFunction(event, func) end

---Unregister an event for the addon
---@param event WowEvent the event to unregister for
function NercUtilsAddon:UnregisterEvent(event) end

-- -------------------------------------------------------------------------- --
--                                    Menu                                    --
-- -------------------------------------------------------------------------- --

---@alias MenuEntryType "button" | "title" | "checkbox" | "radio" | "divider" | "spacer" | "template" | "submenu"

---@class MenuEntry
---@field type MenuEntryType

---@class MenuButtonEntry : MenuEntry
---@field type "button"
---@field label string
---@field onClick fun()

---@class MenuTitleEntry : MenuEntry
---@field type "title"
---@field label string

---@class MenuCheckboxEntry : MenuEntry
---@field type "checkbox"
---@field label string
---@field isSelected fun(): boolean
---@field setSelected fun(isSelected: boolean)
---@field data number

---@class MenuRadioEntry : MenuEntry
---@field type "radio"
---@field label string
---@field isSelected fun(): boolean
---@field setSelected fun()
---@field data number

---@class MenuDividerEntry : MenuEntry
---@field type "divider"

---@class MenuSpacerEntry : MenuEntry
---@field type "spacer"

---@class MenuTemplateEntry : MenuEntry
---@field type "template"
---@field template string
---@field initializer fun(frame: Frame)

---@class MenuSubmenuEntry : MenuEntry
---@field type "submenu"
---@field entry AnyMenuEntry
---@field entries AnyMenuEntry[] | fun(): AnyMenuEntry[]


---@alias AnyMenuEntry MenuButtonEntry | MenuTitleEntry | MenuCheckboxEntry | MenuRadioEntry | MenuDividerEntry | MenuSpacerEntry | MenuTemplateEntry | MenuSubmenuEntry

---@class MenuOptions
---@field gridModeColumns? number

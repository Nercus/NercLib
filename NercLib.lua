local MAJOR, MINOR = "NercLib", 1
assert(LibStub, MAJOR .. " requires LibStub")

---@class NercLib
local NercLib = LibStub:NewLibrary(MAJOR, MINOR)
if not NercLib then return end

_G.NercLib = NercLib

---@alias DEFAULT_MODULES "Debug"|"Events"|"Menu"|"Options"|"SavedVars"|"SlashCommand"|"Tests"|"Text"|"Utils"
---@type table<string, NercLibAddon>
local addons = {}

---@param addonName string The name of the addon to create
---@param tableName string The saved variables to use for the addon
---@return NercLibAddon
function NercLib:CreateAddon(addonName, tableName)
    ---@class NercLibAddon
    local addon = {
        name = addonName,
        tableName = tableName,
        ---@type table<string, table>
        modules = {}
    }

    ---@param name string
    ---@return table
    function addon:CreateModule(name)
        local m = {}
        if (not self.modules) then
            self.modules = {}
        end
        self.modules[name] = m
        return m
    end

    ---@generic T
    ---@param name `T`|DEFAULT_MODULES
    ---@return T
    function addon:GetModule(name)
        if (not self.modules or not self.modules[name]) then
            return self:CreateModule(name)
        end
        return self.modules[name]
    end

    ---@cast self NercLibPrivate
    self:AddPersistenceModule(addon)
    self:AddEventsModule(addon)
    self:AddTextModule(addon)
    self:AddSlashCommandModule(addon)
    self:AddUtilsModule(addon)
    self:AddMenuModule(addon)
    self:AddTestsModule(addon)
    self:AddDebugModule(addon)
    self:AddOptionModule(addon)

    local Debug = addon:GetModule("Debug")
    addon.Debug = Debug.Debug


    --- Add localization
    local L = setmetatable({}, {
        __index = function(t, k)
            local v = tostring(k)
            --@do-not-package@
            if Debug.Debug then
                Debug:Debug("Missing localization for: " .. v)
            end
            --@end-do-not-package@
            rawset(t, k, v)
            return v
        end
    })
    addon.L = L
    addon.locale = GetLocale()


    addons[addonName] = addon
    return addon
end

---@generic T
---@param addonName T | string
---@return T
function NercLib:GetAddon(addonName)
    assert(addons[addonName], "Addon not found: " .. addonName)
    return addons[addonName]
end

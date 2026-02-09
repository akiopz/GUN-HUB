---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Core Module
-- 放置於: src/core.lua

local Core = {}

local getgenv = (getgenv or function() return _G end)
---@class GlobalEnv
local env_global = getgenv() --[[@as GlobalEnv]]

-- [[ 基礎環境定義 ]]
Core.load_func = (env_global.loadstring or env_global.load or loadstring or load)
Core.hookmetamethod = env_global.hookmetamethod or (getgenv and getgenv().hookmetamethod)
Core.newcclosure = env_global.newcclosure or (getgenv and getgenv().newcclosure) or function(f) return f end
Core.checkcaller = env_global.checkcaller or (getgenv and getgenv().checkcaller) or function() return false end
Core.getnamecallmethod = env_global.getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
Core.hookfunction = env_global.hookfunction or (getgenv and getgenv().hookfunction)
Core.Drawing = env_global.Drawing or (getgenv and getgenv().Drawing)
Core.gethui = env_global.gethui or (getgenv and getgenv().gethui) or function() return game:GetService("CoreGui") end
Core.identifyexecutor = env_global.identifyexecutor or env_global.getexecutorname or function() return "Unknown" end
Core.read_file = env_global.readfile or function(...) return nil end
Core.write_file = env_global.writefile or function(...) return false end
Core.is_file = env_global.isfile or function(...) return false end
Core.is_folder = env_global.isfolder or function(...) return false end
Core.make_folder = env_global.makefolder or function(...) return false end
Core.list_files = env_global.listfiles or function(...) return {} end

-- 跨執行器 API 兼容層
function Core.GetExecutorInfo()
    local name, version = "Unknown", "1.0"
    pcall(function()
        if env_global.identifyexecutor then
            name, version = env_global.identifyexecutor()
        elseif env_global.getexecutorname then
            name = env_global.getexecutorname()
        end
    end)
    return name, version
end

-- 服務獲取優化 (含 cloneref 支援)
function Core.get_service(name)
    local service = game:GetService(name)
    if env_global.cloneref then
        return env_global.cloneref(service)
    end
    return service
end

-- 常用的服務
Core.Players = Core.get_service("Players")
Core.RunService = Core.get_service("RunService")
Core.UserInputService = Core.get_service("UserInputService")
Core.HttpService = Core.get_service("HttpService")
Core.StarterGui = Core.get_service("StarterGui")
Core.LocalPlayer = Core.Players.LocalPlayer
Core.Camera = workspace.CurrentCamera

-- 通知函數
function Core.Notify(title, text, duration)
    pcall(function()
        Core.StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration or 5
        })
    end)
end

-- 安全執行包裹 (含自動通知)
function Core.SafeExecute(name, func, ...)
    local success, result = pcall(func, ...)
    if not success then
        local errMsg = tostring(result)
        warn("[Halol Error] " .. name .. ": " .. errMsg)
        -- 自動彈出 GUI 通知告知使用者
        pcall(function()
            Core.Notify("系統錯誤", name .. " 模組執行失敗，請檢查控制台 (F9)", 5)
        end)
    end
    return success, result
end

-- [[ 配置管理系統優化 ]]
local ConfigFolder = "射擊類/configs"
local ConfigCache = {}

function Core.SaveConfig(name, data)
    pcall(function()
        local json = Core.HttpService:JSONEncode(data)
        
        -- Dirty check: 僅在資料變動時寫入
        if ConfigCache[name] == json then return end
        
        if not Core.is_folder("射擊類") then Core.make_folder("射擊類") end
        if not Core.is_folder(ConfigFolder) then Core.make_folder(ConfigFolder) end
        
        Core.write_file(ConfigFolder .. "/" .. name .. ".json", json)
        ConfigCache[name] = json
    end)
end

function Core.LoadConfig(name)
    local path = ConfigFolder .. "/" .. name .. ".json"
    if Core.is_file(path) then
        local ok, data = pcall(function()
            local content = Core.read_file(path)
            ConfigCache[name] = content
            return Core.HttpService:JSONDecode(content)
        end)
        if ok then return data end
    end
    return nil
end

function Core.ListConfigs()
    if Core.is_folder(ConfigFolder) then
        local files = Core.list_files(ConfigFolder)
        local configs = {}
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(configs, name) end
        end
        return configs
    end
    return {}
end

-- [[ 功能註冊系統 (為 UI 做準備) ]]
Core.Features = {}
function Core.RegisterFeature(id, info)
    Core.Features[id] = {
        Name = info.Name or id,
        Description = info.Description or "",
        Category = info.Category or "Misc",
        Callback = info.Callback,
        Enabled = false
    }
    print("[Halol] 功能已註冊: " .. id)
end

function Core.ToggleFeature(id, state)
    local feature = Core.Features[id]
    if feature then
        feature.Enabled = (state ~= nil) and state or (not feature.Enabled)
        if feature.Callback then
            Core.SafeExecute("Feature:" .. id, feature.Callback, feature.Enabled)
        end
        return feature.Enabled
    end
    return false
end

return Core

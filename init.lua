---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol 射擊類功能啟動器 (模組化版本)
-- 放置於: 射擊類/init.lua

-- [[ 啟動最前端：立即回饋 ]]
print("========================================")
print("[Halol] 偵測到執行指令，正在初始化...")
local CURRENT_VERSION = "1.0.3"

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Halol 啟動中",
        Text = "版本: " .. CURRENT_VERSION .. " | 正在檢查更新...",
        Duration = 3
    })
end)

local getgenv = (getgenv or function() return _G end)
---@class GlobalEnv
---@field ManualConfig boolean?
---@field FastMode boolean?
---@field OptimizeMemory boolean?
---@field DisableAggressiveProtection boolean?
---@field DisableAdvancedHooks boolean?
local env_global = getgenv() --[[@as GlobalEnv]]

-- [[ 環境能力檢查 ]]
local function CheckEnvironment()
    local missing = {}
    if not readfile then table.insert(missing, "readfile") end
    if not listfiles then table.insert(missing, "listfiles") end
    if not isfile then table.insert(missing, "isfile") end
    
    if #missing > 0 then
        local msg = "執行器缺少關鍵函數: " .. table.concat(missing, ", ")
        warn("[Halol Critical] " .. msg)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "啟動失敗",
                Text = msg,
                Duration = 10
            })
        end)
        return false
    end
    return true
end

-- [[ 更新檢查機制 ]]
local function CheckForUpdates()
    local baseUrl = "https://raw.githubusercontent.com/akiopz/-ez/main/%E5%B0%84%E6%93%8A%E9%A1%9E/"
    local ok, onlineVersion = pcall(game.HttpGet, game, baseUrl .. "version.txt")
    
    if ok and onlineVersion and not onlineVersion:find("404") then
        onlineVersion = onlineVersion:gsub("%s+", "")
        if onlineVersion ~= CURRENT_VERSION then
            print("[Halol] 偵測到新版本: " .. onlineVersion .. " (當前: " .. CURRENT_VERSION .. ")")
            return true, onlineVersion
        end
    else
        print("[Halol] 無法獲取版本資訊或版本檔案不存在，跳過更新檢查。")
    end
    return false, CURRENT_VERSION
end

-- [[ 高效加載器 ]]
local ModuleCache = {}
local FORCE_UPDATE = false

local function LoadModule(path)
    if ModuleCache[path] then return ModuleCache[path] end
    
    local content
    local baseUrl = "https://raw.githubusercontent.com/akiopz/-ez/main/%E5%B0%84%E6%93%8A%E9%A1%9E/"
    
    -- 1. 智能路徑偵測 (僅在非強制更新時)
    if not FORCE_UPDATE then
        local possiblePaths = {
            "射擊類/" .. path,
            path,
            "workspace/射擊類/" .. path,
            "../" .. path
        }
        
        for _, p in ipairs(possiblePaths) do
            local ok, res = pcall(readfile, p)
            if ok and res and #res > 0 then
                print("[Halol] 從本地成功加載: " .. p)
                content = res
                break
            end
        end
    end

    -- 2. 遠端同步 (GitHub)
    if not content then
        local logMsg = FORCE_UPDATE and "[Halol] 正在強制更新模組: " or "[Halol] 本地找不到模組，嘗試從 GitHub 獲取: "
        print(logMsg .. path)
        
        local ok, res = pcall(game.HttpGet, game, baseUrl .. path)
        -- 增加 404 檢查
        if ok and res and #res > 0 and not res:find("404") then
            print("[Halol] 從 GitHub 成功加載: " .. path)
            content = res
            if writefile then 
                pcall(function()
                    if not isfolder("射擊類") then makefolder("射擊類") end
                    if not isfolder("射擊類/src") then makefolder("射擊類/src") end
                    writefile("射擊類/" .. path, res) 
                end)
            end
        else
            local errorType = (not ok or not res or #res == 0) and "連線失敗" or "檔案不存在 (404)"
            warn("[Halol Error] 無法從 GitHub 加載模組 (" .. errorType .. "): " .. path)
        end
    end
    
    if content then
        local func, err = loadstring(content)
        if func then
            local ok, result = pcall(func)
            if ok then
                ModuleCache[path] = result
                return result
            else
                warn("[Halol Runtime Error] 模組 " .. path .. " 執行出錯: " .. tostring(result))
            end
        else
            warn("[Halol Syntax Error] 模組 " .. path .. " 解析失敗: " .. tostring(err))
        end
    end
    return nil
end

-- [[ 極速啟動引擎 ]]
local function Main()
    if not CheckEnvironment() then return end
    
    -- 檢查更新
    local hasUpdate, newVersion = CheckForUpdates()
    if hasUpdate then
        FORCE_UPDATE = true
        print("[Halol] 發現新版本 " .. newVersion .. "，正在執行同步更新...")
    end

    local executor = "Unknown"
    pcall(function() executor = (identifyexecutor or getexecutorname)() end)
    print("[Halol] 當前執行器: " .. tostring(executor))
    
    -- [[ Zeus 專屬優化設定 ]]
    if tostring(executor):find("Zeus") then
        env_global.DisableAdvancedHooks = true -- Zeus 環境下 Hook 較不穩定，預設關閉
        env_global.AntiCheatBypass = false     -- 減少激進的繞過行為，優先保證不崩潰
        print("[Halol] 已套用 Zeus 穩定性優化配置")
    end
    env_global.FastMode = true
    env_global.OptimizeMemory = true
    
    -- 針對各類執行器預設最穩配置
    if not env_global.ManualConfig then
        env_global.DisableAggressiveProtection = false -- 啟用強化保護
        env_global.DisableAdvancedHooks = false        -- 啟用高級 Hook
    end

    -- 並行加載模組群
    local Core = LoadModule("src/core.lua")
    if not Core then 
        warn("[Halol Critical] 核心組件 (core.lua) 加載失敗，腳本停止執行。")
        return 
    end
    
    -- 優先初始化 GUI
    Core.CreateGUI()
    Core.Notify("Halol", "核心加載成功，正在啟動功能...", 2)
    
    local modules = {
        {"Protection", "src/protection.lua"},
        {"Combat", "src/combat.lua"},
        {"Visuals", "src/visuals.lua"},
        {"World", "src/world.lua"},
        {"Misc", "src/misc.lua"}
    }
    
    for _, modInfo in ipairs(modules) do
        task.spawn(function()
            local success, mod = pcall(LoadModule, modInfo[2])
            if success and mod and mod.Init then
                local ok, err = pcall(mod.Init, Core)
                if not ok then
                    warn("[Halol] 模組 " .. modInfo[1] .. " 初始化失敗: " .. tostring(err))
                end
            end
        end)
    end

    print("[Halol] 所有模組已發送加載請求。")
    print("========================================")
end

Main()

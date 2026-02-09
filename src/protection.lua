---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Protection Module
-- 放置於: src/protection.lua

local Protection = {}

function Protection.Init(Core)
    ---@class GlobalEnv
    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    local lp = Core.LocalPlayer
    local Camera = Core.Camera
    local hookmetamethod = Core.hookmetamethod
    local hookfunction = Core.hookfunction
    local newcclosure = Core.newcclosure
    local checkcaller = Core.checkcaller
    local getnamecallmethod = Core.getnamecallmethod
    local gethui = Core.gethui

    env_global.AntiCheatBypass = env_global.AntiCheatBypass or false
    env_global.AntiSpectate = env_global.AntiSpectate or false
    env_global.FakeName = env_global.FakeName or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("AntiCheatBypass", {
        Name = "防偵測繞過 (AC Bypass)",
        Category = "Protection",
        Callback = function(state)
            env_global.AntiCheatBypass = state
        end
    })

    Core.RegisterFeature("AntiSpectate", {
        Name = "反觀戰 (Anti-Spectate)",
        Category = "Protection",
        Callback = function(state)
            env_global.AntiSpectate = state
        end
    })

    Core.RegisterFeature("FakeName", {
        Name = "偽造名字 (Fake Name)",
        Category = "Protection",
        Callback = function(state)
            env_global.FakeName = state
        end
    })
    local ac_keywords_map = {}
    local ac_keywords_list = {
        "Anticheat", "Adonis", "Sentinel", "AC", "Detection", "Flag", "Log",
        "Watcher", "Checker", "Ban", "Kick", "Verify", "Protect", "Security",
        "Guardian", "Cerberus", "Bat", "Krampus", "Cyclops", "TrueSight", "Vanguard"
    }
    for _, word in ipairs(ac_keywords_list) do ac_keywords_map[word:lower()] = true end

    local function IsRealRequest()
        if not env_global.AntiCheatBypass then return true end
        if checkcaller and checkcaller() then return true end

        local stack = debug.traceback():lower()
        for word, _ in pairs(ac_keywords_map) do
            if stack:find(word) then return false end
        end

        local info = debug.getinfo(3)
        if info then
            local source = info.source
            if source and (source:find("Halol") or source:find("Combat")) then
                return true
            end
            local name = info.name and info.name:lower()
            if name and (name:find("check") or name:find("detect") or name:find("kick") or name:find("ban") or name:find("flag")) then
                return false
            end
        end
        return true
    end

    -- [[ 反觀戰邏輯 ]]
    task.spawn(function()
        while task.wait(1) do
            if env_global.AntiSpectate then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        -- 如果有玩家距離太近且視角正對著我，可能是觀戰或錄影
                        local dist = (player.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 10 then
                            Core.Notify("反觀戰警報", player.Name .. " 正在貼身觀察你！", 3)
                        end
                    end
                end
            end
        end
    end)
    local function SetupStealthProtection()
        if not hookfunction or env_global.DisableAggressiveProtection then return end

        -- 註釋掉高風險 Hook，避免直接導致崩潰
        --[[
        local oldGetGC
        oldGetGC = hookfunction(getgc, newcclosure(function(include_tables)
            local gc = oldGetGC(include_tables)
            if not checkcaller() then
                local new_gc = {}
                for i, v in pairs(gc) do
                    local is_mine = false
                    if type(v) == "function" then
                        local info = debug.getinfo(v)
                        if info and info.source and info.source:find("Halol") then
                            is_mine = true
                        end
                    elseif type(v) == "table" and (v == env_global) then
                        is_mine = true
                    end
                    if not is_mine then table.insert(new_gc, v) end
                end
                return new_gc
            end
            return gc
        end))
        ]]

        if env_global.identifyexecutor then
            local oldIdentify
            oldIdentify = hookfunction(env_global.identifyexecutor, newcclosure(function()
                if not checkcaller() then return "Roblox", "1.0" end
                return oldIdentify()
            end))
        end
        print("[Halol] 基礎隱蔽系統已啟動")
    end

    -- [[ 進階保護與偽裝 ]]
    local function SetupAdvancedProtection()
        if env_global.__HalolAdvancedProtectionActive then return end
        
        local executor, version = Core.GetExecutorInfo()
        
        -- 多層次防護判斷邏輯
        local capabilities = {
            Metatable = (hookmetamethod ~= nil),
            FunctionHook = (hookfunction ~= nil),
            CClosure = (newcclosure ~= nil),
            CallerCheck = (checkcaller ~= nil)
        }

        -- 如果是已知不穩定或限制較多的執行器，強制進入「相容模式」
        local isUnstable = executor:find("Solara") or executor:find("Velocity") or executor:find("Wave") or executor:find("Celery") or executor:find("Zeus")
        
        if isUnstable or env_global.DisableAdvancedHooks or not capabilities.Metatable then
            print("[Halol] 使用通用相容模式 (Executor: " .. executor .. ")")
            if executor:find("Zeus") then
                warn("[Halol] Zeus 偵測：已自動停用高風險 Hook 以防崩潰")
            end
            env_global.__HalolAdvancedProtectionActive = true
            -- 在相容模式下，只啟用最基礎的非 Hook 防護 (如 pcall 包裹與頻率限制)
            return
        end

        env_global.__HalolAdvancedProtectionActive = true
        -- 只有在穩定執行器上才啟用 getgc 等激進 Hook
        if not env_global.DisableAggressiveProtection and capabilities.FunctionHook then
            pcall(SetupStealthProtection)
        end

        pcall(function()
            local lastPing = 35
            local function jitter(base)
                local j = (math.random() - 0.5) * 2
                return math.max(20, math.min(50, base + j * 3))
            end

            -- Metatable Hooks 對某些執行器來說非常不穩定
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
                local success, result = pcall(function()
                    if not checkcaller() then
                        local coreGui = game:GetService("CoreGui")
                        if (self == coreGui or (gethui and self == gethui())) and (key == "HalolMainGui" or key == "HalolESP") then
                            return nil
                        end
                        if self == getgenv() and (key == "CombatModule" or key:find("Halol")) then
                            return nil
                        end
                        if env_global.AntiCheatBypass then
                            if key == "DataReceiveKbps" or key == "DataSendKbps" then
                                lastPing = jitter(lastPing)
                                return lastPing
                            end
                            if key == "HeartbeatTimeReference" then return tick() end
                        end
                        if env_global.AntiKickEnabled and self == lp and key == "Kick" then
                            if not IsRealRequest() then
                                return newcclosure(function() 
                                    warn("[Halol Anti-Kick] 攔截到 Kick")
                                    return nil 
                                end)
                            end
                        end
                    end
                    return "CONTINUE"
                end)

                if success and result ~= "CONTINUE" then
                    return result
                end
                return oldIndex(self, key)
            end))

            local lastRemoteTime = {}
            local block_keywords = {"cheat", "exploit", "detect", "flag", "report", "scan", "ban", "kick"}
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                if checkcaller() then return oldNamecall(self, ...) end
                
                local method = getnamecallmethod()
                local success, result = pcall(function()
                    if env_global.AntiKickEnabled and method == "Kick" and self == lp then
                        warn("[Halol Anti-Kick] 攔截到 Kick")
                        return nil
                    end
                    
                    if (method == "FireServer" or method == "InvokeServer") then
                        local remoteName = tostring(self):lower()
                        local now = tick()
                        
                        -- 頻率限制優化
                        if lastRemoteTime[self] and (now - lastRemoteTime[self]) < 0.05 then 
                            return nil 
                        end
                        lastRemoteTime[self] = now

                        for _, kw in ipairs(block_keywords) do
                            if remoteName:find(kw) then
                                if not IsRealRequest() or env_global.AntiReportEnabled or env_global.AntiKickEnabled then
                                    warn("[Halol Protection] 攔截到敏感 Remote: " .. remoteName)
                                    return nil
                                end
                            end
                        end
                    end
                    return "CONTINUE"
                end)

                if success and result ~= "CONTINUE" then
                    return result
                end
                return oldNamecall(self, ...)
            end))

            -- debug.getinfo Hook 是最高風險的，預設關閉或謹慎使用
            --[[
            local oldGetInfo
            oldGetInfo = hookfunction(debug.getinfo, newcclosure(function(f, ...)
                local info = oldGetInfo(f, ...)
                if not checkcaller() and info and info.source and info.source:find("Halol") then
                    info.source = "=[C]"
                    info.what = "C"
                    info.name = "hidden"
                end
                return info
            end))
            ]]
        end)
        print("[Halol] 進階保護系統已啟動")
    end

    SetupAdvancedProtection()
end

return Protection

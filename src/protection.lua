---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
local Protection = {}

function Protection.Init(Core)
    local getgenv = Core.getgenv or getgenv
    local getnamecallmethod = Core.getnamecallmethod or getnamecallmethod
    local game = Core.game or game
    local workspace = Core.workspace or workspace
    local tick = Core.tick or tick

    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    
    -- [[ 配置初始化 ]]
    env_global.GodModeEnabled = env_global.GodModeEnabled or false
    env_global.ShieldEnabled = env_global.ShieldEnabled or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("GodMode", {
        Name = "無敵模式 (God Mode)",
        Description = "鎖定血量並攔截所有傷害封包",
        Category = "Protection",
        Callback = function(state) env_global.GodModeEnabled = state end
    })

    -- [[ 強化反腳本掃描與偽造 ]]
    local function SecureEnvironment()
        local hookmetamethod = Core.hookmetamethod
        local hookfunction = Core.hookfunction
        local newcclosure = Core.newcclosure
        local checkcaller = Core.checkcaller
        local islclosure = env_global.islclosure or function(f) return type(f) == "function" end
        local getinfo = debug.info
        
        if not hookmetamethod then return end

        -- 0. Hook 檢測防禦 (Preventing detection of our hooks)
        local function IsOurFunction(f)
            local source = debug.info(f, "s")
            return source:find("halol") or source:find("combat") or source:find("visuals") or source:find("protection") or source:find("core") or source:find("misc")
        end

        -- 1. 執行器偽裝 (Executor Spoofing)
        if env_global.identifyexecutor then
            local success, err = pcall(function()
                local oldIdentify
                oldIdentify = hookfunction(env_global.identifyexecutor, newcclosure(function()
                    if not checkcaller() then
                        return "Roblox", "1.0" -- 讓遊戲腳本以為是官方環境
                    end
                    return oldIdentify()
                end))
            end)
            if not success then warn("[Halol Protection] identifyexecutor hook 失敗: " .. tostring(err)) end
        end

        -- 2. 屬性與環境偽造 (Property & Environment Spoofing)
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                -- 隱藏外掛物件與屬性
                if key == "Clonable" or key == "Archivable" then
                    return false
                end
                
                -- 防止遊戲腳本檢測特定的敏感服務
                if self == game then
                    local sensitiveServices = {
                        ["LogService"] = true,
                        ["ScriptContext"] = true,
                        ["HttpService"] = true, -- 防止遊戲檢測外掛發出的 Http 請求
                        ["Stats"] = true,
                        ["VirtualUser"] = true
                    }
                    if sensitiveServices[key] then
                        return nil
                    end
                end

                -- 偽造 Humanoid 屬性 (防止本地腳本檢測 WalkSpeed/JumpPower 修改)
                if self:IsA("Humanoid") then
                    if key == "WalkSpeed" then return 16 end
                    if key == "JumpPower" then return 50 end
                    if key == "JumpHeight" then return 7.2 end
                end

                -- 偽造環境屬性
                if self:IsA("Camera") and key == "FieldOfView" then
                    return 70
                end
                if self == workspace and key == "Gravity" then
                    return 196.2
                end
                
                -- 隱藏 UI 物件
                if (key == "Parent" or key == "Name") and self:IsA("GuiObject") then
                    local source = debug.info(2, "s")
                    if not source:find("halol") then
                        -- 如果是遊戲腳本在查詢 UI，且該 UI 是我們創建的，則隱藏它
                        -- 這裡需要配合 UI 創建時的命名規則
                    end
                end
            end
            return oldIndex(self, key)
        end))

        -- 3. 方法攔截 (Method Spoofing)
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if not checkcaller() then
                -- 攔截 Kick
                if method == "Kick" or method == "kick" then
                    print("[Halol Protection] 攔截到 Kick 請求: " .. tostring(args[1]))
                    return nil
                end

                -- 攔截檢測性 Remote
                if method == "FireServer" or method == "InvokeServer" then
                    local name = tostring(self.Name):lower()
                    local detectionKeywords = {"check", "detect", "anticheat", "verify", "log", "report", "teleport"}
                    for _, kw in ipairs(detectionKeywords) do
                        if name:find(kw) then
                            print("[Halol Protection] 攔截到可疑 Remote: " .. name)
                            return nil
                        end
                    end
                end
                
                -- 攔截 GetService 獲取敏感服務
                if method == "GetService" or method == "getService" then
                    local serviceName = args[1]
                    local sensitiveServices = {
                        ["LogService"] = true,
                        ["ScriptContext"] = true,
                        ["VirtualUser"] = true
                    }
                    if sensitiveServices[serviceName] then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))

        -- 4. 調試資訊偽裝 (Debug Info Spoofing)
        local oldDebugInfo
        oldDebugInfo = hookfunction(debug.info, newcclosure(function(f, ...)
            if not checkcaller() and type(f) == "function" then
                if IsOurFunction(f) then
                    return "Roblox", "1.0", "global" -- 偽裝成官方腳本
                end
            end
            return oldDebugInfo(f, ...)
        end))

        -- 5. GC 偽裝 (Garbage Collector Spoofing - 如果執行器支援)
        if env_global.getgc then
            local oldGetgc
            oldGetgc = hookfunction(env_global.getgc, newcclosure(function(...)
                local gc = oldGetgc(...)
                if not checkcaller() then
                    local newGc = {}
                    for _, v in ipairs(gc) do
                        if type(v) == "function" then
                            if not IsOurFunction(v) then
                                table.insert(newGc, v)
                            end
                        else
                            table.insert(newGc, v)
                        end
                    end
                    return newGc
                end
                return gc
            end))
        end

        print("[Halol Protection] 超強反偵測系統已啟動")
    end

    SecureEnvironment()
end

return Protection

---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
local Protection = {}

function Protection.Init(Core)
    local get_genv = Core.get_genv or getgenv
    local getnamecallmethod = Core.getnamecallmethod or getnamecallmethod
    local game = Core.game or game
    local workspace = Core.workspace or workspace
    local tick = Core.tick or tick

    local env_global = get_genv() --[[@as GlobalEnv]]
    
    -- [[ 配置初始化 ]]
    env_global.GodModeEnabled = env_global.GodModeEnabled or false
    env_global.LavaImmunity = env_global.LavaImmunity or false
    env_global.ShieldEnabled = env_global.ShieldEnabled or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("GodMode", {
        Name = "無敵模式 (God Mode)",
        Description = "鎖定血量並攔截所有傷害封包",
        Category = "Protection",
        Callback = function(state) env_global.GodModeEnabled = state end
    })

    Core.RegisterFeature("LavaImmunity", {
        Name = "岩漿免疫 (Lava Immunity)",
        Description = "防止受到來自岩漿零件的傷害",
        Category = "Protection",
        Callback = function(state) env_global.LavaImmunity = state end
    })

    Core.RegisterFeature("ShieldEnabled", {
        Name = "護盾模式 (Shield)",
        Description = "減少受到的傷害 (偽造傷害數值)",
        Category = "Protection",
        Callback = function(state) env_global.ShieldEnabled = state end
    })

    -- [[ 強化反腳本掃描與偽造 ]]
    local function SecureEnvironment()
        if env_global.DisableAdvancedHooks then return end

        local hookmetamethod = Core.hookmetamethod
        local hookfunction = Core.hookfunction
        local newcclosure = Core.newcclosure
        local checkcaller = Core.checkcaller
        local islclosure = Core.islclosure or function(f) return type(f) == "function" end
        local getinfo = debug.info
        local setreadonly = env_global.setreadonly or (make_writeable and function(t, v) if v then make_writeable(t) else make_readonly(t) end end)
        local getrawmetatable = env_global.getrawmetatable or (getgenv and getgenv().getrawmetatable)
        
        if not hookmetamethod then return end

        -- 0. Hook 檢測防禦 (Preventing detection of our hooks)
        local function IsOurFunction(f)
            if type(f) ~= "function" then return false end
            local success, source = pcall(debug.info, f, "s")
            if not success or not source then return false end
            source = source:lower()
            local keywords = {"halol", "combat", "visuals", "protection", "core", "misc", "world"}
            for _, kw in ipairs(keywords) do
                if source:find(kw) then return true end
            end
            return false
        end

        -- 0.1 防止 Metatable 檢測 (Metatable Protection)
        local raw_mt = getrawmetatable(game)
        if raw_mt and setreadonly then
            setreadonly(raw_mt, false)
            local old_index = raw_mt.__index
            raw_mt.__index = newcclosure(function(self, key)
                if not checkcaller() then
                    if key == "__metatable" then return "The metatable is locked" end
                end
                return old_index(self, key)
            end)
            setreadonly(raw_mt, true)
        end

        -- 1. 執行器偽裝 (Executor Spoofing)
        if env_global.identifyexecutor then
            local oldIdentify
            oldIdentify = hookfunction(env_global.identifyexecutor, newcclosure(function()
                if not checkcaller() then
                    return "Roblox", "1.0" -- 讓遊戲腳本以為是官方環境
                end
                return oldIdentify()
            end))
        end

        -- 1.1 偽造常見注入標記
        if not env_global.LPH_OBFUSCATED then
            env_global.LPH_OBFUSCATED = true -- 讓某些腳本以為已混淆
        end

        -- 2. 屬性與環境偽造 (Property & Environment Spoofing)
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                -- 核心屬性隱藏
                if key == "Clonable" or key == "Archivable" then return false end
                
                -- 防止遊戲腳本檢測特定的敏感服務
                if self == game then
                    local sensitiveServices = {
                        ["LogService"] = true,
                        ["ScriptContext"] = true,
                        ["HttpService"] = true,
                        ["Stats"] = true,
                        ["VirtualUser"] = true,
                        ["DataStoreService"] = true,
                        ["Selection"] = true,
                        ["TestService"] = true
                    }
                    if sensitiveServices[key] then return nil end
                end

                -- 偽造 Humanoid 屬性 (防止本地腳本檢測修改)
                if self:IsA("Humanoid") then
                    if key == "WalkSpeed" then return 16 end
                    if key == "JumpPower" then return 50 end
                    if key == "JumpHeight" then return 7.2 end
                end

                -- 偽造環境屬性
                if self:IsA("Camera") and key == "FieldOfView" then return 70 end
                if self == workspace and key == "Gravity" then return 196.2 end
                
                -- 隱藏特定命名的 UI 物件
                if (key == "Parent" or key == "Name") and self:IsA("GuiObject") then
                    local name = tostring(self.Name):lower()
                    if name:find("halol") or name:find("menu") or name:find("ui") then
                        return nil
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
                    warn("[Halol Protection] 攔截到 Kick 請求: " .. tostring(args[1]))
                    return nil
                end

                -- 攔截檢測性 Remote
                if method == "FireServer" or method == "InvokeServer" then
                    local name = tostring(self.Name):lower()
                    local detectionKeywords = {"check", "detect", "anticheat", "verify", "log", "report", "teleport", "error", "kick", "ban", "screenshot"}
                    for _, kw in ipairs(detectionKeywords) do
                        if name:find(kw) then
                            local stack = debug.traceback():lower()
                            if stack:find("halol") or stack:find("combat") or stack:find("visuals") or stack:find("protection") then
                                print("[Halol Protection] 攔截到腳本關聯 Remote: " .. name)
                                return nil
                            end
                        end
                    end
                end
                
                -- 攔截 GetService 獲取敏感服務
                if method == "GetService" or method == "getService" then
                    local serviceName = args[1]
                    local sensitiveServices = {
                        ["LogService"] = true,
                        ["ScriptContext"] = true,
                        ["VirtualUser"] = true,
                        ["HttpService"] = true,
                        ["TestService"] = true
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
            if not checkcaller() then
                if IsOurFunction(f) then
                    return "Roblox", "1.0", "global" -- 偽裝成官方腳本
                end
            end
            return oldDebugInfo(f, ...)
        end))

        -- 5. GC 偽裝 (Garbage Collector Spoofing)
        if env_global.getgc then
            local oldGetgc
            oldGetgc = hookfunction(env_global.getgc, newcclosure(function(...)
                local gc = oldGetgc(...)
                if not checkcaller() then
                    local newGc = {}
                    for i = 1, #gc do
                        local v = gc[i]
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

        -- 5.1 連線偽裝 (Connections Spoofing)
        if env_global.getconnections then
            local oldGetConnections
            oldGetConnections = hookfunction(env_global.getconnections, newcclosure(function(signal)
                local connections = oldGetConnections(signal)
                if not checkcaller() then
                    local newConnections = {}
                    for i = 1, #connections do
                        local conn = connections[i]
                        local func = conn.Function
                        if func and not IsOurFunction(func) then
                            table.insert(newConnections, conn)
                        end
                    end
                    return newConnections
                end
                return connections
            end))
        end

        -- 5.2 Upvalue & Constant Protection
        local oldGetUpvalues = debug.getupvalues
        if oldGetUpvalues then
            hookfunction(debug.getupvalues, newcclosure(function(f)
                if not checkcaller() and IsOurFunction(f) then
                    return {}
                end
                return oldGetUpvalues(f)
            end))
        end

        local oldGetConstants = debug.getconstants
        if oldGetConstants then
            hookfunction(debug.getconstants, newcclosure(function(f)
                if not checkcaller() and IsOurFunction(f) then
                    return {}
                end
                return oldGetConstants(f)
            end))
        end

        -- 6. 腳本列表偽裝 (Scripts & Modules Spoofing)
        local scriptFunctions = {"getscripts", "getrunningscripts", "getloadedmodules", "getnilinstances"}
        for _, funcName in ipairs(scriptFunctions) do
            if env_global[funcName] then
                local oldFunc
                oldFunc = hookfunction(env_global[funcName], newcclosure(function(...)
                    local list = oldFunc(...)
                    if not checkcaller() then
                        local newList = {}
                        for i = 1, #list do
                            local item = list[i]
                            local name = tostring(item.Name):lower()
                            if not (name:find("halol") or name:find("combat") or name:find("visuals")) then
                                table.insert(newList, item)
                            end
                        end
                        return newList
                    end
                    return list
                end))
            end
        end

        -- 7. 網路請求偽裝 (HttpRequest Spoofing)
        if env_global.request or env_global.http_request then
            local reqFunc = env_global.request or env_global.http_request
            local oldRequest
            oldRequest = hookfunction(reqFunc, newcclosure(function(options)
                if not checkcaller() then
                    local url = tostring(options.Url):lower()
                    -- 攔截向可疑 API 發送的數據
                    if url:find("webhook") or url:find("analytics") or url:find("log") then
                        print("[Halol Protection] 攔截到可疑網路請求: " .. url)
                        return {StatusCode = 200, Body = "OK", Success = true}
                    end
                end
                return oldRequest(options)
            end))
        end

        print("[Halol Protection] 高級防護與繞過系統已強化")
    end

    -- [[ 功能邏輯實現 ]]
    task.spawn(function()
        while task.wait(0.1) do -- 縮短間隔以提高免疫反應
            local player = game:GetService("Players").LocalPlayer
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                -- 1. 全域無敵
                if env_global.GodModeEnabled then
                    humanoid.Health = humanoid.MaxHealth
                end

                -- 2. 岩漿免疫 (檢測是否正在接觸岩漿)
                if env_global.LavaImmunity and not env_global.GodModeEnabled then
                    local touching = humanoid:GetTouchingParts()
                    local inLava = false
                    for i = 1, #touching do
                        local name = touching[i].Name:lower()
                        if name:find("lava") or name:find("magma") then
                            inLava = true
                            break
                        end
                    end
                    
                    if inLava and humanoid.Health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end
        end
    end)

    SecureEnvironment()
end

return Protection

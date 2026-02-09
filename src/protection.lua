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
            local success, result = pcall(function()
                if not checkcaller() then
                    -- 隱藏外掛物件
                    if key == "Clonable" or key == "Archivable" then
                        return false
                    end
                    -- 強化：防止檢測腳本獲取特定服務
                    if self == game and (key == "LogService" or key == "ScriptContext") then
                        return nil
                    end

                    -- 偽造 Humanoid 屬性 (防止本地腳本檢測 WalkSpeed/JumpPower 修改)
                    if self:IsA("Humanoid") then
                        if key == "WalkSpeed" then return 16 end
                        if key == "JumpPower" then return 50 end
                        if key == "Health" then return self.Health end 
                    end

                    -- 偽造環境屬性
                    if self:IsA("Camera") and key == "FieldOfView" then
                        return 70 -- 即使開啟 FOV Changer，腳本讀取到的也是 70
                    end
                    if self == workspace and key == "Gravity" then
                        return 196.2 -- 即使修改重力，腳本讀取到的也是預設值
                    end
                    
                    -- 強化：偽造光照與零件屬性
                    if self:IsA("Lighting") then
                        if key == "ClockTime" then return 12 end
                        if key == "Brightness" then return 2 end
                    end
                    if self:IsA("BasePart") then
                        if key == "CanCollide" then return true end
                        if key == "Transparency" then return 0 end
                    end

                    -- 偽造時間戳 (Time Spoofing - 防止速度檢查)
                    if key == "DistributedGameTime" or key == "DistributedTime" then
                        return oldIndex(self, key) 
                    end
                end
                return oldIndex(self, key)
            end)
            if success then return result else return oldIndex(self, key) end
        end))

        -- 2.5 屬性修改攔截 (Property Modification Spoofing)
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
            local success = pcall(function()
                if not checkcaller() then
                    if self:IsA("Humanoid") then
                        -- 無敵模式：鎖定生命值 (本地偽造)
                        if env_global.GodModeEnabled and key == "Health" then
                            oldNewIndex(self, key, self.MaxHealth)
                            return true
                        end
                        -- 無減速攔截
                        if env_global.NoSlow and key == "WalkSpeed" then
                            local targetSpeed = env_global.WalkSpeedEnabled and env_global.WalkSpeed or 16
                            if value < targetSpeed then
                                oldNewIndex(self, key, targetSpeed)
                                return true
                            end
                        end
                        -- 跳躍攔截
                        if env_global.JumpPowerEnabled and key == "JumpPower" then
                            if value < env_global.JumpPower then
                                oldNewIndex(self, key, env_global.JumpPower)
                                return true
                            end
                        end
                    end
                end
                return false
            end)
            
            if success then return end
            return oldNewIndex(self, key, value)
        end))

        -- 2.6 強化 Namecall 攔截 (Advanced Namecall Bypass)
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            local name = self.Name:lower()

            local success, result = pcall(function()
                if not checkcaller() then
                    -- 0. 針對常見 Anti-Cheat 框架 (Adonnis 等) 的通用繞過
                    if method == "GetDebugId" or method == "GetFullName" then
                        local fullName = oldNamecall(self, "GetFullName")
                        if fullName:find("Halol") or fullName:find("ScreenGui") then
                            return true, "GameWorkspace"
                        end
                    end

                    -- 1. 攔截 Kick (防止被遊戲腳本踢出)
                    if method == "Kick" or method == "kick" then
                        warn("[Halol Anti-Kick] 攔截到 Kick 請求: " .. tostring(args[1]))
                        return true, nil
                    end

                    -- 2. 攔截檢測性遠程封包 (Security Remotes)
                    if method == "FireServer" or method == "InvokeServer" then
                        if name:find("check") or name:find("detect") or name:find("verify") or 
                           name:find("security") or name:find("kick") or name:find("ban") or 
                           name:find("teleport") or name:find("speed") or name:find("fly") or
                           name:find("report") then
                            return true, nil -- 直接吞掉檢測封包
                        end
                    end

                    -- 3. 無敵模式：攔截傷害封包
                    if env_global.GodModeEnabled then
                        if method == "FireServer" or method == "InvokeServer" then
                            if name:find("damage") or name:find("takehealth") or name:find("hit") or 
                               name:find("ouch") or name:find("die") then
                                return true, nil
                            end
                        end
                    end

                    -- 3.5 強化：攔截遠端函數調用，防止被 Anti-Cheat 主動掃描
                    if method == "FireServer" or method == "InvokeServer" then
                        -- 如果發送的是字串且包含本腳本特徵
                        for _, arg in ipairs(args) do
                            if type(arg) == "string" and (arg:find("Halol") or arg:find("combat") or arg:find("visuals")) then
                                return true, nil
                            end
                        end
                    end

                    -- 4. 隱藏外掛 Instance (攔截 GetChildren / GetDescendants)
                    if method == "GetChildren" or method == "GetDescendants" or method == "getchildren" or method == "getdescendants" then
                        local list = oldNamecall(self, unpack(args))
                        local newList = {}
                        for i, v in ipairs(list) do
                            local vName = v.Name:lower()
                            if not (vName:find("halol") or vName:find("gui") or vName == "screen") then
                                table.insert(newList, v)
                            end
                        end
                        return true, newList
                    end
                end
                return false, nil
            end)

            if success and result ~= nil then return result end
            return oldNamecall(self, ...)
        end))

        -- 3. 全域變數偽裝 (Global Variable Spoofing)
        local blockedGlobals = {
            "syn", "getgenv", "getrawmetatable", "hookmetamethod", 
            "Drawing", "identifyexecutor", "hookfunction", "newcclosure",
            "getrenv", "getreg", "getgc", "setfpscap"
        }
        
        local oldGenIndex
        oldGenIndex = hookmetamethod(getgenv(), "__index", newcclosure(function(self, key)
            if not checkcaller() and table.find(blockedGlobals, key) then
                return nil -- 遊戲腳本讀取不到外掛 API
            end
            return oldGenIndex(self, key)
        end))

        -- 4. 函數行為偽裝 (Function Behavior Spoofing)
        if hookfunction then
            -- 偽裝 tick() 避免頻率檢查
            local oldTick = tick
            hookfunction(tick, newcclosure(function()
                if not checkcaller() then
                    return oldTick()
                end
                return oldTick()
            end))

            -- 5. 堆棧追蹤偽裝 (Stack Trace Spoofing)
            local oldTraceback = debug.traceback
            hookfunction(debug.traceback, newcclosure(function(...)
                local trace = oldTraceback(...)
                if not checkcaller() and type(trace) == "string" then
                    -- 移除所有包含外掛關鍵字的堆棧行
                    local lines = trace:split("\n")
                    local newLines = {}
                    for _, line in ipairs(lines) do
                        if not (line:lower():find("halol") or line:lower():find("combat") or line:lower():find("visuals")) then
                            table.insert(newLines, line)
                        end
                    end
                    return table.concat(newLines, "\n")
                end
                return trace
            end))

            -- 6. debug.info / debug.getinfo 偽裝 (隱藏腳本來源)
            local oldDebugInfo = debug.info
            hookfunction(debug.info, newcclosure(function(f, ...)
                if not checkcaller() and type(f) == "function" then
                    -- 如果檢測腳本試圖讀取我們的函數信息
                    if IsOurFunction(f) then
                        return "SystemScript", 0, "Native", "C" -- 偽造成系統內置 C 函數
                    end
                end
                return oldDebugInfo(f, ...)
            end))

            -- 7. 針對 getfenv 的偽裝 (防止檢測腳本讀取我們的環境變數)
            if env_global.getfenv then
                local oldGetFenv = env_global.getfenv
                hookfunction(env_global.getfenv, newcclosure(function(f)
                    if not checkcaller() and type(f) == "function" and IsOurFunction(f) then
                        return oldGetFenv(0) -- 回傳全局環境而非我們的私有環境
                    end
                    return oldGetFenv(f)
                end))
            end
        end
        
        print("[Halol] 全方位偽造系統 (Advanced Spoofing) 已啟動")
    end

    SecureEnvironment()
end

return Protection

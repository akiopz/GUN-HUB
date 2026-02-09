    -- [[ 強化反腳本掃描與偽造 ]]
    local function SecureEnvironment()
        local hookmetamethod = Core.hookmetamethod
        local hookfunction = Core.hookfunction
        local newcclosure = Core.newcclosure
        local checkcaller = Core.checkcaller
        
        if not hookmetamethod then return end

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

        -- 2. 屬性與環境偽造 (Property & Environment Spoofing)
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                -- 隱藏外掛物件
                if key == "Clonable" or key == "Archivable" then
                    return false
                end
                if self:IsA("LuaSourceContainer") and (key == "Name" or key == "FullName") then
                    return "SystemScript"
                end

                -- 偽造 Humanoid 屬性 (防止本地腳本檢測 WalkSpeed/JumpPower 修改)
                if self:IsA("Humanoid") then
                    if key == "WalkSpeed" then return 16 end
                    if key == "JumpPower" then return 50 end
                    if key == "Health" then return self.Health end -- 正常回傳
                end

                -- 偽造時間戳 (Time Spoofing - 防止速度檢查)
                if key == "DistributedGameTime" or key == "DistributedTime" then
                    return oldIndex(self, key) -- 這裡可以加入偏移量如果需要
                end
            end
            return oldIndex(self, key)
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
                    return oldTick() -- 可以在此加入平滑邏輯
                end
                return oldTick()
            end))
        end
        
        print("[Halol] 全方位偽造系統 (Advanced Spoofing) 已啟動")
    end

    SecureEnvironment()

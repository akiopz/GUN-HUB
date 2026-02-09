    -- [[ 強化反腳本掃描 ]]
    local function SecureEnvironment()
        local hookmetamethod = Core.hookmetamethod
        local newcclosure = Core.newcclosure
        local checkcaller = Core.checkcaller
        
        if not hookmetamethod then return end

        -- 隱藏特定物件 (如 GUI 或 Drawing 物件)
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                if key == "Clonable" or key == "Archivable" then
                    return false
                end
                -- 偽裝腳本名稱或路徑
                if self:IsA("LuaSourceContainer") and (key == "Name" or key == "FullName") then
                    return "SystemScript"
                end
            end
            return oldIndex(self, key)
        end))

        -- 防止檢測常用外掛全域變數
        local blockedGlobals = {"syn", "getgenv", "getrawmetatable", "hookmetamethod", "Drawing", "identifyexecutor"}
        local oldGenIndex
        oldGenIndex = hookmetamethod(getgenv(), "__index", newcclosure(function(self, key)
            if not checkcaller() and table.find(blockedGlobals, key) then
                return nil -- 讓遊戲腳本找不到外掛 API
            end
            return oldGenIndex(self, key)
        end))
        
        print("[Halol] Protection 模組已強化")
    end

    SecureEnvironment()

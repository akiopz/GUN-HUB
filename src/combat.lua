---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Combat Module
-- 放置於: src/combat.lua

local Combat = {}

function Combat.Init(Core)
    ---@class GlobalEnv
    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    local lp = Core.LocalPlayer
    local Camera = Core.Camera
    local Players = Core.Players
    local UserInputService = Core.UserInputService
    local RunService = Core.RunService

    local lastTarget = nil -- 用於黏性瞄準的快取目標

    -- [[ 配置初始化 ]]
    env_global.AimbotEnabled = env_global.AimbotEnabled or false
    env_global.AimbotQuickSwitch = env_global.AimbotQuickSwitch or false
    env_global.KillAll = env_global.KillAll or false
    env_global.KillAllDelay = env_global.KillAllDelay or 0.1
    env_global.BulletTeleport = env_global.BulletTeleport or false
    env_global.BulletMultiTarget = env_global.BulletMultiTarget or false
    env_global.BulletCritical = env_global.BulletCritical or false
    env_global.MagicBullet = env_global.MagicBullet or false
    env_global.DamageMultiplierEnabled = env_global.DamageMultiplierEnabled or false
    env_global.DamageMultiplier = env_global.DamageMultiplier or 2
    
    env_global.NoRecoilEnabled = env_global.NoRecoilEnabled or false
    env_global.NoSpreadEnabled = env_global.NoSpreadEnabled or false
    local function GetCurrentWeapon()
        local char = lp.Character
        if not char then return nil end
        return char:FindFirstChildOfClass("Tool")
    end

    local function IsSniper(weapon)
        if not weapon then return false end
        local name = weapon.Name:lower()
        -- 常見狙擊槍關鍵字
        return name:find("sniper") or name:find("awp") or name:find("remington") or name:find("scout") or name:find("rifle")
    end

    local function QuickSwitch()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local weapon = GetCurrentWeapon()
        
        if hum and weapon then
            -- 執行快切：卸下再裝備，繞過狙擊槍射擊間隔
            hum:UnequipTools()
            task.wait(0.05)
            hum:EquipTool(weapon)
        end
    end
    env_global.AimbotSmoothness = env_global.AimbotSmoothness or 0.15
    env_global.AimbotFOV = env_global.AimbotFOV or 150
    env_global.AimbotTargetPart = env_global.AimbotTargetPart or "Head"
    env_global.AimbotVisibilityCheck = env_global.AimbotVisibilityCheck or false
    env_global.AimbotPriority = env_global.AimbotPriority or "Mouse" -- "Mouse", "Distance"
    env_global.AimbotPrediction = env_global.AimbotPrediction or false
    env_global.AimbotPredictionAmount = env_global.AimbotPredictionAmount or 0.165
    env_global.AimbotBulletSpeed = env_global.AimbotBulletSpeed or 1000 -- 用於進階預測
    env_global.AimbotGravity = env_global.AimbotGravity or 196.2 -- 用於重力補償
    env_global.AimbotMultiBone = env_global.AimbotMultiBone or true -- 多骨骼掃描
    env_global.AimbotSticky = env_global.AimbotSticky or false -- 黏性瞄準
    env_global.AimbotRageMode = env_global.AimbotRageMode or false -- 暴力鎖頭模式
    env_global.AimbotPingCompensation = env_global.AimbotPingCompensation or true -- 延遲補償
    env_global.SilentAimEnabled = env_global.SilentAimEnabled or false
    env_global.SilentAimFOV = env_global.SilentAimFOV or 200
    env_global.SilentAimHitChance = env_global.SilentAimHitChance or 100
    env_global.HitboxExpanderEnabled = env_global.HitboxExpanderEnabled or false
    env_global.HitboxSize = env_global.HitboxSize or 5
    env_global.SpinbotEnabled = env_global.SpinbotEnabled or false
    env_global.SpinbotSpeed = env_global.SpinbotSpeed or 50
    env_global.AntiAimEnabled = env_global.AntiAimEnabled or false
    env_global.AntiAimMode = env_global.AntiAimMode or "Jitter" -- "Jitter", "Spin", "Backwards"
    env_global.TeleportKillEnabled = env_global.TeleportKillEnabled or false
    env_global.InstaKillEnabled = env_global.InstaKillEnabled or false
    env_global.ShieldEnabled = env_global.ShieldEnabled or false
    env_global.InfiniteAmmoEnabled = env_global.InfiniteAmmoEnabled or false
    env_global.RapidFireEnabled = env_global.RapidFireEnabled or false
    env_global.InstaReloadEnabled = env_global.InstaReloadEnabled or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("TeleportKill", {
        Name = "傳送殺敵 (TP Kill)",
        Category = "Rage",
        Callback = function(state)
            env_global.TeleportKillEnabled = state
        end
    })

    Core.RegisterFeature("InstaKill", {
        Name = "秒殺模式 (Insta Kill)",
        Category = "Rage",
        Callback = function(state)
            env_global.InstaKillEnabled = state
        end
    })

    Core.RegisterFeature("Spinbot", {
        Name = "大陀螺 (Spinbot)",
        Category = "Rage",
        Callback = function(state)
            env_global.SpinbotEnabled = state
        end
    })

    Core.RegisterFeature("AntiAim", {
        Name = "反自瞄 (Anti-Aim)",
        Category = "Rage",
        Callback = function(state)
            env_global.AntiAimEnabled = state
        end
    })

    Core.RegisterFeature("SilentAim", {
        Name = "靜默瞄準 (Silent Aim)",
        Category = "Rage",
        Callback = function(state)
            env_global.SilentAimEnabled = state
        end
    })

    Core.RegisterFeature("RapidFire", {
        Name = "快速射擊 (Rapid Fire)",
        Category = "Rage",
        Callback = function(state)
            env_global.RapidFireEnabled = state
        end
    })

    Core.RegisterFeature("InfiniteAmmo", {
        Name = "無限子彈 (Inf Ammo)",
        Category = "Combat",
        Callback = function(state)
            env_global.InfiniteAmmoEnabled = state
        end
    })

    Core.RegisterFeature("InstaReload", {
        Name = "瞬間換彈 (Insta Reload)",
        Category = "Combat",
        Callback = function(state)
            env_global.InstaReloadEnabled = state
        end
    })

    Core.RegisterFeature("KillAll", {
        Name = "全地圖殺敵 (Kill All)",
        Category = "Rage",
        Callback = function(state)
            env_global.KillAll = state
            if state then
                Core.Notify("暴力模式", "全地圖殺敵已啟動，請謹慎使用", 3)
            end
        end
    })

    Core.RegisterFeature("BulletTeleport", {
        Name = "子彈傳送 (Bullet Teleport)",
        Category = "Rage",
        Callback = function(state) env_global.BulletTeleport = state end
    })

    Core.RegisterFeature("BulletMultiTarget", {
        Name = "多目標傳送 (Multi-Target)",
        Category = "Rage",
        Callback = function(state) env_global.BulletMultiTarget = state end
    })

    Core.RegisterFeature("BulletCritical", {
        Name = "子彈爆擊 (Bullet Critical)",
        Category = "Rage",
        Callback = function(state) env_global.BulletCritical = state end
    })

    Core.RegisterFeature("DamageMultiplier", {
        Name = "傷害增加 (Damage Multiplier)",
        Description = "倍增你的射擊傷害",
        Category = "Rage",
        Callback = function(state) env_global.DamageMultiplierEnabled = state end
    })

    Core.RegisterFeature("MagicBullet", {
        Name = "魔法子彈 (Magic Bullet)",
        Description = "子彈自動追蹤、無視障礙物且無視距離限制",
        Category = "Rage",
        Callback = function(state) env_global.MagicBullet = state end
    })

    Core.RegisterFeature("HitboxExpander", {
        Name = "碰撞箱擴大 (Hitbox Expander)",
        Category = "Rage",
        Callback = function(state)
            env_global.HitboxExpanderEnabled = state
        end
    })

    Core.RegisterFeature("Aimbot", {
        Name = "自動瞄準 (Aimbot)",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotEnabled = state
        
        end
    })

    Core.RegisterFeature("AimbotRage", {
        Name = "超強鎖頭 (Rage Lock)",
        Description = "瞬間鎖定、無視平滑度、進階預測",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotRageMode = state
            if state then
                env_global.AimbotSmoothness = 0
                env_global.AimbotSticky = true
            end
        end
    })

    Core.RegisterFeature("AimbotQuickSwitch", {
        Name = "狙擊自動快切 (Quick Switch)",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotQuickSwitch = state
        end
    })

    Core.RegisterFeature("NoRecoil", {
        Name = "無後座力 (No Recoil)",
        Category = "Combat",
        Callback = function(state)
            env_global.NoRecoilEnabled = state
        end
    })

    Core.RegisterFeature("NoSpread", {
        Name = "無擴散 (No Spread)",
        Category = "Combat",
        Callback = function(state)
            env_global.NoSpreadEnabled = state
        end
    })

    -- [[ 性能優化：Raycast 快取 ]]
    local raycastCache = {}
    local RAYCAST_INTERVAL = 0.05 -- 每秒最多 20 次 Raycast，節省 CPU
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local function IsVisible(part, character)
        if not env_global.AimbotVisibilityCheck then return true end
        if not part or not character then return false end

        local now = tick()
        local cacheKey = part:GetDebugId()

        -- 如果快取在有效期內，直接返回
        if raycastCache[cacheKey] and (now - raycastCache[cacheKey].time) < RAYCAST_INTERVAL then
            return raycastCache[cacheKey].visible
        end

        local origin = Camera.CFrame.Position
        local destination = part.Position
        local direction = (destination - origin)

        raycastParams.FilterDescendantsInstances = {character, Camera, workspace:FindFirstChild("Terrain")}

        local result = workspace:Raycast(origin, direction, raycastParams)
        local isVisible = true
        if result then
            local hit = result.Instance
            isVisible = hit:IsDescendantOf(part.Parent) or hit.Transparency > 0.8 or not hit.CanCollide
        end

        -- 更新快取
        raycastCache[cacheKey] = {
            visible = isVisible,
            time = now
        }

        return isVisible
    end

    function Combat.GetNearestEnemy()
        local nearest = nil
        local maxDist = env_global.MagicBullet and 999999 or env_global.AimbotFOV
        local minDistanceToChar = math.huge
        local minHealth = math.huge
        local mousePos = UserInputService:GetMouseLocation()
        local localChar = lp.Character

        -- 黏性瞄準：如果已有目標且目標存活，優先保留
        if env_global.AimbotSticky and lastTarget and lastTarget.Parent then
            local hum = lastTarget.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(lastTarget.Position)
                if onScreen then
                    local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if mouseDistance < env_global.AimbotFOV * 1.5 then -- 擴大一點黏性範圍
                        return lastTarget
                    end
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then
                local isTeam = (player.Team == lp.Team and player.Team ~= nil)
                if not isTeam then
                    local char = player.Character
                    if char then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            -- 多骨骼掃描邏輯
                            local bones = {env_global.AimbotTargetPart, "UpperTorso", "HumanoidRootPart", "LowerTorso"}
                            local bestBone = nil
                            
                            for _, boneName in ipairs(bones) do
                                local bone = char:FindFirstChild(boneName)
                                if bone then
                                    if env_global.MagicBullet or IsVisible(bone, localChar) then
                                        bestBone = bone
                                        break -- 找到第一個可用骨骼就停止
                                    end
                                    if not env_global.AimbotMultiBone then break end
                                end
                            end

                            if bestBone then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(bestBone.Position)
                                if onScreen or env_global.MagicBullet then
                                    local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                    
                                    -- 強化：預測補償
                                    local targetPos = bestBone.Position
                                    if env_global.AimbotPrediction then
                                        local velocity = humanoid.RootPart and humanoid.RootPart.Velocity or Vector3.new(0,0,0)
                                        local ping = lp:GetNetworkPing()
                                        local distance = (targetPos - Camera.CFrame.Position).Magnitude
                                        local timeToHit = (distance / env_global.AimbotBulletSpeed) + ping
                                        
                                        targetPos = targetPos + (velocity * timeToHit)
                                        
                                        -- 重力補償
                                        local gravityCompensation = 0.5 * env_global.AimbotGravity * (timeToHit ^ 2)
                                        targetPos = targetPos + Vector3.new(0, gravityCompensation, 0)
                                    end

                                    if mouseDistance < maxDist or env_global.MagicBullet then
                                        -- 優先度邏輯
                                        if env_global.AimbotPriority == "Mouse" then
                                            maxDist = mouseDistance
                                            nearest = bestBone
                                        elseif env_global.AimbotPriority == "Distance" then
                                            local hrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
                                            local charDistance = hrp and (hrp.Position - bestBone.Position).Magnitude or 0
                                            if charDistance < minDistanceToChar then
                                                minDistanceToChar = charDistance
                                                nearest = bestBone
                                            end
                                        elseif env_global.AimbotPriority == "Health" then
                                            if humanoid.Health < minHealth then
                                                minHealth = humanoid.Health
                                                nearest = bestBone
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        lastTarget = nearest -- 更新快取目標
        return nearest
    end

    Core.UI.AddSlider("SilentAimHitChance", {
        Name = "靜默自瞄命中率",
        Category = "Rage",
        Min = 0,
        Max = 100,
        Default = env_global.SilentAimHitChance,
        Callback = function(v) env_global.SilentAimHitChance = v end
    })

    Core.UI.AddSlider("DamageMultiplier", {
        Name = "傷害倍率 (Damage Multi)",
        Category = "Rage",
        Min = 1,
        Max = 10,
        Default = env_global.DamageMultiplier,
        Callback = function(v) env_global.DamageMultiplier = v end
    })

    Core.UI.AddSlider("HitboxSize", {
        Name = "碰撞箱大小 (Hitbox)",
        Category = "Rage",
        Min = 1,
        Max = 50,
        Default = env_global.HitboxSize,
        Callback = function(v) env_global.HitboxSize = v end
    })

    Core.UI.AddSlider("SpinbotSpeed", {
        Name = "大陀螺速度 (Spin)",
        Category = "Rage",
        Min = 1,
        Max = 500,
        Default = env_global.SpinbotSpeed,
        Callback = function(v) env_global.SpinbotSpeed = v end
    })

    Core.UI.AddSlider("KillAllDelay", {
        Name = "全圖殺敵間隔 (Delay)",
        Category = "Rage",
        Min = 0,
        Max = 100,
        Default = env_global.KillAllDelay * 100,
        Callback = function(v) env_global.KillAllDelay = v / 100 end
    })

    Core.UI.AddSlider("AimbotFOV", {
        Name = "自瞄範圍 (FOV)",
        Category = "Combat",
        Min = 10,
        Max = 1000,
        Default = env_global.AimbotFOV,
        Callback = function(v) env_global.AimbotFOV = v end
    })

    Core.UI.AddSlider("AimbotSmooth", {
        Name = "自瞄平滑度 (Smoothness)",
        Category = "Combat",
        Min = 0,
        Max = 50,
        Default = env_global.AimbotSmoothness * 100,
        Callback = function(v) env_global.AimbotSmoothness = v / 100 end
    })

    Core.RegisterFeature("AutoShoot", {
        Name = "自動射擊 (Auto Shoot)",
        Category = "Combat",
        Callback = function(state) env_global.AutoShoot = state end
    })

    -- [[ 超遠子彈優化 ]]
    local function OptimizeBullet(args, targetPos)
        for i, arg in ipairs(args) do
            if typeof(arg) == "Vector3" then
                -- 修正起點與方向，確保能打到超遠處
                args[i] = targetPos
            elseif typeof(arg) == "CFrame" then
                args[i] = CFrame.new(arg.Position, targetPos)
            elseif typeof(arg) == "Ray" then
                args[i] = Ray.new(arg.Origin, (targetPos - arg.Origin).Unit * 10000)
            end
        end
        return args
    end

    -- [[ 靜默自瞄核心 Hook ]]
    local function SetupSilentAim()
        local hookmetamethod = Core.hookmetamethod
        local getnamecallmethod = Core.getnamecallmethod
        local newcclosure = Core.newcclosure
        local checkcaller = Core.checkcaller

        if not hookmetamethod then return end

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if not checkcaller() then
                -- 靜默自瞄 & 魔法子彈 (Raycast 繞過)
                if env_global.SilentAimEnabled or env_global.MagicBullet then
                    if method == "Raycast" then
                        local target = Combat.GetNearestEnemy()
                        if target and (env_global.MagicBullet or math.random(1, 100) <= env_global.SilentAimHitChance) then
                            local origin = args[1]
                            local targetPos = target.Position
                            
                            -- 魔法子彈 & 超遠射程優化
                            if env_global.MagicBullet then
                                local params = RaycastParams.new()
                                params.FilterType = Enum.RaycastFilterType.Include
                                params.FilterDescendantsInstances = {target.Parent}
                                args[3] = params
                            end

                            local direction = (targetPos - origin).Unit * 15000 -- 極大化射程
                            args[2] = direction
                            return oldNamecall(self, unpack(args))
                        end
                    elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                        local target = Combat.GetNearestEnemy()
                        if target and (env_global.MagicBullet or math.random(1, 100) <= env_global.SilentAimHitChance) then
                            local origin = args[1].Origin
                            local direction = (target.Position - origin).Unit * 15000
                            args[1] = Ray.new(origin, direction)
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end

                -- 無後座力 & 無擴散 (透過 Namecall 攔截常見屬性修改)
                if method == "FireServer" then
                    local remoteName = self.Name:lower()

                    -- 傷害增加 (Damage Multiplier)
                    if env_global.DamageMultiplierEnabled then
                        if remoteName:find("damage") or remoteName:find("hit") or remoteName:find("weapon") then
                            for i, v in ipairs(args) do
                                if type(v) == "number" and v > 0 then
                                    args[i] = v * env_global.DamageMultiplier
                                end
                            end
                            return oldNamecall(self, unpack(args))
                        end
                    end

                    if (env_global.NoRecoilEnabled or env_global.NoSpreadEnabled) then
                        -- 更加精確的攔截邏輯，避免誤傷正常遊戲邏輯
                        if remoteName:find("recoil") or remoteName:find("spread") or remoteName:find("kick") or remoteName:find("shake") then
                            return
                        end
                        
                        -- 檢查參數中是否包含敏感數值 (如後座力系數)
                        for i, v in ipairs(args) do
                            if type(v) == "number" and v > 0 and (remoteName:find("weapon") or remoteName:find("gun")) then
                                -- 如果數值看起來像後座力參數，則將其修改為 0
                                args[i] = 0
                            end
                        end
                    end
                end -- 閉合 if method == "FireServer" (Line 495)

                -- 通用 Remote 繞過 (防止行為檢測)
                if method == "FireServer" or method == "InvokeServer" then
                    -- 1. 子彈傳送 (Bullet Teleport / Kill All / Multi-Target)
                    if env_global.KillAll or env_global.BulletTeleport or env_global.BulletMultiTarget then
                        local targets = {}
                        if env_global.BulletMultiTarget then
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= lp and p.Character and p.Character:FindFirstChild("Head") then
                                    table.insert(targets, p.Character.Head)
                                end
                            end
                        else
                            local t = Combat.GetNearestEnemy()
                            if t then table.insert(targets, t) end
                        end

                        for _, target in ipairs(targets) do
                            local origin = Camera.CFrame.Position
                            local targetPos = target.Position
                            
                            -- 魔法子彈優化：無視障礙物且極大化射程 (支援大地圖)
                            local newArgs = {unpack(args)}
                            local remoteName = self.Name:lower()
                            if remoteName:find("bullet") or remoteName:find("shoot") or remoteName:find("fire") then
                                -- 假設參數 2 是目標位置或射線方向
                                local direction = (targetPos - origin).Unit * 15000 -- 極大化射程
                                newArgs[2] = direction
                                
                                -- 爆擊與傷害加倍
                                if env_global.BulletCritical then
                                    newArgs[3] = 100 -- 假設參數 3 是爆擊率
                                end
                                
                                if env_global.DamageMultiplierEnabled then
                                    task.spawn(function()
                                        for i = 1, env_global.DamageMultiplier do
                                            self[method](self, unpack(newArgs))
                                        end
                                    end)
                                else
                                    self[method](self, unpack(newArgs))
                                end
                            end
                        end
                        return -- 攔截原始調用，因為我們已經手動發送了
                    end

                    -- 2. 狙擊槍快切
                    if env_global.AimbotQuickSwitch then
                        local weapon = GetCurrentWeapon()
                        if IsSniper(weapon) then
                            task.spawn(function()
                                task.wait(0.05) -- 等待射擊包發送完成
                                QuickSwitch()
                            end)
                        end
                    end

                    local remoteName = self.Name:lower()
                    if remoteName:find("check") or remoteName:find("detect") or remoteName:find("verify") then
                        return -- 吞掉所有疑似檢查的請求
                    end
                end -- 閉合 if method == "FireServer" or method == "InvokeServer" (Line 527)
            end -- 閉合 if not checkcaller() (Line 462)
            return oldNamecall(self, ...)
        end))

        -- 屬性 Hook (__index / __newindex)
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                -- 鼠標 Hook
                if env_global.SilentAimEnabled and self:IsA("Mouse") then
                    if key == "Hit" or key == "Target" then
                        local target = Combat.GetNearestEnemy()
                        if target and math.random(1, 100) <= env_global.SilentAimHitChance then
                            if key == "Hit" then return target.CFrame
                            elseif key == "Target" then return target end
                        end
                    end
                end
                
                -- 無後座力 / 無擴散 屬性偽造
                if env_global.NoRecoilEnabled and (key == "Recoil" or key == "RecoilControl" or key == "VisualRecoil") then
                    return 0
                end
                if env_global.NoSpreadEnabled and (key == "Spread" or key == "Accuracy" or key == "Inaccuracy") then
                    return 0
                end

                -- 子彈修改 (無限子彈 / 快速射擊)
                if env_global.InfiniteAmmoEnabled and (key == "Ammo" or key == "CurrentAmmo" or key == "Clip" or key == "Mag") then
                    return 999
                end
                if env_global.RapidFireEnabled and (key == "FireRate" or key == "Cooldown" or key == "Delay") then
                    return 0
                end
                if env_global.InstaReloadEnabled and (key == "ReloadTime" or key == "ReloadSpeed") then
                    return 0
                end
            end
            return oldIndex(self, key)
        end))
        
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
            if not checkcaller() then
                if env_global.NoRecoilEnabled and (key == "Recoil" or key == "RecoilControl" or key == "VisualRecoil") then
                    return oldNewIndex(self, key, 0)
                end
                if env_global.NoSpreadEnabled and (key == "Spread" or key == "Accuracy" or key == "Inaccuracy") then
                    return oldNewIndex(self, key, 0)
                end

                -- 子彈修改 (寫入攔截)
                if env_global.InfiniteAmmoEnabled and (key == "Ammo" or key == "CurrentAmmo" or key == "Clip" or key == "Mag") then
                    return oldNewIndex(self, key, 999)
                end
                if env_global.RapidFireEnabled and (key == "FireRate" or key == "Cooldown" or key == "Delay") then
                    return oldNewIndex(self, key, 0)
                end
                if env_global.InstaReloadEnabled and (key == "ReloadTime" or key == "ReloadSpeed") then
                    return oldNewIndex(self, key, 0)
                end
            end
            return oldNewIndex(self, key, value)
        end))
        
        print("[Halol] 強化 Combat Hooks 已啟動")
    end -- 閉合 SetupSilentAim

    -- 啟動所有循環與 Hook
    SetupSilentAim()
    
    -- [[ Aimbot 循環 ]]
    local lastTarget = nil
    RunService.RenderStepped:Connect(function()
        if not env_global.AimbotEnabled then return end
        
        local target = Combat.GetNearestEnemy()
        if target then
            lastTarget = target
            local targetPos = target.Position
            local char = target.Parent
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            -- 強化預測與重力補償
            if (env_global.AimbotPrediction or env_global.AimbotRageMode) and root then
                local dist = (Camera.CFrame.Position - targetPos).Magnitude
                local bulletSpeed = env_global.AimbotBulletSpeed
                
                -- 如果是暴力模式，自動提升預測精度
                local timeToHit = dist / bulletSpeed
                
                -- 延遲補償 (Ping Compensation)
                if env_global.AimbotPingCompensation then
                    local ping = tonumber(lp:GetNetworkPing()) or 0.05
                    timeToHit = timeToHit + ping
                end
                
                -- 進階預測 (位置 + 速度*時間 + 0.5*加速度*時間^2)
                local velocity = root.Velocity
                local predictionOffset = velocity * timeToHit
                
                -- 簡單的加速度估算 (如果目標在跳躍或快速轉向)
                if velocity.Magnitude > 1 then
                    predictionOffset = predictionOffset + (velocity.Unit * 0.5 * timeToHit * timeToHit)
                end
                
                targetPos = targetPos + predictionOffset
                
                -- 重力補償 (0.5 * g * t^2)
                local gravity = env_global.AimbotGravity
                local gravityCompensation = 0.5 * gravity * (timeToHit ^ 2)
                targetPos = targetPos + Vector3.new(0, gravityCompensation, 0)
            end
            
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            
            -- 平滑度處理
            if env_global.AimbotRageMode then
                -- 暴力模式：瞬間鎖定，無視平滑度
                Camera.CFrame = targetCF
            elseif env_global.AimbotSmoothness > 0 then
                local smoothness = math.max(0.01, env_global.AimbotSmoothness)
                local alpha = 1 / (smoothness * 100)
                Camera.CFrame = currentCF:Lerp(targetCF, alpha)
            else
                Camera.CFrame = targetCF
            end

            -- 自動射擊邏輯
            if env_global.AutoShoot then
                local weapon = GetCurrentWeapon()
                if weapon then
                    local remote = weapon:FindFirstChild("RemoteEvent") or weapon:FindFirstChildOfClass("RemoteEvent") or weapon:FindFirstChild("Fire")
                    if remote then
                        -- 如果是魔法子彈，直接打頭，否則打當前瞄準點
                        local shotPos = env_global.MagicBullet and target.Position or targetPos
                        remote:FireServer(shotPos)
                    end
                end
            end
        else
            lastTarget = nil
        end
    end)

    -- [[ Rage 循環: TP Kill ]]
    task.spawn(function()
        while task.wait(0.1) do
            if env_global.TeleportKillEnabled then
                local target = Combat.GetNearestEnemy()
                if target and target.Parent then
                    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        -- 傳送到目標背後
                        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
                    end
                end
            end
        end
    end)

    -- [[ Rage 循環: Spinbot & Anti-Aim ]]
    local rageAngle = 0
    RunService.Heartbeat:Connect(function()
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- 大陀螺邏輯
        if env_global.SpinbotEnabled then
            rageAngle = (rageAngle + env_global.SpinbotSpeed) % 360
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(env_global.SpinbotSpeed), 0)
        end

        -- 反自瞄邏輯
        if env_global.AntiAimEnabled then
            if env_global.AntiAimMode == "Jitter" then
                -- 快速抖動角度
                local jitter = math.random(-180, 180)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(jitter), 0)
            elseif env_global.AntiAimMode == "Spin" then
                -- 獨立於 Spinbot 的旋轉
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(25), 0)
            elseif env_global.AntiAimMode == "Backwards" then
                -- 始終背對
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)
            end
        end
    end)

    -- [[ Hitbox Expander 循環 ]]
    task.spawn(function()
        while task.wait(1) do
            if env_global.HitboxExpanderEnabled then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character then
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            head.Size = Vector3.new(env_global.HitboxSize, env_global.HitboxSize, env_global.HitboxSize)
                            head.Transparency = 0.5
                            head.CanCollide = false
                        end
                    end
                end
            end
        end
    end)

    -- [[ 全圖殺敵核心邏輯 ]]
    task.spawn(function()
        while task.wait() do
            if env_global.KillAll then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        local isTeammate = (player.Team == lp.Team and player.Team ~= nil)
                        
                        if hum and hum.Health > 0 and (not env_global.TeamCheck or not isTeammate) then
                            local weapon = GetCurrentWeapon()
                            if weapon then
                                -- 模擬射擊封包 (需配合靜默自瞄的 Hook)
                                -- 這裡觸發武器的射擊邏輯，具體取決於遊戲的 Remote 名稱
                                -- 我們透過 Hook Namecall 已經實現了自動重定向子彈
                                pcall(function()
                                    -- 如果有自動射擊 API 則調用
                                    local remote = weapon:FindFirstChild("RemoteEvent") or weapon:FindFirstChildOfClass("RemoteEvent")
                                    if remote then
                                        remote:FireServer(player.Character.Head.Position)
                                    end
                                end)
                                task.wait(env_global.KillAllDelay)
                            end
                        end
                    end
                    if not env_global.KillAll then break end
                end
            end
        end
    end)

    print("[Halol] 戰鬥模組已啟動")
end

return Combat

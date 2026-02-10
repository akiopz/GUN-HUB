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
    local TweenService = game:GetService("TweenService")
    local CollectionService = game:GetService("CollectionService")

    -- [[ 性能優化：快取常用函數 ]]
    local Vector2_new = Vector2.new
    local Vector3_new = Vector3.new
    local CFrame_new = CFrame.new
    local math_huge = math.huge
    local math_abs = math.abs
    local math_clamp = math.clamp
    local math_sin = math.sin
    local math_cos = math.cos
    local tick = tick
    local task_wait = task.wait
    local task_spawn = task.spawn
    local task_delay = task.delay
    local table_insert = table.insert
    local table_remove = table.remove

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
    env_global.MagicBulletPrediction = env_global.MagicBulletPrediction or false
    env_global.MagicBulletWallbang = env_global.MagicBulletWallbang or true
    env_global.MagicBulletHoming = env_global.MagicBulletHoming or false
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
    env_global.SpinbotMode = env_global.SpinbotMode or "Normal" -- "Normal", "Jitter", "Vertical", "Chaos"
    env_global.AntiAimEnabled = env_global.AntiAimEnabled or false
    env_global.AntiAimMode = env_global.AntiAimMode or "Jitter" -- "Jitter", "Spin", "Backwards", "Headless"
    env_global.TeleportKillEnabled = env_global.TeleportKillEnabled or false
    env_global.InstaKillEnabled = env_global.InstaKillEnabled or false
    env_global.ShieldEnabled = env_global.ShieldEnabled or false
    env_global.InfiniteAmmoEnabled = env_global.InfiniteAmmoEnabled or false
    env_global.RapidFireEnabled = env_global.RapidFireEnabled or false
    env_global.InstaReloadEnabled = env_global.InstaReloadEnabled or false
    env_global.AimbotNPCs = env_global.AimbotNPCs or false
    env_global.TeamCheck = env_global.TeamCheck or true
    env_global.AimbotVisibleOnly = env_global.AimbotVisibleOnly or true
    env_global.AimbotFOVVisible = env_global.AimbotFOVVisible or true
    env_global.AimbotFOVColor = env_global.AimbotFOVColor or Color3.fromRGB(0, 150, 255)
    env_global.AimbotAutoShoot = env_global.AimbotAutoShoot or false
    env_global.AimbotWallCheck = env_global.AimbotWallCheck or true
    env_global.AimbotFOVTransparency = env_global.AimbotFOVTransparency or 0.5
    env_global.AimbotFOVSides = env_global.AimbotFOVSides or 64
    env_global.AimbotTargetVisualizer = env_global.AimbotTargetVisualizer or false
    env_global.AimbotTargetLine = env_global.AimbotTargetLine or false
    env_global.TriggerBotEnabled = env_global.TriggerBotEnabled or false
    env_global.TriggerBotDelay = env_global.TriggerBotDelay or 0
    env_global.BulletPathEnabled = env_global.BulletPathEnabled or false
    env_global.BulletPathColor = env_global.BulletPathColor or Color3.fromRGB(255, 0, 0)
    env_global.BulletPathDuration = env_global.BulletPathDuration or 1

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
        Callback = function(state) env_global.SpinbotEnabled = state end
    })

    Core.UI.AddDropdown("SpinbotMode", {
        Name = "陀螺模式",
        Category = "Rage",
        Options = {"Normal", "Jitter", "Vertical", "Chaos"},
        Default = "Normal",
        Callback = function(v) env_global.SpinbotMode = v end
    })

    Core.UI.AddSlider("SpinbotSpeed", {
        Name = "旋轉速度",
        Category = "Rage",
        Min = 10,
        Max = 200,
        Default = 50,
        Callback = function(v) env_global.SpinbotSpeed = v end
    })

    Core.RegisterFeature("AntiAim", {
        Name = "反自瞄 (Anti-Aim)",
        Category = "Rage",
        Callback = function(state) env_global.AntiAimEnabled = state end
    })

    Core.UI.AddDropdown("AntiAimMode", {
        Name = "反自瞄模式",
        Category = "Rage",
        Options = {"Jitter", "Spin", "Backwards", "Headless"},
        Default = "Jitter",
        Callback = function(v) env_global.AntiAimMode = v end
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

    Core.RegisterFeature("MagicBulletPrediction", {
        Name = "魔法預測 (Magic Prediction)",
        Description = "為魔法子彈增加移動預測，提高命中率",
        Category = "Rage",
        Callback = function(state) env_global.MagicBulletPrediction = state end
    })

    Core.RegisterFeature("MagicBulletWallbang", {
        Name = "魔法穿牆 (Magic Wallbang)",
        Description = "魔法子彈是否直接無視所有障礙物",
        Category = "Rage",
        Callback = function(state) env_global.MagicBulletWallbang = state end
    })

    Core.RegisterFeature("MagicBulletHoming", {
        Name = "彈道追蹤 (Bullet Homing)",
        Description = "使實體子彈(Projectile)具備自動追蹤能力",
        Category = "Rage",
        Callback = function(state) env_global.MagicBulletHoming = state end
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

    Core.RegisterFeature("AimbotSticky", {
        Name = "強制鎖定 (Sticky Aim)",
        Description = "開啟後即使不點擊也會自動鎖定目標",
        Category = "Combat",
        Default = false,
        Callback = function(state)
            env_global.AimbotSticky = state
        end
    })

    Core.RegisterFeature("TriggerBot", {
        Name = "自動扳機 (Trigger Bot)",
        Category = "Combat",
        Callback = function(state) env_global.TriggerBotEnabled = state end
    })

    Core.RegisterFeature("AimbotTargetVisualizer", {
        Name = "目標指示器 (Target UI)",
        Category = "Combat",
        Callback = function(state) env_global.AimbotTargetVisualizer = state end
    })

    Core.RegisterFeature("AimbotTargetLine", {
        Name = "目標連線 (Target Line)",
        Category = "Combat",
        Callback = function(state) env_global.AimbotTargetLine = state end
    })

    Core.RegisterFeature("BulletPath", {
        Name = "彈道顯示 (Bullet Path)",
        Category = "Combat",
        Callback = function(state) env_global.BulletPathEnabled = state end
    })

    Core.RegisterFeature("AimbotNPCs", {
        Name = "瞄準 NPC (Target NPCs)",
        Description = "使自動瞄準與靜默自瞄支援非玩家角色 (NPC)",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotNPCs = state
        end
    })

    Core.RegisterFeature("TeamCheck", {
        Name = "隊友檢查 (Team Check)",
        Description = "開啟後自動瞄準將不會鎖定同隊玩家",
        Category = "Combat",
        Callback = function(state)
            env_global.TeamCheck = state
        end
    })

    Core.UI.AddDropdown("AimbotTargetPart", {
        Name = "瞄準部位",
        Category = "Combat",
        Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
        Default = "Head",
        Callback = function(v) env_global.AimbotTargetPart = v end
    })

    Core.UI.AddDropdown("AimbotPriority", {
        Name = "優先順序",
        Category = "Combat",
        Options = {"Mouse", "Distance", "Health"},
        Default = "Mouse",
        Callback = function(v) env_global.AimbotPriority = v end
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
        Max = 100,
        Default = env_global.AimbotSmoothness * 100,
        Callback = function(v) env_global.AimbotSmoothness = v / 100 end
    })

    Core.RegisterFeature("AimbotWallCheck", {
        Name = "牆壁檢查 (Wall Check)",
        Description = "開啟後自動瞄準將不會鎖定障礙物後的玩家",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotWallCheck = state
            env_global.AimbotVisibilityCheck = state
        end
    })

    Core.RegisterFeature("AimbotFOVVisible", {
        Name = "顯示範圍 (Show FOV)",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotFOVVisible = state
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

    Core.RegisterFeature("AimbotPrediction", {
        Name = "自動瞄準預測 (Prediction)",
        Description = "開啟後自動瞄準會預測目標移動位置",
        Category = "Combat",
        Callback = function(state)
            env_global.AimbotPrediction = state
        end
    })

    Core.UI.AddSlider("AimbotBulletSpeed", {
        Name = "子彈速度 (彈道預測用)",
        Category = "Combat",
        Min = 100,
        Max = 5000,
        Default = 1000,
        Callback = function(v) env_global.AimbotBulletSpeed = v end
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

    Core.UI.AddSlider("SilentAimFOV", {
        Name = "靜默瞄準範圍 (FOV)",
        Category = "Rage",
        Min = 10,
        Max = 1000,
        Default = env_global.SilentAimFOV,
        Callback = function(v) env_global.SilentAimFOV = v end
    })

    Core.UI.AddSlider("SilentAimHitChance", {
        Name = "靜默瞄準命中率",
        Category = "Rage",
        Min = 0,
        Max = 100,
        Default = env_global.SilentAimHitChance,
        Callback = function(v) env_global.SilentAimHitChance = v end
    })

    Core.UI.AddSlider("HitboxSize", {
        Name = "碰撞箱大小",
        Category = "Rage",
        Min = 1,
        Max = 20,
        Default = env_global.HitboxSize,
        Callback = function(v) env_global.HitboxSize = v end
    })

    Core.UI.AddSlider("DamageMultiplierValue", {
        Name = "傷害倍率數值",
        Category = "Rage",
        Min = 1,
        Max = 10,
        Default = env_global.DamageMultiplier,
        Callback = function(v) env_global.DamageMultiplier = v end
    })

    Core.UI.AddSlider("TriggerBotDelay", {
        Name = "自動扳機延遲 (ms)",
        Category = "Combat",
        Min = 0,
        Max = 1000,
        Default = env_global.TriggerBotDelay * 1000,
        Callback = function(v) env_global.TriggerBotDelay = v / 1000 end
    })

    Core.UI.AddColorPicker("AimbotFOVColor", {
        Name = "自瞄範圍顏色",
        Category = "Combat",
        Default = env_global.AimbotFOVColor,
        Callback = function(color) env_global.AimbotFOVColor = color end
    })

    Core.UI.AddSlider("KillAllDelay", {
        Name = "全場擊殺延遲 (s)",
        Category = "Rage",
        Min = 0,
        Max = 5,
        Default = env_global.KillAllDelay,
        Callback = function(v) env_global.KillAllDelay = v end
    })

    Core.UI.AddSlider("AimbotPredictionAmount", {
        Name = "自瞄預測強度",
        Category = "Combat",
        Min = 0,
        Max = 20,
        Default = env_global.AimbotPredictionAmount * 10,
        Callback = function(v) env_global.AimbotPredictionAmount = v / 10 end
    })

    Core.UI.AddSlider("AimbotFOVSides", {
        Name = "FOV 圓形邊數",
        Category = "Visuals",
        Min = 3,
        Max = 64,
        Default = env_global.AimbotFOVSides,
        Callback = function(v) env_global.AimbotFOVSides = v end
    })

    Core.UI.AddSlider("BulletPathDuration", {
        Name = "彈道顯示時間",
        Category = "Combat",
        Min = 1,
        Max = 10,
        Default = env_global.BulletPathDuration,
        Callback = function(v) env_global.BulletPathDuration = v end
    })

    Core.UI.AddDropdown("AimbotTarget", {
        Name = "自瞄部位",
        Category = "Combat",
        Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
        Default = env_global.AimbotTarget,
        Callback = function(v) env_global.AimbotTarget = v end
    })

    Core.UI.AddSlider("AimbotSmoothness", {
        Name = "自瞄平滑度",
        Category = "Combat",
        Min = 1,
        Max = 20,
        Default = env_global.AimbotSmoothness,
        Callback = function(v) env_global.AimbotSmoothness = v end
    })

    Core.UI.AddSlider("SpinbotSpeedValue", {
        Name = "陀螺旋轉速度",
        Category = "Rage",
        Min = 1,
        Max = 100,
        Default = env_global.SpinbotSpeed,
        Callback = function(v) env_global.SpinbotSpeed = v end
    })

    Core.UI.AddSlider("AimbotFOVTransparency", {
        Name = "FOV 圓形透明度",
        Category = "Visuals",
        Min = 0,
        Max = 100,
        Default = env_global.AimbotFOVTransparency * 100,
        Callback = function(v) env_global.AimbotFOVTransparency = v / 100 end
    })

    Core.UI.AddColorPicker("BulletPathColor", {
        Name = "彈道顏色",
        Category = "Combat",
        Default = env_global.BulletPathColor,
        Callback = function(color) env_global.BulletPathColor = color end
    })

    -- [[ 性能優化：Raycast 快取 ]]
    local raycastCache = {}
    
    -- [[ Aimbot 平滑曲線優化 ]]
    local function GetSmoothStep(t)
        -- 使用 Bezier 或 Sine 曲線使瞄準更自然
        return t * t * (3 - 2 * t)
    end

    -- [[ 戰鬥視覺效果 ]]
    local TargetCircle = Drawing.new("Circle")
    TargetCircle.Thickness = 1
    TargetCircle.NumSides = 64
    TargetCircle.Radius = 5
    TargetCircle.Filled = false
    TargetCircle.Visible = false
    TargetCircle.Color = Color3.fromRGB(255, 0, 0)

    local TargetLine = Drawing.new("Line")
    TargetLine.Thickness = 1
    TargetLine.Transparency = 1
    TargetLine.Visible = false
    TargetLine.Color = Color3.fromRGB(255, 0, 0)

    local function DrawBulletPath(from, to)
        if not env_global.BulletPathEnabled then return end
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = env_global.BulletPathColor
        line.From = from
        line.To = to
        line.Visible = true
        task.delay(env_global.BulletPathDuration, function()
            line:Remove()
        end)
    end
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
            -- 增加半透明物件與不可碰撞物件的穿透邏輯
            isVisible = hit:IsDescendantOf(part.Parent) or hit.Transparency > 0.8 or not hit.CanCollide
        end

        -- 更新快取
        raycastCache[cacheKey] = {
            visible = isVisible,
            time = now
        }

        return isVisible
    end

    -- [[ 進階預測邏輯 ]]
    local function GetPredictedPosition(targetPart, bulletSpeed)
        if not targetPart or not targetPart.Parent then return nil end
        local character = targetPart.Parent
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return targetPart.Position end

        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local distance = (targetPos - origin).Magnitude
        
        -- 考慮 Ping 的基礎預測
        local ping = 0
        if env_global.AimbotPingCompensation then
            -- 嘗試獲取延遲，如果無法獲取則使用預設值 (100ms)
            ping = (Core.Stats and Core.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 100) / 1000
        end

        local timeToHit = (distance / bulletSpeed) + ping
        local velocity = root.Velocity
        
        -- 核心預測計算
        local predictedPos = targetPos + (velocity * timeToHit)
        
        -- 重力補償
        local gravity = env_global.AimbotGravity or 196.2
        predictedPos = predictedPos + Vector3_new(0, 0.5 * gravity * (timeToHit ^ 2), 0)
        
        -- 加速度補償 (檢測跳躍或急停)
        if velocity.Y > 5 or velocity.Y < -5 then
            predictedPos = predictedPos + Vector3_new(0, (velocity.Y * timeToHit * 0.2), 0)
        end

        return predictedPos
    end

    -- [[ NPC 快取系統 ]]
    local npcCache = {}
    task_spawn(function()
        while true do
            if env_global.AimbotNPCs then
                local newCache = {}
                -- 優先檢查常見的 NPC 容器
                local searchRoots = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Zombies"), workspace:FindFirstChild("Enemies")}
                if #searchRoots == 0 then table_insert(searchRoots, workspace) end

                for _, root in ipairs(searchRoots) do
                    if root then
                        for _, obj in ipairs(root:GetChildren()) do
                            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                                if humanoid and humanoid.Health > 0 then
                                    table_insert(newCache, obj)
                                end
                            end
                        end
                    end
                end
                npcCache = newCache
            else
                npcCache = {}
            end
            task_wait(3) -- 稍微增加間隔以節省性能
        end
    end)

    -- [[ NPC 與隊友檢查優化 ]]
    local function GetTeamColor(player)
        return player.TeamColor.Color
    end

    function Combat.GetNearestEnemy()
        local nearest = nil
        local bestScore = math.huge -- 分數越低越優先
        local mousePos = UserInputService:GetMouseLocation()
        local localChar = lp.Character
        local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
        
        -- 智慧黏性目標加成 (權重係數 0.7)
        local stickyBonus = env_global.AimbotSticky and 0.7 or 1.0

        -- 獲取所有潛在目標
        local targets = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                local isEnemy = not env_global.TeamCheck or Core.IsEnemy(player.Character)
                if isEnemy then
                    table.insert(targets, {char = player.Character, isNPC = false})
                end
            end
        end
        if env_global.AimbotNPCs then
            for _, npc in ipairs(npcCache) do
                if npc.Parent then
                    local isEnemy = not env_global.TeamCheck or Core.IsEnemy(npc)
                    if isEnemy then
                        table.insert(targets, {char = npc, isNPC = true})
                    end
                end
            end
        end

        for _, targetInfo in ipairs(targets) do
            local char = targetInfo.char
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- 智慧多骨骼掃描：優先目標骨骼，其次 Head，最後 Torso
                local targetBoneName = env_global.AimbotTargetPart or "Head"
                local bones = {targetBoneName, "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}
                local bestBoneForThisChar = nil
                
                for _, boneName in ipairs(bones) do
                    local bone = char:FindFirstChild(boneName)
                    if bone then
                        -- 可見度與牆壁檢查
                        if env_global.MagicBullet or not env_global.AimbotWallCheck or IsVisible(bone, localChar) then
                            bestBoneForThisChar = bone
                            break 
                        end
                        if not env_global.AimbotMultiBone then break end
                    end
                end

                if bestBoneForThisChar then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(bestBoneForThisChar.Position)
                    local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    -- 基本過濾：FOV 或 MagicBullet
                    if (onScreen or env_global.MagicBullet) and (mouseDistance <= env_global.AimbotFOV or env_global.MagicBullet) then
                        local worldDist = localHrp and (bestBoneForThisChar.Position - localHrp.Position).Magnitude or 0
                        local health = hum.Health
                        
                        -- 智慧評分系統 (Smart Scoring)
                        local score = 0
                        if env_global.AimbotPriority == "Mouse" then
                            score = mouseDistance + (worldDist * 0.05) -- 距離稍微影響分數
                        elseif env_global.AimbotPriority == "Distance" then
                            score = worldDist + (mouseDistance * 0.2)
                        elseif env_global.AimbotPriority == "Health" then
                            score = (health * 5) + (mouseDistance * 1.0)
                        end
                        
                        -- 黏性目標加成 (分數越低越優先)
                        if lastTarget and (bestBoneForThisChar == lastTarget or bestBoneForThisChar.Parent == lastTarget.Parent) then
                            score = score * stickyBonus
                        end
                        
                        -- NPC 權重稍微降低 (如果是玩家，分數更低)
                        if targetInfo.isNPC then
                            score = score * 1.5
                        end

                        if score < bestScore then
                            bestScore = score
                            nearest = bestBoneForThisChar
                        end
                    end
                end
            end
        end

        lastTarget = nearest
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

    Core.UI.AddSlider("KillAllDelay", {
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
            local remoteName = tostring(self)

            if not checkcaller() then
                -- 自動射擊增強：攔截並重定向射擊 Remote
                if env_global.AutoShoot and (method == "FireServer" or method == "InvokeServer") then
                    if remoteName:lower():find("fire") or remoteName:lower():find("shoot") or remoteName:lower():find("hit") then
                        local target = Combat.GetNearestEnemy()
                        if target and env_global.AimbotEnabled then
                            -- 如果檢測到正在嘗試射擊，將參數中的位置或目標重定向到自瞄目標
                            for i, v in ipairs(args) do
                                if typeof(v) == "Vector3" then
                                    args[i] = target.Position
                                elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                                    args[i] = target
                                end
                            end
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
                -- 靜默自瞄 & 魔法子彈 (Raycast 繞過)
                if env_global.SilentAimEnabled or env_global.MagicBullet then
                    if method == "Raycast" then
                        local target = Combat.GetNearestEnemy()
                        if target and (env_global.MagicBullet or math.random(1, 100) <= env_global.SilentAimHitChance) then
                            local origin = args[1]
                            local targetPos = target.Position
                            
                            -- 強化預測 (動態預測)
                            if (env_global.MagicBulletPrediction or env_global.AimbotPrediction) and target.Parent then
                                local hum = target.Parent:FindFirstChildOfClass("Humanoid")
                                local root = hum and hum.RootPart
                                if root then
                                    local dist = (origin - targetPos).Magnitude
                                    local bulletSpeed = env_global.AimbotBulletSpeed or 1000
                                    local timeToHit = dist / bulletSpeed
                                    
                                    -- 考慮加速度的預測
                                    local velocity = root.Velocity
                                    local acceleration = Vector3.new(0, (velocity.Y > 2 or velocity.Y < -2) and -196.2 or 0, 0)
                                    targetPos = targetPos + (velocity * timeToHit) + (0.5 * acceleration * (timeToHit ^ 2))
                                    
                                    -- 重力補償
                                    local gravity = env_global.AimbotGravity or 196.2
                                    targetPos = targetPos + Vector3.new(0, 0.5 * gravity * (timeToHit ^ 2), 0)
                                end
                            end

                            -- 魔法子彈 & 智慧彈道 (Smart Pathfinding)
                            if env_global.MagicBullet then
                                local params = RaycastParams.new()
                                if env_global.MagicBulletWallbang then
                                    -- 穿牆模式：只過濾自己，不檢查障礙物
                                    params.FilterType = Enum.RaycastFilterType.Include
                                    params.FilterDescendantsInstances = {target.Parent}
                                else
                                    -- 繞過障礙物模式：動態尋找最佳路徑
                                    params.FilterType = Enum.RaycastFilterType.Exclude
                                    params.FilterDescendantsInstances = {lp.Character, Camera}
                                end
                                args[3] = params
                            end

                            local direction = (targetPos - origin).Unit * 20000 -- 更大的射程
                            args[2] = direction
                            
                            -- 繪製彈道
                            local _, onScreenFrom = Camera:WorldToViewportPoint(origin)
                            local vTo, onScreenTo = Camera:WorldToViewportPoint(targetPos)
                            if onScreenFrom or onScreenTo then
                                local vFrom = Camera:WorldToViewportPoint(origin)
                                DrawBulletPath(Vector2.new(vFrom.X, vFrom.Y), Vector2.new(vTo.X, vTo.Y))
                            end
                            
                            return oldNamecall(self, unpack(args))
                        end
                    elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                        local target = Combat.GetNearestEnemy()
                        if target and (env_global.MagicBullet or math.random(1, 100) <= env_global.SilentAimHitChance) then
                            local origin = args[1].Origin
                            local targetPos = target.Position
                            
                            -- 強化預測 (動態預測)
                            if (env_global.MagicBulletPrediction or env_global.AimbotPrediction) and target.Parent then
                                local hum = target.Parent:FindFirstChildOfClass("Humanoid")
                                local root = hum and hum.RootPart
                                if root then
                                    local dist = (origin - targetPos).Magnitude
                                    local bulletSpeed = env_global.AimbotBulletSpeed or 1000
                                    local timeToHit = dist / bulletSpeed
                                    
                                    -- 考慮加速度的預測
                                    local velocity = root.Velocity
                                    local acceleration = Vector3.new(0, (velocity.Y > 2 or velocity.Y < -2) and -196.2 or 0, 0)
                                    targetPos = targetPos + (velocity * timeToHit) + (0.5 * acceleration * (timeToHit ^ 2))
                                    
                                    -- 重力補償
                                    local gravity = env_global.AimbotGravity or 196.2
                                    targetPos = targetPos + Vector3.new(0, 0.5 * gravity * (timeToHit ^ 2), 0)
                                end
                            end

                            local direction = (targetPos - origin).Unit * 20000
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
                            local multiplier = tonumber(env_global.DamageMultiplier) or 1
                            for i, v in ipairs(args) do
                                if type(v) == "number" and v > 0 then
                                    args[i] = v * multiplier
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
                                        local multiplier = tonumber(env_global.DamageMultiplier) or 1
                                        for i = 1, multiplier do
                                            self[method](self, unpack(newArgs))
                                        end
                                        -- 觸發命中標記
                                        if Core.Visuals and Core.Visuals.ShowHitMarker then
                                            Core.Visuals.ShowHitMarker()
                                        end
                                    end)
                                else
                                    self[method](self, unpack(newArgs))
                                    -- 觸發命中標記
                                    if Core.Visuals and Core.Visuals.ShowHitMarker then
                                        Core.Visuals.ShowHitMarker()
                                    end
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
        
        -- [[ 彈道追蹤 (Homing Projectiles) ]]
    task.spawn(function()
        while task.wait(0.1) do
            if env_global.MagicBullet and env_global.MagicBulletHoming then
                local target = Combat.GetNearestEnemy()
                if target then
                    -- 掃描 workspace 中的新子彈實體
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if (obj:IsA("BasePart") or obj:IsA("Model")) and (obj.Name:lower():find("bullet") or obj.Name:lower():find("projectile") or obj.Name:lower():find("shot")) then
                            -- 如果是子彈且距離玩家較近 (假設是自己射的)
                            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (obj:GetPivot().Position - hrp.Position).Magnitude < 50 then
                                -- 轉向目標
                                local targetPos = target.Position
                                if obj:IsA("BasePart") then
                                    obj.CFrame = CFrame.new(obj.Position, targetPos)
                                    obj.Velocity = (targetPos - obj.Position).Unit * obj.Velocity.Magnitude
                                else
                                    obj:PivotTo(CFrame.new(obj:GetPivot().Position, targetPos))
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    print("[Halol] 強化 Combat Hooks 已啟動")
end -- 閉合 SetupSilentAim

    -- 啟動所有循環與 Hook
    SetupSilentAim()
    
    -- [[ Aimbot 循環 ]]
    local fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1
    fovCircle.NumSides = env_global.AimbotFOVSides or 64
    fovCircle.Radius = env_global.AimbotFOV
    fovCircle.Filled = false
    fovCircle.Transparency = env_global.AimbotFOVTransparency or 0.5
    fovCircle.Color = env_global.AimbotFOVColor

    RunService.RenderStepped:Connect(function()
        local now = tick()
        -- 計算彩虹顏色
        local rainbowColor = Color3.fromHSV((now * (env_global.ESPRainbowSpeed or 1) * 0.1) % 1, 1, 1)
        local mousePos = UserInputService:GetMouseLocation()

        -- 更新 FOV 圓圈
        if env_global.AimbotFOVVisible and env_global.AimbotEnabled then
            fovCircle.Position = mousePos
            fovCircle.Radius = env_global.AimbotFOV
            fovCircle.Color = env_global.ESPRainbow and rainbowColor or env_global.AimbotFOVColor
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end

        if env_global.AimbotEnabled then
            -- 檢查自瞄狀態
            local isKeyDown = env_global.AimbotSticky or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

            local target = isKeyDown and Combat.GetNearestEnemy() or nil
            
            -- Aimbot 執行
            if target then
                local targetPos = target.Position
                -- 核心預測邏輯應用
                if env_global.AimbotPrediction then
                    local bulletSpeed = env_global.AimbotBulletSpeed or 1000
                    local predicted = GetPredictedPosition(target, bulletSpeed)
                    if predicted then targetPos = predicted end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                if onScreen then
                    local targetScreenPos = Vector2_new(screenPos.X, screenPos.Y)
                    local smoothness = env_global.AimbotSmoothness or 0.15
                    
                    if env_global.AimbotRageMode then
                        smoothness = 0
                    end

                    if smoothness > 0 then
                        -- 使用 GetSmoothStep 優化平滑曲線
                        local currentMousePos = UserInputService:GetMouseLocation()
                        local diff = (targetScreenPos - currentMousePos)
                        local moveAmount = diff * GetSmoothStep(math_clamp(1 / (smoothness * 60), 0, 1))
                        mousemoverel(moveAmount.X, moveAmount.Y)
                    else
                        -- Rage 模式或 0 平滑度：直接移動
                        local currentMousePos = UserInputService:GetMouseLocation()
                        local diff = (targetScreenPos - currentMousePos)
                        mousemoverel(diff.X, diff.Y)
                    end
                end
            end

            -- 更新目標指示器與連線 (優化：合併判斷)
            local showVisuals = target and target.Parent and (env_global.AimbotTargetVisualizer or env_global.AimbotTargetLine)
            if showVisuals and target then
                local targetPos = target.Position
                if targetPos then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local targetScreenPos = Vector2_new(pos.X, pos.Y)
                        local color = env_global.ESPRainbow and rainbowColor or Color3.fromRGB(255, 0, 0)
                        
                        if env_global.AimbotTargetVisualizer then
                            TargetCircle.Position = targetScreenPos
                            TargetCircle.Color = color
                            TargetCircle.Visible = true
                        else
                            TargetCircle.Visible = false
                        end

                        if env_global.AimbotTargetLine then
                            TargetLine.From = mousePos
                            TargetLine.To = targetScreenPos
                            TargetLine.Color = color
                            TargetLine.Visible = true
                        else
                            TargetLine.Visible = false
                        end
                    else
                        TargetCircle.Visible = false
                        TargetLine.Visible = false
                    end
                end
            else
                TargetCircle.Visible = false
                TargetLine.Visible = false
            end

            -- 自動扳機 (Trigger Bot) - 優化：降低頻率或僅在瞄準時檢查
            if env_global.TriggerBotEnabled and (now % 0.05 < 0.01) then
                local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {lp.Character, Camera}
                
                local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                local hitPart = result and result.Instance
                if hitPart then
                    local model = hitPart:FindFirstAncestorOfClass("Model")
                    local hum = model and model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local player = Players:GetPlayerFromCharacter(model)
                        if player ~= lp and (not env_global.TeamCheck or not Core.IsTeammate(player)) then
                            task_delay(env_global.TriggerBotDelay, mouse1click)
                        end
                    end
                end
            end

            if target then
                local targetPos = target.Position
                local char = target.Parent
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                -- 強化預測與重力補償 (動態自適應)
                if (env_global.AimbotPrediction or env_global.AimbotRageMode) and root then
                    local camPos = Camera.CFrame.Position
                    local dist = (camPos - targetPos).Magnitude
                    local bulletSpeed = env_global.AimbotBulletSpeed or 1000
                    
                    local timeToHit = dist / bulletSpeed
                    
                    if env_global.AimbotPingCompensation then
                        timeToHit = timeToHit + ((tonumber(lp:GetNetworkPing()) or 0.05) * 0.8)
                    end
                    
                    local velocity = root.Velocity
                    local acceleration = (velocity.Y > 2 or velocity.Y < -2) and Vector3_new(0, -196.2, 0) or Vector3_new(0, 0, 0)

                    local predictionOffset = (velocity * timeToHit) + (0.5 * acceleration * (timeToHit ^ 2))
                    
                    -- 抖動補償
                    if velocity.Magnitude > 25 then
                        predictionOffset = predictionOffset * 1.1
                    end

                    targetPos = targetPos + predictionOffset
                    
                    -- 重力補償
                    local gravity = env_global.AimbotGravity or 196.2
                    targetPos = targetPos + Vector3_new(0, 0.5 * gravity * (timeToHit ^ 2), 0)
                end
                
                local currentCF = Camera.CFrame
                local targetCF = CFrame_new(currentCF.Position, targetPos)
                
                -- 智慧平滑曲線 (Bezier-like Smoothness)
                if env_global.AimbotRageMode then
                    Camera.CFrame = targetCF
                elseif env_global.AimbotSmoothness > 0 then
                    local smoothness = math_clamp(env_global.AimbotSmoothness, 0.01, 1)
                    local alpha = 1 / (smoothness * 100)
                    
                    -- 使用更加平滑的 Lerp
                    Camera.CFrame = currentCF:Lerp(targetCF, math_clamp(alpha, 0, 1))
                else
                    Camera.CFrame = targetCF
                end

                -- [[ 增強型自動射擊邏輯 ]]
                if env_global.AutoShoot then
                    local weapon = GetCurrentWeapon()
                    if weapon then
                        local remote = weapon:FindFirstChild("RemoteEvent") 
                            or weapon:FindFirstChildOfClass("RemoteEvent") 
                            or weapon:FindFirstChild("Fire")
                            or weapon:FindFirstChild("Shoot")
                            or weapon:FindFirstChild("Input")
                            or (weapon:FindFirstChild("Remotes") and weapon.Remotes:FindFirstChildOfClass("RemoteEvent"))

                        if remote then
                            remote:FireServer(targetPos)
                            -- 某些遊戲需要額外參數，使用 pcall 避免崩潰
                            pcall(function()
                                remote:FireServer({
                                    [1] = targetPos,
                                    ["Hit"] = target,
                                    ["Distance"] = (lp.Character.Head.Position - targetPos).Magnitude
                                })
                            end)
                        end
                    end
                end
            end
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
    local verticalAngle = 0
    RunService.Heartbeat:Connect(function()
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hrp) then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        -- 大陀螺邏輯 (Spinbot)
        if env_global.SpinbotEnabled then
            local speed = env_global.SpinbotSpeed
            rageAngle = (rageAngle + speed) % 360
            
            local newCF = CFrame.new(hrp.Position)
            
            if env_global.SpinbotMode == "Normal" then
                hrp.CFrame = newCF * CFrame.Angles(0, math.rad(rageAngle), 0)
            elseif env_global.SpinbotMode == "Jitter" then
                local jitter = math.random(-45, 45)
                hrp.CFrame = newCF * CFrame.Angles(0, math.rad(rageAngle + jitter), 0)
            elseif env_global.SpinbotMode == "Vertical" then
                verticalAngle = (verticalAngle + speed * 0.5) % 360
                hrp.CFrame = newCF * CFrame.Angles(math.rad(verticalAngle), math.rad(rageAngle), 0)
            elseif env_global.SpinbotMode == "Chaos" then
                local rx = math.random(-180, 180)
                local ry = math.random(-180, 180)
                local rz = math.random(-180, 180)
                hrp.CFrame = newCF * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
            end
        end

        -- 反自瞄邏輯 (Anti-Aim)
        if env_global.AntiAimEnabled then
            if env_global.AntiAimMode == "Jitter" then
                -- 快速抖動角度
                local jitter = math.random(-180, 180)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(jitter), 0)
            elseif env_global.AntiAimMode == "Spin" then
                -- 獨立於 Spinbot 的旋轉
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(25), 0)
            elseif env_global.AntiAimMode == "Backwards" then
                -- 始終背對 (假設相機方向是正向)
                local camLook = Camera.CFrame.LookVector
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position - Vector3.new(camLook.X, 0, camLook.Z))
            elseif env_global.AntiAimMode == "Headless" then
                -- 偽裝成斷頭 (向下看 90 度，但在伺服器端可能導致碰撞箱異常)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
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
                        local isTeammate = Core.IsTeammate(player)
                        
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

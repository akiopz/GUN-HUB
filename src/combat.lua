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

    -- [[ 預設配置 ]]
    env_global.AimbotEnabled = env_global.AimbotEnabled or false
    env_global.AimbotSmoothness = env_global.AimbotSmoothness or 0.15
    env_global.AimbotFOV = env_global.AimbotFOV or 150
    env_global.AimbotTargetPart = env_global.AimbotTargetPart or "Head"
    env_global.AimbotVisibilityCheck = env_global.AimbotVisibilityCheck or false
    env_global.AimbotPriority = env_global.AimbotPriority or "Mouse" -- "Mouse", "Distance"
    env_global.AimbotPrediction = env_global.AimbotPrediction or false
    env_global.AimbotPredictionAmount = env_global.AimbotPredictionAmount or 0.165
    env_global.SilentAimEnabled = env_global.SilentAimEnabled or false
    env_global.SilentAimFOV = env_global.SilentAimFOV or 200
    env_global.SilentAimHitChance = env_global.SilentAimHitChance or 100
    env_global.NoRecoilEnabled = env_global.NoRecoilEnabled or false
    env_global.NoSpreadEnabled = env_global.NoSpreadEnabled or false
    env_global.RapidFireEnabled = env_global.RapidFireEnabled or false
    env_global.KillAllEnabled = env_global.KillAllEnabled or false
    env_global.HitboxExpanderEnabled = env_global.HitboxExpanderEnabled or false
    env_global.HitboxSize = env_global.HitboxSize or 5
    env_global.SpinbotEnabled = env_global.SpinbotEnabled or false
    env_global.SpinbotSpeed = env_global.SpinbotSpeed or 50
    env_global.AntiAimEnabled = env_global.AntiAimEnabled or false
    env_global.AntiAimMode = env_global.AntiAimMode or "Jitter" -- "Jitter", "Spin", "Backwards"
    env_global.TeleportKillEnabled = env_global.TeleportKillEnabled or false
    env_global.InstaKillEnabled = env_global.InstaKillEnabled or false
    env_global.ShieldEnabled = env_global.ShieldEnabled or false

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

    Core.RegisterFeature("KillAll", {
        Name = "全地圖殺敵 (Kill All)",
        Category = "Rage",
        Callback = function(state)
            env_global.KillAllEnabled = state
            if state then
                Core.Notify("暴力模式", "全地圖殺敵已啟動，請謹慎使用", 3)
            end
        end
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

    -- [[ 優化物件快取 ]]
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local function IsVisible(part, character)
        if not env_global.AimbotVisibilityCheck then return true end
        if not character then return false end
        
        local origin = Camera.CFrame.Position
        local destination = part.Position
        local direction = (destination - origin)
        
        raycastParams.FilterDescendantsInstances = {character, Camera, workspace:FindFirstChild("Terrain")}
        
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result then
            local hit = result.Instance
            return hit:IsDescendantOf(part.Parent) or hit.Transparency > 0.8 or not hit.CanCollide
        end
        return true
    end

    function Combat.GetNearestEnemy()
        local nearest = nil
        local maxDist = env_global.AimbotFOV
        local minDistanceToChar = math.huge
        local mousePos = UserInputService:GetMouseLocation()
        local localChar = lp.Character

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then
                -- 團隊檢查優化
                local isTeam = (player.Team == lp.Team and player.Team ~= nil)
                if not isTeam then
                    local char = player.Character
                    if char then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            local targetPart = char:FindFirstChild(env_global.AimbotTargetPart) or char:FindFirstChild("HumanoidRootPart")
                            if targetPart then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                                if onScreen then
                                    local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                    if mouseDistance < maxDist then
                                        -- 優先度邏輯
                                        if env_global.AimbotPriority == "Mouse" then
                                            if IsVisible(targetPart, localChar) then
                                                maxDist = mouseDistance
                                                nearest = targetPart
                                            end
                                        elseif env_global.AimbotPriority == "Distance" then
                                            local hrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
                                            local charDistance = hrp and (hrp.Position - targetPart.Position).Magnitude or 0
                                            if charDistance < minDistanceToChar then
                                                if IsVisible(targetPart, localChar) then
                                                    minDistanceToChar = charDistance
                                                    nearest = targetPart
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
        end
        return nearest
    end

    -- [[ Aimbot 循環 ]]
    local lastTarget = nil
    RunService.RenderStepped:Connect(function()
        if not env_global.AimbotEnabled then return end
        
        local target = Combat.GetNearestEnemy()
        if target then
            local targetPos = target.Position
            
            -- 預測邏輯優化
            if env_global.AimbotPrediction then
                local root = target.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    targetPos = targetPos + (root.Velocity * env_global.AimbotPredictionAmount)
                end
            end
            
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            
            -- 平滑度處理
            if env_global.AimbotSmoothness > 0 then
                Camera.CFrame = currentCF:Lerp(targetCF, env_global.AimbotSmoothness)
            else
                Camera.CFrame = targetCF
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

    print("[Halol] 戰鬥模組已啟動")
end

return Combat

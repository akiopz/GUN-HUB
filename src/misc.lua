---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Misc Module
-- 放置於: src/misc.lua

local Misc = {}

function Misc.Init(Core)
    ---@class GlobalEnv
    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    local lp = Core.LocalPlayer
    local Camera = Core.Camera
    local RunService = Core.RunService
    local UserInputService = Core.UserInputService

    -- [[ 配置初始化 ]]
    env_global.WalkSpeedEnabled = env_global.WalkSpeedEnabled or false
    env_global.WalkSpeed = env_global.WalkSpeed or 16
    env_global.CFrameSpeedEnabled = env_global.CFrameSpeedEnabled or false
    env_global.CFrameSpeed = env_global.CFrameSpeed or 1
    
    env_global.JumpPowerEnabled = env_global.JumpPowerEnabled or false
    env_global.JumpPower = env_global.JumpPower or 50
    env_global.InfJump = env_global.InfJump or false
    
    env_global.FlyEnabled = env_global.FlyEnabled or false
    env_global.FlySpeed = env_global.FlySpeed or 50
    env_global.VelocityFly = env_global.VelocityFly or false
    
    env_global.TeleportWalk = env_global.TeleportWalk or false
    env_global.TeleportWalkDist = env_global.TeleportWalkDist or 5

    env_global.Noclip = env_global.Noclip or false
    env_global.LavaNoclip = env_global.LavaNoclip or false
    env_global.NoSlow = env_global.NoSlow or false
    env_global.DesyncEnabled = env_global.DesyncEnabled or false
    env_global.DesyncAmount = env_global.DesyncAmount or 5
    env_global.Spider = env_global.Spider or false
    env_global.Bhop = env_global.Bhop or false
    env_global.SprintEnabled = env_global.SprintEnabled or false
    env_global.SprintMultiplier = env_global.SprintMultiplier or 1.5
    env_global.KillEffect = env_global.KillEffect or false
    env_global.KillSound = env_global.KillSound or false
    env_global.AntiAFK = env_global.AntiAFK or false
    env_global.AutoClicker = env_global.AutoClicker or false
    env_global.AutoClickDelay = env_global.AutoClickDelay or 0.1

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("WalkSpeedEnabled", {
        Name = "加速模式 (Speed Hack)",
        Description = "自定義移動速度",
        Category = "Movement",
        Callback = function(state) env_global.WalkSpeedEnabled = state end
    })

    Core.UI.AddSlider("WalkSpeedValue", {
        Name = "行走速度數值",
        Category = "Movement",
        Min = 16,
        Max = 500,
        Default = env_global.WalkSpeed,
        Callback = function(v) env_global.WalkSpeed = v end
    })

    Core.RegisterFeature("SprintEnabled", {
        Name = "衝刺模式 (Sprint)",
        Description = "按住 Shift 鍵進行衝刺",
        Category = "Movement",
        Callback = function(state) env_global.SprintEnabled = state end
    })

    Core.UI.AddSlider("SprintMultiplier", {
        Name = "衝刺速度倍率",
        Category = "Movement",
        Min = 1.1,
        Max = 10.0,
        Step = 0.1,
        Default = env_global.SprintMultiplier,
        Callback = function(v) env_global.SprintMultiplier = v end
    })

    Core.RegisterFeature("JumpPowerEnabled", {
        Name = "跳躍加強 (Jump Power)",
        Category = "Movement",
        Callback = function(state) env_global.JumpPowerEnabled = state end
    })

    Core.UI.AddSlider("JumpPowerValue", {
        Name = "跳躍高度數值",
        Category = "Movement",
        Min = 50,
        Max = 1000,
        Default = env_global.JumpPower,
        Callback = function(v) env_global.JumpPower = v end
    })

    Core.RegisterFeature("InfJump", {
        Name = "無限跳躍 (Inf Jump)",
        Category = "Movement",
        Callback = function(state) env_global.InfJump = state end
    })

    Core.RegisterFeature("Noclip", {
        Name = "穿牆 (Noclip)",
        Category = "Movement",
        Callback = function(state) env_global.Noclip = state end
    })

    Core.RegisterFeature("LavaNoclip", {
        Name = "穿過岩漿 (Lava Noclip)",
        Description = "使你能夠無視碰撞並穿過名為 Lava 或 Magma 的零件",
        Category = "Movement",
        Callback = function(state) env_global.LavaNoclip = state end
    })

    Core.RegisterFeature("FlyEnabled", {
        Name = "飛行模式 (Fly)",
        Category = "Movement",
        Callback = function(state) env_global.FlyEnabled = state end
    })

    Core.UI.AddSlider("FlySpeedValue", {
        Name = "飛行速度數值",
        Category = "Movement",
        Min = 10,
        Max = 1000,
        Default = env_global.FlySpeed,
        Callback = function(v) env_global.FlySpeed = v end
    })

    Core.RegisterFeature("AutoClicker", {
        Name = "自動點擊 (Auto Clicker)",
        Category = "Misc",
        Callback = function(state) env_global.AutoClicker = state end
    })

    Core.UI.AddSlider("AutoClickDelay", {
        Name = "點擊間隔 (秒)",
        Category = "Misc",
        Min = 0.01,
        Max = 1.0,
        Step = 0.01,
        Default = env_global.AutoClickDelay,
        Callback = function(v) env_global.AutoClickDelay = v end
    })

    Core.RegisterFeature("AntiAFK", {
        Name = "防掛機 (Anti-AFK)",
        Category = "Misc",
        Callback = function(state)
            env_global.AntiAFK = state
            if state then
                lp.Idled:Connect(function()
                    game:GetService("VirtualUser"):CaptureController()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                end)
            end
        end
    })

    Core.RegisterFeature("KillEffect", {
        Name = "擊殺特效 (Kill Effect)",
        Description = "擊殺敵人後在目標位置產生爆炸特效",
        Category = "Misc",
        Callback = function(state) env_global.KillEffect = state end
    })

    Core.RegisterFeature("KillSound", {
        Name = "擊殺音效 (Kill Sound)",
        Description = "擊殺敵人後播放經典擊殺音效",
        Category = "Misc",
        Callback = function(state) env_global.KillSound = state end
    })

    Core.RegisterFeature("CFrameSpeedEnabled", {
        Name = "瞬移加速 (CFrame Speed)",
        Category = "Movement",
        Callback = function(state) env_global.CFrameSpeedEnabled = state end
    })

    Core.UI.AddSlider("CFrameSpeedValue", {
        Name = "瞬移速度數值",
        Category = "Movement",
        Min = 1,
        Max = 100,
        Default = env_global.CFrameSpeed,
        Callback = function(v) env_global.CFrameSpeed = v end
    })
    
    Core.RegisterFeature("VelocityFly", {
        Name = "物理飛行 (Velocity Fly)",
        Description = "基於物理速度的飛行，較不易被某些 AC 偵測",
        Category = "Movement",
        Callback = function(state) env_global.VelocityFly = state end
    })

    Core.RegisterFeature("TeleportWalk", {
        Name = "瞬移行走 (TP Walk)",
        Description = "行走時向前瞬移，實現極速移動",
        Category = "Movement",
        Callback = function(state) env_global.TeleportWalk = state end
    })

    Core.UI.AddSlider("TeleportWalkDist", {
        Name = "瞬移距離",
        Category = "Movement",
        Min = 1,
        Max = 50,
        Default = env_global.TeleportWalkDist,
        Callback = function(v) env_global.TeleportWalkDist = v end
    })

    Core.RegisterFeature("NoSlow", {
        Name = "無減速 (No Slow)",
        Description = "防止開鏡、射擊或受傷時的移動減速",
        Category = "Movement",
        Callback = function(state) env_global.NoSlow = state end
    })

    Core.RegisterFeature("Desync", {
        Name = "回朔/脫節 (Desync)",
        Description = "使敵人在其視角中看到你的位置滯後或回朔",
        Category = "Misc",
        Callback = function(state) env_global.DesyncEnabled = state end
    })

    Core.RegisterFeature("Spider", {
        Name = "蜘蛛爬牆 (Spider)",
        Category = "Movement",
        Callback = function(state) env_global.Spider = state end
    })

    Core.RegisterFeature("Bhop", {
        Name = "自動連跳 (Bhop)",
        Category = "Movement",
        Callback = function(state) env_global.Bhop = state end
    })

    Core.UI.AddSlider("DesyncAmount", {
        Name = "反瞄準強度 (Desync)",
        Category = "Misc",
        Min = 1,
        Max = 100,
        Default = env_global.DesyncAmount,
        Callback = function(v) env_global.DesyncAmount = v end
    })

    Core.RegisterFeature("ServerHop", {
        Name = "更換伺服器 (Server Hop)",
        Category = "Misc",
        Callback = function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
            for _, s in ipairs(servers) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
                    break
                end
            end
        end
    })

    Core.RegisterFeature("Rejoin", {
        Name = "重新加入 (Rejoin)",
        Category = "Misc",
        Callback = function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end
    })

    -- [[ 效能優化：零件快取 ]]
    local lavaParts = {}
    local lastLavaScan = 0
    local function UpdateLavaParts()
        if not env_global.LavaNoclip then return end
        local now = tick()
        if now - lastLavaScan < 5 then return end -- 每 5 秒掃描一次
        lastLavaScan = now
        
        lavaParts = {}
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local name = v.Name:lower()
                if name:find("lava") or name:find("magma") then
                    table.insert(lavaParts, v)
                end
            end
        end
    end

    -- [[ 移動邏輯核心 ]]
    local charParts = {}
    local function UpdateCharParts(char)
        charParts = {}
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(charParts, part)
            end
        end
    end

    lp.CharacterAdded:Connect(UpdateCharParts)
    UpdateCharParts(lp.Character)

    -- [[ 性能優化：頻率控制與快取 ]]
    local lastHeartbeat = 0
    local MOVEMENT_INTERVAL = 0.005 -- 約 200Hz，保持極高流暢度但減少運算

    RunService.Heartbeat:Connect(function(dt)
        local now = tick()
        if now - lastHeartbeat < MOVEMENT_INTERVAL then return end
        lastHeartbeat = now
        
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if not (hum and hrp) then return end

        -- 1. 速度強化 (繞過模式：CFrame + Velocity 混合)
        if (env_global.WalkSpeedEnabled or (env_global.SprintEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift))) and hum.MoveDirection.Magnitude > 0 then
            local baseSpeed = env_global.WalkSpeedEnabled and env_global.WalkSpeed or 16
            local multiplier = (env_global.SprintEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) and env_global.SprintMultiplier or 1
            local targetSpeed = baseSpeed * multiplier
            
            local extraSpeed = (targetSpeed - 16)
            if extraSpeed > 0 then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (extraSpeed * dt))
            end

            -- 瞬移行走 (TP Walk) 邏輯
            if env_global.TeleportWalk then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * env_global.TeleportWalkDist)
            end
        end

        -- 2. CFrame 速度 (極速繞過模式)
        if env_global.CFrameSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * env_global.CFrameSpeed * dt * 10)
        end

        -- 3. 跳躍強化
        if env_global.JumpPowerEnabled then
            hum.JumpPower = env_global.JumpPower
        end

        -- 3.5 無減速 (No Slow)
        if env_global.NoSlow then
            local targetSpeed = env_global.WalkSpeedEnabled and env_global.WalkSpeed or 16
            if hum.WalkSpeed < targetSpeed then
                hum.WalkSpeed = targetSpeed
            end
        end

        -- 4. 飛行模式 (Fly)
        if env_global.FlyEnabled or env_global.VelocityFly then
            local moveDir = hum.MoveDirection
            local cameraCF = Camera.CFrame
            local flyVel = Vector3.new(0, 0, 0)
            
            if moveDir.Magnitude > 0 then
                flyVel = (cameraCF.LookVector * moveDir.Z + cameraCF.RightVector * moveDir.X) * env_global.FlySpeed
            end
            
            -- 上升/下降 (Space / LeftControl)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                flyVel = flyVel + Vector3.new(0, env_global.FlySpeed, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                flyVel = flyVel + Vector3.new(0, -env_global.FlySpeed, 0)
            end

            if env_global.VelocityFly then
                hrp.Velocity = flyVel
            else
                hrp.CFrame = hrp.CFrame + (flyVel * dt)
                hrp.Velocity = Vector3.new(0, 0, 0)
            end
        end

        -- 5. Noclip (穿牆)
        if env_global.Noclip then
            for i = 1, #charParts do
                local part = charParts[i]
                if part.Parent then
                    part.CanCollide = false
                end
            end
        end

        -- 5.1 穿過岩漿 (Lava Noclip)
        if env_global.LavaNoclip then
            UpdateLavaParts()
            for i = 1, #lavaParts do
                local v = lavaParts[i]
                if v and v.Parent then
                    v.CanCollide = false
                end
            end
        end

        -- 6. Spider (爬牆)
        if env_global.Spider then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            
            local result = workspace:Raycast(hrp.Position, hum.MoveDirection * 2, rayParams)
            if result and math.abs(result.Normal.Y) < 0.1 then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, env_global.WalkSpeed or 16, hrp.Velocity.Z)
            end
        end

        -- 7. Bhop (連跳)
        if env_global.Bhop and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        -- 8. 回朔/脫節 (Desync)
        if env_global.DesyncEnabled then
            -- 透過交替修改 Velocity 與位置偏移，使伺服器接收到的座標產生「回朔」感
            local desyncOffset = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
            local oldCF = hrp.CFrame
            
            -- 暫時將真實位置移開，隨即移回，干擾網路同步
            hrp.CFrame = oldCF * CFrame.new(desyncOffset)
            RunService.RenderStepped:Wait()
            hrp.CFrame = oldCF
        end
    end)

    -- [[ 無限跳躍 ]]
    UserInputService.JumpRequest:Connect(function()
        if env_global.InfJump and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            lp.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end)

    -- [[ 擊殺偵測與效果 ]]
    local function PlayKillEffect(pos)
        if env_global.KillEffect then
            local p = Instance.new("Explosion")
            p.Position = pos
            p.BlastRadius = 0
            p.BlastPressure = 0
            p.Parent = workspace
            
            local part = Instance.new("Part")
            part.Position = pos
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            part.Parent = workspace
            
            local attachment = Instance.new("Attachment", part)
            local particles = Instance.new("ParticleEmitter", attachment)
            particles.Rate = 100
            particles.Speed = NumberRange.new(5, 10)
            particles.Lifetime = NumberRange.new(0.5, 1)
            particles.Size = NumberSequence.new(0.5, 0)
            particles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0))
            
            task.wait(1)
            part:Destroy()
        end
    end

    local function PlayKillSound()
        if env_global.KillSound then
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://6831303433" -- 擊殺音效 ID
            sound.Volume = 2
            sound.Parent = game:GetService("SoundService")
            sound:Play()
            sound.Ended:Connect(function() sound:Destroy() end)
        end
    end

    local function OnPlayerDied(player)
        if player == lp then return end
        
        -- 檢查是否是由本地玩家擊殺 (簡單判定：如果距離近且死掉)
        -- 更準確的方式需要 Hook 傷害 Remote，這裡採用通用判定
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            if dist < 500 then -- 在一定範圍內死掉就觸發特效 (作為簡單判定)
                PlayKillEffect(hrp.Position)
                PlayKillSound()
            end
        end
    end

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= lp then
            p.CharacterAdded:Connect(function(char)
                local hum = char:WaitForChild("Humanoid", 5)
                if hum then
                    hum.Died:Connect(function() OnPlayerDied(p) end)
                end
            end)
        end
    end

    game:GetService("Players").PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                hum.Died:Connect(function() OnPlayerDied(p) end)
            end
        end)
    end)

    -- [[ 自動點擊 ]]
    task.spawn(function()
        while task.wait() do
            if env_global.AutoClicker then
                local VirtualInputManager = game:GetService("VirtualInputManager")
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                task.wait(env_global.AutoClickDelay)
            end
        end
    end)

    print("[Halol] 強化移動模組已啟動")
end

return Misc

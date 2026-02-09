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
    
    env_global.Noclip = env_global.Noclip or false
    env_global.NoSlow = env_global.NoSlow or false
    env_global.DesyncEnabled = env_global.DesyncEnabled or false
    env_global.DesyncAmount = env_global.DesyncAmount or 5
    env_global.Spider = env_global.Spider or false
    env_global.Bhop = env_global.Bhop or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("WalkSpeedEnabled", {
        Name = "速度加強 (Speed)",
        Category = "Misc",
        Callback = function(state) env_global.WalkSpeedEnabled = state end
    })

    Core.UI.AddSlider("WalkSpeedValue", {
        Name = "行走速度數值",
        Category = "Misc",
        Min = 16,
        Max = 300,
        Default = env_global.WalkSpeed,
        Callback = function(v) env_global.WalkSpeed = v end
    })

    Core.RegisterFeature("CFrameSpeedEnabled", {
        Name = "瞬移加速 (CFrame Speed)",
        Category = "Misc",
        Callback = function(state) env_global.CFrameSpeedEnabled = state end
    })

    Core.UI.AddSlider("CFrameSpeedValue", {
        Name = "瞬移速度數值",
        Category = "Misc",
        Min = 1,
        Max = 50,
        Default = env_global.CFrameSpeed,
        Callback = function(v) env_global.CFrameSpeed = v end
    })
    
    Core.RegisterFeature("JumpPowerEnabled", {
        Name = "跳躍加強 (Jump Power)",
        Category = "Misc",
        Callback = function(state) env_global.JumpPowerEnabled = state end
    })

    Core.UI.AddSlider("JumpPowerValue", {
        Name = "跳躍高度數值",
        Category = "Misc",
        Min = 50,
        Max = 500,
        Default = env_global.JumpPower,
        Callback = function(v) env_global.JumpPower = v end
    })

    Core.RegisterFeature("InfJump", {
        Name = "無限跳躍 (Inf Jump)",
        Category = "Misc",
        Callback = function(state) env_global.InfJump = state end
    })

    Core.RegisterFeature("FlyEnabled", {
        Name = "飛行模式 (Fly)",
        Category = "Misc",
        Callback = function(state) env_global.FlyEnabled = state end
    })

    Core.UI.AddSlider("FlySpeedValue", {
        Name = "飛行速度數值",
        Category = "Misc",
        Min = 10,
        Max = 500,
        Default = env_global.FlySpeed,
        Callback = function(v) env_global.FlySpeed = v end
    })

    Core.RegisterFeature("FullBright", {
        Name = "全亮模式 (Full Bright)",
        Category = "Visuals",
        Callback = function(state)
            env_global.FullBright = state
            if state then
                game:GetService("Lighting").Brightness = 2
                game:GetService("Lighting").ClockTime = 14
                game:GetService("Lighting").FogEnd = 100000
                game:GetService("Lighting").GlobalShadows = false
            else
                -- 恢復預設 (概略值)
                game:GetService("Lighting").GlobalShadows = true
            end
        end
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

    Core.RegisterFeature("Noclip", {
        Name = "穿牆 (Noclip)",
        Category = "Misc",
        Callback = function(state) env_global.Noclip = state end
    })
    
    Core.RegisterFeature("NoSlow", {
        Name = "無減速 (No Slow)",
        Description = "防止開鏡、射擊或受傷時的移動減速",
        Category = "Misc",
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
        Category = "Misc",
        Callback = function(state) env_global.Spider = state end
    })

    Core.RegisterFeature("Bhop", {
        Name = "自動連跳 (Bhop)",
        Category = "Misc",
        Callback = function(state) env_global.Bhop = state end
    })

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
        if env_global.WalkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
            -- 保持屬性值為正常 (16)，但實際移動加快
            local extraSpeed = (env_global.WalkSpeed - 16)
            if extraSpeed > 0 then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (extraSpeed * dt))
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
        if env_global.FlyEnabled then
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

            hrp.Velocity = flyVel
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

    print("[Halol] 強化移動模組已啟動")
end

return Misc

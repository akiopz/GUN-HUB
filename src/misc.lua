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
    env_global.Spider = env_global.Spider or false
    env_global.Bhop = env_global.Bhop or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("WalkSpeedEnabled", {
        Name = "速度加強 (Speed)",
        Category = "Misc",
        Callback = function(state) env_global.WalkSpeedEnabled = state end
    })

    Core.RegisterFeature("CFrameSpeedEnabled", {
        Name = "瞬移加速 (CFrame Speed)",
        Category = "Misc",
        Callback = function(state) env_global.CFrameSpeedEnabled = state end
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

    Core.RegisterFeature("Noclip", {
        Name = "穿牆 (Noclip)",
        Category = "Misc",
        Callback = function(state) env_global.Noclip = state end
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

    RunService.Heartbeat:Connect(function(dt)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if not (hum and hrp) then return end

        -- 1. 速度強化 (屬性模式)
        if env_global.WalkSpeedEnabled then
            hum.WalkSpeed = env_global.WalkSpeed
        end

        -- 2. CFrame 速度 (繞過模式)
        if env_global.CFrameSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * env_global.CFrameSpeed * dt * 10)
        end

        -- 3. 跳躍強化
        if env_global.JumpPowerEnabled then
            hum.JumpPower = env_global.JumpPower
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

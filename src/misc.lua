    -- [[ 強化移動邏輯 ]]
    local function SetupMovement()
        Core.RunService.Heartbeat:Connect(function()
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and hrp then
                -- 速度強化 (防跌落)
                if env_global.WalkSpeedEnabled then
                    hum.WalkSpeed = env_global.WalkSpeed
                    if hrp.Velocity.Y < -50 then -- 防止跌落過快觸發檢測
                        hrp.Velocity = Vector3.new(hrp.Velocity.X, -50, hrp.Velocity.Z)
                    end
                end
                
                -- 跳躍強化
                if env_global.JumpPowerEnabled then
                    hum.JumpPower = env_global.JumpPower
                end
                
                -- Noclip 強化
                if env_global.Noclip then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
    
    SetupMovement()

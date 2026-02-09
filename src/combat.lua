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

    print("[Halol] 戰鬥模組已啟動")
end

return Combat

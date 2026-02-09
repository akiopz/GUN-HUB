---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Visuals Module
-- 放置於: src/visuals.lua

local Visuals = {}

function Visuals.Init(Core)
    ---@class GlobalEnv
    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    local RunService = Core.RunService
    local UserInputService = Core.UserInputService
    local Camera = Core.Camera
    local Drawing = Core.Drawing

    -- [[ ESP 配置 ]]
    env_global.ESPEnabled = env_global.ESPEnabled or false
    env_global.ESPBoxes = env_global.ESPBoxes or false
    env_global.ESPNames = env_global.ESPNames or false
    env_global.ShowFOV = env_global.ShowFOV or false
    env_global.AimbotFOV = env_global.AimbotFOV or 150
    env_global.ESPColor = env_global.ESPColor or Color3.fromRGB(255, 255, 255)
    env_global.ESPHealthBar = env_global.ESPHealthBar or false
    env_global.ESPChams = env_global.ESPChams or false
    env_global.ESPTeamCheck = env_global.ESPTeamCheck or true
    env_global.ESPShowTeammates = env_global.ESPShowTeammates or false
    env_global.ESPDistance = env_global.ESPDistance or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("ESPTeamCheck", {
        Name = "隊伍檢查 (Team Check)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPTeamCheck = state
        end
    })

    Core.RegisterFeature("ESPShowTeammates", {
        Name = "顯示隊友 (Show Team)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPShowTeammates = state
        end
    })
    Core.RegisterFeature("ESPMain", {
        Name = "玩家透視 (ESP)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPEnabled = state
        end
    })

    Core.RegisterFeature("ESPBoxes", {
        Name = "顯示方框 (Boxes)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPBoxes = state
        end
    })

    Core.RegisterFeature("ESPNames", {
        Name = "顯示名稱 (Names)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPNames = state
        end
    })

    Core.RegisterFeature("ESPHealthBar", {
        Name = "血量條 (Health Bar)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPHealthBar = state
        end
    })

    Core.RegisterFeature("ESPChams", {
        Name = "透視牆壁 (Chams)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPChams = state
        end
    })

    Core.RegisterFeature("ESPDistance", {
        Name = "顯示距離 (Distance)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPDistance = state
        end
    })

    Core.RegisterFeature("ShowFOV", {
        Name = "顯示範圍 (Show FOV)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ShowFOV = state
        end
    })

    -- [[ FOV Circle ]]
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 100
    FOVCircle.Radius = env_global.AimbotFOV
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)

    RunService.RenderStepped:Connect(function()
        if env_global.ShowFOV then
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = mousePos
            FOVCircle.Radius = env_global.AimbotFOV
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end)

    -- [[ ESP 核心系統 ]]
    local ESP_Objects = {}
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer

    local function CreateESP(player)
        if ESP_Objects[player] then return end
        
        local objects = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Tracer = Drawing.new("Line"),
            HealthBar = Drawing.new("Line"),
            HealthBarBG = Drawing.new("Line"),
            Chams = Instance.new("Highlight")
        }
        
        objects.Box.Thickness = 1
        objects.Box.Filled = false
        objects.Box.Color = env_global.ESPColor
        
        objects.Name.Size = 14
        objects.Name.Center = true
        objects.Name.Outline = true
        objects.Name.Color = Color3.new(1, 1, 1)
        
        objects.Tracer.Thickness = 1
        objects.Tracer.Color = env_global.ESPColor

        objects.HealthBar.Thickness = 2
        objects.HealthBarBG.Thickness = 2
        objects.HealthBarBG.Color = Color3.new(0, 0, 0)
        
        objects.Chams.Name = "HalolChams"
        objects.Chams.FillColor = env_global.ESPColor
        objects.Chams.FillTransparency = 0.5
        objects.Chams.OutlineColor = Color3.new(1, 1, 1)
        objects.Chams.Enabled = false
        
        ESP_Objects[player] = objects
    end

    local function RemoveESP(player)
        if ESP_Objects[player] then
            for _, obj in pairs(ESP_Objects[player]) do
                if typeof(obj) == "Instance" then
                    obj:Destroy()
                else
                    obj:Remove()
                end
            end
            ESP_Objects[player] = nil
        end
    end

    local function UpdateESP()
        for player, objects in pairs(ESP_Objects) do
            local char = player.Character
            local isTeammate = (player.Team == lp.Team and player.Team ~= nil)
            local visible = false
            
            local shouldShow = false
            if env_global.ESPEnabled and char and player ~= lp then
                shouldShow = true
                if env_global.ESPTeamCheck and isTeammate and not env_global.ESPShowTeammates then
                    shouldShow = false
                end
            end

            if shouldShow then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                
                if hrp and hum and hum.Health > 0 then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    
                    if onScreen then
                        -- 計算 Box 大小
                        local head = char:FindFirstChild("Head")
                        local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or {Y = pos.Y - 2}
                        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local sizeY = math.abs(headPos.Y - legPos.Y)
                        local sizeX = sizeY * 0.6
                        
                        -- 更新 Box
                        objects.Box.Size = Vector2.new(sizeX, sizeY)
                        objects.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                        objects.Box.Color = isTeammate and Color3.new(0, 1, 0) or env_global.ESPColor
                        objects.Box.Visible = env_global.ESPBoxes
                        
                        -- 更新 Name & Distance
                        local nameText = player.Name
                        if env_global.ESPDistance then
                            local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                            nameText = nameText .. " [" .. dist .. "m]"
                        end
                        objects.Name.Text = nameText
                        objects.Name.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 15)
                        objects.Name.Visible = env_global.ESPNames
                        
                        -- 更新 Health Bar
                        if env_global.ESPHealthBar then
                            local healthPercent = hum.Health / hum.MaxHealth
                            local barHeight = sizeY
                            local barPos = Vector2.new(pos.X - sizeX/2 - 5, pos.Y + sizeY/2)
                            
                            objects.HealthBarBG.From = barPos
                            objects.HealthBarBG.To = barPos - Vector2.new(0, barHeight)
                            objects.HealthBarBG.Visible = true
                            
                            objects.HealthBar.From = barPos
                            objects.HealthBar.To = barPos - Vector2.new(0, barHeight * healthPercent)
                            objects.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                            objects.HealthBar.Visible = true
                        else
                            objects.HealthBar.Visible = false
                            objects.HealthBarBG.Visible = false
                        end
                        
                        -- 更新 Chams
                        if env_global.ESPChams then
                            objects.Chams.Parent = char
                            objects.Chams.Enabled = true
                        else
                            objects.Chams.Enabled = false
                        end
                        
                        visible = true
                    end
                end
            end
            
            if not visible then
                objects.Box.Visible = false
                objects.Name.Visible = false
                objects.HealthBar.Visible = false
                objects.HealthBarBG.Visible = false
                objects.Chams.Enabled = false
            end
        end
    end

    -- 初始化與清理
    for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    Players.PlayerAdded:Connect(CreateESP)
    Players.PlayerRemoving:Connect(RemoveESP)

    RunService.RenderStepped:Connect(function()
        -- FOV 圓圈更新
        if env_global.ShowFOV then
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = mousePos
            FOVCircle.Radius = env_global.AimbotFOV
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
        
        -- ESP 更新
        UpdateESP()
    end)

    print("[Halol] 視覺模組已啟動 (高效能 ESP 已載入)")
end

return Visuals

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

    -- [[ 註冊功能 ]]
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
            Tracer = Drawing.new("Line")
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
        
        ESP_Objects[player] = objects
    end

    local function RemoveESP(player)
        if ESP_Objects[player] then
            for _, obj in pairs(ESP_Objects[player]) do
                obj:Remove()
            end
            ESP_Objects[player] = nil
        end
    end

    local function UpdateESP()
        for player, objects in pairs(ESP_Objects) do
            local char = player.Character
            local isTeam = (player.Team == lp.Team and player.Team ~= nil)
            local visible = false
            
            if env_global.ESPEnabled and char and player ~= lp and not isTeam then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                
                if hrp and hum and hum.Health > 0 then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    
                    if onScreen then
                        -- 計算 Box 大小
                        local head = char:FindFirstChild("Head")
                        local headPos = head and Camera:WorldToViewportPoint(head.Position) or {Y = pos.Y - 2}
                        local sizeY = math.abs(pos.Y - headPos.Y) * 3
                        local sizeX = sizeY * 0.6
                        
                        if env_global.ESPBoxes then
                            objects.Box.Size = Vector2.new(sizeX, sizeY)
                            objects.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                            objects.Box.Visible = true
                        else
                            objects.Box.Visible = false
                        end
                        
                        if env_global.ESPNames then
                            objects.Name.Text = player.Name
                            objects.Name.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 15)
                            objects.Name.Visible = true
                        else
                            objects.Name.Visible = false
                        end
                        
                        objects.Tracer.Visible = false -- 預設關閉
                        visible = true
                    end
                end
            end
            
            -- 如果不可見或不符合條件，隱藏所有物件
            if not visible then
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
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

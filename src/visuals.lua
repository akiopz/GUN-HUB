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
    local math_clamp = math.clamp

    -- [[ FOV 圓圈 ]]
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 64
    FOVCircle.Radius = env_global.AimbotFOV
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.5
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Visible = false

    -- [[ ESP 配置 ]]
    env_global.ESPEnabled = env_global.ESPEnabled or false
    env_global.ESPBoxes = env_global.ESPBoxes or false
    env_global.ESP3DBoxes = env_global.ESP3DBoxes or false
    env_global.ESPSkeleton = env_global.ESPSkeleton or false
    env_global.ESPNames = env_global.ESPNames or false
    env_global.ShowFOV = env_global.ShowFOV or false
    env_global.AimbotFOV = env_global.AimbotFOV or 150
    env_global.ESPColor = env_global.ESPColor or Color3.fromRGB(255, 255, 255)
    env_global.ESPHealthBar = env_global.ESPHealthBar or false
    env_global.ESPHealthText = env_global.ESPHealthText or false
    env_global.ESPTracers = env_global.ESPTracers or false
    env_global.ESPTracerOrigin = env_global.ESPTracerOrigin or "Bottom" -- "Bottom", "Center", "Top", "Mouse"
    env_global.ESPRadar = env_global.ESPRadar or false
    env_global.ESPRadarSize = env_global.ESPRadarSize or 150
    env_global.ESPRadarRange = env_global.ESPRadarRange or 500
    env_global.ESPChams = env_global.ESPChams or false
    env_global.ESPTeamCheck = env_global.ESPTeamCheck or true
    env_global.ESPShowTeammates = env_global.ESPShowTeammates or false
    env_global.ESPDistance = env_global.ESPDistance or false
    env_global.ESPRainbow = env_global.ESPRainbow or false
    env_global.ESPRainbowSpeed = env_global.ESPRainbowSpeed or 1
    env_global.RainbowFOV = env_global.RainbowFOV or false
    env_global.ESPBoxFill = env_global.ESPBoxFill or false
    env_global.ESPBoxFillTransparency = env_global.ESPBoxFillTransparency or 0.5
    env_global.ESPMaxDistance = env_global.ESPMaxDistance or 2500
    env_global.ESPFont = env_global.ESPFont or 2 -- 0: UI, 1: System, 2: Plex, 3: Monospace
    env_global.ESPTextSize = env_global.ESPTextSize or 13
    env_global.ESPSkeletonThickness = env_global.ESPSkeletonThickness or 1
    env_global.ESPBoxThickness = env_global.ESPBoxThickness or 1

    -- [[ 新功能配置 ]]
    env_global.WatermarkEnabled = env_global.WatermarkEnabled or true
    env_global.CrosshairEnabled = env_global.CrosshairEnabled or false
    env_global.CrosshairSize = env_global.CrosshairSize or 10
    env_global.CrosshairThickness = env_global.CrosshairThickness or 1
    env_global.CrosshairColor = env_global.CrosshairColor or Color3.fromRGB(0, 255, 0)
    env_global.HitMarkerEnabled = env_global.HitMarkerEnabled or false
    env_global.HitMarkerColor = env_global.HitMarkerColor or Color3.fromRGB(255, 0, 0)

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("Watermark", {
        Name = "浮水印 (Watermark)",
        Category = "Visuals",
        Default = true,
        Callback = function(state) env_global.WatermarkEnabled = state end
    })

    Core.RegisterFeature("Crosshair", {
        Name = "自定義準星 (Crosshair)",
        Category = "Visuals",
        Callback = function(state) env_global.CrosshairEnabled = state end
    })

    Core.UI.AddSlider("CrosshairSize", {
        Name = "準星大小",
        Category = "Visuals",
        Min = 5,
        Max = 50,
        Default = 10,
        Callback = function(v) env_global.CrosshairSize = v end
    })

    Core.RegisterFeature("HitMarker", {
        Name = "命中標記 (Hit Marker)",
        Category = "Visuals",
        Callback = function(state) env_global.HitMarkerEnabled = state end
    })
    Core.RegisterFeature("ESPRainbow", {
        Name = "彩虹透視 (Rainbow ESP)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPRainbow = state
        end
    })

    Core.UI.AddSlider("ESPRainbowSpeed", {
        Name = "彩虹速度 (RGB Speed)",
        Category = "Visuals",
        Min = 1,
        Max = 10,
        Default = 1,
        Callback = function(v)
            env_global.ESPRainbowSpeed = v
        end
    })

    Core.RegisterFeature("RainbowFOV", {
        Name = "彩虹 FOV (Rainbow FOV)",
        Category = "Visuals",
        Callback = function(state)
            env_global.RainbowFOV = state
        end
    })

    Core.RegisterFeature("ESPBoxFill", {
        Name = "框內填充 (Box Fill)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPBoxFill = state
        end
    })

    Core.UI.AddSlider("ESPBoxFillTransparency", {
        Name = "填充透明度",
        Category = "Visuals",
        Min = 0,
        Max = 100,
        Default = 50,
        Callback = function(v)
            env_global.ESPBoxFillTransparency = v / 100
        end
    })

    Core.UI.AddSlider("ESPMaxDistance", {
        Name = "ESP 最大距離",
        Category = "Visuals",
        Min = 100,
        Max = 5000,
        Default = 2500,
        Callback = function(v)
            env_global.ESPMaxDistance = v
        end
    })

    Core.UI.AddSlider("ESPTextSize", {
        Name = "ESP 字體大小",
        Category = "Visuals",
        Min = 10,
        Max = 30,
        Default = 13,
        Callback = function(v)
            env_global.ESPTextSize = v
        end
    })

    Core.UI.AddSlider("ESPBoxThickness", {
        Name = "方框粗細",
        Category = "Visuals",
        Min = 1,
        Max = 5,
        Default = 1,
        Callback = function(v)
            env_global.ESPBoxThickness = v
        end
    })

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
        Name = "2D 框 (2D Box)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPBoxes = state
        end
    })

    Core.RegisterFeature("ESP3DBoxes", {
        Name = "3D 框 (3D Box)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESP3DBoxes = state
        end
    })

    Core.RegisterFeature("ESPSkeleton", {
        Name = "骨骼透視 (Skeleton)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPSkeleton = state
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

    Core.RegisterFeature("ESPHealthText", {
        Name = "血量數值 (Health Text)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPHealthText = state
        end
    })

    Core.RegisterFeature("ESPTracers", {
        Name = "追蹤線 (Tracers)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPTracers = state
        end
    })

    Core.UI.AddDropdown("ESPTracerOrigin", {
        Name = "追蹤線起點",
        Category = "Visuals",
        Options = {"Bottom", "Center", "Top", "Mouse"},
        Default = "Bottom",
        Callback = function(v)
            env_global.ESPTracerOrigin = v
        end
    })

    Core.RegisterFeature("ESPRadar", {
        Name = "小地圖雷達 (Radar)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ESPRadar = state
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

    Core.UI.AddSlider("AimbotFOV", {
        Name = "自瞄範圍 (FOV)",
        Category = "Visuals",
        Min = 10,
        Max = 1000,
        Default = env_global.AimbotFOV,
        Callback = function(v)
            env_global.AimbotFOV = v
        end
    })

    Core.UI.AddColorPicker("ESPColor", {
        Name = "ESP 顏色",
        Category = "Visuals",
        Default = env_global.ESPColor,
        Callback = function(color)
            env_global.ESPColor = color
        end
    })

    Core.UI.AddSlider("ESPRadarSize", {
        Name = "雷達大小",
        Category = "Visuals",
        Min = 100,
        Max = 300,
        Default = 150,
        Callback = function(v)
            env_global.ESPRadarSize = v
        end
    })

    Core.UI.AddSlider("ESPRadarRange", {
        Name = "雷達範圍",
        Category = "Visuals",
        Min = 100,
        Max = 2000,
        Default = 500,
        Callback = function(v)
            env_global.ESPRadarRange = v
        end
    })

    Core.RegisterFeature("ShowFOV", {
        Name = "顯示範圍 (Show FOV)",
        Category = "Visuals",
        Callback = function(state)
            env_global.ShowFOV = state
        end
    })

    Core.UI.AddSlider("ESPSkeletonThickness", {
        Name = "骨骼粗細",
        Category = "Visuals",
        Min = 1,
        Max = 5,
        Default = env_global.ESPSkeletonThickness,
        Callback = function(v) env_global.ESPSkeletonThickness = v end
    })

    Core.UI.AddSlider("CrosshairThickness", {
        Name = "準星粗細",
        Category = "Visuals",
        Min = 1,
        Max = 5,
        Default = env_global.CrosshairThickness,
        Callback = function(v) env_global.CrosshairThickness = v end
    })

    Core.UI.AddColorPicker("CrosshairColor", {
        Name = "準星顏色",
        Category = "Visuals",
        Default = env_global.CrosshairColor,
        Callback = function(color) env_global.CrosshairColor = color end
    })

    Core.UI.AddColorPicker("HitMarkerColor", {
        Name = "擊中提示顏色",
        Category = "Visuals",
        Default = env_global.HitMarkerColor,
        Callback = function(color) env_global.HitMarkerColor = color end
    })

    -- [[ Watermark UI ]]
    local Watermark = Drawing.new("Text")
    Watermark.Size = 18
    Watermark.Center = false
    Watermark.Outline = true
    Watermark.OutlineColor = Color3.new(0, 0, 0)
    Watermark.Color = Color3.fromRGB(0, 255, 255)
    Watermark.Position = Vector2.new(15, 15)
    Watermark.Visible = false

    -- [[ Crosshair UI ]]
    local CrosshairV = Drawing.new("Line")
    local CrosshairH = Drawing.new("Line")
    CrosshairV.Thickness = 2
    CrosshairH.Thickness = 2
    CrosshairV.Visible = false
    CrosshairH.Visible = false

    local CrosshairV2 = Drawing.new("Line")
    local CrosshairH2 = Drawing.new("Line")
    CrosshairV2.Thickness = 1
    CrosshairH2.Thickness = 1
    CrosshairV2.Color = Color3.new(0, 0, 0)
    CrosshairH2.Color = Color3.new(0, 0, 0)
    CrosshairV2.Visible = false
    CrosshairH2.Visible = false

    -- [[ HitMarker UI ]]
    local HitMarkers = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Visible = false
        table.insert(HitMarkers, line)
    end

    local lastHitTime = 0
    local function ShowHitMarker()
        if not env_global.HitMarkerEnabled then return end
        lastHitTime = tick()
    end

    -- 監聽命中事件 (這通常需要從 combat.lua 或遊戲 Remote 觸發)
    -- 這裡我們先定義函數，後續在核心邏輯中調用
    Visuals.ShowHitMarker = ShowHitMarker

    RunService.RenderStepped:Connect(function()
        local now = tick()
        local viewportSize = Camera.ViewportSize
        local center = viewportSize / 2

        -- 更新 Watermark
        if env_global.WatermarkEnabled then
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = "0"
            pcall(function()
                ping = tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()))
            end)
            Watermark.Text = string.format("Halol Shooting | FPS: %d | Ping: %s ms | %s", fps, ping, os.date("%X"))
            Watermark.Color = env_global.ESPRainbow and Color3.fromHSV((now * 0.1) % 1, 1, 1) or Color3.fromRGB(0, 255, 255)
            Watermark.Visible = true
        else
            Watermark.Visible = false
        end

        -- 更新 Crosshair
        if env_global.CrosshairEnabled then
            local size = env_global.CrosshairSize
            local color = env_global.ESPRainbow and Color3.fromHSV((now * 0.1) % 1, 1, 1) or env_global.CrosshairColor
            
            CrosshairV.From = center - Vector2.new(0, size)
            CrosshairV.To = center + Vector2.new(0, size)
            CrosshairH.From = center - Vector2.new(size, 0)
            CrosshairH.To = center + Vector2.new(size, 0)
            CrosshairV.Color = color
            CrosshairH.Color = color
            
            -- 外框
            CrosshairV2.From = CrosshairV.From
            CrosshairV2.To = CrosshairV.To
            CrosshairH2.From = CrosshairH.From
            CrosshairH2.To = CrosshairH.To
            
            CrosshairV.Visible = true
            CrosshairH.Visible = true
            -- CrosshairV2.Visible = true
            -- CrosshairH2.Visible = true
        else
            CrosshairV.Visible = false
            CrosshairH.Visible = false
            CrosshairV2.Visible = false
            CrosshairH2.Visible = false
        end

        -- 更新 HitMarker
        local hitAlpha = math_clamp(1 - (now - lastHitTime) / 0.5, 0, 1)
        if hitAlpha > 0 then
            local size = 10
            local gap = 5
            local color = env_global.HitMarkerColor:lerp(Color3.new(1, 1, 1), 0.5)
            
            for i, line in ipairs(HitMarkers) do
                line.Transparency = hitAlpha
                line.Color = color
                if i == 1 then -- Top Left
                    line.From = center - Vector2.new(gap, gap)
                    line.To = center - Vector2.new(gap + size, gap + size)
                elseif i == 2 then -- Top Right
                    line.From = center + Vector2.new(gap, -gap)
                    line.To = center + Vector2.new(gap + size, -(gap + size))
                elseif i == 3 then -- Bottom Left
                    line.From = center + Vector2.new(-gap, gap)
                    line.To = center + Vector2.new(-(gap + size), gap + size)
                elseif i == 4 then -- Bottom Right
                    line.From = center + Vector2.new(gap, gap)
                    line.To = center + Vector2.new(gap + size, gap + size)
                end
                line.Visible = true
            end
        else
            for _, line in ipairs(HitMarkers) do line.Visible = false end
        end

        if env_global.ShowFOV then
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = mousePos
            FOVCircle.Radius = env_global.AimbotFOV
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end)

    -- [[ 啟動通知 ]]
    task.spawn(function()
        Core.Notify("Halol Shooting", "視覺模組已加載成功！", 3)
    end)

    -- [[ Radar UI ]]
    local RadarFrame = Drawing.new("Square")
    RadarFrame.Size = Vector2.new(env_global.ESPRadarSize, env_global.ESPRadarSize)
    RadarFrame.Position = Vector2.new(20, 200) -- 默認位置
    RadarFrame.Thickness = 1
    RadarFrame.Filled = true
    RadarFrame.Transparency = 0.5
    RadarFrame.Color = Color3.new(0, 0, 0)
    RadarFrame.Visible = false

    local RadarCenter = Drawing.new("Circle")
    RadarCenter.Radius = 2
    RadarCenter.Filled = true
    RadarCenter.Color = Color3.new(1, 1, 1)
    RadarCenter.Visible = false

    local RadarCross1 = Drawing.new("Line")
    local RadarCross2 = Drawing.new("Line")
    RadarCross1.Thickness = 1
    RadarCross2.Thickness = 1
    RadarCross1.Color = Color3.fromRGB(50, 50, 50)
    RadarCross2.Color = Color3.fromRGB(50, 50, 50)
    RadarCross1.Visible = false
    RadarCross2.Visible = false

    -- [[ ESP 核心系統 ]]
    local ESP_Objects = {}
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer

    local function CreateESP(entity)
        if ESP_Objects[entity] then return end
        
        local objects = {
            Box = Drawing.new("Square"),
            BoxFill = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Tracer = Drawing.new("Line"),
            HealthBar = Drawing.new("Line"),
            HealthBarBG = Drawing.new("Line"),
            HealthText = Drawing.new("Text"),
            RadarDot = Drawing.new("Circle"),
            Chams = Instance.new("Highlight"),
            Skeleton = {},
            Box3D = {}
        }

        -- 初始化 3D Box (12 條線)
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Transparency = 1
            line.Visible = false
            table.insert(objects.Box3D, line)
        end

        -- 初始化 Skeleton (常用骨骼連接)
        local connections = {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }
        for _, _ in ipairs(connections) do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Transparency = 1
            line.Visible = false
            table.insert(objects.Skeleton, line)
        end
        
        objects.Box.Thickness = 1
        objects.Box.Filled = false
        objects.Box.Color = env_global.ESPColor

        objects.BoxFill.Thickness = 0
        objects.BoxFill.Filled = true
        objects.BoxFill.Transparency = env_global.ESPBoxFillTransparency
        
        objects.Name.Size = env_global.ESPTextSize or 14
        objects.Name.Center = true
        objects.Name.Outline = true
        objects.Name.Color = Color3.new(1, 1, 1)
        
        objects.Tracer.Thickness = 1
        objects.Tracer.Color = env_global.ESPColor

        objects.HealthBar.Thickness = 2
        objects.HealthBarBG.Thickness = 2
        objects.HealthBarBG.Color = Color3.new(0, 0, 0)

        objects.HealthText.Size = 13
        objects.HealthText.Center = true
        objects.HealthText.Outline = true
        objects.HealthText.Color = Color3.new(1, 1, 1)
        objects.HealthText.Visible = false

        objects.RadarDot.Radius = 3
        objects.RadarDot.Filled = true
        objects.RadarDot.Visible = false
        
        objects.Chams.Name = "HalolChams"
        objects.Chams.FillColor = env_global.ESPColor
        objects.Chams.FillTransparency = 0.5
        objects.Chams.OutlineColor = Color3.new(1, 1, 1)
        objects.Chams.Enabled = false
        
        ESP_Objects[entity] = objects
    end

    local function RemoveESP(entity)
        if ESP_Objects[entity] then
            for _, obj in pairs(ESP_Objects[entity]) do
                if typeof(obj) == "Instance" then
                    obj:Destroy()
                else
                    obj:Remove()
                end
            end
            ESP_Objects[entity] = nil
        end
    end

    -- [[ 性能優化：頻率控制 ]]
    local lastUpdate = 0
    local UPDATE_INTERVAL = 0.01 -- 限制每秒最多更新 100 次，減少渲染負擔

    local function UpdateESP()
        local now = tick()
        if now - lastUpdate < UPDATE_INTERVAL then return end
        lastUpdate = now
        
        -- 計算彩虹顏色 (速度受 env_global.ESPRainbowSpeed 控制)
        local rainbowColor = Color3.fromHSV((tick() * (env_global.ESPRainbowSpeed or 1) * 0.1) % 1, 1, 1)
        local viewportSize = Camera.ViewportSize

        -- 更新 FOV 顏色
        if env_global.RainbowFOV then
            FOVCircle.Color = rainbowColor
        else
            FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        end

        -- 更新 Radar 背景
        if env_global.ESPRadar then
            RadarFrame.Visible = true
            RadarCenter.Visible = true
            RadarCross1.Visible = true
            RadarCross2.Visible = true
            
            RadarFrame.Size = Vector2.new(env_global.ESPRadarSize, env_global.ESPRadarSize)
            local rPos = RadarFrame.Position
            local rSize = RadarFrame.Size
            local rCenter = rPos + rSize / 2
            
            RadarCenter.Position = rCenter
            RadarCross1.From = Vector2.new(rPos.X, rCenter.Y)
            RadarCross1.To = Vector2.new(rPos.X + rSize.X, rCenter.Y)
            RadarCross2.From = Vector2.new(rCenter.X, rPos.Y)
            RadarCross2.To = Vector2.new(rCenter.X, rPos.Y + rSize.Y)
        else
            RadarFrame.Visible = false
            RadarCenter.Visible = false
            RadarCross1.Visible = false
            RadarCross2.Visible = false
        end

        for entity, objects in pairs(ESP_Objects) do
            local visible = false
            if env_global.ESPEnabled and entity and entity.Parent and entity ~= lp then
                local char = entity.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hum and hrp and hum.Health > 0 then
                    -- 團隊檢查
                    local isTeammate = (lp.Team ~= nil and entity.Team == lp.Team)
                    if env_global.ESPTeamCheck and isTeammate and not env_global.ESPShowTeammates then
                        -- 不顯示隊友
                    else
                        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                        
                        if onScreen and distance <= env_global.ESPMaxDistance then
                            local currentColor = isTeammate and Color3.new(0, 1, 0) or (env_global.ESPRainbow and rainbowColor or env_global.ESPColor)
                            
                            -- 計算方框大小
                            local head = char:FindFirstChild("Head")
                            if head then
                                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                                
                                local sizeY = math.abs(headPos.Y - legPos.Y)
                                local sizeX = sizeY * 0.6
                                local pos = Vector2.new(screenPos.X, screenPos.Y)
                                
                                -- 更新 2D 方框
                                if env_global.ESPBoxes then
                                    objects.Box.Size = Vector2.new(sizeX, sizeY)
                                    objects.Box.Position = pos - Vector2.new(sizeX/2, sizeY/2)
                                    objects.Box.Color = currentColor
                                    objects.Box.Thickness = env_global.ESPBoxThickness or 1
                                    objects.Box.Visible = true
                                    
                                    if env_global.ESPBoxFill then
                                        objects.BoxFill.Size = objects.Box.Size
                                        objects.BoxFill.Position = objects.Box.Position
                                        objects.BoxFill.Color = currentColor
                                        objects.BoxFill.Transparency = env_global.ESPBoxFillTransparency
                                        objects.BoxFill.Visible = true
                                    else
                                        objects.BoxFill.Visible = false
                                    end
                                else
                                    objects.Box.Visible = false
                                    objects.BoxFill.Visible = false
                                end
                                
                                -- 更新 3D 方框
                                if env_global.ESP3DBoxes then
                                    local cf = hrp.CFrame
                                    local size = Vector3.new(2, 3, 1.5)
                                    local vertices = {
                                        cf * CFrame.new(-size.X, size.Y, -size.Z),
                                        cf * CFrame.new(size.X, size.Y, -size.Z),
                                        cf * CFrame.new(size.X, size.Y, size.Z),
                                        cf * CFrame.new(-size.X, size.Y, size.Z),
                                        cf * CFrame.new(-size.X, -size.Y, -size.Z),
                                        cf * CFrame.new(size.X, -size.Y, -size.Z),
                                        cf * CFrame.new(size.X, -size.Y, size.Z),
                                        cf * CFrame.new(-size.X, -size.Y, size.Z)
                                    }
                                    
                                    local screenVertices = {}
                                    local allOnScreen = true
                                    for i, v in ipairs(vertices) do
                                        local p, on = Camera:WorldToViewportPoint(v.p)
                                        if not on then allOnScreen = false end
                                        screenVertices[i] = Vector2.new(p.X, p.Y)
                                    end
                                    
                                    if allOnScreen then
                                        local connections = {
                                            {1,2}, {2,3}, {3,4}, {4,1},
                                            {5,6}, {6,7}, {7,8}, {8,5},
                                            {1,5}, {2,6}, {3,7}, {4,8}
                                        }
                                        for i, conn in ipairs(connections) do
                                            local line = objects.Box3D[i]
                                            line.From = screenVertices[conn[1]]
                                            line.To = screenVertices[conn[2]]
                                            line.Color = currentColor
                                            line.Visible = true
                                        end
                                    else
                                        for _, line in ipairs(objects.Box3D) do line.Visible = false end
                                    end
                                else
                                    for _, line in ipairs(objects.Box3D) do line.Visible = false end
                                end
                                
                                -- 更新名稱與距離
                                if env_global.ESPNames then
                                    local text = entity.Name
                                    if env_global.ESPDistance then
                                        text = text .. string.format(" [%dm]", math.floor(distance))
                                    end
                                    objects.Name.Text = text
                                    objects.Name.Position = pos - Vector2.new(0, sizeY/2 + 15)
                                    objects.Name.Color = currentColor
                                    objects.Name.Visible = true
                                else
                                    objects.Name.Visible = false
                                end
                                
                                -- 更新追蹤線
                                if env_global.ESPTracers then
                                    local origin = Vector2.new(viewportSize.X / 2, viewportSize.Y) -- Bottom
                                    if env_global.ESPTracerOrigin == "Center" then
                                        origin = viewportSize / 2
                                    elseif env_global.ESPTracerOrigin == "Top" then
                                        origin = Vector2.new(viewportSize.X / 2, 0)
                                    elseif env_global.ESPTracerOrigin == "Mouse" then
                                        origin = UserInputService:GetMouseLocation()
                                    end
                                    
                                    objects.Tracer.From = origin
                                    objects.Tracer.To = pos
                                    objects.Tracer.Color = currentColor
                                    objects.Tracer.Visible = true
                                else
                                    objects.Tracer.Visible = false
                                end
                                
                                -- 更新骨骼
                                if env_global.ESPSkeleton then
                                    local connections = {
                                        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                                    }
                                    
                                    local skeletonParts = {}
                                    if char:FindFirstChild("UpperTorso") then -- R15
                                        skeletonParts = connections
                                    else -- R6
                                        skeletonParts = {
                                            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
                                            {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
                                        }
                                    end
                                    
                                    for i, conn in ipairs(skeletonParts) do
                                        local p1 = char:FindFirstChild(conn[1])
                                        local p2 = char:FindFirstChild(conn[2])
                                        local line = objects.Skeleton[i]
                                        
                                        if p1 and p2 and line then
                                            local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                                            local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                                            
                                            if on1 and on2 then
                                                line.From = Vector2.new(pos1.X, pos1.Y)
                                                line.To = Vector2.new(pos2.X, pos2.Y)
                                                line.Color = currentColor
                                                line.Thickness = env_global.ESPSkeletonThickness or 1
                                                line.Visible = true
                                            else
                                                line.Visible = false
                                            end
                                        elseif line then
                                            line.Visible = false
                                        end
                                    end
                                    -- 隱藏多餘的線 (R15 有 14 條, R6 只有 5 條)
                                    for i = #skeletonParts + 1, #objects.Skeleton do
                                        objects.Skeleton[i].Visible = false
                                    end
                                else
                                    for _, line in ipairs(objects.Skeleton) do line.Visible = false end
                                end
                                
                                -- 更新 Health Bar & Text
                                if env_global.ESPHealthBar then
                                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                    local barHeight = sizeY
                                    local barPos = Vector2.new(pos.X - sizeX/2 - 5, pos.Y + sizeY/2)
                                    
                                    objects.HealthBarBG.From = barPos
                                    objects.HealthBarBG.To = barPos - Vector2.new(0, barHeight)
                                    objects.HealthBarBG.Visible = true
                                    
                                    objects.HealthBar.From = barPos
                                    objects.HealthBar.To = barPos - Vector2.new(0, barHeight * healthPercent)
                                    objects.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                                    objects.HealthBar.Visible = true
        
                                    if env_global.ESPHealthText then
                                        objects.HealthText.Text = math.floor(hum.Health)
                                        objects.HealthText.Position = objects.HealthBar.To - Vector2.new(15, 0)
                                        objects.HealthText.Visible = true
                                        objects.HealthText.Color = objects.HealthBar.Color
                                    else
                                        objects.HealthText.Visible = false
                                    end
                                else
                                    objects.HealthBar.Visible = false
                                    objects.HealthBarBG.Visible = false
                                    objects.HealthText.Visible = false
                                end
                                
                                -- 更新 Chams
                                if env_global.ESPChams then
                                    objects.Chams.Parent = char
                                    objects.Chams.Enabled = true
                                    objects.Chams.FillColor = currentColor
                                else
                                    objects.Chams.Enabled = false
                                end
                                
                                visible = true
                            end
                        end
                    end
                end
            end
            
            if not visible then
                objects.Box.Visible = false
                objects.BoxFill.Visible = false
                objects.Name.Visible = false
                objects.Tracer.Visible = false
                objects.HealthBar.Visible = false
                objects.HealthBarBG.Visible = false
                objects.HealthText.Visible = false
                objects.RadarDot.Visible = false
                objects.Chams.Enabled = false
                for _, line in ipairs(objects.Box3D) do line.Visible = false end
                for _, line in ipairs(objects.Skeleton) do line.Visible = false end
            end
        end
    end
            RadarCenter.Visible = false
            RadarCross1.Visible = false
            RadarCross2.Visible = false
        end

        -- 獲取所有當前有效的實體
        local currentEntities = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then currentEntities[p] = true end
        end
        
        -- 如果啟用了 NPC ESP，則獲取 NPC
        if env_global.AimbotNPCs then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        currentEntities[obj] = true
                        if not ESP_Objects[obj] then CreateESP(obj) end
                    end
                end
            end
        end

        for entity, objects in pairs(ESP_Objects) do
            if not currentEntities[entity] then
                RemoveESP(entity)
            else
                local char = entity:IsA("Player") and entity.Character or entity
                local isTeammate = entity:IsA("Player") and Core.IsTeammate(entity) or (entity:IsA("Model") and not Core.IsEnemyNPC(entity))
                local visible = false
                
                local shouldShow = false
                if env_global.ESPEnabled and char then
                    shouldShow = true
                    if env_global.ESPTeamCheck and isTeammate and not env_global.ESPShowTeammates then
                        shouldShow = false
                    end
                end

                if shouldShow then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if hrp and hum and hum.Health > 0 then
                        local hrpPos = hrp.Position
                        local distance = (Camera.CFrame.Position - hrpPos).Magnitude
                        
                        -- 距離過濾
                        if distance <= env_global.ESPMaxDistance then
                            local pos, onScreen = Camera:WorldToViewportPoint(hrpPos)
                            local currentColor = env_global.ESPRainbow and rainbowColor or (isTeammate and Color3.new(0, 1, 0) or env_global.ESPColor)

                            -- 雷達更新
                            if env_global.ESPRadar then
                                local relativePos = (hrpPos - Camera.CFrame.Position)
                                local distance = relativePos.Magnitude
                                
                                if distance <= env_global.ESPRadarRange then
                                    local rSize = RadarFrame.Size
                                    local rCenter = RadarFrame.Position + rSize / 2
                                    
                                    -- 旋轉座標以匹配相機朝向
                                    local _, camY, _ = Camera.CFrame:ToOrientation()
                                    local angle = math.atan2(relativePos.Z, relativePos.X) + camY + math.rad(90)
                                    local cosA = math.cos(angle)
                                    local sinA = math.sin(angle)
                                    
                                    local dx = distance * cosA * (rSize.X / 2 / env_global.ESPRadarRange)
                                    local dy = distance * sinA * (rSize.Y / 2 / env_global.ESPRadarRange)
                                    
                                    objects.RadarDot.Position = rCenter + Vector2.new(dx, dy)
                                    objects.RadarDot.Color = currentColor
                                    objects.RadarDot.Visible = true
                                else
                                    objects.RadarDot.Visible = false
                                end
                            else
                                objects.RadarDot.Visible = false
                            end

                            if onScreen then
                        -- 計算 Box 大小
                        local head = char:FindFirstChild("Head")
                        local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or {Y = pos.Y - 2}
                        local legPos = Camera:WorldToViewportPoint(hrpPos - Vector3.new(0, 3, 0))
                        local sizeY = math.abs(headPos.Y - legPos.Y)
                        local sizeX = sizeY * 0.6
                        
                        -- 更新 Box
                        objects.Box.Size = Vector2.new(sizeX, sizeY)
                        objects.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                        objects.Box.Color = currentColor
                        objects.Box.Thickness = env_global.ESPBoxThickness
                        objects.Box.Visible = env_global.ESPBoxes
                        
                        -- 更新 Box Fill
                        objects.BoxFill.Size = objects.Box.Size
                        objects.BoxFill.Position = objects.Box.Position
                        objects.BoxFill.Color = currentColor
                        objects.BoxFill.Transparency = env_global.ESPBoxFillTransparency
                        objects.BoxFill.Visible = env_global.ESPBoxFill and env_global.ESPBoxes

                        -- 更新 Name
                        if env_global.ESPNames then
                            local nameStr = entity:IsA("Player") and entity.Name or entity.Name
                            if env_global.ESPDistance then
                                nameStr = nameStr .. " [" .. math.floor(distance) .. "m]"
                            end
                            objects.Name.Text = nameStr
                            objects.Name.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 15)
                            objects.Name.Color = currentColor
                            objects.Name.Size = env_global.ESPTextSize
                            objects.Name.Visible = true
                        else
                            objects.Name.Visible = false
                        end

                        -- 更新 Tracers
                        if env_global.ESPTracers then
                            local origin = Vector2.new(viewportSize.X / 2, viewportSize.Y) -- Default Bottom
                            if env_global.ESPTracerOrigin == "Center" then
                                origin = viewportSize / 2
                            elseif env_global.ESPTracerOrigin == "Top" then
                                origin = Vector2.new(viewportSize.X / 2, 0)
                            elseif env_global.ESPTracerOrigin == "Mouse" then
                                origin = UserInputService:GetMouseLocation()
                            end
                            
                            objects.Tracer.From = origin
                            objects.Tracer.To = Vector2.new(pos.X, pos.Y + sizeY/2)
                            objects.Tracer.Color = currentColor
                            objects.Tracer.Visible = true
                        else
                            objects.Tracer.Visible = false
                        end

                        -- 更新 3D Box
                        if env_global.ESP3DBoxes then
                            local cf = char:GetPivot()
                            local size = Vector3.new(4, 6, 4)
                            local points = {
                                cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2)
                            }
                            local screenPoints = {}
                            for i, p in ipairs(points) do
                                local v, on = Camera:WorldToViewportPoint(p.Position)
                                screenPoints[i] = {v, on}
                            end
                            
                            local lines = {
                                {1,2}, {2,3}, {3,4}, {4,1},
                                {5,6}, {6,7}, {7,8}, {8,5},
                                {1,5}, {2,6}, {3,7}, {4,8}
                            }
                            for i, connection in ipairs(lines) do
                                local p1 = screenPoints[connection[1]]
                                local p2 = screenPoints[connection[2]]
                                local line = objects.Box3D[i]
                                if p1[2] and p2[2] then
                                    line.From = Vector2.new(p1[1].X, p1[1].Y)
                                    line.To = Vector2.new(p2[1].X, p2[1].Y)
                                    line.Color = currentColor
                                    line.Thickness = env_global.ESPBoxThickness
                                    line.Visible = true
                                else
                                    line.Visible = false
                                end
                            end
                        else
                            for _, line in ipairs(objects.Box3D) do line.Visible = false end
                        end

                        -- 更新 Skeleton
                        if env_global.ESPSkeleton then
                            local isR15 = hum.RigType == Enum.HumanoidRigType.R15
                            local skeletonParts = isR15 and {
                                {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                                {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                                {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                                {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                                {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                            } or {
                                {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
                                {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
                            }
                            
                            for i, pair in ipairs(skeletonParts) do
                                local p1 = char:FindFirstChild(pair[1])
                                local p2 = char:FindFirstChild(pair[2])
                                local line = objects.Skeleton[i]
                                if line and p1 and p2 then
                                    local v1, on1 = Camera:WorldToViewportPoint(p1.Position)
                                    local v2, on2 = Camera:WorldToViewportPoint(p2.Position)
                                    if on1 and on2 then
                                        line.From = Vector2.new(v1.X, v1.Y)
                                        line.To = Vector2.new(v2.X, v2.Y)
                                        line.Color = currentColor
                                        line.Thickness = env_global.ESPSkeletonThickness or 1
                                        line.Visible = true
                                    else
                                        line.Visible = false
                                    end
                                elseif line then
                                    line.Visible = false
                                end
                            end
                            -- 隱藏多餘的線 (R15 有 14 條, R6 只有 5 條)
                            for i = #skeletonParts + 1, #objects.Skeleton do
                                objects.Skeleton[i].Visible = false
                            end
                        else
                            for _, line in ipairs(objects.Skeleton) do line.Visible = false end
                        end
                        
                        -- 更新 Health Bar & Text
                        if env_global.ESPHealthBar then
                            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            local barHeight = sizeY
                            local barPos = Vector2.new(pos.X - sizeX/2 - 5, pos.Y + sizeY/2)
                            
                            objects.HealthBarBG.From = barPos
                            objects.HealthBarBG.To = barPos - Vector2.new(0, barHeight)
                            objects.HealthBarBG.Visible = true
                            
                            objects.HealthBar.From = barPos
                            objects.HealthBar.To = barPos - Vector2.new(0, barHeight * healthPercent)
                            objects.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                            objects.HealthBar.Visible = true

                            if env_global.ESPHealthText then
                                objects.HealthText.Text = math.floor(hum.Health)
                                objects.HealthText.Position = objects.HealthBar.To - Vector2.new(15, 0)
                                objects.HealthText.Visible = true
                                objects.HealthText.Color = objects.HealthBar.Color
                            else
                                objects.HealthText.Visible = false
                            end
                        else
                            objects.HealthBar.Visible = false
                            objects.HealthBarBG.Visible = false
                            objects.HealthText.Visible = false
                        end
                        
                        -- 更新 Chams
                        if env_global.ESPChams then
                            objects.Chams.Parent = char
                            objects.Chams.Enabled = true
                            objects.Chams.FillColor = currentColor
                        else
                            objects.Chams.Enabled = false
                        end
                        
                        visible = true
                    end
                end
            end
        end
        
        if not visible then
            objects.Box.Visible = false
            objects.BoxFill.Visible = false
            objects.Name.Visible = false
            objects.Tracer.Visible = false
            objects.HealthBar.Visible = false
            objects.HealthBarBG.Visible = false
            objects.HealthText.Visible = false
            objects.RadarDot.Visible = false
            objects.Chams.Enabled = false
            for _, line in ipairs(objects.Box3D) do line.Visible = false end
            for _, line in ipairs(objects.Skeleton) do line.Visible = false end
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

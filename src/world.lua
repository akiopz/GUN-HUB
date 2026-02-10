---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol World Module
-- 放置於: src/world.lua

local World = {}

function World.Init(Core)
    ---@class GlobalEnv
    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    local Lighting = game:GetService("Lighting")
    local RunService = Core.RunService

    -- [[ 配置初始化 ]]
    env_global.MinecraftStyle = env_global.MinecraftStyle or false
    env_global.FullBright = env_global.FullBright or false
    env_global.NoFog = env_global.NoFog or false
    env_global.CustomGravity = env_global.CustomGravity or 196.2
    env_global.GravityEnabled = env_global.GravityEnabled or false
    env_global.FPSUnlocker = env_global.FPSUnlocker or false
    env_global.TimeOfDay = env_global.TimeOfDay or 14
    env_global.CameraFOV = env_global.CameraFOV or 70
    env_global.NoTextures = env_global.NoTextures or false
    env_global.GlobalWalkSpeed = env_global.GlobalWalkSpeed or false
    env_global.GlobalWalkSpeedValue = env_global.GlobalWalkSpeedValue or 16
    env_global.GlobalJumpPower = env_global.GlobalJumpPower or false
    env_global.GlobalJumpPowerValue = env_global.GlobalJumpPowerValue or 50
    env_global.AmbientColor = env_global.AmbientColor or Color3.fromRGB(127, 127, 127)
    env_global.CustomAmbientEnabled = env_global.CustomAmbientEnabled or false
    env_global.NoLagV2 = env_global.NoLagV2 or false
    env_global.ClearSky = env_global.ClearSky or false

    -- 儲存原始設定
    local originalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation
    }

    local originalSky = nil
    local function GetOriginalSky()
        if originalSky then return originalSky end
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then
            originalSky = sky:Clone()
        end
        return originalSky
    end

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("NoLagV2", {
        Name = "極限 FPS 優化 (No Lag V2)",
        Description = "移除陰影、降低渲染品質、關閉特效",
        Category = "World",
        Callback = function(state)
            env_global.NoLagV2 = state
            Lighting.GlobalShadows = not state
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("PostProcessEffect") or v:IsA("Beam") or v:IsA("Trail") then
                    v.Enabled = not state
                elseif v:IsA("Explosion") then
                    v.Visible = not state
                end
            end
            if state then
                settings().Rendering.QualityLevel = 1
            else
                settings().Rendering.QualityLevel = 0 -- 自動
            end
        end
    })

    Core.RegisterFeature("ClearSky", {
        Name = "清空天空盒 (Clear Sky)",
        Category = "World",
        Callback = function(state)
            env_global.ClearSky = state
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if state then
                GetOriginalSky()
                if sky then sky:Destroy() end
                local newSky = Instance.new("Sky")
                newSky.SkyboxBk = "rbxassetid://0"
                newSky.SkyboxDn = "rbxassetid://0"
                newSky.SkyboxFt = "rbxassetid://0"
                newSky.SkyboxLf = "rbxassetid://0"
                newSky.SkyboxRt = "rbxassetid://0"
                newSky.SkyboxUp = "rbxassetid://0"
                newSky.SunTextureId = "rbxassetid://0"
                newSky.MoonTextureId = "rbxassetid://0"
                newSky.Parent = Lighting
            else
                if sky then sky:Destroy() end
                if originalSky then
                    originalSky:Clone().Parent = Lighting
                end
            end
        end
    })

    Core.UI.AddSlider("CameraFOV", {
        Name = "視角範圍 (FOV)",
        Category = "World",
        Min = 70,
        Max = 120,
        Default = 70,
        Callback = function(v)
            env_global.CameraFOV = v
            Core.Camera.FieldOfView = v
        end
    })

    Core.RegisterFeature("CustomAmbient", {
        Name = "自定義環境光 (Ambient)",
        Category = "World",
        Callback = function(state)
            env_global.CustomAmbientEnabled = state
            if not state then
                Lighting.Ambient = originalLighting.Ambient
                Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            end
        end
    })

    Core.UI.AddColorPicker("AmbientColor", {
        Name = "環境光顏色",
        Category = "World",
        Default = env_global.AmbientColor,
        Callback = function(color)
            env_global.AmbientColor = color
        end
    })

    Core.RegisterFeature("NoTextures", {
        Name = "移除材質 (No Textures)",
        Description = "移除所有物體材質以大幅提升 FPS",
        Category = "World",
        Callback = function(state)
            env_global.NoTextures = state
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v:IsA("MeshPart") then
                    if state then
                        v:SetAttribute("OriginalMaterial", v.Material.Name)
                        v.Material = Enum.Material.SmoothPlastic
                    else
                        local original = v:GetAttribute("OriginalMaterial")
                        if original then
                            v.Material = Enum.Material[original]
                        end
                    end
                elseif v:IsA("Texture") or v:IsA("Decal") then
                    v.Transparency = state and 1 or 0
                end
            end
        end
    })

    Core.RegisterFeature("GlobalWalkSpeed", {
        Name = "全局移動速度 (Global Speed)",
        Description = "影響伺服器內所有玩家與 NPC (本地模擬)",
        Category = "World",
        Callback = function(state)
            env_global.GlobalWalkSpeed = state
        end
    })

    Core.UI.AddSlider("GlobalWalkSpeedValue", {
        Name = "全局速度數值",
        Category = "World",
        Min = 0,
        Max = 300,
        Default = 16,
        Callback = function(v)
            env_global.GlobalWalkSpeedValue = v
        end
    })

    Core.RegisterFeature("GlobalJumpPower", {
        Name = "全局跳躍高度 (Global Jump)",
        Description = "影響伺服器內所有玩家與 NPC (本地模擬)",
        Category = "World",
        Callback = function(state)
            env_global.GlobalJumpPower = state
        end
    })

    Core.UI.AddSlider("GlobalJumpPowerValue", {
        Name = "全局跳躍數值",
        Category = "World",
        Min = 0,
        Max = 500,
        Default = 50,
        Callback = function(v)
            env_global.GlobalJumpPowerValue = v
        end
    })

    Core.RegisterFeature("MinecraftStyle", {
        Name = "麥塊風格 (MC Style)",
        Description = "使世界色調變得明亮、飽和，類似 Minecraft 的風格",
        Category = "World",
        Callback = function(state)
            env_global.MinecraftStyle = state
            if state then
                Lighting.Ambient = Color3.fromRGB(150, 150, 150)
                Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
                Lighting.Brightness = 3
                Lighting.GlobalShadows = false
                Lighting.ExposureCompensation = 0.5
            else
                Lighting.Ambient = originalLighting.Ambient
                Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
                Lighting.Brightness = originalLighting.Brightness
                Lighting.GlobalShadows = originalLighting.GlobalShadows
                Lighting.ExposureCompensation = originalLighting.ExposureCompensation
            end
        end
    })

    Core.RegisterFeature("FullBright", {
        Name = "全亮模式 (Full Bright)",
        Category = "World",
        Callback = function(state)
            env_global.FullBright = state
        end
    })

    Core.RegisterFeature("NoFog", {
        Name = "移除霧氣 (No Fog)",
        Category = "World",
        Callback = function(state)
            env_global.NoFog = state
            if state then
                Lighting.FogEnd = 100000
            else
                Lighting.FogEnd = originalLighting.FogEnd
            end
        end
    })

    Core.RegisterFeature("GravityEnabled", {
        Name = "修改重力 (Gravity)",
        Category = "World",
        Callback = function(state)
            env_global.GravityEnabled = state
            if not state then
                workspace.Gravity = 196.2
            end
        end
    })

    Core.UI.AddSlider("GravityValue", {
        Name = "重力數值",
        Category = "World",
        Min = 0,
        Max = 500,
        Default = 196.2,
        Callback = function(v)
            env_global.CustomGravity = v
            if env_global.GravityEnabled then
                workspace.Gravity = v
            end
        end
    })

    Core.UI.AddSlider("TimeOfDay", {
        Name = "時間調整 (Time)",
        Category = "World",
        Min = 0,
        Max = 24,
        Default = 14,
        Callback = function(v)
            env_global.TimeOfDay = v
            Lighting.ClockTime = v
        end
    })

    Core.RegisterFeature("FPSUnlocker", {
        Name = "FPS 解鎖 (FPS Unlock)",
        Category = "World",
        Callback = function(state)
            env_global.FPSUnlocker = state
            if setfpscap then
                setfpscap(state and 999 or 60)
            end
        end
    })

    -- [[ 全局 Humanoid 快取 ]]
    local cachedHumanoids = {}
    local lastCacheUpdate = 0
    local function UpdateHumanoidCache()
        local now = tick()
        if now - lastCacheUpdate < 2 then return end -- 每 2 秒更新一次快取
        lastCacheUpdate = now
        
        table.clear(cachedHumanoids)
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Humanoid") then
                table.insert(cachedHumanoids, v)
            end
        end
    end

    -- [[ 循環邏輯 ]]
    RunService.RenderStepped:Connect(function()
        if env_global.FullBright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        elseif env_global.CustomAmbientEnabled then
            Lighting.Ambient = env_global.AmbientColor
            Lighting.OutdoorAmbient = env_global.AmbientColor
        end
        
        if env_global.GravityEnabled then
            workspace.Gravity = env_global.CustomGravity
        end

        local char = Core.LocalPlayer.Character
        
        -- [[ 全局修改邏輯 (影響所有 Humanoid) ]]
        if env_global.GlobalWalkSpeed or env_global.GlobalJumpPower then
            UpdateHumanoidCache()
            for _, v in ipairs(cachedHumanoids) do
                if v.Parent and v.Parent ~= char then
                    if env_global.GlobalWalkSpeed then
                        v.WalkSpeed = env_global.GlobalWalkSpeedValue
                    end
                    if env_global.GlobalJumpPower then
                        v.JumpPower = env_global.GlobalJumpPowerValue
                        v.UseJumpPower = true
                    end
                end
            end
        end
    end)

    -- [[ 移除 redundant JumpRequest (已移至 misc.lua) ]]
    -- Core.UserInputService.JumpRequest:Connect(function() ... end)

    print("[Halol] 世界模組已啟動 (含進階功能)")
end

return World

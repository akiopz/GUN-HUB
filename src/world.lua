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

    -- [[ 註冊功能 ]]
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

    -- [[ 循環邏輯 ]]
    RunService.RenderStepped:Connect(function()
        if env_global.FullBright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        end
        
        if env_global.GravityEnabled then
            workspace.Gravity = env_global.CustomGravity
        end
    end)

    print("[Halol] 世界模組已啟動")
end

return World

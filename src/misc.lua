---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Misc Module
-- 放置於: src/misc.lua

local Misc = {}

function Misc.Init(Core)
    ---@class GlobalEnv
    local env_global = (getgenv or function() return _G end)() --[[@as GlobalEnv]]
    local RunService = Core.RunService
    local lp = Core.LocalPlayer

    -- [[ 配置 ]]
    env_global.WalkSpeedMultiplier = env_global.WalkSpeedMultiplier or 1
    env_global.JumpPowerMultiplier = env_global.JumpPowerMultiplier or 1
    env_global.InfJumpEnabled = env_global.InfJumpEnabled or false
    env_global.NoClipEnabled = env_global.NoClipEnabled or false

    -- [[ 註冊功能 ]]
    Core.RegisterFeature("InfJump", {
        Name = "無限跳躍 (Infinite Jump)",
        Category = "Misc",
        Callback = function(state)
            env_global.InfJumpEnabled = state
        end
    })

    Core.RegisterFeature("NoClip", {
        Name = "穿牆 (NoClip)",
        Category = "Misc",
        Callback = function(state)
            env_global.NoClipEnabled = state
        end
    })

    -- [[ 移動功能優化 ]]
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

    RunService.Stepped:Connect(function()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if hum then
            -- Speed 優化：僅在需要時設定
            if env_global.WalkSpeedMultiplier > 1 then
                hum.WalkSpeed = 16 * env_global.WalkSpeedMultiplier
            end
            
            -- NoClip 優化：使用快取的零件列表
            if env_global.NoClipEnabled then
                for i = 1, #charParts do
                    local part = charParts[i]
                    if part.Parent then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)

    -- [[ 無限跳躍 ]]
    Core.UserInputService.JumpRequest:Connect(function()
        if env_global.InfJumpEnabled and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            lp.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end)

    print("[Halol] 雜項模組已啟動")
end

return Misc

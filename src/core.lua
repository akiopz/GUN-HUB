---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Core Module
-- 放置於: src/core.lua

local Core = {}

local getgenv = (getgenv or function() return _G end)
---@class GlobalEnv
local env_global = getgenv() --[[@as GlobalEnv]]

-- [[ 基礎環境定義 ]]
Core.game = game
Core.workspace = workspace
Core.tick = tick
Core.HttpService = game:GetService("HttpService")
Core.RunService = game:GetService("RunService")
Core.UserInputService = game:GetService("UserInputService")
Core.TweenService = game:GetService("TweenService")
Core.Players = game:GetService("Players")
Core.LocalPlayer = Core.Players.LocalPlayer
Core.Camera = workspace.CurrentCamera

-- [[ 跨執行器兼容性層 (Universal Compatibility Layer) ]]
Core.load_func = (env_global.loadstring or env_global.load or loadstring or load)
Core.hookmetamethod = env_global.hookmetamethod or (getgenv and getgenv().hookmetamethod)
Core.newcclosure = env_global.newcclosure or (getgenv and getgenv().newcclosure) or function(f) return f end
Core.checkcaller = env_global.checkcaller or (getgenv and getgenv().checkcaller) or function() return false end
Core.getnamecallmethod = env_global.getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
Core.hookfunction = env_global.hookfunction or (getgenv and getgenv().hookfunction)
Core.islclosure = env_global.islclosure or function(f) return type(f) == "function" end
Core.cloneref = env_global.cloneref or function(s) return s end
Core.Drawing = env_global.Drawing or (getgenv and getgenv().Drawing)
Core.request = (env_global.request or env_global.http_request or (http and http.request) or syn and syn.request)
Core.set_clipboard = (env_global.setclipboard or env_global.set_clipboard or (syn and syn.set_clipboard))
Core.get_genv = (getgenv or function() return _G end)

-- [[ 智能 GUI 容器獲取 (Smart GUI Container) ]]
Core.gethui = function()
    -- 針對 Solara/Wave/Oxygen 等執行器的優化
    local success, res = pcall(function() return env_global.gethui and env_global.gethui() end)
    if success and res then return res end
    
    success, res = pcall(function() return game:GetService("CoreGui") end)
    if success and res then return res end
    
    -- 如果 CoreGui 無法存取，嘗試 PlayerGui (Solara 常用)
    local lp = Core.LocalPlayer
    local playerGui = lp and lp:FindFirstChild("PlayerGui")
    if playerGui then
        return playerGui
    end
    
    return nil
end

Core.identifyexecutor = env_global.identifyexecutor or env_global.getexecutorname or function() return "Unknown" end
Core.read_file = env_global.readfile or function(...) return nil end
Core.write_file = env_global.writefile or function(...) return false end
Core.is_file = env_global.isfile or function(...) return false end
Core.is_folder = env_global.isfolder or function(...) return false end
Core.make_folder = env_global.makefolder or function(...) return false end
Core.list_files = env_global.listfiles or function(...) return {} end

-- [[ 針對特定執行器的自動優化 ]]
local executor = Core.identifyexecutor()
if tostring(executor):find("Solara") or tostring(executor):find("Zeus") then
    env_global.DisableAdvancedHooks = true 
    print("[Halol] 已針對 " .. tostring(executor) .. " 套用穩定性優化")
end

    -- [[ 啟動加載界面 (Loading Overlay) ]]
    local LoadingOverlay = nil
    function Core.ShowLoading(title)
        local gui = Core.gethui()
        if not gui then return end

        if LoadingOverlay then LoadingOverlay:Destroy() end

        LoadingOverlay = Instance.new("Frame")
        local main = Instance.new("Frame")
        local titleLabel = Instance.new("TextLabel")
        local statusLabel = Instance.new("TextLabel")
        local progressBarBG = Instance.new("Frame")
        local progressBar = Instance.new("Frame")

        LoadingOverlay.Name = "HalolLoading"
        LoadingOverlay.Size = UDim2.new(1, 0, 1, 0)
        LoadingOverlay.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        LoadingOverlay.BackgroundTransparency = 0.5
        LoadingOverlay.BorderSizePixel = 0
        LoadingOverlay.Parent = gui

        main.Size = UDim2.new(0, 300, 0, 120)
        main.Position = UDim2.new(0.5, -150, 0.5, -60)
        main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        main.BorderSizePixel = 0
        main.Parent = LoadingOverlay
        Core.AddCorner(main, UDim.new(0, 10))
        Core.AddStroke(main, Color3.fromRGB(60, 60, 65), 2)

        titleLabel.Size = UDim2.new(1, 0, 0, 40)
        titleLabel.Position = UDim2.new(0, 0, 0, 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title or "HALOL SHOOTING"
        titleLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
        titleLabel.TextSize = 20
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = main

        statusLabel.Size = UDim2.new(1, -40, 0, 20)
        statusLabel.Position = UDim2.new(0, 20, 0, 50)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "正在初始化系統..."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.TextSize = 14
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.Parent = main

        progressBarBG.Size = UDim2.new(1, -40, 0, 6)
        progressBarBG.Position = UDim2.new(0, 20, 0, 85)
        progressBarBG.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        progressBarBG.BorderSizePixel = 0
        progressBarBG.Parent = main
        Core.AddCorner(progressBarBG, UDim.new(0, 3))

        progressBar.Size = UDim2.new(0, 0, 1, 0)
        progressBar.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        progressBar.BorderSizePixel = 0
        progressBar.Parent = progressBarBG
        Core.AddCorner(progressBar, UDim.new(0, 3))

        -- 動態效果
        task.spawn(function()
            while LoadingOverlay and LoadingOverlay.Parent do
                titleLabel.TextColor3 = Color3.fromRGB(0, 150, 255):lerp(Color3.fromRGB(0, 255, 255), (math.sin(tick() * 2) + 1) / 2)
                task.wait()
            end
        end)

        local overlay = {
            Instance = LoadingOverlay,
            Status = statusLabel,
            Bar = progressBar
        }

        function overlay:Update(text, progress)
            if self.Status then self.Status.Text = text end
            if self.Bar then
                Core.TweenService:Create(self.Bar, TweenInfo.new(0.3), {
                    Size = UDim2.new(progress or 0, 0, 1, 0)
                }):Play()
            end
        end

        function overlay:Hide()
            if self.Instance then
                Core.TweenService:Create(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                Core.TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Position = UDim2.new(0.5, -150, 1, 20)
                }):Play()
                task.delay(0.5, function() self.Instance:Destroy() end)
            end
        end

        return overlay
    end

    -- [[ 跨執行器 API 兼容層 ]]
    function Core.GetExecutorInfo()
        local name, version = "Unknown", "1.0"
        pcall(function()
            if env_global.identifyexecutor then
                name, version = env_global.identifyexecutor()
            elseif env_global.getexecutorname then
                name = env_global.getexecutorname()
            end
        end)
        return name, version
    end

    -- [[ 錯誤捕捉系統 (Error Handling) ]]
    function Core.SafeCall(func, ...)
        local success, result = pcall(func, ...)
        if not success then
            warn("[Halol Error]: " .. tostring(result))
            Core.Notify("腳本運行錯誤", tostring(result), 5)
        end
        return success, result
    end

    -- [[ 通知系統 (Notification System) ]]
    local Notifications = {}
    function Core.Notify(title, text, duration, type)
        task.spawn(function()
            local gui = Core.gethui()
            if not gui then return end

            local notifyFrame = Instance.new("Frame")
            local notifyTitle = Instance.new("TextLabel")
            local notifyText = Instance.new("TextLabel")
            local bar = Instance.new("Frame")
            local iconLabel = Instance.new("TextLabel")

            local accentColor = Color3.fromRGB(0, 150, 255)
            local icon = "ℹ️"
            
            if type == "success" then
                accentColor = Color3.fromRGB(0, 255, 100)
                icon = "✅"
            elseif type == "error" then
                accentColor = Color3.fromRGB(255, 50, 50)
                icon = "❌"
            elseif type == "warning" then
                accentColor = Color3.fromRGB(255, 200, 0)
                icon = "⚠️"
            end

            notifyFrame.Size = UDim2.new(0, 240, 0, 65)
            notifyFrame.Position = UDim2.new(1, 20, 1, -80 - (#Notifications * 75))
            notifyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            notifyFrame.BorderSizePixel = 0
            notifyFrame.Parent = gui
            Core.AddCorner(notifyFrame, UDim.new(0, 8))
            Core.AddStroke(notifyFrame, Color3.fromRGB(50, 50, 55), 1)

            iconLabel.Size = UDim2.new(0, 30, 0, 30)
            iconLabel.Position = UDim2.new(0, 10, 0, 10)
            iconLabel.BackgroundTransparency = 1
            iconLabel.Text = icon
            iconLabel.TextSize = 20
            iconLabel.Parent = notifyFrame

            notifyTitle.Size = UDim2.new(1, -50, 0, 20)
            notifyTitle.Position = UDim2.new(0, 45, 0, 8)
            notifyTitle.BackgroundTransparency = 1
            notifyTitle.Text = title or "Halol Shooting"
            notifyTitle.TextColor3 = accentColor
            notifyTitle.TextSize = 14
            notifyTitle.Font = Enum.Font.GothamBold
            notifyTitle.TextXAlignment = Enum.TextXAlignment.Left
            notifyTitle.Parent = notifyFrame

            notifyText.Size = UDim2.new(1, -50, 0, 30)
            notifyText.Position = UDim2.new(0, 45, 0, 25)
            notifyText.BackgroundTransparency = 1
            notifyText.Text = text or ""
            notifyText.TextColor3 = Color3.fromRGB(220, 220, 220)
            notifyText.TextSize = 12
            notifyText.Font = Enum.Font.Gotham
            notifyText.TextXAlignment = Enum.TextXAlignment.Left
            notifyText.TextWrapped = true
            notifyText.Parent = notifyFrame

            bar.Size = UDim2.new(1, 0, 0, 2)
            bar.Position = UDim2.new(0, 0, 1, -2)
            bar.BackgroundColor3 = accentColor
            bar.BorderSizePixel = 0
            bar.Parent = notifyFrame
            Core.AddCorner(bar, UDim.new(0, 2))

            table.insert(Notifications, notifyFrame)

            -- 進場動畫
            Core.TweenService:Create(notifyFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -260, 1, -80 - ((#Notifications - 1) * 75))
            }):Play()

            -- 進度條動畫
            Core.TweenService:Create(bar, TweenInfo.new(duration or 5, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 0, 2)
            }):Play()

            task.wait(duration or 5)

            -- 退場動畫
            local tween = Core.TweenService:Create(notifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, notifyFrame.Position.Y.Scale, notifyFrame.Position.Y.Offset)
            })
            tween:Play()
            tween.Completed:Connect(function()
                notifyFrame:Destroy()
                for i, v in ipairs(Notifications) do
                    if v == notifyFrame then
                        table.remove(Notifications, i)
                        break
                    end
                end
                -- 重新排列其餘通知
                for i, v in ipairs(Notifications) do
                    Core.TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(1, -260, 1, -80 - ((i - 1) * 75))
                    }):Play()
                end
            end)
        end)
    end

    function Core.Success(text, duration) Core.Notify("成功", text, duration or 5, "success") end
    function Core.Info(text, duration) Core.Notify("提示", text, duration or 5, "info") end
    function Core.Warn(text, duration) Core.Notify("警告", text, duration or 5, "warning") end
    function Core.Error(text, duration) Core.Notify("錯誤", text, duration or 5, "error") end

    -- [[ 強化隊友檢查系統 ]]
    function Core.IsTeammate(player)
        if not player or player == Core.LocalPlayer then return true end
        
        -- 1. 原生 Team 檢查
        if player.Team ~= nil then
            if player.Team == Core.LocalPlayer.Team then
                return true
            end
        end
        
        -- 2. TeamColor 檢查 (部分遊戲 Team 物件可能被混淆或無效)
        if player.TeamColor == Core.LocalPlayer.TeamColor and player.TeamColor ~= nil then
            -- 排除兩者都是 Neutral 的情況 (如果遊戲預設 Neutral 為敵對)
            if not player.Neutral then
                return true
            end
        end

        -- 3. 檢查 Teams 服務中的歸屬
        local teams = game:GetService("Teams"):GetTeams()
        if #teams > 0 then
            for _, team in ipairs(teams) do
                if player:IsDescendantOf(team) and Core.LocalPlayer:IsDescendantOf(team) then
                    return true
                end
            end
        end
        
        -- 3. 屬性檢查 (擴展多種常見的隊伍屬性鍵值)
        local teamKeys = {"Team", "Side", "Faction", "Alliance", "Group", "Club", "Organization"}
        for _, key in ipairs(teamKeys) do
            local playerAttr = player:GetAttribute(key)
            local lpAttr = Core.LocalPlayer:GetAttribute(key)
            if playerAttr ~= nil and playerAttr == lpAttr then
                return true
            end
        end
        
        -- 4. 角色內部物件檢查 (TeamValue/SideValue 等)
        local char = player.Character
        if char then
            local teamValue = char:FindFirstChild("Team") or char:FindFirstChild("Side") or char:FindFirstChild("Faction")
            local lpChar = Core.LocalPlayer.Character
            local lpTeamValue = lpChar and (lpChar:FindFirstChild("Team") or lpChar:FindFirstChild("Side") or lpChar:FindFirstChild("Faction"))
            
            if teamValue and lpTeamValue and teamValue:IsA("ValueBase") and lpTeamValue:IsA("ValueBase") then
                if teamValue.Value == lpTeamValue.Value then
                    return true
                end
            end
        end

        -- 5. 角色父物件檢查 (某些遊戲將同隊玩家放在 Workspace 下的特定 Folder)
        if char and char.Parent then
            local parent = char.Parent
            if parent.Name ~= "Workspace" and parent.Name ~= "Players" then
                -- 檢查名稱是否包含隊伍關鍵字
                local pName = parent.Name:lower()
                if pName:find("blue") or pName:find("red") or pName:find("team") or pName:find("ally") then
                    if Core.LocalPlayer.Character and Core.LocalPlayer.Character.Parent == parent then
                        return true
                    end
                end
            end
        end

        -- 6. 字符串名稱檢查 (例如：[Police] PlayerName)
        if player.DisplayName:find("%[") and Core.LocalPlayer.DisplayName:find("%[") then
            local pTag = player.DisplayName:match("%[(.-)%]")
            local lpTag = Core.LocalPlayer.DisplayName:match("%[(.-)%]")
            if pTag and lpTag and pTag == lpTag then
                return true
            end
        end

        -- 7. 角色外觀顏色檢查 (BodyColors)
        if char and Core.LocalPlayer.Character then
            local pBC = char:FindFirstChildOfClass("BodyColors")
            local lpBC = Core.LocalPlayer.Character:FindFirstChildOfClass("BodyColors")
            if pBC and lpBC then
                -- 檢查軀幹顏色是否一致
                if pBC.TorsoColor == lpBC.TorsoColor then
                    return true
                end
            end
        end

        return false
    end

    -- [[ NPC 敵對檢查邏輯 ]]
    function Core.IsEnemyNPC(model)
        if not model then return false end
        
        -- 1. 檢查屬性 (Team/Side/Faction)
        local teamKeys = {"Team", "Side", "Faction", "Alliance"}
        for _, key in ipairs(teamKeys) do
            local val = model:GetAttribute(key)
            if val then
                local sVal = tostring(val):lower()
                if sVal:find("player") or sVal:find("friendly") or sVal:find("ally") or sVal:find("citizen") then
                    return false
                end
            end
        end

        -- 2. 檢查子物件 (TeamValue)
        local teamValue = model:FindFirstChild("Team") or model:FindFirstChild("Side") or model:FindFirstChild("Faction")
        if teamValue and teamValue:IsA("ValueBase") then
            local val = tostring(teamValue.Value):lower()
            if val:find("player") or val:find("friendly") or val:find("ally") then
                return false
            end
        end

        -- 3. 檢查頭頂標籤顏色
        local overhead = model:FindFirstChild("Overhead") or model:FindFirstChild("NameTag") or model:FindFirstChild("Head") and model.Head:FindFirstChildOfClass("BillboardGui")
        if overhead then
            local textLabel = overhead:FindFirstChildOfClass("TextLabel") or (overhead:IsA("BillboardGui") and overhead:FindFirstChildOfClass("TextLabel"))
            if textLabel then
                local color = textLabel.TextColor3
                -- 綠色/藍色/白色(中立) 通常非敵人
                if (color.G > 0.7 and color.R < 0.4 and color.B < 0.4) or -- 綠色
                   (color.B > 0.7 and color.R < 0.4 and color.G < 0.7) or -- 藍色
                   (color.R > 0.8 and color.G > 0.8 and color.B > 0.8) then -- 白色
                    return false
                end
            end
        end

        -- 4. 檢查名稱關鍵字
        local name = model.Name:lower()
        local keywords = {"friendly", "ally", "guard", "citizen", "civilian", "neutral", "shop", "quest"}
        for _, kw in ipairs(keywords) do
            if name:find(kw) then
                return false
            end
        end

        return true -- 預設視為敵人
    end

    -- [[ 統一敵對判斷入口 ]]
    function Core.IsEnemy(target)
        if not target then return false end
        
        local player = game:GetService("Players"):GetPlayerFromCharacter(target)
        if player then
            -- 如果是玩家，判斷是否為隊友
            return not Core.IsTeammate(player)
        else
            -- 如果是 NPC
            return Core.IsEnemyNPC(target)
        end
    end

-- 服務獲取優化 (含 cloneref 支援)
function Core.get_service(name)
    local service = game:GetService(name)
    if env_global.cloneref then
        return env_global.cloneref(service)
    end
    return service
end

-- 常用的服務
Core.Players = Core.get_service("Players")
Core.RunService = Core.get_service("RunService")
Core.UserInputService = Core.get_service("UserInputService")
Core.HttpService = Core.get_service("HttpService")
Core.StarterGui = Core.get_service("StarterGui")
Core.TweenService = Core.get_service("TweenService")
Core.LocalPlayer = Core.Players.LocalPlayer
Core.Camera = workspace.CurrentCamera

-- [[ UI 輔助工具 ]]
function Core.AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 6)
    corner.Parent = parent
    return corner
end

function Core.AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(60, 60, 65)
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function Core.AddGradient(parent, colors)
    local success, gradient = pcall(function()
        local g = Instance.new("UIGradient")
        local sequence
        
        if typeof(colors) == "ColorSequence" then
            sequence = colors
        elseif typeof(colors) == "Color3" then
            sequence = ColorSequence.new(colors)
        elseif typeof(colors) == "table" then
            if #colors >= 2 then
                -- 檢查是否已經是 Keypoints
                if typeof(colors[1]) == "ColorSequenceKeypoint" then
                    sequence = ColorSequence.new(colors)
                else
                    -- 轉換 Color3 table 為 Keypoints
                    local kps = {}
                    for i, c in ipairs(colors) do
                        table.insert(kps, ColorSequenceKeypoint.new((i-1)/(#colors-1), typeof(c) == "Color3" and c or Color3.new(1,1,1)))
                    end
                    sequence = ColorSequence.new(kps)
                end
            elseif #colors == 1 then
                sequence = ColorSequence.new(typeof(colors[1]) == "Color3" and colors[1] or Color3.new(1,1,1))
            else
                sequence = ColorSequence.new(Color3.new(1,1,1))
            end
        else
            sequence = ColorSequence.new(Color3.new(1,1,1))
        end
        
        g.Color = sequence
        g.Rotation = 90
        g.Parent = parent
        return g
    end)
    return success and gradient or nil
end

-- [[ 水印系統 ]]
function Core.CreateWatermark()
    local gui = Core.gethui()
    if not gui then return end

    local watermark = Instance.new("Frame")
    local text = Instance.new("TextLabel")

    watermark.Name = "HalolWatermark"
    watermark.Size = UDim2.new(0, 200, 0, 25)
    watermark.Position = UDim2.new(0, 10, 0, 10)
    watermark.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    watermark.BorderSizePixel = 0
    watermark.Parent = gui
    Core.AddCorner(watermark)
    Core.AddStroke(watermark)

    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "Halol GUN-HUB | FPS: 0 | Ping: 0ms"
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextSize = 12
    text.Font = Enum.Font.Code
    text.Parent = watermark

    Core.RunService.RenderStepped:Connect(function(dt)
        local fps = math.floor(1/dt)
        local ping = 0
        pcall(function() ping = math.floor(Core.LocalPlayer:GetNetworkPing() * 1000) end)
        
        local weaponText = env_global.CurrentWeaponName or "None"
        text.Text = string.format("Halol GUN-HUB | FPS: %d | Ping: %dms | 武器: %s", fps, ping, weaponText)
        
        -- 動態調整寬度
        local textBounds = text.TextBounds.X
        watermark.Size = UDim2.new(0, textBounds + 20, 0, 25)
    end)
end

-- 安全執行包裹 (含自動通知)
    function Core.Notify(title, text, duration)
        local gui = Core.gethui()
        if not gui then return end

        local notifyFrame = Instance.new("Frame")
        local titleLabel = Instance.new("TextLabel")
        local textLabel = Instance.new("TextLabel")

        notifyFrame.Name = "HalolNotify"
        notifyFrame.Size = UDim2.new(0, 250, 0, 60)
        notifyFrame.Position = UDim2.new(1, 10, 1, -70)
        notifyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        notifyFrame.BorderSizePixel = 0
        notifyFrame.Parent = gui
        Core.AddCorner(notifyFrame)
        Core.AddStroke(notifyFrame, Color3.fromRGB(0, 150, 255), 2)

        titleLabel.Size = UDim2.new(1, -20, 0, 25)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notifyFrame

        textLabel.Size = UDim2.new(1, -20, 0, 25)
        textLabel.Position = UDim2.new(0, 10, 0, 30)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = notifyFrame

        -- 動畫效果
        local TweenService = Core.TweenService
        TweenService:Create(notifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -70)}):Play()
        
        task.delay(duration or 3, function()
            TweenService:Create(notifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -70)}):Play()
            task.wait(0.5)
            notifyFrame:Destroy()
        end)
    end

    -- 安全執行包裹 (含自動通知)
function Core.SafeExecute(name, func, ...)
    if type(func) ~= "function" then
        warn("[Halol Error] Attempted to execute non-function: " .. tostring(name))
        return false, "Not a function"
    end
    local success, result = pcall(func, ...)
    if not success then
        local errMsg = tostring(result)
        warn("[Halol Error] " .. name .. ": " .. errMsg)
        -- 自動彈出 GUI 通知告知使用者
        pcall(function()
            Core.Notify("系統錯誤", name .. " 模組執行失敗，請檢查控制台 (F9)", 5)
        end)
    end
    return success, result
end

-- [[ 配置管理系統優化 ]]
local ConfigFolder = "HalolHub/configs"
local ConfigCache = {}
Core.CurrentConfig = {}

function Core.SaveConfig(name, data)
    pcall(function()
        local json = Core.HttpService:JSONEncode(data or Core.CurrentConfig)
        
        -- Dirty check: 僅在資料變動時寫入
        if ConfigCache[name or "default"] == json then return end
        
        if not Core.is_folder("HalolHub") then Core.make_folder("HalolHub") end
        if not Core.is_folder(ConfigFolder) then Core.make_folder(ConfigFolder) end
        
        Core.write_file(ConfigFolder .. "/" .. (name or "default") .. ".json", json)
        ConfigCache[name or "default"] = json
    end)
end

function Core.LoadConfig(name)
    local path = ConfigFolder .. "/" .. (name or "default") .. ".json"
    if Core.is_file(path) then
        local ok, data = pcall(function()
            local content = Core.read_file(path)
            ConfigCache[name or "default"] = content
            return Core.HttpService:JSONDecode(content)
        end)
        if ok then 
            Core.CurrentConfig = data
            return data 
        end
    end
    return nil
end

function Core.ListConfigs()
    if Core.is_folder(ConfigFolder) then
        local files = Core.list_files(ConfigFolder)
        local configs = {}
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(configs, name) end
        end
        return configs
    end
    return {}
end

-- [[ 功能註冊系統 (為 UI 做準備) ]]
Core.Features = {}
Core.Categories = {"All", "Favorites", "Rage", "Combat", "Visuals", "World", "Misc", "Protection", "Config"}
Core.CategoryIcons = {
    All = "🏠",
    Favorites = "⭐",
    Rage = "🔥",
    Combat = "🎯",
    Visuals = "👁️",
    World = "🌍",
    Misc = "⚙️",
    Protection = "🛡️",
    Config = "💾"
}

function Core.RegisterFeature(id, info)
    Core.Features[id] = {
        Name = info.Name or id,
        Description = info.Description or "",
        Category = info.Category or "Misc",
        Callback = info.Callback,
        Enabled = false,
        Favorite = false
    }
    -- 如果 GUI 已經存在，則更新 GUI
    if Core.UI and Core.UI.AddFeature then
        Core.UI.AddFeature(id, Core.Features[id])
    end
    print("[Halol] 功能已註冊: " .. id)
end

function Core.ToggleFeature(id, state)
    local feature = Core.Features[id]
    if feature then
        feature.Enabled = (state ~= nil) and state or (not feature.Enabled)
        if feature.Callback then
            Core.SafeExecute("Feature:" .. id, feature.Callback, feature.Enabled)
        end
        return feature.Enabled
    end
    return false
end

-- [[ GUI 核心系統 ]]
    function Core.CreateGUI()
        if Core.MainGui then Core.MainGui:Destroy() end
        Core.CreateWatermark() -- 啟動水印

        local targetParent = Core.gethui()
        if not targetParent then
            warn("[Halol Error] 找不到可用的 GUI 容器 (PlayerGui/CoreGui)")
            return
        end

        local TweenService = Core.TweenService
        local UserInputService = Core.UserInputService
        local ScreenGui = Instance.new("ScreenGui")
        local MainFrame = Instance.new("Frame")
        local Title = Instance.new("TextLabel")
        local MinButton = Instance.new("TextButton")
        local CloseButton = Instance.new("TextButton")
        local TabContainer = Instance.new("Frame")
        local FeatureList = Instance.new("ScrollingFrame")
        local UIListLayout = Instance.new("UIListLayout")
        local SearchBar = Instance.new("Frame")
        local SearchInput = Instance.new("TextBox")

        ScreenGui.Name = "HalolMainGui"
        ScreenGui.Parent = targetParent
        ScreenGui.ResetOnSpawn = false
        ScreenGui.DisplayOrder = 9999 -- 提高層級
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- 使用 Global ZIndex

    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 420, 0, 320)
    MainFrame.Active = true
    Core.AddCorner(MainFrame, UDim.new(0, 8))
    Core.AddStroke(MainFrame)

    -- 改良版拖拽系統
    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    -- 獲取版本號
    local version = "v1.2.3"
    pcall(function()
        local v = readfile("HalolHub/version.txt")
        if v then version = "v" .. v:gsub("%s+", "") end
    end)

    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "  Halol GUN-HUB " .. version
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Core.AddCorner(Title, UDim.new(0, 8))

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)

    -- 最小化功能
    local minimized = false
    MinButton.Name = "MinButton"
    MinButton.Parent = Title
    MinButton.Size = UDim2.new(0, 30, 0, 30)
    MinButton.Position = UDim2.new(1, -65, 0, 2)
    MinButton.BackgroundTransparency = 1
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.new(1, 1, 1)
    MinButton.TextSize = 20
    MinButton.Font = Enum.Font.GothamBold

    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TabContainer.Visible = false
            FeatureList.Visible = false
            SearchBar.Visible = false
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 420, 0, 35)}):Play()
            MinButton.Text = "+"
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 420, 0, 320)}):Play()
            task.delay(0.3, function()
                TabContainer.Visible = true
                FeatureList.Visible = true
                SearchBar.Visible = true
            end)
            MinButton.Text = "-"
        end
    end)

    CloseButton.Name = "CloseButton"
    CloseButton.Parent = Title
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 2)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    CloseButton.TextSize = 20
    CloseButton.Font = Enum.Font.GothamBold

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    Core.AddGradient(Title, {
        Color3.fromRGB(0, 150, 255),
        Color3.fromRGB(0, 80, 200)
    })

    TabContainer.Name = "TabContainer"
    TabContainer.Parent = MainFrame
    TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    TabContainer.Position = UDim2.new(0, 0, 0, 35)
    TabContainer.Size = UDim2.new(0, 110, 1, -35)
    TabContainer.ScrollBarThickness = 0 -- 隱藏捲軸但允許捲動
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.BorderSizePixel = 0
    Core.AddCorner(TabContainer, UDim.new(0, 8))

    SearchBar.Name = "SearchBar"
    SearchBar.Parent = MainFrame
    SearchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    SearchBar.Position = UDim2.new(0, 115, 0, 40)
    SearchBar.Size = UDim2.new(1, -125, 0, 30)
    SearchBar.BorderSizePixel = 0
    Core.AddCorner(SearchBar)
    Core.AddStroke(SearchBar)

    SearchInput.Name = "SearchInput"
    SearchInput.Parent = SearchBar
    SearchInput.BackgroundTransparency = 1
    SearchInput.Size = UDim2.new(1, -20, 1, 0)
    SearchInput.Position = UDim2.new(0, 10, 0, 0)
    SearchInput.Font = Enum.Font.Gotham
    SearchInput.PlaceholderText = "搜尋功能... (Search)"
    SearchInput.Text = ""
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.TextSize = 12
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left

    FeatureList.Name = "FeatureList"
    FeatureList.Parent = MainFrame
    FeatureList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    FeatureList.Position = UDim2.new(0, 115, 0, 75)
    FeatureList.Size = UDim2.new(1, -125, 1, -85)
    FeatureList.ScrollBarThickness = 2
    FeatureList.CanvasSize = UDim2.new(0, 0, 0, 0)
    FeatureList.BorderSizePixel = 0
    FeatureList.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)

    UIListLayout.Parent = FeatureList
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    local currentCategory = "All"
    local searchText = ""

    -- 分類按鈕與過濾邏輯
    local function RefreshFeatures()
        for _, child in ipairs(FeatureList:GetChildren()) do
            if child:IsA("Frame") then 
                local featCat = child:GetAttribute("Category")
                local featName = child:GetAttribute("DisplayName") or child.Name
                local isFavorite = child:GetAttribute("IsFavorite") or false
                
                local matchCat = (currentCategory == "All" or featCat == currentCategory or (currentCategory == "Favorites" and isFavorite))
                local matchSearch = (searchText == "" or string.find(string.lower(featName), string.lower(searchText)) or string.find(string.lower(child.Name), string.lower(searchText)))
                
                child.Visible = matchCat and matchSearch
            end
        end
    end

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        searchText = SearchInput.Text
        RefreshFeatures()
    end)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = TabContainer
    tabLayout.Padding = UDim.new(0, 2)
    
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 5)
    end)

    for _, cat in ipairs(Core.Categories) do
        local btn = Instance.new("TextButton")
        local icon = Core.CategoryIcons[cat] or ""
        
        btn.Name = cat .. "Tab"
        btn.Parent = TabContainer
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.Font = Enum.Font.Gotham
        btn.Text = " " .. icon .. " " .. cat
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Core.AddCorner(btn)
        
        btn.MouseEnter:Connect(function()
            if currentCategory ~= cat then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 65)}):Play()
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if currentCategory ~= cat then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if currentCategory == cat then return end
            currentCategory = cat
            
            -- 分頁動畫
    FeatureList.CanvasPosition = Vector2.new(0, 0)
    FeatureList.ScrollBarImageTransparency = 1
    TweenService:Create(FeatureList, TweenInfo.new(0.3), {ScrollBarImageTransparency = 0}):Play()
    
    for _, otherBtn in ipairs(TabContainer:GetChildren()) do
                if otherBtn:IsA("TextButton") then
                    TweenService:Create(otherBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                end
            end
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 150, 255), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            RefreshFeatures()
        end)
        
        -- 預設選中 All
        if cat == "All" then
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    -- 自動更新 CanvasSize
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentSize = UIListLayout.AbsoluteContentSize.Y + 10
        FeatureList.CanvasSize = UDim2.new(0, 0, 0, contentSize)
    end)

    -- 新增功能按鈕的函數
    Core.UI = {}
    
    function Core.UI.AddFeature(id, info)
        local frame = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local toggle = Instance.new("TextButton")
        local favorite = Instance.new("TextButton")
        local toggleCircle = Instance.new("Frame")

        frame.Name = id
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 35)
        frame.BorderSizePixel = 0
        Core.AddCorner(frame)
        frame:SetAttribute("Category", info.Category)
        frame:SetAttribute("DisplayName", info.Name)
        frame:SetAttribute("IsFavorite", info.Favorite)

        favorite.Name = "Favorite"
        favorite.Parent = frame
        favorite.Size = UDim2.new(0, 25, 0, 25)
        favorite.Position = UDim2.new(0, 5, 0, 5)
        favorite.BackgroundTransparency = 1
        favorite.Text = info.Favorite and "⭐" or "☆"
        favorite.TextColor3 = info.Favorite and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(150, 150, 150)
        favorite.TextSize = 14
        favorite.Font = Enum.Font.GothamBold

        label.Parent = frame
        label.Size = UDim2.new(1, -90, 1, 0)
        label.Position = UDim2.new(0, 35, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = info.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        toggle.Parent = frame
        toggle.Size = UDim2.new(0, 40, 0, 20)
        toggle.Position = UDim2.new(1, -50, 0, 7)
        toggle.BackgroundColor3 = info.Enabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 65)
        toggle.Text = ""
        Core.AddCorner(toggle, UDim.new(1, 0))

        toggleCircle.Parent = toggle
        toggleCircle.Size = UDim2.new(0, 14, 0, 14)
        toggleCircle.Position = info.Enabled and UDim2.new(1, -17, 0, 3) or UDim2.new(0, 3, 0, 3)
        toggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
        Core.AddCorner(toggleCircle, UDim.new(1, 0))

        favorite.MouseButton1Click:Connect(function()
            info.Favorite = not info.Favorite
            frame:SetAttribute("IsFavorite", info.Favorite)
            favorite.Text = info.Favorite and "⭐" or "☆"
            favorite.TextColor3 = info.Favorite and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(150, 150, 150)
            if currentCategory == "Favorites" and not info.Favorite then
                frame.Visible = false
            end
        end)

        toggle.MouseButton1Click:Connect(function()
            local success, newState = pcall(function() return Core.ToggleFeature(id) end)
            if success then
                TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = newState and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 65)}):Play()
                TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = newState and UDim2.new(1, -17, 0, 3) or UDim2.new(0, 3, 0, 3)}):Play()
                
                -- 自動儲存
                Core.CurrentConfig[id] = newState
                Core.SaveConfig("default")
            end
        end)

        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    function Core.UI.AddDropdown(id, info)
        local frame = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local dropBtn = Instance.new("TextButton")
        local dropList = Instance.new("ScrollingFrame")
        local listLayout = Instance.new("UIListLayout")

        local options = info.Options or {}
        local current = info.Default or options[1]
        local isOpen = false

        frame.Name = id
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 40)
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        frame:SetAttribute("Category", info.Category)
        frame:SetAttribute("DisplayName", info.Name)

        label.Parent = frame
        label.Size = UDim2.new(0.5, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = info.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        dropBtn.Parent = frame
        dropBtn.Size = UDim2.new(0.5, -10, 0.7, 0)
        dropBtn.Position = UDim2.new(0.5, 5, 0.15, 0)
        dropBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        dropBtn.Text = current
        dropBtn.TextColor3 = Color3.fromRGB(0, 150, 255)
        dropBtn.TextSize = 10
        dropBtn.Font = Enum.Font.GothamBold

        dropList.Parent = frame
        dropList.Size = UDim2.new(0.5, -10, 0, 0)
        dropList.Position = UDim2.new(0.5, 5, 1, 0)
        dropList.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        dropList.BorderSizePixel = 0
        dropList.Visible = false
        dropList.ZIndex = 10
        dropList.ScrollBarThickness = 2

        listLayout.Parent = dropList
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        for i, opt in ipairs(options) do
            local btn = Instance.new("TextButton")
            btn.Parent = dropList
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            btn.Text = opt
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 10
            btn.Font = Enum.Font.Gotham
            btn.BorderSizePixel = 0
            
            btn.MouseButton1Click:Connect(function()
                current = opt
                dropBtn.Text = opt
                isOpen = false
                dropList.Visible = false
                dropList.Size = UDim2.new(0.5, -10, 0, 0)
                if info.Callback then info.Callback(opt) end
                
                -- 自動儲存
                Core.CurrentConfig[id] = opt
                Core.SaveConfig("default")
            end)
        end

        dropBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropList.Visible = isOpen
            if isOpen then
                dropList.Size = UDim2.new(0.5, -10, 0, math.min(#options * 25, 100))
                dropList.CanvasSize = UDim2.new(0, 0, 0, #options * 25)
            else
                dropList.Size = UDim2.new(0.5, -10, 0, 0)
            end
        end)

        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    function Core.UI.AddSlider(id, info)
        local frame = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local sliderBG = Instance.new("Frame")
        local sliderBar = Instance.new("Frame")
        local valueLabel = Instance.new("TextLabel")

        local min = info.Min or 0
        local max = info.Max or 100
        local default = info.Default or min
        local current = default

        frame.Name = id
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 45)
        frame.BorderSizePixel = 0
        frame:SetAttribute("Category", info.Category)
        frame:SetAttribute("DisplayName", info.Name)

        label.Parent = frame
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = info.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        sliderBG.Parent = frame
        sliderBG.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        sliderBG.BorderSizePixel = 0
        sliderBG.Position = UDim2.new(0, 10, 0, 30)
        sliderBG.Size = UDim2.new(1, -60, 0, 6)

        sliderBar.Parent = sliderBG
        sliderBar.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        sliderBar.BorderSizePixel = 0
        sliderBar.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)

        valueLabel.Parent = frame
        valueLabel.Size = UDim2.new(0, 40, 0, 20)
        valueLabel.Position = UDim2.new(1, -45, 0, 23)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(current)
        valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        valueLabel.TextSize = 10
        valueLabel.Font = Enum.Font.Code

        local function update(input)
            local pos = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
            sliderBar.Size = UDim2.new(pos, 0, 1, 0)
            current = math.floor(min + (max - min) * pos)
            valueLabel.Text = tostring(current)
            if info.Callback then info.Callback(current) end
            
            -- 自動儲存 (節流：僅在放開滑鼠時儲存較重，這裡先即時更新變數)
            Core.CurrentConfig[id] = current
        end

        local dragging = false
        sliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input)
            end
        end)

        Core.UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)

        Core.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                Core.SaveConfig("default") -- 放開時寫入檔案
            end
        end)

        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    function Core.UI.AddColorPicker(id, info)
        local frame = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local colorDisplay = Instance.new("TextButton")
        
        local default = info.Default or Color3.new(1, 1, 1)
        local current = default

        frame.Name = id
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 35)
        frame.BorderSizePixel = 0
        Core.AddCorner(frame)
        frame:SetAttribute("Category", info.Category)
        frame:SetAttribute("DisplayName", info.Name)

        label.Parent = frame
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = info.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        colorDisplay.Parent = frame
        colorDisplay.Size = UDim2.new(0, 40, 0, 20)
        colorDisplay.Position = UDim2.new(1, -50, 0, 7)
        colorDisplay.BackgroundColor3 = current
        colorDisplay.Text = ""
        Core.AddCorner(colorDisplay)
        Core.AddStroke(colorDisplay, Color3.new(1, 1, 1), 1)

        colorDisplay.MouseButton1Click:Connect(function()
            -- 簡單的顏色切換 (為了演示，實際應使用更完整的顏色選擇器)
            -- 這裡循環切換幾種顏色，或彈出輸入框
            local colors = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(255, 0, 255),
                Color3.fromRGB(0, 255, 255)
            }
            local index = 1
            for i, c in ipairs(colors) do
                if c == current then index = i break end
            end
            index = (index % #colors) + 1
            current = colors[index]
            colorDisplay.BackgroundColor3 = current
            
            if info.Callback then info.Callback(current) end
            
            -- 自動儲存
            Core.CurrentConfig[id] = {r = current.R, g = current.G, b = current.B}
            Core.SaveConfig("default")
        end)

        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    -- 初始化現有功能
    local savedConfig = Core.LoadConfig("default") or {}
    
    local sortedFeatures = {}
    for id, info in pairs(Core.Features) do
        table.insert(sortedFeatures, {id = id, info = info})
    end
    table.sort(sortedFeatures, function(a, b) return (a.info.Name or a.id) < (b.info.Name or b.id) end)

    for _, feat in ipairs(sortedFeatures) do
        Core.UI.AddFeature(feat.id, feat.info)
    end
    
    -- 強制刷新一次顯示
    task.delay(0.5, function() RefreshFeatures() end)
    
    -- 自動開啟選單 (防止隱藏)
    MainFrame.Visible = true
    ScreenGui.Enabled = true
    MainFrame.ZIndex = 5 -- 確保 MainFrame 有足夠高的 ZIndex

    -- [[ 滑鼠解鎖邏輯 ]]
    local function ToggleMouse(visible)
        Core.UserInputService.MouseIconEnabled = visible
        if visible then
            -- 解鎖滑鼠位置
            Core.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        else
            -- 回歸遊戲控制
            Core.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end

    -- 初始化時解鎖
    ToggleMouse(true)

    -- 監聽可見性變化
    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        ToggleMouse(MainFrame.Visible)
    end)

    -- [[ 快捷鍵監聽 (INS) ]]
    Core.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            MainFrame.Visible = not MainFrame.Visible
            -- 播放切換音效或通知 (可選)
            print("[Halol] GUI 狀態已切換: " .. (MainFrame.Visible and "顯示" or "隱藏"))
        end
    end)

    Core.MainGui = ScreenGui
    print("[Halol] GUI 已創建並強制顯示")
end

return Core

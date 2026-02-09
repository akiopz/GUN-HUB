---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
-- Halol Core Module
-- 放置於: src/core.lua

local Core = {}

local getgenv = (getgenv or function() return _G end)
---@class GlobalEnv
local env_global = getgenv() --[[@as GlobalEnv]]

-- [[ 基礎環境定義 ]]
Core.load_func = (env_global.loadstring or env_global.load or loadstring or load)
Core.hookmetamethod = env_global.hookmetamethod or (getgenv and getgenv().hookmetamethod)
Core.newcclosure = env_global.newcclosure or (getgenv and getgenv().newcclosure) or function(f) return f end
Core.checkcaller = env_global.checkcaller or (getgenv and getgenv().checkcaller) or function() return false end
Core.getnamecallmethod = env_global.getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
Core.hookfunction = env_global.hookfunction or (getgenv and getgenv().hookfunction)
Core.Drawing = env_global.Drawing or (getgenv and getgenv().Drawing)
Core.gethui = function()
    -- 針對 Solara 等執行器的優化：優先嘗試 PlayerGui
    local lp = game:GetService("Players").LocalPlayer
    local playerGui = lp and lp:FindFirstChild("PlayerGui")
    
    if playerGui then
        print("[Halol] 使用 PlayerGui 作為 GUI 容器 (對 Solara 更穩定)")
        return playerGui
    end

    local success, res = pcall(function() return env_global.gethui and env_global.gethui() end)
    if success and res then return res end
    success, res = pcall(function() return game:GetService("CoreGui") end)
    if success and res then return res end
    
    return nil
end
Core.identifyexecutor = env_global.identifyexecutor or env_global.getexecutorname or function() return "Unknown" end
Core.read_file = env_global.readfile or function(...) return nil end
Core.write_file = env_global.writefile or function(...) return false end
Core.is_file = env_global.isfile or function(...) return false end
Core.is_folder = env_global.isfolder or function(...) return false end
Core.make_folder = env_global.makefolder or function(...) return false end
Core.list_files = env_global.listfiles or function(...) return {} end

-- 跨執行器 API 兼容層
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
Core.LocalPlayer = Core.Players.LocalPlayer
Core.Camera = workspace.CurrentCamera

-- 通知函數
function Core.Notify(title, text, duration)
    pcall(function()
        Core.StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration or 5
        })
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
local ConfigFolder = "射擊類/configs"
local ConfigCache = {}

function Core.SaveConfig(name, data)
    pcall(function()
        local json = Core.HttpService:JSONEncode(data)
        
        -- Dirty check: 僅在資料變動時寫入
        if ConfigCache[name] == json then return end
        
        if not Core.is_folder("射擊類") then Core.make_folder("射擊類") end
        if not Core.is_folder(ConfigFolder) then Core.make_folder(ConfigFolder) end
        
        Core.write_file(ConfigFolder .. "/" .. name .. ".json", json)
        ConfigCache[name] = json
    end)
end

function Core.LoadConfig(name)
    local path = ConfigFolder .. "/" .. name .. ".json"
    if Core.is_file(path) then
        local ok, data = pcall(function()
            local content = Core.read_file(path)
            ConfigCache[name] = content
            return Core.HttpService:JSONDecode(content)
        end)
        if ok then return data end
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
Core.Categories = {"Rage", "Combat", "Visuals", "Misc", "Protection"}

function Core.RegisterFeature(id, info)
    Core.Features[id] = {
        Name = info.Name or id,
        Description = info.Description or "",
        Category = info.Category or "Misc",
        Callback = info.Callback,
        Enabled = false
    }
    -- 如果 GUI 已經存在，則更新 GUI (這部分待會實現)
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

    local targetParent = Core.gethui()
    if not targetParent then
        warn("[Halol Error] 找不到可用的 GUI 容器 (PlayerGui/CoreGui)")
        return
    end

    local ScreenGui = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local TabContainer = Instance.new("Frame")
    local FeatureList = Instance.new("ScrollingFrame")
    local UIListLayout = Instance.new("UIListLayout")

    ScreenGui.Name = "HalolMainGui"
    ScreenGui.Parent = targetParent
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Active = true
    MainFrame.Draggable = true

    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "  Halol GUN-HUB v1.0.3"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    TabContainer.Name = "TabContainer"
    TabContainer.Parent = MainFrame
    TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    TabContainer.Position = UDim2.new(0, 0, 0, 30)
    TabContainer.Size = UDim2.new(0, 100, 1, -30)

    FeatureList.Name = "FeatureList"
    FeatureList.Parent = MainFrame
    FeatureList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    FeatureList.Position = UDim2.new(0, 105, 0, 35)
    FeatureList.Size = UDim2.new(1, -110, 1, -40)
    FeatureList.ScrollBarThickness = 2
    FeatureList.CanvasSize = UDim2.new(0, 0, 0, 0)

    UIListLayout.Parent = FeatureList
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    -- 分類按鈕與過濾邏輯
    local function RefreshFeatures(category)
        if not FeatureList then return end
        for _, child in ipairs(FeatureList:GetChildren()) do
            if child:IsA("Frame") then 
                local featCat = child:GetAttribute("Category")
                child.Visible = (category == "All" or featCat == category) 
            end
        end
    end

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = TabContainer
    tabLayout.Padding = UDim.new(0, 2)

    for _, cat in ipairs({"All", "Rage", "Combat", "Visuals", "Misc", "Protection"}) do
        local btn = Instance.new("TextButton")
        btn.Name = cat .. "Tab"
        btn.Parent = TabContainer
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Font = Enum.Font.Gotham
        btn.Text = cat
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        
        btn.MouseButton1Click:Connect(function()
            RefreshFeatures(cat)
        end)
    end

    -- 自動更新 CanvasSize
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- 新增功能按鈕的函數
    Core.UI = {}
    
    function Core.UI.AddFeature(id, info)
        local frame = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local toggle = Instance.new("TextButton")

        frame.Name = id
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 35)
        frame.BorderSizePixel = 0
        frame:SetAttribute("Category", info.Category)

        label.Parent = frame
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = info.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        toggle.Parent = frame
        toggle.Size = UDim2.new(0, 50, 0, 25)
        toggle.Position = UDim2.new(1, -55, 0, 5)
        toggle.BackgroundColor3 = info.Enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
        toggle.Text = info.Enabled and "ON" or "OFF"
        toggle.TextColor3 = Color3.new(1, 1, 1)
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 10

        toggle.MouseButton1Click:Connect(function()
            local success, newState = pcall(function() return Core.ToggleFeature(id) end)
            if success then
                toggle.BackgroundColor3 = newState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
                toggle.Text = newState and "ON" or "OFF"
            else
                warn("[Halol UI Error] Failed to toggle feature: " .. tostring(id))
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

        frame.Name = id .. "Slider"
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 45)
        frame.BorderSizePixel = 0
        frame:SetAttribute("Category", info.Category)

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
            end
        end)

        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    function Core.UI.AddKeybind(id, info)
        local frame = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local bindBtn = Instance.new("TextButton")

        frame.Name = id .. "Bind"
        frame.Parent = FeatureList
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.Size = UDim2.new(1, -5, 0, 35)
        frame.BorderSizePixel = 0
        frame:SetAttribute("Category", info.Category)

        label.Parent = frame
        label.Size = UDim2.new(1, -80, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = info.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        bindBtn.Parent = frame
        bindBtn.Size = UDim2.new(0, 70, 0, 25)
        bindBtn.Position = UDim2.new(1, -75, 0, 5)
        bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        bindBtn.Text = info.Default and info.Default.Name or "NONE"
        bindBtn.TextColor3 = Color3.new(1, 1, 1)
        bindBtn.Font = Enum.Font.GothamBold
        bindBtn.TextSize = 10

        local listening = false
        bindBtn.MouseButton1Click:Connect(function()
            listening = true
            bindBtn.Text = "..."
        end)

        Core.UserInputService.InputBegan:Connect(function(input)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                bindBtn.Text = input.KeyCode.Name
                if info.Callback then info.Callback(input.KeyCode) end
            end
        end)

        FeatureList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    -- 初始化現有功能
    for id, info in pairs(Core.Features) do
        Core.UI.AddFeature(id, info)
    end

    -- 自動開啟選單 (防止隱藏)
    MainFrame.Visible = true
    ScreenGui.Enabled = true

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

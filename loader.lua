---@diagnostic disable: undefined-global, undefined-field, deprecated, inject-field
--[[
    Halol Shooting Suite - Loader (Pure English Version)
    Version: 1.1.2
    Note: Removed all non-ASCII characters to prevent encoding errors in some executors.
]]

local entryFile = "init.lua"

local function loadScript()
    -- 1. Try to find the local file without using Chinese characters in the string
    -- We use a pattern to match folders if possible, or just look for the file
    local paths = {
        entryFile,
        "HalolHub/" .. entryFile,
        "workspace/" .. entryFile
    }

    -- Scan for any path that might contain our entry file
    if listfiles then
        local success, files = pcall(listfiles, "")
        if success then
            for _, file in ipairs(files) do
                -- Check if the file is init.lua (case insensitive)
                if file:lower():find("init.lua") then
                    table.insert(paths, 1, file)
                end
            end
        end
    end

    for _, localPath in ipairs(paths) do
        if isfile and isfile(localPath) then
            local success, content = pcall(readfile, localPath)
            if success and content and #content > 0 then
                print("[Halol] Found local script: " .. tostring(localPath))
                local func, err = loadstring(content)
                if func then
                    func()
                    return
                else
                    warn("[Halol] Load Error: " .. tostring(err))
                end
            end
        end
    end

    -- 2. Fallback: Load from GitHub (The most stable way, no special characters)
    print("[Halol] Local file not found, loading from GitHub...")
    local success, content = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/akiopz/GUN-HUB/main/init.lua")
    
    if success and content then
        local func, err = loadstring(content)
        if func then
            func()
        else
            warn("[Halol] GitHub Load Error: " .. tostring(err))
        end
    else
        warn("[Halol Error] Failed to load from GitHub. Check connection.")
    end
end

loadScript()

-- [[ VanilllaHub / VanilllaHub.Lt2 ]]
local function fetch(url)
    local ok, res = pcall(game.HttpGet, game, url)
    return ok and res or nil
end

-- List of scripts to load from this repo
local scripts = {
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla1.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla2.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla3.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla4.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla5.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla6.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla7.lua"
}

print("VanilllaHub: Loading LT2 Modules...")

for i, url in ipairs(scripts) do
    local content = fetch(url)
    if content then
        local func, err = loadstring(content)
        if func then
            task.spawn(func)
        else
            warn("VanilllaHub: Failed to compile Module " .. i .. ": " .. tostring(err))
        end
    else
        warn("VanilllaHub: Failed to fetch Module " .. i)
    end
    task.wait(0.2)
end

print("VanilllaHub: All modules loaded!")

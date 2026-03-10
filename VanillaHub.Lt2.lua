-- [[ VanilllaHub / VanilllaHub.Lt2 ]]
local function fetch(url)
    local ok, res = pcall(game.HttpGet, game, url)
    return ok and res or nil
end

local scripts = {
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla1.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla2.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla3.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla4.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla5.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla6.lua",
    "https://raw.githubusercontent.com/VanilllaHub/VanillaHub.Lt2/main/Vanilla7.lua",
}

print("VanilllaHub: Loading LT2 Modules...")

for i, url in ipairs(scripts) do
    if i > 1 then
        local timeout = 0
        while not _G.VH and timeout < 10 do
            task.wait(0.05)
            timeout = timeout + 0.05
        end
        if not _G.VH then
            warn("VanilllaHub: Timed out waiting for _G.VH before Module " .. i)
            break
        end
    end

    local content = fetch(url)
    if content then
        local func, err = loadstring(content)
        if func then
            func()
        else
            warn("VanilllaHub: Failed to compile Module " .. i .. ": " .. tostring(err))
        end
    else
        warn("VanilllaHub: Failed to fetch Module " .. i)
    end
end

print("VanilllaHub: All modules loaded!")

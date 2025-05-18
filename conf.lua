-- conf.lua
function love.conf(t)
    t.window.title = "3CG - Mythic Clash"
    t.window.width = 1280     -- Increase this for a wider board
    t.window.height = 720     -- Increase this for more vertical space
    t.window.resizable = false
    t.console = true          -- Optional: shows the console on Windows for debugging
end
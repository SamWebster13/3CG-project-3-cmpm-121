-- src/Card.lua
local Card = {}
Card.__index = Card

function Card:new(id, cost, power)
    local self = setmetatable({}, Card)

    self.id = id or 0
    self.cost = cost or 1
    self.power = power or 1
    self.color = {0.85, 0.85, 0.85}  -- default gray

    self.width = 60
    self.height = 90
    self.x = 0
    self.y = 0
    self.faceUp = true

    return self
end

function Card:draw()
    -- Card background
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Card border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- Mana Cost (top-left, red)
    love.graphics.setColor(1, 0, 0)
    love.graphics.print(tostring(self.cost), self.x + 4, self.y + 4)

    -- Power (bottom-right, black)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring(self.power), self.x + self.width - 12, self.y + self.height - 16)

end

function Card:contains(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

return Card

local Card = {}
Card.__index = Card

--------------------------------------------------------------------------------
-- CONSTRUCTOR
-- Constructor: Create a new card initalized with info from an .csv file
--------------------------------------------------------------------------------
function Card.new(name, cost, power, description, x, y)
    local self = setmetatable({}, Card)
    self.name = name
    self.cost = tonumber(cost)
    self.power = tonumber(power)
    self.description = description
    self.x = x or 0
    self.y = y or 0
    return self
end

--------------------------------------------------------------------------------
-- DRAW
-- Draw function: Draw cards
--------------------------------------------------------------------------------
function Card:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 60, 90)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, 60, 90)
    love.graphics.print(self.name, self.x + 5, self.y + 10)
    love.graphics.print("Cost: " .. self.cost, self.x + 5, self.y + 30)
    love.graphics.print("Power: " .. self.power, self.x + 5, self.y + 50)
end

--------------------------------------------------------------------------------
-- HELPER
-- Sizing: helps with sizing and hitbox behaviors
--------------------------------------------------------------------------------
function Card:contains(x, y)
    return x >= self.x and x <= self.x + 60 and y >= self.y and y <= self.y + 90
end

return Card

local Card = {}
Card.__index = Card

function Card.new(data)
    local self = setmetatable({}, Card)
    self.name = data.name or "Unknown"
    self.cost = tonumber(data.cost) or 1
    self.power = tonumber(data.power) or 1
    self.text = data.text or ""
    self.x = 0
    self.y = 0
    self.width = 60    -- ← Add this
    self.height = 90   -- ← And this
    return self
end

function Card:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 60, 90)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, 60, 90)

    love.graphics.print(self.name, self.x + 5, self.y + 5)
    love.graphics.print("Cost: " .. self.cost, self.x + 5, self.y + 25)
    love.graphics.print("Pow: " .. self.power, self.x + 5, self.y + 45)
end

function Card:contains(mx, my)
    return mx >= self.x and mx <= self.x + 60 and my >= self.y and my <= self.y + 90
end

return Card

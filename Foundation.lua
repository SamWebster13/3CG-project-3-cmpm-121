-- src/Foundation.lua
local Foundation = {}
Foundation.__index = Foundation

function Foundation:new(x, y)
    return setmetatable({
        x = x,
        y = y,
        cards = {}
    }, Foundation)
end

function Foundation:addCard(card)
    card.x = self.x
    card.y = self.y
    table.insert(self.cards, card)
end

function Foundation:draw()
    if #self.cards == 0 then
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("line", self.x, self.y, 60, 90)
    end

    for i, card in ipairs(self.cards) do
        card:draw()
    end
end

function Foundation:canAccept(card)
    return self.cards[#self.cards] == nil  -- allow if empty
end

function Foundation:isPointInside(x, y)
    return x >= self.x and x <= self.x + 60 and y >= self.y and y <= self.y + 90
end

return Foundation

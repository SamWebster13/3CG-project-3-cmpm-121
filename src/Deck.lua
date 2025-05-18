-- src/Deck.lua
local Card = require("src.Card")

local Deck = {}
Deck.__index = Deck

setmetatable(Deck, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

-- Filler deck constructor
function Deck.new(startX, startY)
    local self = setmetatable({cards = {}}, Deck)

    local colors = {
        {1, 0, 0}, {0, 1, 0}, {0, 0, 1},
        {1, 1, 0}, {1, 0, 1}, {0, 1, 1},
        {0.5, 0.5, 0.5}, {1, 0.5, 0}, {0.5, 0, 1}, {0, 0, 0}
    }

    for i = 1, 10 do
        local card = Card:new(i, math.random(1, 5), math.random(1, 8))
        card.x = startX or 0
        card.y = startY or 0
        table.insert(self.cards, card)
    end

    return self
end


function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = math.random(1, i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:drawAll()
    for _, card in ipairs(self.cards) do
        card:draw()
    end
end

function Deck:drawTopCard()
    return table.remove(self.cards)
end

return Deck

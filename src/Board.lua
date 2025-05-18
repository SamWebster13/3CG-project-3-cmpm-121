-- Internal class for a row of 4 card slots (like a foundation line)
local SlotRow = {}
SlotRow.__index = SlotRow

function SlotRow:new(x, y, cardWidth, cardHeight, slotCount)
    local self = setmetatable({}, SlotRow)
    self.x = x
    self.y = y
    self.cardWidth = cardWidth
    self.cardHeight = cardHeight
    self.slotCount = slotCount or 4
    self.cards = {}  -- table of 4 card positions (can be nil or contain a card)
    for i = 1, self.slotCount do
        self.cards[i] = nil
    end
    return self
end

function SlotRow:draw(highlightIndex)
    for i = 1, self.slotCount do
        local x = self.x + (i - 1) * (self.cardWidth + 20)
        local y = self.y

        if highlightIndex == i then
            love.graphics.setColor(0.4, 0.4, 0.6) -- darker shade
            love.graphics.rectangle("fill", x, y, self.cardWidth, self.cardHeight)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, y, self.cardWidth, self.cardHeight)

        local card = self.cards[i]
        if card then
            card.x = x
            card.y = y
            card:draw()
        end
    end
end

function SlotRow:placeCard(card, slotIndex)
    if self.cards[slotIndex] == nil then
        self.cards[slotIndex] = card
        card.x = self.x + (slotIndex - 1) * (self.cardWidth + 5)
        card.y = self.y
        return true
    end
    return false
end

function SlotRow:clear()
    for i = 1, self.slotCount do
        self.cards[i] = nil
    end
end

function SlotRow:getCards()
    return self.cards
end


-- Board.lua -------------------------------------------------------------------------------------------------------
local Board = {}
Board.__index = Board

function Board:new()
    local self = setmetatable({}, Board)

    -- Constants
    self.cardWidth = 60
    self.cardHeight = 90
    self.slotPadding = 25

    -- Define location slots
    self.locations = {}
    local baseX = 175
    local spacing = 350
    local startY = 150
    for i = 1, 3 do
        local x = baseX + (i - 1) * spacing
        table.insert(self.locations, {
            top = SlotRow:new(x, startY, self.cardWidth, self.cardHeight),
            bottom = SlotRow:new(x, startY + self.cardHeight + 60, self.cardWidth, self.cardHeight),
            frameX = x - 15,
            frameY = startY - 15,
            frameW = (self.cardWidth + 20) * 4 - 5 + 30,
            frameH = (self.cardHeight + 60 + self.cardHeight) + 30
        })
    end

    -- Define deck/discard positions
    self.deck = { x = 30, y = 230, w = 60, h = 90 }
    self.discardP1 = { x = 30, y = 470, w = 60, h = 90 }
    self.discardP2 = { x = 30, y = 10, w = 60, h = 90 }

    -- Player hands
    self.handP1 = self:createHandSlots(100, 440)
    self.handP2 = self:createHandSlots(100, 10)

    -- Mana bars
    self.manaBarP1 = {
        x = self.handP1[1].x,
        y = self.handP1[1].y - 25,
        w = (#self.handP1) * (self.cardWidth + self.slotPadding) - self.slotPadding,
        h = 12
    }

    self.manaBarP2 = {
        x = self.handP2[1].x,
        y = self.handP2[1].y + self.cardHeight + 13,
        w = (#self.handP2) * (self.cardWidth + self.slotPadding) - self.slotPadding,
        h = 12
    }

    self.scoreP1 = { x = 40, y = 370 }
    self.scoreP2 = { x = 40, y = 160 }

    self.submitButton = { x = 750, y = 460, w = 80, h = 40 }

    return self
end

function Board:createHandSlots(startX, y)
    local hand = {}
    for i = 1, 7 do
        table.insert(hand, {
            x = startX + (i - 1) * (self.cardWidth + self.slotPadding),
            y = y,
            w = self.cardWidth,
            h = self.cardHeight
        })
    end
    return hand
end

function Board:drawRect(r, color)
    if color then love.graphics.setColor(color) else love.graphics.setColor(1, 1, 1) end
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
end

function Board:drawTrashIcon(cx, cy)
    local w = 20
    local h = 25
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", cx - w / 2, cy - h / 2, w, h)
    love.graphics.rectangle("line", cx - w / 2 - 2, cy - h / 2 - 6, w + 4, 4)
    love.graphics.line(cx - 5, cy - h / 2 - 8, cx + 5, cy - h / 2 - 8)
    for i = -1, 1 do
        love.graphics.line(cx + i * 5, cy - h / 2 + 2, cx + i * 5, cy + h / 2 - 2)
    end
end

function Board:drawDeckIcon(cx, cy)
    local w, h = 24, 36
    local offset = 4
    love.graphics.setColor(0.8, 0.8, 0.8)
    for i = 2, 0, -1 do
        local ox = i * offset
        local oy = i * offset
        love.graphics.rectangle("line", cx - w / 2 + ox, cy - h / 2 + oy, w, h)
    end
end



function Board:draw()
    love.graphics.clear(0.2, 0.3, 0.4)

    -- Draw group rectangles first
    for _, loc in ipairs(self.locations) do
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("line", loc.frameX, loc.frameY, loc.frameW, loc.frameH)
      
    end

    -- Draw slot rows
    for _, loc in ipairs(self.locations) do
        loc.top:draw()
        loc.bottom:draw()
    end

    self:drawRect(self.deck)
    self:drawDeckIcon(self.deck.x + self.deck.w / 2, self.deck.y + self.deck.h / 2)
    self:drawRect(self.discardP1)
    self:drawTrashIcon(self.discardP1.x + self.discardP1.w / 2, self.discardP1.y + self.discardP1.h / 2)
    self:drawRect(self.discardP2)
    self:drawTrashIcon(self.discardP2.x + self.discardP2.w / 2, self.discardP2.y + self.discardP2.h / 2)

    for _, slot in ipairs(self.handP1) do self:drawRect(slot) end
    for _, slot in ipairs(self.handP2) do self:drawRect(slot) end

    love.graphics.setColor(0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", self.manaBarP1.x, self.manaBarP1.y, self.manaBarP1.w, self.manaBarP1.h)
    love.graphics.rectangle("fill", self.manaBarP2.x, self.manaBarP2.y, self.manaBarP2.w, self.manaBarP2.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.manaBarP1.x, self.manaBarP1.y, self.manaBarP1.w, self.manaBarP1.h)
    love.graphics.rectangle("line", self.manaBarP2.x, self.manaBarP2.y, self.manaBarP2.w, self.manaBarP2.h)

    love.graphics.setColor(1, 0, 0)
    love.graphics.print("0", self.scoreP2.x, self.scoreP2.y)
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("0", self.scoreP1.x, self.scoreP1.y)

    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.submitButton.x, self.submitButton.y, self.submitButton.w / 2, self.submitButton.h)
    love.graphics.rectangle("fill", self.submitButton.x + self.submitButton.w / 2, self.submitButton.y, self.submitButton.w / 2, self.submitButton.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("SUBMIT", self.submitButton.x + 16, self.submitButton.y + 12)

    love.graphics.setColor(1, 0, 0)
    love.graphics.print("PLAYER 2", 100, 100)
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("PLAYER 1", 100, 400)
end

return setmetatable({}, { __call = function(_, ...) return Board:new(...) end })

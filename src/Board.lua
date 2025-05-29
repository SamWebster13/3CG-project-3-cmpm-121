local SlotRow = require("src.slot")

-- Board.lua -------------------------------------------------------------------------------------------------------
local Board = {}
Board.__index = Board

--------------------------------------------------------------------------------------------------
-- Helper drawing functions
--------------------------------------------------------------------------------------------------

-- Draw a rectangle outline with optional color
function Board:drawRect(r, color)
    if color then 
        love.graphics.setColor(color) 
    else 
        love.graphics.setColor(1, 1, 1) 
    end
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
end

-- Draw trash can icon at (cx, cy)
function Board:drawTrashIcon(cx, cy)
    local w, h = 20, 25
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", cx - w/2, cy - h/2, w, h)
    love.graphics.rectangle("line", cx - w/2 - 2, cy - h/2 - 6, w + 4, 4)
    love.graphics.line(cx - 5, cy - h/2 - 8, cx + 5, cy - h/2 - 8)
    for i = -1, 1 do
        love.graphics.line(cx + i * 5, cy - h/2 + 2, cx + i * 5, cy + h/2 - 2)
    end
end

-- Draw deck icon (stacked rectangles) at (cx, cy)
function Board:drawDeckIcon(cx, cy)
    local w, h = 24, 36
    local offset = 4
    love.graphics.setColor(0.8, 0.8, 0.8)
    for i = 2, 0, -1 do
        local ox, oy = i * offset, i * offset
        love.graphics.rectangle("line", cx - w/2 + ox, cy - h/2 + oy, w, h)
    end
end

--------------------------------------------------------------------------------------------------
-- Create an array of hand slots starting at (startX, y)
-- Each slot tracks position, size, and assigned card (initially nil)
--------------------------------------------------------------------------------------------------
function Board:createHandSlots(startX, y)
    local hand = {}
    for i = 1, 7 do
        table.insert(hand, {
            x = startX + (i - 1) * (self.cardWidth + self.slotPadding),
            y = y,
            w = self.cardWidth,
            h = self.cardHeight,
            card = nil
        })
    end
    return hand
end

--------------------------------------------------------------------------------------------------
-- Draw an array of slots and their cards (if any)
-- slotArray: array of slot tables, each with x,y,w,h and optional .card
-- Draws a rectangle outline for each slot and calls the card's draw method if present
--------------------------------------------------------------------------------------------------
function Board:drawSlotArray(slotArray)
    for _, slot in ipairs(slotArray) do
        -- Draw rectangle outline for the slot
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", slot.x, slot.y, slot.w, slot.h)
        
        -- Draw the card inside the slot, if assigned
        if slot.card then
            slot.card:draw(slot.x, slot.y, slot.w, slot.h)
        end
    end
end
--------------------------------------------------------------------------------------------------
-- Board Constructor
--------------------------------------------------------------------------------------------------
function Board:new()
    local self = setmetatable({}, Board)

    -- Initialize scores for 3 locations
    self.scores = {}
    for i = 1, 3 do
        self.scores[i] = { p1 = 0, p2 = 0 }
    end

    -- Constants for card dimensions and spacing
    self.cardWidth = 60
    self.cardHeight = 90
    self.slotPadding = 25

    -- Define 3 locations, each with top and bottom slot rows and a frame rectangle
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

    -- Deck position and size
    self.deck = { x = 30, y = 230, w = 60, h = 90 }

    -- Discard piles as slot rows for both players
    self.discardP1 = SlotRow:new(30, 440, self.cardWidth, self.cardHeight, 1)
    self.discardP2 = SlotRow:new(30, 10, self.cardWidth, self.cardHeight, 1)

    -- Player hands as arrays of slots (each with x,y,w,h,card=nil)
    self.handP1 = self:createHandSlots(100, 440)
    self.handP2 = self:createHandSlots(100, 10)

    -- Update mana bar coords to use hand slot arrays
    local function getManaBarCoords(handSlots, offsetY)
        local firstSlot = handSlots[1]
        local x = firstSlot and firstSlot.x or 100
        local y = firstSlot and (firstSlot.y + offsetY) or 100
        local w = (#handSlots) * (self.cardWidth + self.slotPadding) - self.slotPadding
        local h = 12
        return { x = x, y = y, w = w, h = h }
    end

    self.manaBarP1 = getManaBarCoords(self.handP1, -25)
    self.manaBarP2 = getManaBarCoords(self.handP2, 105)

    -- Score display positions
    self.scoreP1 = { x = 40, y = 370 }
    self.scoreP2 = { x = 40, y = 160 }

    -- Submit button rectangle
    self.submitButton = { x = 750, y = 460, w = 80, h = 40 }

    return self
end


--------------------------------------------------------------------------------------------------
-- Draw method: draws entire board and UI elements
--------------------------------------------------------------------------------------------------
function Board:draw()
    love.graphics.clear(0.2, 0.3, 0.4)

    -- Draw location frames and centered scores ("0" for now)
    for _, loc in ipairs(self.locations) do
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("line", loc.frameX, loc.frameY, loc.frameW, loc.frameH)

        local text = "0"
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight(text)
        local centerX = loc.frameX + loc.frameW / 2 - textWidth / 2
        local centerY = loc.frameY + loc.frameH / 2 - textHeight / 2

        love.graphics.setColor(0, 1, 0)
        love.graphics.print(text, centerX, centerY)
    end

    -- Draw slot rows for each location
    for _, loc in ipairs(self.locations) do
        loc.top:draw()
        loc.bottom:draw()
    end

    -- Draw deck and discard piles
    self:drawRect(self.deck)
    self:drawDeckIcon(self.deck.x + self.deck.w / 2, self.deck.y + self.deck.h / 2)
    self.discardP1:draw()
    self.discardP2:draw()
    self:drawTrashIcon(self.discardP1.x + self.cardWidth / 2, self.discardP1.y + self.cardHeight / 2)
    self:drawTrashIcon(self.discardP2.x + self.cardWidth / 2, self.discardP2.y + self.cardHeight / 2)   

    -- Draw player hands
    self:drawSlotArray(self.handP1)
    self:drawSlotArray(self.handP2)

    -- Draw mana bars (filled rectangles + outlines)
    love.graphics.setColor(0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", self.manaBarP1.x, self.manaBarP1.y, self.manaBarP1.w, self.manaBarP1.h)
    love.graphics.rectangle("fill", self.manaBarP2.x, self.manaBarP2.y, self.manaBarP2.w, self.manaBarP2.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.manaBarP1.x, self.manaBarP1.y, self.manaBarP1.w, self.manaBarP1.h)
    love.graphics.rectangle("line", self.manaBarP2.x, self.manaBarP2.y, self.manaBarP2.w, self.manaBarP2.h)

    -- Draw scores
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("0", self.scoreP2.x, self.scoreP2.y)
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("0", self.scoreP1.x, self.scoreP1.y)

    -- Draw submit button (green split rectangle with text)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.submitButton.x, self.submitButton.y, self.submitButton.w / 2, self.submitButton.h)
    love.graphics.rectangle("fill", self.submitButton.x + self.submitButton.w / 2, self.submitButton.y, self.submitButton.w / 2, self.submitButton.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("SUBMIT", self.submitButton.x + 16, self.submitButton.y + 12)

    -- Player labels
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("PLAYER 2", 100, 100)
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("PLAYER 1", 100, 400)
end

--------------------------------------------------------------------------------------------------
-- Return a callable table to create Board instances
--------------------------------------------------------------------------------------------------
return setmetatable({}, { __call = function(_, ...) return Board:new(...) end })

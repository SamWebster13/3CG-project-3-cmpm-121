local SlotRow = {}
SlotRow.__index = SlotRow

---------------------------------------------------------------------------------------------------
-- Constructor: Create a new SlotRow
-- @param x, y          Top-left coordinates of the slot row
-- @param cardWidth     Width of each card slot
-- @param cardHeight    Height of each card slot
-- @param slotCount     Number of slots (default 4)
-- @return SlotRow instance
---------------------------------------------------------------------------------------------------
function SlotRow:new(x, y, cardWidth, cardHeight, slotCount)
    local self = setmetatable({}, SlotRow)
    self.x = x
    self.y = y
    self.cardWidth = cardWidth
    self.cardHeight = cardHeight
    self.slotCount = slotCount or 4
    self.cards = {}

    -- Initialize slots as empty (nil)
    for i = 1, self.slotCount do
        self.cards[i] = nil
    end

    return self
end

---------------------------------------------------------------------------------------------------
-- Draw the SlotRow including slots and any cards placed in them
-- @param highlightIndex Optional index of slot to highlight (e.g., for hover or selection)
---------------------------------------------------------------------------------------------------
function SlotRow:draw(highlightIndex)
    for i = 1, self.slotCount do
        local x = self.x + (i - 1) * (self.cardWidth + 20)
        local y = self.y

        -- Draw highlight background if this slot is highlighted
        if highlightIndex == i then
            love.graphics.setColor(0.4, 0.4, 0.6)
            love.graphics.rectangle("fill", x, y, self.cardWidth, self.cardHeight)
        end

        -- Draw slot border
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, y, self.cardWidth, self.cardHeight)

        -- Draw card if present in this slot
        local card = self.cards[i]
        if card then
            card.x = x
            card.y = y
            if card.draw then
                card:draw()
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Place a card into a slot if empty
-- @param card       Card object to place (assumed to have x,y properties)
-- @param slotIndex  Index of the slot to place the card into
-- @return boolean   True if card placed successfully, false if slot occupied
---------------------------------------------------------------------------------------------------
function SlotRow:placeCard(card, slotIndex)
    if self.cards[slotIndex] == nil then
        self.cards[slotIndex] = card
        card.x = self.x + (slotIndex - 1) * (self.cardWidth + 20)
        card.y = self.y
        return true
    end
    return false
end

---------------------------------------------------------------------------------------------------
-- Clear all cards from the slot row
---------------------------------------------------------------------------------------------------
function SlotRow:clear()
    for i = 1, self.slotCount do
        self.cards[i] = nil
    end
end

---------------------------------------------------------------------------------------------------
-- Get all cards currently in the slot row
-- @return table Array of cards (nil if empty slot)
---------------------------------------------------------------------------------------------------
function SlotRow:getCards()
    return self.cards
end

---------------------------------------------------------------------------------------------------
-- Determine which slot (if any) is under given coordinates
-- @param x, y Screen coordinates to check
-- @return table or nil:
--    {
--      index = slotIndex,
--      valid = true if slot is empty, false if occupied,
--      hasCard = true if slot occupied, false if empty
--    }
--  or nil if coordinates are outside all slots
---------------------------------------------------------------------------------------------------
function SlotRow:getSlotAt(x, y)
    for i = 1, self.slotCount do
        local slotX = self.x + (i - 1) * (self.cardWidth + 20)
        local slotY = self.y
        local w = self.cardWidth
        local h = self.cardHeight

        if x >= slotX and x <= slotX + w and y >= slotY and y <= slotY + h then
            local hasCard = self.cards[i] ~= nil
            return {
                index = i,
                valid = not hasCard,
                hasCard = hasCard
            }
        end
    end
    return nil
end

return SlotRow

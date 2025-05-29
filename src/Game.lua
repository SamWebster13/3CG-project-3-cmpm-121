-- src/Game.lua
local Deck = require("src.Deck")
local Board = require("src.Board")

local Game = {}
Game.__index = Game

--------------------------------------------------------------------------------------------------
-- Constructor: Creates a new game instance
--------------------------------------------------------------------------------------------------
function Game:new()
    local self = setmetatable({}, Game)

    -- Create the game board
    self.board = Board()

    -- Load and shuffle the deck from the CSV
    self.deck = Deck.new("assets/cards.csv")
    self.deck:shuffle()

    -- Card interaction state
    self.hand = {}        -- Player's hand of cards
    self.heldCard = nil   -- Currently dragged card
    self.dragOffsetX = 0
    self.dragOffsetY = 0

    -- Turn and mana system
    self.turn = 1
    self.mana = 1
    self.maxMana = 25

    -- Slot interaction tracking (hovered slot info)
    self.hoveredSlot = { location = nil, index = nil }

    -- Player and enemy setup
    self.player = {
        hand = {},
        mana = 3,
        score = 0
    }

    self.enemy = {
        hand = {},
        mana = 3,
        score = 0
    }

    -- Draw initial hands for both player and enemy
    for i = 1, 3 do
        table.insert(self.player.hand, self.deck:drawTopCard())
        table.insert(self.enemy.hand, self.deck:drawTopCard())
    end

    return self
end

--------------------------------------------------------------------------------------------------
-- Update: Handles card dragging and hovered slot detection
-- dt: delta time since last update (unused here, but typical in Love2D update)
--------------------------------------------------------------------------------------------------
function Game:update(dt)
    if self.heldCard then
        local mx, my = love.mouse.getPosition()
        self.heldCard.x = mx - self.dragOffsetX
        self.heldCard.y = my - self.dragOffsetY

        self.hoveredSlot = { location = nil, index = nil }

        for _, loc in ipairs(self.board.locations) do
            local row = loc.bottom:getCards()
            for i = 1, #row do
                local sx = loc.bottom.x + (i - 1) * (self.heldCard.width + 5)
                local sy = loc.bottom.y
                if not row[i] and mx >= sx and mx <= sx + self.heldCard.width and my >= sy and my <= sy + self.heldCard.height then
                    self.hoveredSlot = { location = loc.bottom, index = i }
                    return
                end
            end
        end
    else
        self.hoveredSlot = { location = nil, index = nil }
    end
end

--------------------------------------------------------------------------------------------------
-- Draw: Renders the board, cards in hand, held card, and mana bar
--------------------------------------------------------------------------------------------------
function Game:draw()
    self.board:draw(self.hoveredSlot)

    -- Draw cards in player's hand
    for _, card in ipairs(self.hand) do
        card:draw()
    end

    -- Draw held card on top if dragging
    if self.heldCard then
        self.heldCard:draw()
    end

    -- Draw mana bar fill (currently only Player 1)
    local manaRatio = math.min(self.mana / self.maxMana, 1)
    local bar = self.board.manaBarP1
    local fillW = bar.w * manaRatio

    love.graphics.setColor(0, 0.8, 1)
    love.graphics.rectangle("fill", bar.x, bar.y, fillW, bar.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", bar.x, bar.y, bar.w, bar.h)
end

--------------------------------------------------------------------------------------------------
-- Mouse Pressed Handler: Handles clicking on buttons, deck, board slots, and hand cards
-- x, y: mouse position
-- button: mouse button (1 = left click)
--------------------------------------------------------------------------------------------------
function Game:mousepressed(x, y, button)
    if button ~= 1 then return end

    -- Check if submit button (end turn) clicked
    local btn = self.board.submitButton
    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
        self.turn = self.turn + 1
        self.mana = math.min(self.turn, self.maxMana)
        return
    end

    -- Check if deck clicked to draw a card
    local deck = self.board.deck
    if x >= deck.x and x <= deck.x + deck.w and y >= deck.y and y <= deck.y + deck.h then
        local handRow = self.board.handP1  -- SlotRow object
        local slotIndex = nil

        -- Find first empty slot in hand
       for i = 1, handRow.slotCount do
            if not handRow.cards[i] then
                slotIndex = i
                break
            end
        end

        if slotIndex then
            local card = self.deck:drawTopCard()
            if card then
                handRow:placeCard(card, slotIndex) -- ✅ Place on the correct Slot
                table.insert(self.hand, card)      -- Optional: Add to logical hand tracking
            end
        end

        return -- Prevent further processing
    end

    -- Try to pick up a card from any bottom slot on the board
    for _, loc in ipairs(self.board.locations) do
        local slotInfo = loc.bottom:getSlotAt(x, y)
        if slotInfo and slotInfo.hasCard then
            self.heldCard = loc.bottom.cards[slotInfo.index]
            loc.bottom.cards[slotInfo.index] = nil -- Remove card for dragging

            -- Store drag offset for smooth dragging
            self.dragOffsetX = x - self.heldCard.x
            self.dragOffsetY = y - self.heldCard.y
            return -- Exit after picking up card
        end
    end

    -- If no card picked up yet, check if clicked on a card in hand
    for i, card in ipairs(self.hand) do
        if card:contains(x, y) then
            self.heldCard = card
            self.dragOffsetX = x - card.x
            self.dragOffsetY = y - card.y
            table.remove(self.hand, i)
            break
        end
    end
end

--------------------------------------------------------------------------------------------------
-- Mouse Released Handler: Attempts to place held card onto a valid slot, or returns it to hand
-- x, y: mouse position
-- button: mouse button (1 = left click)
--------------------------------------------------------------------------------------------------
function Game:mousereleased(x, y, button)
    if button ~= 1 or not self.heldCard then return end

    local placed = false

    for _, loc in ipairs(self.board.locations) do
        local slotInfo = loc.bottom:getSlotAt(x, y)

        if slotInfo and slotInfo.valid and self:isValidPlay(self.heldCard, loc.bottom, slotInfo.index) then
            local success = loc.bottom:placeCard(self.heldCard, slotInfo.index)
            if success then
                -- Deduct mana cost
                if self.heldCard.manaCost then
                    self.mana = self.mana - self.heldCard.manaCost
                end

                placed = true
                break
            end
        end
    end

    -- If not placed, return card to hand
    if not placed then
        table.insert(self.hand, self.heldCard)
    end

    self.heldCard = nil
end

--------------------------------------------------------------------------------------------------
-- isValidPlay: Validates whether a card can be placed on a given slot
-- card: the card to place
-- slotRow: the SlotRow object representing the row of slots
-- index: slot index within the row
-- Returns: true if valid, false otherwise
--------------------------------------------------------------------------------------------------
function Game:isValidPlay(card, slotRow, index)
    -- Must have enough mana
    if card.manaCost and card.manaCost > self.mana then
        return false
    end

    -- Only "creature" cards allowed in bottom rows (example rule)
    if card.type and card.type ~= "creature" then
        return false
    end

    -- Prevent duplicate card names in the same row
    local rowCards = slotRow:getCards()
    for _, c in ipairs(rowCards) do
        if c and c.name == card.name then
            return false
        end
    end

    return true
end

return setmetatable({}, { __call = function(_, ...) return Game:new(...) end })

-- src/Game.lua
local Deck = require("src.Deck")
local Board = require("src.Board")

local Game = {}
Game.__index = Game

function Game:new()
    local self = setmetatable({}, Game)

    self.board = Board()
    self.deck = Deck(self.board.deck.x, self.board.deck.y)
    self.deck:shuffle()

    self.hand = {}        -- Player 1's current hand
    self.heldCard = nil   -- Card being dragged
    self.dragOffsetX = 0
    self.dragOffsetY = 0

    self.turn = 1         -- Starts on turn 1
    self.mana = 1         -- Mana equals turn number
    self.maxMana = 25     -- Maximum mana allowed

    self.hoveredSlot = { location = nil, index = nil }

    -- Deal initial hand (3 cards)
    for i = 1, 3 do
        local card = self.deck:drawTopCard()
        if card then
            card.x = self.board.handP1[i].x
            card.y = self.board.handP1[i].y
            table.insert(self.hand, card)
        end
    end

    return self
end

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

function Game:draw()
    self.board:draw(self.hoveredSlot)

    -- Draw cards in hand
    for _, card in ipairs(self.hand) do
        card:draw()
    end

    -- Draw held card on top
    if self.heldCard then
        self.heldCard:draw()
    end

    -- Draw mana bar fill (for Player 1 only for now)
    local manaRatio = math.min(self.mana / self.maxMana, 1)
    local bar = self.board.manaBarP1
    local fillW = bar.w * manaRatio

    love.graphics.setColor(0, 0.8, 1)
    love.graphics.rectangle("fill", bar.x, bar.y, fillW, bar.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", bar.x, bar.y, bar.w, bar.h)
end

function Game:mousepressed(x, y, button)
    if button ~= 1 then return end

    -- Handle clicking submit button to end turn
    local btn = self.board.submitButton
    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
        self.turn = self.turn + 1
        self.mana = math.min(self.turn, self.maxMana)
        return
    end

    -- Grab card from hand
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

function Game:mousereleased(x, y, button)
    if button ~= 1 or not self.heldCard then return end

    local placed = false

    -- Check for legal drop zones (bottom rows only)
    for _, loc in ipairs(self.board.locations) do
        local row = loc.bottom:getCards()
        for i = 1, #row do
            local sx = loc.bottom.x + (i - 1) * (self.heldCard.width + 5)
            local sy = loc.bottom.y
            if not row[i] and x >= sx and x <= sx + self.heldCard.width and y >= sy and y <= sy + self.heldCard.height then
                placed = loc.bottom:placeCard(self.heldCard, i)
                break
            end
        end
        if placed then break end
    end

    if not placed then
        -- Return to hand if not placed
        table.insert(self.hand, self.heldCard)
    end

    self.heldCard = nil
end

return setmetatable({}, { __call = function(_, ...) return Game:new(...) end })

local Card = require("Card")
local Board = require("Board")

local GameState = {}
GameState.__index = GameState

local WINNING_POINTS = 25

local HAND_LIMIT = 7

function GameState:new()
    local self = setmetatable({}, GameState)
    self.turn = 1
    self.mana = 1
    
    self.playerManaUsed = 0
    self.aiManaUsed = 0
    self.hoveredCard = nil

    self.board = Board.new()
    self.playerDeck = {}
    self.aiDeck = {}
    self.playerHand = {}
    self.aiHand = {}

    self.playerPoints = 0
    self.aiPoints = 0

    self.phase = "play"

    self.drawButton = { x = 30, y = 550, w = 80, h = 40 }
    self.submitButton = { x = 35, y = 640, w = 80, h = 40 }
    self.continueButton = { x = 35, y = 640, w = 80, h = 40 }
    self.restartButton = { x = 640, y = 310, w = 120, h = 40 }


    self:loadDecks()
    self:shuffleDeck(self.playerDeck)
    self:shuffleDeck(self.aiDeck)

    self:drawCards(self.playerDeck, self.playerHand, 3)
    self:drawCards(self.aiDeck, self.aiHand, 3)

    return self
end

local function parseCSVLine(line)
    local res = {}
    for token in string.gmatch(line, '([^,]+)') do
        table.insert(res, token)
    end
    return res
end

function GameState:loadDecks()
    local path = "cards.csv"
    local file = love.filesystem.read(path)
    if not file then
        print("Failed to load cards.csv, using default deck")
        for i = 2, #lines do
            local values = parseCSVLine(lines[i])
            local name = values[1]
            local cost = tonumber(values[2]) or 1
            local power = tonumber(values[3]) or 1
            local effect = values[4] or ""

            local card1 = Card.new(name, cost, power, effect, 0, 0)
            local card2 = Card.new(name, cost, power, effect, 0, 0)
            
            table.insert(self.playerDeck, card1)
            table.insert(self.aiDeck, card2)
        end
        return
    end

    local lines = {}
    for line in file:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for i = 2, #lines do
        local values = parseCSVLine(lines[i])
        local name = values[1]
        local cost = tonumber(values[2]) or 1
        local power = tonumber(values[3]) or 1
        local effect = values[4]

        local card1 = Card.new(name, cost, power, effect, 0, 0)
        local card2 = Card.new(name, cost, power, effect, 0, 0)
        table.insert(self.playerDeck, card1)
        table.insert(self.aiDeck, card2)
    end
end


function GameState:shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function GameState:drawCards(deck, hand, num)
    for i = 1, num do
        if #deck > 0 then
            local card = table.remove(deck, 1)
            card.x = 0
            card.y = 0
            table.insert(hand, card)
        end
    end
    self:layoutHand(hand)
end

function GameState:layoutHand(hand)
    local y = (hand == self.playerHand) and 620 or 20
    for i, card in ipairs(hand) do
        card.x = 150 + (i - 1) * 80
        card.y = y
    end
end

function GameState:update(dt)
end

function GameState:drawManaBar(x, y, width, height)
    -- Background bar (dark blue)
    love.graphics.setColor(0.1, 0.1, 0.5)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Filled mana (light blue)
    local manaRatio = (self.mana - self.playerManaUsed) / self.mana
    local filledWidth = math.max(0, width * manaRatio)

    love.graphics.setColor(0.4, 0.6, 1.0)
    love.graphics.rectangle("fill", x, y, filledWidth, height)

    -- Hovered card cost bar (red), drawn from right to left
    if self.hoveredCard then
        local cardCost = self.hoveredCard.cost or 0
        local costRatio = math.min(cardCost / self.mana, 1)
        local redBarWidth = width * costRatio
        local redBarStartX = x + filledWidth - redBarWidth

        love.graphics.setColor(1.0, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", redBarStartX, y, redBarWidth, height)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end


function GameState:draw()
    self.board:draw()
    for _, card in ipairs(self.playerHand) do
        card:draw()
    end
    for _, card in ipairs(self.aiHand) do
        card:draw()
    end
    
    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            local aiSlot = zone.aiSlots[i]
            local card = aiSlot.card
            if card then
                if self.phase == "play" then
                    love.graphics.setColor(0.6, 0.6, 0.6)
                    love.graphics.rectangle("fill", card.x, card.y, card.width or 60, card.height or 90)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf("???", card.x, card.y + 35, card.width or 55, "center")
                else
                    card:draw()
                end
            end
        end
    end

    local cx = self.drawButton.x + self.drawButton.w / 2
        local cy = self.drawButton.y + self.drawButton.h / 2
        local w, h = 34, 46 -- same size as your drawDeckIcon
        local offset = 4
        love.graphics.setColor(0.8, 0.8, 0.8)
        for i = 2, 0, -1 do
            local ox, oy = i * offset, i * offset
            love.graphics.rectangle("line", cx - w/2 + ox, cy - h/2 + oy, w, h)
        end
    -- Draw buttons based on phase
    love.graphics.setColor(0.4, 0.9, 0.4)
    if self.phase == "play" then
        love.graphics.setColor(0.6, 0.6, 0.9)
        love.graphics.rectangle("fill", self.submitButton.x, self.submitButton.y, self.submitButton.w, self.submitButton.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Submit", self.submitButton.x, self.submitButton.y + 12, self.submitButton.w, "center")
    elseif self.phase == "reveal" then
        love.graphics.setColor(0.9, 0.4, 0.4)
        love.graphics.rectangle("fill", self.continueButton.x, self.continueButton.y, self.continueButton.w, self.continueButton.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Continue", self.continueButton.x, self.continueButton.y + 12, self.continueButton.w, "center")
    end

    -- Draw points and info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("" .. #self.playerDeck, 65, 565)
    love.graphics.print("Hand: " .. #self.playerHand .. "/" .. HAND_LIMIT, 20, 30)
    love.graphics.print("Player Points: " .. self.playerPoints, 20, 50)
    love.graphics.print("AI Points: " .. self.aiPoints, 20, 70)
    
    -- Draw Player mana info
    love.graphics.print("Player Mana: " .. (self.mana - self.playerManaUsed) .. "/" .. self.mana, 150, 550)
    love.graphics.print("Player Mana Used: " .. self.playerManaUsed, 150, 575)

    -- Draw AI mana info
    love.graphics.print("AI Mana: " .. self.mana, 150, 125)
    love.graphics.print("AI Mana Used: " .. self.aiManaUsed, 150, 150)

    -- Draw AI cards count (hand size)
    love.graphics.print("AI Cards in Hand: " .. #self.aiHand, 20, 90)
    
    -- Draw mana bar at bottom center
    self:drawManaBar(150, 575, 540, 20)

    
    
    if self.phase == "gameover" then
      love.graphics.setColor(1, 0, 0)
      local msg = "Game Over! "
      if self.winner == "Tie" then
          msg = msg .. "It's a tie!"
      else
          msg = msg .. self.winner .. " wins!"
      if self.phase == "gameover" then
          love.graphics.setColor(0.2, 0.8, 0.2)
          love.graphics.rectangle("fill", self.restartButton.x, self.restartButton.y, self.restartButton.w, self.restartButton.h)
          love.graphics.setColor(0, 0, 0)
          love.graphics.printf("Restart", self.restartButton.x, self.restartButton.y + 12, self.restartButton.w, "center")
      end
    end
    love.graphics.printf(msg, 0, 300, love.graphics.getWidth(), "center")
end

end


function GameState:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self.phase == "play" then
        if self:inRect(x, y, self.drawButton) then
            if #self.playerHand < HAND_LIMIT then
                self:drawCards(self.playerDeck, self.playerHand, 1)
                self:layoutHand(self.playerHand)
            end
            return
        end

        if self:inRect(x, y, self.submitButton) then
            self:resolveCombat()
            self.phase = "reveal"
            return
        end

        for _, card in ipairs(self.playerHand) do
            if card:contains(x, y) then
                self.draggingCard = card
                self.dragOffsetX = x - card.x
                self.dragOffsetY = y - card.y
                break
            end
        end

    elseif self.phase == "reveal" then
        if self:inRect(x, y, self.continueButton) then
            self:nextRound()
        end

    elseif self.phase == "gameover" then
        if self:inRect(x, y, self.restartButton) then
            self:restartGame()
            return
        end
    end

    self.hoveredCard = nil
    self.board.textbox.text = ""

    for _, card in ipairs(self.playerHand) do
        if card:contains(x, y) then
            self.hoveredCard = card
            self.board.textbox.text = string.format(
                "%s\nCost: %d\nPower: %d\n%s",
                card.name,
                card.cost,
                card.power,
                card.description
            )
            break
        end
    end
end


function GameState:mousemoved(x, y, dx, dy)
    if self.draggingCard then
        self.draggingCard.x = x - self.dragOffsetX
        self.draggingCard.y = y - self.dragOffsetY
        return
    end

    
end

function GameState:mousereleased(x, y, button)
    if button ~= 1 or not self.draggingCard then return end

    local slot = self.board:getHoveredSlot(x, y)
    if slot and not slot.card and self.phase == "play" then
        -- Check if player has enough mana left
        if self.draggingCard.cost + self.playerManaUsed <= self.mana then
            -- Valid move
            slot.card = self.draggingCard
            self.playerManaUsed = self.playerManaUsed + self.draggingCard.cost

            for i, c in ipairs(self.playerHand) do
                if c == self.draggingCard then
                    table.remove(self.playerHand, i)
                    break
                end
            end

            self.draggingCard.x = slot.x
            self.draggingCard.y = slot.y
            self:layoutHand(self.playerHand)

            self:aiTurn()
        else
            -- Not enough mana, reject the move and reset card position
            self.draggingCard.x = nil
            self.draggingCard.y = nil
            self:layoutHand(self.playerHand)
        end
    end

    self.draggingCard = nil
end

function GameState:aiTurn()
    if self.phase ~= "play" then return end

  
    local i = 1
    while i <= #self.aiHand do
        local card = self.aiHand[i]
        if card.cost + self.aiManaUsed <= self.mana then
            local slot = self.board:getEmptySlotForAI()
            if slot then
                -- Place the card
                slot.card = card
                card.x = slot.x
                card.y = slot.y

                self.aiManaUsed = self.aiManaUsed + card.cost
                table.remove(self.aiHand, i) 
            else
                break 
            end
        else
            i = i + 1 
        end
    end
end


function GameState:resolveCombat()
    for _, zone in ipairs(self.board.zones) do
        -- Trigger onReveal abilities before calculating power
        for i = 1, 4 do
            local pCard = zone.playerSlots[i].card
            local aCard = zone.aiSlots[i].card

            if pCard and pCard.onReveal then
                print("Triggering onReveal for player card: " .. pCard.name)
                pCard.onReveal(self, "player")
            end
            if aCard and aCard.onReveal then
                aCard.onReveal(self, "ai")
            end
        end

        -- Then do regular power comparison
        local playerPower, aiPower = 0, 0
        for i = 1, 4 do
            local pCard = zone.playerSlots[i].card
            local aCard = zone.aiSlots[i].card
            if pCard then playerPower = playerPower + pCard.power end
            if aCard then aiPower = aiPower + aCard.power end
        end

        if playerPower > aiPower then
            self.playerPoints = self.playerPoints + (playerPower - aiPower)
        elseif aiPower > playerPower then
            self.aiPoints = self.aiPoints + (aiPower - playerPower)
        end
    end

    self:checkWinCondition()
end



function GameState:nextRound()
    -- Clear board slots
    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            zone.playerSlots[i].card = nil
            zone.aiSlots[i].card = nil
        end
    end

    -- Increase turn and update mana
    self.turn = (self.turn or 1) + 1
    self.mana = self.turn

    -- Reset used mana
    self.playerManaUsed = 0
    self.aiManaUsed = 0

    -- Draw 1 card for each player if hand size is less than limit
    if #self.playerHand < HAND_LIMIT then
        self:drawCards(self.playerDeck, self.playerHand, 1)
    end
    if #self.aiHand < HAND_LIMIT then
        self:drawCards(self.aiDeck, self.aiHand, 1)
    end

    -- Reset round state
    self.phase = "play"
    self.winner = nil
    self.draggingCard = nil

    -- Layout updated hands
    self:layoutHand(self.playerHand)
    self:layoutHand(self.aiHand)

    self:checkWinCondition()
end


function GameState:checkWinCondition()
    if self.playerPoints >= WINNING_POINTS and self.aiPoints >= WINNING_POINTS then
        self.phase = "gameover"
        self.winner = "Tie"
    elseif self.playerPoints >= WINNING_POINTS then
        self.phase = "gameover"
        self.winner = "Player"
    elseif self.aiPoints >= WINNING_POINTS then
        self.phase = "gameover"
        self.winner = "AI"
    end
end


function GameState:inRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end

function GameState:restartGame()
    self.turn = 1
    self.mana = 1
    self.playerManaUsed = 0
    self.aiManaUsed = 0
    self.playerPoints = 0
    self.aiPoints = 0
    self.phase = "play"
    self.winner = nil
    self.draggingCard = nil

    self.playerDeck = {}
    self.aiDeck = {}
    self.playerHand = {}
    self.aiHand = {}

    self:loadDecks()
    self:shuffleDeck(self.playerDeck)
    self:shuffleDeck(self.aiDeck)
    self:drawCards(self.playerDeck, self.playerHand, 3)
    self:drawCards(self.aiDeck, self.aiHand, 3)

    for _, zone in ipairs(self.board.zones) do
        for i = 1, 4 do
            zone.playerSlots[i].card = nil
            zone.aiSlots[i].card = nil
        end
    end
end


return GameState
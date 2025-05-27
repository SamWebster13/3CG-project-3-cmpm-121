local GameState = {}
GameState.__index = GameState

local Card = require("Card")
local Board = require("Board")

function GameState.new()
    local self = setmetatable({}, GameState)
    self.board = Board.new()

    -- Create draw pile (shuffled deck of all cards)
    self.drawPile = {}
    for i = 1, 20 do
        table.insert(self.drawPile, Card.new("Card " .. i, love.math.random(1, 3), love.math.random(1, 5)))
    end
    -- Shuffle
    for i = #self.drawPile, 2, -1 do
        local j = love.math.random(i)
        self.drawPile[i], self.drawPile[j] = self.drawPile[j], self.drawPile[i]
    end

    self.playerHand = {}
    self.maxHandSize = 5

    return self
end

function GameState:draw()
    self.board:draw()

    -- Draw player hand
    local startX = 100
    for i, card in ipairs(self.playerHand) do
        card.x = startX + (i - 1) * 120
        card.y = 600
        card:draw()
    end

    -- Draw draw pile
    love.graphics.setColor(0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 40, 600, 100, 140)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 40, 600, 100, 140)
    love.graphics.print("Draw (" .. #self.drawPile .. ")", 50, 610)
    
    love.graphics.print("Turn: " .. self.turn, 40, 20)
    love.graphics.print("Your Mana: " .. self.player.mana, 40, 40)
    love.graphics.print("Your Points: " .. self.player.points, 40, 60)
    love.graphics.print("Enemy Points: " .. self.enemy.points, 40, 80)

    -- Draw Submit button
    if self.phase == "play" then
        love.graphics.rectangle("line", 600, 700, 150, 40)
        love.graphics.print("Submit Turn", 610, 710)
    end

end

function GameState:mousepressed(x, y, button)
    if button == 1 then
        -- Clicked on draw pile?
        if x >= 40 and x <= 140 and y >= 600 and y <= 740 then
            self:drawCard()
        end
    end
end

function GameState:drawCard()
    if #self.drawPile > 0 and #self.playerHand < self.maxHandSize then
        local card = table.remove(self.drawPile)
        table.insert(self.playerHand, card)
    end
end

function GameState:mousepressed(x, y, button)
    if button == 1 then
        for _, card in ipairs(self.playerHand) do
            if card:contains(x, y) then
                print("Card clicked:", card.name)
            end
        end

        -- Draw pile clicked
        if x >= 40 and x <= 140 and y >= 600 and y <= 740 then
            self:drawCard()
        end
    end
end

function GameState:startTurn()
    self.turn = self.turn + 1
    self.player.mana = self.turn
    self.enemy.mana = self.turn
    self.player:drawCard()
    self.enemy:drawCard()
    self.phase = "play"
end

function GameState:submitTurn()
    self.phase = "resolution"

    -- Random enemy placement
    for i = 1, 3 do
        local slots = self.enemy.board[i]
        while #slots < 4 and #self.enemy.hand > 0 do
            local idx = love.math.random(#self.enemy.hand)
            local card = table.remove(self.enemy.hand, idx)
            if self.enemy:canPlay(card) then
                self.enemy.mana = self.enemy.mana - card.cost
                table.insert(slots, card)
            end
        end
    end

    -- Reveal order (winner flips first)
    self:resolveCombat()
end

function GameState:resolveCombat()
    for i = 1, 3 do
        local playerPower, enemyPower = 0, 0
        for _, c in ipairs(self.player.board[i]) do playerPower = playerPower + c.power end
        for _, c in ipairs(self.enemy.board[i]) do enemyPower = enemyPower + c.power end

        if playerPower > enemyPower then
            self.player.points = self.player.points + (playerPower - enemyPower)
        elseif enemyPower > playerPower then
            self.enemy.points = self.enemy.points + (enemyPower - playerPower)
        end
    end

    -- Check win condition
    local winScore = 20
    if self.player.points >= winScore or self.enemy.points >= winScore then
        self.phase = "gameover"
    else
        self:prepareNextTurn()
    end
end

function GameState:prepareNextTurn()
    -- Clear board or move to discard pile if you have one
    for i = 1, 3 do
        self.player.board[i] = {}
        self.enemy.board[i] = {}
    end
    self:startTurn()
end

function GameState:mousepressed(x, y, button)
    if button == 1 and self.phase == "play" then
        if x >= 600 and x <= 750 and y >= 700 and y <= 740 then
            self:submitTurn()
        end
    end
end

return GameState

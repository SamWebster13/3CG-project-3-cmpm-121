local Card = {}
Card.__index = Card

--------------------------------------------------------------------------------
-- CONSTRUCTOR
-- Constructor: Create a new card initalized with info from an .csv file
--------------------------------------------------------------------------------
function Card.new(name, cost, power, description, x, y)
    local self = setmetatable({}, Card)
    self.name = name
    self.cost = tonumber(cost)
    self.power = tonumber(power)
    self.description = description or ""
    self.x = x or 0
    self.y = y or 0

    -- Auto-generate simple effects from name or description
    -- CARDS IMPLEMENTED:
    -- Zeus
    -- Ares 
    -- Pandora 
    -- Dionysus
    -- Artemis
    -- Aphrodite
    -- Medusa 
    -- Cyclops
    -- Hera
    -- Hercules
    -- Athena
    -- Apollo
    self.onReveal = nil    
    if name == "Zeus" then -- ZEUS --------------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local slots = isPlayer and zone.aiSlots or zone.playerSlots
                for _, slot in ipairs(slots) do
                    local card = slot.card
                    if card then
                        print("Zeus lowers " .. card.name .. "'s power from " .. card.power)
                        card.power = math.max(0, card.power - 1)
                    end
                end
            end
        end                    
    elseif name == "Ares" then -- ARES --------------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local slots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(slots) do
                    if slot.card == self then
                        -- Found Ares's lane
                        local enemySlots = isPlayer and zone.aiSlots or zone.playerSlots
                        local enemyCount = 0

                        for _, enemySlot in ipairs(enemySlots) do
                            if enemySlot.card then
                                enemyCount = enemyCount + 1
                            end
                        end

                        local boost = 2 * enemyCount
                        print("Ares gains +" .. boost .. " power from " .. enemyCount .. " enemies")
                        self.power = self.power + boost
                        return
                    end
                end
            end
        end                       
    elseif name == "Pandora" then -- PANDORA -----------------------------------------
    self.onReveal = function(gameState, owner)
        local zones = gameState.board.zones
        local isPlayer = (owner == "player")

        for _, zone in ipairs(zones) do
            local slots = isPlayer and zone.playerSlots or zone.aiSlots
            for _, slot in ipairs(slots) do
                if slot.card == self then
                    -- Found Pandora's location
                    local allyCount = 0
                    for _, s in ipairs(slots) do
                        if s.card and s.card ~= self then
                            allyCount = allyCount + 1
                        end
                    end
                    if allyCount == 0 then
                        print("Pandora loses 5 power due to being alone")
                        self.power = math.max(0, self.power - 5)
                    end
                    return
                end
            end
        end
    end                            
    elseif name == "Dionysus" then -- DIONYSUS ----------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local slots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(slots) do
                    if slot.card == self then
                        -- Found Dionysus's zone
                        local allyCount = 0
                        for _, s in ipairs(slots) do
                            if s.card and s.card ~= self then
                                allyCount = allyCount + 1
                            end
                        end
                        local gain = 2 * allyCount
                        print("Dionysus gains +" .. gain .. " power from " .. allyCount .. " allies")
                        self.power = self.power + gain
                        return
                    end
                end
            end
        end                       
    elseif name == "Artemis" then -- ARTEMIS -----------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local mySlots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(mySlots) do
                    if slot.card == self then
                        -- Found Artemis's zone
                        local enemySlots = isPlayer and zone.aiSlots or zone.playerSlots
                        local enemyCount = 0
                        for _, eSlot in ipairs(enemySlots) do
                            if eSlot.card then
                                enemyCount = enemyCount + 1
                            end
                        end
                        if enemyCount == 1 then
                            print("Artemis gains +5 power due to exactly one enemy")
                            self.power = self.power + 5
                        end
                        return
                    end
                end
            end
        end                         
    elseif name == "Aphrodite" then -- APHRODITE ---------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local slots = isPlayer and zone.aiSlots or zone.playerSlots
                for _, slot in ipairs(slots) do
                    local card = slot.card
                    if card then
                        print("Aphrodite lowers " .. card.name .. "'s power from " .. card.power)
                        card.power = math.max(0, card.power - 1)
                    end
                end
            end
        end               
    elseif name == "Medusa" then -- MEDUSA ------------------------------------------
        -- Medusa sets a persistent effect: when any other card is played in her zone, reduce its power
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local mySlots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(mySlots) do
                    if slot.card == self then
                        zone.medusaEffect = function(playedCard)
                            if playedCard ~= self then
                                print("Medusa petrifies " .. playedCard.name .. ", lowering power by 2")
                                playedCard.power = math.max(0, playedCard.power - 2)
                            end
                        end
                        print("Medusa's effect activated in this zone.")
                        return
                    end
                end
            end
        end                       
    elseif name == "Cyclops" then -- CYCLOPS -----------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")

            for _, zone in ipairs(zones) do
                local mySlots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(mySlots) do
                    if slot.card == self then
                        -- Found Cyclops's zone
                        local discarded = 0
                        for _, s in ipairs(mySlots) do
                            if s.card and s.card ~= self then
                                print("Cyclops discards " .. s.card.name)
                                s.card = nil
                                discarded = discarded + 1
                            end
                        end
                        local gain = 2 * discarded
                        print("Cyclops gains +" .. gain .. " power from discarding " .. discarded .. " allies")
                        self.power = self.power + gain
                        return
                    end
                end
            end
        end                    
    elseif name == "Hera" then -- HERA --------------------------------------------
        self.onReveal = function(gameState, owner)
            local hand = (owner == "player") and gameState.playerHand or gameState.aiHand
            local buffed = 0
            for _, card in ipairs(hand) do
                if card ~= self then
                    card.power = card.power + 1
                    buffed = buffed + 1
                    print("Hera blesses " .. card.name .. ", now has " .. card.power .. " power")
                end
            end
            print("Hera buffed " .. buffed .. " cards in hand.")
        end
    elseif name == "Hercules" then -- HERCULES -----------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")
            for _, zone in ipairs(zones) do
                local slots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(slots) do
                    if slot.card == self then
                        -- Check if strongest in this zone
                        local strongest = true
                        for _, s in ipairs(slots) do
                            if s.card and s.card ~= self and s.card.power > self.power then
                                strongest = false
                                break
                            end
                        end
                        if strongest then
                            print("Hercules doubles power from " .. self.power .. " to " .. (self.power * 2))
                            self.power = self.power * 2
                        end
                        return
                    end
                end
            end
        end

    


    elseif name == "Athena" then -- ATHENA --------------------------------------------
        self.onReveal = function(gameState, owner)
            local zones = gameState.board.zones
            local isPlayer = (owner == "player")
            for _, zone in ipairs(zones) do
                local slots = isPlayer and zone.playerSlots or zone.aiSlots
                for _, slot in ipairs(slots) do
                    if slot.card == self then
                        zone.athenaEffect = function(playedCard)
                            if playedCard ~= self then
                                print("Athena inspires " .. playedCard.name)
                                playedCard.power = playedCard.power + 1
                            end
                        end
                        print("Athena's passive effect activated in this zone.")
                        return
                    end
                end
            end
        end

    elseif name == "Apollo" then -- APOLLO --------------------------------------------
        self.onReveal = function(gameState, owner)
            if owner == "player" then
                gameState.pendingPlayerMana = (gameState.pendingPlayerMana or 0) + 1
                print("Apollo blesses the player with +1 mana next turn")
            else
                gameState.pendingAiMana = (gameState.pendingAiMana or 0) + 1
                print("Apollo blesses the AI with +1 mana next turn")
            end
        end

    end -- ← MISSING `end` was added here

    return self
end
--------------------------------------------------------------------------------
-- DRAW
-- Draw function: Draw cards
--------------------------------------------------------------------------------
function Card:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 60, 90)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, 60, 90)
    love.graphics.print(self.name, self.x + 5, self.y + 10)
    love.graphics.print("Cost: " .. self.cost, self.x + 5, self.y + 30)
    love.graphics.print("Power: " .. self.power, self.x + 5, self.y + 50)
end

--------------------------------------------------------------------------------
-- HELPER
-- Sizing: helps with sizing and hitbox behaviors
--------------------------------------------------------------------------------
function Card:contains(x, y)
    return x >= self.x and x <= self.x + 60 and y >= self.y and y <= self.y + 90
end

return Card

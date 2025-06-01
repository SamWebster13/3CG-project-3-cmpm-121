local Board = {}
Board.__index = Board

--------------------------------------------------------------------------------
-- FUNCTION: createZoneSlots
-- Creates a single zone with AI and player slots arranged in a grid
--------------------------------------------------------------------------------
local function createZoneSlots(zoneIndex, xStart)
    local zone = {
        name = "Zone " .. zoneIndex,
        playerSlots = {},
        aiSlots = {},
    }

    local cols, rows = 4, 1
    local slotWidth, slotHeight = 60, 90
    local spacingX, spacingY = 75, 160
    local gapBetweenZones = 400
    local zoneXOffset = (zoneIndex - 1) * gapBetweenZones
    local zoneCenterX = xStart + zoneXOffset
    local aiYStart = 220
    local playerYStart = aiYStart + (rows * spacingY) + 40
    local function createGrid(xCenter, yTop)
        local slots = {}
        local startX = xCenter - ((cols - 1) * spacingX) / 2
        for row = 1, rows do
            for col = 1, cols do
                table.insert(slots, {
                    x = startX + (col - 1) * spacingX,
                    y = yTop + (row - 1) * spacingY,
                    width = slotWidth,
                    height = slotHeight,
                    card = nil,
                })
            end
        end
        return slots
    end
    zone.aiSlots = createGrid(zoneCenterX, aiYStart)
    zone.playerSlots = createGrid(zoneCenterX, playerYStart)
    local allSlots = {}
    for _, slot in ipairs(zone.aiSlots) do table.insert(allSlots, slot) end
    for _, slot in ipairs(zone.playerSlots) do table.insert(allSlots, slot) end
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, slot in ipairs(allSlots) do
        minX = math.min(minX, slot.x)
        minY = math.min(minY, slot.y)
        maxX = math.max(maxX, slot.x + slot.width)
        maxY = math.max(maxY, slot.y + slot.height)
    end
    zone.x = minX - 10
    zone.y = minY - 10
    zone.width = (maxX - minX) + 20
    zone.height = (maxY - minY) + 20
    return zone
end


--------------------------------------------------------------------------------
-- FUNCTION: createHandSlots
-- Manual slot array creation (for hand zones)
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- FUNCTION: drawSlotArray
-- Manual drawing for any array of slots
--------------------------------------------------------------------------------
function Board:drawSlotArray(slotArray)
    for _, slot in ipairs(slotArray) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", slot.x, slot.y, slot.w or slot.width, slot.h or slot.height)
        if slot.card then
            if slot.card.draw then
                slot.card:draw(slot.x, slot.y, slot.w or slot.width, slot.h or slot.height)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- CONSTRUCTOR
-- Constructor: Create a new Board with 3 zones and hand areas
--------------------------------------------------------------------------------
function Board.new(player)
    local self = setmetatable({}, Board)

    self.cardWidth = 60
    self.cardHeight = 90
    self.slotPadding = 20

    -- Store player reference
    self.player = player

    local startX = 200
    self.zones = {
        createZoneSlots(1, startX),
        createZoneSlots(2, startX),
        createZoneSlots(3, startX),
    }

    self.playerHandSlots = self:createHandSlots(150, 620)
    self.aiHandSlots = self:createHandSlots(150, 20)
    self.maxMana = 25

    local function getManaBarCoords(handSlots, offsetY)
        local firstSlot = handSlots[1]
        local x = firstSlot and firstSlot.x or 100
        local y = firstSlot and (firstSlot.y + offsetY) or 100
        local w = (#handSlots) * (self.cardWidth + self.slotPadding) - self.slotPadding
        local h = 12
        return { x = x, y = y, w = w, h = h }
    end
    self.manaBar = getManaBarCoords(self.playerHandSlots, -40)
    self.textbox = {
        x = 800,
        y = 550,
        width = 400,
        height = 150,
        text = "", 
    }
    self.playerDiscardPile = {}
    self.aiDiscardPile = {}
    self.playerDiscardSlot = {
        x = 715, y = 620, width = self.cardWidth, height = self.cardHeight, card = nil
    }
    self.aiDiscardSlot = {
        x = 715, y = 20, width = self.cardWidth, height = self.cardHeight, card = nil
    }
    return self
end

--------------------------------------------------------------------------------
-- DRAW
-- Draw function: Draw all zones, slots, cards, and power totals
--------------------------------------------------------------------------------
function Board:draw()
    love.graphics.clear(0.2, 0.3, 0.4)
    for i, zone in ipairs(self.zones) do
        -- Draw zone outline rectangle
        love.graphics.setColor(.7, 1, .7)
        love.graphics.rectangle("line", zone.x, zone.y, zone.width, zone.height)
        local zoneLabelX = zone.playerSlots[1].x
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Zone " .. i, zoneLabelX, zone.y - 20)
        love.graphics.setColor(1, 0.8, 0.8)
        self:drawSlotArray(zone.aiSlots)
        love.graphics.setColor(0.8, 0.8, 1)
        self:drawSlotArray(zone.playerSlots)
        local playerPower, aiPower = self:calculateZonePower(zone)
        love.graphics.setColor(0.6, 0.6, 1)
        love.graphics.print("Player Power: " .. playerPower, zone.x + 10, zone.y + zone.height - 150)
        love.graphics.setColor(1, 0.6, 0.6)
        love.graphics.print("AI Power: " .. aiPower, zone.x + 10, zone.y + zone.height - 170)
    end
    love.graphics.setColor(0.9, 0.9, 1)
    self:drawSlotArray(self.playerHandSlots)
    love.graphics.setColor(1, 0.9, 0.9)
    self:drawSlotArray(self.aiHandSlots)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", self.textbox.x, self.textbox.y, self.textbox.width, self.textbox.height, 8, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.textbox.x, self.textbox.y, self.textbox.width, self.textbox.height, 8, 8)
    love.graphics.printf(
        self.textbox.text,
        self.textbox.x + 10,
        self.textbox.y + 10,
        self.textbox.width - 20
    )
    love.graphics.setColor(0.8, 0.5, 0.5)
    love.graphics.rectangle("line", self.playerDiscardSlot.x, self.playerDiscardSlot.y, self.cardWidth, self.cardHeight)
    if self.playerDiscardSlot.card then
        self.playerDiscardSlot.card:draw(self.playerDiscardSlot.x, self.playerDiscardSlot.y)
    end
    love.graphics.setColor(0.5, 0.5, 0.8)
    love.graphics.rectangle("line", self.aiDiscardSlot.x, self.aiDiscardSlot.y, self.cardWidth, self.cardHeight)
    if self.aiDiscardSlot.card then
        self.aiDiscardSlot.card:draw(self.aiDiscardSlot.x, self.aiDiscardSlot.y)
    end
end

--------------------------------------------------------------------------------
-- FUNCTION: getHoveredSlot
-- Returns the player slot under the given (x, y) coordinates or nil
--------------------------------------------------------------------------------
function Board:getHoveredSlot(x, y)
    for _, zone in ipairs(self.zones) do
        for _, slot in ipairs(zone.playerSlots) do
            if x >= slot.x and x <= slot.x + slot.width and
               y >= slot.y and y <= slot.y + slot.height then
                return slot
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- FUNCTION: calculateZonePower
-- Calculates total player and AI power in a given zone
--------------------------------------------------------------------------------
function Board:calculateZonePower(zone)
    local playerPower, aiPower = 0, 0
    for _, slot in ipairs(zone.playerSlots) do
        if slot.card then
            playerPower = playerPower + (slot.card.power or 0)
        end
    end
    for _, slot in ipairs(zone.aiSlots) do
        if slot.card then
            aiPower = aiPower + (slot.card.power or 0)
        end
    end
    return playerPower, aiPower
end

--------------------------------------------------------------------------------
-- FUNCTION: getEmptySlotForAI
-- Finds and returns an empty AI slot across all zones, or nil if none found
--------------------------------------------------------------------------------
function Board:getEmptySlotForAI()
    for _, zone in ipairs(self.zones) do
        for _, slot in ipairs(zone.aiSlots) do
            if not slot.card then
                return slot
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Return the Board module
--------------------------------------------------------------------------------
return Board

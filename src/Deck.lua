local Deck = {}
Deck.__index = Deck

local Card = require("src.Card")

local function loadCSV(filename)
    local cards = {}
    local fileContent = love.filesystem.read(filename)
    if not fileContent then return cards end

    local lines = {}
    for line in string.gmatch(fileContent, "[^\r\n]+") do
        table.insert(lines, line)
    end

    local headers = {}  -- Parse CSV header
    for header in string.gmatch(lines[1], '([^,]+)') do
        table.insert(headers, header)
    end

    for i = 2, #lines do
        local values = {}
        for value in string.gmatch(lines[i], '([^,]+)') do
            table.insert(values, value)
        end

        local cardData = {
            name  = values[1],
            cost  = tonumber(values[2]),
            power = tonumber(values[3]),
            text  = values[4] or ""
        }

        table.insert(cards, Card.new(cardData))
    end

    return cards
end

function Deck.new(csvPath, x, y)
    local self = setmetatable({}, Deck)
    self.cards = {}
    self.x = x or 50
    self.y = y or 300
    self.width = 60
    self.height = 90

    -- Load cards from CSV
    local file = love.filesystem.read(csvPath)
    if file then
        local firstLine = true
        for line in string.gmatch(file, "[^\r\n]+") do
            if firstLine then
                firstLine = false
            else
                local fields = {}
                for value in string.gmatch(line, '([^,]+)') do
                    table.insert(fields, value)
                end

                local data = {
                    name = fields[1] or "Unknown",
                    cost = tonumber(fields[2]) or 1,
                    power = tonumber(fields[3]) or 1,
                    text = fields[4] or "No effect"
                }

                table.insert(self.cards, require("src.Card").new(data))
            end
        end
    end

    return self
end


function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = math.random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:drawTopCard()
    if #self.cards == 0 then return nil end
    return table.remove(self.cards)
end

return Deck

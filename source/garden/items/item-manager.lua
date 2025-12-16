local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Constants
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Data
-- --------------------------------------------------------------------------------
-- Filename where ring count is saved
local kDataFilename <const> = 'item-data'

-- --------------------------------------------------------------------------------
-- Config
-- --------------------------------------------------------------------------------
-- Max number of items allowed in the garden
local kMaxItems <const> = 8

-- Default coordinates for newly spawned items
-- TODO: handle this more dynamically based on valid garden bounds
local kItemDefaultX <const> = 150
local kItemDefaultY <const> = 64

-- ===============================================================================
-- Item Manager Class
-- ===============================================================================
class('ItemManager').extends()

function ItemManager:init()
    -- Items currently in the garden
    self.items = {}

    if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.spawnAllFruits) then
        -- DEBUG: Don't save or load items, instead spawn one of each fruit.
        self:spawnAllFruits()
    else
        -- Attempt to load data
        self:loadData()
        -- Register save function
        DATA_MANAGER:registerSaveFunction(kDataFilename, function()
            self:saveData()
        end)
    end
end

-- --------------------------------------------------------------------------------
-- Save/Load Data
-- --------------------------------------------------------------------------------

function ItemManager:saveData()
    local data = {}
    -- Save item classes and positions
    for i,item in ipairs(self.items) do
        data[i] = {
            className = item.className,
            x = item.lastValidCoordinates.x,
            y = item.lastValidCoordinates.y,
        }
    end
    pd.datastore.write(data, kDataFilename)
end

function ItemManager:loadData()
    local data = pd.datastore.read(kDataFilename)
    if data == nil then
        DEBUG_MANAGER:vPrint('ItemManager: no save data found.')
        return
    end
    DEBUG_MANAGER:vPrint('ItemManager: loading item data...')
    for _,itemData in ipairs(data) do
        self:addNewItem(itemData.className, itemData.x, itemData.y)
        DEBUG_MANAGER:vPrint('- '..itemData.className..'('..itemData.x..','..itemData.y..')', 1)
    end
    -- DEBUG: Create a fruit if nothing else was loaded
    if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.addTestItemIfNoneLoaded) and #self.items == 0 then
        DEBUG_MANAGER:vPrint('ItemManager: Adding free fruit for testing.')
        self:addNewItem('FruitA')
    end
end

-- --------------------------------------------------------------------------------
-- Add/Remove/Check Items
-- --------------------------------------------------------------------------------

function ItemManager:canAddItem()
    return #self.items < kMaxItems
end

function ItemManager:addItem(item)
    local success = self:canAddItem()

    if success then
        local index = #self.items+1
        self.items[index] = item
        item:setManagerIndex(index)
        item:add()
        DEBUG_MANAGER:vPrint('ItemManager: added item['..index..']='..item.className)
    else
        DEBUG_MANAGER:vPrint('ItemManager: attempted to add item, but limit reached.')
    end

    return success
end

-- Instantiate item with class className, add item to garden, and return item instance.
-- If coordinates aren't specified, use default values.
--
-- Note: className is not validated
function ItemManager:addNewItem(className, x, y)
    x = x ~= nil and x or kItemDefaultX
    y = y ~= nil and y or kItemDefaultY

    local item = _G[className](x, y, self)
    self:addItem(item)

    return item
end

function ItemManager:removeItem(index)
    if self.items[index] ~= nil then
        local itemToRemove = table.remove(self.items, index)
        itemToRemove:remove()
        self:updateItemIndexes()
        DEBUG_MANAGER:vPrint('ItemManager: item at index='..index..' removed')
    else
        DEBUG_MANAGER:vPrint('ItemManager: attempted to remove item at index='..index..', but not found')
    end
end

-- Call whenever indexes change on self.items
function ItemManager:updateItemIndexes()
    for i,item in ipairs(self.items) do
        item:setManagerIndex(i)
    end
end

-- Mostly for testing, probably won't get used IRL
function ItemManager:removeAll()
    for i,_ in ipairs(self.items) do
        self:removeItem(i)
    end
end

-- --------------------------------------------------------------------------------
-- Debugging
-- --------------------------------------------------------------------------------

-- DEBUG: Spawn one of each fruit
function ItemManager:spawnAllFruits()
    local startingX = kItemDefaultX
    local startingY = kItemDefaultY
    local spacing = 8

    local i = 1
    local x = startingX
    local y = startingY
    for itemClass,_ in pairs(FRUITS) do
        local item = self:addNewItem(itemClass, x, y)
        if i % 3 == 0 then
            x = startingX
            y = y + item.height + spacing
        else
            x = x + item.width + spacing
        end
        i = i + 1
    end
end
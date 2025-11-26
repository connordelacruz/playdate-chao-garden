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

-- ===============================================================================
-- Item Manager Class
-- ===============================================================================
class('ItemManager').extends()

function ItemManager:init()
    -- Items currently in the garden
    self.items = {}
    -- Attempt to load data
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)
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
            x = item.x,
            y = item.y,
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
        local item = _G[itemData.className](itemData.x, itemData.y, self)
        self:addItem(item)
        DEBUG_MANAGER:vPrint('- '..itemData.className..'('..itemData.x..','..itemData.y..')', 1)
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
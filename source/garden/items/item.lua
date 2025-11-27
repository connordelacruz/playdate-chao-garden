local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Base Item Class
-- ===============================================================================
class('Item').extends(gfx.sprite)

-- NOTE: Call <Class>.super.init(self, <args>) AT THE END of the subclass init()
function Item:init(x, y, itemManager)
    self.itemManager = itemManager

    if self:getImage() ~= nil then
        self:setCollideRect(0, 0, self:getSize())
        self:setTag(TAGS.ITEM)
    end

    self:moveTo(x, y)
end

function Item:setManagerIndex(index)
    self.index = index
end

function Item:delete()
    self.itemManager:removeItem(self.index)
end

function Item:click(cursor)
    -- TODO: when being clicked and dragged, indicate this to the itemManager so x/y pos is not saved until dropped!!!!!
    cursor:grabItem(self)
end

-- ================================================================================
-- Fruits
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Spritesheet
-- --------------------------------------------------------------------------------
local kFruitSpritesheet <const> = gfx.imagetable.new('images/items/fruit')

-- --------------------------------------------------------------------------------
-- Base Fruit Class
-- --------------------------------------------------------------------------------
class('Fruit').extends('Item')

-- NOTE: Subclasses must set the following properties in their declaration:
--      - spritesheetIndex = index into kFruitSpritesheet
--      - attributes = table with the attributes of the fruit
function Fruit:init(x, y, itemManager)
    -- Set sprite. Subclass definition needs to specify the property spritesheetIndex
    if self.spritesheetIndex ~= nil then
        -- TODO: DEBUG
        DEBUG_MANAGER:vPrint('Fruit: image set')
        self:setImage(kFruitSpritesheet[self.spritesheetIndex])
    else
        -- TODO: DEBUG
        DEBUG_MANAGER:vPrint('Fruit: image NOT set')
    end

    Fruit.super.init(self, x, y, itemManager)
end

-- --------------------------------------------------------------------------------
-- Fruit Classes
-- --------------------------------------------------------------------------------
class('FruitA', {
    spritesheetIndex = 1,
    attributes = {
        cost = 30,
        mood = 1,
        belly = 2,
        swim = 3,
        fly = -2,
        run = -2,
        power = 3,
        stamina = 1,
    },
}).extends('Fruit')

-- TODO: finish implementing
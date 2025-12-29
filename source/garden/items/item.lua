local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Base Item Class
-- ===============================================================================
class('Item', {
    -- If true, item can be given to Chao
    chaoCanTake = true,
    -- If true, Chao can eat item
    isEdible = true,
}).extends(gfx.sprite)

-- NOTE: Call <Class>.super.init(self, <args>) AT THE END of the subclass init()
function Item:init(x, y, itemManager)
    self.itemManager = itemManager
    -- Last valid position. Used to restore item position regardless of cursor shenanigans
    self.lastValidCoordinates = {
        x = x,
        y = y,
    }

    if self:getImage() ~= nil then
        self:setCollideRect(0, 0, self:getSize())
        self:setTag(TAGS.ITEM)
    end

    self:moveTo(x, y)
    self:setZIndex(Z_INDEX.GARDEN_ITEM)
end

function Item:setManagerIndex(index)
    self.index = index
end

function Item:updateLastValidCoordinates()
    self.lastValidCoordinates = {
        x = self.x,
        y = self.y,
    }
end

function Item:moveToLastValidCoordinates()
    self:moveTo(self.lastValidCoordinates.x, self.lastValidCoordinates.y)
end

function Item:delete()
    self.itemManager:removeItem(self.index)
end

function Item:click(cursor)
    cursor:grabItem(self)
end

-- ================================================================================
-- Fruits
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Spritesheet
-- --------------------------------------------------------------------------------
FRUIT_SPRITESHEET = gfx.imagetable.new('images/items/fruit')

-- --------------------------------------------------------------------------------
-- Global Constants
-- --------------------------------------------------------------------------------
-- Map classnames to fruit properties
FRUITS = {
    FruitA = {
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
    },
    FruitB = {
        spritesheetIndex = 2,
        attributes = {
            cost = 60,
            mood = 0,
            belly = 1,
            swim = 2,
            fly = 5,
            run = -1,
            power = -1,
            stamina = 3,
        },
    },
    FruitC = {
        spritesheetIndex = 3,
        attributes = {
            cost = 55,
            mood = 2,
            belly = 2,
            swim = 4,
            fly = -3,
            run = 4,
            power = -3,
            stamina = 2,
        },
    },
    FruitD = {
        spritesheetIndex = 4,
        attributes = {
            cost = 50,
            mood = -1,
            belly = 1,
            swim = 0,
            fly = -1,
            run = 3,
            power = 4,
            stamina = 2,
        },
    },
    FruitE = {
        spritesheetIndex = 5,
        attributes = {
            cost = 30,
            mood = 1,
            belly = 2,
            swim = -2,
            fly = 3,
            run = 3,
            power = -2,
            stamina = 1,
        },
    },
    FruitF = {
        spritesheetIndex = 6,
        attributes = {
            cost = 55,
            mood = 2,
            belly = 2,
            swim = -2,
            fly = 4,
            run = -2,
            power = 4,
            stamina = 2,
        },
    },
    FruitG = {
        spritesheetIndex = 7,
        attributes = {
            cost = 70,
            mood = -3,
            belly = 0,
            swim = 3,
            fly = 1,
            run = 3,
            power = 2,
            stamina = -5,
        },
    },
}

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
        self:setImage(FRUIT_SPRITESHEET[self.spritesheetIndex])
    end

    Fruit.super.init(self, x, y, itemManager)
end

-- --------------------------------------------------------------------------------
-- Fruit Classes
-- --------------------------------------------------------------------------------
-- TODO: can we use factory pattern to create these?
-- See FRUITS declaration for details
for className,props in pairs(FRUITS) do
    class(className, props).extends('Fruit')
end
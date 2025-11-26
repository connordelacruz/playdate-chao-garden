local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Base Item Class
-- ===============================================================================
class('Item').extends(gfx.sprite)

function Item:init(x, y, itemManager)
    self.itemManager = itemManager
    -- TODO: move to position. Call this after setting sprites n shit
    self:moveTo(x, y)
end

function Item:setManagerIndex(index)
    self.index = index
end

function Item:delete()
    self.itemManager:removeItem(self.index)
end

-- TODO: fruits w/ sprite
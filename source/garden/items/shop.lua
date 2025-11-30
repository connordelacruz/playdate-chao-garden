local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Shop Menu Button Indicator/Input Listener
-- ===============================================================================
class('ShopButton').extends(gfx.sprite)
-- TODO: implement open/closed state

function ShopButton:init(cursor)
    self.cursor = cursor
    -- TODO: add a simple image for this
    self:add()
end

-- --------------------------------------------------------------------------------
-- Input Handling
-- --------------------------------------------------------------------------------

function ShopButton:handlePress()
    if pd.buttonJustPressed(pd.kButtonB) and self.cursor:handsFree() then
        -- TODO: Open ShopPanel
        DEBUG_MANAGER:vPrint('ShopButton: B pressed + hands free.')
    end
end

-- --------------------------------------------------------------------------------
-- Update
-- --------------------------------------------------------------------------------

function ShopButton:update()
    self:handlePress()
end

-- ===============================================================================
-- Shop UI
-- ===============================================================================
class('ShopPanel').extends(gfx.sprite)

function ShopPanel:init(itemManager)
    self.itemManager = itemManager
    -- TODO: finish
end

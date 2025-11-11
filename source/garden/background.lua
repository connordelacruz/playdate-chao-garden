local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Garden background "sprite"
-- ================================================================================
class('GardenBackground').extends(gfx.sprite)

function GardenBackground:init()
    GardenBackground.super.init(self)
    local bgImage = gfx.image.new('images/garden/background')
    self:setImage(bgImage)

    -- Display below all other sprites
    self:setZIndex(-1)

    -- To make things easy, set center to bottom right corner
    self:setCenter(1.0, 1.0)
    -- Right side of the screen
    self:moveTo(SCREEN_WIDTH, SCREEN_HEIGHT)

    self:add()
end
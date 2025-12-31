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
    self:setZIndex(Z_INDEX.BACKGROUND)

    -- To make things easy, set center to bottom right corner
    self:setCenter(1.0, 1.0)
    -- Right side of the screen
    self:moveTo(SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Setup pond collisions
    self:createPondBoundaries()

    self:add()
end

-- Painstakingly hard-coded from guides setup in Gimp lol
function GardenBackground:createPondBoundaries()
    local bgBoundsRect = self:getBoundsRect()
    self.pondBoundaries = {}
    self.pondBoundaries[#self.pondBoundaries+1] = gfx.sprite.addEmptyCollisionSprite(
        bgBoundsRect.x, 179, 24, bgBoundsRect.height - 179
    )
    self.pondBoundaries[#self.pondBoundaries+1] = gfx.sprite.addEmptyCollisionSprite(
        bgBoundsRect.x + 24, 170, 96 - 24, bgBoundsRect.height - 170
    )
    self.pondBoundaries[#self.pondBoundaries+1] = gfx.sprite.addEmptyCollisionSprite(
        bgBoundsRect.x + 96, 198, 152 - 96, bgBoundsRect.height - 198
    )
    self.pondBoundaries[#self.pondBoundaries+1] = gfx.sprite.addEmptyCollisionSprite(
        bgBoundsRect.x + 96, 187, 138 - 96, 198 - 187
    )
    self.pondBoundaries[#self.pondBoundaries+1] = gfx.sprite.addEmptyCollisionSprite(
        bgBoundsRect.x + 96, 179, 125 - 96, 187 - 179
    )

    for i=1,#self.pondBoundaries do
        local boundarySprite = self.pondBoundaries[i]
        boundarySprite:setTag(TAGS.POND)
        boundarySprite:add()
    end
end
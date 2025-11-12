local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Cursor Sprite Class
-- ===============================================================================
-- TODO: implement states
class('Cursor').extends(gfx.sprite)

function Cursor:init(startX, startY)
    Cursor.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Spritesheet
    -- --------------------------------------------------------------------------------
    self.spritesheet = gfx.imagetable.new('images/ui/cursor')
    -- Spritesheet indices
    self.pointerSpriteIndex = 1
    self.grabSpriteIndex = 2
    self.hoverSpriteIndex = 3
    self.petSpriteIndex = 4
    self:setImage(self.spritesheet[self.pointerSpriteIndex])
    -- --------------------------------------------------------------------------------
    -- Collision
    -- --------------------------------------------------------------------------------
    self:setCollideRect(0, 0, self:getSize())
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
    -- --------------------------------------------------------------------------------
    -- Initialization
    -- --------------------------------------------------------------------------------
    -- Cursor should appear above most sprites
    self:setZIndex(999)

    self:moveTo(startX, startY)
    self:add()
end

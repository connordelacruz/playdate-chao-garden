local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Cursor Sprite Class
-- ================================================================================
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
    self:setTag(TAGS.CURSOR)
    -- --------------------------------------------------------------------------------
    -- Properties
    -- --------------------------------------------------------------------------------
    -- Speed of the cursor when moving (px / sec)
    self.speed = 200
    -- --------------------------------------------------------------------------------
    -- Initialization
    -- --------------------------------------------------------------------------------
    -- Cursor should appear above most sprites
    self:setZIndex(999)

    self:moveTo(startX, startY)
    self:add()
end

function Cursor:update()
    local current, _, _ = pd.getButtonState()
    local dx = 0
    local dy = 0
    -- Determine direction cursor should move
    if (current & pd.kButtonUp) > 0 then
        dy -= 1
    end
    if (current & pd.kButtonDown) > 0 then
        dy += 1
    end
    if (current & pd.kButtonLeft) > 0 then
        dx -= 1
    end
    if (current & pd.kButtonRight) > 0 then
        dx += 1
    end

    -- Handle movement
    if dx ~= 0 or dy ~=0 then
        local distance = self.speed * DELTA_TIME
        -- Divide distance by square root of 2 for diagonal movement
        if dx ~= 0 and dy ~= 0 then
            distance = distance / math.sqrt(2)
        end
        -- Calculate desired position
        local targetX = self.x + dx * distance
        local targetY = self.y + dy * distance
        self:moveWithCollisions(targetX, targetY)

        -- DEBUG: Print coordinates
        if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.printCursorCoordinates) then
            print('cursor @ (' .. self.x .. ',' .. self.y ..')')
        end
    end
end

function Cursor:collisionResponse(other)
    -- Overlap by default
    local toReturn = gfx.sprite.kCollisionTypeOverlap
    -- Freeze if we hit the edges of the screen
    if other:getTag() == TAGS.SCREEN_BOUNDARY then
        toReturn = gfx.sprite.kCollisionTypeFreeze
    end
    return toReturn
end
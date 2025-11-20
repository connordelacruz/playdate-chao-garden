local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Cursor States
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Generic cursor state with common constructor
-- --------------------------------------------------------------------------------
class('CursorState').extends('State')

function CursorState:init(cursor)
    self.cursor = cursor
end

-- --------------------------------------------------------------------------------
-- Active:
-- - D-pad moves cursor
-- - When cursor is not moving, A clicks
-- --------------------------------------------------------------------------------
local kActiveState <const> = 'active'
class('CursorActiveState').extends('CursorState')

function CursorActiveState:enter()
    self.cursor:setPointerImage()
end

function CursorActiveState:update()
    -- Handle D-pad input
    local isMoving = self.cursor:handleMovement()
    -- If stationary, handle A button input
    if not isMoving then
        self.cursor:handleClick()
    end
end

-- --------------------------------------------------------------------------------
-- Disabled:
-- - Cursor is hidden
-- - Input is ignored
-- --------------------------------------------------------------------------------
local kDisabledState <const> = 'disabled'
class('CursorDisabledState').extends('CursorState')

function CursorDisabledState:enter()
    -- Hide cursor
    self.cursor:setVisible(false)
end

-- ================================================================================
-- Cursor Sprite Class
-- ================================================================================
class('Cursor').extends('FSMSprite')

function Cursor:init(startX, startY)
    Cursor.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Spritesheet
    -- --------------------------------------------------------------------------------
    self.spritesheet = gfx.imagetable.new('images/ui/cursor')
    -- Spritesheet indices
    self.pointerSpriteIndex = 1
    self.grabSpriteIndex = 2
    self.dropSpriteIndex = 3
    self.pettingSpriteIndex = 4
    -- --------------------------------------------------------------------------------
    -- Properties
    -- --------------------------------------------------------------------------------
    -- Speed of the cursor when moving (px / sec)
    self.speed = 200
    -- Cursor should appear above most sprites
    self:setZIndex(999)
    -- --------------------------------------------------------------------------------
    -- State
    -- --------------------------------------------------------------------------------
    self.states = {
        [kActiveState] = CursorActiveState(self),
        [kDisabledState] = CursorDisabledState(self),
    }
    self:setInitialState(kActiveState)
    -- --------------------------------------------------------------------------------
    -- Collision
    -- --------------------------------------------------------------------------------
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.CURSOR)
    -- --------------------------------------------------------------------------------
    -- Initialization
    -- --------------------------------------------------------------------------------
    self:moveTo(startX, startY)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image setters
-- --------------------------------------------------------------------------------

function Cursor:setImageFromSpritesheet(spriteIndex)
    -- If this method is called, we're assuming the sprite should be visible
    self:setVisible(true)
    self:setImage(self.spritesheet[spriteIndex])
end

function Cursor:setPointerImage()
    self:setImageFromSpritesheet(self.pointerSpriteIndex)
end

function Cursor:setGrabImage()
    self:setImageFromSpritesheet(self.grabSpriteIndex)
end

function Cursor:setDropImage()
    self:setImageFromSpritesheet(self.dropSpriteIndex)
end

function Cursor:setPettingImage()
    self:setImageFromSpritesheet(self.pettingSpriteIndex)
end

-- --------------------------------------------------------------------------------
-- Collision
-- --------------------------------------------------------------------------------

function Cursor:collisionResponse(other)
    -- Overlap by default
    local toReturn = gfx.sprite.kCollisionTypeOverlap
    -- Freeze if we hit the edges of the screen
    if other:getTag() == TAGS.SCREEN_BOUNDARY then
        toReturn = gfx.sprite.kCollisionTypeFreeze
    end
    return toReturn
end

-- --------------------------------------------------------------------------------
-- State Functions (for external interaction)
-- --------------------------------------------------------------------------------

function Cursor:disable()
    self:setState(kDisabledState)
end

function Cursor:enable()
    self:setState(kActiveState)
end

-- --------------------------------------------------------------------------------
-- Input Handling
-- --------------------------------------------------------------------------------

-- Handle D-pad input to move cursor.
-- Returns true if cursor moved this frame, otherwise false
function Cursor:handleMovement()
    local isMoving = false
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
        isMoving = true
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

    return isMoving
end

-- TODO: return something to indicate what was clicked idk
function Cursor:handleClick()
    if pd.buttonJustPressed(pd.kButtonA) then
        local overlapping = self:overlappingSprites()
        for _, other in pairs(overlapping) do
            -- TODO: array of clickable tags
            if other:getTag() == TAGS.CLICK_TARGET then
                -- TODO: ensure click() exists and is callable
                other:click(self)
                break
            end
        end
    end
end
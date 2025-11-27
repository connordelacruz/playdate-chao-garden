local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Constants
-- ================================================================================
-- Collision tags of sprites that can be clicked
local kClickableTags <const> = {
    TAGS.CHAO,
    TAGS.CLICK_TARGET,
    TAGS.ITEM,
}

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
    -- Set default collides with tags
    self.cursor:setDefaultCollidesWithTags()
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

-- --------------------------------------------------------------------------------
-- Dragging:
-- - Sprite changes to grab w/ item sprite
-- - Cursor now collides with SCREEN_BOUNDARY and GARDEN_BOUNDARY
-- - D-pad moves cursor
-- - When cursor is not moving, A attempts to place item
-- --------------------------------------------------------------------------------
local kDraggingState <const> = 'dragging'
class('CursorDraggingState').extends('CursorState')

function CursorDraggingState:enter()
    -- TODO: pass item? Or store in obj prop
    self.cursor:setGrabImage()
    -- Cursor should collide with garden boundary when dragging an item
    self.cursor:setCollidesWithTags({
        TAGS.SCREEN_BOUNDARY,
        TAGS.GARDEN_BOUNDARY,
    })
end

function CursorDraggingState:update()
    -- Handle D-pad input
    local isMoving = self.cursor:handleMovement()
    -- TODO: self.cursor:attemptToDropItem() or whatever:
    -- If stationary, handle A button input
    -- if not isMoving then
    --     self.cursor:handleClick()
    -- end
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
    self.speed = 250
    -- Cursor should appear above most sprites
    self:setZIndex(Z_INDEX.TOP)
    -- --------------------------------------------------------------------------------
    -- Instance Variables
    -- --------------------------------------------------------------------------------
    -- When an item is being dragged, this should be set to the grabbed item object
    self.item = nil
    -- --------------------------------------------------------------------------------
    -- State
    -- --------------------------------------------------------------------------------
    self.states = {
        [kActiveState] = CursorActiveState(self),
        [kDisabledState] = CursorDisabledState(self),
        [kDraggingState] = CursorDraggingState(self),
    }
    self:setInitialState(kActiveState)
    -- --------------------------------------------------------------------------------
    -- Collision
    --
    -- NOTE: States where collision is a factor should call the relevant function
    --       to set collides with tags in their enter() function
    -- --------------------------------------------------------------------------------
    local width, height = self:getSize()
    -- Slightly offset to be closer to pointer finger
    self:setCollideRect(-(width / 4), height / 4, width, height)
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

-- TODO: take item? or check self.item; generate image with grab sprite + item sprite
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

-- Set self.collidesWithTags to the default value.
function Cursor:setDefaultCollidesWithTags()
    self.collidesWithTags = {TAGS.SCREEN_BOUNDARY}
end

-- Allow collides with tags to be overridden by state.
function Cursor:setCollidesWithTags(tagList)
    self.collidesWithTags = tagList
end

-- Check if a collision tag is in collidesWithTags.
function Cursor:shouldCollideWithTag(tag)
    -- TODO: can we do caching to make this more efficient?
    for _,collidesWithTag in ipairs(self.collidesWithTags) do
        if collidesWithTag == tag then
            return true
        end
    end
    return false
end

function Cursor:collisionResponse(other)
    -- Overlap by default
    local toReturn = gfx.sprite.kCollisionTypeOverlap
    -- Freeze if we hit a tag we should collide with
    if self:shouldCollideWithTag(other:getTag()) then
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

-- Check if a sprite's collision tag is in our list of clickables.
function Cursor:isTagClickable(otherTag)
    -- TODO: caching? map from tag -> true?
    for _,clickableTag in ipairs(kClickableTags) do
        if otherTag == clickableTag then
            return true
        end
    end
    return false
end

-- Check if a sprite with collisions is clickable
function Cursor:isTargetClickable(other)
    local isClickable = self:isTagClickable(other:getTag())
    if isClickable then
        isClickable = other['click'] ~= nil and type(other['click']) == 'function'
    end
    return isClickable
end

function Cursor:handleClick()
    if pd.buttonJustPressed(pd.kButtonA) then
        local overlapping = self:overlappingSprites()
        for _, other in ipairs(overlapping) do
            if self:isTargetClickable(other) then
                other:click(self)
                break
            end
        end
    end
end
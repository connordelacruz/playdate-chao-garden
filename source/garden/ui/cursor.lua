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
-- Tags that active cursor should collide with
local kActiveCollidesWithTags <const> = {
    TAGS.SCREEN_BOUNDARY,
}
-- Tags that grabbing cursor should collide with
local kGrabbingCollidesWithTags <const> = {
    TAGS.SCREEN_BOUNDARY,
    TAGS.GARDEN_BOUNDARY,
    TAGS.POND,
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
-- Grabbing:
-- - Sprite changes to grab w/ item sprite
-- - Cursor now collides with SCREEN_BOUNDARY and GARDEN_BOUNDARY
-- - D-pad moves cursor
-- - When cursor is not moving, A attempts to place item
-- --------------------------------------------------------------------------------
local kGrabbingState <const> = 'grabbing'
class('CursorGrabbingState').extends('CursorState')

function CursorGrabbingState:enter()
    self.cursor:setGrabImage()
    -- Cursor should collide with garden boundary when grabbing an item
    self.cursor:setCollidesWithTags(kGrabbingCollidesWithTags)
    -- Cursor may be colliding with rects with tags added above.
    -- Call this to line it up with the target item first.
    self.cursor:setInitialGrabPosition()
end

function CursorGrabbingState:update()
    -- Handle D-pad input
    local isMoving = self.cursor:handleMovement()
    self.cursor:handleGrabbedItemMovement()
    -- If stationary, handle A button input
    if not isMoving then
        self.cursor:handleGrabbedItemClick()
    end
end

function CursorGrabbingState:exit()
    -- Update last valid coordinates of item and set cursor.item to nil
    self.cursor.item:updateLastValidCoordinates()
    self.cursor.item = nil
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
        [kGrabbingState] = CursorGrabbingState(self),
    }
    self:setInitialState(kActiveState)
    -- --------------------------------------------------------------------------------
    -- Collision
    --
    -- NOTE: States where collision is a factor should call the relevant function
    --       to set collides with tags in their enter() function
    -- --------------------------------------------------------------------------------
    local width, height = self:getSize()
    self:setCollideRect(-(width / 4), height / 4, width, height)
    self:setTag(TAGS.CURSOR)
    -- Set center to line up with collide rect
    self:setCenter(0.25, 0.75)
    -- --------------------------------------------------------------------------------
    -- Item Grabbing
    -- --------------------------------------------------------------------------------
    -- We're gonna center the grabbed item in the collide rect.
    -- Rect coords are relative to sprite coords, so we'll ues these as offsets
    local collideRect = self:getCollideRect()
    self.grabbedItemPositionOffsets = {
        x = collideRect.x,
        y = collideRect.y,
    }
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

-- Set self.collidesWithTags to the default value.
function Cursor:setDefaultCollidesWithTags()
    self.collidesWithTags = kActiveCollidesWithTags
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

function Cursor:grabItem(item)
    self.item = item
    self:setState(kGrabbingState)
end

-- --------------------------------------------------------------------------------
-- Grabbing Items
-- --------------------------------------------------------------------------------

-- To try and ensure that the cursor isn't overlapping with something that
-- it should collide with when grabbing, we move it so that its collision rect
-- lines up with the target item when its state changes.
-- NOTE: self.item is assumed to be set.
function Cursor:setInitialGrabPosition()
    -- Cursor center is set to line up with the collide rect.
    -- So if we move the cursor to line up with the item, its collision will align with it too.
    self:moveTo(self.item.x, self.item.y)
end

-- Call after handleMovement() in grabbing state.
-- We are assuming self.item was set to the grabbed item object by now.
-- Moves the item sprite relative to cursor position.
function Cursor:handleGrabbedItemMovement()
    self.item:moveTo(
        self.x,
        self.y
    )
end

-- TODO: placeItem() (with validation). set self.item = nil and go back to active state
function Cursor:placeItem()
    -- TODO: need to handle moving vs stationary item pos for saving/loading
    -- TODO: also make sure we're placing it in a valid spot, need to add mo collision shit for the pond and whatever
    -- TODO: also also, if placing near a chao and it's something it can interact with, do that!
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

-- TODO: RENAME THESE TO LIKE checkForClick() or whatever!!

-- Handles clicking on an object when active
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

-- TODO: validation n shit
-- Handle A press when holding an item
function Cursor:handleGrabbedItemClick()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:placeItem()
    end
end
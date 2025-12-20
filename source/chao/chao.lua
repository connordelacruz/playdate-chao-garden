local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Constants
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Data
-- --------------------------------------------------------------------------------
-- Filename where Chao.data is saved
local kDataFilename <const> = 'chao-data'
-- Default names to pick from when generating blank chao data
local kDefaultNames <const> = {
    'Ajax',
    'Atom',
    'Bingo',
    'Brandy',
    'Bruno',
    'Bubbles',
    'Buddy',
    'Buzzy',
    'Cash',
    'Casino',
    'Chacha',
    'Chacky',
    'Chaggy',
    'Chai',
    'Chalulu',
    'Cham',
    'Champ',
    'Chang',
    'Chaofun',
    'Chaoko',
    'Chaolin',
    'Chaorro',
    'Chaosky',
    'Chap',
    'Chapon',
    'Chappy',
    'Charon',
    'Chasm',
    'Chaz',
    'Cheng',
    'Choc',
    'Cholly',
    'Chucky',
    'Cody',
    'Cuckoo',
    'DEJIME',
    'Dash',
    'Dingy',
    'Dino',
    'Dixie',
    'Echo',
    'Edge',
    'Elvis',
    'Emmy',
    'Fuzzie',
    'Groom',
    'HITM',
    'Hiya',
    'Honey',
    'Jojo',
    'Keno',
    'Kosmo',
    'Loose',
    'Melody',
    'NAGOSHI',
    'OVER',
    'Papoose',
    'Peaches',
    'Pebbles',
    'Pinky',
    'Quartz',
    'Quincy',
    'ROSSO',
    'Rascal',
    'Rocky',
    'Rover',
    'Roxy',
    'Rusty',
    'SMILEB',
    'SOUL',
    'Spike',
    'Star',
    'Tango',
    'Tiny',
    'WOW',
    'Woody',
    'YS',
    'Zack',
    'Zippy',
}

-- --------------------------------------------------------------------------------
-- Sprite/Action Stuff
-- --------------------------------------------------------------------------------
-- Directions Chao can face
local kDown <const>  = 'down'
local kLeft <const>  = 'left'
local kUp <const>    = 'up'
local kRight <const> = 'right'
-- Actions Chao can perform at each index
local kIdle <const>  = 'idle'
local kLStep <const> = 'lStep'
local kRStep <const> = 'rStep'

-- ===============================================================================
-- Collisions
-- ===============================================================================
-- Tags that Chao should collide with
local kCollidesWithTags <const> = {
    TAGS.SCREEN_BOUNDARY,
    TAGS.GARDEN_BOUNDARY,
    TAGS.POND,
}

-- ===============================================================================
-- Chao States
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Generic with common constructor
-- --------------------------------------------------------------------------------
class('ChaoState').extends('State')

function ChaoState:init(chao)
    self.chao = chao
end

-- --------------------------------------------------------------------------------
-- Idle:
-- - Chao standing still
-- - Change states after a period of time
-- --------------------------------------------------------------------------------
local kIdleState <const> = 'idle'
class('ChaoIdleState').extends('ChaoState')

function ChaoIdleState:enter()
    self.chao:setImageFromSpritesheet(kIdle)
    -- TODO: pick an amount of time to wait before picking a state to transition to
end

function ChaoIdleState:update()
    -- TODO: pick a new state if enough time has elapsed
end

-- --------------------------------------------------------------------------------
-- Walking:
-- - Randomize angle on enter()
-- - Chao starts walking at that angle
-- - If Barrier is hit, flip angle
-- - Change states after a period of time
-- --------------------------------------------------------------------------------
local kWalkingState <const> = 'walking'
class('ChaoWalkingState').extends('ChaoState')

function ChaoWalkingState:enter()
    self.chao:randomizeAngle()
    self.chao:playWalkingAnimation()
    -- TODO: pick an amount of time to wait before picking a state to transition to
end

function ChaoWalkingState:update()
    self.chao:setImageFromWalkingAnimation()
    self.chao:handleMove()
    -- TODO: pick a new state if enough time has elapsed
end

function ChaoWalkingState:exit()
    self.chao:pauseWalkingAnimation()
end

-- ===============================================================================
-- Chao Sprite Class
-- ===============================================================================
class('Chao').extends('FSMSprite')

function Chao:init(startX, startY)
    Chao.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Data and Stats
    -- --------------------------------------------------------------------------------
    -- Set initial data
    self:initData()
    -- Attempt to load data
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)
    -- --------------------------------------------------------------------------------
    -- Spritesheet
    -- --------------------------------------------------------------------------------
    self.spritesheet = gfx.imagetable.new('images/chao/chao-idle-walk')
    -- Index starts for directions
    self.spriteDir = {
        [kDown]  = 1,
        [kLeft]  = 4,
        [kUp]    = 7,
        [kRight] = 10,
    }
    -- Index modifiers to add to direction for idle and stepping
    self.spriteAction = {
        [kIdle]  = 0,
        [kLStep] = 1,
        [kRStep] = 2,
    }
    -- Animation loop object for walking.
    -- NOTE: Loop gets updated in setAngle() to account for facing direction.
    self.walkingLoop = nil
    self:initializeWalkingAnimation()
    -- Set default image 
    self:setImage(self:spritesheetImage(kDown, kIdle))
    -- --------------------------------------------------------------------------------
    -- Collision
    -- --------------------------------------------------------------------------------
    -- TODO: tags, collisionResponse and all that
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.CHAO)
    -- --------------------------------------------------------------------------------
    -- Instance Variables
    -- --------------------------------------------------------------------------------
    -- Speed Chao moves at (px / sec)
    -- TODO: fine-tune; increase based on run stat!
    self.speed = 50
    -- Angle the Chao is facing
    self.angle = nil
    -- Cardinal direction based on self.angle
    self.direction = nil
    -- Set default to these as 270 degrees (straight down)
    self:setAngle(270)
    -- --------------------------------------------------------------------------------
    -- State
    -- --------------------------------------------------------------------------------
    self.states = {
        [kIdleState] = ChaoIdleState(self),
        [kWalkingState] = ChaoWalkingState(self),
    }
    -- TODO: DEBUGGING!!!!!!!!
    -- self:setInitialState(kIdleState)
    self:setInitialState(kWalkingState)
    -- --------------------------------------------------------------------------------
    -- Initialization
    -- --------------------------------------------------------------------------------
    self:moveTo(startX, startY)
    self:setZIndex(Z_INDEX.GARDEN_CHAO)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Save/Load/Initialize Data
-- --------------------------------------------------------------------------------

function Chao:initData()
    self.data = {
        -- Pick random default name
        name = kDefaultNames[math.random(1, #kDefaultNames)],
        -- Start with 50% mood and belly
        mood = 50,
        belly = 50,
        -- Start with all 0's in stats
        stats = {
            swim = {
                level = 0,
                progress = 0,
            },
            fly = {
                level = 0,
                progress = 0,
            },
            run = {
                level = 0,
                progress = 0,
            },
            power = {
                level = 0,
                progress = 0,
            },
            stamina = {
                level = 0,
                progress = 0,
            },
        },
    }
end

function Chao:loadData()
    if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.skipLoadingChaoData) then
        DEBUG_MANAGER:vPrint('Chao: skipLoadingChaoData set, will not load data.')
        return
    end
    local loadedData = pd.datastore.read(kDataFilename)
    -- Return if there's nothing to load
    if loadedData == nil then
        DEBUG_MANAGER:vPrint('Chao: no save data found.')
        return
    end
    DEBUG_MANAGER:vPrint('Chao: save data found. Loading data.')
    -- Iterate through saved data and update self.data accordingly.
    -- If self:initData() is called first, self.data should have default values.
    -- Setting data this way allows for forwards compatibility. If keys are missing from
    -- loaded data, then the inital data set won't get overwritten here.
    for k,v in pairs(loadedData) do
        self.data[k] = v
    end
end

function Chao:saveData()
    if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.skipSavingChaoData) then
        DEBUG_MANAGER:vPrint('Chao: skipSavingChaoData set, will not save data.')
        return
    end
    DEBUG_MANAGER:vPrint('Chao:saveData() called. self.data:')
    DEBUG_MANAGER:vPrintTable(self.data)
    pd.datastore.write(self.data, kDataFilename)
end

-- --------------------------------------------------------------------------------
-- Data Setters
-- --------------------------------------------------------------------------------

function Chao:setName(newName)
    self.data.name = newName
end

-- --------------------------------------------------------------------------------
-- Image Functions
-- --------------------------------------------------------------------------------

-- Set sprite's image based on specified action and calculated direction.
function Chao:setImageFromSpritesheet(action)
    self:setImage(
        self:spritesheetImage(
            self.direction,
            action
        )
    )
end

-- Returns an image from self.spritesheet based on the direction and action.
function Chao:spritesheetImage(dir, action)
    local dirIndex = self.spriteDir[dir]
    local actionIndex = self.spriteAction[action]
    return self.spritesheet[dirIndex + actionIndex]
end

function Chao:initializeWalkingAnimation()
    self.walkingLoop = gfx.animation.loop.new(500, self.spritesheet, true)
    -- Default to paused
    self.walkingLoop.paused = true
end

function Chao:updateWalkingAnimation()
    local startIndex = self.spriteDir[self.direction] + self.spriteAction[kLStep]
    local endIndex = self.spriteDir[self.direction] + self.spriteAction[kRStep]
    self.walkingLoop.startFrame = startIndex
    self.walkingLoop.endFrame = endIndex
end

function Chao:playWalkingAnimation()
    self.walkingLoop.paused = false
end

function Chao:pauseWalkingAnimation()
    self.walkingLoop.paused = true
end

function Chao:setImageFromWalkingAnimation()
    self:setImage(self.walkingLoop:image())
end

-- --------------------------------------------------------------------------------
-- Angle/Direction
-- --------------------------------------------------------------------------------

-- Set angle and calculate cardinal direction.
function Chao:setAngle(angle)
    self.angle = angle % 360
    self.direction = self:angleToDirection()
    -- Update walking animation loop start/end frames
    self:updateWalkingAnimation()
end

-- Returns a cardinal direction constant based on self.angle.
function Chao:angleToDirection()
    local direction = kRight
    if self.angle >= 45 and self.angle < 135 then
        direction = kUp
    elseif self.angle >= 135 and self.angle < 225 then
        direction = kLeft
    elseif self.angle >= 225 and self.angle < 315 then
        direction = kDown
    end
    return direction
end

-- Set a random angle.
function Chao:randomizeAngle()
    self:setAngle(math.random(0, 360))
end

-- Flip angle's x direction (e.g. "bounce" off vertical boundary)
function Chao:flipXDirection()
    self:setAngle(180 - self.angle)
end

-- Flip angle's y direction (e.g. "bounce" off horizontal boundary)
function Chao:flipYDirection()
    self:setAngle(360 - self.angle)
end

-- --------------------------------------------------------------------------------
-- Collision
-- --------------------------------------------------------------------------------

function Chao:shouldCollideWithTag(tag)
    for i=1,#kCollidesWithTags do
        local collidesWithTag = kCollidesWithTags[i]
        if collidesWithTag == tag then
            return true
        end
    end
    return false
end

function Chao:collisionResponse(other)
    -- Overlap by default
    local collideType = gfx.sprite.kCollisionTypeOverlap
    if self:shouldCollideWithTag(other:getTag()) then
        collideType = gfx.sprite.kCollisionTypeFreeze
    end
    return collideType
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

-- Returns target x,y coordinates calculated based on angle and speed.
function Chao:getTargetCoordinates()
    local rad = math.rad(self.angle)
    local targetX = self.x + self.speed * math.cos(rad) * DELTA_TIME
    local targetY = self.y + self.speed * -math.sin(rad) * DELTA_TIME
    return targetX, targetY
end

-- Move walking Chao. Handles wall collisions.
-- Called on update() in walking state
function Chao:handleMove()
    local targetX, targetY = self:getTargetCoordinates()
    local _, _, collisions, _ = self:moveWithCollisions(targetX, targetY)
    for i=1, #collisions do
        local collision = collisions[i]
        if collision.type ~= gfx.sprite.kCollisionTypeOverlap then
            if collision.normal.x ~= 0 then
                self:flipXDirection()
            end
            if collision.normal.y ~= 0 then
                self:flipYDirection()
            end
        end
    end
end
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
-- TODO: load this from file when needed instead?
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
-- Sounds
-- --------------------------------------------------------------------------------
local kSounds <const> = {
    step = pd.sound.sampleplayer.new('sounds/chao/step.wav'),
    pet = pd.sound.sampleplayer.new('sounds/chao/pet.wav'),
    boost = pd.sound.sampleplayer.new('sounds/chao/boost.wav'),
}

-- --------------------------------------------------------------------------------
-- Sprite/Action Stuff
-- --------------------------------------------------------------------------------
-- Directions Chao can face
local kDown <const>  = 'down'
local kLeft <const>  = 'left'
local kUp <const>    = 'up'
local kRight <const> = 'right'
-- Walk/Idle: Actions Chao can perform at each index
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
-- State name constants
-- --------------------------------------------------------------------------------
local kIdleState <const> = 'idle'
local kWalkingState <const> = 'walking'
local kPettingState <const> = 'pet'

-- --------------------------------------------------------------------------------
-- Generic with common constructor and default props
-- --------------------------------------------------------------------------------
class('ChaoState', {
    -- Min/max time in seconds before picking a new state (if applicable)
    minDuration = 3,
    maxDuration = 7,
    -- States we can transition to from this state
    nextStateOptions = {},
    -- Whether the Chao can be pet in this state
    -- TODO: make this more robust? Per-state click()? Also handle eating
    canPet = true,
    -- Whether the Chao can accept food in this state
    canEat = true,
}).extends('State')

function ChaoState:init(chao)
    self.chao = chao
    -- Initialize transitionAfter (this should get updated on enter())
    self.transitionAfter = pd.getCurrentTimeMilliseconds()
end

-- Helper to calculate timestamp after which a new state should be selected.
-- If duration is not specified, will randomly pick between minDuration and maxDuration.
function ChaoState:changeStateTimestamp(duration)
    local currentTime = pd.getCurrentTimeMilliseconds()
    if duration == nil then
        duration = math.random(self.minDuration * 1000, self.maxDuration * 1000)
    end
    return currentTime + duration
end

-- Set self.transitionAfter to return value of changeStateTimestamp().
-- Takes optional duration parameter (ms)
function ChaoState:setDuration(duration)
    self.transitionAfter = self:changeStateTimestamp(duration)
end

-- Returns state name to transition to if duration is up,
-- or false if either duration is not up or nextStateOptions is empty.
function ChaoState:transitionToState()
    if #self.nextStateOptions == 0 or pd.getCurrentTimeMilliseconds() < self.transitionAfter then
        return false
    else
        return self.nextStateOptions[math.random(1, #self.nextStateOptions)]
    end
end

-- Change Chao state if duration is up.
function ChaoState:changeStateIfPastDuration()
    local nextState = self:transitionToState()
    if nextState then
        self.chao:setState(nextState)
    end
end

-- --------------------------------------------------------------------------------
-- Idle:
-- - Chao standing or sitting still
-- - Change states after a period of time
-- --------------------------------------------------------------------------------
class('ChaoIdleState', {
    nextStateOptions = {
        kWalkingState,
    },
}).extends('ChaoState')

function ChaoIdleState:enter()
    -- Randomly sit or stand idle
    -- TODO: make separate sitting state that extends ChaoIdleState?
    if math.random(0, 1) == 1 then
        self.chao:setImageFromSitSpritesheet()
    else
        self.chao:setImageFromWalkIdleSpritesheet(kIdle)
    end
    self:setDuration()
end

function ChaoIdleState:update()
    self:changeStateIfPastDuration()
end

-- --------------------------------------------------------------------------------
-- Walking:
-- - Randomize angle on enter()
-- - Chao starts walking at that angle
-- - If Barrier is hit, flip angle
-- - Change states after a period of time
-- --------------------------------------------------------------------------------
class('ChaoWalkingState', {
    minDuration = 5,
    maxDuration = 10,
    nextStateOptions = {
        kIdleState,
        kWalkingState,
    },
}).extends('ChaoState')

function ChaoWalkingState:enter()
    self.chao:randomizeAngle()
    self.chao:playWalkingAnimation()
    self:setDuration()
end

function ChaoWalkingState:update()
    self.chao:takeStep()
    self.chao:handleMove()
    self:changeStateIfPastDuration()
end

function ChaoWalkingState:exit()
    self.chao:pauseWalkingAnimation()
end

-- --------------------------------------------------------------------------------
-- Pet:
-- - Set angle to 270
-- - Play petting animation
-- - Increase mood 
-- - Transition to idle state once animation completes
--
-- NOTE:
-- - In Chao:click(), make sure to pass a reference to the cursor to the instance of this state
-- --------------------------------------------------------------------------------
class('ChaoPettingState', {
    -- Not that this should happen since the cursor is locked, but whatever:
    canPet = false,
    canEat = false,
}).extends('ChaoState')

function ChaoPettingState:enter()
    self.chao:setAngle(270)
    self.chao:pet()
end

-- TODO: do this for a fixed duration
function ChaoPettingState:update()
    self.chao:setImageFromPettingAnimation()
    -- TODO: use kSounds.pet:setFinishCallback() to handle this instead
    if self.chao:hasPettingAnimationFinished() then
        self.chao:setState(kIdleState)
    end
end

function ChaoPettingState:exit()
    -- TODO: !!!! UPDATE STATUS PANEL !!!!
    -- TODO: COOLDOWN!!! separate boost state with animation
    self.chao:boostMood()
    -- TODO: see if this is necessary
    self.chao:pausePettingAnimation()
    if self.cursor ~= nil and self.cursor.className == 'Cursor' then
        self.cursor:enable()
    end
end

-- ===============================================================================
-- Chao Sprite Class
-- ===============================================================================
class('Chao').extends('FSMSprite')

function Chao:init(startX, startY)
    Chao.super.init(self)
    -- ================================================================================
    -- Data and Stats
    -- ================================================================================
    -- Set initial data
    self:initData()
    -- Attempt to load data
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)
    -- ================================================================================
    -- Spritesheets/Animations + Sound Effects
    -- ================================================================================
    -- --------------------------------------------------------------------------------
    -- Walking/Standing
    -- --------------------------------------------------------------------------------
    self.walkIdleSpritesheet = gfx.imagetable.new('images/chao/chao-idle-walk')
    -- Index starts for directions
    self.walkIdleSpriteDir = {
        [kDown]  = 1,
        [kLeft]  = 4,
        [kUp]    = 7,
        [kRight] = 10,
    }
    -- Index modifiers to add to direction for idle and stepping
    self.walkIdleSpriteAction = {
        [kIdle]  = 0,
        [kLStep] = 1,
        [kRStep] = 2,
    }
    -- Animation loop object for walking.
    -- NOTE: Loop gets updated in setAngle() to account for facing direction.
    self.walkingLoop = nil
    self:initializeWalkingAnimation()
    -- Set to true when step sound has been played on frame 1.
    -- Set to false again once animation has moved past frame 1.
    self.stepSoundPlayed = false
    -- --------------------------------------------------------------------------------
    -- Sitting
    -- --------------------------------------------------------------------------------
    self.sitSpritesheet = gfx.imagetable.new('images/chao/chao-sit')
    -- Indexes for facing directions.
    -- NOTE: No sprite for facing up, probably cuz it looks weird.
    self.sitSpriteDir = {
        [kDown] = 1,
        [kLeft] = 2,
        [kRight] = 3,
    }
    -- --------------------------------------------------------------------------------
    -- Being Pet
    -- --------------------------------------------------------------------------------
    self.pettingSpritesheet = gfx.imagetable.new('images/chao/chao-pet')
    -- Animation loop for petting.
    self.pettingLoop = nil
    self:initializePettingAnimation()
    -- --------------------------------------------------------------------------------
    -- Default image 
    -- --------------------------------------------------------------------------------
    self.defaultImage = self:walkIdleSpritesheetImage(kDown, kIdle)
    self:setImage(self.defaultImage)
    -- ================================================================================
    -- Collision
    -- ================================================================================
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.CHAO)
    -- ================================================================================
    -- Instance Variables
    -- ================================================================================
    -- Speed Chao moves at (px / sec)
    -- TODO: increase based on run stat?
    self.speed = 20
    -- Angle the Chao is facing
    self.angle = nil
    -- Cardinal direction based on self.angle
    self.direction = nil
    -- Set default to these as 270 degrees (straight down)
    self:setAngle(270)
    -- ================================================================================
    -- State
    -- ================================================================================
    self.states = {
        [kIdleState] = ChaoIdleState(self),
        [kWalkingState] = ChaoWalkingState(self),
        [kPettingState] = ChaoPettingState(self),
    }
    self:setInitialState(kIdleState)
    -- When game starts, explicitly set duration of idle state
    self.state:setDuration(2000)
    -- ================================================================================
    -- Initialization
    -- ================================================================================
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
-- Mood Functions
-- --------------------------------------------------------------------------------
-- TODO: logic for decreasing mood over time

-- Set mood value. Ensures value is between 0 and 100.
function Chao:setMood(val)
    if val < 0 then
        val = 0
    elseif val > 100 then
        val = 100
    end
    self.data.mood = val
end

-- Boost mood by 10% (up to 100%)
function Chao:boostMood()
    if self.data.mood < 100 then
        self:setMood(self.data.mood + 10)
    end
end

-- --------------------------------------------------------------------------------
-- Walk/Idle Image + Sound Functions
-- --------------------------------------------------------------------------------

-- From the walking/idle spritesheet, set sprite's image based on specified action and calculated direction.
function Chao:setImageFromWalkIdleSpritesheet(action)
    self:setImage(
        self:walkIdleSpritesheetImage(
            self.direction,
            action
        )
    )
end

-- Returns an image from self.spritesheet based on the direction and action.
function Chao:walkIdleSpritesheetImage(dir, action)
    local dirIndex = self.walkIdleSpriteDir[dir]
    local actionIndex = self.walkIdleSpriteAction[action]
    return self.walkIdleSpritesheet[dirIndex + actionIndex]
end

-- Initialize self.walkingLoop.
function Chao:initializeWalkingAnimation()
    self.walkingLoop = gfx.animation.loop.new(300, self.walkIdleSpritesheet, true)
    -- Default to paused
    self.walkingLoop.paused = true
end

-- Update self.walkingLoop, accounting for self.direction.
function Chao:updateWalkingAnimation()
    -- Build animation (insert idle frame between steps)
    local newFrames = {
        self:walkIdleSpritesheetImage(self.direction, kLStep),
        self:walkIdleSpritesheetImage(self.direction, kIdle),
        self:walkIdleSpritesheetImage(self.direction, kRStep),
        self:walkIdleSpritesheetImage(self.direction, kIdle),
    }
    self.walkingLoop:setImageTable(newFrames)
end

-- Shorthand to play loop.
function Chao:playWalkingAnimation()
    self.walkingLoop.paused = false
end

-- Shorthand to pause loop.
function Chao:pauseWalkingAnimation()
    self.walkingLoop.paused = true
end

-- Set sprite image to self.walkingLoop's current image.
function Chao:setImageFromWalkingAnimation()
    self:setImage(self.walkingLoop:image())
end

-- If step sound hasn't been played on frame 1 this loop, play it.
function Chao:handleStepSound()
    if self.walkingLoop.frame == 1 then
        if not self.stepSoundPlayed then
            self.stepSoundPlayed = true
            kSounds.step:play()
        end
    else
        -- Reset this after frame 1 so it plays next loop
        self.stepSoundPlayed = false
    end
end

-- Update image from walking animation and handle step sound effect.
function Chao:takeStep()
    self:setImageFromWalkingAnimation()
    self:handleStepSound()
end

-- --------------------------------------------------------------------------------
-- Sit Image Functions
-- --------------------------------------------------------------------------------

-- NOTE: Since there's no upward-facing sitting sprite, will default to standing image if self.direction == kUp
function Chao:setImageFromSitSpritesheet()
    self:setImage(
        self:sitSpritesheetImage(self.direction)
    )
end

-- NOTE: kUp is not a valid index, so will default to standing in that case.
function Chao:sitSpritesheetImage(dir)
    if dir ~= kUp then
        return self.sitSpritesheet[self.sitSpriteDir[dir]]
    else
        return self:walkIdleSpritesheetImage(dir, kIdle)
    end
end

-- --------------------------------------------------------------------------------
-- Pet Image + Sound Functions
-- --------------------------------------------------------------------------------

function Chao:initializePettingAnimation()
    -- Insert upright frame in between leaning frames and repeat animation twice
    local pettingFrames = {
        self.pettingSpritesheet[1],
        self.pettingSpritesheet[2],
        self.pettingSpritesheet[1],
        self.pettingSpritesheet[3],
    }
    -- TODO: figure out duration
    self.pettingLoop = gfx.animation.loop.new(500, pettingFrames, false)
    self.pettingLoop.paused = true
end

-- TODO: keeps getting stuck in animation! Find a better way to do this cuz it's looping foreverrrr
function Chao:startPettingAnimation()
    self.pettingLoop.frame = 1
    self.pettingLoop.paused = false
    self.pettingLoop.shouldLoop = false
end

-- TODO: is this necessary for non-looping?
function Chao:pausePettingAnimation()
    self.pettingLoop.paused = true
end

-- TODO: this is INSANELY inconsistent
function Chao:hasPettingAnimationFinished()
    -- For non-looping animations, isValid() returns false if it's passed the final frame
    return not self.pettingLoop:isValid()
end

function Chao:setImageFromPettingAnimation()
    self:setImage(self.pettingLoop:image())
end

function Chao:playPetSound()
    kSounds.pet:play()
end

-- Start petting animation and play sound effect.
function Chao:pet()
    self:startPettingAnimation()
    self:playPetSound()
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

-- --------------------------------------------------------------------------------
-- Cursor Interactions
-- --------------------------------------------------------------------------------

function Chao:click(cursor)
    -- TODO: Check if cursor is holding food?
    if self.state.canPet then
        self:setState(kPettingState)
        -- Pass reference to cursor for syncing animation
        self.state.cursor = cursor
        -- Set cursor state to petting
        cursor:pet(self)
    end
end
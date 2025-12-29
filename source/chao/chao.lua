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
-- Eating: Frame names for animation
local kHold <const> = 'hold'
local kChomp1 <const> = 'chomp1'
local kChomp2 <const> = 'chomp2'
-- -------------------------------------------------------------------------------
-- Collisions
-- -------------------------------------------------------------------------------
-- Tags that Chao should collide with
local kCollidesWithTags <const> = {
    TAGS.SCREEN_BOUNDARY,
    TAGS.GARDEN_BOUNDARY,
    TAGS.POND,
}
-- -------------------------------------------------------------------------------
-- Mood
-- -------------------------------------------------------------------------------
-- Duration in seconds of mood cooldown (so you can't just spam petting)
local kMoodBoostCooldown <const> = 10
-- Duration in seconds of mood drain timer
-- TODO: Once fruits and minigames are implemented, decide if this is too short/long
-- TODO: Once weeds are implemented, maybe decrease duration proportionally to weeds?
local kMoodDrainTimerDuration <const> = 45
-- -------------------------------------------------------------------------------
-- Belly
-- -------------------------------------------------------------------------------
-- Duration in seconds of belly drain timer
-- TODO: Decrease? Or scale drain duration/value based on current state?
local kBellyDrainTimerDuration <const> = 45
-- -------------------------------------------------------------------------------
-- Stat indexes
-- -------------------------------------------------------------------------------
local kStatIndexes <const> = {
    'swim', 'fly', 'run', 'power', 'stamina',
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
local kMoodBoostState <const> = 'mood-boost'
local kEatingState <const> = 'eating'

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
    canPet = true,
    -- Whether the Chao can accept holdable items in this state
    canAcceptItems = true,
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
    canAcceptItems = false,
}).extends('ChaoState')

function ChaoPettingState:enter()
    self.chao:setAngle(270)
    self.chao:pet()
    -- Pause mood drain
    self.chao:pauseMoodDrainTimer()
end

function ChaoPettingState:update()
    self.chao:setImageFromPettingAnimation()
end

function ChaoPettingState:exit()
    self.chao:pausePettingAnimation()
    -- Restart mood drain timer
    self.chao:restartMoodDrainTimer()
    -- Re-enable cursor
    if self.cursor ~= nil then
        self.cursor:enable()
    end
end

-- --------------------------------------------------------------------------------
-- Mood Boost:
-- - Play happy animation
-- - Boost mood
--
-- NOTE:
-- - Should transition to this from petting state, but only when not in cooldown
-- --------------------------------------------------------------------------------
class('ChaoMoodBoostState', {
    canPet = false,
    canAcceptItems = false,
}).extends('ChaoState')

function ChaoMoodBoostState:enter()
    self.chao:setAngle(270)
    self.chao:playHappyAnimation()
    self.chao:boostMood()
    self.timer = pd.timer.new(1000, function ()
        self.chao:setState(kIdleState)
    end)
end

function ChaoMoodBoostState:update()
    self.chao:setImageFromHappyAnimation()
end

function ChaoMoodBoostState:exit()
    if self.timer ~= nil then
        self.timer:remove()
    end
    self.chao:pauseHappyAnimation()
end

-- --------------------------------------------------------------------------------
-- Eating:
-- - Update and unpause eating animation
-- - Move item relative to facing direction
-- - Play eating animation + boost sound, gradually shrink item
-- - Apply stat changes 
-- - Delete item
-- - Switch to idle state after delay
-- --------------------------------------------------------------------------------
class('ChaoEatingState', {
    canPet = false,
    canAcceptItems = false,
}).extends('ChaoState')

function ChaoEatingState:enter()
    self.chao:eat()
    local eatingDuration = 2000
    pd.timer.performAfterDelay(eatingDuration, function ()
        self.chao:setState(kIdle)
    end)
    -- Shrinking animation for item
    self.itemAnimator = gfx.animator.new(eatingDuration, 1.0, 0.0)
end

function ChaoEatingState:update()
    self.chao:setImageFromEatingAnimation()
    self.chao.item:setScale(self.itemAnimator:currentValue())
end

function ChaoEatingState:exit()
    self.chao:pauseEatingAnimation()
    self.chao:removeItem()
end

-- ===============================================================================
-- Chao Sprite Class
-- ===============================================================================
class('Chao').extends('FSMSprite')

function Chao:init(gardenScene, startX, startY)
    Chao.super.init(self)
    self.scene = gardenScene
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
    -- Happy/Mood Boost
    -- --------------------------------------------------------------------------------
    self.happySpritesheet = gfx.imagetable.new('images/chao/chao-happy')
    -- Animation loop for happy chao.
    self.happyLoop = nil
    self:initializeHappyAnimation()
    -- --------------------------------------------------------------------------------
    -- Eating
    -- --------------------------------------------------------------------------------
    self.eatingSpritesheet = gfx.imagetable.new('images/chao/chao-eat')
    -- Index starts for directions
    self.eatingSpriteDir = {
        [kLeft] = 1,
        [kRight] = 6,
    }
    -- Index modifiers to add to direction for eating animation frames
    self.eatingSpriteAction = {
        [kHold] = 0,
        [kChomp1] = 1,
        [kChomp2] = 2,
    }
    -- Animation loop for eating.
    self.eatingLoop = nil
    self:initializeEatingAnimation()
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
    -- --------------------------------------------------------------------------------
    -- Movement
    -- --------------------------------------------------------------------------------
    -- Speed Chao moves at (px / sec)
    self.speed = 20
    -- --------------------------------------------------------------------------------
    -- Items
    -- --------------------------------------------------------------------------------
    -- Item Chao is currently holding
    self.item = nil
    -- --------------------------------------------------------------------------------
    -- Angle
    -- --------------------------------------------------------------------------------
    -- Angle the Chao is facing
    self.angle = nil
    -- Cardinal direction based on self.angle
    self.direction = nil
    -- Set default to these as 270 degrees (straight down)
    self:setAngle(270)
    -- --------------------------------------------------------------------------------
    -- Mood
    -- --------------------------------------------------------------------------------
    -- Timestamp of last mood boost from petting. Used for cooldown calculation.
    -- Default to negative of cooldown so first pet is always a boost.
    self.lastMoodBoostTimestamp = kMoodBoostCooldown * -1000
    -- Initialize self.moodDrainTimer.
    self:initializeMoodDrainTimer()
    -- --------------------------------------------------------------------------------
    -- Belly
    -- --------------------------------------------------------------------------------
    -- Initialize self.bellyDrainTimer.
    self:initializeBellyDrainTimer()
    -- ================================================================================
    -- State
    -- ================================================================================
    self.states = {
        [kIdleState] = ChaoIdleState(self),
        [kWalkingState] = ChaoWalkingState(self),
        [kPettingState] = ChaoPettingState(self),
        [kMoodBoostState] = ChaoMoodBoostState(self),
        [kEatingState] = ChaoEatingState(self),
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

-- ================================================================================
-- Chao Data
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Save/Load/Initialize Data
-- --------------------------------------------------------------------------------

function Chao:initData()
    self.data = {
        -- Pick random default name
        name = self:selectRandomDefaultName(),
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

function Chao:selectRandomDefaultName()
    local names <const> = json.decodeFile('chao/default-names.json')
    return names[math.random(1, #names)]
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
-- Stat Setters
-- --------------------------------------------------------------------------------

-- Add to a stat's progress bar, level up if progress exceeds 100.
-- Set skipUpdateUI to true if you don't want to update UI yet.
-- Returns true if stat leveled up.
function Chao:addToStatProgress(statIndex, addProgress, skipUpdateUI)
    local statData = self.data.stats[statIndex]
    local newProgress = statData.progress + addProgress
    local levelUp = newProgress >= 100
    -- Level up if progress > 100
    if levelUp then
        statData.level += newProgress // 100
        newProgress = newProgress % 100
    end
    -- Progress cannot go below 0
    if newProgress < 0 then
        newProgress = 0
    end
    statData.progress = newProgress
    -- Update UI, redraw if level up text changed
    if skipUpdateUI ~= true then
        self.scene.statusPanel:updateStatUI(statIndex)
        self.scene.statusPanel:updateUI(levelUp)
    end
    -- Logging
    DEBUG_MANAGER:vPrint('Chao: updated ' .. statIndex .. ': level=' .. statData.level .. ', progress=' .. statData.progress)

    return levelUp
end

-- ================================================================================
-- Angle, Collisions, Walking, and Idling
-- ================================================================================

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

-- Returns kLeft if angle is between 90-269.
-- Returns kRIght if angle is between 270-360 or 0-89.
function Chao:angleToLeftOrRight()
    local direction = kRight
    if self.angle >= 90 and self.angle < 270 then
        direction = kLeft
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

-- ================================================================================
-- Mood Mechanics, Petting, and Boosting
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Mood Functions
-- --------------------------------------------------------------------------------

-- Set mood value. Ensures value is between 0 and 100.
-- Set skipUpdateUI to true if you don't want to update UI yet.
function Chao:setMood(val, skipUpdateUI)
    if val < 0 then
        val = 0
    elseif val > 100 then
        val = 100
    end
    self.data.mood = val
    -- Update status panel UI
    if skipUpdateUI ~= true then
        self.scene.statusPanel:updateMood()
        self.scene.statusPanel:updateUI()
    end
end

-- Add a value to mood.
function Chao:addToMood(val, skipUpdateUI)
    self:setMood(self.data.mood + val, skipUpdateUI)
end

-- Update timestamp of last time mood was boosted.
-- (Also resets when Chao is pet to prevent spamming).
function Chao:updateLastMoodBoostTimestamp()
    self.lastMoodBoostTimestamp = pd.getCurrentTimeMilliseconds()
end

-- Boost mood by 10% (up to 100%) and play happy sound
function Chao:boostMood()
    if self.data.mood < 100 then
        self:addToMood(10)
        -- Update timestamp for cooldown calculations
        self:updateLastMoodBoostTimestamp()
        -- Sound cue
        self:playHappySound()
    end
end

-- Drain mood by 10%.
function Chao:drainMood()
    if self.data.mood > 0 then
        self:addToMood(-10)
    end
end

-- Returns true if mood boost cooldown is done, false otherwise.
function Chao:isMoodBoostCooldownComplete()
    local timeDiff = pd.getCurrentTimeMilliseconds() - self.lastMoodBoostTimestamp
    return timeDiff >= kMoodBoostCooldown * 1000
end

-- Returns true if mood boost cooldown is complete and current mood is > 100.
function Chao:canBoostMood()
    return self.data.mood < 100 and self:isMoodBoostCooldownComplete()
end

-- Initialize mood drain timer.
function Chao:initializeMoodDrainTimer()
    self.moodDrainTimer = pd.timer.new(kMoodDrainTimerDuration * 1000, function ()
        DEBUG_MANAGER:vPrint('Chao: Mood drain timer ended, draining mood and restarting timer.')
        -- Drain mood
        self:drainMood()
        -- Restart timer
        self:restartMoodDrainTimer()
    end)
    self.moodDrainTimer.repeats = true
end

function Chao:pauseMoodDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Pausing mood drain timer.')
    self.moodDrainTimer:pause()
end

function Chao:playMoodDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Starting mood drain timer.')
    self.moodDrainTimer:start()
end

function Chao:restartMoodDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Restarting mood drain timer.')
    self.moodDrainTimer:reset()
    self.moodDrainTimer:start()
end

-- NOTE: Not sure if this will ever get used, but might as well add it for completeness.
-- If this does get implemented, make sure to add nil checks to above functions.
function Chao:removeMoodDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Removing mood drain timer.')
    self.moodDrainTimer:remove()
end

-- --------------------------------------------------------------------------------
-- Pet Animations + Sound Functions
-- --------------------------------------------------------------------------------

function Chao:initializePettingAnimation()
    -- Insert upright frame in between leaning frames and repeat animation twice
    local pettingFrames = {
        self.pettingSpritesheet[1],
        self.pettingSpritesheet[2],
        self.pettingSpritesheet[1],
        self.pettingSpritesheet[3],
    }
    self.pettingLoop = gfx.animation.loop.new(250, pettingFrames, true)
    self.pettingLoop.paused = true
end

function Chao:playPettingAnimation()
    self.pettingLoop.paused = false
end

function Chao:pausePettingAnimation()
    self.pettingLoop.paused = true
end

function Chao:setImageFromPettingAnimation()
    self:setImage(self.pettingLoop:image())
end

-- Set callback to switch Chao state when pet sound finishes.
function Chao:setPetSoundFinishCallback()
    kSounds.pet:setFinishCallback(function ()
        if self:canBoostMood() then
            DEBUG_MANAGER:vPrint('Chao: Boosting mood')
            self:setState(kMoodBoostState)
        else
            DEBUG_MANAGER:vPrint('Chao: Mood cannot be boosted')
            self:setState(kIdleState)
        end
        -- Regardless, update last mood boost timer.
        self:updateLastMoodBoostTimestamp()
    end)
end

function Chao:playPetSound()
    kSounds.pet:play()
end

-- Start petting animation and play sound effect.
function Chao:pet()
    self:playPettingAnimation()
    self:setPetSoundFinishCallback()
    self:playPetSound()
end

-- --------------------------------------------------------------------------------
-- Cursor Click
-- --------------------------------------------------------------------------------

function Chao:click(cursor)
    if self.state.canPet then
        self:setState(kPettingState)
        -- Pass reference to cursor for syncing animation
        self.state.cursor = cursor
        -- Set cursor state to petting
        cursor:pet(self)
    end
end

-- --------------------------------------------------------------------------------
-- Happy Chao Animation + Sound Functions
-- --------------------------------------------------------------------------------

function Chao:initializeHappyAnimation()
    self.happyLoop = gfx.animation.loop.new(250, self.happySpritesheet, true)
    self.happyLoop.paused = true
end

function Chao:playHappyAnimation()
    self.happyLoop.paused = false
end

function Chao:pauseHappyAnimation()
    self.happyLoop.paused = true
end

function Chao:setImageFromHappyAnimation()
    self:setImage(self.happyLoop:image())
end

function Chao:playHappySound()
    kSounds.boost:play()
end

-- ================================================================================
-- Item Holding + Eating Mechanics
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Belly Functions
-- --------------------------------------------------------------------------------

-- Set belly value. Ensure value is between 0 and 100.
-- Set skipUpdateUI to true if you don't want to update UI yet.
function Chao:setBelly(val, skipUpdateUI)
    if val < 0 then
        val = 0
    elseif val > 100 then
        val = 100
    end
    self.data.belly = val
    -- Update status panel UI
    if skipUpdateUI ~= true then
        self.scene.statusPanel:updateBelly()
        self.scene.statusPanel:updateUI()
    end
end

-- Add a value to belly.
function Chao:addToBelly(val, skipUpdateUI)
    self:setBelly(self.data.belly + val, skipUpdateUI)
end

-- Drain belly by 10%.
function Chao:drainBelly()
    if self.data.belly > 0 then
        self:addToBelly(-10)
    end
end

-- Returns true if belly is full.
function Chao:isBellyFull()
    return self.data.belly >= 100
end

-- Initialize belly drain timer.
function Chao:initializeBellyDrainTimer()
    self.bellyDrainTimer = pd.timer.new(kBellyDrainTimerDuration * 1000, function ()
        DEBUG_MANAGER:vPrint('Chao: Belly drain timer ended, draining belly and restarting timer.')
        -- Drain belly
        self:drainBelly()
        -- Restart timer
        self:restartBellyDrainTimer()
    end)
    self.bellyDrainTimer.repeats = true
end

function Chao:pauseBellyDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Pausing belly drain timer.')
    self.bellyDrainTimer:pause()
end

function Chao:playBellyDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Starting belly drain timer.')
    self.bellyDrainTimer:start()
end

function Chao:restartBellyDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Restarting belly drain timer.')
    self.bellyDrainTimer:reset()
    self.bellyDrainTimer:start()
end

-- NOTE: Not sure if this will ever get used, but might as well add it for completeness.
-- If this does get implemented, make sure to add nil checks to above functions.
function Chao:removeBellyDrainTimer()
    DEBUG_MANAGER:vPrint('Chao: Removing belly drain timer.')
    self.bellyDrainTimer:remove()
end

-- --------------------------------------------------------------------------------
-- Item Holding Functions
-- --------------------------------------------------------------------------------

-- Returns true if Chao can accept items in its current state.
function Chao:canAcceptItems()
    return self.state.canAcceptItems
end

-- Set self.item and switch states based on item type.
function Chao:giveItem(item)
    self.item = item
    if item.isEdible then
        -- TODO: check if belly too full, drop item (in valid spot, updating last valid), play animation
        self:setState(kEatingState)
        DEBUG_MANAGER:vPrint('Chao: given edible item.')
    end
    -- TODO: implement interactive items that aren't food + fallback for possible edge cases?
end

-- Remove current item.
function Chao:removeItem()
    self.item:delete()
    self.item = nil
end

-- --------------------------------------------------------------------------------
-- Eating Functions
-- --------------------------------------------------------------------------------

-- Update and play eating animation, play eating sound, move item.
function Chao:eat()
    local direction = self.item.x < self.x and kLeft or kRight
    self:updateEatingAnimation(direction)
    self:moveItemForEatingAnimation(direction)
    self:playEatingAnimation()
    self:playEatingSound()
    -- TODO: figure out level up sound
    -- TODO: use animator to increment stats in chunks??
    local levelUp = self:addStatsFromItem()
end

-- Move self.item to a position for eating animation based on direction.
function Chao:moveItemForEatingAnimation(direction)
    local halfWidth = self.width / 2
    if direction == kRight then
        self.item:moveTo(self.x + halfWidth, self.y)
    else
        self.item:moveTo(self.x - halfWidth, self.y)
    end
end

-- --------------------------------------------------------------------------------
-- Updating Stats from Item
-- --------------------------------------------------------------------------------

-- Update stat progress from currently held item.
-- Returns true if one or more stats levelled up.
function Chao:addStatsFromItem()
    -- Shouldn't hit this, but just in case, don't bother if item.attributes not set.
    if self.item == nil or self.item.attributes == nil then
        return
    end
    local attributes = self.item.attributes
    -- Mood/belly
    if type(attributes.mood) == 'number' then
        self:addToMood(10 * attributes.mood, true)
        self:restartMoodDrainTimer()
    end
    if type(attributes.belly) == 'number' then
        self:addToBelly(10 * attributes.belly, true)
        self:restartBellyDrainTimer()
    end
    -- Stat progress
    local levelUp = false
    for i=1,#kStatIndexes do
        local statIndex = kStatIndexes[i]
        if attributes[statIndex] ~= nil then
            if type(attributes[statIndex]) == 'number' then
                levelUp = levelUp or self:addToStatProgress(statIndex, 10 * attributes[statIndex], true)
            end
        end
    end

    -- Update UI
    self.scene.statusPanel:updateMood()
    self.scene.statusPanel:updateBelly()
    self.scene.statusPanel:updateStats()
    self.scene.statusPanel:updateUI(levelUp)

    return levelUp
end

-- --------------------------------------------------------------------------------
-- Eating Animation + Sound Functions
-- --------------------------------------------------------------------------------

-- Initialize self.eatingLoop.
function Chao:initializeEatingAnimation()
    self.eatingLoop = gfx.animation.loop.new(200, self.eatingSpritesheet, true)
    self.eatingLoop.paused = true
end

-- Update self.eatingLoop, accounting for direction.
function Chao:updateEatingAnimation(direction)
    -- Only have sprites for left and right, so convert current angle to that.
    if direction == nil then
        direction = self:angleToLeftOrRight()
    end
    self.eatingLoop.startFrame = self.eatingSpriteDir[direction] + self.eatingSpriteAction[kChomp1]
    self.eatingLoop.endFrame = self.eatingSpriteDir[direction] + self.eatingSpriteAction[kChomp2]
end

function Chao:playEatingAnimation()
    self.eatingLoop.paused = false
end

function Chao:pauseEatingAnimation()
    self.eatingLoop.paused = true
end

function Chao:setImageFromEatingAnimation()
    self:setImage(self.eatingLoop:image())
end

-- Play boost sound 3 times
function Chao:playEatingSound()
    kSounds.boost:play(3)
end

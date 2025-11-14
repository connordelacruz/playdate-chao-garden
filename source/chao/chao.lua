local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Constants
-- ===============================================================================
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
-- Chao Sprite Class
-- ===============================================================================
-- TODO: implement states
class('Chao').extends(gfx.sprite)

function Chao:init(startX, startY)
    Chao.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Data and Stats
    -- --------------------------------------------------------------------------------
    -- TODO: save/load
    self.data = {
        name = 'Megabob',
        age = 3,
        mood = 75,
        belly = 50,
        -- TODO: figure out grade/level/value calculations? 
        stats = {
            swim = {
                level = 33,
                progress = 50,
            },
            fly = {
                level = 66,
                progress = 50,
            },
            run = {
                level = 99,
                progress = 0,
            },
            power = {
                level = 75,
                progress = 50,
            },
            stamina = {
                level = 51,
                progress = 50,
            },
        },
    }
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
    self:setImage(self:spritesheetImage(kDown, kIdle))
    -- --------------------------------------------------------------------------------
    -- Collision
    -- --------------------------------------------------------------------------------
    self:setCollideRect(0, 0, self:getSize())
    -- --------------------------------------------------------------------------------
    -- Initialization
    -- --------------------------------------------------------------------------------
    self:moveTo(startX, startY)
    self:add()
end

function Chao:spritesheetImage(dir, action)
    local dirIndex = self.spriteDir[dir]
    local actionIndex = self.spriteAction[action]
    return self.spritesheet[dirIndex + actionIndex]
end

function Chao:update()
    local ms = pd.getCurrentTimeMilliseconds()
    local spriteIndex = (ms // 500 % #self.spritesheet) + 1
    self:setImage(self.spritesheet[spriteIndex])
end
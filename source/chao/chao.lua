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
-- Chao Sprite Class
-- ===============================================================================
-- TODO: implement states
class('Chao').extends(gfx.sprite)

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

-- --------------------------------------------------------------------------------
-- Sprite Functions
-- --------------------------------------------------------------------------------

function Chao:spritesheetImage(dir, action)
    local dirIndex = self.spriteDir[dir]
    local actionIndex = self.spriteAction[action]
    return self.spritesheet[dirIndex + actionIndex]
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
-- Update
-- --------------------------------------------------------------------------------

function Chao:update()
    local ms = pd.getCurrentTimeMilliseconds()
    local spriteIndex = (ms // 500 % #self.spritesheet) + 1
    self:setImage(self.spritesheet[spriteIndex])
end
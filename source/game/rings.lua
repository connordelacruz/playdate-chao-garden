local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Constants
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Data
-- --------------------------------------------------------------------------------
-- Filename where ring count is saved
local kDataFilename <const> = 'ring-data'

-- --------------------------------------------------------------------------------
-- Config
-- --------------------------------------------------------------------------------
-- Max possible ring count
local kMaxRings <const> = 99999
-- Ring count to default to for a new file
local kStartingRings <const> = 200

-- ===============================================================================
-- Ring Master Class
-- ===============================================================================
class('RingMaster').extends()

function RingMaster:init()
    -- Default to kStartingRings
    self.rings = kStartingRings

    -- Attempt to load data
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)
end

-- --------------------------------------------------------------------------------
-- Save/Load Data
-- --------------------------------------------------------------------------------

function RingMaster:loadData()
    local loadedData = pd.datastore.read(kDataFilename)
    if loadedData == nil then
        DEBUG_MANAGER:vPrint('RingMaster: no save data found.')
        return
    end
    self.rings = loadedData.rings
    DEBUG_MANAGER:vPrint('RingMaster: save data found. Ring count = ' .. self.rings)
end

function RingMaster:saveData()
    local data = {rings = self.rings}
    DEBUG_MANAGER:vPrint('RingMaster:saveData() called. Data:')
    DEBUG_MANAGER:vPrintTable(data)
    pd.datastore.write(data, kDataFilename)
end
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
    -- Ring count. Default to kStartingRings
    self.rings = kStartingRings
    -- Functions to call when ring value changes.
    -- Register with RingMaster:registerRingListener().
    self.ringListeners = {}

    -- Attempt to load data
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)

    -- Debug: Crank to set rings
    if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.crankToSetRings) then
        DEBUG_MANAGER:registerDebugUpdateFunction('crankToSetRings', function ()
            self:crankinItUpdate()
        end)
    end
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

-- --------------------------------------------------------------------------------
-- Ring Count Update Listeners
-- --------------------------------------------------------------------------------

-- Register function to call when ring count is updated.
-- Function should take new ring count as a parameter.
function RingMaster:registerRingListener(key, func)
    if self.ringListeners[key] == nil then
        self.ringListeners[key] = func
    end
end

-- Remove ring listener function.
function RingMaster:removeRingListener(key)
    self.ringListeners[key] = nil
end

-- Call all ring listeners.
function RingMaster:callRingListeners()
    DEBUG_MANAGER:vPrint('RingMaster: calling ring listeners...')
    for key,func in pairs(self.ringListeners) do
        if type(func) == 'function' then
            DEBUG_MANAGER:vPrint('- ' .. key, 1)
            func(self.rings)
        end
    end
end

-- --------------------------------------------------------------------------------
-- Ring Count Setters
-- --------------------------------------------------------------------------------

-- Set rings. 
-- If val > kMaxRings, it will be set to kMaxRings.
-- If val < 0, it will be set to 0.
function RingMaster:setRings(val)
    if val > kMaxRings then
        val = kMaxRings
    elseif val < 0 then
        val = 0
    end
    self.rings = val
    DEBUG_MANAGER:vPrint('RingMaster: new ring count = ' .. self.rings)
    -- Call all ring count listeners
    self:callRingListeners()
end

-- Add rings.
function RingMaster:addRings(val)
    self:setRings(self.rings + val)
end

-- Subtract rings.
-- Note: Does not check if the new value would be < 0.
--       New ring count will default to 0 for negative numbers.
function RingMaster:subtractRings(val)
    self:setRings(self.rings - val)
end

-- --------------------------------------------------------------------------------
-- Helpers
-- --------------------------------------------------------------------------------

-- Returns true if self.rings - val > 0, false otherwise.
function RingMaster:canAfford(val)
    return self.rings - val >= 0
end

-- --------------------------------------------------------------------------------
-- Debug
-- --------------------------------------------------------------------------------

-- Debug Update Function: Use crank to modify ring count.
function RingMaster:crankinItUpdate()
    local change,_ = pd.getCrankChange()
    if change ~= 0 then
        self:addRings(math.floor(change))
    end
end
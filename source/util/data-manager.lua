-- TODO: move to game/ ?

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Data Manager Class
-- ===============================================================================
class('DataManager').extends()

function DataManager:init()
    self.saveFunctions = {}
    -- Invoke self:saveAll() on sleep/termination
    pd.gameWillTerminate = function ()
        self:saveAll()
    end
    pd.deviceWillSleep = function ()
        self:saveAll()
    end
end

function DataManager:registerSaveFunction(key, func)
    if self.saveFunctions[key] == nil then
        self.saveFunctions[key] = func
    end
end

function DataManager:saveAll()
    DEBUG_MANAGER:vPrint('DataManager: Saving data...')
    for key,func in pairs(self.saveFunctions) do
        if type(func) == 'function' then
            DEBUG_MANAGER:vPrint('- ' .. key, 1)
            func()
        end
    end
end
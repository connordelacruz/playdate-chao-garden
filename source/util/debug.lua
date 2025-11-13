-- ================================================================================
-- Constants
-- ================================================================================

-- Names for debug options
local kDebugOptions <const> = {
    'skipTitle',
}
-- Bit masks generated from above options
local function generateDebugMasks()
    local masks = {}
    for i,opt in ipairs(kDebugOptions) do
        masks[opt] = 2 ^ (i - 1)
    end
    return masks
end
-- Global constant
DEBUG_FLAGS = generateDebugMasks()

-- ================================================================================
-- Debug Manager Class
-- ================================================================================
class('DebugManager').extends()

function DebugManager:init()
    self.flags = 0
end

function DebugManager:setFlag(debugFlag)
    self.flags = self.flags | debugFlag
end

-- TODO: unsetFlag() https://yourbasic.org/golang/bitmask-flag-set-clear/

function DebugManager:isFlagSet(debugFlag)
    return (self.flags & debugFlag) > 0
end

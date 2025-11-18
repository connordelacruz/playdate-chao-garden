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

-- --------------------------------------------------------------------------------
-- Flags
-- --------------------------------------------------------------------------------

function DebugManager:setFlag(debugFlag)
    self.flags = self.flags | debugFlag
end

-- TODO: unsetFlag() https://yourbasic.org/golang/bitmask-flag-set-clear/

function DebugManager:isFlagSet(debugFlag)
    return (self.flags & debugFlag) > 0
end

-- --------------------------------------------------------------------------------
-- Utility
-- --------------------------------------------------------------------------------

function DebugManager:printTable(t, maxDepth)
    local out = self:tableToString(t, 1, maxDepth)
    print(out)
end

function DebugManager:printTableTopLevel(t)
    local out = self:tableToString(t, 1, 1)
    print(out)
end

function DebugManager:tableToString(t, indentLevel, maxDepth)
    if maxDepth == nil then
        maxDepth = 999
    end
    local indent = string.rep('  ', indentLevel)
    local out = '{'

    for k,v in pairs(t) do
        local line = '\n' .. indent .. k .. ' = '
        local vType = type(v)
        if vType == 'table' then
            if indentLevel < maxDepth then
                line = line .. self:tableToString(v, indentLevel + 1)
            else
                line = line .. tostring(v)
            end
        elseif vType == 'string' then
            line = line .. v
        else
            line = line .. tostring(v)
        end
        out = out .. line
    end

    out = out .. '\n' .. indent .. '}'
    return out
end
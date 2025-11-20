-- ================================================================================
-- Constants
-- ================================================================================

-- Names for debug options
local kDebugOptions <const> = {
    'verbose',
    'skipTitle',
    'printCursorCoordinates',
    'skipLoadingChaoData',
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
-- Logging Utilities
-- --------------------------------------------------------------------------------

function DebugManager:getIndentString(indentLevel)
    if type(indentLevel) ~= 'number' or indentLevel < 0 then
        indentLevel = 0
    end
    return string.rep('  ', indentLevel)
end

-- --------------------------------------------------------------------------------
-- Verbose Printing
-- --------------------------------------------------------------------------------

function DebugManager:vPrint(text, indentLevel)
    if not self:isFlagSet(DEBUG_FLAGS.verbose) then
        return
    end
    local indent = self:getIndentString(indentLevel)
    print(indent .. text)
end

function DebugManager:vPrintTable(t, maxDepth)
    if not self:isFlagSet(DEBUG_FLAGS.verbose) then
        return
    end
    self:printTable(t, maxDepth)
end

-- --------------------------------------------------------------------------------
-- Table Logging
-- --------------------------------------------------------------------------------

-- TODO: use sdk tableDump() instead???
--       https://sdk.play.date/3.0.1/Inside%20Playdate.html#_object_oriented_programming_in_lua:~:text=A%20debugging%20function%20Object%3AtableDump(%5Bindent%5D%2C%20%5Btable%5D)%20is%20provided%20to%20print%20all%20key/value%20pairs%20from%20the%20object%20and%20its%20superclasses.
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
    local indent = self:getIndentString(indentLevel)
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
local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Constants
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Shorthand for screen dimensions
-- --------------------------------------------------------------------------------
SCREEN_WIDTH = pd.display.getWidth()
SCREEN_HEIGHT = pd.display.getHeight()
SCREEN_CENTER_X = SCREEN_WIDTH / 2
SCREEN_CENTER_Y = SCREEN_HEIGHT / 2

-- --------------------------------------------------------------------------------
-- Collision groups
-- --------------------------------------------------------------------------------
TAG_NAMES = {
    -- Chao
    'CHAO',
    -- Cursor
    'CURSOR',
    -- Edges of the screen
    'SCREEN_BOUNDARY',
    -- Edge of the garden that is not the edge of the screen
    'GARDEN_BOUNDARY',
}
TAGS = {}
for i,tag in ipairs(TAG_NAMES) do
    TAGS[tag] = i
end
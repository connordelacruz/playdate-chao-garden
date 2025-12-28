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
    -- Clickable UI
    'CLICK_TARGET',
    -- Grabbable Item
    'ITEM',
    -- Edges of the screen
    'SCREEN_BOUNDARY',
    -- Edge of the garden that is not the edge of the screen
    'GARDEN_BOUNDARY',
    -- Garden pond boundaries
    'POND',
}
TAGS = {}
for i=1,#TAG_NAMES do
    TAGS[TAG_NAMES[i]] = i
end

-- --------------------------------------------------------------------------------
-- Z-Index Levels
-- --------------------------------------------------------------------------------
Z_INDEX = {
    BOTTOM = -1,
    TOP = 999,
    MIN = -32768,
    MAX = 32767,
    UI_LAYER_1 = 100,
    UI_LAYER_2 = 200,
    UI_LAYER_3 = 300,
    GARDEN_CHAO = 99,
    GARDEN_ITEM = 5,
    GARDEN_GB = 1,
}

-- --------------------------------------------------------------------------------
-- Fonts
-- --------------------------------------------------------------------------------
FONTS = {
    -- Headings, e.g. Chao name
    heading = gfx.getSystemFont(gfx.font.kVariantBold),
    -- Normal text, e.g. status panel stat names
    normal = gfx.font.new('fonts/diamond_12'),
    -- Small text, e.g. stat levels
    small = gfx.font.new('fonts/dpaint_8'),
}

-- --------------------------------------------------------------------------------
-- Playout Styles
-- --------------------------------------------------------------------------------
-- Root panel styles (status, shop)
STYLE_ROOT_PANEL = {
    -- Note: Width must be set by the implementing class
    height = SCREEN_HEIGHT,
    vAlign = playout.kAlignStart,
    hAlign = playout.kAlignCenter,
    paddingTop = 12,
    -- paddingBottom = 12,
    paddingLeft = 6,
    paddingRight = 6,
    backgroundColor = gfx.kColorWhite,
    borderRadius = 9,
    border = 2,
}
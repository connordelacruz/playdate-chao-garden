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
    -- Absolute min/max supported (for extreme cases, like scene transition overlays)
    MIN = -32768,
    MAX = 32767,
    -- Background image
    BACKGROUND = -1,
    -- Shadows TODO: implement
    SHADOW = 1,
    -- Gameboy
    GARDEN_GB = 3,
    -- Items
    GARDEN_ITEM = 5,
    -- Chao
    GARDEN_CHAO = 100,
    -- UI, should appear over most things
    UI_LAYER_1 = 1000,
    UI_LAYER_2 = 1100,
    UI_LAYER_3 = 1200,
    -- Items being grabbed by cursor
    GARDEN_ITEM_GRABBED = 9998,
    -- Cursors
    CURSOR = 9999,
    -- Overlays
    UI_OVERLAY = 10000,
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
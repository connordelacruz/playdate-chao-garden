import 'garden/background'
import 'garden/ui/cursor'
import 'garden/ui/status-panel'
import 'garden/items/item-manager'
import 'garden/items/item'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Chao Garden Scene Class
-- ================================================================================
class('GardenScene').extends(gfx.sprite)

function GardenScene:init()
    -- Background
    self.bg = GardenBackground()
    -- Status Panel UI
    self.statusPanel = StatusPanel(SCREEN_WIDTH - self.bg.width)
    -- Cursor
    self.cursor = Cursor(SCREEN_WIDTH - 64, 64)
    -- Chao
    local gardenCenterX = 400 - (self.bg.width / 2)
    self.chao = Chao(gardenCenterX, SCREEN_CENTER_Y)
    self.statusPanel:setChao(self.chao)
    -- Item Manager
    self.itemManager = ItemManager()

    -- Boundary collisions
    self:createBoundaries()

    self:add()
end

-- Create collision sprites for cursor and chao boundaries
-- TODO: getGardenBoundaries() to return a rect with valid garden area, accounting for boundary thiccness?
function GardenScene:createBoundaries()
    self.boundaries = {}
    local kWallThiccness <const> = 6
    self.boundaries[#self.boundaries + 1] = gfx.sprite.addEmptyCollisionSprite(
        0, 0, kWallThiccness, SCREEN_HEIGHT
    )
    self.boundaries[#self.boundaries + 1] = gfx.sprite.addEmptyCollisionSprite(
        SCREEN_WIDTH - kWallThiccness, 0, kWallThiccness, SCREEN_HEIGHT
    )
    self.boundaries[#self.boundaries + 1] = gfx.sprite.addEmptyCollisionSprite(
        0, 0, SCREEN_WIDTH, kWallThiccness
    )
    self.boundaries[#self.boundaries + 1] = gfx.sprite.addEmptyCollisionSprite(
        0, SCREEN_HEIGHT - kWallThiccness, SCREEN_WIDTH, kWallThiccness
    )

    for _,boundarySprite in ipairs(self.boundaries) do
        boundarySprite:setTag(TAGS.SCREEN_BOUNDARY)
        boundarySprite:add()
    end
end
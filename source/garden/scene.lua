import 'garden/background'
import 'garden/ui/cursor'
import 'garden/ui/status-panel'

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

    self:add()
end

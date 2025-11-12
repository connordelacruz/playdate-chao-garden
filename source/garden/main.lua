import 'garden/background'
import 'garden/ui/cursor'
import 'garden/ui/status-panel'

-- ================================================================================
-- Instances
-- ================================================================================
-- Background
local bg = GardenBackground()
-- Status Panel UI
local statusPanel = StatusPanel(SCREEN_WIDTH - bg.width)
-- Cursor
local cursor = Cursor(SCREEN_WIDTH - 64, 64)

-- Chao
local gardenCenterX = 400 - (bg.width / 2)
local chao = Chao(gardenCenterX, SCREEN_CENTER_Y)
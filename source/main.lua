-- Core libs
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/ui'
-- Toybox-managed libraries
import 'toyboxes'
-- Common stuff
import 'globals'
import 'util/state'
import 'util/scene-manager'
-- Chao
import 'chao/main'
-- Garden
import 'garden/scene'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Delta Time
-- ===============================================================================

DELTA_TIME = 0

function updateDeltaTime()
    DELTA_TIME = pd.getElapsedTime()
    pd.resetElapsedTime()
end

-- ===============================================================================
-- Scene Manager
-- ===============================================================================
SCENE_MANAGER = SceneManager()
SCENE_MANAGER:switchScene(GardenScene)

-- ===============================================================================
-- Game Loop
-- ===============================================================================

function pd.update()
    updateDeltaTime()
    gfx.sprite.update()
    pd.timer.updateTimers()
end

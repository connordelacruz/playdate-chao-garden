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
-- Scenes
import 'title/scene'
import 'garden/scene'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Delta Time
-- ===============================================================================

-- Will store time in seconds since the last frame
DELTA_TIME = 0

function updateDeltaTime()
    DELTA_TIME = pd.getElapsedTime()
    pd.resetElapsedTime()
end

-- ===============================================================================
-- Scenes
-- ===============================================================================
-- Global enum of scenes
SCENES = {
    title = TitleScene,
    garden = GardenScene,
}
-- Scene Manager
SCENE_MANAGER = SceneManager()
SCENE_MANAGER:switchScene(SCENES.title)

-- ===============================================================================
-- Game Loop
-- ===============================================================================

function pd.update()
    updateDeltaTime()
    gfx.sprite.update()
    pd.timer.updateTimers()
end

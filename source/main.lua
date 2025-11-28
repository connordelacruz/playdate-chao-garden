-- Core libs
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/ui'
import 'CoreLibs/keyboard'
-- Toybox-managed libraries
import 'toyboxes'
-- Common stuff
import 'globals'
import 'util/debug'
import 'util/data-manager'
import 'util/state'
import 'util/scene-manager'
-- Game stuff
import 'game/rings'
-- Chao
import 'chao/main'
-- Scenes
import 'title/scene'
import 'garden/scene'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Debug
-- ===============================================================================
DEBUG_MANAGER = DebugManager()
-- --------------------------------------------------------------------------------
-- Debug Options:
-- --------------------------------------------------------------------------------
-- Verbose logging.
DEBUG_MANAGER:setFlag(DEBUG_FLAGS.verbose)

-- Enable debug update functions that will be called in the main update() loop.
-- These must be registered via DEBUG_MANAGER:registerDebugUpdateFunction().
-- DEBUG_MANAGER:setFlag(DEBUG_FLAGS.enableDebugUpdateFunctions)

-- Skip title scene, go straight into garden.
DEBUG_MANAGER:setFlag(DEBUG_FLAGS.skipTitle)

-- Use the crank to add/remove rings.
-- NOTE: enableDebugUpdateFunctions must also be enabled!
-- DEBUG_MANAGER:setFlag(DEBUG_FLAGS.crankToSetRings)

-- When cursor moves, print coordinates to console.
-- DEBUG_MANAGER:setFlag(DEBUG_FLAGS.printCursorCoordinates)

-- If no items were loaded, add a fruit to the garden for testing.
-- DEBUG_MANAGER:setFlag(DEBUG_FLAGS.addTestItemIfNoneLoaded)

-- Don't load Chao data on start. 
-- NOTE: This gets silly with saving in the simulator,
--       probably should also set skipSavingChaoData.
-- DEBUG_MANAGER:setFlag(DEBUG_FLAGS.skipLoadingChaoData)

-- Don't save Chao data wherever Chao:saveData() would be called.
-- DEBUG_MANAGER:setFlag(DEBUG_FLAGS.skipSavingChaoData)

-- ===============================================================================
-- Save/Load Data
-- ===============================================================================
DATA_MANAGER = DataManager()

-- ===============================================================================
-- Rings
-- ===============================================================================
RING_MASTER = RingMaster()

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
-- Scene to load on game start
local startingScene = DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.skipTitle) and SCENES.garden or SCENES.title
-- TODO: hack so it doesn't transition on initial load, but it would be nicer to let the manager initialize shit:
startingScene()
-- Scene Manager
SCENE_MANAGER = SceneManager()

-- ===============================================================================
-- Game Loop
-- ===============================================================================

function pd.update()
    -- Update frame delta
    updateDeltaTime()
    -- Call debug update functions if enabled
    if DEBUG_MANAGER:isFlagSet(DEBUG_FLAGS.enableDebugUpdateFunctions) then
        DEBUG_MANAGER:update()
    end
    -- Update sprites and timers
    gfx.sprite.update()
    pd.timer.updateTimers()
end

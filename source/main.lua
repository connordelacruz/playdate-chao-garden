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
-- Chao
import 'chao/main'
-- Garden
import 'garden/main'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Game Loop
-- ===============================================================================

-- TODO: scene mgmt: https://www.youtube.com/watch?v=3LoMft137z8

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end

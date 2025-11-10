import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/ui'

local pd <const> = playdate
local gfx <const> = pd.graphics

----------------------------------------------------------------------------------
-- Game Loop
----------------------------------------------------------------------------------

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end

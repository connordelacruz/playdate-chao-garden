import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/ui'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- TODO: extract to files

local gardenBackgroundImage = gfx.image.new('images/garden/background')
function drawGardenBackground()
    local bgX = (400 - gardenBackgroundImage.width) / 2
    gardenBackgroundImage:draw(bgX, 0)
end

----------------------------------------------------------------------------------
-- Game Loop
----------------------------------------------------------------------------------

-- TODO: scene mgmt: https://www.youtube.com/watch?v=3LoMft137z8

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()

    drawGardenBackground()
end

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Gameboy Class
-- ===============================================================================
class('Gameboy').extends(gfx.sprite)

function Gameboy:init(x, y)
    local image = gfx.image.new('images/garden/gameboy')
    self:setImage(image)

    self:setCollideRect(0, 0, self:getSize())
    -- TODO: tags n all that

    self:moveTo(x, y)
    self:add()
end

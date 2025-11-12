local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Chao Sprite Class
-- ===============================================================================
-- TODO: implement states
class('Chao').extends(gfx.sprite)

function Chao:init(startX, startY)
    Chao.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Spritesheet
    -- --------------------------------------------------------------------------------
    self.spritesheet = gfx.imagetable.new('images/chao/chao-idle-walk')
    self:setImage(self.spritesheet[1])
    -- --------------------------------------------------------------------------------
    -- Initialization
    -- --------------------------------------------------------------------------------
    self:setCollideRect(0, 0, self.spritesheet[1].width, self.spritesheet[1].height)
    self:moveTo(startX, startY)
    self:add()
end

function Chao:update()
    local ms = pd.getCurrentTimeMilliseconds()
    local spriteIndex = (ms // 500 % #self.spritesheet) + 1
    print(spriteIndex)
    self:setImage(self.spritesheet[spriteIndex])
end
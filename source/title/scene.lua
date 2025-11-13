local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Title Screen Scene Class
-- ================================================================================
class('TitleScene').extends(gfx.sprite)

function TitleScene:init()
    TitleScene.super.init(self)
    local bgImage = gfx.image.new('images/title/background')
    self:setImage(bgImage)
    self:moveTo(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    self:add()
end

function TitleScene:update()
    if pd.buttonJustPressed(pd.kButtonA) then
        SCENE_MANAGER:switchScene(SCENES.garden)
    end
end
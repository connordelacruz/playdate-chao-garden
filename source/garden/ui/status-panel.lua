local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Status Panel UI "Sprite"
-- ===============================================================================
class('StatusPanel').extends(gfx.sprite)

-- panelWidth: Set to screen width minus background width
function StatusPanel:init(panelWidth)
    StatusPanel.super.init(self)

    local panelImage = gfx.image.new(panelWidth, SCREEN_HEIGHT)
    gfx.pushContext(panelImage)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.setLineWidth(4)
        gfx.drawRoundRect(0, 0, panelImage.width, panelImage.height, 4)
    gfx.popContext()
    self:setImage(panelImage)

    -- Draw from top left corner
    self:setCenter(0, 0)
    -- Left side of the screen
    self:moveTo(0, 0)

    self:add()
end
local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Status Panel UI "Sprite"
-- ===============================================================================
class('StatusPanel').extends(gfx.sprite)

-- panelWidth: Set to screen width minus background width
function StatusPanel:init(panelWidth)
    StatusPanel.super.init(self)

    self.panelWidth = panelWidth

    -- Setup Playout elements for UI
    -- TODO: We're gonna want to update stuff here dynamically, so maybe store panelUI in class and draw it in draw function
    local panelUI = playout.tree.new(self:createPanelUI())
    local panelImage = panelUI:draw()
    self:setImage(panelImage)

    -- Draw from top left corner
    self:setCenter(0, 0)
    -- Left side of the screen
    self:moveTo(0, 0)

    self:add()
end

-- Build Menu UI
-- TODO: We're gonna want to update stuff here dynamically
function StatusPanel:createPanelUI()
    local box = playout.box.new
    local image = playout.image.new
    local text = playout.text.new

    local outerPanelBoxProps = {
        width = self.panelWidth,
        height = SCREEN_HEIGHT,
        vAlign = playout.kAlignStart,
        hAlign = playout.kAlignCenter,
        paddingTop = 12,
        paddingBottom = 12,
        paddingLeft = 6,
        paddingRight = 6,
        backgroundColor = gfx.kColorWhite,
        borderRadius = 9,
        border = 2,
    }

    return box(outerPanelBoxProps, {
        self:createNameUI(),
    })
end

function StatusPanel:createNameUI()
    local box = playout.box.new
    local image = playout.image.new
    local text = playout.text.new

    -- Chao name display
    local nameText = text('*Megabob*', {
        alignment = kTextAlignment.center,
    })
    -- Chao life stage display
    local lifeStageText = text('child', {
        alignment = kTextAlignment.center,
    })

    return box({
        spacing = 3,
    },
    {
        nameText,
        lifeStageText,
    }
    )
end
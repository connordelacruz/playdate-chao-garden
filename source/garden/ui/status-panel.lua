local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Status Panel UI "Sprite"
-- ===============================================================================
class('StatusPanel').extends(gfx.sprite)

-- panelWidth: Set to screen width minus background width
function StatusPanel:init(panelWidth)
    StatusPanel.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Data
    -- --------------------------------------------------------------------------------
    -- To be set after initialization
    self.chao = nil
    self.rings = 0

    -- --------------------------------------------------------------------------------
    -- Image
    -- --------------------------------------------------------------------------------
    self.panelWidth = panelWidth
    -- Setup Playout elements for UI
    self:renderUI()

    -- Draw from top left corner
    self:setCenter(0, 0)
    -- Left side of the screen
    self:moveTo(0, 0)

    self:add()
end

function StatusPanel:setChao(chao)
    self.chao = chao
    self:renderUI()
end

function StatusPanel:setRings(rings)
    self.rings = rings
    self:renderUI()
end

function StatusPanel:renderUI()
    local panelUI = playout.tree.new(self:createPanelUI())
    local panelImage = panelUI:draw()
    self:setImage(panelImage)
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

    local name = ''
    local lifeStage = ''
    if self.chao ~= nil then
        name = '*' .. self.chao.data.name .. '*'
        lifeStage = self.chao.data.age > 1 and 'adult' or 'child'
    end
    -- Chao name display
    local nameText = text(name, {
        alignment = kTextAlignment.center,
    })
    -- Chao life stage display
    local lifeStageText = text(lifeStage, {
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
local pd <const> = playdate
local gfx <const> = pd.graphics
-- --------------------------------------------------------------------------------
-- Playout Shorthands
-- --------------------------------------------------------------------------------
local box <const> = playout.box.new
local image <const> = playout.image.new
local text <const> = playout.text.new

-- ===============================================================================
-- Shop States
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Superclass
-- --------------------------------------------------------------------------------
class('ShopState').extends('State')

function ShopState:init(shopButton)
    self.shopButton = shopButton
end

-- --------------------------------------------------------------------------------
-- Closed:
-- - Listen for B press to open panel (if cursor has a free hand)
-- --------------------------------------------------------------------------------
local kClosedState <const> = 'closed'
class('ShopClosedState').extends('ShopState')

function ShopClosedState:update()
    self.shopButton:handleOpenPress()
end

-- --------------------------------------------------------------------------------
-- Open:
-- - Listen for B press to close panel
-- --------------------------------------------------------------------------------
local kOpenState <const> = 'open'
class('ShopOpenState').extends('ShopState')

function ShopOpenState:update()
    self.shopButton:handleClosePress()
end

-- ===============================================================================
-- Shop Menu Button Indicator/Input Listener
-- ===============================================================================
class('ShopButton').extends('FSMSprite')

function ShopButton:init(cursor, itemManager)
    self.cursor = cursor
    self.itemManager = itemManager
    -- Shop UI sprite
    self.shopPanel = ShopPanel(self.itemManager)

    -- States
    self.states = {
        [kClosedState] = ShopClosedState(self),
        [kOpenState] = ShopOpenState(self),
    }
    self:setInitialState(kClosedState)

    -- TODO: add a simple image for this
    self:add()
end

-- --------------------------------------------------------------------------------
-- Input Handling
-- --------------------------------------------------------------------------------

function ShopButton:handleOpenPress()
    if pd.buttonJustPressed(pd.kButtonB) and self.cursor:handsFree() then
        self:showShopPanel()
    end
end

function ShopButton:handleClosePress()
    if pd.buttonJustPressed(pd.kButtonB) then
        self:hideShopPanel()
    end
end

-- --------------------------------------------------------------------------------
-- Hide/Show Shop Panel
-- --------------------------------------------------------------------------------

function ShopButton:showShopPanel()
    self.cursor:disable()
    self.shopPanel:add()
    self:setState(kOpenState)
end

function ShopButton:hideShopPanel()
    self.shopPanel:remove()
    self.cursor:enable()
    self:setState(kClosedState)
end

-- ===============================================================================
-- Shop UI
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Style Constants
-- --------------------------------------------------------------------------------

-- TODO: extract styles

-- --------------------------------------------------------------------------------
-- Class
-- --------------------------------------------------------------------------------
class('ShopPanel').extends(gfx.sprite)

function ShopPanel:init(itemManager)
    self.itemManager = itemManager
    -- Index of selected menu item
    self.selectedIndex = 1
    
    -- Setup Playout elements for UI
    self:renderUI()
    -- Create shop cursor sprite
    self:createCursor()

    -- Draw from top right corner
    self:setCenter(1, 0)
    -- Move to right side of the screen
    self:moveTo(SCREEN_WIDTH, 0)
    -- Display over other elements
    self:setZIndex(Z_INDEX.UI_LAYER_3)
end

-- --------------------------------------------------------------------------------
-- Shop Cursor
-- --------------------------------------------------------------------------------

function ShopPanel:createCursor()
    -- TODO: sprite w/ triangle for now
    local nodeHeight = 20
    -- Draw triangle
    local cursorImage = gfx.image.new(nodeHeight, nodeHeight)
    gfx.pushContext(cursorImage)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(
            0, 0,
            nodeHeight, nodeHeight / 2,
            0, nodeHeight
        )
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.drawTriangle(
            0, 0,
            nodeHeight, nodeHeight / 2,
            0, nodeHeight
        )
    gfx.popContext()

    -- Create sprite object
    self.cursorSprite = gfx.sprite.new(cursorImage)
    -- Center on right side, middle point
    self.cursorSprite:setCenter(1, 0.5)
    -- Display on top
    self.cursorSprite:setZIndex(Z_INDEX.TOP)
end

function ShopPanel:moveCursorToSelectedIndex()
    local selected = self.panelUI.tabIndex[self.selectedIndex]
    -- Point anchored center left of the selected node
    local pointerPos = getRectAnchor(selected.rect, playout.kAnchorCenterLeft):offsetBy(self.x - self.width, self.y)
    self.cursorSprite:moveTo(pointerPos:unpack())
end

-- --------------------------------------------------------------------------------
-- add()/remove() Overrides
-- --------------------------------------------------------------------------------

function ShopPanel:add()
    ShopPanel.super.add(self)
    self:moveCursorToSelectedIndex()
    self.cursorSprite:add()
end

function ShopPanel:remove()
    self.cursorSprite:remove()
    ShopPanel.super.remove(self)
end

-- --------------------------------------------------------------------------------
-- Render UI
-- --------------------------------------------------------------------------------

function ShopPanel:renderUI()
    self.panelUI = playout.tree.new(self:createPanelUI())
    self.panelUI:computeTabIndex()
    local panelImage = self.panelUI:draw()
    self:setImage(panelImage)
end

function ShopPanel:createPanelUI()
    local outerPanelBoxProps = {
        id = 'shop-panel-root',
        style = STYLE_ROOT_PANEL,
        -- TODO: width?
    }

    return box(outerPanelBoxProps, self:createItemsListUI())
end

-- Returns a list of shop item UI elements
function ShopPanel:createItemsListUI()
    local itemElements = {}
    -- Fruits
    for className,props in pairs(FRUITS) do
        local fruitImage = FRUIT_SPRITESHEET[props.spritesheetIndex]
        local tabIndex = #itemElements+1
        itemElements[tabIndex] = self:createItemUI(tabIndex, className, fruitImage, props.attributes.cost)
    end
    return itemElements
end

-- Creates an item UI to add to the shop list
function ShopPanel:createItemUI(tabIndex, className, itemImage, cost)
    local imageUI = image(itemImage)
    local costText = text(tostring(cost), {
        fontFamily = FONTS.normal,
    })
    -- TODO: figure out logic for clicking on list item
    return box({
        tabIndex = tabIndex,
        direction = playout.kDirectionHorizontal,
        vAlign = playout.kAlignCenter,
        hAlign = playout.kAlignStart,
        spacing = 12,
        paddingBottom = 5,
        paddingLeft = 5,
        paddingRight = 5,
    }, {
        imageUI,
        costText,
    })
end
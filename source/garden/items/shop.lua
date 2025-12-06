local pd <const> = playdate
local gfx <const> = pd.graphics
-- --------------------------------------------------------------------------------
-- Playout Shorthands
-- --------------------------------------------------------------------------------
local box <const> = playout.box.new
local image <const> = playout.image.new
local text <const> = playout.text.new

-- ===============================================================================
-- Constants
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Fonts
-- --------------------------------------------------------------------------------
local kFonts <const> = {
    -- Price of an item TODO: better font
    itemCost = FONTS.normal,
}

-- --------------------------------------------------------------------------------
-- Styles
-- --------------------------------------------------------------------------------
-- Shop list item container
local kItemListNodeStyle <const> = {
    font = kFonts.itemCost,
    direction = playout.kDirectionHorizontal,
    vAlign = playout.kAlignCenter,
    hAlign = playout.kAlignStart,
    spacing = 12,
    paddingBottom = 5,
    paddingLeft = 5,
    paddingRight = 5,
}

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

-- Shorthand to get the playout node for the selected item in the list
function ShopPanel:getSelectedNode()
    return self.panelUI.tabIndex[self.selectedIndex]
end

-- Check for D-pad input, update self.selectedIndex, and update shop cursor
function ShopPanel:handleMove()
    if pd.buttonJustPressed(pd.kButtonUp) then
        local i = self.selectedIndex - 1
        self.selectedIndex = i > 0 and i or #self.panelUI.tabIndex
        self:moveCursorToSelectedIndex()
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        -- Gotta do modulo before incrementing cuz lua indexes by 1
        local i = self.selectedIndex % #self.panelUI.tabIndex
        self.selectedIndex = i + 1
        self:moveCursorToSelectedIndex()
    end
end

-- Move shop cursor to item node for self.selectedIndex
function ShopPanel:moveCursorToSelectedIndex()
    local selected = self:getSelectedNode()
    -- Point anchored center left of the selected node
    local pointerPos = getRectAnchor(selected.rect, playout.kAnchorCenterLeft):offsetBy(self.x - self.width, self.y)
    self.cursorSprite:moveTo(pointerPos:unpack())
end

-- Check for A press, attempt to purchase selected item
function ShopPanel:handleClick()
    if pd.buttonJustPressed(pd.kButtonA) then
        local selected = self:getSelectedNode()
        -- Note: this custom prop is defined in createItemUI()
        local itemProps = selected.properties.item
        -- TODO: FINISH
        DEBUG_MANAGER:vPrint('A clicked on shop list')
        DEBUG_MANAGER:vPrintTable(itemProps)
    end
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
    local costText = text(tostring(cost))

    return box({
        tabIndex = tabIndex,
        style = kItemListNodeStyle,
        -- Custom properties for item logic
        item = {
            className = className,
            cost = cost,
        },
    }, {
        imageUI,
        costText,
    })
end

-- --------------------------------------------------------------------------------
-- Update
-- --------------------------------------------------------------------------------

function ShopPanel:update()
    -- TODO: RENAME to checkFor.*
    self:handleMove()
    self:handleClick()
end
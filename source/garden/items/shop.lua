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
-- Sounds
-- --------------------------------------------------------------------------------
-- TODO: may want to make this global since we'll prob reuse these sounds
local kSounds <const> = {
    move = pd.sound.sampleplayer.new('sounds/ui/move.wav'),
    click = pd.sound.sampleplayer.new('sounds/ui/select.wav'),
    cancel = pd.sound.sampleplayer.new('sounds/ui/cancel.wav'),
    nope = pd.sound.sampleplayer.new('sounds/ui/nope.wav'),
}
-- These samples are loud, so decrease volume of each
for _,s in pairs(kSounds) do
    s:setVolume(0.25)
end

-- --------------------------------------------------------------------------------
-- Fonts
-- --------------------------------------------------------------------------------
local kFonts <const> = {
    -- Price of an item TODO: better font
    itemCost = FONTS.normal,
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
    self.shopPanel = ShopPanel(self.itemManager, self)

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
        kSounds.click:play()
        self:showShopPanel()
    end
end

function ShopButton:handleClosePress()
    if pd.buttonJustPressed(pd.kButtonB) then
        kSounds.cancel:play()
        self:hideShopPanel()
    end
end

-- --------------------------------------------------------------------------------
-- Hide/Show Shop Panel
-- --------------------------------------------------------------------------------

-- Disable cursor, add shop panel sprite
function ShopButton:showShopPanel()
    self.cursor:disable()
    self.shopPanel:add()
    self:setState(kOpenState)
end

-- Remove shop panel sprite, set cursor to active
function ShopButton:hideShopPanel()
    self.shopPanel:remove()
    self.cursor:enable()
    self:setState(kClosedState)
end

-- Remove shop panel sprite, grab passed in item with cursor
function ShopButton:closeShopPanelAfterPurchase(item)
    self.shopPanel:remove()
    -- Cursor should ignore A press from purchase, otherwise it drops the item right away.
    -- Wait 1 frame before updating cursor state
    pd.frameTimer.performAfterDelay(1, function ()
        self.cursor:grabItem(item)
        self:setState(kClosedState)
    end)
end

-- ===============================================================================
-- Shop UI
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Style Constants
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

-- --------------------------------------------------------------------------------
-- Class
-- --------------------------------------------------------------------------------
class('ShopPanel').extends(gfx.sprite)

function ShopPanel:init(itemManager, shopButton)
    self.itemManager = itemManager
    self.shopButton = shopButton
    
    -- --------------------------------------------------------------------------------
    -- UI and Cursor
    -- --------------------------------------------------------------------------------
    -- Setup Playout elements for UI
    self:renderUI()
    -- Create shop cursor sprite
    self:createCursor()
    -- TODO: precalculate cursor coords?

    -- --------------------------------------------------------------------------------
    -- Menu Selection
    -- --------------------------------------------------------------------------------
    -- Index of selected menu item
    self.selectedIndex = 1

    -- --------------------------------------------------------------------------------
    -- Drawing
    -- --------------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------------
-- D-Pad Input Handling
-- --------------------------------------------------------------------------------

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

-- Move shop cursor to item node for self.selectedIndex.
-- If noSound is truthy, do not play cursor move sound.
function ShopPanel:moveCursorToSelectedIndex(noSound)
    local selected = self:getSelectedNode()
    -- Point anchored center left of the selected node
    -- TODO: caching
    local pointerPos = getRectAnchor(selected.rect, playout.kAnchorCenterLeft):offsetBy(self.x - self.width, self.y)
    self.cursorSprite:moveTo(pointerPos:unpack())
    if not noSound then
        kSounds.move:play()
    end
end

-- --------------------------------------------------------------------------------
-- Click Input Handling
-- --------------------------------------------------------------------------------

-- Check if we can afford a selected item and if there's space in the garden for it
function ShopPanel:canPurchaseItem(itemProps)
    local canAfford = RING_MASTER:canAfford(itemProps.cost)
    local canAddItem = self.itemManager:canAddItem()

    -- DEBUG: log when we can't buy item
    if not canAfford then
        DEBUG_MANAGER:vPrint('Cannot afford item (cost=' .. itemProps.cost .. ', rings=' .. RING_MASTER.rings .. ')', 1)
    end
    if not canAddItem then
        DEBUG_MANAGER:vPrint('Cannot purchase, no room for new items', 1)
    end

    return canAfford and canAddItem
end

-- Update ring master and item manger and return instance of newly purchased item
function ShopPanel:purchaseItem(itemProps)
    RING_MASTER:subtractRings(itemProps.cost)
    -- Spawn item vertically centered on the edge of the shop panel
    local x = SCREEN_WIDTH - self.width
    local y = SCREEN_CENTER_Y
    
    return self.itemManager:addNewItem(itemProps.className, x, y)
end

-- Check for A press, attempt to purchase selected item
function ShopPanel:handleClick()
    if pd.buttonJustPressed(pd.kButtonA) then
        local selected = self:getSelectedNode()
        -- Note: this custom prop is defined in createItemUI()
        local itemProps = selected.properties.item

        DEBUG_MANAGER:vPrint('ShopPanel: A press on shop list, seeing if we can buy it...')
        local canPurchase = self:canPurchaseItem(itemProps)

        if canPurchase then
            DEBUG_MANAGER:vPrint(itemProps.className .. ' purchased, closing shop panel', 1)
            local item = self:purchaseItem(itemProps)
            kSounds.click:play()
            -- Pass new item to shop button and let it handle giving it to cursor
            self.shopButton:closeShopPanelAfterPurchase(item)
        else
            -- TODO: visual indication that hints at why we can't purchase
            kSounds.nope:play()
        end
    end
end

-- --------------------------------------------------------------------------------
-- add()/remove() Overrides
-- (adds logic to deal with internal cursor sprite)
-- --------------------------------------------------------------------------------

function ShopPanel:add()
    ShopPanel.super.add(self)
    self:moveCursorToSelectedIndex(true)
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
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
    -- Chao name
    name = FONTS.heading,
    -- Bar UI title
    title = FONTS.normal,
    -- Stat UI level
    level = FONTS.small,
}
-- --------------------------------------------------------------------------------
-- Styles
-- --------------------------------------------------------------------------------
-- Chao name text
local kNameTextStyle <const> = {
    fontFamily = kFonts.name,
    alignment = kTextAlignment.center,
}
-- Bar UI title text
local kTitleTextStyle <const> = {
    fontFamily = kFonts.title,
    alignment = kTextAlignment.left,
}
-- Stat level text
local kLevelTextStyle <const> = {
    fontFamily = kFonts.level,
    alignment = kTextAlignment.right,
}
-- Bar UI title/level container
local kBarTitleContainerStyle <const> = {
    direction = playout.kDirectionHorizontal,
    vAlign = playout.kAlignCenter,
    hAlign = playout.kAlignStretch,
}
-- Progress bar chunks
local kProgressBarChunkStyle <const> = {
    height = 6,
    border = 1,
    borderRadius = 3,
}
-- Progress bar container
local kProgressBarContainerStyle <const> = {
    direction = playout.kDirectionHorizontal,
    vAlign = playout.kAlignCenter,
    hAlign = playout.kAlignStretch,
}
-- Bar UI container
local kBarUIContainerStyle <const> = {
    spacing = 3,
    hAlign = playout.kAlignStretch,
    paddingBottom = 5,
}
-- --------------------------------------------------------------------------------
-- Stats Display
-- --------------------------------------------------------------------------------
-- Lua apparently does not maintain ordering of tables indexed by keys, so using this
-- constant to explicitly define the order that stats should be displayed in.
local kStatIndexesInOrder <const> = {
    'swim', 'fly', 'run', 'power', 'stamina',
}

-- ================================================================================
-- Status Panel UI Sprite
-- ================================================================================
class('StatusPanel').extends(gfx.sprite)

-- panelWidth: Set to screen width minus background width
function StatusPanel:init(panelWidth)
    StatusPanel.super.init(self)
    -- --------------------------------------------------------------------------------
    -- Data
    -- --------------------------------------------------------------------------------
    -- To be set after initialization
    self.chao = nil
    -- Register listener for when ring value updates
    RING_MASTER:registerRingListener('status-panel', function ()
        self:updateRings()
        self:updateUI()
    end)
    -- TODO: removeRingListener() on StatusPanel:remove() !!!!!

    -- --------------------------------------------------------------------------------
    -- Image
    -- --------------------------------------------------------------------------------
    self.panelWidth = panelWidth
    -- Setup Playout elements for UI
    self:initializeUI()
    -- Draw from top left corner
    self:setCenter(0, 0)
    -- Left side of the screen
    self:moveTo(0, 0)
    -- UI layer 1
    self:setZIndex(Z_INDEX.UI_LAYER_1)
    -- --------------------------------------------------------------------------------
    -- Collision
    -- --------------------------------------------------------------------------------
    -- The status panel marks the edge of the garden, so we want collisions
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.GARDEN_BOUNDARY)

    self:add()
end

-- --------------------------------------------------------------------------------
-- Setters
-- --------------------------------------------------------------------------------

-- TODO: reorganize/move this?
function StatusPanel:setChao(chao)
    self.chao = chao
    self:updateChaoName()
    self:createOrUpdateEditNameClickTarget()
    -- TODO: update mood, belly, stats
    self:updateUI()
end

-- --------------------------------------------------------------------------------
-- Top Level UI
-- --------------------------------------------------------------------------------

-- Initialize UI tree and set image.
function StatusPanel:initializeUI()
    self.panelUI = playout.tree.new(self:createPanelUI())
    local panelImage = self.panelUI:draw()
    self:setImage(panelImage)
    self:createOrUpdateEditNameClickTarget()
end

-- Build Menu UI tree.
function StatusPanel:createPanelUI()
    local outerPanelBoxProps = {
        id = 'status-panel-root',
        style = STYLE_ROOT_PANEL,
        width = self.panelWidth,
    }

    -- TODO: may not be necessary
    self.sectionNodes = {
        name = self:createNameUI(),
        mood = self:createMoodUI(),
        belly = self:createBellyUI(),
        stats = self:createStatsUI(),
        rings = self:createRingCountUI(),
    }

    return box(outerPanelBoxProps, {
        self.sectionNodes.name,
        self.sectionNodes.mood,
        self.sectionNodes.belly,
        self.sectionNodes.stats,
        self.sectionNodes.rings,
    })
end

-- Update UI. Call after making changes to specific UI properties.
function StatusPanel:updateUI()
    self.panelUI:layout()
    self.panelUI:draw()
end

-- --------------------------------------------------------------------------------
-- Name UI + Edit Click Target
-- --------------------------------------------------------------------------------

-- Returns UI node for name section.
-- Sets self.nameTextNode.
function StatusPanel:createNameUI()
    local name = self.chao == nil and '' or self.chao.data.name
    self.nameTextNode = text(name, {
        id = 'name-text',
        style = kNameTextStyle,
    })

    return box({
            id = 'name-container',
            minWidth = 66,
        },
        {
            self.nameTextNode,
        }
    )
end

-- Update Chao name to match self.chao.
function StatusPanel:updateChaoName()
    local name = self.chao == nil and '' or self.chao.data.name
    self.nameTextNode.text = name
    -- Update edit click target rect to match new name size.
    self:createOrUpdateEditNameClickTarget()
end

-- Create/update edit name click target.
-- TODO: figure out where this is used and see if we can clean this up?
function StatusPanel:createOrUpdateEditNameClickTarget()
    if self.panelUI == nil then
        return
    end
    if self.editNameClickTarget == nil then
        self.editNameClickTarget = EditNameClickTarget(self, self.chao)
    else
        self.editNameClickTarget.chao = self.chao
        self.editNameClickTarget:updateRect()
    end
end

-- --------------------------------------------------------------------------------
-- Mood UI
-- --------------------------------------------------------------------------------

-- Returns UI node for mood section.
-- TODO: set a reference to bars section or whatever so we can update
function StatusPanel:createMoodUI()
    local mood = self.chao == nil and 0 or self.chao.data.mood
    return self:createBarUI('Mood', mood, nil)
end

-- --------------------------------------------------------------------------------
-- Belly UI
-- --------------------------------------------------------------------------------

-- Returns UI node for belly section.
-- TODO: set a reference to bars section or whatever so we can update
function StatusPanel:createBellyUI()
    local belly = self.chao == nil and 0 or self.chao.data.belly
    return self:createBarUI('Belly', belly, nil)
end

-- --------------------------------------------------------------------------------
-- Stats UI
-- --------------------------------------------------------------------------------

-- All stats sections
function StatusPanel:createStatsUI()
    local stats = {}
    if self.chao ~= nil then
        stats = self.chao.data.stats
    else
        -- Default to all 0's
        for _,statIndex in ipairs(kStatIndexesInOrder) do
            stats[statIndex] = {
                level = 0,
                progress = 0,
            }
        end
    end

    local statsUIChildren = {}
    for _,statIndex in ipairs(kStatIndexesInOrder) do
        local statData = stats[statIndex]
        local title = statIndex:gsub("^%l", string.upper)
        local statUI = self:createStatUI(title, statData)
        statsUIChildren[#statsUIChildren+1] = statUI
    end

    -- TODO: JUST RETURN statsUIChildren unpacked?
    return box(
        {},
        statsUIChildren
    )
end

-- Create a single stat section
function StatusPanel:createStatUI(statName, statData)
    local progress = statData == nil and 0 or statData.progress
    local level = statData == nil and 0 or statData.level
    return self:createBarUI(statName, progress, level)
end

-- --------------------------------------------------------------------------------
-- Bar UI (mood, belly, stats sections)
-- --------------------------------------------------------------------------------

-- TODO: figure out how we can keep track of and update progress bar and level
-- TODO: maybe return container, levelTextNode, progressBarContainer separately?

-- Create a bar UI section (mood/belly + stats)
function StatusPanel:createBarUI(title, progress, level)
    -- Title and optional LV display
    local titleText = text(
        title,
        {
            style = kTitleTextStyle,
            flex = 2,
        }
    )
    local levelText = text(
        level == nil and '' or 'LV ' .. level,
        {
            style = kLevelTextStyle,
            flex = 1,
        }
    )
    local titleContainer = box({
            style = kBarTitleContainerStyle,
        },
        {
            titleText,
            levelText,
        }
    )
    -- Progress bar
    local progressBarContainer = self:createProgressBar(progress)

    return box({
            style = kBarUIContainerStyle,
        },
        {
            titleContainer,
            progressBarContainer,
        }
    )
end

-- Create a progress bar box
function StatusPanel:createProgressBar(progress)
    -- Convert progress percent to rounded down int
    local progressInt = progress // 10
    -- Create little progress boxes
    local progressBarChildren = {}
    for i=1,10 do
        local filled = i <= progressInt
        local progressChunkBox = box({
            style = kProgressBarChunkStyle,
            flex = 1,
            backgroundColor = filled and gfx.kColorBlack or gfx.kColorWhite,
        })
        progressBarChildren[i] = progressChunkBox
    end

    return box({
            style = kProgressBarContainerStyle,
        },
        progressBarChildren)
end

-- --------------------------------------------------------------------------------
-- Rings UI
-- --------------------------------------------------------------------------------

-- Returns UI node for rings section.
-- Sets self.ringsTextNode.
function StatusPanel:createRingCountUI()
    -- TODO: add sprite n shit, polish up, move styles to constants
    self.ringsTextNode = text(
        'Rings: ' .. RING_MASTER.rings,
        {
            fontFamily = kFonts.level,
            alignment = kTextAlignment.center,
        }
    )
    return box({
            hAlign = playout.kAlignCenter,
            vAlign = playout.kAlignEnd,
            -- TODO: anything > 3 pushes it off screen...
            paddingTop = 3,
        },
        {
            self.ringsTextNode,
        })
end

-- Update ring count to match RING_MASTER.rings.
function StatusPanel:updateRings()
    self.ringsTextNode.text = 'Rings: ' .. RING_MASTER.rings
end

-- ================================================================================
-- Edit Name Click Target
-- ================================================================================
class('EditNameClickTarget').extends(gfx.sprite)

-- TODO: !!!!!!!!
-- TODO: Freeze game when edit menu is open!!!!!! it lags otherwise
-- TODO: !!!!!!!!

function EditNameClickTarget:init(statusPanel, chao)
    EditNameClickTarget.super.init(self)

    self.statusPanel = statusPanel
    self.chao = chao

    -- Rect size/stroke stuff
    self.stroke = 2
    self.borderRadius = 4
    self.hPadding = self.stroke + 2
    self.vPadding = self.stroke
    self:updateRect()

    -- Collisions
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
    self:setTag(TAGS.CLICK_TARGET)

    -- Set Z-index to a high value, but not as high as the cursor
    self:setZIndex(Z_INDEX.UI_LAYER_2)
    -- Invisible by default
    self:setVisible(false)

    self:add()
end

function EditNameClickTarget:updateRect()
    local nameContainerRect = self.statusPanel.panelUI:get('name-container').rect
    local hPaddingAdding = 2 * self.hPadding
    local vPaddingAdding = 2 * self.vPadding
    self:setSize(nameContainerRect.width + hPaddingAdding, 
                 nameContainerRect.height + vPaddingAdding)
    self:moveTo(nameContainerRect:centerPoint())
    self:updateHoverImage()
end

function EditNameClickTarget:updateHoverImage()
    local w,h = self:getSize()
    local img = gfx.image.new(w, h)
    gfx.pushContext(img)
        gfx.setLineWidth(self.stroke)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.drawRoundRect(0, 0, w, h, self.borderRadius)
    gfx.popContext()
    self:setImage(img)
    self:setCollideRect(0, 0, w, h)
end

function EditNameClickTarget:click(cursor)
    local currentName = self.chao ~= nil and self.chao.data.name or ''
    -- Create text input sprite
    local editNameTextInput = nil
    -- Freeze cursor until keyboard is hidden
    cursor:disable()

    pd.keyboard.keyboardDidShowCallback = function ()
        editNameTextInput = EditNameTextInput(currentName, pd.keyboard.left())
        editNameTextInput:add()
    end

    pd.keyboard.keyboardDidHideCallback = function ()
        editNameTextInput:remove()
        -- Update Chao name data
        self.chao:setName(pd.keyboard.text)
        -- Redraw panel UI
        self.statusPanel:updateChaoName()
        self.statusPanel:updateUI()
        -- Re-enable cursor
        cursor:enable()
    end
    
    pd.keyboard.textChangedCallback = function ()
        local txt = pd.keyboard.text
        if string.len(txt) > 7 then
            pd.keyboard.text = string.sub(txt, 1, 7)
        end
        editNameTextInput:updateText(pd.keyboard.text)
    end

    -- Show keyboard
    pd.keyboard.show(currentName)
end

function EditNameClickTarget:update()
    -- Determine if cursor is hovering over this
    -- TODO: probably move logic to cursor / use states n shit but this is ok for a draft
    local overlapping = self:overlappingSprites()
    local isCursorHovering = false
    for _,other in pairs(overlapping) do
        if other:getTag() == TAGS.CURSOR then
            isCursorHovering = true
            break
        end
    end
    self:setVisible(isCursorHovering)
end

-- ================================================================================
-- Edit Name Text Input
-- ================================================================================
class('EditNameTextInput').extends(gfx.sprite)

function EditNameTextInput:init(inputText, width)
    self.text = inputText
    self.inputWidth = width

    self:renderUI()

    self:setCenter(0, 0.5)
    self:moveTo(0, SCREEN_CENTER_Y)
    self:setZIndex(Z_INDEX.TOP)
end

function EditNameTextInput:renderUI()
    -- TODO: figure out how to do this without completely rebuilding it?
    self.textInputUI = playout.tree.new(self:createTextInputUI())
    local textInputImage = self.textInputUI:draw()
    local spriteImage = gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)
    gfx.pushContext(spriteImage)
        -- Draw dithered background TODO: cache this maybe
        local filledRect = gfx.image.new(spriteImage.width, spriteImage.height, gfx.kColorBlack)
        filledRect:drawFaded(0, 0, 0.75, gfx.image.kDitherTypeBayer8x8)
        textInputImage:draw(0, spriteImage.height / 3)
    gfx.popContext()
    self:setImage(spriteImage)
end

function EditNameTextInput:createTextInputUI()
    self.nameTextUI = text(
        self.text,
        {
            id = 'name-input-text',
            style = kNameTextStyle,
        }
    )
    return box({
        width = self.inputWidth,
        hAlign = playout.kAlignCenter,
        vAlign = playout.kAlignCenter,
        border = 2,
        borderRadius = 9,
        backgroundColor = gfx.kColorWhite,
        paddingTop = 6,
        paddingBottom = 6,
    }, {
        self.nameTextUI,
    })
end

function EditNameTextInput:updateText(newText)
    self.text = newText
    -- TODO: just update tree
    self:renderUI()
end
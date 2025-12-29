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
function StatusPanel:init(panelWidth, cursor)
    StatusPanel.super.init(self)
    self.cursor = cursor
    -- --------------------------------------------------------------------------------
    -- Data
    -- --------------------------------------------------------------------------------
    -- To be set after initialization
    self.chao = nil
    -- Register listener for when ring value updates
    RING_MASTER:registerRingListener('status-panel', function ()
        self:updateRings()
        self:updateUI(true)
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

-- Set self.chao, update UI nodes, and re-draw UI.
function StatusPanel:setChao(chao)
    self.chao = chao
    self:updateChaoName()
    self:createOrUpdateEditNameClickTarget()
    self:updateMood()
    self:updateBelly()
    self:updateStats()
    self:updateUI()
end

-- --------------------------------------------------------------------------------
-- Top Level UI
-- --------------------------------------------------------------------------------

-- Initialize UI tree and set image.
function StatusPanel:initializeUI()
    -- Initialize images to use for progress bars
    self:initializeProgressBarImages()
    -- Build and render UI.
    self.panelUI = playout.tree.new(self:createPanelUI())
    local panelImage = self.panelUI:draw()
    self:setImage(panelImage)
    -- Create edit name click target.
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
-- Set recomputeLayout to true to call self.panelUI:layout() before drawing.
function StatusPanel:updateUI(recomputeLayout)
    if recomputeLayout == true then
        self.panelUI:layout()
    end
    self.panelUI:draw()
end

-- --------------------------------------------------------------------------------
-- Name UI + Edit Click Target
-- --------------------------------------------------------------------------------

-- Returns UI node for name section.
-- Sets self.nameTextNode and self.nameContainer.
function StatusPanel:createNameUI()
    local name = self.chao == nil and '' or self.chao.data.name
    self.nameTextNode = text(name, {
        id = 'name-text',
        style = kNameTextStyle,
    })

    self.nameContainer = box({
            id = 'name-container',
            minWidth = 66,
        },
        {
            self.nameTextNode,
        }
    )
    return self.nameContainer
end

-- Update Chao name to match self.chao.
-- Also recomputes panel UI layout and updates edit name click target.
function StatusPanel:updateChaoName()
    local name = self.chao == nil and '' or self.chao.data.name
    self.nameTextNode.text = name
    -- Need to recompute layout so we can update edit click target.
    self.panelUI:layout()
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
        self.editNameClickTarget = EditNameClickTarget(self)
    else
        self.editNameClickTarget.chao = self.chao
        -- TODO: just calculate rect size once!! No sense in doing anything but the largest
        self.editNameClickTarget:updateRect()
    end
end

-- --------------------------------------------------------------------------------
-- Mood UI
-- --------------------------------------------------------------------------------

-- Returns UI node for mood section.
-- Sets self.moodProgressBar.
function StatusPanel:createMoodUI()
    local mood = self.chao == nil and 0 or self.chao.data.mood
    local moodUI, moodProgressBar, _ = self:createBarUI('Mood', mood, nil)
    self.moodProgressBar = moodProgressBar
    return moodUI
end

-- Updates mood progress bar to match self.chao's data.
function StatusPanel:updateMood()
    self:updateProgressBar(self.moodProgressBar, self.chao.data.mood)
end

-- --------------------------------------------------------------------------------
-- Belly UI
-- --------------------------------------------------------------------------------

-- Returns UI node for belly section.
-- Sets self.bellyProgressBar.
function StatusPanel:createBellyUI()
    local belly = self.chao == nil and 0 or self.chao.data.belly
    local bellyUI, bellyProgressBar, _ = self:createBarUI('Belly', belly, nil)
    self.bellyProgressBar = bellyProgressBar
    return bellyUI
end

-- Updates belly progress bar to match self.chao's data.
function StatusPanel:updateBelly()
    self:updateProgressBar(self.bellyProgressBar, self.chao.data.belly)
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
        for i=1,#kStatIndexesInOrder do
            local statIndex = kStatIndexesInOrder[i]
            stats[statIndex] = {
                level = 0,
                progress = 0,
            }
        end
    end

    -- Will store level text nodes and progress bar containers for each stat so we can update them later.
    self.statsUI = {}
    -- List of UI nodes for each stat section
    local statsUIChildren = {}
    for i=1,#kStatIndexesInOrder do
        local statIndex = kStatIndexesInOrder[i]
        local statData = stats[statIndex]
        local title = statIndex:gsub("^%l", string.upper)
        local statUI, statProgressBar, statLevelText = self:createStatUI(title, statData)
        -- Append node to children
        statsUIChildren[#statsUIChildren+1] = statUI
        -- Store progress bar and level text for UI updates.
        self.statsUI[statIndex] = {
            progressBar = statProgressBar,
            levelText = statLevelText,
        }
    end

    -- TODO: JUST RETURN statsUIChildren unpacked?
    return box(
        {},
        statsUIChildren
    )
end

-- Create a single stat section.
function StatusPanel:createStatUI(statName, statData)
    local progress = statData == nil and 0 or statData.progress
    local level = statData == nil and 0 or statData.level
    return self:createBarUI(statName, progress, level)
end

-- Update progress bar and level to match self.chao's data based for the specified stat index.
function StatusPanel:updateStatUI(statIndex)
    local statNodes = self.statsUI[statIndex]
    local chaoStatData = self.chao.data.stats[statIndex]
    self:updateProgressBar(statNodes.progressBar, chaoStatData.progress)
    self:updateLevelText(statNodes.levelText, chaoStatData.level)
end

-- Update all stats UI sections.
function StatusPanel:updateStats()
    for i=1,#kStatIndexesInOrder do
        local statIndex = kStatIndexesInOrder[i]
        self:updateStatUI(statIndex)
    end
end

-- --------------------------------------------------------------------------------
-- Bar UI (mood, belly, stats sections)
-- --------------------------------------------------------------------------------

-- Create a bar UI section with optional level text.
-- Returns 3 values:
--  1. The entire bar section UI container node
--  2. The progress bar image node
--  3. The level text node
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
    local progressBarImage = image(self:getProgressBarImage(progress))

    -- Top level container
    local barSectionContainer = box({
            style = kBarUIContainerStyle,
        },
        {
            titleContainer,
            progressBarImage,
        }
    )

    return barSectionContainer, progressBarImage, levelText
end

-- Initialize images for progress bar chunks. Must be called before accessing self.progressBarImages.
-- NOTE: relies on self.panelWidth for sizing.
function StatusPanel:initializeProgressBarImages()
    -- Calculate full bar width (panel size - padding)
    local fullBarWidth <const> = self.panelWidth - (STYLE_ROOT_PANEL.paddingLeft + STYLE_ROOT_PANEL.paddingRight)
    -- Progress chunk width is 1/10 of the full bar
    local progressChunkWidth <const> = fullBarWidth // 10
    -- Initialize filled and empty progress bar chunk images
    local progressChunkEmpty = gfx.image.new(progressChunkWidth, kProgressBarChunkStyle.height)
    gfx.pushContext(progressChunkEmpty)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.setLineWidth(kProgressBarChunkStyle.border)
        gfx.drawRoundRect(0, 0, progressChunkWidth, kProgressBarChunkStyle.height, kProgressBarChunkStyle.borderRadius)
    gfx.popContext()
    local progressChunkFilled = gfx.image.new(progressChunkWidth, kProgressBarChunkStyle.height)
    gfx.pushContext(progressChunkFilled)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.fillRoundRect(0, 0, progressChunkWidth, kProgressBarChunkStyle.height, kProgressBarChunkStyle.borderRadius)
    gfx.popContext()
    -- Generate pre-calculated images for progress bars.
    -- (And yeah we're indexing from 0 cuz it makes sense here, bite me Lua).
    self.progressBarImages = {}
    for i=0,10 do
        local progressBarImage = gfx.image.new(fullBarWidth, kProgressBarChunkStyle.height)
        gfx.pushContext(progressBarImage)
            for chunk=1,10 do
                local chunkImage = chunk <= i and progressChunkFilled or progressChunkEmpty
                local x = (chunk - 1) * progressChunkWidth
                chunkImage:draw(x, 0)
            end
        gfx.popContext()
        self.progressBarImages[i] = progressBarImage
    end
end

-- Returns an image for a progress bar representing the specified progress percent.
function StatusPanel:getProgressBarImage(progress)
    local progressInt = progress // 10
    -- Validate
    if progressInt < 0 then
        progressInt = 0
    elseif progressInt > 10 then
        progressInt = 10
    end
    
    return self.progressBarImages[progressInt]
end

-- Takes a progress bar image node created by the above function and updates it based on the progress parameter.
function StatusPanel:updateProgressBar(progressBarImageNode, progress)
    local progressBarImage = self:getProgressBarImage(progress)
    progressBarImageNode.img = progressBarImage
end

-- Takes a level text node created by the above function and updates it based on the level paramter.
function StatusPanel:updateLevelText(levelTextNode, level)
    local levelText = level == nil and '' or 'LV ' .. level
    levelTextNode.text = levelText
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
-- TODO: try and optimize like the stats panel
-- TODO: !!!!!!!!

-- TODO: !!!!!!!!
-- TODO: Freeze game when edit menu is open!!!!!! it lags otherwise
-- TODO: !!!!!!!!

function EditNameClickTarget:init(statusPanel)
    EditNameClickTarget.super.init(self)

    self.statusPanel = statusPanel
    self.chao = statusPanel.chao
    self.nameContainer = statusPanel.nameContainer
    self.cursor = statusPanel.cursor

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

-- TODO: just precalculate this rect, don't bother resizing it!!!
function EditNameClickTarget:updateRect()
    local nameContainerRect = self.nameContainer.rect
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
    -- TODO: cache self bounds rect
    -- TODO: account for shifted cursor collision rect
    local isCursorHovering = self:getBoundsRect():intersects(self.cursor:getBoundsRect())
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
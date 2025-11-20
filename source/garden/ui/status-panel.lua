local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Constants
-- ===============================================================================

-- --------------------------------------------------------------------------------
-- Playout Shorthands
-- --------------------------------------------------------------------------------
local box <const> = playout.box.new
local image <const> = playout.image.new
local text <const> = playout.text.new
-- --------------------------------------------------------------------------------
-- Fonts
-- --------------------------------------------------------------------------------
local kFonts <const> = {
    -- Chao name
    name = gfx.getSystemFont(gfx.font.kVariantBold),
    -- Bar UI title
    title = gfx.font.new('fonts/diamond_12'),
    -- Stat UI level
    level = gfx.font.new('fonts/dpaint_8'),
}
-- --------------------------------------------------------------------------------
-- Styles
-- --------------------------------------------------------------------------------
-- Root panel UI
local kRootPanelStyle <const> = {
    -- Note: Width to be set based on self.panelWidth when UI is created
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
    self.panelUI = playout.tree.new(self:createPanelUI())
    local panelImage = self.panelUI:draw()
    self:setImage(panelImage)
    self:createEditNameClickTarget()
end

-- Build Menu UI
function StatusPanel:createPanelUI()
    local outerPanelBoxProps = {
        id = 'status-panel-root',
        style = kRootPanelStyle,
        width = self.panelWidth,
    }

    return box(outerPanelBoxProps, {
        self:createNameUI(),
        self:createMoodBellyUI(),
        self:createStatsUI(),
    })
end

function StatusPanel:createNameUI()
    local name = self.chao == nil and '' or self.chao.data.name
    local nameText = text(name, {
        id = 'name-text',
        style = kNameTextStyle,
    })

    return box({
            id = 'name-container',
            minWidth = 66,
        },
        {
            nameText,
        }
    )
end

function StatusPanel:createMoodBellyUI()
    local mood = self.chao == nil and 0 or self.chao.data.mood
    local belly = self.chao == nil and 0 or self.chao.data.belly

    local moodUI = self:createBarUI('Mood', mood, nil)
    local bellyUI = self:createBarUI('Belly', belly, nil)

    return box(
        {},
        {
            moodUI,
            bellyUI,
        }
    )
end

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

    return box(
        {},
        statsUIChildren
    )
end

function StatusPanel:createStatUI(statName, statData)
    local progress = statData == nil and 0 or statData.progress
    local level = statData == nil and 0 or statData.level
    return self:createBarUI(statName, progress, level)
end

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

-- Create/update edit name click target
function StatusPanel:createEditNameClickTarget()
    if self.panelUI == nil then
        return
    end
    local nameContainer = self.panelUI:get('name-container')
    if self.editNameClickTarget == nil then
        self.editNameClickTarget = EditNameClickTarget(nameContainer.rect, self.chao)
    else
        self.editNameClickTarget.chao = self.chao
        self.editNameClickTarget:updateRect(nameContainer.rect)
    end
end

-- ================================================================================
-- Edit Name Sprite
-- ================================================================================
class('EditNameClickTarget').extends(gfx.sprite)

function EditNameClickTarget:init(nameContainerRect, chao)
    EditNameClickTarget.super.init(self)

    self.chao = chao

    self.stroke = 2
    self.hPadding = self.stroke + 2
    self:updateRect(nameContainerRect)

    -- Collisions
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
    self:setTag(TAGS.CLICK_TARGET)

    -- Set Z-index to a high value, but not as high as the cursor
    self:setZIndex(100)
    -- Invisible by default
    self:setVisible(false)

    self:add()
end

function EditNameClickTarget:updateRect(nameContainerRect)
    local hPaddingAdding = 2 * self.hPadding
    self:setSize(nameContainerRect.width + hPaddingAdding, nameContainerRect.height)
    self:moveTo(nameContainerRect:centerPoint())
    self:updateHoverImage()
end

function EditNameClickTarget:updateHoverImage()
    local img = gfx.image.new(self:getSize())
    gfx.pushContext(img)
        gfx.setLineWidth(self.stroke)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.drawRect(0, 0, self:getSize())
    gfx.popContext()
    self:setImage(img)
    self:setCollideRect(0, 0, self:getSize())
end

function EditNameClickTarget:click(cursor)
    local currentName = self.chao ~= nil and self.chao.data.name or ''
    -- Freeze cursor until keyboard is hidden
    cursor:disable()
    pd.keyboard.keyboardDidHideCallback = function ()
        -- TODO: update chao name data + UI display
        cursor:enable()
    end
    
    pd.keyboard.textChangedCallback = function ()
        local txt = pd.keyboard.text
        if string.len(txt) > 7 then
            pd.keyboard.text = string.sub(txt, 1, 7)
        end
        -- TODO: DEBUGGING
        print(pd.keyboard.text)
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
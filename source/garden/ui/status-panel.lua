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
local kTitleFont <const> = gfx.font.new('fonts/diamond_12')
local kLevelFont <const> = gfx.font.new('fonts/dpaint_8')
-- --------------------------------------------------------------------------------
-- Styles
-- --------------------------------------------------------------------------------
local kTitleStyle <const> = {
    fontFamily = kTitleFont,
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
    local panelUI = playout.tree.new(self:createPanelUI())
    local panelImage = panelUI:draw()
    self:setImage(panelImage)
end

-- Build Menu UI
function StatusPanel:createPanelUI()
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
        self:createMoodBellyUI(),
        self:createStatsUI(),
    })
end

function StatusPanel:createNameUI()
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
        fontFamily = kTitleFont,
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
            flex = 2,
            alignment = kTextAlignment.left,
            style = kTitleStyle,
        }
    )
    local levelText = text(
        level == nil and '' or 'LV ' .. level,
        {
            flex = 1,
            alignment = kTextAlignment.right,
            fontFamily = kLevelFont,
        }
    )
    local titleContainer = box({
            direction = playout.kDirectionHorizontal,
            vAlign = playout.kAlignCenter,
        },
        {
            titleText,
            levelText,
        }
    )
    -- Progress bar
    local progressBarContainer = self:createProgressBar(progress)

    return box({
            spacing = 3,
            hAlign = playout.kAlignCenter,
            paddingBottom = 5,
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
            flex = 1,
            height = 6,
            border = 1,
            borderRadius = 3,
            backgroundColor = filled and gfx.kColorBlack or gfx.kColorWhite,
        })
        progressBarChildren[i] = progressChunkBox
    end

    return box({
            direction = playout.kDirectionHorizontal,
            vAlign = playout.kAlignCenter,
        },
        progressBarChildren)
end
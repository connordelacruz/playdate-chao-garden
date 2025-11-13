local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Transition Helpers
-- ===============================================================================
-- Pre-compute fade out rects since it's expensive 
-- TODO: get a better idea of how this works and document it
local fadedRects = {}
for i = 0, 1, 0.01 do
    local fadedImage = gfx.image.new(400, 240)
    gfx.pushContext(fadedImage)
    local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
    filledRect:drawFaded(0, 0, i, gfx.image.kDitherTypeBayer8x8)
    gfx.popContext()
    fadedRects[math.floor(i * 100)] = fadedImage
end
-- Loop doesn't add last image, so here it is manually
fadedRects[100] = gfx.image.new(400, 240, gfx.kColorBlack)

-- ===============================================================================
-- Scene Manager Class
-- 
-- Based on https://github.com/SquidGodDev/Playdate-Scene-Management
-- ===============================================================================
class('SceneManager').extends()

-- TODO: this is fine for prototyping, but he mentions some drawbacks in his video that would be important to consider:
--          https://youtu.be/3LoMft137z8?si=030EkkgOlddfg976&t=802
-- TODO: most pressing (pun not intended) is that inputs still get parsed mid transition

function SceneManager:init()
    self.transitionTime = 1000
    self.transitioning = false
end

function SceneManager:switchScene(scene, ...)
    if self.transitioning then
        return
    end
    self.transitioning = true

    self.newScene = scene
    local args = {...}
    self.sceneArgs = args

    self:startTransition()
end

function SceneManager:startTransition()
    -- Fade out old scene timer
    local transitionTimer = self:fadeTransition(0, 1)
    transitionTimer.timerEndedCallback = function ()
        self:loadNewScene()
        -- Fade in new scene timer
        transitionTimer = self:fadeTransition(1, 0)
        transitionTimer.timerEndedCallback = function ()
            self.transitioning = false
            self.transitionSprite:remove()
            -- TODO: figure out what this is about?:
            -- Temp fix to resolve bug with sprite artifacts/smearing after transition
            -- local allSprites = gfx.sprite.getAllSprites()
            -- for i = 1, #allSprites do
            --     allSprites[i]:markDirty()
            -- end
        end
    end
end

function SceneManager:fadeTransition(startValue, endValue)
    local transitionSprite = self:createTransitionSprite()
    transitionSprite:setImage(self:getFadedImage(startValue))

    local transitionTimer = pd.timer.new(self.transitionTime, startValue, endValue, pd.easingFunctions.inOutCubic)
    transitionTimer.updateCallback = function(timer)
        transitionSprite:setImage(self:getFadedImage(timer.value))
    end
    return transitionTimer
end

function SceneManager:createTransitionSprite()
    -- TODO: is it necessary to set an image here if we're immediately overriding it??
    -- TODO: screen size/center constants
    local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
    local transitionSprite = gfx.sprite.new(filledRect)
    transitionSprite:moveTo(200, 120)
    transitionSprite:setZIndex(10000)
    transitionSprite:setIgnoresDrawOffset(true)
    transitionSprite:add()
    -- TODO: is this really necessary if we're also returning it? or vice versa?
    self.transitionSprite = transitionSprite
    return transitionSprite
end

-- TODO: explain
function SceneManager:getFadedImage(alpha)
    return fadedRects[math.floor(alpha * 100)]
end

function SceneManager:loadNewScene()
    self:cleanupScene()
    -- Initialize scene class stored in self.newScene
    self.newScene(table.unpack(self.sceneArgs))
end

function SceneManager:cleanupScene()
    -- Remove all sprites
    gfx.sprite.removeAll()
    -- Remove timers
    self:removeAllTimers()
end

function SceneManager:removeAllTimers()
    local timers = pd.timer.allTimers()
    for _, timer in ipairs(timers) do
        timer:remove()
    end
end
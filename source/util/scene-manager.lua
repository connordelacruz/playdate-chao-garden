local pd <const> = playdate
local gfx <const> = pd.graphics

-- ===============================================================================
-- Scene Manager Class
-- 
-- Based on https://github.com/SquidGodDev/Playdate-Scene-Management
-- ===============================================================================
class('SceneManager').extends()

function SceneManager:switchScene(scene, ...)
    self.newScene = scene
    self.sceneArgs = ...

    self:loadNewScene()
end

function SceneManager:loadNewScene()
    self:cleanupScene()
    -- Initialize scene class stored in self.newScene
    self.newScene(self.sceneArgs)
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
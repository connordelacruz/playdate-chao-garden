local pd <const> = playdate

-- ===============================================================================
-- Constants
-- ===============================================================================
local kTrackPaths <const> = {
    garden = 'sounds/music/garden',
}

-- ===============================================================================
-- Music Manager Class
-- ===============================================================================
class('MusicManager').extends()

function MusicManager:init()
    -- TODO: set volume a little lower?
    self.player = pd.sound.fileplayer.new()
    -- TODO: menu item to toggle music on/off, save config and load here
end

-- --------------------------------------------------------------------------------
-- Player Controls
-- --------------------------------------------------------------------------------

function MusicManager:play()
    local loadedSuccessfully, error = self.player:play(0)
    -- DEBUG
    if loadedSuccessfully then
        DEBUG_MANAGER:vPrint('MusicManager: Track loaded successfully.')
    else
        DEBUG_MANAGER:vPrint('MusicManager: ERROR: Unable to play track:')
        DEBUG_MANAGER:vPrint(error, 1)
    end
end

function MusicManager:pause()
    self.player:pause()
end

function MusicManager:stop()
    self.player:stop()
end

function MusicManager:loadAndPlay(path)
    self.player:stop()
    self.player:load(path)
    self:play()
end

-- --------------------------------------------------------------------------------
-- Play Specific Tracks
-- --------------------------------------------------------------------------------

function MusicManager:playGardenTheme()
    self:loadAndPlay(kTrackPaths.garden)
end
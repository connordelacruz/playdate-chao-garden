local pd <const> = playdate

-- ===============================================================================
-- Constants
-- ===============================================================================
-- File paths to tracks.
-- NOTE: For some reason, extension must be omitted, even though no error is thrown
--       when player attempts to load it with extension.
local kTrackPaths <const> = {
    garden = 'sounds/music/garden',
}
-- Volume level to set player to when not muted.
local kPlayerVolume <const> = 0.8

-- ===============================================================================
-- Music Manager Class
-- ===============================================================================
class('MusicManager').extends()

function MusicManager:init()
    self.player = pd.sound.fileplayer.new()
    self.player:setVolume(kPlayerVolume)
    -- TODO: save/load music playback setting
    -- Menu item for toggling music playback
    self:registerMenuItem()
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

function MusicManager:mute()
    self:stop()
    self.player:setVolume(0.0)
end

function MusicManager:unmute(play)
    self.player:setVolume(kPlayerVolume)
    if play then
        self:play()
    end
end

function MusicManager:togglePlayback(play)
    if play then
        self:unmute(true)
    else
        self:mute()
    end
end

-- --------------------------------------------------------------------------------
-- System Menu Options
-- --------------------------------------------------------------------------------

function MusicManager:registerMenuItem()
    local menu = pd.getSystemMenu()
    -- TODO: load saved prefs, use that as default
    local toggleMusicMenuItem, error = menu:addCheckmarkMenuItem(
        'play music', true, function (val)
            DEBUG_MANAGER:vPrint('MusicManager: Music playback set to ' .. tostring(val))
            self:togglePlayback(val)
        end
    )
    if toggleMusicMenuItem == nil then
        DEBUG_MANAGER:vPrint('MusicManager: Unable to add music playback menu item:')
        DEBUG_MANAGER:vPrint(error, 1)
    end
end

-- --------------------------------------------------------------------------------
-- Play Specific Tracks
-- --------------------------------------------------------------------------------

function MusicManager:playGardenTheme()
    self:loadAndPlay(kTrackPaths.garden)
end
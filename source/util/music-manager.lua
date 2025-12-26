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
-- Filename where playback prefs are stored
local kDataFilename <const> = 'music-prefs-data'

-- ===============================================================================
-- Music Manager Class
-- ===============================================================================
class('MusicManager').extends()

function MusicManager:init()
    self.player = pd.sound.fileplayer.new()
    self.player:setVolume(kPlayerVolume)
    -- Load saved music playback prefs
    self:loadData()
    -- Register save function
    DATA_MANAGER:registerSaveFunction(kDataFilename, function ()
        self:saveData()
    end)
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
    self:stop()
    self.player:load(path)
    if self.playMusic then
        self:play()
    end
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
    self.playMusic = play
    if play then
        self:unmute(true)
    else
        self:mute()
    end
end

-- --------------------------------------------------------------------------------
-- System Menu Options + Save/Load Prefs
-- --------------------------------------------------------------------------------

function MusicManager:registerMenuItem()
    local menu = pd.getSystemMenu()
    local toggleMusicMenuItem, error = menu:addCheckmarkMenuItem(
        'play music', self.playMusic, function (val)
            DEBUG_MANAGER:vPrint('MusicManager: Music playback set to ' .. tostring(val))
            self:togglePlayback(val)
        end
    )
    if toggleMusicMenuItem == nil then
        DEBUG_MANAGER:vPrint('MusicManager: Unable to add music playback menu item:')
        DEBUG_MANAGER:vPrint(error, 1)
    end
end

function MusicManager:saveData()
    local data = {playMusic = self.playMusic}
    DEBUG_MANAGER:vPrint('MusicManager:saveData() called. Data:')
    DEBUG_MANAGER:vPrintTable(data)
    pd.datastore.write(data, kDataFilename)
end

function MusicManager:loadData()
    local loadedData = pd.datastore.read(kDataFilename)
    if loadedData == nil then
        DEBUG_MANAGER:vPrint('MusicManager: no save data found.')
        self:togglePlayback(true)
    else
        DEBUG_MANAGER:vPrint('MusicManager: save data found. Play music setting = ' .. tostring(loadedData.playMusic))
        self:togglePlayback(loadedData.playMusic)
    end
end

-- --------------------------------------------------------------------------------
-- Play Specific Tracks
-- --------------------------------------------------------------------------------

function MusicManager:playGardenTheme()
    self:loadAndPlay(kTrackPaths.garden)
end
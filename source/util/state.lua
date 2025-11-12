local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- State "interface" for FSM pattern.
-- 
-- Mostly implementing so exit() and enter() are optional for classes extending this.
-- ================================================================================
class('State').extends()

-- Constructor should be overridden.
function State:init(object)
    self.object = object
end

-- Method called when we switch to this state.
-- (Optional to implement)
function State:enter()
    return
end

-- Method called each frame.
-- (Must be implemented, otherwise what are you doing lol)
function State:update()
    return
end

-- Method called when we switch out of this state.
-- (Optional to implement)
function State:exit()
    return
end

-- ================================================================================
-- "Interface" for sprites that implement FSM states.
--
-- Note: Classes that implement this MUST initialize self.state and self.states
--       in their init() function.
-- ================================================================================
class('FSMSprite').extends(gfx.sprite)

-- Switch to a new state.
-- Note: newState must be a valid key into self.states.
--       self.state must be an instance of a State object.   
function FSMSprite:setState(newState)
    self.state:exit()
    self.state = self.states[newState]
    self.state:enter()
end

-- Shorthand to set initial state.
-- (Basicall the same as setState() but doesn't call exit() because there's no old state)
function FSMSprite:setInitialState(initialState)
    self.state = self.states[initialState]
    self.state:enter()
end

-- Delegate update() to current state.
function FSMSprite:update()
    self.state:update()
end
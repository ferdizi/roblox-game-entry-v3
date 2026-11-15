-- Coin Rush: keyboard input. Movement is polled every frame with IsKeyDown,
-- which sees the arrow keys even though Roblox's camera scripts take them.
-- Menu keys (Enter to start, R to restart) go through ContextActionService.

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Input = {}

local MOVE_KEYS = {
	left = { Enum.KeyCode.Left, Enum.KeyCode.A },
	right = { Enum.KeyCode.Right, Enum.KeyCode.D },
	up = { Enum.KeyCode.Up, Enum.KeyCode.W },
	down = { Enum.KeyCode.Down, Enum.KeyCode.S },
}

local function anyDown(keys)
	for _, key in ipairs(keys) do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

-- Returns a unit-ish direction vector from the held movement keys.
function Input.getMoveVector()
	local dx = 0
	local dy = 0
	if anyDown(MOVE_KEYS.left) then
		dx -= 1
	end
	if anyDown(MOVE_KEYS.right) then
		dx += 1
	end
	if anyDown(MOVE_KEYS.up) then
		dy -= 1
	end
	if anyDown(MOVE_KEYS.down) then
		dy += 1
	end
	if dx ~= 0 and dy ~= 0 then
		local len = math.sqrt(2)
		dx /= len
		dy /= len
	end
	return dx, dy
end

function Input.bindAction(name, key, callback)
	ContextActionService:BindAction(name, function(_, state)
		if state == Enum.UserInputState.Begin then
			callback()
		end
		return Enum.ContextActionResult.Sink
	end, false, key)
end

return Input

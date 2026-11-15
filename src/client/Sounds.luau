-- Coin Rush v2: tiny sound effects from Roblox's built-in sounds.
-- Every call is pcall-safe: if a sound cannot load, the game plays on silently.

local SoundService = game:GetService("SoundService")

local Sounds = {}

local BUILTIN_PING = "rbxasset://sounds/electronicpingshort.wav"

local cache = {}

local function play(pitch, volume)
	local ok = pcall(function()
		local sound = cache[pitch]
		if not sound then
			sound = Instance.new("Sound")
			sound.Name = "CoinRushSfx"
			sound.SoundId = BUILTIN_PING
			sound.Parent = SoundService
			cache[pitch] = sound
		end
		sound.PlaybackSpeed = pitch
		sound.Volume = volume
		sound:Play()
	end)
	return ok
end

function Sounds.playCoin()
	play(1.6, 0.5)
end

function Sounds.playStar()
	play(2.0, 0.6)
end

function Sounds.playHit()
	play(0.5, 0.7)
end

function Sounds.playLevel()
	play(1.2, 0.6)
end

function Sounds.playWin()
	play(1.8, 0.6)
end

function Sounds.playLose()
	play(0.4, 0.6)
end

function Sounds.playDash()
	play(2.4, 0.5)
end

function Sounds.playShield()
	play(1.0, 0.6)
end

function Sounds.playPowerup()
	play(1.4, 0.6)
end

return Sounds

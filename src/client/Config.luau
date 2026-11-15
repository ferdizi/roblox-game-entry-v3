-- Coin Rush v3: every tuning number lives here, in one place.
-- The game is a 2D dodge-and-collect arena: move with the arrow keys (or WASD),
-- grab coins, dodge the red blocks. v3 turns the three zones into FOUR VAULTS
-- with a quota each, adds a COMBO multiplier, a third enemy (the weaver), and
-- a boss finale: THE WARDEN. The round is won by beating the Warden, not by
-- the coin count alone.

local Config = {}

-- Arena (pixels, inside a centred frame).
Config.ARENA_WIDTH = 640
Config.ARENA_HEIGHT = 480
Config.PLAYER_SIZE = 44
Config.COIN_SIZE = 30
Config.STAR_SIZE = 36
Config.ENEMY_SIZE = 40
Config.WEAVER_SIZE = 36
Config.BOSS_SIZE = 84
Config.POWERUP_SIZE = 34

-- Round rules.
Config.ROUND_SECONDS = 150
Config.COINS_TO_WIN = 30
Config.LIVES = 3
Config.COINS_PER_LEVEL = 5
Config.MAX_COINS_ON_FIELD = 3
Config.COIN_SCORE = 100
Config.STAR_SCORE = 300
Config.STAR_SPAWN_SECONDS = 12
Config.STAR_LIFETIME = 6
Config.INVULNERABLE_SECONDS = 1.5

-- Vaults: 1 Meadow (coins 0-6, quota 7), 2 Desert (7-14, quota 8),
-- 3 Neon (15-22, quota 8), 4 Core (23-29, quota 7). At 30 coins the
-- Warden spawns and the round becomes the boss finale.
Config.VAULT_QUOTAS = { 7, 8, 8, 7 }
Config.ZONES = {
	{
		name = "MEADOW",
		arena = Color3.fromRGB(26, 46, 40),
		hud = Color3.fromRGB(18, 36, 30),
		accent = Color3.fromRGB(90, 200, 120),
		speedMult = 1.0,
	},
	{
		name = "DESERT",
		arena = Color3.fromRGB(52, 40, 26),
		hud = Color3.fromRGB(40, 30, 20),
		accent = Color3.fromRGB(255, 180, 80),
		speedMult = 1.05,
	},
	{
		name = "NEON",
		arena = Color3.fromRGB(34, 20, 52),
		hud = Color3.fromRGB(26, 16, 44),
		accent = Color3.fromRGB(120, 220, 255),
		speedMult = 1.1,
	},
	{
		name = "CORE",
		arena = Color3.fromRGB(52, 18, 28),
		hud = Color3.fromRGB(40, 14, 22),
		accent = Color3.fromRGB(255, 80, 120),
		speedMult = 1.15,
	},
}
function Config.zoneForCoins(coins)
	if coins >= 23 then
		return 4
	elseif coins >= 15 then
		return 3
	elseif coins >= 7 then
		return 2
	end
	return 1
end

-- Vault quota: how many coins into this vault charge the portal to the next.
-- vaultStart is the coin count at which the vault begins.
function Config.vaultStart(vault)
	local start = 0
	for i = 1, vault - 1 do
		start += Config.VAULT_QUOTAS[i]
	end
	return start
end

-- Combo: each pickup without taking a hit raises the multiplier by 1, up to
-- x5. A hit resets it to x1. The points for a pickup are base x combo.
Config.COMBO_MAX = 5

-- Dash: a short speed burst with brief invulnerability. Cooldown keeps it a
-- skill tool, not a spam button. Dashing through the Warden is how you hit it.
Config.DASH_DURATION = 0.25
Config.DASH_SPEED_MULT = 2.2
Config.DASH_INVULN_SECONDS = 0.3
Config.DASH_COOLDOWN_SECONDS = 2.0

-- Shield power-up: blocks the next hit, or expires after 10 seconds.
-- One shield orb spawns for every 6 coins collected (at 6, 12, 18 and 24).
Config.SHIELD_SECONDS = 10
Config.POWERUP_EVERY_COINS = 6
Config.POWERUP_LIFETIME = 10

-- The Warden (boss finale): spawns at 30 coins. A big chaser with 3 HP.
-- Dash through it to land a hit; 3 hits wins the round. If it is not beaten
-- in 30 seconds it retreats and the round is still a win (the player charged
-- all four vaults and survived the finale). The round timer pauses while the
-- Warden is up, so the finale is never cut short by the clock.
Config.BOSS_HP = 3
Config.BOSS_SPEED = 70
Config.BOSS_TIMEOUT_SECONDS = 30
Config.BOSS_HIT_COOLDOWN = 0.5

-- Speeds (pixels per second). Enemies get faster every level.
function Config.playerSpeed(level)
	return 340 * (1 + 0.04 * (level - 1))
end

function Config.drifterSpeed(level)
	return 65 + level * 10
end

function Config.chaserSpeed(level)
	return 50 + level * 7
end

-- Weavers sweep across the arena in a sine wave. They appear from level 3.
function Config.weaverSpeed(level)
	return 75 + level * 6
end

function Config.drifterCount(level)
	return math.min(1 + level, 5)
end

function Config.chaserCount(level)
	if level < 2 then
		return 0
	end
	return math.min(level - 1, 3)
end

function Config.weaverCount(level)
	if level < 3 then
		return 0
	end
	return math.min(level - 2, 2)
end

-- Palette: deep navy night, gold coins, coral danger.
Config.COLORS = {
	background = Color3.fromRGB(16, 20, 34),
	arena = Color3.fromRGB(31, 42, 68),
	arenaBorder = Color3.fromRGB(58, 74, 107),
	player = Color3.fromRGB(255, 201, 60),
	playerBorder = Color3.fromRGB(176, 124, 0),
	coin = Color3.fromRGB(255, 217, 77),
	star = Color3.fromRGB(77, 227, 255),
	drifter = Color3.fromRGB(255, 90, 90),
	chaser = Color3.fromRGB(255, 138, 60),
	weaver = Color3.fromRGB(190, 110, 255),
	boss = Color3.fromRGB(255, 60, 90),
	bossBorder = Color3.fromRGB(140, 10, 30),
	shield = Color3.fromRGB(90, 230, 140),
	powerup = Color3.fromRGB(90, 230, 140),
	text = Color3.fromRGB(242, 245, 255),
	muted = Color3.fromRGB(160, 175, 205),
	button = Color3.fromRGB(255, 201, 60),
	buttonText = Color3.fromRGB(20, 27, 46),
	overlay = Color3.fromRGB(10, 13, 24),
}

return Config

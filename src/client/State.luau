-- Coin Rush v3: the whole round state lives in this one module.
-- Modes: "menu" -> "playing" -> "won" or "lost". Nothing else writes these fields.
-- v3 adds the combo multiplier and the Warden boss finale. The round is won by
-- beating the Warden (3 dash-hits) or surviving its 30s timeout, not by coins.

local Config = require(script.Parent.Config)

local State = {}

State.mode = "menu"
State.score = 0
State.coins = 0
State.lives = Config.LIVES
State.level = 1
State.zone = 1
State.combo = 1
State.timeLeft = Config.ROUND_SECONDS
State.best = 0
State.invulnerableUntil = 0
State.dashUntil = 0
State.dashCooldownUntil = 0
State.shieldUntil = 0
-- Boss finale: true once the Warden spawns at 30 coins. The round timer
-- pauses while the boss is up; bossTimeLeft is the 30s retreat countdown.
State.bossActive = false
State.bossTimeLeft = Config.BOSS_TIMEOUT_SECONDS
State.bossDefeated = false
State.bossDrivenOff = false

function State.resetRound()
	State.mode = "playing"
	State.score = 0
	State.coins = 0
	State.lives = Config.LIVES
	State.level = 1
	State.zone = 1
	State.combo = 1
	State.timeLeft = Config.ROUND_SECONDS
	State.invulnerableUntil = 0
	State.dashUntil = 0
	State.dashCooldownUntil = 0
	State.shieldUntil = 0
	State.bossActive = false
	State.bossTimeLeft = Config.BOSS_TIMEOUT_SECONDS
	State.bossDefeated = false
	State.bossDrivenOff = false
end

function State.toMenu()
	State.mode = "menu"
end

function State.levelFromCoins(coins)
	return math.floor(coins / Config.COINS_PER_LEVEL) + 1
end

-- Adds points for a pickup, multiplied by the current combo, then raises the
-- combo by 1 (capped). Returns true when the pickup levelled the player up.
-- Also refreshes the zone; the caller checks State.zone to spot a zone change.
function State.addPickup(basePoints)
	local points = basePoints * State.combo
	State.score = State.score + points
	State.coins = State.coins + 1
	State.combo = math.min(State.combo + 1, Config.COMBO_MAX)
	State.zone = Config.zoneForCoins(State.coins)
	local newLevel = State.levelFromCoins(State.coins)
	if newLevel > State.level then
		State.level = newLevel
		return true
	end
	return false
end

-- A hit resets the combo to x1, on top of losing the life.
function State.loseLife(now)
	if now < State.invulnerableUntil then
		return false
	end
	State.lives = State.lives - 1
	State.combo = 1
	State.invulnerableUntil = now + Config.INVULNERABLE_SECONDS
	return true
end

function State.isInvulnerable(now)
	return now < State.invulnerableUntil
end

-- Dash: returns true when the dash started (off cooldown and playing).
function State.tryDash(now)
	if now < State.dashCooldownUntil then
		return false
	end
	State.dashUntil = now + Config.DASH_DURATION
	State.dashCooldownUntil = now + Config.DASH_COOLDOWN_SECONDS
	State.invulnerableUntil = math.max(State.invulnerableUntil, now + Config.DASH_INVULN_SECONDS)
	return true
end

function State.isDashing(now)
	return now < State.dashUntil
end

function State.dashCooldownLeft(now)
	return math.max(0, State.dashCooldownUntil - now)
end

-- Shield: blocks the next hit. Returns true when a shield was consumed.
function State.hasShield(now)
	return now < State.shieldUntil
end

function State.grantShield(now)
	State.shieldUntil = now + Config.SHIELD_SECONDS
end

-- Consuming a shield also grants a brief invulnerability window, so a second
-- enemy overlapping the player in the same frame cannot take a life right
-- after the shield absorbed the first hit.
function State.consumeShield(now)
	State.shieldUntil = 0
	State.invulnerableUntil = math.max(State.invulnerableUntil, now + 0.5)
end

function State.shieldSecondsLeft(now)
	return math.max(0, State.shieldUntil - now)
end

-- Boss finale: called when the 30th coin is collected.
function State.startBoss()
	State.bossActive = true
	State.bossTimeLeft = Config.BOSS_TIMEOUT_SECONDS
end

function State.tickTimer(dt)
	if State.mode ~= "playing" then
		return
	end
	-- The round timer pauses while the Warden is up; the boss countdown runs.
	if State.bossActive then
		State.bossTimeLeft = State.bossTimeLeft - dt
		if State.bossTimeLeft <= 0 then
			State.bossDrivenOff = true
		end
		return
	end
	State.timeLeft = State.timeLeft - dt
end

-- Coins are full: the boss phase begins. hasWon is only true once the boss
-- is beaten or driven off, so the finale always gets played.
function State.coinsFull()
	return State.coins >= Config.COINS_TO_WIN
end

function State.hasWon()
	return State.bossDefeated or State.bossDrivenOff
end

function State.hasLost()
	return State.lives <= 0 or (not State.bossActive and State.timeLeft <= 0)
end

function State.endRoundAsWin()
	State.mode = "won"
	if State.score > State.best then
		State.best = State.score
	end
end

function State.endRoundAsLoss()
	State.mode = "lost"
	if State.score > State.best then
		State.best = State.score
	end
end

return State

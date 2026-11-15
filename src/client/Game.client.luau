-- Coin Rush v3: the entrypoint. Builds the interface, runs the round loop,
-- and wires input, pickups, hits and the server's best score together.
-- Round end is decided in the loop, never inside an entity callback:
-- ending a round clears the entity tables, which the update loop is walking.
-- v3 adds the combo multiplier, four vaults with quotas, the weaver enemy,
-- and the Warden boss finale (dash through it 3 times to win).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)
local Entities = require(script.Parent.Entities)
local Input = require(script.Parent.Input)
local Sounds = require(script.Parent.Sounds)

local C = Config.COLORS

local playerX = 0
local playerY = 0
local events = nil
local lastDx, lastDy = 0, -1
local dashDirX, dashDirY = 0, -1
local lastTrailTime = 0
-- The 30th coin queues the boss finale, but the boss only spawns in the
-- main loop AFTER Entities.updateAll returns: spawning it inside a pickup
-- callback would clear the coin/enemy tables while updateAll is walking them.
local bossPending = false

local function centerPlayer()
	playerX = (Config.ARENA_WIDTH - Config.PLAYER_SIZE) / 2
	playerY = (Config.ARENA_HEIGHT - Config.PLAYER_SIZE) / 2
end

local function startRound()
	State.resetRound()
	Entities.clear()
	bossPending = false
	centerPlayer()
	lastDx, lastDy = 0, -1
	dashDirX, dashDirY = 0, -1
	lastTrailTime = 0
	Ui.setArenaTheme(1)
	Ui.setShieldRingVisible(false)
	Ui.setShieldChip(0)
	Ui.setDashCooldown(0)
	Ui.setBossBar(0)
	Ui.showPlaying()
	Ui.updateHud(State)
	Ui.placePlayer(playerX, playerY)
	Entities.spawnCoin()
	Entities.spawnCoin()
	Entities.spawnDrifter(1, 1)
	Entities.spawnDrifter(1, 1)
end

local function endRound(won)
	if won then
		State.endRoundAsWin()
	else
		State.endRoundAsLoss()
	end
	Entities.clear()
	if events ~= nil then
		pcall(function()
			events:FireServer("SubmitScore", State.score)
		end)
	end
	if won then
		Sounds.playWin()
		Ui.showWin(State)
	else
		Sounds.playLose()
		Ui.showLose(State)
	end
end

-- Dash in the current move direction, else the last direction faced.
-- Only while playing; the cooldown lives in State.
local function tryDash()
	if State.mode ~= "playing" then
		return
	end
	local now = os.clock()
	if State.tryDash(now) then
		local dx, dy = Input.getMoveVector()
		if dx == 0 and dy == 0 then
			dx, dy = lastDx, lastDy
		end
		dashDirX, dashDirY = dx, dy
		Sounds.playDash()
	end
end

-- Shared post-pickup work: zone change, HUD, level banner, shield orb.
-- The combo multiplier is applied inside State.addPickup; the popup shows
-- the points actually awarded (base x combo).
local function afterPickup(basePoints, x, y)
	local comboBefore = State.combo
	local oldZone = State.zone
	local levelledUp = State.addPickup(basePoints)
	local points = basePoints * comboBefore
	Ui.spawnPopup(x, y, "+" .. points .. (comboBefore >= 2 and (" x" .. comboBefore) or ""), C.coin)
	if State.zone ~= oldZone then
		Ui.setArenaTheme(State.zone)
		Ui.showZoneBanner(State.zone)
	end
	Ui.updateHud(State)
	if levelledUp then
		Sounds.playLevel()
		Ui.showLevelBanner(State.level)
	end
	if State.coins % Config.POWERUP_EVERY_COINS == 0 and State.coins < Config.COINS_TO_WIN then
		Entities.spawnPowerup(os.clock())
	end
	-- The 30th coin queues the boss finale; the loop spawns it once
	-- updateAll has finished walking the entity tables.
	if State.coinsFull() and not State.bossActive and not bossPending then
		bossPending = true
	end
end

-- Pickups and hits only change the state and play feedback here.
-- The loop below decides when the round is won or lost.
local callbacks = {
	onCoin = function(x, y)
		Ui.spawnBurst(x, y, C.coin)
		Sounds.playCoin()
		afterPickup(Config.COIN_SCORE, x, y)
	end,
	onStar = function(x, y)
		Ui.spawnBurst(x, y, C.star)
		Sounds.playStar()
		afterPickup(Config.STAR_SCORE, x, y)
	end,
	onPowerup = function(x, y)
		Ui.spawnBurst(x, y, C.powerup)
		Sounds.playPowerup()
		State.grantShield(os.clock())
		Sounds.playShield()
		Ui.setShieldRingVisible(true)
		Ui.placePlayer(playerX, playerY)
		Ui.setShieldChip(State.shieldSecondsLeft(os.clock()))
	end,
	onHit = function(enemy)
		local now = os.clock()
		-- A shield absorbs the hit: no life lost, no red flash, ring goes away.
		if State.hasShield(now) then
			State.consumeShield(now)
			Ui.setShieldRingVisible(false)
			Ui.setShieldChip(0)
			Sounds.playShield()
			return
		end
		if State.loseLife(now) then
			Sounds.playHit()
			Ui.flashHit()
			Ui.shakeArena()
			Ui.updateHud(State)
		end
	end,
}

-- Boss callbacks: dashing through the Warden lands a hit (3 hits wins);
-- touching it without dashing costs a life, but the Warden stays.
local bossCallbacks = {
	onBossHit = function(hpLeft)
		Sounds.playHit()
		Ui.setBossBar(hpLeft)
		Ui.spawnPopup(playerX + Config.PLAYER_SIZE / 2, playerY, "HIT!", C.boss)
		if hpLeft <= 0 then
			State.bossDefeated = true
		end
	end,
	onBossTouch = function()
		local now = os.clock()
		if State.hasShield(now) then
			State.consumeShield(now)
			Ui.setShieldRingVisible(false)
			Ui.setShieldChip(0)
			Sounds.playShield()
			return
		end
		if State.loseLife(now) then
			Sounds.playHit()
			Ui.flashHit()
			Ui.shakeArena()
			Ui.updateHud(State)
		end
	end,
}

Ui.build()
Entities.init(Ui.getArena())
centerPlayer()
Ui.placePlayer(playerX, playerY)
State.toMenu()
Ui.showMenu(State.best)
Ui.updateHud(State)

-- The server's best score is a bonus, never a blocker: look it up in the
-- background, and play on without it when it is not there.
task.spawn(function()
	local ok, remote = pcall(function()
		return ReplicatedStorage:WaitForChild("CoinRushEvents", 5)
	end)
	if not ok or remote == nil then
		return
	end
	events = remote
	remote.OnClientEvent:Connect(function(kind, value)
		if kind == "BestScore" and typeof(value) == "number" then
			State.best = math.max(State.best, value)
			if State.mode == "menu" then
				Ui.showMenu(State.best)
			end
		end
	end)
	pcall(function()
		remote:FireServer("AskBest")
	end)
end)

Ui.startButton.MouseButton1Click:Connect(startRound)
Ui.winAgainButton.MouseButton1Click:Connect(startRound)
Ui.loseAgainButton.MouseButton1Click:Connect(startRound)
Ui.dashButton.MouseButton1Click:Connect(tryDash)
Input.bindAction("CoinRushStart", Enum.KeyCode.Return, function()
	if State.mode == "menu" then
		startRound()
	end
end)
Input.bindAction("CoinRushRestart", Enum.KeyCode.R, function()
	if State.mode == "won" or State.mode == "lost" then
		startRound()
	end
end)
Input.bindAction("CoinRushDash", Enum.KeyCode.Space, tryDash)

RunService.RenderStepped:Connect(function(dt)
	if State.mode ~= "playing" then
		return
	end
	dt = math.min(dt, 0.1)
	local now = os.clock()

	local dx, dy = Input.getMoveVector()
	if dx ~= 0 or dy ~= 0 then
		lastDx, lastDy = dx, dy
	end

	-- Dashing locks the dash direction and multiplies speed; the trail
	-- ghosts mark the dash so it reads in a still screenshot.
	local moveX, moveY = dx, dy
	local speed = Config.playerSpeed(State.level)
	if State.isDashing(now) then
		moveX, moveY = dashDirX, dashDirY
		speed = speed * Config.DASH_SPEED_MULT
		if now - lastTrailTime >= 0.05 then
			lastTrailTime = now
			Ui.spawnDashGhost(playerX, playerY)
		end
	end
	if moveX ~= 0 or moveY ~= 0 then
		playerX = math.clamp(playerX + moveX * speed * dt, 0, Config.ARENA_WIDTH - Config.PLAYER_SIZE)
		playerY = math.clamp(playerY + moveY * speed * dt, 52, Config.ARENA_HEIGHT - Config.PLAYER_SIZE)
		Ui.placePlayer(playerX, playerY)
	end

	-- Blink while invulnerable after a hit.
	Ui.setPlayerVisible(not State.isInvulnerable(now) or math.floor(now * 10) % 2 == 0)

	local zoneMult = (Config.ZONES[State.zone] or Config.ZONES[1]).speedMult
	Entities.maintainSpawns(dt, State.level, now, zoneMult)
	Entities.updateAll(dt, playerX, playerY, State.level, now, callbacks)
	-- Boss finale starts here, after updateAll has finished its walk.
	if bossPending and not State.bossActive then
		bossPending = false
		State.startBoss()
		Entities.setBossActive(true)
		Entities.spawnBoss()
		Ui.setBossBar(Config.BOSS_HP)
		Ui.showBossBanner()
		Sounds.playLevel()
		Ui.updateHud(State)
	end
	if State.bossActive then
		Entities.updateBoss(dt, playerX, playerY, State.isDashing(now), now, bossCallbacks)
	end
	State.tickTimer(dt)
	Ui.updateHud(State)
	Ui.setDashCooldown(State.dashCooldownLeft(now))
	Ui.setShieldChip(State.shieldSecondsLeft(now))
	Ui.setShieldRingVisible(State.hasShield(now))

	if State.hasWon() then
		endRound(true)
	elseif State.hasLost() then
		endRound(false)
	end
end)

-- Coin Rush v3: coins, stars, power-ups and enemies. Spawning, movement and collisions.
-- Three pickup kinds (gold coin +100, rare star +300, shield power-up) and four
-- enemy kinds (drifters that cross the arena, chasers that steer at the player
-- from level 2, weavers that sweep in a sine wave from level 3, and the boss:
-- THE WARDEN, a big chaser the player beats by dashing through it 3 times).
-- Enemy speeds scale with the zone multiplier, so later vaults are faster
-- but never faster than the player.

local Config = require(script.Parent.Config)

local Entities = {}
local C = Config.COLORS

local arena
local coins = {}
local enemies = {}
local coinTimer = 0
local starTimer = 0
local enemyTimer = 0
local boss = nil
local bossActive = false
local lastBossHitAt = -10

local function roundedFrame(name, size, color, corner)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(corner, 0)
	uiCorner.Parent = frame
	frame.Parent = arena
	return frame
end

local function overlaps(ax, ay, asize, bx, by, bsize)
	return ax < bx + bsize and ax + asize > bx and ay < by + bsize and ay + asize > by
end

local function coinCount()
	local n = 0
	for _, coin in ipairs(coins) do
		if coin.kind == "coin" then
			n += 1
		end
	end
	return n
end

local function hasStar()
	for _, coin in ipairs(coins) do
		if coin.kind == "star" then
			return true
		end
	end
	return false
end

function Entities.hasPowerup()
	for _, coin in ipairs(coins) do
		if coin.kind == "powerup" then
			return true
		end
	end
	return false
end

local function drifterCount()
	local n = 0
	for _, enemy in ipairs(enemies) do
		if enemy.kind == "drifter" then
			n += 1
		end
	end
	return n
end

local function chaserCount()
	local n = 0
	for _, enemy in ipairs(enemies) do
		if enemy.kind == "chaser" then
			n += 1
		end
	end
	return n
end

local function weaverCount()
	local n = 0
	for _, enemy in ipairs(enemies) do
		if enemy.kind == "weaver" then
			n += 1
		end
	end
	return n
end

local function randomArenaPoint(size)
	local x = math.random(8, Config.ARENA_WIDTH - size - 8)
	local y = math.random(52, Config.ARENA_HEIGHT - size - 8)
	return x, y
end

function Entities.init(arenaFrame)
	arena = arenaFrame
end

function Entities.clear()
	for _, coin in ipairs(coins) do
		coin.frame:Destroy()
	end
	for _, enemy in ipairs(enemies) do
		enemy.frame:Destroy()
	end
	if boss ~= nil then
		boss.frame:Destroy()
		boss = nil
	end
	table.clear(coins)
	table.clear(enemies)
	coinTimer = 0
	starTimer = 0
	enemyTimer = 0
	bossActive = false
	lastBossHitAt = -10
end

-- While the Warden is up, no new pickups or enemies spawn: the finale is
-- one-on-one. Called by the round loop when the boss phase starts.
function Entities.setBossActive(active)
	bossActive = active
	if active then
		for _, coin in ipairs(coins) do
			coin.frame:Destroy()
		end
		for _, enemy in ipairs(enemies) do
			enemy.frame:Destroy()
		end
		table.clear(coins)
		table.clear(enemies)
	end
end

function Entities.spawnCoin()
	if coinCount() >= Config.MAX_COINS_ON_FIELD then
		return
	end
	local x, y = randomArenaPoint(Config.COIN_SIZE)
	local frame = roundedFrame("Coin", Config.COIN_SIZE, C.coin, 0.5)
	frame.BorderColor3 = Color3.fromRGB(176, 124, 0)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.fromOffset(x, y)
	table.insert(coins, { kind = "coin", frame = frame, x = x, y = y, size = Config.COIN_SIZE })
end

function Entities.spawnStar(now)
	if hasStar() then
		return
	end
	local x, y = randomArenaPoint(Config.STAR_SIZE)
	local frame = roundedFrame("Star", Config.STAR_SIZE, C.star, 0.5)
	frame.BorderColor3 = Color3.fromRGB(0, 120, 160)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.fromOffset(x, y)
	table.insert(coins, { kind = "star", frame = frame, x = x, y = y, size = Config.STAR_SIZE, bornAt = now })
end

-- Shield orb: one at a time, fades after its lifetime if never collected.
function Entities.spawnPowerup(now)
	if Entities.hasPowerup() then
		return
	end
	local x, y = randomArenaPoint(Config.POWERUP_SIZE)
	local frame = roundedFrame("Powerup", Config.POWERUP_SIZE, C.powerup, 0.5)
	frame.BorderColor3 = Color3.fromRGB(20, 120, 60)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.fromOffset(x, y)
	-- A white centre dot so the orb reads as a shield, not a coin.
	local dot = Instance.new("Frame")
	dot.Name = "ShieldDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(12, 12)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = dot
	dot.Parent = frame
	table.insert(coins, { kind = "powerup", frame = frame, x = x, y = y, size = Config.POWERUP_SIZE, bornAt = now })
end

-- Picks a point just outside one random edge and a velocity aimed into the arena.
local function edgeSpawn(speed)
	local edge = math.random(1, 4)
	local x, y, vx, vy
	if edge == 1 then -- left
		x, y = -Config.ENEMY_SIZE, math.random(52, Config.ARENA_HEIGHT - Config.ENEMY_SIZE)
		vx, vy = speed, math.random(-40, 40)
	elseif edge == 2 then -- right
		x, y = Config.ARENA_WIDTH, math.random(52, Config.ARENA_HEIGHT - Config.ENEMY_SIZE)
		vx, vy = -speed, math.random(-40, 40)
	elseif edge == 3 then -- top (below the HUD)
		x, y = math.random(0, Config.ARENA_WIDTH - Config.ENEMY_SIZE), 44 - Config.ENEMY_SIZE
		vx, vy = math.random(-40, 40), speed
	else -- bottom
		x, y = math.random(0, Config.ARENA_WIDTH - Config.ENEMY_SIZE), Config.ARENA_HEIGHT
		vx, vy = math.random(-40, 40), -speed
	end
	return x, y, vx, vy
end

function Entities.spawnDrifter(level, speedMult)
	speedMult = speedMult or 1
	local speed = Config.drifterSpeed(level) * speedMult
	local x, y, vx, vy = edgeSpawn(speed)
	local frame = roundedFrame("Drifter", Config.ENEMY_SIZE, C.drifter, 0.2)
	frame.BorderColor3 = Color3.fromRGB(140, 20, 20)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.fromOffset(x, y)
	table.insert(enemies, { kind = "drifter", frame = frame, x = x, y = y, vx = vx, vy = vy, speed = speed })
end

function Entities.spawnChaser(level, speedMult)
	speedMult = speedMult or 1
	local speed = Config.chaserSpeed(level) * speedMult
	local x, y, vx, vy = edgeSpawn(speed)
	local frame = roundedFrame("Chaser", Config.ENEMY_SIZE, C.chaser, 0.2)
	frame.BorderColor3 = Color3.fromRGB(140, 60, 0)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.fromOffset(x, y)
	table.insert(enemies, { kind = "chaser", frame = frame, x = x, y = y, vx = vx, vy = vy, speed = speed })
end

-- Weaver: sweeps horizontally across the arena in a sine wave. Spawns at a
-- random height on the left or right edge and crosses to the other side.
function Entities.spawnWeaver(level, speedMult)
	speedMult = speedMult or 1
	local speed = Config.weaverSpeed(level) * speedMult
	local fromLeft = math.random(1, 2) == 1
	local y = math.random(60, Config.ARENA_HEIGHT - Config.WEAVER_SIZE - 8)
	local x = fromLeft and -Config.WEAVER_SIZE or Config.ARENA_WIDTH
	local frame = roundedFrame("Weaver", Config.WEAVER_SIZE, C.weaver, 0.2)
	frame.BorderColor3 = Color3.fromRGB(110, 40, 180)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.fromOffset(x, y)
	table.insert(enemies, {
		kind = "weaver",
		frame = frame,
		x = x,
		y = y,
		baseY = y,
		phase = math.random() * math.pi * 2,
		dir = fromLeft and 1 or -1,
		speed = speed,
	})
end

-- THE WARDEN: the boss. A big slow chaser that spawns at the top centre of
-- the arena. Dash through it to land a hit (3 hits). It never despawns on
-- contact: it is only removed when beaten or when the round ends.
function Entities.spawnBoss()
	if boss ~= nil then
		return
	end
	local size = Config.BOSS_SIZE
	local x = (Config.ARENA_WIDTH - size) / 2
	local y = 60
	local frame = roundedFrame("Warden", size, C.boss, 0.2)
	frame.BorderColor3 = C.bossBorder
	frame.BorderSizePixel = 3
	frame.Position = UDim2.fromOffset(x, y)
	local mark = Instance.new("TextLabel")
	mark.Name = "WardenMark"
	mark.BackgroundTransparency = 1
	mark.Text = "!"
	mark.TextSize = 48
	mark.TextColor3 = Color3.fromRGB(255, 255, 255)
	mark.Font = Enum.Font.GothamBold
	mark.Size = UDim2.fromScale(1, 1)
	mark.Parent = frame
	boss = {
		frame = frame,
		x = x,
		y = y,
		hp = Config.BOSS_HP,
		speed = Config.BOSS_SPEED,
	}
end

function Entities.bossHp()
	if boss == nil then
		return 0
	end
	return boss.hp
end

function Entities.hasBoss()
	return boss ~= nil
end

-- Moves the Warden toward the player and resolves contact. A dashing player
-- HITS the Warden (one hit per 0.5s, then it is knocked back); a player who
-- touches it without dashing takes a hit like any enemy. callbacks:
-- { onBossHit = fn(hpLeft), onBossTouch = fn() }.
function Entities.updateBoss(dt, playerX, playerY, isDashing, now, callbacks)
	if boss == nil then
		return
	end
	local psize = Config.PLAYER_SIZE
	local size = Config.BOSS_SIZE
	-- Steer toward the player, slow and relentless.
	local dx = (playerX + psize / 2) - (boss.x + size / 2)
	local dy = (playerY + psize / 2) - (boss.y + size / 2)
	local len = math.sqrt(dx * dx + dy * dy)
	if len > 1 then
		boss.x += (dx / len) * boss.speed * dt
		boss.y += (dy / len) * boss.speed * dt
	end
	boss.x = math.clamp(boss.x, 0, Config.ARENA_WIDTH - size)
	boss.y = math.clamp(boss.y, 52, Config.ARENA_HEIGHT - size)
	boss.frame.Position = UDim2.fromOffset(math.floor(boss.x + 0.5), math.floor(boss.y + 0.5))

	if overlaps(playerX, playerY, psize, boss.x + 4, boss.y + 4, size - 8) then
		if isDashing and now - lastBossHitAt >= Config.BOSS_HIT_COOLDOWN then
			lastBossHitAt = now
			boss.hp -= 1
			-- Knockback away from the player so the next hit needs a fresh dash.
			local kx = (boss.x + size / 2) - (playerX + psize / 2)
			local ky = (boss.y + size / 2) - (playerY + psize / 2)
			local kl = math.sqrt(kx * kx + ky * ky)
			if kl > 1 then
				boss.x = math.clamp(boss.x + (kx / kl) * 90, 0, Config.ARENA_WIDTH - size)
				boss.y = math.clamp(boss.y + (ky / kl) * 90, 52, Config.ARENA_HEIGHT - size)
			end
			-- Flash white on a hit so it reads in a screenshot.
			boss.frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			task.delay(0.15, function()
				if boss ~= nil then
					boss.frame.BackgroundColor3 = C.boss
				end
			end)
			if boss.hp <= 0 then
				boss.frame:Destroy()
				boss = nil
			end
			callbacks.onBossHit(boss == nil and 0 or boss.hp)
		elseif not isDashing then
			callbacks.onBossTouch()
		end
	end
end

-- Keeps the field stocked: coins, the occasional star, and the level's enemies.
-- speedMult is the current zone's enemy speed multiplier (1.0 in vault 1).
-- Nothing spawns while the Warden is up.
function Entities.maintainSpawns(dt, level, now, speedMult)
	if bossActive then
		return
	end
	speedMult = speedMult or 1
	coinTimer += dt
	if coinTimer >= 0.8 then
		coinTimer = 0
		Entities.spawnCoin()
	end

	starTimer += dt
	if starTimer >= Config.STAR_SPAWN_SECONDS then
		starTimer = 0
		Entities.spawnStar(now)
	end

	enemyTimer += dt
	if enemyTimer >= 1.0 then
		enemyTimer = 0
		if drifterCount() < Config.drifterCount(level) then
			Entities.spawnDrifter(level, speedMult)
		elseif chaserCount() < Config.chaserCount(level) then
			Entities.spawnChaser(level, speedMult)
		elseif weaverCount() < Config.weaverCount(level) then
			Entities.spawnWeaver(level, speedMult)
		end
	end
end

-- Moves every enemy, expires old stars and power-ups, and reports pickups
-- and hits through callbacks. Pickup callbacks get the pickup's centre
-- (for the particle burst); onHit gets the enemy.
-- callbacks: { onCoin = fn(x, y), onStar = fn(x, y), onPowerup = fn(x, y), onHit = fn(enemy) }.
function Entities.updateAll(dt, playerX, playerY, level, now, callbacks)
	local px, py, psize = playerX, playerY, Config.PLAYER_SIZE

	for i = #coins, 1, -1 do
		local coin = coins[i]
		if coin.kind == "star" or coin.kind == "powerup" then
			local lifetime = coin.kind == "star" and Config.STAR_LIFETIME or Config.POWERUP_LIFETIME
			local age = now - coin.bornAt
			if age >= lifetime then
				coin.frame:Destroy()
				table.remove(coins, i)
			else
				-- Blink in its last two seconds so the player sees it fading.
				coin.frame.BackgroundTransparency = age > lifetime - 2 and (math.floor(now * 6) % 2 == 0 and 0.6 or 0) or 0
				if overlaps(px, py, psize, coin.x + 4, coin.y + 4, coin.size - 8) then
					local cx = coin.x + coin.size / 2
					local cy = coin.y + coin.size / 2
					coin.frame:Destroy()
					table.remove(coins, i)
					if coin.kind == "star" then
						callbacks.onStar(cx, cy)
					else
						callbacks.onPowerup(cx, cy)
					end
				end
			end
		elseif overlaps(px, py, psize, coin.x + 4, coin.y + 4, coin.size - 8) then
			local cx = coin.x + coin.size / 2
			local cy = coin.y + coin.size / 2
			coin.frame:Destroy()
			table.remove(coins, i)
			callbacks.onCoin(cx, cy)
		end
	end

	for i = #enemies, 1, -1 do
		local enemy = enemies[i]
		if enemy.kind == "chaser" then
			-- Steer toward the player.
			local dx = (px + psize / 2) - (enemy.x + Config.ENEMY_SIZE / 2)
			local dy = (py + psize / 2) - (enemy.y + Config.ENEMY_SIZE / 2)
			local len = math.sqrt(dx * dx + dy * dy)
			if len > 1 then
				enemy.vx = (dx / len) * enemy.speed
				enemy.vy = (dy / len) * enemy.speed
			end
			enemy.x += enemy.vx * dt
			enemy.y += enemy.vy * dt
		elseif enemy.kind == "weaver" then
			-- Sweep across in a sine wave.
			enemy.x += enemy.dir * enemy.speed * dt
			enemy.phase += dt * 3
			enemy.y = enemy.baseY + math.sin(enemy.phase) * 60
			enemy.y = math.clamp(enemy.y, 52, Config.ARENA_HEIGHT - Config.WEAVER_SIZE)
		else
			enemy.x += enemy.vx * dt
			enemy.y += enemy.vy * dt
		end
		enemy.frame.Position = UDim2.fromOffset(math.floor(enemy.x + 0.5), math.floor(enemy.y + 0.5))

		-- A drifter that leaves the arena comes back in from a random edge.
		if enemy.kind == "drifter" then
			local m = Config.ENEMY_SIZE + 8
			if enemy.x < -m or enemy.x > Config.ARENA_WIDTH + m or enemy.y < 44 - m or enemy.y > Config.ARENA_HEIGHT + m then
				local nx, ny, nvx, nvy = edgeSpawn(enemy.speed)
				enemy.x, enemy.y, enemy.vx, enemy.vy = nx, ny, nvx, nvy
			end
		end

		-- A weaver that crosses the arena leaves for good (a fresh one spawns
		-- later from maintainSpawns if the level still wants one).
		local gone = false
		if enemy.kind == "weaver" then
			if enemy.x < -Config.WEAVER_SIZE - 8 or enemy.x > Config.ARENA_WIDTH + 8 then
				enemy.frame:Destroy()
				table.remove(enemies, i)
				gone = true
			end
		end

		if not gone and overlaps(px, py, psize, enemy.x + 3, enemy.y + 3, (enemy.kind == "weaver" and Config.WEAVER_SIZE or Config.ENEMY_SIZE) - 6) then
			enemy.frame:Destroy()
			table.remove(enemies, i)
			callbacks.onHit(enemy)
		end
	end
end

return Entities

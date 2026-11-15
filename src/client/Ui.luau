-- Coin Rush v3: builds every interface element and paints the round state on screen.
-- The title and HUD sit clear of the screen's top-left corner, where Roblox puts
-- its own menu buttons. All text is large enough to read on a scaled-down screenshot.
-- v3: the HUD carries the vault next to the level, the arena re-themes per vault,
-- and there is a dash button, a shield chip, a shield ring, particle bursts, a
-- combo badge, a vault-objective line, floating score popups, and the Warden
-- boss bar.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)

local Ui = {}
local C = Config.COLORS

local ARENA_BASE_POS = UDim2.new(0.5, 0, 0.5, 32)

local gui
local arena
local hud
local accentStrip
local playerFrame
local shieldRing
local scoreLabel
local coinsLabel
local timeLabel
local levelLabel
local lifePips = {}
local menuOverlay
local winOverlay
local loseOverlay
local winStats
local loseStats
local bannerLabel
local bannerToken = 0
local flashFrame
local dashButton
local shieldChip
local comboLabel
local objectiveLabel
local bossBar
local bossTitle
local bossPips = {}
local shaking = false

local function newText(parent, name, text, size, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.Font = font or Enum.Font.GothamBold
	label.Parent = parent
	return label
end

local function newOverlay(name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = C.overlay
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = arena
	return frame
end

function Ui.build()
	local player = Players.LocalPlayer

	gui = Instance.new("ScreenGui")
	gui.Name = "CoinRushGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = C.background
	background.BorderSizePixel = 0
	background.Parent = gui

	local title = newText(background, "Title", "COIN RUSH", 38, C.player)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 10)
	title.Size = UDim2.fromOffset(640, 48)
	title.Parent = background

	local subtitle = newText(
		background,
		"Subtitle",
		"Charge all 4 vaults, then beat THE WARDEN. Combo pickups for x5 score.",
		18,
		C.muted,
		Enum.Font.Gotham
	)
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.new(0.5, 0, 0, 58)
	subtitle.Size = UDim2.fromOffset(640, 26)
	subtitle.Parent = background

	arena = Instance.new("Frame")
	arena.Name = "Arena"
	arena.AnchorPoint = Vector2.new(0.5, 0.5)
	arena.Position = ARENA_BASE_POS
	arena.Size = UDim2.fromOffset(Config.ARENA_WIDTH, Config.ARENA_HEIGHT)
	arena.BackgroundColor3 = C.arena
	arena.BorderColor3 = C.arenaBorder
	arena.BorderSizePixel = 2
	arena.ClipsDescendants = true
	arena.Parent = background

	-- HUD bar across the top of the arena.
	hud = Instance.new("Frame")
	hud.Name = "Hud"
	hud.Size = UDim2.new(1, 0, 0, 44)
	hud.BackgroundColor3 = Color3.fromRGB(22, 30, 52)
	hud.BorderSizePixel = 0
	hud.Parent = arena

	-- HUD labels use fixed, non-overlapping slots across the 640 px arena.
	-- (20 pt text overflowed its label, so COINS ran into TIME in v1.)
	-- v2: score 10-150, coins 155-280, time 285-390, level+zone 395-525,
	-- life pips 556-626. Every label's widest text fits its slot at 18 pt.
	scoreLabel = newText(hud, "Score", "SCORE 0", 18, C.text)
	scoreLabel.Position = UDim2.fromOffset(10, 0)
	scoreLabel.Size = UDim2.fromOffset(140, 44)
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	scoreLabel.Parent = hud

	coinsLabel = newText(hud, "Coins", "COINS 0/20", 18, C.coin)
	coinsLabel.Position = UDim2.fromOffset(155, 0)
	coinsLabel.Size = UDim2.fromOffset(125, 44)
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = hud

	timeLabel = newText(hud, "Time", "TIME 1:15", 18, C.text)
	timeLabel.Position = UDim2.fromOffset(285, 0)
	timeLabel.Size = UDim2.fromOffset(105, 44)
	timeLabel.TextXAlignment = Enum.TextXAlignment.Center
	timeLabel.Parent = hud

	levelLabel = newText(hud, "Level", "LV1 MEADOW", 18, C.star)
	levelLabel.Position = UDim2.fromOffset(395, 0)
	levelLabel.Size = UDim2.fromOffset(130, 44)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Right
	levelLabel.Parent = hud

	for i = 1, Config.LIVES do
		local pip = Instance.new("Frame")
		pip.Name = "Life" .. i
		pip.AnchorPoint = Vector2.new(1, 0.5)
		pip.Position = UDim2.new(1, -14 - (i - 1) * 26, 0.5, 0)
		pip.Size = UDim2.fromOffset(18, 18)
		pip.BackgroundColor3 = C.drifter
		pip.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = pip
		pip.Parent = hud
		lifePips[i] = pip
	end

	-- Thin accent strip under the HUD: the zone's colour, so the zone reads
	-- at a glance even in a still screenshot.
	accentStrip = Instance.new("Frame")
	accentStrip.Name = "ZoneStrip"
	accentStrip.Position = UDim2.fromOffset(0, 44)
	accentStrip.Size = UDim2.new(1, 0, 0, 4)
	accentStrip.BackgroundColor3 = Config.ZONES[1].accent
	accentStrip.BorderSizePixel = 0
	accentStrip.Parent = arena

	-- Combo badge: top-centre just under the HUD, only while the combo is x2
	-- or better. It is the most visible reward for chaining pickups.
	comboLabel = newText(arena, "ComboBadge", "", 26, C.player)
	comboLabel.AnchorPoint = Vector2.new(0.5, 0)
	comboLabel.Position = UDim2.new(0.5, 0, 0, 52)
	comboLabel.Size = UDim2.fromOffset(200, 32)
	comboLabel.Visible = false
	comboLabel.Parent = arena

	-- Warden boss bar: same spot as the combo badge (they never show at once).
	-- Three pips = the Warden's HP; dash through it to land a hit.
	bossBar = Instance.new("Frame")
	bossBar.Name = "BossBar"
	bossBar.AnchorPoint = Vector2.new(0.5, 0)
	bossBar.Position = UDim2.new(0.5, 0, 0, 52)
	bossBar.Size = UDim2.fromOffset(240, 32)
	bossBar.BackgroundColor3 = Color3.fromRGB(20, 12, 18)
	bossBar.BackgroundTransparency = 0.2
	bossBar.BorderSizePixel = 0
	bossBar.Visible = false
	bossBar.Parent = arena
	bossTitle = newText(bossBar, "BossTitle", "THE WARDEN", 16, C.boss)
	bossTitle.Position = UDim2.fromOffset(8, 0)
	bossTitle.Size = UDim2.fromOffset(130, 32)
	bossTitle.TextXAlignment = Enum.TextXAlignment.Left
	bossTitle.Parent = bossBar
	for i = 1, Config.BOSS_HP do
		local pip = Instance.new("Frame")
		pip.Name = "BossHp" .. i
		pip.AnchorPoint = Vector2.new(1, 0.5)
		pip.Position = UDim2.new(1, -10 - (i - 1) * 26, 0.5, 0)
		pip.Size = UDim2.fromOffset(18, 18)
		pip.BackgroundColor3 = C.boss
		pip.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = pip
		pip.Parent = bossBar
		bossPips[i] = pip
	end

	-- Shield ring: a green border around the player while the shield is up.
	shieldRing = Instance.new("Frame")
	shieldRing.Name = "ShieldRing"
	shieldRing.Size = UDim2.fromOffset(Config.PLAYER_SIZE + 12, Config.PLAYER_SIZE + 12)
	shieldRing.BackgroundTransparency = 1
	shieldRing.BorderColor3 = C.shield
	shieldRing.BorderSizePixel = 3
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(0.3, 0)
	ringCorner.Parent = shieldRing
	shieldRing.Visible = false
	shieldRing.Parent = arena

	-- The player: a gold rounded square.
	playerFrame = Instance.new("Frame")
	playerFrame.Name = "Player"
	playerFrame.Size = UDim2.fromOffset(Config.PLAYER_SIZE, Config.PLAYER_SIZE)
	playerFrame.BackgroundColor3 = C.player
	playerFrame.BorderColor3 = C.playerBorder
	playerFrame.BorderSizePixel = 2
	local playerCorner = Instance.new("UICorner")
	playerCorner.CornerRadius = UDim.new(0.25, 0)
	playerCorner.Parent = playerFrame
	playerFrame.Parent = arena

	-- Red flash on taking a hit.
	flashFrame = Instance.new("Frame")
	flashFrame.Name = "HitFlash"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = C.drifter
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = arena

	-- Level-up / zone banner, centre of the arena.
	bannerLabel = newText(arena, "LevelBanner", "", 40, C.player)
	bannerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	bannerLabel.Position = UDim2.fromScale(0.5, 0.4)
	bannerLabel.Size = UDim2.fromOffset(480, 60)
	bannerLabel.Visible = false
	bannerLabel.Parent = arena

	-- Dash button, bottom-right inside the arena. Its text is the cooldown
	-- indicator: "DASH (SPACE)" when ready, a countdown while cooling down.
	dashButton = Instance.new("TextButton")
	dashButton.Name = "DashButton"
	dashButton.AnchorPoint = Vector2.new(1, 1)
	dashButton.Position = UDim2.new(1, -10, 1, -10)
	dashButton.Size = UDim2.fromOffset(110, 36)
	dashButton.BackgroundColor3 = C.button
	dashButton.TextColor3 = C.buttonText
	dashButton.Text = "DASH (SPACE)"
	dashButton.TextSize = 16
	dashButton.Font = Enum.Font.GothamBold
	local dashCorner = Instance.new("UICorner")
	dashCorner.CornerRadius = UDim.new(0.25, 0)
	dashCorner.Parent = dashButton
	dashButton.Parent = arena
	Ui.dashButton = dashButton

	-- Shield chip, bottom-left inside the arena. Hidden unless a shield is up.
	shieldChip = newText(arena, "ShieldChip", "", 14, C.shield)
	shieldChip.Position = UDim2.fromOffset(10, 442)
	shieldChip.Size = UDim2.fromOffset(150, 28)
	shieldChip.TextXAlignment = Enum.TextXAlignment.Left
	shieldChip.Visible = false
	shieldChip.Parent = arena

	-- Vault objective: bottom-centre, between the shield chip and the dash
	-- button. It always says what the player is working toward right now.
	objectiveLabel = newText(arena, "Objective", "", 14, C.muted)
	objectiveLabel.AnchorPoint = Vector2.new(0.5, 0)
	objectiveLabel.Position = UDim2.new(0.5, 0, 0, 444)
	objectiveLabel.Size = UDim2.fromOffset(300, 28)
	objectiveLabel.Parent = arena

	menuOverlay = newOverlay("MenuOverlay")
	local menuTitle = newText(menuOverlay, "MenuTitle", "COIN RUSH", 44, C.player)
	menuTitle.AnchorPoint = Vector2.new(0.5, 0)
	menuTitle.Position = UDim2.new(0.5, 0, 0, 84)
	menuTitle.Size = UDim2.fromOffset(480, 56)
	menuTitle.Parent = menuOverlay
	local menuBody = newText(
		menuOverlay,
		"MenuBody",
		"Arrow keys or WASD to move. SPACE to dash.\n4 vaults: Meadow, Desert, Neon, Core - charge each portal.\nChain pickups for a x5 COMBO. A hit resets it.\nDash through THE WARDEN 3 times to win. Shield blocks a hit.",
		20,
		C.text,
		Enum.Font.Gotham
	)
	menuBody.AnchorPoint = Vector2.new(0.5, 0)
	menuBody.Position = UDim2.new(0.5, 0, 0, 150)
	menuBody.Size = UDim2.fromOffset(480, 110)
	menuBody.Parent = menuOverlay
	local menuBest = newText(menuOverlay, "BestScore", "", 20, C.muted, Enum.Font.Gotham)
	menuBest.Name = "BestScore"
	menuBest.AnchorPoint = Vector2.new(0.5, 0)
	menuBest.Position = UDim2.new(0.5, 0, 0, 268)
	menuBest.Size = UDim2.fromOffset(480, 28)
	menuBest.Parent = menuOverlay
	local startButton = Instance.new("TextButton")
	startButton.Name = "StartButton"
	startButton.AnchorPoint = Vector2.new(0.5, 0)
	startButton.Position = UDim2.new(0.5, 0, 0, 310)
	startButton.Size = UDim2.fromOffset(220, 56)
	startButton.BackgroundColor3 = C.button
	startButton.TextColor3 = C.buttonText
	startButton.Text = "START  (ENTER)"
	startButton.TextSize = 24
	startButton.Font = Enum.Font.GothamBold
	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0.25, 0)
	startCorner.Parent = startButton
	startButton.Parent = menuOverlay
	Ui.startButton = startButton

	winOverlay = newOverlay("WinOverlay")
	local winTitle = newText(winOverlay, "WinTitle", "YOU WIN!", 44, C.player)
	winTitle.AnchorPoint = Vector2.new(0.5, 0)
	winTitle.Position = UDim2.new(0.5, 0, 0, 84)
	winTitle.Size = UDim2.fromOffset(480, 56)
	winTitle.Parent = winOverlay
	winStats = newText(winOverlay, "WinStats", "", 22, C.text, Enum.Font.Gotham)
	winStats.AnchorPoint = Vector2.new(0.5, 0)
	winStats.Position = UDim2.new(0.5, 0, 0, 160)
	winStats.Size = UDim2.fromOffset(480, 150)
	winStats.Parent = winOverlay
	local winAgain = Instance.new("TextButton")
	winAgain.Name = "PlayAgainButton"
	winAgain.AnchorPoint = Vector2.new(0.5, 0)
	winAgain.Position = UDim2.new(0.5, 0, 0, 310)
	winAgain.Size = UDim2.fromOffset(220, 56)
	winAgain.BackgroundColor3 = C.button
	winAgain.TextColor3 = C.buttonText
	winAgain.Text = "PLAY AGAIN  (R)"
	winAgain.TextSize = 24
	winAgain.Font = Enum.Font.GothamBold
	local winCorner = Instance.new("UICorner")
	winCorner.CornerRadius = UDim.new(0.25, 0)
	winCorner.Parent = winAgain
	winAgain.Parent = winOverlay
	Ui.winAgainButton = winAgain

	loseOverlay = newOverlay("LoseOverlay")
	local loseTitle = newText(loseOverlay, "LoseTitle", "GAME OVER", 44, C.drifter)
	loseTitle.AnchorPoint = Vector2.new(0.5, 0)
	loseTitle.Position = UDim2.new(0.5, 0, 0, 84)
	loseTitle.Size = UDim2.fromOffset(480, 56)
	loseTitle.Parent = loseOverlay
	loseStats = newText(loseOverlay, "LoseStats", "", 22, C.text, Enum.Font.Gotham)
	loseStats.AnchorPoint = Vector2.new(0.5, 0)
	loseStats.Position = UDim2.new(0.5, 0, 0, 160)
	loseStats.Size = UDim2.fromOffset(480, 120)
	loseStats.Parent = loseOverlay
	local loseAgain = Instance.new("TextButton")
	loseAgain.Name = "PlayAgainButton"
	loseAgain.AnchorPoint = Vector2.new(0.5, 0)
	loseAgain.Position = UDim2.new(0.5, 0, 0, 310)
	loseAgain.Size = UDim2.fromOffset(220, 56)
	loseAgain.BackgroundColor3 = C.button
	loseAgain.TextColor3 = C.buttonText
	loseAgain.Text = "TRY AGAIN  (R)"
	loseAgain.TextSize = 24
	loseAgain.Font = Enum.Font.GothamBold
	local loseCorner = Instance.new("UICorner")
	loseCorner.CornerRadius = UDim.new(0.25, 0)
	loseCorner.Parent = loseAgain
	loseAgain.Parent = loseOverlay
	Ui.loseAgainButton = loseAgain

	gui.Parent = player:WaitForChild("PlayerGui")
end

function Ui.getArena()
	return arena
end

function Ui.placePlayer(x, y)
	playerFrame.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
	if shieldRing.Visible then
		shieldRing.Position = UDim2.fromOffset(math.floor(x - 6 + 0.5), math.floor(y - 6 + 0.5))
	end
end

function Ui.setPlayerVisible(visible)
	playerFrame.Visible = visible
end

function Ui.setShieldRingVisible(visible)
	shieldRing.Visible = visible
end

-- Re-themes the arena for a zone: background, HUD bar and accent strip.
function Ui.setArenaTheme(zone)
	local z = Config.ZONES[zone] or Config.ZONES[1]
	arena.BackgroundColor3 = z.arena
	hud.BackgroundColor3 = z.hud
	accentStrip.BackgroundColor3 = z.accent
end

function Ui.updateHud(state)
	scoreLabel.Text = "SCORE " .. state.score
	coinsLabel.Text = "COINS " .. state.coins .. "/" .. Config.COINS_TO_WIN
	local seconds = math.max(0, math.ceil(state.timeLeft))
	timeLabel.Text = string.format("TIME %d:%02d", math.floor(seconds / 60), seconds % 60)
	local zoneName = (Config.ZONES[state.zone] or Config.ZONES[1]).name
	levelLabel.Text = "LV" .. state.level .. " " .. zoneName
	for i = 1, Config.LIVES do
		lifePips[i].BackgroundTransparency = i <= state.lives and 0 or 0.75
	end
	-- Combo badge: only x2 or better, so the first pickup stays quiet.
	if state.combo >= 2 and not state.bossActive then
		comboLabel.Visible = true
		comboLabel.Text = "COMBO x" .. state.combo
	else
		comboLabel.Visible = false
	end
	-- Objective: what the vault still needs, or the boss countdown.
	if state.bossActive then
		objectiveLabel.Text = string.format("BEAT THE WARDEN - %ds", math.max(0, math.ceil(state.bossTimeLeft)))
	else
		local start = Config.vaultStart(state.zone)
		local quota = Config.VAULT_QUOTAS[state.zone] or 1
		local into = state.coins - start
		objectiveLabel.Text = string.format("VAULT %d - %d/%d TO PORTAL", state.zone, into, quota)
	end
end

-- Warden boss bar: visible only while the boss is up; pips show HP left.
function Ui.setBossBar(hp)
	if hp > 0 then
		bossBar.Visible = true
		comboLabel.Visible = false
		for i = 1, Config.BOSS_HP do
			bossPips[i].BackgroundTransparency = i <= hp and 0 or 0.75
		end
	else
		bossBar.Visible = false
	end
end

-- Dash button doubles as the cooldown indicator.
function Ui.setDashCooldown(secondsLeft)
	if secondsLeft <= 0 then
		dashButton.Text = "DASH (SPACE)"
		dashButton.BackgroundColor3 = C.button
		dashButton.TextColor3 = C.buttonText
	else
		dashButton.Text = string.format("DASH %.1fs", secondsLeft)
		dashButton.BackgroundColor3 = Color3.fromRGB(90, 100, 130)
		dashButton.TextColor3 = C.muted
	end
end

-- Shield chip: hidden when no shield is up, else shows seconds left.
function Ui.setShieldChip(secondsLeft)
	if secondsLeft <= 0 then
		shieldChip.Visible = false
		shieldChip.Text = ""
	else
		shieldChip.Visible = true
		shieldChip.Text = string.format("SHIELD %ds", math.ceil(secondsLeft))
	end
end

function Ui.showMenu(best)
	menuOverlay.Visible = true
	winOverlay.Visible = false
	loseOverlay.Visible = false
	playerFrame.Visible = false
	shieldRing.Visible = false
	local bestLabel = menuOverlay:FindFirstChild("BestScore")
	if bestLabel then
		bestLabel.Text = best > 0 and ("BEST SCORE: " .. best) or ""
	end
end

function Ui.showPlaying()
	menuOverlay.Visible = false
	winOverlay.Visible = false
	loseOverlay.Visible = false
	playerFrame.Visible = true
end

function Ui.showWin(state)
	winOverlay.Visible = true
	loseOverlay.Visible = false
	playerFrame.Visible = false
	shieldRing.Visible = false
	bossBar.Visible = false
	comboLabel.Visible = false
	local elapsed = math.max(0, math.floor(Config.ROUND_SECONDS - state.timeLeft))
	local bossLine = state.bossDefeated and "WARDEN BEATEN!" or "WARDEN DRIVEN OFF"
	winStats.Text = string.format(
		"Score: %d   Coins: %d/%d   Level: %d\n%s\nBest score: %d\nPlay Time: %d:%02d",
		state.score,
		state.coins,
		Config.COINS_TO_WIN,
		state.level,
		bossLine,
		state.best,
		math.floor(elapsed / 60),
		elapsed % 60
	)
end

function Ui.showLose(state)
	loseOverlay.Visible = true
	winOverlay.Visible = false
	playerFrame.Visible = false
	shieldRing.Visible = false
	bossBar.Visible = false
	comboLabel.Visible = false
	local elapsed = math.max(0, math.floor(Config.ROUND_SECONDS - state.timeLeft))
	loseStats.Text = string.format(
		"Score: %d   Coins: %d/%d   Level: %d\nBest score: %d\nPlay Time: %d:%02d",
		state.score,
		state.coins,
		Config.COINS_TO_WIN,
		state.level,
		state.best,
		math.floor(elapsed / 60),
		elapsed % 60
	)
end

function Ui.flashHit()
	flashFrame.BackgroundTransparency = 0.45
	local tween = TweenService:Create(
		flashFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
end

-- Tiny arena shake on a hit. Always restores the base position; a 3 px
-- offset is harmless even if the restore were ever skipped.
function Ui.shakeArena()
	if shaking then
		return
	end
	shaking = true
	pcall(function()
		arena.Position = UDim2.new(0.5, 3, 0.5, 35)
	end)
	task.delay(0.12, function()
		pcall(function()
			arena.Position = ARENA_BASE_POS
		end)
		shaking = false
	end)
end

-- Gold burst at a pickup: six sparks fly out and fade. Fire-and-forget;
-- every spark destroys itself, so a burst can never leak instances.
function Ui.spawnBurst(x, y, color)
	for i = 1, 6 do
		local angle = (i - 1) * (math.pi * 2 / 6) + math.random() * 0.5
		local dist = 22 + math.random(0, 10)
		local spark = Instance.new("Frame")
		spark.Name = "Burst"
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
		spark.Size = UDim2.fromOffset(8, 8)
		spark.BackgroundColor3 = color
		spark.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = spark
		spark.Parent = arena
		local tween = TweenService:Create(
			spark,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromOffset(
					math.floor(x + math.cos(angle) * dist + 0.5),
					math.floor(y + math.sin(angle) * dist + 0.5)
				),
				BackgroundTransparency = 1,
			}
		)
		tween:Play()
		task.delay(0.4, function()
			spark:Destroy()
		end)
	end
end

-- Floating score text at a pickup: "+200 x2" rises and fades. Fire-and-
-- forget; the label destroys itself, so popups can never leak instances.
function Ui.spawnPopup(x, y, text, color)
	local label = Instance.new("TextLabel")
	label.Name = "ScorePopup"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
	label.Size = UDim2.fromOffset(160, 30)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = 22
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.Parent = arena
	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y - 40 + 0.5)),
			TextTransparency = 1,
		}
	)
	tween:Play()
	task.delay(0.85, function()
		label:Destroy()
	end)
end

-- Fading gold ghost left behind while dashing.
function Ui.spawnDashGhost(x, y)
	local ghost = Instance.new("Frame")
	ghost.Name = "DashGhost"
	ghost.Size = UDim2.fromOffset(Config.PLAYER_SIZE, Config.PLAYER_SIZE)
	ghost.BackgroundColor3 = C.player
	ghost.BackgroundTransparency = 0.5
	ghost.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = ghost
	ghost.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
	ghost.Parent = arena
	local tween = TweenService:Create(
		ghost,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
	task.delay(0.35, function()
		ghost:Destroy()
	end)
end

-- One banner label for level-ups and zone changes. A token keeps a newer
-- banner from being hidden early by an older banner's fade.
local function showBanner(text, color)
	bannerToken += 1
	local token = bannerToken
	bannerLabel.Text = text
	bannerLabel.TextColor3 = color
	bannerLabel.Visible = true
	bannerLabel.TextTransparency = 0
	task.delay(1.1, function()
		if token ~= bannerToken then
			return
		end
		local tween = TweenService:Create(
			bannerLabel,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Wait()
		if token == bannerToken then
			bannerLabel.Visible = false
		end
	end)
end

function Ui.showLevelBanner(level)
	showBanner("LEVEL " .. level .. "!", C.player)
end

function Ui.showZoneBanner(zone)
	local z = Config.ZONES[zone] or Config.ZONES[1]
	showBanner("VAULT " .. zone .. " - " .. z.name .. "!", z.accent)
end

function Ui.showBossBanner()
	showBanner("THE WARDEN!", C.boss)
end

return Ui

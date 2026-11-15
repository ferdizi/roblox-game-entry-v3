-- Coin Rush: the server keeps this server's best score.
-- The client reports its final score at the end of a round; the server
-- remembers the best and sends it back. Nothing here touches the game itself:
-- the whole round runs on the client, the server only holds one number.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = Instance.new("RemoteEvent")
events.Name = "CoinRushEvents"
events.Parent = ReplicatedStorage

local bestScore = 0

events.OnServerEvent:Connect(function(player, kind, value)
	if kind == "SubmitScore" and typeof(value) == "number" then
		if value > bestScore then
			bestScore = value
		end
		events:FireClient(player, "BestScore", bestScore)
	elseif kind == "AskBest" then
		events:FireClient(player, "BestScore", bestScore)
	end
end)

print("Coin Rush server ready.")

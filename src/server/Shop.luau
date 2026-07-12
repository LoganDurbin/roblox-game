--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Catalog = require(Shared:WaitForChild("UnitCatalog"))
local PlayerData = require(script.Parent.PlayerData)

local Shop = {}

local function tryBuy(player: Player, unitId: any)
	-- 1. Validate the input itself. The client can send anything.
	if type(unitId) ~= "string" then
		return
	end
	local unit = Catalog[unitId]
	if not unit then
		Remotes.Notify:FireClient(player, "That item doesn't exist.")
		return
	end

	-- 2. Read authoritative state.
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	-- 3. Validate affordability.
	if data.Cash < unit.price then
		Remotes.Notify:FireClient(player, `Not enough Cash for {unit.name}.`)
		return
	end

	-- 4. Apply atomically — no yields between the check above and here,
	--    or two rapid buys could both pass step 3 and overspend.
	PlayerData.Mutate(player, function(d)
		d.Cash -= unit.price
		d.Units[unitId] = (d.Units[unitId] or 0) + 1
	end)

	Remotes.Notify:FireClient(player, `Bought {unit.name}!`)
end

function Shop.Init()
	Remotes.BuyUnit.OnServerEvent:Connect(tryBuy)
end

return Shop
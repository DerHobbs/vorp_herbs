VorpInv = exports.vorp_inventory:vorp_inventoryApi()

local VorpCore = {}

TriggerEvent("getCore",function(core)
    VorpCore = core
end)

RegisterServerEvent('vorp_picking:addItem')
AddEventHandler('vorp_picking:addItem', function()
	local FinalLoot = LootToGive(source)
	local User = VorpCore.getUser(source).getUsedCharacter
	for k,v in pairs(Config.Items) do
		if v.item == FinalLoot then
			VorpInv.addItem(source, FinalLoot, Config.randomgive)
			if Config.randomgive > 1 then
				LootsToGive = {}
				VorpCore.NotifyLeft(source, Config.Language.notifytitel, "You have " ..v.name.. " found", "INVENTORY_ITEMS", "consumable_herb_black_berry", 3000, "COLOR_PURPLE")
			else
				LootsToGive = {}
				VorpCore.NotifyLeft(source, Config.Language.notifytitel, "You have a " ..v.name.. " found", "INVENTORY_ITEMS", "consumable_herb_black_berry", 3000, "COLOR_PURPLE")
			end
		end
	end
end)

function LootToGive(source)
	local LootsToGive = {}
	for k,v in pairs(Config.Items) do
		table.insert(LootsToGive,v.item)
	end

	if LootsToGive[1] ~= nil then
		local value = math.random(1,#LootsToGive)
		local picked = LootsToGive[value]
		return picked
	end
end
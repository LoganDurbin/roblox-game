--!strict
export type Unit = {
	id: string,
	name: string,
	price: number,
	income: number, -- cash/sec it'll generate later
	rarity: string,
}

local Catalog: { [string]: Unit } = {
	starter = { id = "starter", name = "Starter Bot", price = 50, income = 1, rarity = "Common" },
	cooler = { id = "cooler", name = "Cooler Bot", price = 250, income = 6, rarity = "Rare" },
	elite = { id = "elite", name = "Elite Bot", price = 1000, income = 30, rarity = "Epic" },
}

return Catalog
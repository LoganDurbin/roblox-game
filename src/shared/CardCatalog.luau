--!strict
-- Card definitions for the index. Each page is a 3x3 grid: 9 cards, spread
-- 4 Common / 2 Rare / 2 Epic / 1 Legendary. Roster is a placeholder starter
-- set; names are easy to swap.
-- NOTE: names drawn from living traditions (Hindu, Yoruba, Aboriginal, etc.)
-- should get a cultural-sensitivity pass before launch.

export type Card = {
	id: string,
	name: string,
	page: string, -- PageCatalog id
	rarity: string, -- "Common" | "Rare" | "Epic" | "Legendary"
	baseIncome: number, -- Coins/sec at 1 copy
}

-- Base income per rarity, applied uniformly for now (tune later).
local INCOME = { Common = 1, Rare = 3, Epic = 8, Legendary = 20 }

-- { id, name, page, rarity }
local defs: { { string } } = {
	-- Greek
	{ "hermes", "Hermes", "greek", "Common" },
	{ "apollo", "Apollo", "greek", "Common" },
	{ "dionysus", "Dionysus", "greek", "Common" },
	{ "demeter", "Demeter", "greek", "Common" },
	{ "athena", "Athena", "greek", "Rare" },
	{ "ares", "Ares", "greek", "Rare" },
	{ "poseidon", "Poseidon", "greek", "Epic" },
	{ "hades", "Hades", "greek", "Epic" },
	{ "zeus", "Zeus", "greek", "Legendary" },
	-- Norse
	{ "heimdall", "Heimdall", "norse", "Common" },
	{ "baldur", "Baldur", "norse", "Common" },
	{ "tyr", "Tyr", "norse", "Common" },
	{ "idun", "Idun", "norse", "Common" },
	{ "freya", "Freya", "norse", "Rare" },
	{ "loki", "Loki", "norse", "Rare" },
	{ "thor", "Thor", "norse", "Epic" },
	{ "frigg", "Frigg", "norse", "Epic" },
	{ "odin", "Odin", "norse", "Legendary" },
	-- Egyptian
	{ "bastet", "Bastet", "egyptian", "Common" },
	{ "thoth", "Thoth", "egyptian", "Common" },
	{ "sobek", "Sobek", "egyptian", "Common" },
	{ "khonsu", "Khonsu", "egyptian", "Common" },
	{ "anubis", "Anubis", "egyptian", "Rare" },
	{ "set", "Set", "egyptian", "Rare" },
	{ "horus", "Horus", "egyptian", "Epic" },
	{ "isis", "Isis", "egyptian", "Epic" },
	{ "ra", "Ra", "egyptian", "Legendary" },
	-- Hindu
	{ "ganesha", "Ganesha", "hindu", "Common" },
	{ "hanuman", "Hanuman", "hindu", "Common" },
	{ "agni", "Agni", "hindu", "Common" },
	{ "kartikeya", "Kartikeya", "hindu", "Common" },
	{ "saraswati", "Saraswati", "hindu", "Rare" },
	{ "indra", "Indra", "hindu", "Rare" },
	{ "vishnu", "Vishnu", "hindu", "Epic" },
	{ "durga", "Durga", "hindu", "Epic" },
	{ "shiva", "Shiva", "hindu", "Legendary" },
	-- Celtic
	{ "brigid", "Brigid", "celtic", "Common" },
	{ "cernunnos", "Cernunnos", "celtic", "Common" },
	{ "epona", "Epona", "celtic", "Common" },
	{ "manannan", "Manannan", "celtic", "Common" },
	{ "lugh", "Lugh", "celtic", "Rare" },
	{ "danu", "Danu", "celtic", "Rare" },
	{ "morrigan", "The Morrigan", "celtic", "Epic" },
	{ "nuada", "Nuada", "celtic", "Epic" },
	{ "dagda", "The Dagda", "celtic", "Legendary" },
	-- Roman
	{ "mercury", "Mercury", "roman", "Common" },
	{ "venus", "Venus", "roman", "Common" },
	{ "diana", "Diana", "roman", "Common" },
	{ "vulcan", "Vulcan", "roman", "Common" },
	{ "mars", "Mars", "roman", "Rare" },
	{ "juno", "Juno", "roman", "Rare" },
	{ "neptune", "Neptune", "roman", "Epic" },
	{ "pluto", "Pluto", "roman", "Epic" },
	{ "jupiter", "Jupiter", "roman", "Legendary" },
	-- Japanese
	{ "inari", "Inari", "japanese", "Common" },
	{ "tsukuyomi", "Tsukuyomi", "japanese", "Common" },
	{ "ebisu", "Ebisu", "japanese", "Common" },
	{ "hachiman", "Hachiman", "japanese", "Common" },
	{ "susanoo", "Susanoo", "japanese", "Rare" },
	{ "fujin", "Fujin", "japanese", "Rare" },
	{ "raijin", "Raijin", "japanese", "Epic" },
	{ "izanagi", "Izanagi", "japanese", "Epic" },
	{ "amaterasu", "Amaterasu", "japanese", "Legendary" },
	-- Chinese
	{ "nezha", "Nezha", "chinese", "Common" },
	{ "change", "Chang'e", "chinese", "Common" },
	{ "zao-jun", "Zao Jun", "chinese", "Common" },
	{ "yue-lao", "Yue Lao", "chinese", "Common" },
	{ "sun-wukong", "Sun Wukong", "chinese", "Rare" },
	{ "erlang-shen", "Erlang Shen", "chinese", "Rare" },
	{ "guanyin", "Guanyin", "chinese", "Epic" },
	{ "xiwangmu", "Xiwangmu", "chinese", "Epic" },
	{ "jade-emperor", "Jade Emperor", "chinese", "Legendary" },
	-- Aztec
	{ "xochiquetzal", "Xochiquetzal", "aztec", "Common" },
	{ "tlaloc", "Tlaloc", "aztec", "Common" },
	{ "patecatl", "Patecatl", "aztec", "Common" },
	{ "centeotl", "Centeotl", "aztec", "Common" },
	{ "tezcatlipoca", "Tezcatlipoca", "aztec", "Rare" },
	{ "mictlantecuhtli", "Mictlantecuhtli", "aztec", "Rare" },
	{ "huitzilopochtli", "Huitzilopochtli", "aztec", "Epic" },
	{ "coatlicue", "Coatlicue", "aztec", "Epic" },
	{ "quetzalcoatl", "Quetzalcoatl", "aztec", "Legendary" },
	-- Mayan
	{ "ix-chel", "Ix Chel", "mayan", "Common" },
	{ "chaac", "Chaac", "mayan", "Common" },
	{ "yum-kaax", "Yum Kaax", "mayan", "Common" },
	{ "akan", "Akan", "mayan", "Common" },
	{ "camazotz", "Camazotz", "mayan", "Rare" },
	{ "ah-puch", "Ah Puch", "mayan", "Rare" },
	{ "kukulkan", "Kukulkan", "mayan", "Epic" },
	{ "hurakan", "Hurakan", "mayan", "Epic" },
	{ "itzamna", "Itzamna", "mayan", "Legendary" },
	-- Slavic
	{ "mokosh", "Mokosh", "slavic", "Common" },
	{ "svarog", "Svarog", "slavic", "Common" },
	{ "lada", "Lada", "slavic", "Common" },
	{ "stribog", "Stribog", "slavic", "Common" },
	{ "morana", "Morana", "slavic", "Rare" },
	{ "dazhbog", "Dazhbog", "slavic", "Rare" },
	{ "veles", "Veles", "slavic", "Epic" },
	{ "chernobog", "Chernobog", "slavic", "Epic" },
	{ "perun", "Perun", "slavic", "Legendary" },
	-- Yoruba
	{ "oshun", "Oshun", "yoruba", "Common" },
	{ "eshu", "Eshu", "yoruba", "Common" },
	{ "aja", "Aja", "yoruba", "Common" },
	{ "osoosi", "Osoosi", "yoruba", "Common" },
	{ "ogun", "Ogun", "yoruba", "Rare" },
	{ "oya", "Oya", "yoruba", "Rare" },
	{ "yemoja", "Yemoja", "yoruba", "Epic" },
	{ "obatala", "Obatala", "yoruba", "Epic" },
	{ "shango", "Shango", "yoruba", "Legendary" },
	-- Polynesian
	{ "hina", "Hina", "polynesian", "Common" },
	{ "tane", "Tane", "polynesian", "Common" },
	{ "rongo", "Rongo", "polynesian", "Common" },
	{ "haumea", "Haumea", "polynesian", "Common" },
	{ "ku", "Ku", "polynesian", "Rare" },
	{ "tangaroa", "Tangaroa", "polynesian", "Rare" },
	{ "pele", "Pele", "polynesian", "Epic" },
	{ "kanaloa", "Kanaloa", "polynesian", "Epic" },
	{ "maui", "Maui", "polynesian", "Legendary" },
	-- Persian
	{ "anahita", "Anahita", "persian", "Common" },
	{ "atar", "Atar", "persian", "Common" },
	{ "tishtrya", "Tishtrya", "persian", "Common" },
	{ "rashnu", "Rashnu", "persian", "Common" },
	{ "mithra", "Mithra", "persian", "Rare" },
	{ "sraosha", "Sraosha", "persian", "Rare" },
	{ "zurvan", "Zurvan", "persian", "Epic" },
	{ "verethragna", "Verethragna", "persian", "Epic" },
	{ "ahura-mazda", "Ahura Mazda", "persian", "Legendary" },
	-- Inuit
	{ "nanook", "Nanook", "inuit", "Common" },
	{ "pinga", "Pinga", "inuit", "Common" },
	{ "amaguq", "Amaguq", "inuit", "Common" },
	{ "igaluk", "Igaluk", "inuit", "Common" },
	{ "malina", "Malina", "inuit", "Rare" },
	{ "akna", "Akna", "inuit", "Rare" },
	{ "torngarsuk", "Torngarsuk", "inuit", "Epic" },
	{ "tekkeitsertok", "Tekkeitsertok", "inuit", "Epic" },
	{ "sedna", "Sedna", "inuit", "Legendary" },
	-- Australian Aboriginal
	{ "tiddalik", "Tiddalik", "aboriginal", "Common" },
	{ "yara-ma-yha-who", "Yara-ma-yha-who", "aboriginal", "Common" },
	{ "dirawong", "Dirawong", "aboriginal", "Common" },
	{ "karora", "Karora", "aboriginal", "Common" },
	{ "bunjil", "Bunjil", "aboriginal", "Rare" },
	{ "bila", "Bila", "aboriginal", "Rare" },
	{ "baiame", "Baiame", "aboriginal", "Epic" },
	{ "altjira", "Altjira", "aboriginal", "Epic" },
	{ "rainbow-serpent", "Rainbow Serpent", "aboriginal", "Legendary" },
}

local Catalog: { [string]: Card } = {}
for _, d in defs do
	local id, name, page, rarity = d[1], d[2], d[3], d[4]
	Catalog[id] = {
		id = id,
		name = name,
		page = page,
		rarity = rarity,
		baseIncome = INCOME[rarity] :: number,
	}
end

return Catalog

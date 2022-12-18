Config = {}

Config.SearchKey = 0xD9D0E1C0 -- Key to press for prompt

Config.Items = {
    {item = "Wintergreen_Berry", name = "Wintergrüne Beere"},
	{item = "Red_Raspberry", name = "Rote Himbeere"},
	{item = "Black_Berry", name = "Brombeere"},
	{item = "currant", name = "Johannisbeere"},
	{item = "blueberry", name = "Blaubeere"},
	{item = "Black_Currant", name = "SW Johannisbeere"},
    {item = "consumable_herb_evergreen_huckleberry", name = "Immergrüne Beere"}
}

Config.randomgive = math.random(1,3)

Config.Language = {
	prompt = "Search",
	promptsub = "Bush",

	notifytitel = "Berries",

	notfound = "You didn't find any berries!"

}

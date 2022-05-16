local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.stack = [[function()
    return 1
end]]

addon.InitializeDatabase = function()
	addon.db = LibStub("AceDB-3.0"):New("BankOfficerDB", {
		global = {
			templates = {
				["*"] = {},
			},
			settings = {},
			guilds = {
				["*"] = {
					tabsPurchased = false,
					settings = {},
					tabs = {
						["*"] = {
							slots = {
								["*"] = {
									itemID = false,
									stack = addon.stack,
									template = false,
								},
							},
						},
					},
				},
			},
		},
	}, true)

	addon.db.global.guilds[addon.GetGuildKey()].tabsPurchased = GetNumGuildBankTabs()
end

addon.GetGuildKey = function()
	local guild = (GetGuildInfo("player"))
	local realm = GetRealmName()

	return format("%s - %s", guild, realm)
end

addon.GetGuild = function(guild)
	return addon.db.global.guilds[guild or addon.GetGuildKey()]
end

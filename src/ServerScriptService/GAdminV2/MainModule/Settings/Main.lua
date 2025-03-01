local Settings = {

	--[[
	
		Main settings of GAdmin v2.
		
	]]

	Prefix = ";", --== Default prefix of the command.

	Rank = 0, --== Default rank user is given when he joins the game for the first time.

	Sandbox = false, --== When enabled every person in studio will have owner rank.

	SandboxRank = 5, --== Rank that will be given to everyone in the studio if Sandbox is enabled.

	ExecutorEnabled = false, --== In-game server-side code executor. (WARNING: loadstring() must be enabled. To enable it, enable ServerScriptService.LoadStringEnabled checkmark.)

	EventCalls = 500, --== How much calls user can do per minute.

	CommandCalls = 10, --== How much commands user can do per minute. (Set 0 for infinite.)

	RankRefreshment = 120, --== Time in seconds before rank list is refreshed. (WARNING: Uses GetAsync() of datastore in order to refresh.)

	BanlistRefreshment = 240, --== Time in seconds before ban list is refreshed. (WARNING: Uses GetAsync() of datastore in order to refresh.)

	CodeLengthLimit = 500, --== How much code can be saved into datastore by default.

	ConstantRanks = false, --== When enabled, ranks will be restricted from getting added in-game. 

	Defaults = {

		--== Default values for player's data.

		KickMessage = "No Reason.", --== Kick reason if user didn't provide any.

		BanMessage = "No Reason." --== Ban reason if user didn't provde any.

	},

	Groups = require(script.Parent.Groups)

}
























--[[

	Set GAdmin Sandbox to true if its official GAdmin game.
	Setting '__GAdmin_TestingPlace_Sandbox_Everywhere' is very dangerous setting. Because of the reasons:
	
	1. Sandbox will be applied everywhere. (i.e. not only in studio, but in official servers too.)
	
	2. Removes all of the restrictions from Sandbox setting. (Datastore saves changes.)

]]

if game.GameId == 6801481416 and workspace:GetAttribute("GA_TestingPlace_SandboxRank") then
	Settings.__GAdmin_TestingPlace_Sandbox_Everywhere = true
	Settings.Sandbox = true
	Settings.SandboxRank = 5
end

return Settings
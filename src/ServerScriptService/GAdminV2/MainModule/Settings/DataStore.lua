return {

	--[[
	
		DataStore settings of GAdmin v2.
		
	]]
	
	Output = true, -- Any errors will be outputed.
	
	RetryOn = 3, -- Number of seconds after which retry on fail attempt will be made.

	Stores = {
		--[[
			
			Names of datastores.
			
			[!WARNING!]:
			
				If you change name of the datastore, all of the data from the datastore will be lost.
			
		]]
		
		System = "GAdminV2_System",
		Player = "GAdminV2_Player",
		Code = "GAdminV2_Code"
	},
	
	Attempts = { -- Retry attempts on datastore fail.
		System = 5,
		Player = 3,
		Code = 5,
	}

}
return {
	
	--[[
	
		Automaticly gives rank in the game by group and group rank.
		
	]]

	{
		GroupId = 0, -- Id of the group.
		Roles = {
			--== Group roles.

			{GroupRank = 0, AdminRank = 0},

			--== GroupRank is a role rank in the group (i.e. 255 - group owner),
			--== If user has the same rank in the group as specified GroupRank, it will give user AdminRank in the game.
		}
	},
	
	
}
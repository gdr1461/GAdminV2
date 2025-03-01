local Command = {}

Command.Name = "ATest"
Command.Alias = {"AT"}
Command.Description = "Command that was loaded from addon 2."

Command.Rank = 3
Command.Fluid = true

Command.Arguments = {
	
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	print(Arguments)
end

function Command.Server:Get(Services)
	return {
		Remote = Services.Remote
	}
end

--== << Client >>
function Command.Client:Run(Caller, Arguments)
	_G.GAdmin.Framework.Interface:Refresh({
		Place = "_CodeEditor",
		Page = 1,
		MaxPages = 2,
		Arguments = {
			Id = "Button-1",
			Example = "[CODE HERE]",
			Docs = `Hello! This is how to code! <code size=".5">workspace.Parent:Clone().Parent = game.ReplicatedStorage</code> And now you know how to script!`,
		},
	})
end

return Command
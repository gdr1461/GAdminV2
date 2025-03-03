---
sidebar_position: 8
---

# Command Arguments
Almost every command requires arguments to function. If you are creating your own command, chances are you will need some type of argument for it.

Arguments in GAdmin are highly customizable and easy to work with.

## Structure
To ensure your argument is well-structured, follow this template:
```lua
{
		Name: string,
		Types = {string},
		Rank: number | string,

		Flags = {[key]: value},
		Specifics = {[key]: value},
	},
```

Now, let's go over the explanation of this structure.

### Name
Type: `string` <br/>
The name of the argument displayed on the Command page. Skip this to use the first argument type as the default.

### Types
Type: `StringArray` <br/>
Types used to convert the argument. For example, if your argument is a number type, it will convert the argument `'3'` to `3`.

:::info
Learn more about types [here](/docs/Arguments#existing-types).
:::

### Rank
Type: `number | string` <br/>
The rank required to use this argument.

### Flags
Type: `Dictionary` <br/>
Argument flags.

### Specifics
Type: `Dictionary` <br/>
Specifics of the argument.

:::info
Learn more about specifics [here](/docs/Arguments#existing-specifics)
:::

## Existing Types
An argument can be multiple types at once. It can be `number` and `Object`, `string` and `Player`, etc.
:::danger
Some of the arguments are not compatible with each other.
:::

### Player
Converts to: `Player | UserId` <br/>

Compatible flags:
	- **PlayerOther** <br/>
	A Player instance will always be another player, not the command caller.

	- **PlayerClient** <br/>
	If the command has a client side, it will execute on the specified player's client.

	- **PlayerOnline** <br/>
	The Player will always be a `Player` instance.

	- **PlayerOffline** <br/>
	The Player will always be a `UserId` number.

	- **Optional** <br/>
	The Player could also be `nil`.

### Rank
Converts to: `RankData` <br/>

Compatible flags:
	- **RankLower** <br/>
	The rank needs to be lower than the command caller's rank.

	- **RanHigher** <br/>
	The rank needs to be higher than the command caller's rank.

	- **RankEqual** <br/>
	The rank needs to be equal to the command caller's rank.

	- **Optional** <br/>
	The rank could also be `nil`.

### string
Converts to: `string` <br/>

Compatible flags:
	- **ToFilter** <br/>
	The string will be filtered.

	- **Infinite** <br/>
	The string will be able to contain space characters.

	- **Optional** <br/>
	The string could also be `nil`.

### number
Converts to: `number` <br/>

Compatible flags:
	- **Optional** <br/>
	The number could also be `nil`.

### boolean
Converts to: `boolean` <br/>

Compatible flags:
	- **Optional** <br/>
	The boolean could also be `nil`.

### Object
Converts to: `In-game Instance` <br/>

Compatible flags:
	- **Infinite** <br/>
	For a more precise search for objects that have space characters in their names.

	- **Optional** <br/>
	The object could also be `nil`.

Specifics:
	- **Multiple** `boolean` <br/>
	Returns an array of objects that share similar names.

	- **Services** `StringArray | (Player: Player, Argument: string, Data: ArgumentData) -> {Service}` <br/>
	The names of the services to search for objects in.

	- **Classes** `StringArray` <br/>
	What classes the objects need to be.

	- **Properties** `Dictionary` <br/>
	What properties need to be set in objects, and which ones need to be set? For example: `{Transparency = 1}`.

	- **Blacklist** `StringOrObjectArray` <br/>
	What objects need to be ignored?

	- **Whitelist** `StringOrObjectArray` <br/>
	Which objects should be considered and not ignored?

	- **Tags** [ObjectTagArray](/docs/Arguments#objecttag) <br/>
	Middleware for the objects list (sets auto-completion).

## Existing Specifics
All the specifics for tweaking your argument to meet your needs.

### AutoFill
Type: `{function | StringArray}` <br/>

Sets auto-fill for your argument.

```lua
AutoFill = {
	{"aaa", "bbb", "aabb"}, -- Will automatically pick one of these based on what the user types. (Example: a -> aaa, aabb; b -> bbb)
	function(Command, Argument, Word) -- Straight up sets auto-fill to the constant one. (Example: a -> aaa, bbb, aabb; b -> aaa, bbb, aabb)
		return {"aaa", "bbb", "aabb"}
	end,
}
```

### AutoFillOverride
Type: `boolean` <br/>

Override the existing autocompletion of the argument.Override the existing autocompletion of the argument.

Example:

Override off.
```lua
AutoFillOverride = false,
AutoFill = {
	{"aaa", "bbb", "aabb"},
	function(Command, Argument, Word)
		return {"aaa", "bbb", "aabb"}
	end,
}

--[[
	Input: a
	Output: aaa, aabb, aaa, bbb, aabb (From two autofills.)
]]
```

Override on.
```lua
AutoFillOverride = true,
AutoFill = {
	{"aaa", "bbb", "aabb"},
	function(Command, Argument, Word)
		return {"aaa", "bbb", "aabb"}
	end,
}

--[[
	Input: a
	Output: aaa, bbb, aabb (From last autofill in the table.)
]]
```

:::danger
If the last autofill did not return anything, autocompletion will be empty.
:::

## ObjectTag
`Tags` specific for `Object` type. With it, you can create your custom `Specifics` for your argument. <br/>

### Structure
Here’s the structure of the default object tag:

```lua
{
	Alias: StringArray,
	Call: (Objects: {Instance}, Specifics: {[key]: value}) -> {Instance}
}
```

Here’s an example of using an Object Tag:
```lua
{
	{
		Alias = {"omega", "super"},
		Call = function(Objects, Specifics)
			if Specifics.OmegaBanned then
				return {}
			end

			return Objects
		end
	},

	{
		Alias = {"cool"},
		Call = function(Objects, Specifics)
			return {workspace.Baseplate}
		end
	},
}
```
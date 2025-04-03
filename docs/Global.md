---
sidebar_position: 9
---

# _G
By default, GAdminV2 adds a custom key to [_G](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#_G) to make it easier for addons to access GAdmin without requiring additional imports.
You can access GAdmin by typing `_G.GAdmin` on either the server or client side.

:::note
`_G.GAdmin` has different properties depending on whether it is accessed from the server or client side.
:::

## Server
Global properties of GAdmin on the server side:
```lua
{
	API = ServerAPI,
	Modified = true,
	Module = MainModule,
	Path = MainModuleScript,
	Render: Render,
	Scheduler: Scheduler,
	__GetBanData: (RawBanData: table) -> BanData
}
```

### API
GAdmin's [Server API](/api/ServerAPI).

### Modified
A boolean indicating whether GAdmin has been modified by addons.

### Module
The required [module](/api/MainModule) from the path `GAdminV2.MainModule`.

### Path
A shortcut to the `MainModule` path for easier access to the Server folder (e.g., `GAdminV2.MainModule`).

### Render
GAdmin's [Renderer](/api/Render)

### Scheduler
GAdmin's [Scheduler](/api/Scheduler)

### __GetBanData
Used locally in the system to retrieve dictionary-based ban data from an array.

```lua
local BanData = _G.GAdmin.__GetBanData({
	00000, -- Moderator ID
	"No reason.", -- Reason
	"00000000", -- The time in Unix timestamp format, converted to a string.
	"00000000", -- The Unix timestamp of when a user was banned.
	nil, -- Indicates whether a user has been banned locally (deprecated property).
	true, -- ApplyToUniverse – used for the Roblox Ban API.
	nil, -- The type of ban (Global/Server) (deprecated property)..
	"No reason." -- ModHint.
})
```

## Client
### Path
A shortcut to the `GAdminShared` path for easier access to the main folder (e.g., `ReplicatedStorage.GAdminShared`).

### Render
GAdmin's [Renderer](/api/Render)

### __GetBanData
Used locally in the system to retrieve dictionary-based ban data from an array.

```lua
local BanData = _G.GAdmin.__GetBanData({
	00000, -- Moderator ID
	"No reason.", -- Reason
	"00000000", -- The time in Unix timestamp format, converted to a string.
	"00000000", -- The Unix timestamp of when a user was banned.
	nil, -- Indicates whether a user has been banned locally (deprecated property).
	true, -- ApplyToUniverse – used for the Roblox Ban API.
	nil, -- The type of ban (Global/Server) (deprecated property)..
	"No reason." -- ModHint.
})
```

### Framework
GAdmin's [Framework](/api/Framework)

### Scheduler
GAdmin's [Scheduler](/api/Scheduler)

### UseTheme
Boolean that tells the system whether the theme should be applied to the UI panel when the Theme setting is changed.

### Theme
[Theme Data](/api/UI#Theme)
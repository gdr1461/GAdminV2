---
sidebar_position: 2
---

# Installation
GAdminV2 doesn't require unpacking anything. Just insert **GAdminV2.rbxm** into `ServerScriptService`, and you're ready to go!

<br/>
# Guide
1. Download the latest version of GAdminV2 [from GitHub](https://github.com/gdr1461/GAdminV2/releases).
:::warning
It is recommended to download a release that doesn't have the `pre-release` tag.
:::
2. Place GAdminV2 inside `ServerScriptService`.

Now, go to `Game Settings` located in the top bar, navigate to the `Security` category, and enable the following parameters:
- **Enable Studio Access to API Services** <br/>
This is essential for GAdminV2's workflow. Without it, half of GAdmin's features will stop working.

- **Allow Third-Party Sales** <br/>
This is required for the correct functionality of the `About` page in the admin panel.

If you want to use the in-game server-side executor, follow the steps below:
1. Select `ServerScriptService` inside the Explorer.
2. Enable the `LoadStringEnabled` property inside it.
:::info
`LoadStringEnabled` is essential for the executor to work because it relies on that Roblox feature.
:::
:::warning
Enabling the `LoadStringEnabled` property comes with potential downsides. Malicious code can now execute strings as code directly into your game using `loadstring()`. Be cautious with this setting.
:::

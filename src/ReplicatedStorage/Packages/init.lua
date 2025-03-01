local ByteNet = require(script.ByteNet)

return ByteNet.defineNamespace("NazarRemotes", function()
	return {
		SetNazar = ByteNet.definePacket({
			value = ByteNet.bool
		})
	}
end)
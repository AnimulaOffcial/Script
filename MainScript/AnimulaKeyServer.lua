--!strict
-- Place this Script in ServerScriptService, not ReplicatedStorage or a client.
-- Set its KeyBrokerEndpoint attribute to:
--   https://your-domain.example/api/roblox/redeem
-- Create the `animula_broker_key` value in the Roblox Creator Hub Secret Store
-- and configure the identical value as ANIMULA_ROBLOX_SERVER_KEY on the host.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local REMOTE_NAME = "AnimulaKeyBroker"
local LAUNCH_REMOTE_NAME = "AnimulaGameLaunch"
local MODULE_ROOT_NAME = "AnimulaGameModules"
local SECRET_NAME = "animula_broker_key"
local REQUEST_COOLDOWN = 2

local configuredEndpoint = script:GetAttribute("KeyBrokerEndpoint")
if type(configuredEndpoint) ~= "string" or not string.match(configuredEndpoint, "^https://.+/api/roblox/redeem$") then
	error("[Animula] Set the ServerScript KeyBrokerEndpoint attribute to the HTTPS /api/roblox/redeem URL.")
end
local endpoint = configuredEndpoint :: string

local existing = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if existing and not existing:IsA("RemoteFunction") then
	error("[Animula] ReplicatedStorage.AnimulaKeyBroker must be a RemoteFunction.")
end
local broker: RemoteFunction
if existing then
	broker = existing :: RemoteFunction
else
	broker = Instance.new("RemoteFunction")
	broker.Name = REMOTE_NAME
	broker.Parent = ReplicatedStorage
end

local lastRequest: {[Player]: number} = {}
type AccessGrant = {
	keyType: string,
	expiresAt: number?,
}

local authorization: {[Player]: AccessGrant} = {}

local function unixExpiry(value: unknown): number?
	if type(value) ~= "string" or value == "" then
		return nil
	end
	local parsed, dateTime = pcall(function()
		return DateTime.fromIsoDate(value)
	end)
	if parsed and typeof(dateTime) == "DateTime" then
		return dateTime.UnixTimestamp
	end
	return nil
end

local function validKey(value: unknown): boolean
	if type(value) ~= "string" or #value ~= 36 then
		return false
	end
	local suffix = string.sub(value, -25)
	return string.match(value, "^Animula%-[pf]k%-[A-Za-z0-9]+$") ~= nil
		and string.match(suffix, "[A-Z]") ~= nil
		and string.match(suffix, "[a-z]") ~= nil
		and string.match(suffix, "[0-9]") ~= nil
end

local function redeem(player: Player, key: string): {[string]: any}
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return { ok = false, error = "Please wait before trying again." }
	end
	lastRequest[player] = now

	local secretOk, secret = pcall(function()
		return HttpService:GetSecret(SECRET_NAME)
	end)
	if not secretOk or not secret then
		warn("[Animula] Server Secret Store is not configured.")
		return { ok = false, error = "Secure key verification is not configured." }
	end

	local body = HttpService:JSONEncode({
		key = key,
		roblox_user_id = player.UserId,
		roblox_username = player.Name,
	})
	local requestOk, response = pcall(function()
		return HttpService:RequestAsync({
			Url = endpoint,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["X-Animula-Server-Key"] = secret :: any,
			},
			Body = body,
		})
	end)
	if not requestOk or type(response) ~= "table" or not response.Success then
		warn("[Animula] Key broker request failed.")
		return { ok = false, error = "Secure key verification is unavailable." }
	end

	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk or type(data) ~= "table" then
		return { ok = false, error_code = "invalid" }
	end
	if data.ok ~= true then
		return { ok = false, error_code = if data.error_code == "expired" then "expired" else "invalid" }
	end
	if data.key_type ~= "pk" and data.key_type ~= "fk" then
		return { ok = false, error = "Key type was not accepted." }
	end
	authorization[player] = {
		keyType = data.key_type,
		expiresAt = unixExpiry(data.expires_at),
	}
	return {
		ok = true,
		key_type = data.key_type,
		is_unlimited = data.is_unlimited == true,
		expires_at = data.expires_at,
	}
end

broker.OnServerInvoke = function(player: Player, key: unknown): {[string]: any}
	if not validKey(key) then
		return { ok = false, error = "Enter a valid Animula key." }
	end
	return redeem(player, key :: string)
end

local existingLauncher = ReplicatedStorage:FindFirstChild(LAUNCH_REMOTE_NAME)
if existingLauncher and not existingLauncher:IsA("RemoteFunction") then
	error("[Animula] ReplicatedStorage.AnimulaGameLaunch must be a RemoteFunction.")
end
local launcher: RemoteFunction
if existingLauncher then
	launcher = existingLauncher :: RemoteFunction
else
	launcher = Instance.new("RemoteFunction")
	launcher.Name = LAUNCH_REMOTE_NAME
	launcher.Parent = ReplicatedStorage
end

local function canLaunch(player: Player, tier: string): boolean
	if tier == "Free" then
		return true
	end
	local grant = authorization[player]
	if grant and grant.expiresAt and grant.expiresAt <= os.time() then
		authorization[player] = nil
		grant = nil
	end
	local keyType = grant and grant.keyType
	return (tier == "Freemium" and keyType == "fk") or (tier == "Premium" and keyType == "pk")
end

launcher.OnServerInvoke = function(player: Player, gameName: unknown, tier: unknown): {[string]: any}
	if type(gameName) ~= "string" or type(tier) ~= "string" or #gameName > 80 then
		return { ok = false, error = "Invalid game launch request." }
	end
	if tier ~= "Free" and tier ~= "Freemium" and tier ~= "Premium" then
		return { ok = false, error = "Invalid game tier." }
	end
	if not canLaunch(player, tier) then
		return { ok = false, error = "Verify a matching key before launching this module." }
	end

	local root = ServerStorage:FindFirstChild(MODULE_ROOT_NAME)
	local tierFolder = root and root:FindFirstChild(tier)
	local module = tierFolder and tierFolder:FindFirstChild(gameName)
	if not module or not module:IsA("ModuleScript") then
		return { ok = false, error = "This secure game module is not deployed." }
	end

	local required, handler = pcall(require, module)
	if not required or type(handler) ~= "function" then
		warn("[Animula] A deployed game module failed to load: " .. gameName)
		return { ok = false, error = "The secure game module could not start." }
	end
	local launched, launchError = pcall(handler, player)
	if not launched then
		warn("[Animula] A deployed game module failed: " .. tostring(launchError))
		return { ok = false, error = "The secure game module could not start." }
	end
	return { ok = true, message = "Game module started." }
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	authorization[player] = nil
end)

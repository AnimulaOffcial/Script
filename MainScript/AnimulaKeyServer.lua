--!strict
-- Place this Script in ServerScriptService. It only brokers secure key redemption.
-- The request path is: LoaderScript -> this broker -> website API -> Supabase.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "AnimulaKeyBroker"
local SECRET_NAME = "animula_broker_key"
local REQUEST_COOLDOWN = 2

local configuredEndpoint = script:GetAttribute("KeyBrokerEndpoint")
if type(configuredEndpoint) ~= "string" or not string.match(configuredEndpoint, "^https://.+/api/roblox/redeem$") then
	error("[Animula] Set KeyBrokerEndpoint to the HTTPS /api/roblox/redeem URL.")
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

local function invalid(): {[string]: any}
	return { ok = false, error_code = "invalid" }
end

local function redeem(player: Player, key: string): {[string]: any}
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return invalid()
	end
	lastRequest[player] = now

	local secretOk, secret = pcall(function()
		return HttpService:GetSecret(SECRET_NAME)
	end)
	if not secretOk or not secret then
		warn("[Animula] Broker secret is not configured.")
		return invalid()
	end

	local requestOk, response = pcall(function()
		return HttpService:RequestAsync({
			Url = endpoint,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["X-Animula-Server-Key"] = secret :: any,
			},
			Body = HttpService:JSONEncode({
				key = key,
				roblox_user_id = player.UserId,
				roblox_username = player.Name,
			}),
		})
	end)
	if not requestOk or type(response) ~= "table" or not response.Success then
		warn("[Animula] Key verification request failed.")
		return invalid()
	end

	local decoded, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decoded or type(data) ~= "table" then
		return invalid()
	end
	if data.ok ~= true then
		return { ok = false, error_code = if data.error_code == "expired" then "expired" else "invalid" }
	end
	if data.key_type ~= "pk" and data.key_type ~= "fk" then
		return invalid()
	end

	return {
		ok = true,
		key_type = data.key_type,
	}
end

broker.OnServerInvoke = function(player: Player, key: unknown): {[string]: any}
	if not validKey(key) then
		return invalid()
	end
	return redeem(player, key :: string)
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

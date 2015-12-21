local modulename = "abtestingDiversionTracehash"

local _M = {}
local mt = { __index = _M }
_M._VERSION = "0.0.1"

local ERRORINFO = require('abtesting.error.errcode').info

local k_hash = 'hash'
local k_upstream = 'upstream'

_M.new = function(self, database, policyLib)
    if not database then
        error{ERRORINFO.PARAMETER_NONE, 'need available redis db'}
    end
    if not policyLib then 
        error{ERRORINFO.PARAMETER_NONE, 'need available policy lib'}
    end

    self.database = database
    self.policyLib = policyLib
    return setmetatable(self, mt)
end

_M.check = function(self, policy)
    for _, v in pairs(policy) do 
		local tracehash = tonumber(v[k_hash])
		local upstream = v[k_upstream]

	--	if not tracehash  or not upstream then
	--		local info = ERRORINFO.POLICY_INVALID_ERROR
	--		local desc = ' need ' .. k_hash .. ' and ' .. k_upstream
	--		return {false, info, desc}
	--	end

    return {true}
	end
end

_M.set = function(self, policy)
    local database = self.database
    local policyLib = self.policyLib

    database:init_pipeline()
    for i, v in pairs(policy) do
        database:hset(policyLib, v[k_hash], v[k_upstream])
    end

    local ok, err = database:commit_pipeline()
    if not ok then 
        error{ERRORINFO.REDIS_ERROR, err}
    end
end

_M.get = function(self)
    
    local database  = self.database 
    local policyLib = self.policyLib

    local data, err = database:hgetall(policyLib)
    if not data then
        error{ERRORINFO.REDIS_ERROR, err}
    end

    return data
end

local trace2hash = function(trace)
    local h = 0
    local seed = 13
    trace = string.sub(trace, 1, 8) .. string.sub(trace, 10, 13) .. string.sub(trace, 15, 18) .. string.sub(trace, 20, 23) .. string.sub(trace, 25, 36)
    for i = 1, 32 do 
 	-- print(string.sub(trace, i, i))
		local b = string.byte(string.sub(trace, i, i)) - 48
	--print(b)
        h = h*seed + b
	--print(h)
	--print (math.fmod(h, 13))
    end 
    return (math.fmod(h, 5))
end


_M.getUpstream = function(self, trace)
--    if not tonumber(trace) then 
 --       return nil
  --  end

	local hash = trace2hash(trace)
	local database = self.database
	local policyLib = self.policyLib

	local upstream, err = database:hget(policyLib, hash)

	if not upstream then
		error{ERRORINFO.REDIS_ERROR, err}
	end

	if upstream == ngx.null then
		return nil
	else
		return upstream
	end
end


return _M

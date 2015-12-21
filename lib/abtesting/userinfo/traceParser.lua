
local _M = {
    _VERSION = '0.01'
}

_M.get = function()
    local trace = ngx.req.get_headers()["x-ricebook-trace"]
    -- trace = "17211713-1294-5871-ac51-75ffc42c1cfd-xxxx-xxxx"
	return trace
end

return _M

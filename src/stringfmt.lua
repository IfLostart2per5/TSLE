local forbidden = {
    "function",
    "do",
    "end",
    "while",
    "repeat",
    "local",
    "for",
    "goto",
    "if",
    "then"
}

local function block(text)
    for _, w in ipairs(forbidden) do
        if text:match("%f[%a]" .. w .. "%f[%A]") or text:match('["\']') or text:match("%-%-") then
            return false, w
        end
    end
    return true
end

local function eval(expr, ctx)
    ctx = ctx or {}
    local exp = "return " .. expr
    local res, word = block(exp)
    if not res then
        error("Forbidden word found in expression: "..word)
    end
    local env = setmetatable({
        tostring=tostring,
        tonumber=tonumber
    }, {__index=ctx})
    local func, err = loadstring(exp)
    if not func then
        error(err)
    end
    setfenv(func, env)
    return func()
end

local function format(str, ctx)
    local i = 1
    local nstr = ""
    while i <= #str do
        local c = str:sub(i,i)
        if c == "{" then
            i = i + 1
            local s = i
            while str:sub(i, i) ~= "}" do
                i = i + 1
            end
            i = i + 1
            local portion = str:sub(s, i - 2)
            local result = tostring(eval(portion, ctx))
            
            nstr = nstr .. result
            
        else
            nstr = nstr .. c
            i = i + 1
        end
    end
    return nstr
end


return format
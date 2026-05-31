--The Great Language Engine: a pattern matching engine made for translation and linguistic stuff
--second version (improved for perfomance)
local sort = require "src.sort"
local format = require "src.stringfmt"

---@class engine
---@field strings table<string,string>
---@field rules table<string,function>
local engine = {}
local engine_mt = {__index=engine}
local altmark = {}

---@alias matching {[1]: string, [2]: any}
---@alias case {[1]: matching|matching[], [2]: string|function}


---@return engine
function engine.new()
    local obj = {
        strings = {},
        rules={}
    }
    return setmetatable(obj, engine_mt)
end

---@class alternate
---@field mark table
---@field alts any[]
local alternate = {}

---creates an alternate object. That is used to smash similar cases together
---@param tbl any[]
---@return alternate
function engine:alternate(tbl)
    return {
        mark=altmark,
        alts=tbl
    }
end

---@param tbl table
---@return boolean
local function isalternate(tbl)
    return type(tbl) == "table" and tbl.mark == altmark
end

--wildcard for pattern matching
engine.DEFAULT = {}
setmetatable(engine.DEFAULT, {
    __tostring=function (t)
        return "*"
    end
})

---@param case case
---@return case
local function clonecase(case)
    local ncase = {}
    local matchings = case[1]
    local value = case[2]
    if #matchings == 2 and type(matchings[1]) == "string" then
        matchings = {matchings}
    end
    local nmatchings = {}
    for _, matching in ipairs(matchings) do
        local nmatching = {matching[1], matching[2]}
        table.insert(nmatchings, nmatching)
    end
    ncase[1] = nmatchings
    ncase[2] = value
    return ncase
end


---It has two modes: getter and setter. As setter, it defines a simple string internally.
---As getter, it returns the string by its name.
---@param name string
---@param str string
---@overload fun(self,name:string):string
function engine:string(name, str)
    if str then
        self.strings[name] = str
        return
    end
    return self.strings[name]
end

---it also has two modes, getter and setter. As setter, it creates a rule, compiling the cases into 
---a simple lookup function. As getter, it just returns the rule by its name.
---@param name string
---@param params string[]
---@param cases case[]
---@return function
---@overload fun(self,name:string):function
function engine:rule(name, params, cases)
    --getter case
    if not (params or cases) then
        return self.rules[name]
    end
    --zero-params case. It is useful to treat cases where we have a simpler language (that doesn't need
    --inflection, so uses a simple string for a message) and a more complex language (that needs to inflect
    --the same message, so uses a rule for this). A great example is English (simpler) vs Portuguese
    --more complex.
    if #params == 0 then
        self.rules[name] = function()
            return cases
        end
        return self.rules[name]
    end

    --orders that by specificity (number of conditions). Default cases will decrase it
    sort(cases, function (x)
        local matchingslen = type(x[1][1]) == "string" and 1 or #x[1]
        
        return matchingslen
    end)
    
    --fast lookup: disptable stores all the cases with strings (e.g. "masc_sg_plural_nom")
    --the "tree" there is useful for treating default cases
    local disptable = {}
    local tree = {}

    --alternates expanding
    for i = #cases, 1, -1 do
        local case = cases[i]
        local _matchings = case[1]
        local matchings
        if #_matchings == 2 and type(_matchings[1]) == "string" then
            matchings = {_matchings}
        else
            matchings = _matchings
        end
        
        sort(matchings, function (x)
            for j, param in ipairs(params) do
                if param == x[1] then
                    return j
                end
            end
        end)

        case[1] = matchings
        
        for _, matching in ipairs(matchings) do
            if isalternate(matching[2]) then
                for _, alt in ipairs(matching[2].alts) do
                    local k = matching[1]
                    local ncase = clonecase(case)
                    for _, matchin in ipairs(ncase[1]) do
                        if matchin[1] == k then
                            matchin[2] = alt
                        end
                    end
                    table.insert(cases, i + 1, ncase)
                end
                table.remove(cases, i)
            end
        end
    end

    --tree and dispatch table construction
    for i = 1, #cases do
        local case = cases[i]
        local keys = {}
        local prevnode
        for j, vl in ipairs(case[1]) do
            if not tree[vl[1]] then
                tree[vl[1]] = {children={}, values={}}
                if prevnode then
                    prevnode.children[vl[1]] = tree[vl[1]]
                else
                    prevnode = tree[vl[1]]
                end
            end
            
            table.insert(keys, tostring(vl[2]))
            tree[vl[1]].values[vl[2]] = true
        end
        local key = table.concat(keys, "_")

        disptable[key] = case[2]
    end

    --THE RULE
    local tbl = {}
    local function rule(...)
        local keys = {}
        local node = tree[params[1]]
        --key building and tbl fulfilling
        for i, param in ipairs(params) do
            tbl[param] = select(i, ...)
            local test = node.values[tbl[param]]
            local key = test and tostring(tbl[param]) or tostring(engine.DEFAULT)
            keys[#keys + 1] = key
            local node_ = node.children[params[i + 1]]
            if not node_ then
                break
            end
            node = node_
        end
        
        local key = table.concat(keys, "_")
        local match = disptable[key]
        if match then
            if type(match) == "string" then
                return format(match, tbl)
            else
                return match(...)
            end
        end
    end

    self.rules[name] = rule
    return rule
end

return engine
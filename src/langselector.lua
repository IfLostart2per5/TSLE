--Language Selector - this is an abstraction to get strings and rules quickly, and to build languages for your app
local eng = require "src.core"
local languages = {} --pus fora pois isto impede o usuário de acessar
local mod = {}
local unpack = unpack or table.unpack
---A language description. It not describes the languages itself, but the set of strings and rules made with it.
---@class language
---@field engine engine
---@field name string
---@field code string
---@field country string?
local language = {}

---@alias definition string|{[1]: string[], [2]: table[]}

---a string and rule searcher
---@class translator
---@field curlanguage language?
---@field lang table
local translator = {
    ---@type fun(self,key:string,args:any[],langname:string): string
    ---@overload fun(self,key:string,langname:string): string
    translate = function (self,key, args, langname) end,
    ---@type fun(self,name:string)
    setlanguage=function (self,name) end
}

---imports a language and builds it
---@param filename string a lua config file without ".lua" at the end
---@return language
function mod.importlanguage(filename)
    local env = {
        tostring=tostring,
        DEFAULT=eng.DEFAULT
    }

    local code, err = loadfile(filename .. ".lua", "t", env)
    if not code then
        error(err)
    end
    local status, result = pcall(code)
    if not status then
        error(result)
    elseif result then
        error("This file should not return anything.")
    end
    
    local name, langcode, country = assert(env.name, "Expected a name"), assert(env.code, "Expected a language code"), env.country
    local defs = assert(env.definitions, "Expected linguistic definitions")
    local lang = mod.buildlanguage(name, langcode, country, defs)

    return lang
end

---@param name string
---@param code string ISO code of the language
---@param country string? country code (useful to distinguish dialects of the language)
---@param userdefs table<string,definition>
---@return language
function mod.buildlanguage(name, code, country, userdefs)
    local engine = eng.new()
    for k, v in pairs(userdefs) do
        if type(v) == "string" then
            engine:string(k, v)
        else
            engine:rule(k, v[1], v[2])
        end
    end
    
    languages[name] = {
        name=name,
        engine=engine,
        code=code,
        country=country
    }

    return languages[name]
end

---looks up a language
---@param name string
---@return language
function mod.language(name)
    return assert(languages[name], "Language '"..name.."' not found")
end

---it creates a translator
---@return translator
function mod.translator()
    local obj
    ---@type translator
    obj = {
        curlanguage = nil,
      lang=setmetatable({}, {
        __index=function (t, k)
            local curlang = obj.curlanguage
            if curlang then
                return curlang.engine:rule(k) or curlang.engine:string(k)
            end
        end
    })
   }

    function obj:setlanguage(name)
        self.curlanguage = mod.language(name)
    end

    ---@param key string
    ---@param args any[]
    ---@param langname string
    ---@return string
    ---@overload fun(key:string,langname:string): string
    function obj:translate(key, args, langname)
        if not langname then
            langname = args
            args = nil
        end
        local lang = mod.language(langname)
        if not args then
            return lang.engine:string(key)
        else
            return lang.engine:rule(key)(unpack(args))
        end
    end

    return obj
end

return mod --langselector
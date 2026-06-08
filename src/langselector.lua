--Language Selector - this is an abstraction to get strings and rules quickly, and to build languages for your app
local eng = require "tsle.core"
local languages = {} --pus fora pois isto impede o usuário de acessar
local mod = {}
local unpack = unpack or table.unpack
---A language description. It not describes the languages itself, but the set of strings and rules made with it.
---@class language
---@field engine engine
---@field name string
---@field code string
---@field country string?
---@field defs rule
---@field parent language?
local language = {}

---@alias rule table<string,definition|rule>

---@alias definition string|{[1]: string[], [2]: table[]}

---a string and rule searcher
---@class translator
---@field curlanguage language?
---@field lang table?
local translator = {
    ---@type fun(self,key:string,args:any[],langcode:string): string
    ---@overload fun(self,key:string,langcode:string): string
    translate = function (self,key, args, langcode) end,
    ---@type fun(self,code:string)
    setcurrentlanguage=function (self,code) end,
    ---@type fun(self):language
    getcurrentlanguage=function (self)end
}

---imports a language and builds it
---@param filename string a lua config file without ".lua" at the end
---@return language
function mod.importlanguage(filename)
    local env = {
        tostring=tostring,
        DEFAULT=eng.DEFAULT,
        abs=math.abs,
        Alt=eng.alternate,
        pairs=pairs,
        ipairs=ipairs
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

local function processdefs(userdefs, engine, keyprefix, builtdef, parentdefs)
    builtdef = builtdef or {}
    setmetatable(builtdef, {__index=parentdefs})
    keyprefix = keyprefix or ""
    for k, v in pairs(userdefs) do
        local key = keyprefix ..  k
        if type(v) == "string" then
            engine:string(key, v)
            builtdef[k] = v
        elseif type(v) == "table" and type(v[1]) == "table" then
            engine:rule(key, v[1], v[2])
            builtdef[k] = engine:rule(key)
        elseif type(v) == "table" then
            builtdef[k] = {}
            processdefs(v, engine, key .. ".",builtdef[k], parentdefs and parentdefs[k])
        else
            error("invalid value")
        end
    end

    return builtdef
end
---@param name string
---@param code string ISO code of the language
---@param country string? country code (useful to distinguish dialects of the language)
---@param userdefs rule
---@param parent language? useful for dialect variation
---@return language
function mod.buildlanguage(name, code, country, userdefs, parent)
    local engine = eng.new()
    local defs = processdefs(userdefs, engine, nil, nil, parent and parent.defs)
    local langcode = code .. (country and "-"..country or "")
    languages[langcode] = {
        name=name,
        defs=defs,
        engine=engine,
        code=code,
        country=country,
        parent=parent
    }

    return languages[langcode]
end

---looks up a language
---@param code string
---@return language
function mod.language(code)
    return assert(languages[code], "Language '"..code.."' not found")
end

---Checks if there is a language
---@param code string
---@return boolean
function mod.haslanguage(code)
    return languages[code] and true or false
end

---it creates a translator
---@return translator
function mod.translator()
    local obj
    ---@type translator
    obj = {
        curlanguage = nil,
      lang=nil
    }

    function obj:setcurrentlanguage(code)
        self.curlanguage = mod.language(code)
        self.lang=self.curlanguage.defs
    end

    function obj:getcurrentlanguage()
        return self.curlanguage
    end

    ---@param key string
    ---@param args any[]
    ---@param langcode string
    ---@return string
    ---@overload fun(key:string,langcode:string): string
    function obj:translate(key, args, langcode)
        if not langcode then
            langcode = args
            args = nil
        end
        local lang = mod.language(langcode)
        if not args then
            return lang.engine:string(key)
        else
            return lang.engine:rule(key)(unpack(args))
        end
    end

    return obj
end

return mod --langselector

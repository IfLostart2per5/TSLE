# TSLE (The Simple Linguistic Engine)
An ICU-inspired linguistic engine

# How to install
Clone this repo in your machine:
```bash
git clone https://www.github.com/IfLostart2per5/TSLE
```
# How to use
Import it to your code
```
local tsle = require("tsle")
local engine = tsle.engine
```
This engine can store strings and rules. Strings... are strings, and rules are functions that allow you to return different messages
depending on the given arguments. Look this example below
```
--instantiates the engine for english
local english = engine.new()
--simple strings
english:string("greeting", "Hello!")
english:string("leaving", "Bye!")
english:string("wait", "Wait... there is one person more...")
english:string("itsme", "And it's me!! So...")
english:string("laughter", "Hihihi")
--complex rules
english:rule("people_there", {"npeople"}, {
  { {"npeople", 0}, "There is nobody here." },
  { {"npeople", 1}, "There is 1 person here." },
  { {"npeople", engine.DEFAULT}, "There are {npeople} people here." }
})
english:rule("gotthat", {"person"}, {
  { {"person", "player"}, "You got that!" },
  { {"person", "narrator"}, "I got that!" },
  { {"person", "character"}, "He got that!" };
})

--instantiates the engine for portuguese
local portuguese = engine.new()
--simple strings
portuguese:string("greeting", "Olá!")
portuguese:string("leaving", "Tchau!")
portuguese:string("wait", "Pera... há mais alguém aqui...")
portuguese:string("istme", "Esse alguém sou eu! Então...")
portuguese:string("laughter", "Hahaha")
--complex rules
portuguese:rule("people_there", {"npeople"}, {
  { {"npeople", 0}, "Não há ninguém aqui." },
  { {"npeople", 1}, "Há 1 pessoa aqui." },
  { {"npeople", engine.DEFAULT}, "Há {npeople} pessoas aqui." }
})
portuguese:rule("gotthat", {"person"}, {
  { {"person", "player"}, "Tu obtiveste isso!" },
  { {"person", "narrator"}, "Eu obtive isso!" },
  { {"person", "character"}, "Ele obteve isso!" };
})

-- TESTS
function main(language)
  print(language:string "greeting") --Hello!
  local pplthere = language:rule "people_there"
  local gotthat = language:rule "gotthat"
  print(pplthere(1)) --There is one people here
  print(language:string "wait")
  print(language:string "itsme")
  print(pplthere(2))
  print(gotthat "player")
  print(language:string "laughter")
  print(language:string "leaving")
end
main(portuguese)
```
Run it once, then modify the last line to `main(english)`, and you will see.
# Docs
They will come soon.



local function OnLoad( mod )

    Content.AddStringTable("GENOCIDE_ROUTE", {
        GENOCIDE_ROUTE =
        {
            SPEECH =
            {
                BOGUS_ARMOR = "Good thing I have Battle Oshnu armor!",
                DODGE = "Like I would just stand there and take it!",
                -- FALSE_SURRENDER = "You've got me.",
                -- FALSE_SURRENDER_RALLY_1 = "You let your guard down!",
                FALSE_SURRENDER_RALLY_1_RESPONSE = "What? False surrendering is a war crime!",
                FIRST_PHASE_DONE = "There is no end to your bloodlust, is there?",
            },
        }
    })
    local filepath = require "util/filepath"

    for k, path in ipairs( filepath.list_files( "GENOCIDE_ROUTE:patches/", "*.lua", true )) do
        local name = path:match( "(.+)[.]lua$" )
        require(name)
    end

    for k, path in ipairs( filepath.list_files( "GENOCIDE_ROUTE:quips/", "*.yaml", true )) do
        -- local name = path:match( "(.+)[.]yaml$" )
        local db = QuipDatabase(  )
        db:AddFilename(path)
        Content.AddQuips(db)
    end
    for k, path in ipairs( filepath.list_files( "GENOCIDE_ROUTE:quests/", "*.lua", true )) do
        local name = path:match( "(.+)[.]lua$" )
        require(name)
    end
    for k, path in ipairs( filepath.list_files( "GENOCIDE_ROUTE:characters/", "*.lua", true )) do
        local name = path:match( "(.+)[.]lua$" )
        require(name)
    end
end
return {
    version = "0.0.1",
    alias = "GENOCIDE_ROUTE",

    OnLoad = OnLoad,

    title = "Genocide Route",
    desc = "If you kill too much people in Griftlands, you will have to fight the hardest boss in the game, Sals Undertale.",
}
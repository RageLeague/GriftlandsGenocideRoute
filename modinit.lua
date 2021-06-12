local function OnLoad( mod )
    require "GENOCIDE_ROUTE:sals_undertale"
    Content.AddStringTable("GENOCIDE_ROUTE", {
        GENOCIDE_ROUTE =
        {
            SPEECH =
            {
                BOGUS_ARMOR = "Good thing I have Battle Oshnu armor!",
                DODGE = "Like I would just stand there and take it!",
            },
        }
    })
    local filepath = require "util/filepath"

    for k, path in ipairs( filepath.list_files( "GENOCIDE_ROUTE:quips/", "*.yaml", true )) do
        -- local name = path:match( "(.+)[.]yaml$" )
        local db = QuipDatabase(  )
        db:AddFilename(path)
        Content.AddQuips(db)
    end

end
return {
    version = "0.0.1",
    alias = "GENOCIDE_ROUTE",

    OnLoad = OnLoad,

    title = "Genocide Route",
    desc = "If you kill too much people in Griftlands, you will have to fight the hardest boss in the game, Sals Undertale.",
}
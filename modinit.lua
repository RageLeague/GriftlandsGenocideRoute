local function OnLoad( mod )
    require "GENOCIDE_ROUTE:sals_undertale"
    Content.AddStringTable("GENOCIDE_ROUTE", {
        GENOCIDE_ROUTE =
        {
            SPEECH =
            {
                DODGE = "Like I would just stand there and take it!",
            },
        }
    })
end
return {
    version = "0.0.1",
    alias = "GENOCIDE_ROUTE",

    OnLoad = OnLoad,

    title = "Genocide Route",
    desc = "If you kill too much people in Griftlands, you will have to fight the hardest boss in the game, Sals Undertale.",
}
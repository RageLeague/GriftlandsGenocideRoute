local function OnLoad( mod )
    require "GENOCIDE_ROUTE:sals_undertale"
end
return {
    version = "0.0.1",
    alias = "GENOCIDE_ROUTE",

    OnLoad = OnLoad,

    title = "Genocide Route",
    desc = "If you kill too much people in Griftlands, you will have to fight the hardest boss in the game, Sals Undertale.",
}
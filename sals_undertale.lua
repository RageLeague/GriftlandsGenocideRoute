Content.AddCharacterDef
(
    CharacterDef("SALS_UNDERTALE",
    {
        unique = true,
        base_def = "NPC_SAL",

        name = "Sals Undertale",
        title = "Karmic Executioner",

        bio = "If you see Sals Undertale and she looks at your general direction, it is already too late. Just restart the run.",
    })
)
Content.GetCharacterDef("SALS_UNDERTALE"):InheritBaseDef()

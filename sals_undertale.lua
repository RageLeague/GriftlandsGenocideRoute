Content.AddCharacterDef
(
    CharacterDef("SALS_UNDERTALE",
    {
        unique = true,
        base_def = "NPC_SAL",

        name = "Sals Undertale",
        title = "Karmic Executioner",

        bio = "If you see Sals Undertale and she looks at your general direction, it is already too late. Just restart the run.",

        fight_data =
        {
            MAX_HEALTH = 65,
            MAX_MORALE = MAX_MORALE_LOOKUP.HIGH,

            behaviour = {
                OnActivate = function( self, fighter )
                    self.fighter.stat_bounds[ COMBAT_STAT.HEALTH ].min = 1 -- cannot be killed
                end,
            },
        },
    })
)
Content.GetCharacterDef("SALS_UNDERTALE"):InheritBaseDef()

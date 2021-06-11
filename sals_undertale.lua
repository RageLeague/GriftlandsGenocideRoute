local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

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

            conditions =
            {
                sals_dodge_attacks =
                {
                    hidden = true,
                    event_handlers =
                    {
                        [ BATTLE_EVENT.PRE_RESOLVE ] = function( self, battle, attack )
                            if attack.target == self.owner then
                                if attack.card:IsAttackCard() then
                                    for i,hit in ipairs(attack.hits) do
                                        hit.evaded = true
                                        hit.damage = 0
                                    end
                                    self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.DODGE")
                                    self.owner:RemoveCondition(self.id, 1, self)
                                    self.owner:AddCondition("EVASION", 30, self)
                                end

                            end
                        end,
                    },
                },
            },

            behaviour = {
                OnActivate = function( self, fighter )
                    self.fighter.stat_bounds[ COMBAT_STAT.HEALTH ].min = 1 -- cannot be killed

                    self.fighter:AddCondition("sals_dodge_attacks", 1)
                end,
            },
        },
    })
)
Content.GetCharacterDef("SALS_UNDERTALE"):InheritBaseDef()

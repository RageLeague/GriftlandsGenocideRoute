local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = ExtendEnum(battle_defs.BATTLE_EVENT, {
    "CALC_FIGHTER_KILL",
})
local CARD_FLAGS = battle_defs.CARD_FLAGS
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

Content.AddCharacterDef
(
    CharacterDef("SOUL_OF_THE_DEAD",
    {
        base_def = "NPC_BASE",

        name = "",
        title = "Restless Soul",

        combat_strength = 2,
        faction_id = "NEUTRAL",

        combat_anims = {"anim/med_combat_unarmed_chemist.zip"},
		anims={"anim/weapon_knife_common.zip"},

        hide_in_compendium = true,
        is_hologram = true,
        can_talk = true,

        base_builds = {
			[ GENDER.MALE ] = "medium_male",
			[ GENDER.FEMALE ] = "medium_female"
		},

        on_init = function( agent )
            local chargen = require "charactergen"

            local gender = agent.gender
            if gender == nil then
                if agent.species == SPECIES.MECH then
                    gender = GENDER.UNDISCLOSED
                else
                    gender = math.random() > .5 and GENDER.MALE or GENDER.FEMALE
                end
                agent.gender = gender
            end

            if agent.species then
                -- Already determined
            elseif agent.possible_species then
                agent.species = table.tablepick( agent.possible_species )
            else
                agent.species = SPECIES.HUMAN
            end

            chargen.ApplyBuild( agent )

            -- if agent.name == nil then
            -- 	agent:GenerateRandomName()
            -- end
        end,

        AssignDeadChar = function(self, dead_char)
            self.disguise_agent = dead_char
            self.disguise_data = {}
            return self
        end,
    })
)
Content.GetCharacterDef("SOUL_OF_THE_DEAD"):InheritBaseDef()

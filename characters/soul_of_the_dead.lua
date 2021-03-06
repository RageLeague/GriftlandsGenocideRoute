local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = ExtendEnum(battle_defs.BATTLE_EVENT, {
    "CALC_FIGHTER_KILL",
})
local CARD_FLAGS = battle_defs.CARD_FLAGS
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local DEAD_FLASH_VALUES =
{
    colour = 0xeeffffff,
    time_in = 0.1,
    time_out = 0.3,
    max_intensity = 1
}

local DEAD_HOLOGRAM_VALUES =
{
     scale = -1.0,
   -- colour = 0x9900ffff,
    colour = 0xc2d3d2ff,
    alpha = {0.7, 0.3, 2.0}, -- Alpha for each layer of the FX
    speed = {0.05, 0.07, 0.5},
    layersTexture = engine.asset.Texture("rgba/character_hover.tex"),

    glitchSpeed = 0.07,
    glitchScale = 6.0,
    glitchTexture = engine.asset.Texture("glitch/holo_glitch.tex"),

    colormatrixHue = {1.0,1.2,1.2},
    colormatrixSaturation = 0.0,
    colormatrixBrightness = 0.0,
    colormatrixContrast = 1.5,
}

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

        fight_data =
        {
            MAX_HEALTH = 25,
            MAX_MORALE = MAX_MORALE_LOOKUP.IMMUNE,

            OnJoinBattle = function( fighter, anim_fighter )
                local x, y = anim_fighter.sim:GetCamera():WorldToScreen( anim_fighter:GetStatusWidgetPosition() )
                local width = TheGame:FE():GetScreenDims()
                local screen_pos = math.abs(x)/width
                local pan_pos = easing.linear( screen_pos, -1, 2, 1 )
                AUDIO:PlayParamEvent("event:/sfx/battle/atk_anim/kashio/hologram_on", "position", pan_pos)
                anim_fighter:Flash(DEAD_FLASH_VALUES.colour, DEAD_FLASH_VALUES.time_in, DEAD_FLASH_VALUES.time_out, DEAD_FLASH_VALUES.max_intensity)
                anim_fighter:SetHologramEffect(true, DEAD_HOLOGRAM_VALUES)
                local x, z = anim_fighter:GetHomePosition()
                if anim_fighter.team == TEAM.BLUE then
                    x = x - FIGHT_MAX_DIST
                else
                    x = x + FIGHT_MAX_DIST
                end
                anim_fighter:SetPos( x, z )
            end,

            conditions =
            {
                survivors_guilt =
                {
                    name = "Survivor's Guilt",
                    desc = "Deals {1#percent} less damage against Restless Souls.\n\nAt the beginning of their turn, reduce <b>Survivor's Guilt</b> by 1.",
                    desc_fn = function(self, fmt_str)
                        return loc.format(fmt_str, 1 - self.damage_mult)
                    end,

                    ctype = CTYPE.DEBUFF,

                    damage_mult = 0.7,

                    event_priorities =
                    {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = EVENT_PRIORITY_MULTIPLIER,
                    },

                    event_handlers = {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if card.owner == self.owner and target and target:GetAgent() and
                                target:GetAgent():GetContentID() == "SOUL_OF_THE_DEAD" then
                                dmgt:ModifyDamage( math.round( dmgt.min_damage * self.damage_mult ),
                                                math.round( dmgt.max_damage * self.damage_mult ),
                                                self )
                            end
                        end,

                        [ BATTLE_EVENT.END_TURN ] = function( self, fighter )
                            if self.owner == fighter then
                                self.owner:RemoveCondition( self.id, 1 )
                            end
                        end,
                    },
                },

                ghostly_form =
                {
                    name = "Ghostly Form",
                    desc = "If {1}'s attack would cause health loss, prevent that much damage and apply {2} stacks " ..
                        "of debuff chosen from {survivors_guilt}, {dread}, and {annihilation} at the end of {1}'s turn.\n\n" ..
                        "When {1} is killed, each opponent gains debuff chosen from one of the above.",
                    desc_fn = function(self, fmt_str)
                        return loc.format(fmt_str, self:GetOwnerName(), self.stacks or 1)
                    end,

                    ctype = CTYPE.INNATE,

                    event_handlers =
                    {
                        [ BATTLE_EVENT.PRE_RESOLVE ] = function( self, battle, attack )
                            if attack.attacker == self.owner then
                                if attack.card:IsAttackCard() then
                                    for i,hit in attack:Hits() do
                                        if not hit.target:HasCondition("ghostly_form_trigger") then
                                            hit.target:AddCondition("ghostly_form_trigger", self.stacks or 1)
                                            hit.target:GetCondition("ghostly_form_trigger").apply_source = self
                                        end
                                    end
                                end
                            end
                        end,
                        [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, attack )
                            if attack.attacker == self.owner then
                                if attack.card:IsAttackCard() then
                                    for i,hit in attack:Hits() do
                                        hit.target:RemoveCondition("ghostly_form_trigger", nil, self)
                                    end
                                end
                            end
                        end,
                        [ BATTLE_EVENT.STATUS_CHANGED ] = function( self, fighter, status )
                            if fighter == self.owner and status == FIGHT_STATUS.DEAD then
                                for _, other_fighter in pairs( fighter:GetEnemyTeam().fighters ) do
                                    local debuff_list = {"survivors_guilt", "dread"}
                                    if other_fighter:IsPlayer() then
                                        table.insert(debuff_list, "annihilation")
                                    end
                                    other_fighter:AddCondition(table.arraypick(debuff_list), self.stacks, self)
                                end
                            end
                        end,
                    },
                },

                ghostly_form_trigger =
                {
                    hidden = true,
                    -- After defend/damage, but before things like emergency shield generator
                    priority = 1000,

                    OnPreDamage = function( self, damage, attacker, battle, source )
                        if source == nil then
                            return damage
                        end

                        if is_instance( source, Battle.Hit ) and source.attack.owner == (self.apply_source and self.apply_source.owner) then
                            if damage > 0 then
                                if source.target then
                                    local debuff_list = {"survivors_guilt", "dread"}
                                    if source.target:IsPlayer() then
                                        table.insert(debuff_list, "annihilation")
                                    end
                                    source.target:AddCondition(table.arraypick(debuff_list), self.stacks, self)
                                end
                                return 0
                            end
                        end

                        return damage
                    end,
                },
            },

            attacks =
            {
                ghostly_attack = table.extend(NPC_RANGED)
                {
                    name = "Ghostly Attack",
                    anim = "throw",

                    damage_mult = 0.7,
                },
                selfless_protection = table.extend(NPC_BUFF)
                {
                    name = "Selfless Protection",
                    anim = "taunt",
                    target_type = TARGET_TYPE.SELF,
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,

                    defend = { 6, 9, 12, 15, 18 },

                    CanPlayCard = function(self, battle, target )
                        for i, fighter in self.owner.team:Fighters() do
                            if fighter:HasCondition( "PROTECT" ) then
                                return false
                            end
                        end
                        return true
                    end,

                    OnPreResolve = function(self, battle, attack)
                        self.owner:AddCondition( "PROTECT", 1 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ))
                        self.owner:AddCondition( "DEFEND", self:ScaleBuff( self.defend ))
                    end,
                },
                ghostly_restoration = table.extend(NPC_BUFF)
                {
                    name = "Ghostly Restoration",
                    anim = "taunt",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF | CARD_FLAGS.HEAL,

                    target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
                    target_mod = TARGET_MOD.TEAM,

                    OnPostResolve = function(self, battle, attack)
                        for i,hit in ipairs(attack.hits) do
                            hit.target:HealHealth( 8, self )
                        end
                    end,
                },
                ghostly_protection = table.extend(NPC_BUFF)
                {
                    name = "Ghostly Protection",
                    anim = "taunt",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,

                    target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
                    target_mod = TARGET_MOD.TEAM,

                    features =
                    {
                        DEFEND = 8,
                    },
                },
            },

            behaviour =
            {
                OnActivate = function( self, fighter )
                    self.fighter:AddCondition("VENDETTA", 1)
                    self.fighter:AddCondition("ghostly_form", 1 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ))

                    self.buff_cards = self:MakePicker()
                        :AddID( "selfless_protection", 1 )
                        :AddID( "ghostly_protection", 1 )
                        :AddID( "ghostly_restoration", 1 )

                    self.attack_cards = self:MakePicker()
                        :AddID( "ghostly_attack", 1 )
                        -- :AddID( "ai_defend_med", 1 )
                    self:SetPattern( (math.random() < 0.5) and self.AttackPattern or self.BuffPattern )
                end,

                BuffPattern = function( self, fighter )
                    self.buff_cards:ChooseCard()
                    self:SetPattern( self.AttackPattern )
                end,

                AttackPattern = function( self, fighter )
                    self.attack_cards:ChooseCard()
                    self:SetPattern( self.BuffPattern )
                end,
            },
        },
    })
)
Content.GetCharacterDef("SOUL_OF_THE_DEAD"):InheritBaseDef()

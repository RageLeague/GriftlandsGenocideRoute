local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = ExtendEnum(battle_defs.BATTLE_EVENT, {
    "CALC_FIGHTER_KILL",
})
local CARD_FLAGS = battle_defs.CARD_FLAGS
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local COMBO_REQ = 5

local function CollectDeadAgents()
    local dead_agents = {}
    for k, agent in pairs( TheGame:GetGameState().removed_agents or {} ) do
        if agent:IsSentient() and agent:IsDead() then
            table.insert_unique( dead_agents, agent )
        end
    end
    return dead_agents
end

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
            MAX_MORALE = MAX_MORALE_LOOKUP.MEDIUM,

            always_false_surrender = true,

            attacks =
            {
                sals_deception =
                {
                    name = "Deception",
                    desc = "{IMPROVISE} an attack card from your draw pile. That card deals +{1} damage until played.",
                    anim = "taunt2",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function(self, battle, attack)
                        self.owner:AddCondition("deception", 1, self)

                        local selected_card

                        if not self.scripted_improv then
                            local options = {}
                            local attack_picker = self.owner.behaviour.attacks
                            if attack_picker then
                                for card, weight in pairs(attack_picker.weighted_options) do
                                    if card:IsAttackCard() then
                                        table.insert(options, card)
                                    end
                                end
                            end
                            local finisher_picker = self.owner.behaviour.finishers
                            if finisher_picker and self.owner:GetConditionStacks("COMBO") >= COMBO_REQ then
                                for card, weight in pairs(finisher_picker.weighted_options) do
                                    if card:IsAttackCard() then
                                        table.insert(options, card)
                                    end
                                end
                            end
                            if #options > 0 then
                                selected_card = table.arraypick(options)
                            end
                        else
                            if self.scripted_improv == "INIT_SURPRISE" then
                                selected_card = self.owner.behaviour.blademouth_beating
                            elseif self.scripted_improv == "FALSE_SURRENDER" then
                                selected_card = self.owner.behaviour.blademouth_beating
                                if (self.owner.false_surrender_count or 0) == 1 then
                                    if battle:GetPlayerFighter() then
                                        battle:GetPlayerFighter():SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.FALSE_SURRENDER_RALLY_1_RESPONSE")
                                    end
                                end
                            end
                            self.scripted_improv = nil
                        end
                        if selected_card then
                            selected_card.deception_bonus = 4
                            if selected_card.OnNPCImprovised then
                                selected_card:OnNPCImprovised(self)
                            end
                            battle:PlayCard(selected_card)
                        end
                    end,
                },
                sals_inside_fighting =
                {
                    name = "Inside Fighting",
                    anim = "taunt3",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function(self, battle, attack)
                        self.owner:AddCondition("inside_fighting", 1, self)
                    end,
                },
                sals_blademouth_beating = table.extend(NPC_ATTACK)
                {
                    name = "Blademouth Beating",
                    anim = "uppercut",
                    flags = CARD_FLAGS.MELEE | CARD_FLAGS.DEBUFF,
                    damage_mult = 0.3,

                    bleed_feature = "BLEED",
                    bleed_count = 2,
                    -- hit_count = 3,
                    OnNPCImprovised = function(self, source)
                        self.improvised = true
                        self.hit_count = 3
                        self.hit_anim = true
                    end,
                    OnPostResolve = function(self, battle, attack)
                        local feature = Content.GetBattleCardFeature( self.bleed_feature )
                        if feature and feature.apply then
                            for i, hit in attack:Hits() do
                                feature:apply( self.engine, attack, self.bleed_count, hit.target )
                            end
                        end
                        self.improvised = false
                        self.hit_count = 1
                        self.hit_anim = false
                    end,
                },
            },

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
                sals_bogus_armor =
                {
                    hidden = true,
                    event_handlers =
                    {
                        [ BATTLE_EVENT.DELTA_STAT ] = function( self, fighter, stat, delta, value, mitigated  )
                            if fighter == self.owner and stat == COMBAT_STAT.HEALTH and not self.has_gained_defense then
                                if value <= 1 then
                                    self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.BOGUS_ARMOR")
                                    self.owner:RemoveCondition(self.id, 1, self)
                                end
                            end
                        end,
                    },
                },
                -- Just a marker to indicate there is a false surrender for her.
                sals_false_surrender_trigger =
                {
                    hidden = true,
                    event_handlers =
                    {
                        [ BATTLE_EVENT.FIGHTER_SURRENDER ] = function( self, fighter )
                            if fighter == self.owner then
                                -- self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.FALSE_SURRENDER")
                            end
                        end,
                    },
                },
                sals_death_defiance =
                {
                    hidden = true,
                    event_handlers =
                    {
                        [ BATTLE_EVENT.CALC_FIGHTER_KILL ] = function( self, acc, killed, killer )
                            print("Check death defiance")
                            print(self)
                            print(acc)
                            print(killed)
                            print(killer)
                            if killed == self.owner and killed:GetStat( COMBAT_STAT.HEALTH ) > 0 then
                                -- self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.FALSE_SURRENDER")
                                print("Triggered death defiance")
                                acc:ModifyValue(false, self)
                                self.battle:BroadcastEvent( BATTLE_EVENT.ON_DODGE, killed, nil, killer )
                                if self.battle:HasExecutes() then
                                    -- Move on to the next phase
                                    self.owner.behaviour_phase = (self.owner.behaviour_phase or 0) + 1
                                    local screen = TheGame:FE():FindScreen( "Screen.FightScreen" )
                                    if screen then screen.end_turn = true end
                                    self.battle:ResumeFromExecution()
                                    self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.FIRST_PHASE_DONE")

                                    self.owner:AddCondition("sals_custom_rally_logic", 1)
                                    -- self.owner.mute = false

                                    if self.owner.behaviour and self.owner.behaviour.SecondPhaseInit then
                                        self.owner.behaviour:SetPattern(self.owner.behaviour.SecondPhaseInit)
                                    end
                                end
                            end
                        end,
                    },
                },
                sals_custom_rally_logic =
                {
                    hidden = true,
                    event_handlers =
                    {
                        [ BATTLE_EVENT.BEGIN_TURN ] = function( self, fighter )
                            if fighter == self.owner then
                                fighter.mute = true
                                fighter:Rally()
                            end
                        end,
                        [ EVENT.END_TURN ] = function( self, fighter )
                            if fighter == self.owner then
                                fighter.mute = false
                                self.owner:RemoveCondition(self.id, 1, self)
                            end
                        end,
                    },
                },
            },

            behaviour = {
                OnFalseSurrender = function(self, fighter)
                    fighter.false_surrender_count = (fighter.false_surrender_count or 0) + 1
                    self:SetPattern(self.FalseSurrenderDeception)
                    fighter:Rally()

                end,
                OnActivate = function( self, fighter )
                    self.fighter.stat_bounds[ COMBAT_STAT.HEALTH ].min = 1 -- cannot be killed

                    self.fighter:AddCondition("sals_dodge_attacks", 1)
                    self.fighter:AddCondition("sals_bogus_armor", 1)
                    self.fighter:AddCondition("sals_false_surrender_trigger", 1)
                    self.fighter:AddCondition("sals_death_defiance", 1)

                    self.fighter:AddCondition("npc_sal_nailed_glove")
                    -- self.fighter:AddCondition("npc_sal_combo_pattern")

                    self.fighter:AddCondition("sucker_punch", 1)

                    self.blademouth_beating = self:AddCard("sals_blademouth_beating")

                    self.attacks = self:MakePicker()
                        :AddID( "npc_sal_gut_shot", 2 )
                        :AddID( "npc_sal_shoulder_roll", 1 )
                        :AddID( "npc_sal_feint_combo", 1 )
                        :AddCard( self.blademouth_beating, 1 )
                    self.finishers = self:MakePicker()
                        :AddID( "npc_sal_haymaker", 1)
                        :AddID( "npc_sal_blade_fury", 1)
                    -- This is for the initial set up turn
                    self.deception = self:AddCard( "sals_deception" )
                    self.inside_fighting = self:AddCard( "sals_inside_fighting" )

                    self:SetPattern( self.FirstAttack )
                end,

                FirstAttack = function( self )
                    self:ChooseCard( self.inside_fighting )
                    self.deception.scripted_improv = "INIT_SURPRISE"
                    self:ChooseCard( self.deception )

                    self:SetPattern( self.NormalPattern )
                end,

                NormalPattern = function( self )
                    if math.random() < 0.3 then
                        self:ChooseCard( self.deception )
                        return
                    end
                    if self.fighter:GetConditionStacks("COMBO") >= COMBO_REQ then
                        -- self.attacks:ChooseCard()
                        self.finishers:ChooseCard()
                    else
                        self.attacks:ChooseCards(2)
                    end
                end,

                FalseSurrenderDeception = function(self)
                    self.deception.scripted_improv = "FALSE_SURRENDER"
                    self:ChooseCard( self.deception )

                    self:SetPattern( self.NormalPattern )
                end,

                SecondPhaseInit = function(self)
                end,
            },
        },
    })
)
Content.GetCharacterDef("SALS_UNDERTALE"):InheritBaseDef()

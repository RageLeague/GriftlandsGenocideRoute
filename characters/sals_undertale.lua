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

        combat_strength = 5,

        boss = true,

        battle_preview_anim = "anim/hero_sal_outfit1_slide.zip",
        battle_preview_offset = { x = -1024, y = -25, scale = 1 },
        battle_preview_glow = { colour = 0x11FFFEFF, bloom = 0.35, threshold = 0.02 },
        battle_preview_audio = "event:/ui/prebattle_overlay/prebattle_overlay_whooshin_boss_assassin_hanbi",

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

                    base_damage = 3,

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
                sals_summon_dead =
                {
                    name = "Summon Restless Souls",
                    anim = "call_in",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function(self, battle, attack)
                        local dead_people = CollectDeadAgents()
                        table.shuffle(dead_people)
                        for i = 1, 15 do
                            local agent = dead_people[i]
                            local new_agent = Agent("SOUL_OF_THE_DEAD")
                            if agent then
                                new_agent:AssignDeadChar(agent)
                            end
                            self.owner:GetTeam():AddFighter( Fighter.CreateFromAgent( new_agent, self.owner:GetScale() ) )
                        end
                        self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.SUMMON_DEAD")
                        self.owner:DeltaMorale(-self.owner:GetMorale())
                        self.owner:AddCondition("DAUNTLESS", 1)
                    end,
                },
                sals_healing_vapors =
                {
                    name = "Healing Vapors",
                    anim = "taunt",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF | CARD_FLAGS.HEAL,
                    target_type = TARGET_TYPE.SELF,

                    mending_amt = 6,

                    CanPlayCard = function(self, battle, target )
                        return self.owner:GetHealthPercent() < 0.9
                    end,

                    OnPostResolve = function( self, battle, attack )
                        self.target:AddCondition("MENDING", self.mending_amt, self)
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
                            if attack.target == self.owner and self.owner:IsActive() then
                                if attack.card:IsAttackCard() then
                                    for i,hit in ipairs(attack.hits) do
                                        hit.evaded = true
                                        hit.damage = 0
                                    end
                                    self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.DODGE")
                                    self.owner:RemoveCondition(self.id, 1, self)
                                    self.owner:AddCondition("EVASION", 20 + 5 * (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1), self)
                                end

                            end
                        end,
                    },
                },
                sals_bogus_armor =
                {
                    hidden = true,
                    OnApply = function( self, battle )
                        if not self.owner:GetStat(COMBAT_STAT.MORALE) then
                            self.free_surrender = true
                        end
                    end,
                    event_handlers =
                    {
                        [ BATTLE_EVENT.DELTA_STAT ] = function( self, fighter, stat, delta, value, mitigated  )
                            if fighter == self.owner and stat == COMBAT_STAT.HEALTH and not self.has_gained_defense then
                                if value <= 1 then
                                    if self.free_surrender then
                                        self.owner:EnableMorale(true)
                                        self.owner:Surrender()
                                        self.free_surrender = nil
                                        return
                                    end
                                    if self.owner:IsActive() then
                                        self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.BOGUS_ARMOR")
                                        self.owner:RemoveCondition(self.id, 1, self)
                                    end
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
                                if self.battle:HasExecutes() and (self.owner.behaviour_phase or 0) >= 1 then
                                    self.owner:SaySpeech(1, LOC"GENOCIDE_ROUTE.SPEECH.SALS_DEFEATED")
                                    return
                                end
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
                                    if self.owner.behaviour_phase == 1 then
                                        if self.owner.behaviour and self.owner.behaviour.SecondPhaseInit then
                                            self.owner.behaviour:SetPattern(self.owner.behaviour.SecondPhaseInit)
                                        end
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
                                fighter.rally_modifier = "sals_determination"
                                fighter:Rally()
                            end
                        end,
                        [ BATTLE_EVENT.END_TURN ] = function( self, fighter )
                            if fighter == self.owner then
                                fighter.rally_modifier = "RALLIED"
                                self.owner:RemoveCondition(self.id, 1, self)
                            end
                        end,
                    },
                },
                sals_determination =
                {
                    name = "Determination",
                    desc = "Deals 25% more damage.\n\nWhen damaged, gain a stack, then gain {DEFEND} equal to the number of stacks.\n\n" ..
                        "Gain {DEFEND} equal to the number of stacks at the end of turn.",
                    ctype = CTYPE.BUFF,
                    icon = "battle/conditions/rallied.tex",

                    apply_sound = SoundEvents.battle_status_rallied,

                    OnApply = function( self, battle )
                        local HEAL_PERCENT = 1
                        local MIN_HEAL = 5

                        local min, max = self.owner:GetStatBounds( COMBAT_STAT.HEALTH )
                        local current_health = self.owner:GetHealth()

                        self.owner:DeltaHealth( math.max( MIN_HEAL, max * HEAL_PERCENT ) )
                    end,

                    event_handlers =
                    {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if card.owner == self.owner then
                                dmgt:ModifyDamage( math.round( dmgt.min_damage * 1.25 ),
                                                math.round( dmgt.max_damage * 1.25 ),
                                                self )
                            end
                        end,

                        [ BATTLE_EVENT.CONDITION_ADDED ] = function( self, fighter, condition, stacks, source )
                            if condition:GetID() == "SURRENDER" and fighter == self.owner then
                                self.owner:RemoveCondition(self.id)
                            end
                        end,

                        [ BATTLE_EVENT.DELTA_STAT ] = function( self, fighter, stat, delta, value, mitigated  )
                            if fighter == self.owner and stat == COMBAT_STAT.HEALTH and delta < 0 then
                                self.owner:AddCondition(self.id, 1, self)
                                self.owner:AddCondition("DEFEND", self.stacks or 1, self)
                            end
                        end,

                        [ BATTLE_EVENT.END_TURN ] = function( self, fighter )
                            if fighter == self.owner then
                                self.owner:AddCondition("DEFEND", self.stacks or 1, self)
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
                    fighter.mute = true

                    self.fighter:AddCondition("sals_dodge_attacks", 1)
                    self.fighter:AddCondition("sals_bogus_armor", 1)
                    self.fighter:AddCondition("sals_false_surrender_trigger", 1)
                    self.fighter:AddCondition("sals_death_defiance", 1)

                    self.fighter:AddCondition("npc_sal_nailed_glove")
                    -- self.fighter:AddCondition("npc_sal_combo_pattern")

                    self.fighter:AddCondition("sucker_punch", 2)

                    self.blademouth_beating = self:AddCard("sals_blademouth_beating")

                    self.attacks = self:MakePicker()
                        :AddID( "npc_sal_gut_shot", 2 )
                        :AddID( "npc_sal_shoulder_roll", 1 )
                        :AddID( "npc_sal_feint_combo", 1 )
                        :AddID( "sals_healing_vapors", 3 )
                        :AddCard( self.blademouth_beating, 1 )
                    self.finishers = self:MakePicker()
                        :AddID( "npc_sal_haymaker", 1)
                        :AddID( "npc_sal_blade_fury", 1)
                    -- This is for the initial set up turn
                    self.deception = self:AddCard( "sals_deception" )
                    self.inside_fighting = self:AddCard( "sals_inside_fighting" )

                    self.summon_dead = self:AddCard( "sals_summon_dead" )

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
                    self:ChooseCard( self.summon_dead )

                    self:SetPattern( self.NormalPattern )
                end,
            },
        },
    })
)
Content.GetCharacterDef("SALS_UNDERTALE"):InheritBaseDef()

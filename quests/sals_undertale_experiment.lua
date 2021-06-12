local boss_options = {"sals_undertale"}

local QDEF = QuestDef.Define{
        title = "Sals Undertale Boss Test",
        qtype = QTYPE.EXPERIMENT,
        -- dev_only = true,
        icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
        rank = 5,
        act_filter = "SAL",
    }
    :AddLocationDefs{

        AUCTION_HOUSE =
        {
            name = "Auction House",
            desc = "The room where the auction is taking place.",
            show_agents = true,
            indoors = true,
            no_exit = true,
            plax = "EXT_NadanFight",
        }

    }
    :AddCastByAlias{
        cast_id = "sals_undertale",
        alias = "SALS_UNDERTALE",
        non_sentient_valid = true,
    }
    :AddObjective{
        id = "test",
        title = "Fight the new bosses and provide feedback!",
        state = QSTATUS.ACTIVE,
    }

QDEF:AddConvo("test")
    :ConfrontState("INTRO")
        :Fn(function(cxt)
            cxt.quest:SetRank(5)
            TheGame:GetGameState():SetDifficulty(5)
            cxt.quest.param.seed = 0
            cxt.encounter:DoLocationTransition(  cxt.quest:SpawnTempLocation("AUCTION_HOUSE") )
            cxt:GoTo("STATE_INTRO")
        end)

    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                * This is a balancing test for the Sals Undertale. The audio and visuals are not complete, and there are no story elements.
                * The decks used in this experiment are from the end of Sal's 4th day. Therefore the bosses will feel more difficult than they will be in the campaign.
            ]],
            OPT_SET_SEED = "Enter seed",
            OPT_USE_RANDOM_SEED = "Use a random seed",
            DIALOG_BAD_SEED = [[* That is not a valid seed (seeds are numbers)]],
            OPT_SET_PRESITGE = "Set a new prestige",
            DIALOG_NEW_PRESTIGE = [[* Prestige set to: {1}]],
            DIALOG_BAD_PRESTIGE = [[* That is not a valid prestige. (prestige must be a number between 0 and 6)]]
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.enc:GetScreen():ClearHistory()
                cxt:Dialog("DIALOG_INTRO")
                -- if #cxt.caravan:GetPets() < 1then
                --     local pet = cxt.quest:CreateSkinnedAgent( "CRAYOTE" )
                --     pet:MoveToLocation( cxt.location )
                --     TheGame:GetGameState():AddAgent( pet )
                --     pet:Recruit(PARTY_MEMBER_TYPE.CREW)
                -- end
            end

            cxt:Opt("OPT_USE_RANDOM_SEED")
                :Fn(function()
                    cxt.quest.param.seed = os.time()
                    cxt:GoTo("STATE_PRE_FIGHT")
                end)
            cxt:Opt("OPT_SET_PRESITGE")
                :Fn(function(cxt)
                    UIHelpers.EditString(
                        "Enter a prestige", "", "",
                        function( val )
                            val = val and tonumber(val)
                            if val then
                                cxt.quest.param.prestige = val
                            end
                            cxt.enc:ResumeEncounter(val)
                         end )
                    local prestige = cxt.enc:YieldEncounter()
                    if prestige and prestige <= 6 then
                        cxt.quest.param.prestige = prestige
                        TheGame:GetGameState():SetAdvancementLevel(prestige)
                        cxt:Dialog("DIALOG_NEW_PRESTIGE", prestige)
                    else
                        cxt:Dialog("DIALOG_BAD_PRESTIGE")
                    end
                end)

            cxt:Opt("OPT_SET_SEED")
                :Fn(function(cxt)
                    UIHelpers.EditString(
                        "Enter a seed", "", "",
                        function( val )
                            val = val and tonumber(val)
                            if val then
                                cxt.quest.param.seed = val
                            end
                            cxt.enc:ResumeEncounter(val)
                         end )
                    local seed = cxt.enc:YieldEncounter()
                    if seed then
                        cxt.quest.param.seed = seed
                        cxt:GoTo("STATE_PRE_FIGHT")
                    else
                        cxt:Dialog("DIALOG_BAD_SEED")
                    end
                end)

        end)

    :State("STATE_PRE_FIGHT")
        :Loc{
            DIALOG_INTRO = [[
                * Random Seed: {1}
            ]],
            DIALOG_DECK = [[ * Test Deck Selected: #{1}]],
            OPT_REROLL = "Try a new seed",
            OPT_USE = "Use this seed",
            DIALOG_SOCIAL = [[
                * <#BONUS>Social Boons: {1#graft_list}</>
                * <#PENALTY>Social Banes: {2#graft_list}</>
            ]],
        }
        :Fn(function(cxt)
            local DECKS = require "content/quests/experiments/sal_day_4_decks"
            math.randomseed(cxt.quest.param.seed)
            local deck_idx = math.random(#DECKS)
            local deck = DECKS[deck_idx]
            TheGame:GetGameState():SetDecks(deck)

            cxt:Dialog("DIALOG_INTRO", cxt.quest.param.seed)
            cxt:Dialog("DIALOG_DECK", deck_idx)

            local negotiation, battle, boons, banes = {}, {}, {}, {}
            for k,v in ipairs( cxt.player.graft_owner.grafts) do
                if v:GetType() == GRAFT_TYPE.SOCIAL then
                    if v:GetDef().is_boon then
                        table.insert(boons, v)
                    elseif v:GetDef().is_bane then
                        table.insert(banes, v)
                    end
                elseif v:GetType() == GRAFT_TYPE.COMBAT then
                    table.insert(battle, v)
                elseif v:GetType() == GRAFT_TYPE.NEGOTIATION then
                    table.insert(negotiation, v)
                end

            end

            table.sort(boons, function(a,b) return a:GetName() < b:GetName() end)
            table.sort(banes, function(a,b) return a:GetName() < b:GetName() end)
            cxt:Dialog("DIALOG_SOCIAL", boons, banes)


            cxt:RunLoopingFn(function()
                        cxt:Opt("OPT_USE")
                            :Fn(function()
                                cxt:GoTo("STATE_CHOOSE_BOSS")
                            end)
                        cxt:Opt("OPT_REROLL")
                            :Fn(function()
                                cxt.enc:GetScreen():ClearHistory()
                                cxt.quest.param.seed = os.time() + math.random(10000)
                                cxt:GoTo("STATE_PRE_FIGHT")
                            end)
                    end)
        end)

        :State("STATE_CHOOSE_BOSS")
            :Loc{
                DIALOG_INTRO = [[
                    * Choose the boss you wish to fight, or fight a random one.
                ]],
                OPT_SPECIFIC = "Fight {1#agent_list}",
                OPT_RANDOM = "Random Boss",
            }
            :Fn(function(cxt)
                for i,id in ipairs(boss_options) do
                    local boss = cxt.quest:GetCastAgent(id)
                    cxt:Opt("OPT_SPECIFIC", {boss})
                        :Fn(function(cxt)
                            cxt.enc:SetPrimaryCast(boss)
                            cxt.quest.param.boss_id = boss
                            cxt:GoTo("STATE_DO_FIGHT")
                        end)
                end

                cxt:Opt("OPT_RANDOM")
                    :Fn(function(cxt)
                        local boss = cxt.quest:GetCastAgent(table.arraypick(boss_options))
                        cxt.enc:SetPrimaryCast(boss)
                        cxt.quest.param.boss_id = boss
                        cxt:GoTo("STATE_DO_FIGHT")
                    end)
            end)

        :State("STATE_DO_FIGHT")
            :Loc{
                DIALOG_INTRO = [[
                    player:
                        !left
                        !fight
                    agent:
                        !right
                        !fight
                ]],
                OPT_FIGHT = "Fight!",
                DIALOG_DONE_FIGHT = [[
                    left:
                        !happy
                    right:
                        !greeting
                    * Thanks for testing! Now would be a great time to submit some feedback about that fight! (Your seed was: {1})
                ]],
                OPT_RETRY = "Retry this exact fight",
                OPT_AGAIN = "Start over",
                DIALOG_AGAIN = [[
                    player:
                        !exit
                    agent:
                        !exit
                ]],
                OPT_FEEDBACK = "Tell us how that went!"
            }
            :Fn(function(cxt)
                cxt:Dialog("DIALOG_INTRO")
                local allies = {}
                -- Unclear what the structure of the quest and thereby the backup will be in the final version.

                cxt:Opt("OPT_FIGHT")
                    :Battle{
                        allies = allies,
                        flags = BATTLE_FLAGS.ISOLATED | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.SELF_DEFENCE,
                        IS_EXPERIMENT = true,
                        on_experiment_done = function( cxt, battle )
                            local player_team = {}
                            local enemy_team = {}
                            for k,v in ipairs(battle:GetScenario().teams[TEAM.BLUE]) do
                                table.insert(player_team, v:GetContentID())
                            end

                            for k,v in ipairs(battle:GetScenario().teams[TEAM.RED]) do
                                table.insert(enemy_team, v:GetContentID())
                            end

                            local player_state = TheGame:GetGameState():GetPlayerState()
                            local json_t = {
                                PLAYER_DATA = player_state,
                                BATTLE_DATA = {
                                    TURNS = battle.turns,
                                    CONTENT_ID = battle:GetScenario().content_id,
                                    HEALTH_DELTA = battle:GetPlayerFighter():GetHealth() - battle:GetPlayerFighter():GetMaxHealth(), -- Player always start with full HP
                                    PLAYER_TEAM = player_team,
                                    ENEMY_TEAM = enemy_team,
                                },
                                EXPERIMENT_DATA = {
                                    ENEMY_HEALTH_PERCENTAGE = battle:GetEnemyTeam():Primary():GetHealthPercent() * 100,
                                }
                            }
                            local evt_type = (battle:GetBattleResult() == BATTLE_RESULT.WON) and "EXPERIMENT_BATTLE_WON" or "EXPERIMENT_BATTLE_LOST"
                            SendMetricsData(evt_type, json_t )
                        end,
                    }


                    :Fn(function()
                        cxt:Dialog("DIALOG_DONE_FIGHT", cxt.quest.param.seed)

                        cxt:RunLoopingFn(function()
                            cxt:Opt("OPT_FEEDBACK")
                                :Fn(function() TheGame:StartFeedback() end)
                            cxt:Opt("OPT_AGAIN")
                                :Fn(function(cxt)
                                    for i,id in ipairs(boss_options) do
                                        cxt.quest:UnassignCastMember(id)
                                        cxt.quest:AssignCastMember(id)
                                    end
                                end)
                                :Dialog("DIALOG_AGAIN")
                                :GoTo("STATE_INTRO")
                            cxt:Opt("OPT_RETRY")
                                :GoTo("STATE_DO_FIGHT")
                        end)
                    end)
            end)
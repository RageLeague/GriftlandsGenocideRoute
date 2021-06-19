local function CollectDeadAgents()
    local dead_agents = {}
    for k, agent in pairs( TheGame:GetGameState().removed_agents or {} ) do
        if agent:IsSentient() and agent:IsDead() then
            table.insert_unique( dead_agents, agent )
        end
    end
    return dead_agents
end

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    cooldown = EVENT_COOLDOWN.LONG,
    priority = QEVENT_PRIORITY.HIGH,
    precondition = function(quest)
        local dead_agents = CollectDeadAgents()
        quest.param.dead_agents = dead_agents
        return #dead_agents >= 15
    end,
}
:AddCastByAlias{
    cast_id = "sals",
    alias = "SALS_UNDERTALE",
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * You are minding your own business when you are confronted by a person.
                player:
                    !left
                sals:
                    !right
                    Hi, there.
                player:
                {player_sal?
                    Who are you and why do you look like me?
                    |
                    Who are you?
                }
                sals:
                    I am {sals}.
                    You've been busy, haven't you?
                player:
                    Well, yeah.
                    !throatcut
                    In fact, I am so busy that I prefer you to <i>stay out of my way</i>.
                sals:
                    !hips
                    Hmm... Always aggressive huh?
                    That is what I want to talk about.
                    !fight
                    You have too much blood on your hands. It's time to end this.
            ]],
            DIALOG_INTRO_DEATH_RESTART = [[
                * You are confronted by {sals}.
                player:
                    !left
                sals:
                    !right
                {1:
                sals:
                    Heh. Look at you. I betcha I beat you good.
                    But it seems that you come back anyway.
                player:
                    What do you mean?
                sals:
                    !cruel
                    You <i>know</i> what I mean.
                    !fight
                    I've beaten you once, I can beat you again.
                    |
                sals:
                    How's dying? Not great I presume?
                player:
                    Not sure what you are talking about, but I'm pretty sure dying is not great.
                sals:
                    !throatcut
                    Tell that to all those people you've killed.
                    !fight
                    In the afterlife.
                    |
                sals:
                    You know I know you are save scumming, right?
                    You should've restarted a long time ago.
                player:
                    Drop this nonsense.
                sals:
                    !fight
                    I guess you never learn, huh?
                    |
                sals:
                    You know this is all pointless, right?
                    You can't beat me, and I can beat you.
                    You could just restart, and be a better person. And not kill anyone.
                    But no, you think you can beat me if you just keep trying.
                player:
                    You are underestimating me. I am nothing if not resilient.
                sals:
                    !fight
                    You should learn to fold when you draw a bad hand.
                    |
                sals:
                    You are back.
                    !fight
                    Let's just get this over with.
                }
            ]],
            DIALOG_FIGHT_WON = [[
                * You've defeated {sals}. There is no one left that is capable of stopping you now.
            ]],
        }
        :Fn(function(cxt)
            if (cxt.quest.param.dialog_count or 0) == 0 then
                cxt:Dialog("DIALOG_INTRO")
            else
                cxt:Dialog("DIALOG_INTRO_DEATH_RESTART", cxt.quest.param.dialog_count)
            end
            cxt:Opt("OPT_DEFEND")
                :Fn(function(cxt)
                    cxt.quest.param.dialog_count = (cxt.quest.param.dialog_count or 0) + 1
                    DoAutoSave()
                end)
                :Battle{
                    flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT,
                    enemies = {"sals"},
                    on_win = function(cxt)
                        cxt:Dialog("DIALOG_FIGHT_WON")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }
        end)
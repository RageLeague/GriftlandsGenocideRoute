local FightScreen = Screen.FightScreen
local old_accept_surrender_fn = FightScreen.AcceptSurrender
function FightScreen:AcceptSurrender(...)
    local battle = self.battle
    local has_false_surrender = false
    for i, fighter in battle:GetEnemyTeam():Fighters() do
        if fighter.fight_data and fighter.fight_data.always_false_surrender then
            has_false_surrender = true
        end
    end
    if has_false_surrender then
        print("Someone's false surrendering! probably bad for u lol")
        -- return old_accept_surrender_fn(self, ...)
        AUDIO:PlayEvent(SoundEvents.battle_accept_surrender)
        self.end_turn = true

        self.battle:ResumeFromExecution()
        for i, fighter in battle:GetEnemyTeam():Fighters() do
            if fighter.behaviour and fighter.behaviour.OnFalseSurrender then
                fighter.behaviour:OnFalseSurrender(fighter)
            end
        end
    else
        return old_accept_surrender_fn(self, ...)
    end
end

local old_add_executes = BattleEngine.AddExecutes
function BattleEngine:AddExecutes(...)
    if not self.added_executes then
        self.cards_in_play_before_execution = {}
        for i, card in self.hand_deck:Cards() do
            table.insert(self.cards_in_play_before_execution, card)
        end
        for i, card in self.draw_deck:Cards() do
            table.insert(self.cards_in_play_before_execution, card)
        end
        for i, card in self.discard_deck:Cards() do
            table.insert(self.cards_in_play_before_execution, card)
        end
        for i, card in self.resolve_deck:Cards() do
            table.insert(self.cards_in_play_before_execution, card)
        end
    end
    return old_add_executes(self, ...)
end

function BattleEngine:ResumeFromExecution()
    if self.added_executes then
        local screen = TheGame:FE():FindScreen( "Screen.FightScreen" )
        if screen then
            screen.accept_surrender_button:AnimateOut()
            screen.end_turn_btn:AnimateIn()
        end
        self.hand_deck:TransferCards( self.trash_deck )
        self.draw_deck:TransferCards( self.trash_deck )
        self.discard_deck:TransferCards( self.trash_deck )
        self.resolve_deck:TransferCards( self.trash_deck )
        if self.cards_in_play_before_execution then
            for i, card in ipairs(self.cards_in_play_before_execution) do
                card:TransferCard( self.draw_deck )
            end
        end
        self.added_executes = nil
    end
end
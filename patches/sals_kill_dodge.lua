local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = ExtendEnum(battle_defs.BATTLE_EVENT, {
    "CALC_FIGHTER_KILL",
})

local old_fighter_kill = Fighter.Kill
function Fighter:Kill( killer, ... )
    if not self.battle.fighter_kill_accumulator then
        self.battle.fighter_kill_accumulator = CardEngine.ScalarAccumulator( self.battle, BATTLE_EVENT.CALC_FIGHTER_KILL )
    end
    local do_kill, details = self.battle.fighter_kill_accumulator:CalculateValue( true, self, killer )
    if do_kill then
        return old_fighter_kill(self, killer, ...)
    else
    end
end
local patch_id = "DISGUISE_PAPERDOLL_UTIL"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local paperdoll = require "paperdoll_util"

local old_fn1 = paperdoll.SetCharacterData
paperdoll.SetCharacterData = function(anim_model, char, combat, scale )
    if char.disguise_agent then
        if not( char.disguise_data and char.disguise_data.use_new_anim ) and char.disguise_agent:CanTalk() then
            char.disguise_agent.combat_anims = char.combat_anims
            char.disguise_agent.anims = char.anims
        end
        return old_fn1(anim_model, char.disguise_agent, combat, scale)
    end
    return old_fn1(anim_model, char, combat, scale)
end
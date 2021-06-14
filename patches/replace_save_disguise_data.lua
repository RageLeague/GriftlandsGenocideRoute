local patch_id = "REPLACE_SAVE_DISGUISE_DATA"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Agent.Save

Agent.Save = function(self)
    local data = old_fn(self)
    if self.original_data then
        data.original_data = self.original_data
    end
    if self.null_fields then
        data.null_fields = self.null_fields
    end
    if self.disguise_data then
        data.disguise_data = self.disguise_data
    end
    return data
end
local old_load = Agent.Load
Agent.Load = function(self)
    if self.disguise_data then
        self.disguise_agent = Agent.CreateDummyAgent(self.disguise_data.content_id, self.disguise_data.uuid)
    end
    if self.original_data then
        self.original_agent = Agent.CreateDummyAgent(self.original_data.content_id, self.original_data.uuid)
    end
    old_load(self)

end

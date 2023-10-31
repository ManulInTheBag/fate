modifier_medea_dragon = class({})

if IsServer() then
	function modifier_medea_dragon:OnCreated()
		self:StartIntervalThink(FrameTime())
	end

	function modifier_medea_dragon:OnIntervalThink()
	    local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 750, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
	    for k,v in pairs(targets) do
	        self:GetParent():AddNewModifier(v, nil, "modifier_vision_provider", {duration = 0.2})
	    end
	end
end
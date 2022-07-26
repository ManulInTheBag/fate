modifier_death_tracker = class({})

if IsServer() then
	function modifier_death_tracker:OnCreated(args)
		self:SetStackCount(args.Deaths)	
	end

	function modifier_death_tracker:OnRefresh(args)
		self:SetStackCount(args.Deaths)	
	end
end

function modifier_death_tracker:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_death_tracker:GetTexture()
	return "custom/peopledie"
end
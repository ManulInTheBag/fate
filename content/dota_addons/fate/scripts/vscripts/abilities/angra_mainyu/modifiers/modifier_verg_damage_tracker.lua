modifier_verg_damage_tracker = class({})
modifier_verg_damage_tracker_progress = class({})

LinkLuaModifier("modifier_verg_marker", "abilities/angra_mainyu/modifiers/modifier_verg_marker", LUA_MODIFIER_MOTION_NONE)

function modifier_verg_damage_tracker:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE
	 }
end

if IsServer() then 
	function modifier_verg_damage_tracker:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end

		local reset_delay = self:GetAbility():GetSpecialValueFor("reset_delay")
		local marker_duration = self:GetAbility():GetSpecialValueFor("marker_duration")
		local caster = self:GetParent()
		local attacker = args.attacker

		--if caster.IsDIAcquired then args.damage = args.damage * 1.25 end

		self.DamageTaken = math.min((self.DamageTaken or 0) + args.damage, self:GetParent():GetMaxHealth())

		self:SetStackCount(self.DamageTaken / 10)
		self:StartIntervalThink(reset_delay)

		local progress = caster:FindModifierByName("modifier_verg_damage_tracker_progress")
		if progress then
			progress.TotalDuration = reset_delay
			progress.DurationLeft = reset_delay
			progress:StartIntervalThink(0.05)
		end

		if attacker:IsHero() then
			attacker:AddNewModifier(caster, self:GetAbility(), "modifier_verg_marker", { Duration = marker_duration })			
		end		
	end

	function modifier_verg_damage_tracker:OnIntervalThink()
		self:ResetCounter()
	end

	function modifier_verg_damage_tracker:ResetCounter()
		self.DamageTaken = 0
		self:SetStackCount(0)

		local progress = self:GetParent():FindModifierByName("modifier_verg_damage_tracker_progress")
		if progress then			
			progress:StartIntervalThink(-1)
			progress:SetStackCount(0)
		end

		self:StartIntervalThink(-1)
	end

	function modifier_verg_damage_tracker:GetDamageTaken()
		return self.DamageTaken
	end
end

function modifier_verg_damage_tracker:IsHidden()
	return false 
end

function modifier_verg_damage_tracker:IsPermanent()
	return true 
end

if IsServer() then
	function modifier_verg_damage_tracker_progress:OnIntervalThink()
		if self.DurationLeft == nil or self.DurationLeft == 0 then 
			self:SetStackCount(0)
			self:StartIntervalThink(-1) 
			return
		else
			self.DurationLeft = self.DurationLeft - 0.05
			self:SetStackCount(100 * (self.DurationLeft / self.TotalDuration))
		end
	end
end

function modifier_verg_damage_tracker_progress:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_verg_damage_tracker_progress:IsHidden()
    return true
end

function modifier_verg_damage_tracker_progress:IsDebuff()
    return false
end

function modifier_verg_damage_tracker_progress:RemoveOnDeath()
    return false
end

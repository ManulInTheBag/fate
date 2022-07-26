modifier_jtr_mental_pollution = class({})

LinkLuaModifier("modifier_jtr_mental_pollution_shield", "abilities/jtr/modifiers/modifier_jtr_mental_pollution_shield", LUA_MODIFIER_MOTION_NONE)

function modifier_jtr_mental_pollution:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE
	 }
end

if IsServer() then 
	function modifier_jtr_mental_pollution:OnCreated(args)
		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_jtr_mental_pollution_shield", {})
		self:StartIntervalThink(1)
	end

	function modifier_jtr_mental_pollution:OnIntervalThink()
		if self:GetParent():HasModifier("modifier_jtr_mental_pollution_shield") then			
			self:StartIntervalThink(-1)
		else
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_jtr_mental_pollution_shield", {})
		end
	end

	function modifier_jtr_mental_pollution:BeginCooldown()
		print("begin cooldown")
		
		self:StartIntervalThink(self:GetAbility():GetCooldown(1))
		self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(1))
	end

	--[[function modifier_jtr_mental_pollution:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end

		if not self:GetAbility():IsCooldownReady() then
			local cooldown = self:GetAbility():GetCooldownTimeRemaining()
			self:GetAbility():EndCooldown()

			if (cooldown - 2) > 0 then
				self:GetAbility():StartCooldown(cooldown - 2)
				self:StartIntervalThink(cooldown - 2)
			end
		end
	end]]
end

function modifier_jtr_mental_pollution:IsHidden()
	return false
end

function modifier_jtr_mental_pollution:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
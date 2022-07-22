modifier_minds_eye_attribute = class({})

LinkLuaModifier("modifier_minds_eye_vision", "abilities/diarmuid/modifiers/modifier_minds_eye_vision", LUA_MODIFIER_MOTION_NONE)

function modifier_minds_eye_attribute:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_minds_eye_attribute:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_minds_eye_attribute:GetAuraRadius()
	return 1500
end

function modifier_minds_eye_attribute:GetModifierAura()
	return "modifier_minds_eye_vision"
end

function modifier_minds_eye_attribute:IsHidden()
	return false 
end

function modifier_minds_eye_attribute:RemoveOnDeath()
	return false
end

function modifier_minds_eye_attribute:IsDebuff()
	return false 
end

function modifier_minds_eye_attribute:IsAura()
	return true 
end

--[[function modifier_minds_eye_attribute:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

if IsServer() then
	function modifier_minds_eye_attribute:OnCreated(args)	
		self.Radius = args.Radius or self:GetAbility():GetSpecialValueFor("radius")
		self.VisionDuration = args.VisionDuration or self:GetAbility():GetSpecialValueFor("duration")

		self:StartIntervalThink(0.3)
	end


	function modifier_minds_eye_attribute:OnIntervalThink()
		local caster = self:GetParent()
		local targetflag = DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE

		if caster:IsAlive() then
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, targetflag, FIND_ANY_ORDER, false)
	    	
	    	for _,v in pairs(targets) do
		        if CanBeDetected(v) then
		            v:AddNewModifier(caster, self, "modifier_minds_eye_vision", { duration = self.VisionDuration })
	        	end
	        end
		end
	end
end]]
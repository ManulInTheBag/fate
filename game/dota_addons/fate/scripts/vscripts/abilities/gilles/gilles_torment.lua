gilles_torment = class({})
modifier_gilles_torment = class({})

LinkLuaModifier("modifier_gilles_torment", "abilities/gilles/gilles_torment", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_fear", "abilities/gilles/modifiers/modifier_gilles_fear", LUA_MODIFIER_MOTION_NONE)

function gilles_torment:GetManaCost(iLevel)
	return (self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("mana_cost") / 100)
end

function gilles_torment:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_torment:IsHiddenAbilityCastable()
	return true
end

function gilles_torment:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetLocation = self:GetCursorPosition()
	local iAOE = self:GetAOERadius() + 100

	EmitSoundOnLocationWithCaster(vTargetLocation, "Gilles_Torment_Cast", hCaster)

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vTargetLocation, nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
	for _,v in pairs(tEnemies) do
		if not v:IsMagicImmune() then
			v:AddNewModifier(hCaster, self, "modifier_gilles_torment", { DistanceDamage = self:GetSpecialValueFor("distance_damage"),
																		 Damage = self:GetSpecialValueFor("damage"),
																		 Duration =  self:GetSpecialValueFor("duration") + 0.1})
			v:AddNewModifier(hCaster, self, "modifier_gilles_fear", {duration = 10})
		end
	end

	local particle = ParticleManager:CreateParticle("particles/custom/gilles/torment_cast.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
	ParticleManager:SetParticleControl(particle, 0, vTargetLocation)
	ParticleManager:SetParticleControl(particle, 2, vTargetLocation)
	ParticleManager:SetParticleControl(particle, 3, Vector(iAOE, iAOE, iAOE))

	Timers:CreateTimer(2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)
end


if IsServer() then 
	function modifier_gilles_torment:OnCreated(args)
		self.vLocation = self:GetParent():GetAbsOrigin()
		self.Damage = (args.Damage * 0.33) / self:GetDuration()
		self.DistanceDamage = args.DistanceDamage

		self:StartIntervalThink(0.33)

		self.ParticleIndex = ParticleManager:CreateParticle("particles/custom/gilles/torment_debuffhellborn_debuff.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
 		ParticleManager:SetParticleControl(self.ParticleIndex, 0, self:GetParent():GetAbsOrigin())
	end

	function modifier_gilles_torment:OnRefresh(args)
		self.vLocation = self:GetParent():GetAbsOrigin()
		self.Damage = args.Damage * 0.33	
		self.DistanceDamage = args.DistanceDamage
	end

	function modifier_gilles_torment:OnDestroy()
		ParticleManager:DestroyParticle( self.ParticleIndex, false )
        ParticleManager:ReleaseParticleIndex( self.ParticleIndex )
	end

	function modifier_gilles_torment:OnIntervalThink()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local fDamage = self.Damage
		local fDistance = (self:GetParent():GetAbsOrigin() - self.vLocation):Length2D()

		if (fDistance > 0) and (fDistance < 2000) then
			fDamage = fDamage + (fDistance * self.DistanceDamage / 100)
		end
		if not self:GetParent():IsMagicImmune() then
			DoDamage(hCaster, self:GetParent(), fDamage, DAMAGE_TYPE_MAGICAL, 0, hAbility, false)
		end
		self.vLocation = self:GetParent():GetAbsOrigin()
	end
end

function modifier_gilles_torment:IsDebuff()
	return true
end

function modifier_gilles_torment:IsHidden() 
	return false 
end

function modifier_gilles_torment:GetTexture()
	return "custom/gilles/gilles_torment"
end
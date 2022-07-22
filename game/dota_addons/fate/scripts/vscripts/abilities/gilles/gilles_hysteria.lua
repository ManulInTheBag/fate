gilles_hysteria = class({})
modifier_gilles_hysteria = class({})

LinkLuaModifier("modifier_gilles_hysteria", "abilities/gilles/gilles_hysteria", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_fear", "abilities/gilles/modifiers/modifier_gilles_fear", LUA_MODIFIER_MOTION_NONE)

function gilles_hysteria:CastFilterResultTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" or hTarget == self:GetCaster() then -- or hTarget:HasModifier("modifier_gilles_hysteria") then 
		return UF_FAIL_CUSTOM 
	else
		local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
	
		return filter
	end
end

function gilles_hysteria:IsHiddenAbilityCastable()
	return true
end

function gilles_hysteria:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "Cannot target wards"
	elseif hTarget == self:GetCaster() then
		return "Cannot target self"
	--elseif hTarget:HasModifier("modifier_gilles_hysteria") then
	--	return "Already affected by Hysteria"
	else
		return "Invalid Target"
	end
end

function gilles_hysteria:GetManaCost(iLevel)
	return (self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("mana_cost") / 100)
end

function gilles_hysteria:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	--EmitSoundOnLocationWithCaster(vTargetLocation, "Hero_Nevermore.Shadowraze", hCaster)

	hTarget:AddNewModifier(hCaster, self, "modifier_gilles_hysteria", { AttackSpeed = self:GetSpecialValueFor("attack_speed"),
																		Damage = self:GetSpecialValueFor("damage"),
																	 	Duration = self:GetSpecialValueFor("duration") })
	hTarget:AddNewModifier(hCaster, self, "modifier_gilles_fear", {duration = 10})
end

function modifier_gilles_hysteria:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

if IsServer() then 
	function modifier_gilles_hysteria:OnCreated(args)
		self.Damage = args.Damage
		self.AttackSpeed = args.AttackSpeed

		CustomNetTables:SetTableValue("sync","gilles_hysteria_stat", { att_spd = self.AttackSpeed })

		self.Particle = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_infested_unit.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.Particle, 0, self:GetParent():GetAbsOrigin()) 
		ParticleManager:SetParticleControl(self.Particle, 1, self:GetParent():GetAbsOrigin())
	end

	--function modifier_gilles_hysteria:OnRefresh(args)
	--	self.Damage = args.Damage
	--	self.AttackSpeed = args.AttackSpeed

	--	CustomNetTables:SetTableValue("sync","gilles_hysteria_stat", { att_spd = self.AttackSpeed })
    --end

	function modifier_gilles_hysteria:OnDestroy()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local fDamage = (self:GetParent():GetMaxHealth() * self.Damage / 100)

		DoDamage(hCaster, self:GetParent(), fDamage, DAMAGE_TYPE_MAGICAL, 0, hAbility, false)
		self:GetParent():AddNewModifier(hCaster, hAbility, "modifier_stunned", {Duration = hAbility:GetSpecialValueFor("stun_duration") })

		ParticleManager:DestroyParticle(self.Particle, true)
		ParticleManager:ReleaseParticleIndex(self.Particle)
	end	
end

function modifier_gilles_hysteria:GetModifierAttackSpeedBonus_Constant()
	local att_spd = 0

	if IsServer() then
		att_spd = -1*self.AttackSpeed
	else
		att_spd = -1*CustomNetTables:GetTableValue("sync","gilles_hysteria_stat").att_spd
	end

	return att_spd
end

function modifier_gilles_hysteria:IsDebuff()
	return true
end

function modifier_gilles_hysteria:IsHidden() 
	return false 
end

function modifier_gilles_hysteria:GetTexture()
	return "custom/gilles/gilles_hysteria"
end

function modifier_gilles_hysteria:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end
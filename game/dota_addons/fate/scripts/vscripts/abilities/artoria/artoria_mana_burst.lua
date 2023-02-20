-----------------------------
--    Mana Burst   --
-----------------------------

artoria_mana_burst = class({})

LinkLuaModifier( "modifier_artoria_mana_burst_slow", "abilities/artoria/modifiers/modifier_artoria_mana_burst_slow", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_damage", "abilities/artoria/artoria_mana_burst", LUA_MODIFIER_MOTION_NONE )

function artoria_mana_burst:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:IsMagicImmune() then
		return
	end
	
	local damage = self:GetSpecialValueFor("damage")
	
	if caster:HasModifier("modifier_artoria_mana_burst_attribute") then
		damage = damage + 150
		caster:FindAbilityByName("artoria_invisible_air"):EndCooldown()
		caster:AddNewModifier(caster, self, "modifier_artoria_damage", {duration = 3})
	end
	
	--EmitSoundOn("Hero_ElderTitan.EarthSplitter.Destroy", caster)
	
	caster:EmitSound("artoria_mana_burst")
	
	--[[local blastFx = ParticleManager:CreateParticle("particles/custom/artoria/artoria_mana_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( blastFx, 1, Vector(0, 200, 0))]]

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())

    caster:EmitSound("Saber.Caliburn")
    caster:EmitSound("saber_attack_01")
	
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, 350 , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
		for k,mana_burst_target in pairs(targets) do
			if mana_burst_target:IsMagicImmune() then
				return
			end
			local targetdamage = damage
			if mana_burst_target ~= target then
				targetdamage = targetdamage/2
			end
			DoDamage(caster, mana_burst_target, targetdamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			
			local slashParticleName = "particles/custom/saber/caliburn/slash.vpcf"
			local explodeParticleName = "particles/custom/saber/caliburn/explosion.vpcf"


			-- Create particle
			local slashFxIndex = ParticleManager:CreateParticle( slashParticleName, PATTACH_ABSORIGIN, mana_burst_target )
			local explodeFxIndex = ParticleManager:CreateParticle( explodeParticleName, PATTACH_ABSORIGIN, mana_burst_target )
			mana_burst_target:AddNewModifier(caster, self, "modifier_artoria_mana_burst_slow", { Duration = self:GetSpecialValueFor("duration") })
		end
end

modifier_artoria_damage = class({})

function modifier_artoria_damage:IsHidden() return false end
function modifier_artoria_damage:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end
function modifier_artoria_damage:GetModifierPreAttack_BonusDamage()
	return (30 + self:GetCaster():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_multiplier"))
end
function modifier_artoria_damage:GetModifierAttackSpeedBonus_Constant()
	return 40
end
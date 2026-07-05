-- Medusa: Bloodfort Andromeda (full lua port of the old datadriven version).
-- Blood dome around the cast point: ticks damage/lifedrain every 0.5s while
-- Medusa stays inside (or rides Bellerophon), bonus vs bleeding targets,
-- Blood Seal attribute roots/locks on every other tick.
rider_5th_bloodfort_andromeda = class({})

LinkLuaModifier("modifier_bloodfort_slow", "abilities/medusa/rider_5th_bloodfort_andromeda", LUA_MODIFIER_MOTION_NONE)

function rider_5th_bloodfort_andromeda:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function rider_5th_bloodfort_andromeda:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local initCasterPoint = caster:GetAbsOrigin()
	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local absorbAmount = self:GetSpecialValueFor("absorb")
	local bloodfortCount = 0
	caster:EmitSound("medusa_bloodfort_new")

	Timers:RemoveTimer("medusa_bloodfort")
	if type(ability.sphereFxIndex) == "number" then
		ParticleManager:DestroyParticle( ability.sphereFxIndex, false )
		ParticleManager:ReleaseParticleIndex( ability.sphereFxIndex )
	end

	Timers:CreateTimer("medusa_bloodfort", {
		callback = function()
		if bloodfortCount >= duration or not caster:IsAlive() or ((caster:GetAbsOrigin() - initCasterPoint):Length2D() > radius and not caster:HasModifier("modifier_medusa_bellerophon")) then
			if type(ability.sphereFxIndex) == "number" then
				ParticleManager:DestroyParticle( ability.sphereFxIndex, false )
				ParticleManager:ReleaseParticleIndex( ability.sphereFxIndex )
			end
			return
		end

		local first = false

		local targets = FindUnitsInRadius(caster:GetTeam(), initCasterPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" and not v:IsMagicImmune() then
				if not IsImmuneToSlow(v) then v:AddNewModifier(caster, ability, "modifier_bloodfort_slow", { duration = 1.5 }) end

				local target_damage = damage + (v:HasModifier("modifier_medusa_bleed") and v:FindModifierByName("modifier_medusa_bleed"):GetStackCount()*ability:GetSpecialValueFor("bleed_damage") or 0)
				local target_absorb = absorbAmount + (v:HasModifier("modifier_medusa_bleed") and v:FindModifierByName("modifier_medusa_bleed"):GetStackCount()*ability:GetSpecialValueFor("bleed_absorb") or 0)

		        DoDamage(caster, v, target_damage * 0.5, DAMAGE_TYPE_MAGICAL, 0, ability, false)

		        if v:IsHero() then
		        	if not first then
		        		first = true
		        	else
		        		target_absorb = target_absorb/3
		        	end
		        	v:SetMana(v:GetMana() - (target_damage * 0.1))
		        	caster:ApplyHeal(target_absorb * 0.5, caster)
		        	caster:GiveMana(target_absorb * 0.1)
		        end

				if caster.SealAcquired and (bloodfortCount % 2 == 0) then
					giveUnitDataDrivenModifier(caster, v, "rooted", 0.3)
					giveUnitDataDrivenModifier(caster, v, "locked", 0.3)
				end
			end
	    end
		bloodfortCount = bloodfortCount + 0.5
		return 0.5
		end
		}
	)

	ability.sphereFxIndex = ParticleManager:CreateParticle("particles/custom/rider/rider_bloodfort_andromeda_sphere.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(ability.sphereFxIndex, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(ability.sphereFxIndex, 1, Vector(radius, radius, radius))
end

-- tick debuff: attack/move slow while inside the dome
modifier_bloodfort_slow = class({})

function modifier_bloodfort_slow:IsDebuff() return true end

function modifier_bloodfort_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_bloodfort_slow:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_bloodfort_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end

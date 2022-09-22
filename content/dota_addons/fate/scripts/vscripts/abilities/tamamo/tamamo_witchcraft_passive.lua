tamamo_witchcraft_passive = class({})
modifier_tamamo_witchcraft_passive = class({})
modifier_tamamo_witchcraft_debuff = class({})

LinkLuaModifier("modifier_tamamo_witchcraft_passive", "abilities/tamamo/tamamo_witchcraft_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tamamo_witchcraft_debuff", "abilities/tamamo/tamamo_witchcraft_passive", LUA_MODIFIER_MOTION_NONE)

function tamamo_witchcraft_passive:GetIntrinsicModifierName()
	return "modifier_tamamo_witchcraft_passive"
end

function modifier_tamamo_witchcraft_passive:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then 
	function modifier_tamamo_witchcraft_passive:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		local hTarget = args.target
		local hCaster = args.attacker
		local base_damage = self:GetAbility():GetSpecialValueFor("base_damage")
		local duration = self:GetAbility():GetSpecialValueFor("duration")/3

		if hTarget:HasModifier("modifier_tamamo_fire_debuff") then
			local hFireCharm = hCaster:FindAbilityByName("tamamo_fiery_heaven")
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, hFireCharm:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for i = 1, #tEnemies do
				tEnemies[i]:AddNewModifier(hCaster, hFireCharm, "modifier_tamamo_fire_debuff", { Duration = hFireCharm:GetSpecialValueFor("duration")})
			end	

			local explodeFx = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
			ParticleManager:SetParticleControl( explodeFx, 0, hTarget:GetAbsOrigin())
			hTarget:EmitSound("Ability.LightStrikeArray")

			Timers:CreateTimer(1.5, function()
				ParticleManager:DestroyParticle(explodeFx, false)
				ParticleManager:ReleaseParticleIndex(explodeFx)
		    	return nil
		    end)
		elseif hTarget:HasModifier("modifier_tamamo_ice_debuff") then
			local hCharmAbility = hCaster:FindAbilityByName("tamamo_frigid_heaven")
			giveUnitDataDrivenModifier(hCaster, hTarget, "locked", 0.5)
			hTarget:AddNewModifier(hCaster, hCharmAbility, "modifier_tamamo_ice_debuff", { Duration = hCharmAbility:GetSpecialValueFor("duration") })

			hTarget:EmitSound("Hero_Invoker.ColdSnap.Freeze")
		elseif hTarget:HasModifier("modifier_tamamo_wind_debuff") then
			hTarget:FindModifierByName("modifier_tamamo_wind_debuff"):OnIntervalThink()
		end

		DoDamage(hCaster, hTarget, base_damage + self:GetParent():GetIntellect(), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		args.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_tamamo_witchcraft_debuff", { Duration = duration })
	end
end

function modifier_tamamo_witchcraft_passive:IsPermanent()
	return true 
end

function modifier_tamamo_witchcraft_passive:IsHidden()
	return false
end

function modifier_tamamo_witchcraft_passive:GetTexture()
	return "custom/tamamo_witchcraft"
end

function modifier_tamamo_witchcraft_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

if IsServer() then
	function modifier_tamamo_witchcraft_debuff:OnCreated(args)
		self:SetStackCount(1)
	end

	function modifier_tamamo_witchcraft_debuff:OnRefresh(args)
		self:SetStackCount(self:GetStackCount() + 1)
	end
end

function modifier_tamamo_witchcraft_debuff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("magic_resist") * self:GetStackCount()
end

function modifier_tamamo_witchcraft_debuff:IsDebuff()
	return true
end

function modifier_tamamo_witchcraft_debuff:GetTexture()
	return "custom/tamamo_witchcraft"
end
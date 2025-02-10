karna_slashes = class({})
function karna_slashes:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_brahmastra_new"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_brahmastra_new"):SetLevel(self:GetLevel())
    end

end

function karna_slashes:CastFilterResultLocation(location)
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_slashes:GetCustomCastErrorLocation()
	return "Performing other ability"
end

--phase start 0.2
function karna_slashes:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.4})
end

function karna_slashes:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

 

function karna_slashes:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized()
	local time = 0.8
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.4)  
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	caster:EmitSound("karna_new_fire_2")
	caster:EmitSound("karna_new_karna_hit_3")
	local saBool1 = false
	local saBool2 = false
	local armor_modifier = caster:FindModifierByName("modifier_karna_armor") 
	Timers:CreateTimer(0.0, function()

		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)
	if not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
  				local origin_diff_norm = origin_diff:Normalized()
   				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					if caster:HasModifier("modifier_karna_buff_melee") then
						buff_ability:ApplyBurnStacks(v)
					end
					if caster.UncrownedAttribute and not saBool1 then
						armor_modifier:RestoreArmorPercentage(10)
						saBool1 = true
					end
				end
			end
		end
	
	
	end)
	Timers:CreateTimer(0.35, function()
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_3")

	end)
	Timers:CreateTimer(0.4, function()
		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash_2.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)

		if not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
				local origin_diff_norm = origin_diff:Normalized()
				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
				    DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					if caster:HasModifier("modifier_karna_buff_melee") then
						buff_ability:ApplyBurnStacks(v)
					end
					if caster.UncrownedAttribute and not saBool2 then
						armor_modifier:RestoreArmorPercentage(10)
						saBool2 = true
					end
			  	end
			end
		end
		

	
	end)


end

LinkLuaModifier("modifier_karna_self_pause","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_self_pause_2","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
 
karna_upper_slash = class({})
 

function karna_upper_slash:CastFilterResultLocation(location)
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_upper_slash:GetCustomCastErrorLocation()
	return "Performing other ability"
end


 

 

function karna_upper_slash:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized()
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	local forward2 = forward
	local bArmorRestore = false
	local bArmorActive = caster:FindModifierByName("modifier_karna_buff_melee")
	local armor_modifier = caster:FindModifierByName("modifier_karna_armor") 
	forward2.z = 0
	caster:SetForwardVector(forward2)
	caster:AddNewModifier(caster, self, "modifier_karna_self_pause_2", {Duration = 0.6}) 

	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	StartAnimation(caster, {duration=0.8, activity=ACT_DOTA_CAST_ALACRITY, rate=1})
	Timers:CreateTimer(0.42, function()
		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)
		local targets = FATE_FindUnitsInLine(
			caster:GetTeamNumber(),
			caster:GetAbsOrigin(),
			caster:GetAbsOrigin() + forward * 600,
			150,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_ALL,
			0,
			FIND_CLOSEST)

		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
  				local origin_diff_norm = origin_diff:Normalized()
   				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
					if not bArmorRestore and  bArmorActive ~= nil then 
						armor_modifier:RestoreArmorPercentage(5)
						bArmorRestore = true
					end
					if caster:HasModifier("modifier_karna_buff_melee") then
						buff_ability:ApplyBurnStacks(v)
					end
					ApplyAirborne(caster, v, self:GetSpecialValueFor("airborne_duration"))

					v:EmitSound("Hero_Juggernaut.OmniSlash.Damage")	
				end
			end
		end
	
	
	end)



end

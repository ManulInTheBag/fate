demon_king_combo_recast = class({})

LinkLuaModifier("modifier_maou_combo_hit", "abilities/demon_king_nobunaga/demon_king_combo_recast", LUA_MODIFIER_MOTION_NONE)

function demon_king_combo_recast:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function demon_king_combo_recast:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function demon_king_combo_recast:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()
	local CanBeCasted = (hCaster:FindAbilityByName("demon_king_combo").point - vLocation):Length2D() <= hCaster:FindAbilityByName("demon_king_combo"):GetSpecialValueFor("radius")
    if vLocation
        and hCaster and not hCaster:IsNull() then
        if  CanBeCasted and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function demon_king_combo_recast:GetCustomCastErrorLocation(vLocation)
    return "Wrong_Target_Location"
end


function demon_king_combo_recast:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local small_radius = self:GetSpecialValueFor("small_radius")
	local large_radius = self:GetSpecialValueFor("radius")
	local full_damage = self:GetSpecialValueFor("damage")
	local delay = self:GetSpecialValueFor("delay")
	local half_damage = full_damage * 0.5
	local comboAbil = caster:FindAbilityByName("demon_king_combo")

	

	local modifier_counter = caster:GetModifierStackCount("modifier_demon_king_combo_counter", caster)


	if modifier_counter then
		if modifier_counter <= 0 then return 
		else
		caster:SetModifierStackCount("modifier_demon_king_combo_counter", caster, modifier_counter - 1)
		
		end
	end
	
	local add_delay = 0
	if modifier_counter == 1 then
		small_radius = self:GetSpecialValueFor("last_explosion_radius")
		large_radius = self:GetSpecialValueFor("last_explosion_radius")
		full_damage = self:GetSpecialValueFor("last_explosion_damage")
		half_damage = 0
		delay = delay + 0.5
		add_delay = 0.5
		EmitGlobalSound("kostya_release_voice")
		StartAnimation(comboAbil.KostyaDummy, {duration=1.46, activity=ACT_DOTA_CAST_COLD_SNAP, rate=1})
	else
		StartAnimation(comboAbil.KostyaDummy, {duration=0.66, activity=ACT_DOTA_CAST_SUN_STRIKE, rate=1})
	end
	local visiondummy = SpawnVisionDummy(caster, target_point, large_radius, delay + 1, false)
	Timers:CreateTimer(0.4, function()
		caster:EmitSound("kostya_blast_fly_sound")
		return
	end)

	Timers:CreateTimer(0.4, function()
		local point_particle = ParticleManager:CreateParticle("particles/karna/kundala_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
		local point_particle_2 = ParticleManager:CreateParticle("particles/karna/kundala_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(point_particle, 0,  target_point )
		ParticleManager:SetParticleControl(point_particle, 1,  Vector(small_radius,0,0) )

		ParticleManager:SetParticleControl(point_particle_2, 0,  target_point+Vector(0,0,350) )
		ParticleManager:SetParticleControl(point_particle_2, 1,  Vector(small_radius,0,0) )

		Timers:CreateTimer(1.0 +add_delay, function()
			ParticleManager:DestroyParticle(point_particle, false)
			ParticleManager:ReleaseParticleIndex(point_particle)
			ParticleManager:DestroyParticle(point_particle_2, false)
			ParticleManager:ReleaseParticleIndex(point_particle_2)
			if modifier_counter == 1 then
				caster:RemoveModifierByNameAndCaster("modifier_demon_king_combo_counter", caster)
			end
		end)
		return
	end)
	


	local throw_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_projectile.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(throw_particle, 1, (target_point + Vector(0, 0, 1500) - caster:GetAbsOrigin()):Normalized() * 2500)

	Timers:CreateTimer(delay, function()  
        local full_damage_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, small_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        local half_damage_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, large_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

        for i = 1, #full_damage_targets do
            DoDamage(caster, full_damage_targets[i], full_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            full_damage_targets[i]:AddNewModifier(caster, self, "modifier_maou_combo_hit", { Duration = 0.1 })
        end 

        for i = 1, #half_damage_targets do
        	if not half_damage_targets[i]:HasModifier("modifier_maou_combo_hit") then
            	DoDamage(caster, half_damage_targets[i], half_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
        end 



        local particle = ParticleManager:CreateParticle("particles/custom/karna/brahmastra_kundala/brahmastra_kundala_explosion_beam.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, target_point) 
		ParticleManager:SetParticleShouldCheckFoW(particle, false)
		if modifier_counter == 1 then
			EmitGlobalSound("kostya_last_blast")
		else
			EmitGlobalSound("kostya_generic_blast")
		end

		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			ParticleManager:DestroyParticle(throw_particle, false)
			ParticleManager:ReleaseParticleIndex(throw_particle)
	

			return
		end)

        return 
    end)
end

modifier_maou_combo_hit = class({})

function modifier_maou_combo_hit:IsHidden()
	return true 
end

function modifier_maou_combo_hit:RemoveOnDeath()
	return true
end
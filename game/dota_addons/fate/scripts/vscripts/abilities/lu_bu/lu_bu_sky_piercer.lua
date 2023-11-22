-----------------------------
--    Sky Piercer     --
-----------------------------
lu_bu_sky_piercer = class({})

LinkLuaModifier( "modifier_lu_bu_sky_piercer", "abilities/lu_bu/lu_bu_sky_piercer", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_lu_bu_sky_piercer_anim_lock", "abilities/lu_bu/modifiers/modifier_lu_bu_sky_piercer_anim_lock", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_lu_bu_sky_piercer_cooldown", "abilities/lu_bu/modifiers/modifier_lu_bu_sky_piercer_cooldown", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function lu_bu_sky_piercer:IsHiddenWhenStolen()
	return false
end

function lu_bu_sky_piercer:IsNetherWardStealable()
	return false
end

function lu_bu_sky_piercer:OnSpellStart()
    if not IsServer() then return end
    
	-- Ability properties
	local caster = self:GetCaster()
	local caster_position = caster:GetAbsOrigin()
	local playerID = caster:GetPlayerID()
	local scepter = caster:HasScepter()
	
	local enemy = PickRandomEnemy(caster)
	
	if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 4.5 })
    end

	-- Ability specials
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local slow_duration = self:GetSpecialValueFor("slow_duration")
	local stun = 1
	local effect_delay = self:GetSpecialValueFor("crack_time") - 0.4
	local crack_width = self:GetSpecialValueFor("crack_width")
	local crack_distance = self:GetSpecialValueFor("crack_distance")
	local crack_damage = self:GetSpecialValueFor("damage")
	
	if caster:HasModifier("modifier_lu_bu_ruthless_warrior_attribute") then
		crack_damage = crack_damage + 400
		crack_distance = crack_distance + 2000
		effect_delay = effect_delay + 1
	end
	
	local caster_fw_center = caster:GetForwardVector()
	local caster_fw_left = caster:GetForwardVector() - caster:GetRightVector()/7
	local caster_fw_right = caster:GetForwardVector() + caster:GetRightVector()/7
	local caster_fw_left_ext = caster:GetForwardVector() - caster:GetRightVector()/4
	local caster_fw_right_ext = caster:GetForwardVector() + caster:GetRightVector()/4
	
	local crack_ending_center = caster_position + caster_fw_center * crack_distance
	local crack_ending_left = caster_position + caster_fw_left * crack_distance
	local crack_ending_right = caster_position + caster_fw_right * crack_distance
	local crack_ending_left_ext = caster_position + caster_fw_left_ext * crack_distance
	local crack_ending_right_ext = caster_position + caster_fw_right_ext * crack_distance
	
	ScreenShake(caster:GetOrigin(), 15, 4, 8, 40000, 0, true)

	-- Play cast sound
	EmitGlobalSound("lu_bu_sky_piercer_cast")
	EmitGlobalSound("lu_bu_sky_piercer")
	
	StartAnimation(caster, {duration=1.5, activity=ACT_DOTA_RAZE_1, rate=0.75})
	
	caster:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer_anim_lock", { Duration = 2.0 })
	
	caster:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer_cooldown", { Duration = self:GetCooldown(1) })
	local masterCombo = caster.MasterUnit2:FindAbilityByName("lu_bu_sky_piercer")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(120)

	-- Add start particle effect
	Timers:CreateTimer(0.4, function()
		local particle_start_fx_center = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_sky_piercer_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
		local particle_start_fx_left = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_sky_piercer_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
		local particle_start_fx_right = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_sky_piercer_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
		local particle_start_fx_left_ext = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_sky_piercer_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
		local particle_start_fx_right_ext = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_sky_piercer_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
		
		ParticleManager:SetParticleControl(particle_start_fx_center, 0, caster_position)
		ParticleManager:SetParticleControl(particle_start_fx_center, 1, crack_ending_center)
		ParticleManager:SetParticleControl(particle_start_fx_center, 3, Vector(0, effect_delay, 0))
		
		ParticleManager:SetParticleControl(particle_start_fx_left, 0, caster_position)
		ParticleManager:SetParticleControl(particle_start_fx_left, 1, crack_ending_left)
		ParticleManager:SetParticleControl(particle_start_fx_left, 3, Vector(0, effect_delay, 0))
		
		ParticleManager:SetParticleControl(particle_start_fx_right, 0, caster_position)
		ParticleManager:SetParticleControl(particle_start_fx_right, 1, crack_ending_right)
		ParticleManager:SetParticleControl(particle_start_fx_right, 3, Vector(0, effect_delay, 0))
		
		ParticleManager:SetParticleControl(particle_start_fx_left_ext, 0, caster_position)
		ParticleManager:SetParticleControl(particle_start_fx_left_ext, 1, crack_ending_left_ext)
		ParticleManager:SetParticleControl(particle_start_fx_left_ext, 3, Vector(0, effect_delay, 0))
		
		ParticleManager:SetParticleControl(particle_start_fx_right_ext, 0, caster_position)
		ParticleManager:SetParticleControl(particle_start_fx_right_ext, 1, crack_ending_right_ext)
		ParticleManager:SetParticleControl(particle_start_fx_right_ext, 3, Vector(0, effect_delay, 0))
	end)
	

	-- Destroy trees in the radius
	GridNav:DestroyTreesAroundPoint(caster_position, radius, false)

	-- Wait for the effect delay
	Timers:CreateTimer(effect_delay+0.4, function()
		EmitGlobalSound("lu_bu_sky_piercer_explode_1")
		EmitGlobalSound("lu_bu_sky_piercer_explode_2")
		EmitGlobalSound("lu_bu_sky_piercer_explode_3")

		local enemies_center = FindUnitsInLine(caster:GetTeamNumber(), caster_position, crack_ending_center, nil, crack_width, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
		local enemies_left = FindUnitsInLine(caster:GetTeamNumber(), caster_position, crack_ending_left, nil, crack_width, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
		local enemies_right = FindUnitsInLine(caster:GetTeamNumber(), caster_position, crack_ending_right, nil, crack_width, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
		local enemies_left_ext = FindUnitsInLine(caster:GetTeamNumber(), caster_position, crack_ending_left_ext, nil, crack_width, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
		local enemies_right_ext = FindUnitsInLine(caster:GetTeamNumber(), caster_position, crack_ending_right_ext, nil, crack_width, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
		
		for _, enemy in pairs(enemies_center) do
			enemy:Interrupt()
			enemy:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer", {duration = slow_duration * (1 - enemy:GetStatusResistance())})
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun * (1 - enemy:GetStatusResistance())})
			DoDamage(caster, enemy, crack_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		
		for _, enemy in pairs(enemies_left) do
			enemy:Interrupt()
			enemy:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer", {duration = slow_duration * (1 - enemy:GetStatusResistance())})
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun * (1 - enemy:GetStatusResistance())})
			DoDamage(caster, enemy, crack_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		
		for _, enemy in pairs(enemies_right) do
			enemy:Interrupt()
			enemy:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer", {duration = slow_duration * (1 - enemy:GetStatusResistance())})
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun * (1 - enemy:GetStatusResistance())})
			DoDamage(caster, enemy, crack_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		
		for _, enemy in pairs(enemies_left_ext) do
			enemy:Interrupt()
			enemy:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer", {duration = slow_duration * (1 - enemy:GetStatusResistance())})
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun * (1 - enemy:GetStatusResistance())})
			DoDamage(caster, enemy, crack_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		
		for _, enemy in pairs(enemies_right_ext) do
			enemy:Interrupt()
			enemy:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer", {duration = slow_duration * (1 - enemy:GetStatusResistance())})
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun * (1 - enemy:GetStatusResistance())})
			DoDamage(caster, enemy, crack_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		
		ScreenShake(crack_ending_center, 10, 10.0, 2, 5000, 0, true)
		ScreenShake(crack_ending_left, 10, 10.0, 2, 5000, 0, true)
		ScreenShake(crack_ending_right, 10, 10.0, 2, 5000, 0, true)

		ParticleManager:ReleaseParticleIndex(particle_start_fx_center)
		ParticleManager:ReleaseParticleIndex(particle_start_fx_left)
		ParticleManager:ReleaseParticleIndex(particle_start_fx_right)
		ParticleManager:ReleaseParticleIndex(particle_start_fx_left_ext)
		ParticleManager:ReleaseParticleIndex(particle_start_fx_right_ext)
		
		ParticleManager:DestroyParticle( particle_start_fx_center, false )
		ParticleManager:DestroyParticle( particle_start_fx_left, false )
		ParticleManager:DestroyParticle( particle_start_fx_right, false )
		ParticleManager:DestroyParticle( particle_start_fx_left_ext, false )
		ParticleManager:DestroyParticle( particle_start_fx_right_ext, false )
	end)
end

-- Slow Modifier
modifier_lu_bu_sky_piercer = class({})

function modifier_lu_bu_sky_piercer:IsHidden() return false end
function modifier_lu_bu_sky_piercer:IsPurgable() return true end

function modifier_lu_bu_sky_piercer:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return decFuncs
end

function modifier_lu_bu_sky_piercer:CheckState()
	local state = {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_MUTED] = true
	}
	return state
end

function modifier_lu_bu_sky_piercer:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_pct")
end
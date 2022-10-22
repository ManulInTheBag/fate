diarmuid_gae_dearg =  class({})

LinkLuaModifier("modifier_gae_dearg", "abilities/diarmuid/modifiers/modifier_gae_dearg", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doublespear_dearg", "abilities/diarmuid/modifiers/modifier_doublespear_dearg", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doublespear_attribute", "abilities/diarmuid/modifiers/modifier_doublespear_attribute", LUA_MODIFIER_MOTION_NONE)

function diarmuid_gae_dearg:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return self:GetSpecialValueFor("combo_cooldown")
	else
		return self:GetSpecialValueFor("cooldown")
	end
end

function diarmuid_gae_dearg:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return 250
	elseif caster:HasModifier("modifier_doublespear_attribute") then
		return 400
	else
		return 500
	end
end

function diarmuid_gae_dearg:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end	
end

function diarmuid_gae_dearg:GetCustomCastErrorTarget(hTarget)
	return "#Invalid_Target"
end

function diarmuid_gae_dearg:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	--caster:EmitSound("ZL.Dearg_Cast")

	self.SoundQueue = math.random(1,3)
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diarmuid_gaedearg_alt_" .. self.SoundQueue .. "_1"})
				end
	        	
	    
   		end)
		   caster:EmitSound("Diarmuid_GaeDearg_Alt" .. self.SoundQueue .. "_1")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()) 
	ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin()) 
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)

	return true
end

function diarmuid_gae_dearg:GetCastPoint()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return 0.4
	else
		return 0.7
	end
end

function diarmuid_gae_dearg:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self	
	local target = self:GetCursorTarget()	

	if IsSpellBlocked(target) then return end -- Linken effect checker

	ApplyDeargDispel(target)

	caster:RemoveModifierByName("modifier_doublespear_dearg")

	local damage = 0
	local maxDamageDist = self:GetSpecialValueFor("max_damage_dist")
	local minDamageDist = self:GetSpecialValueFor("min_damage_dist")
	local min_damage = self:GetSpecialValueFor("min_damage")
	local max_damage = self:GetSpecialValueFor("max_damage")
	
	local distDiff =  minDamageDist - maxDamageDist
	local damageDiff = max_damage - min_damage
	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() 

	if distance <= maxDamageDist then 
		damage = max_damage
	elseif maxDamageDist < distance and distance < minDamageDist then
		damage = min_damage + damageDiff * (minDamageDist - distance) / distDiff
	elseif minDamageDist <= distance then
		damage = min_damage
	end

	local original_pos = caster:GetAbsOrigin()

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100)
	FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )

	if caster.IsCrimsonRoseAcquired and target:IsHero() then
		giveUnitDataDrivenModifier(caster, target, "revoked", 2)
		if not IsManaLess(target) then
			target:SetMana(target:GetMana() - 500)
			target:AddNewModifier(caster, ability, "modifier_gae_dearg", { Duration = self:GetSpecialValueFor("duration") })
		end
	end

	DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, ability, false)	

	--EmitGlobalSound("ZL.Gae_Dearg")
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diarmuid_gaedearg_alt_" .. self.SoundQueue .. "_2"})
	        end
	        
	      
   		end)
		   caster:EmitSound("Diarmuid_GaeDearg_Alt" .. self.SoundQueue .. "_2")

	target:EmitSound("Hero_Lion.Impale")
	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=2})
	self:PlayGaeEffect(target)

	-- Add dagon particle
	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	local particle_effect_intensity = 600
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( dagon_particle, false )
		ParticleManager:ReleaseParticleIndex( dagon_particle )
	end)

	local flashIndex = ParticleManager:CreateParticle( "particles/custom/diarmuid/gae_dearg_slash.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControl( flashIndex, 2, original_pos )
    ParticleManager:SetParticleControl( flashIndex, 3, caster:GetAbsOrigin() )

    --ParticleManager:SetParticleControlEnt(flashIndex, 3, caster, PATTACH_CUSTOMORIGIN, "attach_attack2", caster:GetAbsOrigin(), true)

	if (caster:HasModifier("modifier_doublespear_attribute") or caster:HasModifier("modifier_double_spearmanship_active")) 
		and not caster:HasModifier("modifier_rampant_warrior") then
		local buidhe = caster:FindAbilityByName("diarmuid_gae_buidhe")

		buidhe:DoubleSpearRefresh()
	end
end

function diarmuid_gae_dearg:DoubleSpearRefresh()
	local current_cooldown = self:GetCooldownTimeRemaining()
	local caster = self:GetCaster()
	local window = self:GetSpecialValueFor("doublespear_window")

	self:EndCooldown()

	if caster:HasModifier("modifier_doublespear_attribute") then
		window = window + self:GetSpecialValueFor("attribute_window")
	end

	caster:AddNewModifier(caster, self, "modifier_doublespear_dearg", { Duration = window,
																		RemainingCooldown = current_cooldown - window})
end

function diarmuid_gae_dearg:StartRemainingCooldown(flCooldown)
	if flCooldown > 0 then
		self:StartCooldown(flCooldown)
	end
end

function diarmuid_gae_dearg:PlayGaeEffect(target)
	--[[local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/diarmuid/diarmuid_cull.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
		ParticleManager:ReleaseParticleIndex( culling_kill_particle )
	end)]]
end
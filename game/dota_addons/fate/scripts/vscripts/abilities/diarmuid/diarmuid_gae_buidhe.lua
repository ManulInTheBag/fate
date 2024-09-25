diarmuid_gae_buidhe =  class({})

LinkLuaModifier("modifier_gae_buidhe", "abilities/diarmuid/modifiers/modifier_gae_buidhe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doublespear_buidhe", "abilities/diarmuid/modifiers/modifier_doublespear_buidhe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doublespear_attribute", "abilities/diarmuid/modifiers/modifier_doublespear_attribute", LUA_MODIFIER_MOTION_NONE)

function diarmuid_gae_buidhe:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return self:GetSpecialValueFor("combo_cooldown")
	else
		return self:GetSpecialValueFor("cooldown")
	end
end

function diarmuid_gae_buidhe:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return 200
	elseif caster:HasModifier("modifier_doublespear_attribute") then
		return 400
	else
		return 500
	end
end

function diarmuid_gae_buidhe:CastFilterResultTarget(hTarget)
	if IsClient() then return self.BaseClass.CastFilterResultTarget(self, hTarget) end
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE

	if caster.IsGoldenRoseAcquired then--caster:HasModifier("modifier_golden_rose_attribute") then
		target_flag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end

	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, target_flag, caster:GetTeamNumber())

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

function diarmuid_gae_buidhe:GetCustomCastErrorTarget(hTarget)
	return "#Invalid_Target"
end

function diarmuid_gae_buidhe:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	--caster:EmitSound("ZL.Buidhe_Cast")

	self.SoundQueue = math.random(1,2)
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Diarmuid_GaeBuidhe_Alt_" .. self.SoundQueue .. "_1"})
	            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
			end
	        	
	         
   		end)
	 
	caster:EmitSound("Diarmuid_GaeBuidhe_Alt" .. self.SoundQueue .. "_1")
	local particle = ParticleManager:CreateParticle("particles/custom/diarmuid/diarmuid_gae_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()) 
	ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin()) 
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)

	return true
end

function diarmuid_gae_buidhe:GetCastPoint()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return 0.3
	elseif caster:HasModifier("modifier_golden_rose_attribute") then
		return 0.4
	else
		return 0.6
	end
end

function diarmuid_gae_buidhe:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self	
	local target = self:GetCursorTarget()	

	caster:RemoveModifierByName("modifier_doublespear_buidhe")

	if IsSpellBlocked(target) then return end

	if (caster:HasModifier("modifier_doublespear_attribute") or caster:HasModifier("modifier_double_spearmanship_active")) 
		and not caster:HasModifier("modifier_rampant_warrior") then
		local dearg = caster:FindAbilityByName("diarmuid_gae_dearg")

		dearg:DoubleSpearRefresh()
	end 

	if target:IsMagicImmune() then return end

	local unitReduction = 10
	local currentStack = target:GetModifierStackCount("modifier_gae_buidhe", ability)
	local damage = self:GetSpecialValueFor("damage")
	local golden_rose_damage = 0
	local healthDiff = target:GetHealth()

	if caster.IsGoldenRoseAcquired then--caster:HasModifier("modifier_golden_rose_attribute") then
		golden_rose_damage = currentStack / 100 * damage
		DoDamage(caster, target, golden_rose_damage, DAMAGE_TYPE_PURE, 0, ability, false)
	end

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)

	healthDiff = healthDiff - target:GetHealth()
	nStacks = math.ceil(healthDiff/10)--(damage*2 / 30)

	if target:GetHealth() > 0 and target:IsAlive() and caster:IsAlive() and nStacks > 1 then
		--target:RemoveModifierByName("modifier_gae_buidhe") 
		target:AddNewModifier(caster, self, "modifier_gae_buidhe", { Stacks = currentStack + nStacks, Duration = 70})
		if target:IsRealHero() then target:CalculateStatBonus(true) end
	--Whoops
	--else
	--	target:Execute(self, caster, { bExecution = true })
	end
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Diarmuid_GaeBuidhe_Alt_" .. self.SoundQueue .. "_2"})
			end
	        	
	       
   		end)
		   caster:EmitSound("Diarmuid_GaeBuidhe_Alt" .. self.SoundQueue .. "_2")
	target:EmitSound("Hero_Lion.Impale")
	
	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=2})

	self:PlayGaeEffect(target)

	local dagon_particle = ParticleManager:CreateParticle("particles/custom/diarmuid/diarmuid_gae_buidhe.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	local particle_effect_intensity = 600
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( dagon_particle, false )
		ParticleManager:ReleaseParticleIndex( dagon_particle )
	end)
end

function diarmuid_gae_buidhe:DoubleSpearRefresh()
	local current_cooldown = self:GetCooldownTimeRemaining()
	local caster = self:GetCaster()
	local window = self:GetSpecialValueFor("doublespear_window")

	self:EndCooldown()

	if caster:HasModifier("modifier_doublespear_attribute") then
		window = window + self:GetSpecialValueFor("attribute_window")
	end

	caster:AddNewModifier(caster, self, "modifier_doublespear_buidhe", { Duration = window,
																		 RemainingCooldown = current_cooldown - window})
end

function diarmuid_gae_buidhe:StartRemainingCooldown(flCooldown)
	if flCooldown > 0 then
		self:StartCooldown(flCooldown)
	end
end

function diarmuid_gae_buidhe:PlayGaeEffect(target)
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

function diarmuid_gae_buidhe:OnOwnerDied()
	LoopOverHeroes(function(hero)
    	hero:RemoveModifierByName("modifier_gae_buidhe")
    end)
end
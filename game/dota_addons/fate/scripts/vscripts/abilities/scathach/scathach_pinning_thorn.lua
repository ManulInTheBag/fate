scathach_pinning_thorn = class({})

LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pinning_god_self_stun", "abilities/scathach/modifiers/modifier_scathach_pinning_god_self_stun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg", LUA_MODIFIER_MOTION_NONE)
function scathach_pinning_thorn:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
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

function scathach_pinning_thorn:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"
	end
end

function scathach_pinning_thorn:OnSpellStart()
	local hCaster = self:GetCaster()
	local caster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	hCaster:EmitSound("Scathach.Pinning_God")
	hTarget:EmitSound("Scathach.Pinning_God")
	
	caster:AddNewModifier(caster, self, "modifier_scathach_pinning_god_self_stun", { Duration = 1.3 })
	
	local caster_name =  PlayerResource:GetPlayerName(caster:GetPlayerID())
	local target_name =  PlayerResource:GetPlayerName(hTarget:GetPlayerID())

    local enemy = PickRandomEnemy(hCaster)
	if enemy then
        hCaster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 6 })
    end
	
	GameRules:SendCustomMessage("<font color='#0083E3'>".. caster_name .." :</font> Prepare to die <font color='#FF0000'>".. target_name .."</font>, your heart is mine!", 0, 0)

	self.ForwardVector = hCaster:GetForwardVector()
	
	StartAnimation(caster, {duration=2.25, activity=ACT_DOTA_CAST_ABILITY_7, rate=1.0})

	Timers:CreateTimer(1.0, function() 
			self.target = hTarget 
			local scathach_Projectile = {
		        Target = hTarget,
		        Source = hCaster,
		        Ability = self,
		        EffectName = "particles/custom/scathach/gae_bolg.vpcf",
		        iMoveSpeed = 3000,
		        vSourceLoc = hCaster:GetAbsOrigin(),
		        bDodgeable = false,
		        flExpireTime = GameRules:GetGameTime() + 10,
		        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_3
		    }

		    ProjectileManager:CreateTrackingProjectile(scathach_Projectile)
	end)   
end

function scathach_pinning_thorn:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
	
	if IsSpellBlocked(hTarget) or hTarget:IsMagicImmune() or hTarget:IsInvulnerable() then return end

	local hCaster = self:GetCaster()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage") + (caster:GetAgility() * self:GetSpecialValueFor("agi_ratio"))/2 + self:GetSpecialValueFor("damage_per_hero_level")/2 * hCaster:GetLevel()
	local damage_secondary = self:GetSpecialValueFor("damage_secondary") + (caster:GetAgility() * self:GetSpecialValueFor("agi_ratio"))/2 + self:GetSpecialValueFor("damage_per_hero_level")/2 * hCaster:GetLevel()
	local radius = self:GetSpecialValueFor("radius")
	local heartbreak = self:GetSpecialValueFor("heartbreak")	
	
	hTarget:EmitSound("scathach_gae_bolg_explosion")

	local blastFx = ParticleManager:CreateParticle("particles/cu_chulain/gae_bolg_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( blastFx, 0, hTarget:GetAbsOrigin())
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( blastFx, false )
		ParticleManager:ReleaseParticleIndex( blastFx )
	end)

	--hTarget:RemoveModifierByName("modifier_heart_of_harmony")
	--hTarget:RemoveModifierByName("modifier_share_damage")
	--hTarget:RemoveModifierByName("modifier_master_intervention")

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
	hTarget:AddNewModifier(hCaster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
--	ScreenShake(hTarget:GetOrigin(), 15, 0.5, 2, 20000, 0, true)
	
	local targets = FindUnitsInRadius(caster:GetTeam(), hTarget:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
	for k,blast_radius_target in pairs(targets) do
		if blast_radius_target:IsMagicImmune() then
			return
		end
			
		DoDamage(caster, blast_radius_target, damage_secondary, DAMAGE_TYPE_MAGICAL, 0, self, false)
			
	end

	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
end
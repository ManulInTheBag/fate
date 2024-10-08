-----------------------------
--    Yew Bow    --
-----------------------------

robin_yew_tree_combo = class({})

LinkLuaModifier( "modifier_robin_yew_bow", "abilities/robin/modifiers/modifier_robin_yew_bow", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_yew_bow_silence", "abilities/robin/modifiers/modifier_robin_yew_bow_silence", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_combo_voice_checker", "abilities/robin/modifiers/modifier_robin_combo_voice_checker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_combo_cooldown", "abilities/robin/modifiers/modifier_robin_combo_cooldown", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_yew_bow_combo_thinker", "abilities/robin/modifiers/modifier_robin_yew_bow_combo_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_yew_bow_combo_lock", "abilities/robin/modifiers/modifier_robin_yew_bow_combo_lock", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_combo_self_stun", "abilities/robin/modifiers/modifier_robin_combo_self_stun", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function robin_yew_tree_combo:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- local point = self:GetCursorPosition()
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end
	
	local enemy = PickRandomEnemy(caster)
	
	EmitGlobalSound("robin_yew_bow_combo")
	
	caster:AddNewModifier(caster, self, "modifier_robin_combo_voice_checker", {duration = 4.0})
	caster:AddNewModifier(caster, self, "modifier_robin_combo_self_stun", { Duration = 3.41 })
	caster:AddNewModifier(caster, self, "modifier_robin_combo_cooldown", { Duration = self:GetCooldown(1) })
	local ultimate = caster:FindAbilityByName("robin_yew_bow")
	ultimate:StartCooldown(ultimate:GetCooldown(ultimate:GetLevel()))
	local masterCombo = caster.MasterUnit2:FindAbilityByName("robin_combo_list")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))
	
	StartAnimation(caster, {duration=3.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.75})
	
    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 0.5 })
    end

	-- load data
	local projectile_name = "particles/custom/robin/robin_yew_bow.vpcf"
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")

	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_3,
		bDodgeable = false,                           -- Optional
		ExtraData = { modifier = self.modifier }
	}
	
	Timers:CreateTimer(3.40, function()
		if caster:IsAlive() then
			ProjectileManager:CreateTrackingProjectile(info)
			EmitGlobalSound("robin_yew_bow_launch")
			local sound_target = "Hero_Sniper.AssassinateProjectile"
			EmitSoundOn( sound_cast, target )
		end
	end)
	
	local caster_name =  PlayerResource:GetPlayerName(caster:GetPlayerID())
	local target_name =  PlayerResource:GetPlayerName(target:GetPlayerID())
	
	GameRules:SendCustomMessage("<font color='#0083E3'>".. caster_name .." :</font> This arrow from my grave... A blessing of the forest... Which becomes a poison to tyrannical regimes... Prepare to die <font color='#FF0000'>".. target_name .."</font>!", 0, 0)
end
--------------------------------------------------------------------------------
-- Projectile
function robin_yew_tree_combo:OnProjectileHit_ExtraData( target, location, extradata )
	
	local caster = self:GetCaster()
	local target_point = target:GetAbsOrigin()
	
	target:AddNewModifier(caster, self, "modifier_robin_yew_bow_combo_lock", { Duration = 2 })
	
	-- Create Particle
	local TreeFx = ParticleManager:CreateParticle("particles/custom/robin/robin_yew_bow_combo_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( TreeFx, 0, target:GetAbsOrigin())
	
	ParticleManager:ReleaseParticleIndex( TreeFx )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( TreeFx, false )
	end)
	
	CreateModifierThinker(target, self, "modifier_robin_yew_bow_combo_thinker", { Duration = 6,
																			 poison_damage = self:GetSpecialValueFor("poison_damage"),
																			 radius = self:GetSpecialValueFor("radius"),
																			 poison_center = target_point}
																			, target_point, caster:GetTeamNumber(), false)

	
	-- cancel if gone
	if (not target) or target:IsInvulnerable() or target:IsOutOfGame() or target:TriggerSpellAbsorb( self ) then
		return
	end
	
	local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
	target:EmitSound("robin_yew_bow_impact")

	-- apply damage
	local damage = self:GetSpecialValueFor("damage")
	local damage_stack = self:GetSpecialValueFor("damage_stack")
	local silence_duration = self:GetSpecialValueFor("silence_duration")
	local poison_detonation_radius = self:GetSpecialValueFor("poison_detonation_radius")
	
	if caster:HasModifier("modifier_robin_of_sherwood_attribute") then
		target:AddNewModifier(
			self:GetCaster(), -- player source
			self, -- ability source
			"modifier_robin_yew_bow_silence", -- modifier name
			{ duration = silence_duration } -- kv
		)
		if target:GetMaxMana() > 0 then
			target:Script_ReduceMana(600, nil)
		end
	end
	
	local yew_bow_ability = caster:FindAbilityByName("robin_yew_bow")
	
	if not target:HasModifier("modifier_robin_poison_stack") then
		target:AddNewModifier(caster, yew_bow_ability, "modifier_robin_poison_stack", { Duration = 7 })
		local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
		poison_stack_ability:SetStackCount(1)
	else
		target:AddNewModifier(caster, yew_bow_ability, "modifier_robin_poison_stack", { Duration = 7 })
	end
	
	local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
	local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
	poison_stack_ability:SetStackCount(poison_stack + 20)
	
	local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
	local real_damage = damage + (damage_stack * poison_stack)
	
	if caster:HasModifier("modifier_robin_yew_bow_attribute") then
		real_damage = real_damage + 250
	end
	
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = real_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)

	-- stun
	target:Interrupt()
	
	if target:HasModifier("modifier_robin_poison_stack") then
		target:RemoveModifierByName("modifier_robin_poison_stack")
		self:PlayEffects( target )
	end
	
	local poison_targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, poison_detonation_radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
		for k,poison_detonation_target in pairs(poison_targets) do
			if poison_detonation_target:IsMagicImmune() then
				return
			end
			
			if poison_detonation_target:HasModifier("modifier_robin_poison_stack") then
			
				local detonation_poison_stack = poison_detonation_target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				local detonation_damage = detonation_poison_stack  * damage_stack
				
				DoDamage(caster, poison_detonation_target, detonation_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				
				poison_detonation_target:RemoveModifierByName("modifier_robin_poison_stack")
				self:PlayEffects( poison_detonation_target )
			end
		end

	-- effects
	local sound_cast = "Hero_Sniper.AssassinateDamage"
	EmitSoundOn( sound_cast, target )
end

------------------------------------------------------------------------------
function robin_yew_tree_combo:PlayEffects( target )
	-- Get Resources
	local particle_cast = "particles/custom/robin/robin_yew_bow_impact.vpcf"
	
	target:EmitSound("robin_yew_bow_poison")

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
end
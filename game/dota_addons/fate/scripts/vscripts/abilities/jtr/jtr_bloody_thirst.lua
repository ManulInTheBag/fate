--1.884 mid cycle, 1.75 until mid

LinkLuaModifier("modifier_jtr_bloody_thirst_passive", "abilities/jtr/jtr_bloody_thirst", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jtr_bloody_thirst_active", "abilities/jtr/jtr_bloody_thirst", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jtr_bloody_thirst_vision", "abilities/jtr/jtr_bloody_thirst", LUA_MODIFIER_MOTION_NONE)

jtr_bloody_thirst = class({})

function jtr_bloody_thirst:GetIntrinsicModifierName()
	return "modifier_jtr_bloody_thirst_passive"
end

function jtr_bloody_thirst:GetBehavior()
	return self:GetSpecialValueFor("behavior") + 64 + 2048--64 for not learnable, 2 passive, 4 no target, 2048 immediate
end

function jtr_bloody_thirst:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_jtr_bloody_thirst_active", {duration = self:GetSpecialValueFor("active_duration")})
end

--

modifier_jtr_bloody_thirst_passive = class({})

function modifier_jtr_bloody_thirst_passive:IsHidden() 
	return true
end

function modifier_jtr_bloody_thirst_passive:IsPermanent()
	return true
end

function modifier_jtr_bloody_thirst_passive:RemoveOnDeath()
	return false
end

function modifier_jtr_bloody_thirst_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_jtr_bloody_thirst_passive:DeclareFunctions()
	return {	MODIFIER_EVENT_ON_HERO_KILLED	}
end

function modifier_jtr_bloody_thirst_passive:OnHeroKilled(args)
	if args.target:IsHero() and args.attacker == self:GetParent() then
		if not self.pepega then
			self.pepega = 1
			self.parent = self:GetParent()
			self.player_id = self.parent:GetPlayerOwnerID()
			self.player = PlayerResource:GetPlayer(self.player_id)
			self.ability = self:GetAbility()
			self:StartIntervalThink(FrameTime())
		end
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_jtr_bloody_thirst_active", {duration = self.ability:GetSpecialValueFor("passive_duration")})
	end
end

function modifier_jtr_bloody_thirst_passive:OnIntervalThink()
	if not self:GetParent():IsAlive() then return end

	local wounded_radius = self.ability:GetSpecialValueFor("wounded_radius")

	if self:GetParent():HasModifier("modifier_whitechapel_murderer") then
		wounded_radius = wounded_radius*2
	end

	local health_threshold = self.ability:GetSpecialValueFor("health_threshold")
	local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
	                                        self.parent:GetAbsOrigin(),
	                                        nil,
	                                        wounded_radius,
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                        DOTA_UNIT_TARGET_HERO,
	                                        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	                                        FIND_ANY_ORDER,
	                                        false)

	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() and IsValidEntity(enemy) and (enemy:GetHealth()/enemy:GetMaxHealth()*100) < health_threshold then
			--enemy:AddNewModifier(self.parent, self.ability, "modifier_jtr_bloody_thirst_marker", {duration = 0.2})
			local hParticle = ParticleManager:CreateParticleForPlayer("particles/jtr/jtr_red_mark.vpcf",  PATTACH_WORLDORIGIN, nil, self.player)
			ParticleManager:SetParticleControl(hParticle, 0, enemy:GetAbsOrigin() + Vector(0, 0, 150))
			ParticleManager:SetParticleShouldCheckFoW(hParticle, false)
			Timers:CreateTimer(FrameTime(), function()
				ParticleManager:DestroyParticle(hParticle, false)
				ParticleManager:ReleaseParticleIndex(hParticle)
			end)
		end
	end

	local radius = self:GetParent():FindAbilityByName("jtr_murderer_mist"):GetSpecialValueFor("blood_rage_vision")

	if self:GetParent():HasModifier("modifier_whitechapel_murderer") then
		radius = radius*2
	end

	local enemies2 = FindUnitsInRadius(  self.parent:GetTeamNumber(),
	                                        self.parent:GetAbsOrigin(),
	                                        nil,
	                                        radius,
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                        DOTA_UNIT_TARGET_HERO,
	                                        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	                                        FIND_ANY_ORDER,
	                                        false)

	for _, enemy2 in pairs(enemies2) do
		if enemy2 and not enemy2:IsNull() and IsValidEntity(enemy2) and IsFemaleServant(enemy2) then
			--enemy:AddNewModifier(self.parent, self.ability, "modifier_jtr_bloody_thirst_marker", {duration = 0.2})
			local hParticle2 = ParticleManager:CreateParticleForPlayer("particles/jtr/jtr_blue_mark.vpcf",  PATTACH_WORLDORIGIN, nil, self.player)
			ParticleManager:SetParticleControl(hParticle2, 0, enemy2:GetAbsOrigin() + Vector(0, 0, 150))
			ParticleManager:SetParticleShouldCheckFoW(hParticle2, false)
			Timers:CreateTimer(FrameTime(), function()
				ParticleManager:DestroyParticle(hParticle2, false)
				ParticleManager:ReleaseParticleIndex(hParticle2)
			end)
		end
	end
end

--

modifier_jtr_bloody_thirst_active = class({})

function modifier_jtr_bloody_thirst_active:IsHidden() 
	return false
end

function modifier_jtr_bloody_thirst_active:RemoveOnDeath()
	return true
end

function modifier_jtr_bloody_thirst_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			--MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
			  }
end

function modifier_jtr_bloody_thirst_active:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true, }
    
    return state
end

--[[function modifier_jtr_bloody_thirst_active:GetModifierIgnoreMovespeedLimit()
    return 1
end]]

function modifier_jtr_bloody_thirst_active:GetModifierBonusStats_Agility()
	return self:GetParent():FindAbilityByName("modifier_jtr_surgery"):GetSpecialValueFor("blood_rage_agility")
end

function modifier_jtr_bloody_thirst_active:GetModifierMoveSpeedBonus_Percentage()
	return self:GetParent():FindAbilityByName("jtr_dagger_throw"):GetSpecialValueFor("blood_rage_ms")
end

--[[function modifier_jtr_bloody_thirst_active:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_jtr_bloody_thirst_active:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_jtr_bloody_thirst_active:GetAuraRadius()
	return self:GetParent():FindAbilityByName("jtr_surgery"):GetSpecialValueFor("blood_rage_vision")
end

function modifier_jtr_bloody_thirst_active:GetModifierAura()
	return "modifier_jtr_bloody_thirst_vision"
end

function modifier_jtr_bloody_thirst_active:IsHidden()
	return false 
end

function modifier_jtr_bloody_thirst_active:RemoveOnDeath()
	return true
end

function modifier_jtr_bloody_thirst_active:IsDebuff()
	return false 
end

function modifier_jtr_bloody_thirst_active:IsAura()
	return true 
end]]

function modifier_jtr_bloody_thirst_active:OnCreated()
	self:StartIntervalThink(FrameTime())
	EmitSoundOn("jtr_bloody_thirst_start", self:GetParent())
	self.timer_particle = 0
	self.timer_sound = 0
	self.timer_cooldown = 0
end

function modifier_jtr_bloody_thirst_active:OnIntervalThink()
	local caster = self:GetCaster()
	self.timer_particle = self.timer_particle + FrameTime()
	self.timer_sound = self.timer_sound + FrameTime()
	self.timer_cooldown = self.timer_cooldown + FrameTime()

	if IsServer() then
		if self.timer_cooldown >= 0.5 then
			self.timer_cooldown = 0
			local ability = caster:FindAbilityByName("jtr_mtr_new")
			local cooldown = ability:GetCooldownTimeRemaining()

			if ability:IsCooldownReady() then
				return
			else
				ability:EndCooldown()
				ability:StartCooldown(cooldown - 1)
			end
		end
	end

	if self.timer_sound >= 1.7 then
		self.timer_sound = 0
		EmitSoundOn("jtr_bloody_thirst_middle", self:GetParent())
	end

	if self.timer_particle >= 0.15 then
		self.timer_particle = 0
		local particle = ParticleManager:CreateParticle("particles/jtr/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	end
end

function modifier_jtr_bloody_thirst_active:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_jtr_bloody_thirst_active:OnDestroy()
	StopSoundOn("jtr_bloody_thirst_middle", self:GetParent())
	EmitSoundOn("jtr_bloody_thirst_end", self:GetParent())
end

modifier_jtr_bloody_thirst_vision = class({})

function modifier_jtr_bloody_thirst_vision:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

function modifier_jtr_bloody_thirst_vision:GetModifierProvidesFOWVision()
	return self:CanBeDetected(self:GetParent())
end

function modifier_jtr_bloody_thirst_vision:IsHidden()
	return self:CanBeDetected(self:GetParent())
end

function modifier_jtr_bloody_thirst_vision:IsDebuff()
    return true
end

function modifier_jtr_bloody_thirst_vision:RemoveOnDeath()
    return true
end

function modifier_jtr_bloody_thirst_vision:CanBeDetected(hHero)
    for i=1, #tCannotDetect do
        if not IsFemaleServant(hHero) then
            return 0
        end
    end
    
    return 1
end
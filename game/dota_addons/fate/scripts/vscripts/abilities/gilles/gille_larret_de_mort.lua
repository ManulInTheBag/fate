gille_larret_de_mort = class({})

LinkLuaModifier("modifier_larret_de_mort_cooldown", "abilities/gilles/gille_larret_de_mort", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gille_combo", "abilities/gilles/gille_larret_de_mort", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gigantic_horror_freeze", "abilities/gilles/gille_larret_de_mort", LUA_MODIFIER_MOTION_NONE)

local function CreateRavageParticle(handle, center, multiplier)
	for i=1, math.floor(multiplier/60) do
		local x = math.cos(i) * multiplier
		local y = math.sin(i) * multiplier
		local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit.vpcf", PATTACH_CUSTOMORIGIN, handle)
		ParticleManager:SetParticleControl(tentacleFx, 0, Vector(center.x + x, center.y + y, 100))
		ParticleManager:SetParticleControl(tentacleFx, 2, Vector(center.x + x, center.y + y, 100))
	end
end

function gille_larret_de_mort:OnSpellStart()
	local caster = self:GetCaster()
	local tentacle = caster.Squidlord
	local ability = self
	local radius = 1000
	local damage = self:GetSpecialValueFor("initial_damage")
	local knockupDuration = self:GetSpecialValueFor("knockup_duration")
	local bloodDuration = self:GetSpecialValueFor("blood_duration")

	caster:RemoveModifierByName("modifier_gilles_combo_window")
	LoopOverPlayers(function(player, playerID, playerHero)
		if playerHero.gachi == true then
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_combo_0"..math.random(1,2)})
		end
	end)

	if not tentacle or not tentacle:IsAlive() then
		self:EndCooldown()
		return
	end

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName("gille_larret_de_mort")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(150)
	caster:AddNewModifier(caster, ability, "modifier_larret_de_mort_cooldown", {duration = 150})

	-- knockup enemies
	local targets = FindUnitsInRadius(caster:GetTeam(), tentacle:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		ApplyAirborne(caster, v, knockupDuration)
	end

	-- remove integrate status
	if caster.IsIntegrated then
		caster:RemoveModifierByName("modifier_integrate_gille")
		tentacle:RemoveModifierByName("modifier_integrate")
		caster.IsIntegrated = false
		tentacle.AttemptingIntegrate = false
		SendMountStatus(caster)
	end

	tentacle:AddNewModifier(caster, ability, "modifier_gigantic_horror_freeze", {duration = 1.5})
	CreateRavageParticle(tentacle, tentacle:GetAbsOrigin(), 300)
	CreateRavageParticle(tentacle, tentacle:GetAbsOrigin(), 650)
	CreateRavageParticle(tentacle, tentacle:GetAbsOrigin(), 1000)
	EmitGlobalSound("ZC.Ravage")
	EmitGlobalSound("ZC.Laugh")

	local contractFx = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_upheaval.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(contractFx, 0, tentacle:GetAbsOrigin())
	ParticleManager:SetParticleControl(contractFx, 1, Vector(radius + 200,0,0))
	Timers:CreateTimer( 3, function()
		ParticleManager:DestroyParticle( contractFx, false )
		ParticleManager:ReleaseParticleIndex( contractFx )
	end)

	Timers:CreateTimer(1, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), tentacle:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, v:GetMaxHealth() * damage/100, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			v:AddNewModifier(caster, ability, "modifier_gille_combo", {duration = bloodDuration})
			v:EmitSound("hero_bloodseeker.rupture")
		end
		Timers:CreateTimer(0.5, function()
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn_shockwave.vpcf", PATTACH_CUSTOMORIGIN, tentacle)
			ParticleManager:SetParticleControl(particle, 0, tentacle:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(radius+200,0,0))
			ParticleManager:DestroyParticle(contractFx, false)
			ParticleManager:ReleaseParticleIndex(contractFx)
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end)

		tentacle:EmitSound("Hero_ObsidianDestroyer.SanityEclipse.Cast")
		local splashFx = ParticleManager:CreateParticle("particles/custom/screen_scarlet_splash.vpcf", PATTACH_EYES_FOLLOW, tentacle)
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( splashFx, false )
			ParticleManager:ReleaseParticleIndex( splashFx )
		end)
		tentacle:EmitSound("Hero_ShadowDemon.DemonicPurge.Impact")
		tentacle:ForceKill(true)
	end)
end

modifier_larret_de_mort_cooldown = class({})

function modifier_larret_de_mort_cooldown:IsDebuff()
	return true
end

function modifier_larret_de_mort_cooldown:GetTexture()
	return "custom/gille_larret_de_mort"
end

function modifier_larret_de_mort_cooldown:RemoveOnDeath()
	return false
end

function modifier_larret_de_mort_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

-- кровотечение комбо: % от макс. HP в секунду
modifier_gille_combo = class({})

function modifier_gille_combo:IsDebuff()
	return true
end

function modifier_gille_combo:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

function modifier_gille_combo:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_gille_combo:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function modifier_gille_combo:OnIntervalThink()
	local target = self:GetParent()
	local damage = target:GetMaxHealth() * self:GetAbility():GetSpecialValueFor("damage_per_sec")/100
	DoDamage(self:GetCaster(), target, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
end

function modifier_gille_combo:DeclareFunctions()
	return { MODIFIER_EVENT_ON_RESPAWN }
end

-- чтобы после респавна не оставалось ядов Жиля (как RemoveAllPoisons в DD)
function modifier_gille_combo:OnRespawn(keys)
	if not IsServer() then return end
	if keys.unit ~= self:GetParent() then return end
	LoopOverHeroes(function(hero)
		hero:RemoveModifierByName("modifier_contaminate")
		hero:RemoveModifierByName("modifier_gille_combo")
	end)
end

-- сквидлорд замирает в касте перед смертью
modifier_gigantic_horror_freeze = class({})

function modifier_gigantic_horror_freeze:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_gigantic_horror_freeze:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_gigantic_horror_freeze:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_gigantic_horror_freeze:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_gigantic_horror_freeze:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

function modifier_gigantic_horror_freeze:GetOverrideAnimationRate()
	return 0.5
end

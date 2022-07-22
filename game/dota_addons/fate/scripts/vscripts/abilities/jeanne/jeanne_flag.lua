require('jeanne_ability')

LinkLuaModifier("modifier_jeanne_flag_invul", "abilities/jeanne/jeanne_flag", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_le_aura", "abilities/jeanne/jeanne_flag", LUA_MODIFIER_MOTION_NONE)

jeanne_flag = class({})

function jeanne_flag:OnAbilityPhaseStart()
	local caster = self:GetCaster()
    caster:EmitSound("Ruler.Luminosite")
    --caster:EmitSound("Hero_Chen.HandOfGodHealHero")
    return true
end

function jeanne_flag:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    caster:StopSound("Ruler.Luminosite")
    --caster:StopSound("Hero_Chen.HandOfGodHealHero")
end

function jeanne_flag:GetChannelAnimation()
	return ACT_DOTA_IDLE_SLEEPING
end

function jeanne_flag:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Ruler.Eternelle")
	local range = self:GetSpecialValueFor("radius")
	local projectileDestination = caster:GetAbsOrigin()
	caster:AddNewModifier(caster, self, "modifier_jeanne_flag_invul", {})
	EmitSoundOnLocationWithCaster(projectileDestination, "Hero_Omniknight.GuardianAngel.Cast", caster)

	if caster.IsRevelationAcquired then			
		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for i,j in pairs(enemies) do
			j:AddNewModifier(caster, self, "modifier_jeanne_vision", { Duration = self:GetSpecialValueFor("reveal_duration") })
		end
	end

	if caster.IsDivineSymbolAcquired then
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			local newKeys = caster
			newKeys.caster = caster
			newKeys.ability = caster:FindAbilityByName("jeanne_charisma")
			newKeys.target = v
			newKeys.Radius = newKeys.ability:GetSpecialValueFor("radius_modifier")
			newKeys.Duration = newKeys.ability:GetSpecialValueFor("duration")
			OnIRStart(newKeys, true)
		end
	end

	local sacredBubble = ParticleManager:CreateParticle("particles/jeanne/jeanne_luminocite_magnetic.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(sacredBubble, 0, projectileDestination)
	ParticleManager:SetParticleControl(sacredBubble, 1, Vector(range,0,0))

	local sacredZoneFx = ParticleManager:CreateParticle("particles/custom/ruler/luminosite_eternelle/sacred_zone.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(sacredZoneFx, 0, projectileDestination)
	ParticleManager:SetParticleControl(sacredZoneFx, 1, Vector(1,1,range))
	ParticleManager:SetParticleControl(sacredZoneFx, 14, Vector(range,range,0))
	ParticleManager:SetParticleControl(sacredZoneFx, 4, Vector(-range * .9,0,0) + projectileDestination) -- Cross arm lengths
	ParticleManager:SetParticleControl(sacredZoneFx, 5, Vector(range * .9,0,0) + projectileDestination)
	ParticleManager:SetParticleControl(sacredZoneFx, 6, Vector(0,-range * .9,0) + projectileDestination)
	ParticleManager:SetParticleControl(sacredZoneFx, 7, Vector(0,range * .9,0) + projectileDestination)
	caster.CurrentFlagParticle = sacredZoneFx
	caster.CurrentFlagParticle1 = sacredBubble
end

function jeanne_flag:OnChannelThink(fInterval)
	local caster = self:GetCaster()
	local range = self:GetSpecialValueFor("radius")
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		if caster:GetMana()>=1 then
			if v ~= self:GetCaster() then
				v:AddNewModifier(caster, self, "modifier_le_aura", {duration = fInterval*2})
				HardCleanse(v)
			end
		else
			v:RemoveModifierByName("modifier_le_aura")
		end
	end
end

function jeanne_flag:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_jeanne_flag_invul")
	ParticleManager:DestroyParticle( caster.CurrentFlagParticle, false )
	ParticleManager:ReleaseParticleIndex( caster.CurrentFlagParticle )

	ParticleManager:DestroyParticle( caster.CurrentFlagParticle1, false )
	ParticleManager:ReleaseParticleIndex( caster.CurrentFlagParticle1 )
end

modifier_jeanne_flag_invul = class({})

function modifier_jeanne_flag_invul:IsHidden() return true end
function modifier_jeanne_flag_invul:IsDebuff() return false end

function modifier_jeanne_flag_invul:CheckState()
	return {[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true}
end

modifier_le_aura = class({})

function modifier_le_aura:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_le_aura:OnTakeDamage(args)
	self.parent = self:GetParent()
	if args.unit ~= self.parent then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.parent:Heal(args.damage, caster)
	self.caster:SpendMana(args.damage/(self.ability:GetSpecialValueFor("dmg_per_mana") + (self.caster.IsDivineSymbolAcquired and 0.5 or 0)), self.ability)

	if self.caster:GetMana() < 1 then
		self.ability:EndChannel(true)
		local caster = self:GetCaster()
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			v:RemoveModifierByName("modifier_le_aura")
		end
	end
end
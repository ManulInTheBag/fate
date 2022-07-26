LinkLuaModifier("modifier_nero_heat", "abilities/nero/nero_heat", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_ready_checker", "abilities/nero/modifiers/modifier_laus_saint_ready_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imperial_buff_h", "abilities/nero/nero_imperial", LUA_MODIFIER_MOTION_NONE)

nero_heat = class({})

function nero_heat:GetIntrinsicModifierName()
	return "modifier_nero_heat"
end
function nero_heat:OnSpellStart()
	local caster = self:GetCaster()
	--if not caster:HasModifier("modifier_aestus_domus_aurea_nero") then return end
	if caster:FindModifierByName("modifier_nero_heat").rank >= 6 then
		caster.UpgradeBase = true
	end
	if caster:FindModifierByName("modifier_nero_heat").rank == 7 then
		caster.UpgradeLSK = true
	end
	caster:RemoveModifierByName("modifier_laus_saint_ready_checker")
	Timers:CreateTimer(FrameTime(), function()
		caster:AddNewModifier(caster, self, "modifier_laus_saint_ready_checker", {duration = 4})
	end)
end
function nero_heat:IncreaseHeat(caster)
	local caster = caster
	local modifier = caster:FindModifierByName("modifier_nero_heat")

	modifier.duration_remaining = self:GetSpecialValueFor("duration")
	if not modifier.rank then
		modifier.rank = 0
	end

	if caster.DiabolisVectisAcquired then
		local damage = self:GetSpecialValueFor("vectis_damage") + self:GetSpecialValueFor("vectis_damage_per_stack")*caster:FindModifierByName("modifier_nero_heat").rank
		local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

		ParticleManager:SetParticleControl(particle, 2, Vector(1,1,350))
		ParticleManager:SetParticleControl(particle, 3, Vector(350 / 350,1,1))

		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end)

		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		for _,enemy in pairs(enemies) do
			DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	end

	if modifier.rank < 6 or (modifier.rank < 7 and caster:HasModifier("modifier_aestus_domus_aurea_nero")) then
		modifier.rank = modifier.rank + 1
		modifier:UpdateParticle()
	end

	if caster.IsPrivilegeImproved then
		caster:AddNewModifier(caster, self, "modifier_imperial_buff_h", {duration = 5})
	end
end

function nero_heat:RefreshHeatDuration(caster)
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_nero_heat")

	if caster.IsPrivilegeImproved then
		caster:AddNewModifier(caster, self, "modifier_imperial_buff_h", {duration = 5})
	end

	modifier.duration_remaining = self:GetSpecialValueFor("duration")
end

modifier_nero_heat = class({})

function modifier_nero_heat:IsHidden() return false end
function modifier_nero_heat:IsDebuff() return false end
function modifier_nero_heat:RemoveOnDeath() return false end
function modifier_nero_heat:OnCreated()
	self.rank = 0
end
function modifier_nero_heat:OnTakeDamage(args)
	if args.attacker ~= self:GetCaster() then return end

	self.ability = self:GetAbility()

	self.ability:RefreshHeatDuration()
end
function modifier_nero_heat:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_nero_heat:UpdateParticle()
	print(self.rank)
	if not self.particle then
		self.particle = ParticleManager:CreateParticle("particles/nero/nero.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	    ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
	    self:StartIntervalThink(FrameTime())
	end
	ParticleManager:SetParticleControl(self.particle, 1, Vector(self.rank, 0, 0))
end
function modifier_nero_heat:OnIntervalThink()
	if not self:GetParent():HasModifier("modifier_aestus_domus_aurea_nero") then
		self.duration_remaining = self.duration_remaining - FrameTime()
	end
	--print(self.duration_remaining)
	if self.duration_remaining <= 0 then
		self.rank = 0
	end
	self:UpdateParticle()
end
function modifier_nero_heat:DeclareFunctions()
    return {
    	--MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end
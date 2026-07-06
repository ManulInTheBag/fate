saber_alter_unleashed_ferocity = class({})

LinkLuaModifier("modifier_unleashed_ferocity_vfx", "abilities/arturia_alter/saber_alter_unleashed_ferocity", LUA_MODIFIER_MOTION_NONE)

-- Combo: if derange opened the combo window and stats are maxed, show MAX Mana Burst for 3 seconds
local function DSCheckCombo(caster)
	if caster:HasModifier("modifier_arturia_alter_combo_window") then
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
			if caster:FindAbilityByName("saber_alter_max_mana_burst"):IsCooldownReady() and caster:FindAbilityByName("saber_alter_mana_burst"):IsCooldownReady() and caster:IsAlive() then
				caster:SwapAbilities("saber_alter_max_mana_burst", "saber_alter_mana_burst", true, false)
				Timers:CreateTimer(3, function()
					caster:SwapAbilities("saber_alter_max_mana_burst", "saber_alter_mana_burst", false, true)
				end)
			end
		end
	end
end

function saber_alter_unleashed_ferocity:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local UFCount = 0
	local bonusDamage = 0

	if caster.IsFerocityImproved then
		bonusDamage = caster:GetStrength()*0.75 + caster:GetIntellect()*0.75
	end

	caster:EmitSound("saber_alter_other_03")

	DSCheckCombo(caster)
	Timers:CreateTimer(function()
		if UFCount == 5 or not caster:IsAlive() then return end
		caster:EmitSound("Saber_Alter.Unleashed")
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius
			, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, v:GetHealth() * damage / 100 + bonusDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.1})
		end
		UFCount = UFCount + 1
		return 0.5
	end)

	caster:AddNewModifier(caster, self, "modifier_unleashed_ferocity_vfx", {duration = 2.0})
end

-- Pulsing caster particle: a short burst on apply and every 0.5s for 2s
modifier_unleashed_ferocity_vfx = class({})

function modifier_unleashed_ferocity_vfx:IsHidden()
	return true
end

function modifier_unleashed_ferocity_vfx:IsPurgable()
	return false
end

function modifier_unleashed_ferocity_vfx:OnCreated()
	if not IsServer() then return end
	self:CreateBurst()
	self:StartIntervalThink(0.5)
end

function modifier_unleashed_ferocity_vfx:OnIntervalThink()
	self:CreateBurst()
end

function modifier_unleashed_ferocity_vfx:CreateBurst()
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_unleashed_ferocity.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(fx, 1, Vector(400, 3, 0))
	Timers:CreateTimer(0.1, function()
		ParticleManager:DestroyParticle(fx, false)
		ParticleManager:ReleaseParticleIndex(fx)
	end)
end

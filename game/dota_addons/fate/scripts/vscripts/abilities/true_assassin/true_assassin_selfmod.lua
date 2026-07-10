true_assassin_selfmod = class({})

LinkLuaModifier("modifier_true_assassin_selfmod", "abilities/true_assassin/modifiers/modifier_true_assassin_selfmod", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_selfmod_agility", "abilities/true_assassin/modifiers/modifier_selfmod_agility", LUA_MODIFIER_MOTION_NONE)

function true_assassin_selfmod:GetIntrinsicModifierName()
	return "modifier_true_assassin_selfmod"
end

function true_assassin_selfmod:OnHeroDiedNearby( hVictim, hKiller, kv )
	if hVictim == nil or hKiller == nil then
		return
	end

	if hKiller == self:GetCaster() or ((hVictim:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D() < 300 and hVictim:GetTeamNumber() ~= self:GetCaster():GetTeamNumber()) then
		if self.nKills == nil then
			self.nKills = 0
		end
		self.nKills = self.nKills + 1
		local hBuff = self:GetCaster():FindModifierByName("modifier_true_assassin_selfmod")
		if hBuff ~= nil then
			hBuff:SetStackCount(self.nKills)
		end
	end
end

function true_assassin_selfmod:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	caster:EmitSound("Hero_LifeStealer.OpenWounds.Cast")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bane/bane_fiendsgrip_ground_rubble.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
			return nil
	end)

	caster:AddNewModifier(caster, ability, "modifier_selfmod_agility", { Duration = self:GetSpecialValueFor("duration") })
end

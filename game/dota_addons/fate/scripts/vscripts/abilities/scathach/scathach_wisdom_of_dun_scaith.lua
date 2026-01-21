scathach_wisdom_of_dun_scaith = class({})

LinkLuaModifier("modifier_scathach_wisdom_of_dun_scaith", "abilities/scathach/modifiers/modifier_scathach_wisdom_of_dun_scaith", LUA_MODIFIER_MOTION_NONE)


function scathach_wisdom_of_dun_scaith:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_scathach_wisdom_of_dun_scaith", { Duration = self:GetSpecialValueFor("duration")})
	local targets = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		if  v:HasModifier("modifier_scathach_pupil") and v:IsAlive() then
			v:AddNewModifier(caster, self, "modifier_scathach_wisdom_of_dun_scaith", { Duration = self:GetSpecialValueFor("duration")})
		end
	end
	--self:CheckCombo()
end

function scathach_wisdom_of_dun_scaith:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect(false) >= 29.1 then
		if caster:FindAbilityByName("scathach_combo_gate_of_sky"):IsCooldownReady() and caster:FindAbilityByName("scathach_red_creed_combo"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_scathach_combo_window", { Duration = 4 })
		end
	end
end
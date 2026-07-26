-- true_assassin_combo — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/true_assassin/ta_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

true_assassin_combo = class({})

LinkLuaModifier("modifier_delusional_illusion_cooldown", "abilities/true_assassin/true_assassin_combo", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/ta_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDIStart, CreateDIDummies

OnDIStart = function(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	local ability = keys.ability
	local DICount = 0
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_delusional_illusion_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	EmitGlobalSound("Hassan_Combo")

	Timers:CreateTimer(function()
		if DICount > ability:GetSpecialValueFor("duration") or not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("search_radius")
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v.IsDIOnCooldown ~= true then
				CreateDIDummies(caster, v)
			end
		end
		DICount = DICount + 0.33
		return 0.33
	end)
end

CreateDIDummies = function(caster, target)
	target.IsDIOnCooldown = true

	local origin = target:GetAbsOrigin() + RandomVector(650)
	local illusion = CreateUnitByName("ta_combo_dummy", origin, false, caster, caster, caster:GetTeamNumber())
	local illusionskill = illusion:FindAbilityByName("true_assassin_combo_zab")
	illusionskill:SetLevel(1)
	illusion:SetForwardVector(target:GetAbsOrigin() - illusion:GetAbsOrigin())
	illusion:CastAbilityOnTarget(target, illusionskill, 1)
	StartAnimation(illusion, {duration = 5, activity = ACT_DOTA_ATTACK, rate = 1}) --maybe take this out

	local origin = target:GetAbsOrigin() + RandomVector(550)
	local illusion2 = CreateUnitByName("ta_combo_dummy_2", origin, false, caster, caster, caster:GetTeamNumber())
	local illusionskill2 = illusion2:FindAbilityByName("true_assassin_combo_zab")
	illusionskill2:SetLevel(1)
	illusion2:SetForwardVector(target:GetAbsOrigin() - illusion2:GetAbsOrigin())
	illusion2:CastAbilityOnTarget(target, illusionskill2, 1)
	StartAnimation(illusion2, {duration = 5, activity = ACT_DOTA_ATTACK, rate = 1}) --maybe take this out

	local origin = target:GetAbsOrigin() + RandomVector(450)
	local illusion3 = CreateUnitByName("ta_combo_dummy_3", origin, false, caster, caster, caster:GetTeamNumber())
	local illusionskill3 = illusion3:FindAbilityByName("true_assassin_combo_zab")
	illusionskill3:SetLevel(1)
	illusion3:SetForwardVector(target:GetAbsOrigin() - illusion3:GetAbsOrigin())
	illusion3:CastAbilityOnTarget(target, illusionskill3, 1)
	StartAnimation(illusion3, {duration = 5, activity = ACT_DOTA_ATTACK, rate = 2}) --maybe take this out

	Timers:CreateTimer(3.0, function()
		illusion:RemoveSelf()
		illusion2:RemoveSelf()
		illusion3:RemoveSelf()
		target.IsDIOnCooldown = false
	return end)
end


function true_assassin_combo:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: ta_ability / OnDIStart
	OnDIStart({ caster = caster, ability = self, target = caster })
end

modifier_delusional_illusion_cooldown = class({})

function modifier_delusional_illusion_cooldown:IsDebuff() return true end
function modifier_delusional_illusion_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

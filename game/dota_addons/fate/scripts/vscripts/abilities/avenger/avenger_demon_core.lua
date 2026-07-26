-- avenger_demon_core — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_demon_core = class({})

LinkLuaModifier("modifier_demon_core", "abilities/avenger/avenger_demon_core", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDCToggleOn, OnDCTick

OnDCToggleOn = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_demon_core", {})
end

OnDCTick = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	-- If Demon Core is not toggled on or caster has less than 50 mana, remove buff 
	if not ability:GetToggleState() or caster:GetMana() < 50 or not caster:HasModifier("modifier_true_form") then 
		caster:RemoveModifierByName("modifier_demon_core")
		return
	end
	-- Reduce mana and process attribute stuffs
	caster:SpendMana(50, ability)
	--caster:SetMana(caster:GetMana() - 25) 
	if caster.IsDIAcquired then 
		local trueform = caster:FindAbilityByName("avenger_true_form")
		local trueformcd = trueform:GetCooldownTimeRemaining() 
		trueform:EndCooldown()
		trueform:StartCooldown(trueformcd - 0.5)
	end
end


function avenger_demon_core:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		EmitSoundOn("Hero_Huskar.Inner_Vitality", caster)
		-- DD RunScript: avenger_ability / OnDCToggleOn
		OnDCToggleOn({ caster = caster, ability = self })
	end
end

modifier_demon_core = class({})

function modifier_demon_core:GetEffectName() return "particles/units/heroes/hero_huskar/huskar_inner_vitality.vpcf" end
function modifier_demon_core:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_demon_core:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
	}
end

function modifier_demon_core:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("health_regen_percentage")
end

function modifier_demon_core:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(0.25)
end

function modifier_demon_core:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_demon_core:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: avenger_ability / OnDCTick
	OnDCTick({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

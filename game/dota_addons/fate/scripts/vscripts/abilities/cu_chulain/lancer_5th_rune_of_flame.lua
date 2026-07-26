-- lancer_5th_rune_of_flame — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/cu_chulain/unused.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancer_5th_rune_of_flame = class({})

LinkLuaModifier("modifier_lancer_rune_of_flame", "abilities/cu_chulain/lancer_5th_rune_of_flame", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lancer_incinerate", "abilities/cu_chulain/lancer_5th_rune_of_flame", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lancer_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIncinerateHit

OnIncinerateHit = function(keys)
	local caster = keys.caster
	local target = keys.target

	--[[if caster:GetAttackTarget():GetName() == "npc_dota_ward_base" then
		print("Attacking Ward")
		return
	end]]

	local currentStack = target:GetModifierStackCount("modifier_lancer_incinerate", keys.ability)

	if currentStack == 0 and target:HasModifier("modifier_lancer_incinerate") then currentStack = 1 end
	target:RemoveModifierByName("modifier_lancer_incinerate") 
	target:AddNewModifier(caster, keys.ability, "modifier_lancer_incinerate", {}) 
	target:SetModifierStackCount("modifier_lancer_incinerate", keys.ability, currentStack + 1)

	DoDamage(caster, target, keys.ExtraDamage*currentStack, DAMAGE_TYPE_PURE, 0, keys.ability, false)
end


function lancer_5th_rune_of_flame:GetIntrinsicModifierName()
	return "modifier_lancer_rune_of_flame"
end

modifier_lancer_rune_of_flame = class({})


function modifier_lancer_rune_of_flame:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_lancer_rune_of_flame:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: lancer_ability / OnIncinerateHit
	OnIncinerateHit({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target,
		ExtraDamage = self:GetAbility():GetSpecialValueFor("extra_damage")
	})
end

modifier_lancer_incinerate = class({})

function modifier_lancer_incinerate:IsDebuff() return true end
function modifier_lancer_incinerate:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_lancer_incinerate:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "5.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(5.0, true)
	end
end

function modifier_lancer_incinerate:OnRefresh(kv)
	self:OnCreated(kv)
end

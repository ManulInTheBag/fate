-- gille_gigantic_horror_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilles/gilles_abyssal_contract.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gille_gigantic_horror_passive = class({})

LinkLuaModifier("modifier_gigantic_horror_passive", "abilities/gilles/gille_gigantic_horror_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gille_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnHorrorTakeDamage

OnHorrorTakeDamage = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner() 
	local hero = ply:GetAssignedHero()
	local damageTaken = keys.DamageTaken
	local threshold = keys.Threshold
	local multiplier = 0.3
	if damageTaken > threshold then 
		DoDamage(keys.attacker, caster, damageTaken * multiplier, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end 
end


function gille_gigantic_horror_passive:GetIntrinsicModifierName()
	return "modifier_gigantic_horror_passive"
end

modifier_gigantic_horror_passive = class({})

function modifier_gigantic_horror_passive:IsHidden() return true end

function modifier_gigantic_horror_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_gigantic_horror_passive:GetModifierHealthRegenPercentage()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("health_regen")
end

function modifier_gigantic_horror_passive:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: gille_ability / OnHorrorTakeDamage
	OnHorrorTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage"),
		Threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")
	})
end

function modifier_gigantic_horror_passive:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	EmitSoundOn("Hero_Spectre.Attack", self:GetCaster())
end

function modifier_gigantic_horror_passive:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	EmitSoundOn("Hero_Centaur.HoofStomp", self:GetCaster())
end

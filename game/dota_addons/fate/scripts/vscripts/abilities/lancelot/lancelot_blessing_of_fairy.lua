-- lancelot_blessing_of_fairy — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_blessing_of_fairy = class({})

LinkLuaModifier("modifier_blessing_of_fairy", "abilities/lancelot/lancelot_blessing_of_fairy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fairy_magic_immunity", "abilities/lancelot/lancelot_blessing_of_fairy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blessing_of_fairy_cooldown", "abilities/lancelot/lancelot_blessing_of_fairy", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFairyDmgTaken

OnFairyDmgTaken = function(keys)
    local caster = keys.caster
    if caster:GetHealth() < 500 and caster:IsAlive() and caster.IsFairyReady then 
        caster:EmitSound("DOTA_Item.BlackKingBar.Activate")
        EmitZlodemonTrueSoundEveryone("moskes_lanc_bkb")
        caster:AddNewModifier(caster, keys.ability, "modifier_fairy_magic_immunity", {})
        caster:AddNewModifier(caster, keys.ability, "modifier_blessing_of_fairy_cooldown", {duration = keys.ability:GetCooldown(keys.ability:GetLevel())})
        caster.IsFairyReady = false
        HardCleanse(caster)
        caster:Heal(500, caster)
        Timers:CreateTimer(keys.ability:GetCooldown(keys.ability:GetLevel()), function()
            caster.IsFairyReady = true
        end)
    end
end


function lancelot_blessing_of_fairy:GetIntrinsicModifierName()
	return "modifier_blessing_of_fairy"
end

modifier_blessing_of_fairy = class({})

function modifier_blessing_of_fairy:IsHidden() return true end

function modifier_blessing_of_fairy:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_blessing_of_fairy:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: lancelot_ability / OnFairyDmgTaken
	OnFairyDmgTaken({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		Threshold = self:GetAbility():GetSpecialValueFor("damage_threshold"),
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage")
	})
end

modifier_fairy_magic_immunity = class({})


function modifier_fairy_magic_immunity:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_fairy_magic_immunity:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("magres")
end

function modifier_fairy_magic_immunity:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	local fx = ParticleManager:CreateParticle("particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_fairy_magic_immunity:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_blessing_of_fairy_cooldown = class({})

function modifier_blessing_of_fairy_cooldown:IsDebuff() return true end
function modifier_blessing_of_fairy_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

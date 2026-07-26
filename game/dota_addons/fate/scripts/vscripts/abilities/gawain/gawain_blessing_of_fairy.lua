-- gawain_blessing_of_fairy — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gawain/gawain_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gawain_blessing_of_fairy = class({})

LinkLuaModifier("modifier_gawain_revive", "abilities/gawain/gawain_blessing_of_fairy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gawain_blessing_cooldown", "abilities/gawain/gawain_blessing_of_fairy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gawain_revive_regen", "abilities/gawain/gawain_blessing_of_fairy", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gawain_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFairyDamageTaken

OnFairyDamageTaken = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local currentHealth = caster:GetHealth()

	if currentHealth < 333 and keys.ability:IsCooldownReady() and IsRevivePossible(caster) then
		RemoveDebuffsForRevival(caster)
		caster:SetHealth(333)
		keys.ability:StartCooldown(99) 

		HardCleanse(caster)

		local proxy = caster:FindAbilityByName("gawain_blessing_proxy")

		proxy:StartCooldown(99)

		caster:AddNewModifier(caster, ability, "modifier_gawain_blessing_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
		caster:AddNewModifier(caster, ability, "modifier_gawain_revive_regen", {duration = 5})
		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
		end)
	end
end


function gawain_blessing_of_fairy:GetIntrinsicModifierName()
	return "modifier_gawain_revive"
end

function gawain_blessing_of_fairy:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_gawain_revive", {})
end

modifier_gawain_revive = class({})

function modifier_gawain_revive:IsHidden() return true end

function modifier_gawain_revive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_gawain_revive:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: gawain_ability / OnFairyDamageTaken
	OnFairyDamageTaken({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage")
	})
end

modifier_gawain_blessing_cooldown = class({})

function modifier_gawain_blessing_cooldown:IsDebuff() return true end
function modifier_gawain_blessing_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_gawain_revive_regen = class({})


function modifier_gawain_revive_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_gawain_revive_regen:GetModifierConstantHealthRegen()
	return 333
end

function modifier_gawain_revive_regen:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(5, true)
	end
end

function modifier_gawain_revive_regen:OnRefresh(kv)
	self:OnCreated(kv)
end

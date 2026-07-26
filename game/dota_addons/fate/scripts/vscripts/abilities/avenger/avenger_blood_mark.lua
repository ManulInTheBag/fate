-- avenger_blood_mark — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_blood_mark = class({})

LinkLuaModifier("modifier_blood_mark_cooldown", "abilities/avenger/avenger_blood_mark", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blood_mark_restriction", "abilities/avenger/avenger_blood_mark", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBloodStart

OnBloodStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_blood_mark_restriction", {})
	caster:AddNewModifier(caster, ability, "modifier_blood_mark_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	if IsSpellBlocked(keys.target, caster) then return end

	DoDamage(caster, target, 500, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	caster:Heal(500, ability)

	-- local casterHealthPct = caster:GetHealthPercent()
	-- local targetHealthPct = target:GetHealthPercent()

	-- print(casterHealthPct)
	-- print(targetHealthPct)

	-- caster:SetHealth(math.max(caster:GetMaxHealth() * targetHealthPct / 100, 1))
	-- target:SetHealth(math.max(target:GetMaxHealth() * casterHealthPct / 100, 1))

	--[[local initHealth = caster:GetHealth() 
	local initTargetHealth = target:GetHealth()

	if initHealth > caster:GetMaxHealth() then
		target:SetHealth(caster:GetMaxHealth())
	else
		target:SetHealth(initHealth)
	end
	if initTargetHealth > target:GetMaxHealth() then
		caster:SetHealth(target:GetMaxHealth())
	else
		caster:SetHealth(initTargetHealth)
	end]]
end


function avenger_blood_mark:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: avenger_ability / OnBloodStart
	OnBloodStart({ caster = caster, ability = self, target = target })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death_bonus.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("Hero_DoomBringer.Devour", target)
end

modifier_blood_mark_cooldown = class({})

function modifier_blood_mark_cooldown:IsDebuff() return true end
function modifier_blood_mark_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_blood_mark_restriction = class({})

function modifier_blood_mark_restriction:IsDebuff() return true end
function modifier_blood_mark_restriction:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_blood_mark_restriction:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3.0, true)
	end
end

function modifier_blood_mark_restriction:OnRefresh(kv)
	self:OnCreated(kv)
end

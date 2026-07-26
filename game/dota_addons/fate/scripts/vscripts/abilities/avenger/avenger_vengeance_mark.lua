-- avenger_vengeance_mark — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_vengeance_mark = class({})

LinkLuaModifier("modifier_vengeance_mark", "abilities/avenger/avenger_vengeance_mark", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnVengeanceStart

OnVengeanceStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	--[[if caster:HasModifier("modifier_blood_mark_restriction") then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
		caster:GiveMana(ability:GetManaCost(1))
		keys.ability:EndCooldown()
		return
	end]]

	if IsSpellBlocked(keys.target, caster) then return end
	target:AddNewModifier(caster, keys.ability, "modifier_vengeance_mark", {})
	giveUnitDataDrivenModifier(caster, target , "rooted", keys.Duration)
	DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

	caster:EmitSound("Hero_DoomBringer.Devour")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death_bonus.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
end


function avenger_vengeance_mark:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: avenger_ability / OnVengeanceStart
	OnVengeanceStart({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		Delay = self:GetSpecialValueFor("delay"),
		Duration = self:GetSpecialValueFor("duration")
	})
end

modifier_vengeance_mark = class({})

function modifier_vengeance_mark:IsDebuff() return true end
function modifier_vengeance_mark:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_vengeance_mark:GetEffectName() return "particles/units/heroes/hero_warlock/warlock_shadow_word_buff.vpcf" end
function modifier_vengeance_mark:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_vengeance_mark:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%delay" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("delay"), true)
	end
end

function modifier_vengeance_mark:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_vengeance_mark:OnDestroy()
	if not IsServer() then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death_bonus.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("Hero_DoomBringer.Devour", self:GetCaster())
end

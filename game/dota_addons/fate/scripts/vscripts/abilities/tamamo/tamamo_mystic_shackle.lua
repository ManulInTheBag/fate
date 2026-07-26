-- tamamo_mystic_shackle — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_mystic_shackle = class({})

LinkLuaModifier("modifier_mystic_shackle_cooldown", "abilities/tamamo/tamamo_mystic_shackle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mystic_shackle", "abilities/tamamo/tamamo_mystic_shackle", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnShackleStart, OnShackleThink

OnShackleStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = caster.MantraTarget

	if (caster:GetAbsOrigin() - caster.MantraLocation):Length2D() > 500
		or not target:IsAlive()
		or (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() > 1000
	then
		caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(keys.ability:GetLevel()-1)) 
		keys.ability:EndCooldown()
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Too Far From Initial Castpoint" } ) 
		return
	end
	caster:AddNewModifier(caster, ability, "modifier_mystic_shackle_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	target:AddNewModifier(caster, ability, "modifier_mystic_shackle", {})
	giveUnitDataDrivenModifier(caster, caster, "locked", 3.0)
	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		giveUnitDataDrivenModifier(caster, target, "locked", 3.0)
	end
end

OnShackleThink = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	if dist > 2500
		or target:IsMagicImmune()
		or not IsInSameRealm(caster:GetAbsOrigin(), target:GetAbsOrigin())
	then
		target:RemoveModifierByName("modifier_mystic_shackle")
	elseif dist > 700 then
		local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
		local normal = diff:Normalized()
		target:SetAbsOrigin(caster:GetAbsOrigin()+normal*700)
		FindClearSpaceForUnit( target, target:GetAbsOrigin(), true )
	end
end


function tamamo_mystic_shackle:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
	return true
end

function tamamo_mystic_shackle:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnShackleStart
	OnShackleStart({
		caster = caster,
		ability = self,
		target = caster,
		OrbAmount = self:GetSpecialValueFor("orb_amount"),
		Target = "POINT"
	})
end

modifier_mystic_shackle_cooldown = class({})

function modifier_mystic_shackle_cooldown:IsDebuff() return true end
function modifier_mystic_shackle_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_mystic_shackle = class({})

function modifier_mystic_shackle:IsDebuff() return true end

function modifier_mystic_shackle:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3.0, true)
	end
	self:StartIntervalThink(0.01)
	EmitSoundOn("Hero_Wisp.Tether.Target", self:GetParent())
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_mystic_shackle:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_mystic_shackle:OnDestroy()
	if not IsServer() then return end
end

function modifier_mystic_shackle:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: tamamo_ability / OnShackleThink
	OnShackleThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

-- astolfo_casa_di_logistilla — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_casa_di_logistilla = class({})

LinkLuaModifier("modifier_casa_passive", "abilities/astolfo/astolfo_casa_di_logistilla", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_casa_passive_mr_aura", "abilities/astolfo/astolfo_casa_di_logistilla", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_casa_passive_mr", "abilities/astolfo/astolfo_casa_di_logistilla", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_casa_active_mr", "abilities/astolfo/astolfo_casa_di_logistilla", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnCasaStart, OnCasaThink

OnCasaStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster:HasModifier("modifier_hippogriff_ride_ascended") or not caster.bIsSanityAcquired then 
		ability:EndCooldown()
		caster:GiveMana(ability:GetManaCost(1)) 
		return 
	end 
	--if caster.bIsSanityAcquired then
	    --local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		--for k,v in pairs(targets) do
		--	ability:ApplyDataDrivenModifier(caster, v, "modifier_casa_active_mr", {})
		--	v:EmitSound("Hero_Oracle.FortunesEnd.Target")
	   -- end
	--else
		caster:AddNewModifier(caster, ability, "modifier_casa_active_mr", {})
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_weave_circle_ray.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin() + Vector(0,0, 100))
		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(particle , true)
			ParticleManager:ReleaseParticleIndex(particle)
		
		end)
		caster:EmitSound("Hero_Oracle.FortunesEnd.Target")
	--end
end

OnCasaThink = function(keys)
	local caster = keys.caster
	local ability = keys.ability

	if ability:IsCooldownReady() then
		--if caster.bIsSanityAcquired then
		--	ability:ApplyDataDrivenModifier(caster, caster, "modifier_casa_passive_mr_aura", {})
		--else
			caster:AddNewModifier(caster, ability, "modifier_casa_passive_mr", {})
		--end
	end
end


function astolfo_casa_di_logistilla:GetIntrinsicModifierName()
	return "modifier_casa_passive"
end

function astolfo_casa_di_logistilla:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnCasaStart
	OnCasaStart({ caster = caster, ability = self, target = caster })
end

modifier_casa_passive = class({})

function modifier_casa_passive:IsHidden() return true end

function modifier_casa_passive:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_casa_passive:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_casa_passive:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnCasaThink
	OnCasaThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_casa_passive_mr_aura = class({})

function modifier_casa_passive_mr_aura:IsHidden() return true end

function modifier_casa_passive_mr_aura:IsAura() return true end
function modifier_casa_passive_mr_aura:GetModifierAura() return "modifier_casa_passive_mr" end
function modifier_casa_passive_mr_aura:GetAuraRadius() return 350 end
function modifier_casa_passive_mr_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_casa_passive_mr_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end

function modifier_casa_passive_mr_aura:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.533" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.533, true)
	end
end

function modifier_casa_passive_mr_aura:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_casa_passive_mr = class({})

function modifier_casa_passive_mr:IsHidden() return true end

function modifier_casa_passive_mr:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_casa_passive_mr:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("passive_mr")
end

function modifier_casa_passive_mr:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.533" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.533, true)
	end
end

function modifier_casa_passive_mr:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_casa_active_mr = class({})

function modifier_casa_active_mr:GetEffectName() return "particles/zlodemon/astolfo_jopa_shield.vpcf" end
function modifier_casa_active_mr:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_casa_active_mr:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_casa_active_mr:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("active_mr")
end

function modifier_casa_active_mr:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3.5, true)
	end
end

function modifier_casa_active_mr:OnRefresh(kv)
	self:OnCreated(kv)
end

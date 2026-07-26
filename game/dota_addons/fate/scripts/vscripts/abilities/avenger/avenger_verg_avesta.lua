-- avenger_verg_avesta — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_verg_avesta = class({})

LinkLuaModifier("modifier_verg_avesta", "abilities/avenger/avenger_verg_avesta", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnVergStart, OnVergTakeDamage

OnVergStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_verg_avesta", {})
	EmitGlobalSound("Avenger.Berg")
	EmitGlobalSound("Avenger.BergShout")

end

OnVergTakeDamage = function(keys)
	--[[local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local attacker = keys.attacker

	if not attacker:IsHero() and IsValidEntity(attacker:GetPlayerOwner()) then
		attacker = attacker:GetPlayerOwner():GetAssignedHero()
	elseif attacker:IsIllusion() then
		attacker = PlayerResource:GetPlayer(attacker:GetPlayerID()):GetAssignedHero()
	end

	if caster.IsDIAcquired then keys.Multiplier = keys.Multiplier + 25 end
	local returnDamage = keys.DamageTaken * keys.Multiplier / 100
	if caster:GetHealth() ~= 0 then
		DoDamage(caster, attacker, returnDamage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, keys.ability, false)
		if attacker:IsRealHero() then attacker:EmitSound("Hero_WitchDoctor.Maledict_Tick") end
		local particle = ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_charlie/sniper_assassinate_impact_blood_charlie.vpcf", PATTACH_ABSORIGIN, attacker)
		ParticleManager:SetParticleControl(particle, 1, attacker:GetAbsOrigin())
	end]]
end


function avenger_verg_avesta:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnVergStart
	OnVergStart({ caster = caster, ability = self, target = caster })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_verg_avesta = class({})


function modifier_verg_avesta:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_verg_avesta:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	local fx = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_verg_avesta:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_verg_avesta:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: avenger_ability / OnVergTakeDamage
	OnVergTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		Multiplier = self:GetAbility():GetSpecialValueFor("multiplier"),
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage")
	})
end

-- caster_5th_sacrifice — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_sacrifice = class({})

LinkLuaModifier("modifier_big_bad_voodoo_channeling", "abilities/medea/caster_5th_sacrifice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_channeling", "abilities/medea/caster_5th_sacrifice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_big_bad_voodoo_damage_bonus", "abilities/medea/caster_5th_sacrifice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_big_bad_voodoo_ally", "abilities/medea/caster_5th_sacrifice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_big_bad_voodoo_invulnerability", "abilities/medea/caster_5th_sacrifice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)
-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSacrificeStart, RemoveSacrificeModifier, MaledictStop, CreateSacrificeAllyParticle

OnSacrificeStart = function(keys)

	local caster = keys.caster

	caster.SacFx = ParticleManager:CreateParticle("particles/custom/caster/sacrifice/caster_sacrifice_indicator.vpcf", PATTACH_WORLDORIGIN, nil )
    caster:AddNewModifier(caster,self, "modifier_kb_immune", {duration = 10})
	ParticleManager:SetParticleControl( caster.SacFx, 0, caster:GetAbsOrigin())

	ParticleManager:SetParticleControl( caster.SacFx, 1, Vector(keys.Radius,0,0))
    ParticleManager:SetParticleShouldCheckFoW(caster.SacFx, false)


	caster:EmitSound("Medea_Skill_" .. math.random(7,8))

end

RemoveSacrificeModifier = function(keys)

	local caster = keys.caster

	keys.caster:RemoveModifierByName("modifier_big_bad_voodoo_channeling")

	keys.caster:RemoveModifierByName("modifier_big_bad_voodoo_ally")

	Timers:CreateTimer(1.0, function()

	keys.caster:RemoveModifierByName("modifier_big_bad_voodoo_damage_bonus")

	end)



	ParticleManager:DestroyParticle( caster.SacFx, false )

	ParticleManager:ReleaseParticleIndex( caster.SacFx )
    caster:RemoveModifierByNameAndCaster("modifier_kb_immune", caster)
	caster.SacFx = nil

end

MaledictStop = function( event )

	local caster = event.caster

	

	caster:StopSound("Hero_WitchDoctor.Maledict_Loop")

end

CreateSacrificeAllyParticle = function(keys)

	ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_buff_j.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.target)

end


function caster_5th_sacrifice:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_big_bad_voodoo_damage_bonus", { duration = self:GetSpecialValueFor("duration") })
	caster:AddNewModifier(caster, self, "modifier_big_bad_voodoo_channeling", {})
	caster:AddNewModifier(caster, self, "modifier_big_bad_voodoo_ally", {})
	-- DD RunScript: caster_ability / OnSacrificeStart
	OnSacrificeStart({
		caster = caster,
		ability = self,
		target = caster,
		Radius = self:GetSpecialValueFor("radius")
	})
end

function caster_5th_sacrifice:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / RemoveSacrificeModifier
	RemoveSacrificeModifier({ caster = caster, ability = self })
end

modifier_big_bad_voodoo_channeling = class({})

function modifier_big_bad_voodoo_channeling:IsHidden() return true end

function modifier_big_bad_voodoo_channeling:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function modifier_big_bad_voodoo_channeling:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_big_bad_voodoo_channeling:OnIntervalThink()
	if not IsServer() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_channeling", { duration = 0.9 })
end

modifier_channeling = class({})

function modifier_channeling:IsHidden() return true end
function modifier_channeling:GetOverrideAnimation() return ACT_DOTA_ATTACK end

modifier_big_bad_voodoo_damage_bonus = class({})

function modifier_big_bad_voodoo_damage_bonus:GetEffectName() return "particles/units/heroes/hero_warlock/warlock_shadow_word_buff.vpcf" end
function modifier_big_bad_voodoo_damage_bonus:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_big_bad_voodoo_damage_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_big_bad_voodoo_damage_bonus:GetModifierIncomingDamage_Percentage()
	return 50
end

function modifier_big_bad_voodoo_damage_bonus:OnCreated(kv)
	if not IsServer() then return end
	EmitSoundOn("Hero_WitchDoctor.Maledict_Loop", self:GetCaster())
end

function modifier_big_bad_voodoo_damage_bonus:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_big_bad_voodoo_damage_bonus:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: caster_ability.lua / MaledictStop
	MaledictStop({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_big_bad_voodoo_ally = class({})

function modifier_big_bad_voodoo_ally:IsHidden() return true end

function modifier_big_bad_voodoo_ally:IsAura() return true end
function modifier_big_bad_voodoo_ally:GetModifierAura() return "modifier_big_bad_voodoo_invulnerability" end
function modifier_big_bad_voodoo_ally:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_big_bad_voodoo_ally:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_big_bad_voodoo_ally:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_big_bad_voodoo_ally:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_big_bad_voodoo_ally:GetAuraEntityReject(target) return target == self:GetParent() end

modifier_big_bad_voodoo_invulnerability = class({})

function modifier_big_bad_voodoo_invulnerability:GetEffectName() return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_buff_j.vpcf" end
function modifier_big_bad_voodoo_invulnerability:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_big_bad_voodoo_invulnerability:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
end

function modifier_big_bad_voodoo_invulnerability:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function modifier_big_bad_voodoo_invulnerability:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_big_bad_voodoo_invulnerability:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: caster_ability.lua / CreateSacrificeAllyParticle
	CreateSacrificeAllyParticle({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

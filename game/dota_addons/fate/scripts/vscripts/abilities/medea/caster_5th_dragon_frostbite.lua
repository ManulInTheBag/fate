-- caster_5th_dragon_frostbite — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_dragon_frostbite = class({})

LinkLuaModifier("modifier_frostbite_root", "abilities/medea/caster_5th_dragon_frostbite", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFrostbiteStart, OnFrostbiteHit

OnFrostbiteStart = function(keys)
	local caster = keys.caster
	local targetPos = keys.ability:GetCursorPosition() 
	local direction = targetPos - caster:GetAbsOrigin()
	direction = direction/direction:Length2D()

	local icebreath = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = 1000,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 900 - keys.EndRadius, -- We need this to take end radius of projectile into account
        fStartRadius = 300,
        fEndRadius = keys.EndRadius,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 700
	}
	projectile = ProjectileManager:CreateLinearProjectile(icebreath)

	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_jakiro/jakiro_dual_breath_ice.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl( pfx, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( pfx, 1, direction * 700 * 1.333 )
	ParticleManager:SetParticleControl( pfx, 3, Vector(0,0,0) )
	ParticleManager:SetParticleControl( pfx, 9, caster:GetAbsOrigin() )

	caster:EmitSound("Hero_Jakiro.DualBreath")

	Timers:CreateTimer(0.8, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
end

OnFrostbiteHit = function(keys)
	local caster = keys.caster 
	local target = keys.target
	DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	target:AddNewModifier(caster, keys.ability, "modifier_frostbite_root", {})

end


function caster_5th_dragon_frostbite:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: caster_ability / OnFrostbiteStart
	OnFrostbiteStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		EndRadius = self:GetSpecialValueFor("radius")
	})
end

function caster_5th_dragon_frostbite:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnFrostbiteHit
	OnFrostbiteHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage")
	})
	return false
end

modifier_frostbite_root = class({})

function modifier_frostbite_root:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_frostbite_root:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_frostbite_root:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_frostbite_root:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%total_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("total_duration"), true)
	end
end

function modifier_frostbite_root:OnRefresh(kv)
	self:OnCreated(kv)
end

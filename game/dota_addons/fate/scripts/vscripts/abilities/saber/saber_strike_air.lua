-- saber_strike_air — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber/saber_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_strike_air = class({})

LinkLuaModifier("saber_strike_air_anim_vfx", "abilities/saber/saber_strike_air", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_strike_air_cooldown", "abilities/saber/saber_strike_air", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_strike_air_animation", "abilities/saber/saber_strike_air", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_strike_air_target_VFX", "abilities/saber/saber_strike_air", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/saber_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnStrikeAirStart, StrikeAirPush

OnStrikeAirStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability

	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 0.75)
	caster:AddNewModifier(caster, ability, "modifier_strike_air_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	local strikeair = 
	{
		Ability = keys.ability,
        EffectName = "particles/custom/saber_strike_air_blast.vpcf",
        iMoveSpeed = 5000,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 1200,
        fStartRadius = 400,
        fEndRadius = 400,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 6.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 5000
	}

	Timers:CreateTimer(0.5, function()
		caster:AddNewModifier(caster, ability, "modifier_strike_air_animation", {})
	end)
	
	Timers:CreateTimer({
		endTime = 0.75, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
		if caster:IsAlive() then 
			strikeair.vSpawnOrigin = caster:GetAbsOrigin() 
			strikeair.vVelocity = caster:GetForwardVector() * 5000
			projectile = ProjectileManager:CreateLinearProjectile(strikeair)
		end
	end})

	EmitGlobalSound("Saber.StrikeAir_Cast")
	caster:EmitSound("Hero_Invoker.Tornado")
	ability:ApplyDataDrivenModifier(caster, caster, "saber_strike_air_anim_vfx", {})
	Timers:CreateTimer(0.75, function()  
		local sound = RandomInt(1,2)
		if sound == 1 then EmitGlobalSound("Saber.StrikeAir_Release1") else EmitGlobalSound("Saber.StrikeAir_Release2") end
	return end)

end

StrikeAirPush = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	if target:HasModifier("modifier_wind_protection_passive") then return end

	--if (target:GetName() == "npc_dota_hero_bounty_hunter" and target.IsPFWAcquired) then return end
	local totalDamage = 400 + (keys.caster:FindAbilityByName("saber_invisible_air"):GetLevel()+keys.caster:FindAbilityByName("saber_caliburn"):GetLevel()) * 100
	--if target:GetName() == "npc_dota_hero_juggernaut" then totalDamage = 0 end
	--+ (keys.caster:FindAbilityByName("saber_caliburn"):GetLevel() 
	local WallDamage = keys.WallDamage
	local WallStun = keys.WallStun

	DoDamage(keys.caster, keys.target, totalDamage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	giveUnitDataDrivenModifier(keys.caster, keys.target, "pause_sealenabled", 0.5)
	target:AddNewModifier(caster, ability, "modifier_strike_air_target_VFX", {})

    local pushTarget = Physics:Unit(keys.target)
    keys.target:PreventDI()
    keys.target:SetPhysicsFriction(0)
	local vectorC = (keys.target:GetAbsOrigin() - keys.caster:GetAbsOrigin()) 
	-- get the direction where target will be pushed back to
	local vectorB = vectorC - vectorA
	keys.target:SetPhysicsVelocity(vectorB:Normalized() * 1000)
    keys.target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	local initialUnitOrigin = keys.target:GetAbsOrigin()
	
	keys.target:OnPhysicsFrame(function(unit) -- pushback distance check
		local unitOrigin = unit:GetAbsOrigin()
		local diff = unitOrigin - initialUnitOrigin
		local n_diff = diff:Normalized()
		unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
		if diff:Length() > 500 then -- if pushback distance is over 500, stop it
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			unit:OnPhysicsFrame(nil)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end
	end)
	
	keys.target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		target:AddNewModifier(caster, target, "modifier_stunned", { Duration = WallStun })
		--giveUnitDataDrivenModifier(caster, target, "stunned",  WallStun)
		DoDamage(keys.caster, unit, WallDamage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end)
end


function saber_strike_air:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: saber_ability / OnStrikeAirStart
	OnStrikeAirStart({ caster = caster, ability = self, target = caster, target_points = { point } })
end

function saber_strike_air:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: saber_ability / StrikeAirPush
	StrikeAirPush({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		Speed = self:GetSpecialValueFor("speed"),
		WallDamage = self:GetSpecialValueFor("wall_bonus_damage"),
		WallStun = self:GetSpecialValueFor("wall_stun")
	})
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_illuminate_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	return false
end

saber_strike_air_anim_vfx = class({})

function saber_strike_air_anim_vfx:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_3 end
function saber_strike_air_anim_vfx:GetEffectName() return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf" end
function saber_strike_air_anim_vfx:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function saber_strike_air_anim_vfx:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function saber_strike_air_anim_vfx:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.75" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.75, true)
	end
end

function saber_strike_air_anim_vfx:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_strike_air_cooldown = class({})

function modifier_strike_air_cooldown:IsDebuff() return true end
function modifier_strike_air_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_strike_air_animation = class({})

function modifier_strike_air_animation:IsHidden() return true end
function modifier_strike_air_animation:IsPurgable() return false end
function modifier_strike_air_animation:GetOverrideAnimation() return ACT_DOTA_ATTACK end

function modifier_strike_air_animation:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_strike_air_animation:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_strike_air_target_VFX = class({})

function modifier_strike_air_target_VFX:IsHidden() return true end
function modifier_strike_air_target_VFX:GetEffectName() return "particles/units/heroes/hero_invoker/invoker_deafening_blast_knockback_debuff.vpcf" end
function modifier_strike_air_target_VFX:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_strike_air_target_VFX:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.5, true)
	end
end

function modifier_strike_air_target_VFX:OnRefresh(kv)
	self:OnCreated(kv)
end

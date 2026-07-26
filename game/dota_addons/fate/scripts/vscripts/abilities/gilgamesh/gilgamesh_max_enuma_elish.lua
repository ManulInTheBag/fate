-- gilgamesh_max_enuma_elish — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilgamesh/gilgamesh_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gilgamesh_max_enuma_elish = class({})

LinkLuaModifier("modifier_max_enuma_elish_cooldown", "abilities/gilgamesh/gilgamesh_max_enuma_elish", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("max_enuma_elish_anim", "abilities/gilgamesh/gilgamesh_max_enuma_elish", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gilg_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMaxEnumaStart, OnMaxEnumaHit

OnMaxEnumaStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	caster:FindAbilityByName("gilgamesh_enuma_elish"):StartCooldown(47)
	local targetPoint = keys.ability:GetCursorPosition()
	local frontward = caster:GetForwardVector()
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 5.0)
	LoopOverPlayers(function(player, playerID, playerHero)
		if playerHero.zlodemon == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_gil_combo"})
		end
	end)

	StartAnimation(caster, {duration=5, activity=ACT_DOTA_BELLYACHE_END, rate=1})

	EmitGlobalSound("Gilgamesh_Enuma_1")

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName("gilgamesh_max_enuma_elish")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))

	caster:AddNewModifier(caster, ability, "modifier_max_enuma_elish_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	-- Create charge particle
	local chargeFxIndex = ParticleManager:CreateParticle( "particles/custom/gilgamesh/gilgamesh_enuma_elish_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )

	local endRadius = keys.EndRadius
	local range = keys.Range
	if caster.IsEnumaImproved then
		endRadius = endRadius * 1.5
	end
	local enuma =
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = range - endRadius, -- We need this to take end radius of projectile into account
        fStartRadius = keys.StartRadius,
        fEndRadius = endRadius,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * keys.Speed
	}

	Timers:CreateTimer(3.75, function()
		if caster:IsAlive() then
			EmitGlobalSound("gilgamesh_enuma_elish")
		end
		return
	end)

	Timers:CreateTimer(4.25, function()
		-- Destroy charge particle regardless of alive/dead
		ParticleManager:DestroyParticle( chargeFxIndex, false )
		ParticleManager:ReleaseParticleIndex( chargeFxIndex )
		if caster:IsAlive() then
			frontward = caster:GetForwardVector()
			enuma.vSpawnOrigin = caster:GetAbsOrigin()
			enuma.vVelocity = frontward * keys.Speed
			projectile = ProjectileManager:CreateLinearProjectile(enuma)
			ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 10000, 0, true)
			ParticleManager:CreateParticle("particles/custom/screen_scarlet_splash.vpcf", PATTACH_EYES_FOLLOW, caster)

			-- Create particle
			local casterLocation = caster:GetAbsOrigin()
			local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			dummy:SetForwardVector(frontward)

			local radius = keys.StartRadius
			local fxIndex = ParticleManager:CreateParticle("particles/custom/gilgamesh/enuma_elish/projectile.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			ParticleManager:SetParticleControl(fxIndex, 3, targetPoint)

			Timers:CreateTimer( function()
				if IsValidEntity(dummy) and not dummy:IsNull() then
					local newLoc = GetGroundPosition(dummy:GetAbsOrigin() + keys.Speed * 0.03 * frontward, dummy)
					dummy:SetAbsOrigin( newLoc )
					radius = radius + (endRadius - keys.StartRadius) * keys.Speed * 0.03 / enuma.fDistance
					ParticleManager:SetParticleControl(fxIndex, 2, Vector(radius,0,0))
					return 0.03
				else
					return nil
				end
			end
			)
			Timers:CreateTimer(enuma.fDistance / keys.Speed + 0.2, function()
				EmitGlobalSound("gilgamesh_laugh_3")
				dummy:RemoveSelf()
			end)
		end
	end)
end

OnMaxEnumaHit = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	if caster.IsEnumaImproved then
		keys.Damage = caster.MasterUnit2:FindAbilityByName("gilgamesh_attribute_sword_of_creation"):GetSpecialValueFor("max_enuma_damage")
	end
	DoDamage(keys.caster, keys.target, keys.Damage, DAMAGE_TYPE_PURE, 0, keys.ability, false)
end


function gilgamesh_max_enuma_elish:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: gilg_ability / OnMaxEnumaStart
	OnMaxEnumaStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		StartRadius = self:GetSpecialValueFor("start_radius"),
		EndRadius = self:GetSpecialValueFor("end_radius"),
		Speed = self:GetSpecialValueFor("speed"),
		Range = self:GetSpecialValueFor("radius")
	})
end

function gilgamesh_max_enuma_elish:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: gilg_ability / OnMaxEnumaHit
	OnMaxEnumaHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage")
	})
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_illuminate_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	return false
end

modifier_max_enuma_elish_cooldown = class({})

function modifier_max_enuma_elish_cooldown:IsDebuff() return true end
function modifier_max_enuma_elish_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

max_enuma_elish_anim = class({})

function max_enuma_elish_anim:IsHidden() return true end
function max_enuma_elish_anim:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_6 end

function max_enuma_elish_anim:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "6.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(6.0, true)
	end
end

function max_enuma_elish_anim:OnRefresh(kv)
	self:OnCreated(kv)
end

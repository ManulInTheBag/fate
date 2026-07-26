-- tamamo_polygamist_castration_fist — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_polygamist_castration_fist = class({})

LinkLuaModifier("modifier_polygamist_cooldown", "abilities/tamamo/modifiers/modifier_polygamist_cooldown", LUA_MODIFIER_MOTION_NONE)
-- ^ класс написан руками и корректен, объявлять свой не нужно

LinkLuaModifier("modifier_polygamist", "abilities/tamamo/tamamo_polygamist_castration_fist", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnKickStart

OnKickStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local lungeDelay = keys.LungeDelay
	local damage = keys.Damage
	local expDamageRatio = keys.ExplosionRatio
	local ability = keys.ability
	local nextTarget = caster
	local count = 0
	local targets = 0
	if IsSpellBlocked(keys.target, caster) then return end

	if ability:GetAbilityName() == "tamamo_polygamist_castration_fist" then
		-- Set master's combo cooldown
		local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
		masterCombo:EndCooldown()
		masterCombo:StartCooldown(keys.ability:GetCooldown(1))
		caster:AddNewModifier(caster, ability, "modifier_polygamist_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	end

	if caster.IsEscapeAcquired then
		--[[if IsRevoked(caster) then
			FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Cannot Be Used(Revoked)" } )
			keys.ability:EndCooldown()
			caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(1))
			return			
		end]]
		lungeDelay = lungeDelay / 2
		damage = damage / 2
		expDamageRatio = expDamageRatio / 2
		caster:AddNewModifier(caster, ability, "modifier_polygamist_shorter", {}) 
	else 
		caster:AddNewModifier(caster, ability, "modifier_polygamist", {}) 
		EmitGlobalSound("Tamamo.Kick")
			
	end

	Timers:CreateTimer(function()
		if count == 3 then 
			-- Do knockback
			nextTarget:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.7})
			local forward = caster:GetForwardVector()
			local backwards = forward * -1
			local dur = 0
			Timers:CreateTimer(function()
				-- If knockback is finished, do damage 
				if dur > 0.4 then 
					FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
					FindClearSpaceForUnit(nextTarget, nextTarget:GetAbsOrigin(), true)
					targets = FindUnitsInRadius(caster:GetTeam(), nextTarget:GetAbsOrigin(), nil, keys.SearchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
					for k,v in pairs(targets) do
						DoDamage(caster, v, expDamageRatio*caster:GetIntellect() ,DAMAGE_TYPE_MAGICAL, 0, ability, false  )
					end
					local explodeFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_hit.vpcf", PATTACH_ABSORIGIN, nextTarget )
					ParticleManager:SetParticleControl( explodeFx1, 0, nextTarget:GetAbsOrigin())
					local explodeFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, nextTarget )
					ParticleManager:SetParticleControl( explodeFx2, 0, nextTarget:GetAbsOrigin())
					nextTarget:EmitSound("Ability.LightStrikeArray")
					return 
				end 
				caster:SetAbsOrigin(caster:GetAbsOrigin() + backwards*33)
				if not nextTarget:HasModifier("modifier_wind_protection_passive") then
					nextTarget:SetAbsOrigin(nextTarget:GetAbsOrigin() + forward*33)
				end
				dur = dur + 0.033
				return 0.033
			end)
			-- Do knockback 
			return 
		end
		targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.SearchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		local trailFxIndex = ParticleManager:CreateParticle("particles/custom/tamamo/tamamo_kick_trail.vpcf", PATTACH_CUSTOMORIGIN, nextTarget )
		ParticleManager:SetParticleControl( trailFxIndex, 1, nextTarget:GetAbsOrigin() )
		if #targets ~= 0 then
			nextTarget = targets[math.random(#targets)]
			caster:SetAbsOrigin(nextTarget:GetAbsOrigin() + RandomVector(100))
			DoDamage(caster, nextTarget, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			nextTarget:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.1})


			ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
			nextTarget:EmitSound("Hero_Tusk.WalrusPunch.Target")
		end
		ParticleManager:SetParticleControl( trailFxIndex, 0, nextTarget:GetAbsOrigin() )
		local splashFx = ParticleManager:CreateParticle("particles/custom/screen_violet_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
		count = count+1
		return lungeDelay 
	end)
end


function tamamo_polygamist_castration_fist:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnKickStart
	OnKickStart({
		caster = caster,
		ability = self,
		target = caster,
		LungeDelay = self:GetSpecialValueFor("lunge_delay"),
		SearchRadius = self:GetSpecialValueFor("search_radius"),
		Damage = self:GetSpecialValueFor("kick_damage"),
		RecoilDistance = self:GetSpecialValueFor("recoil_distance"),
		ExplosionRatio = self:GetSpecialValueFor("explosion_int_ratio")
	})
end

modifier_polygamist = class({})


function modifier_polygamist:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_polygamist:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "2.2" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(2.2, true)
	end
end

function modifier_polygamist:OnRefresh(kv)
	self:OnCreated(kv)
end

-- modifier_polygamist_shorter ← DD-блок удалённой tamamo_polygamist_castration_fist_2
-- (те же состояния, Duration 1.45); применяется из OnKickStart этой способности
LinkLuaModifier("modifier_polygamist_shorter", "abilities/tamamo/tamamo_polygamist_castration_fist", LUA_MODIFIER_MOTION_NONE)
modifier_polygamist_shorter = class({})

function modifier_polygamist_shorter:CheckState()
	return modifier_polygamist.CheckState(self)
end

function modifier_polygamist_shorter:OnCreated(kv)
	if not IsServer() then return end
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.45, true)
	end
end

function modifier_polygamist_shorter:OnRefresh(kv)
	self:OnCreated(kv)
end

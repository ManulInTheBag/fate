-- lancer_5th_wesen_gae_bolg — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/cu_chulain/unused.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancer_5th_wesen_gae_bolg = class({})

LinkLuaModifier("modifier_wesen_gae_bolg_anim", "abilities/cu_chulain/lancer_5th_wesen_gae_bolg", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wesen_gae_bolg_pierce_anim", "abilities/cu_chulain/lancer_5th_wesen_gae_bolg", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wesen_gae_bolg_cooldown", "abilities/cu_chulain/lancer_5th_wesen_gae_bolg", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lancer_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local GBAttachEffect, OnGBComboHit, PlayNormalGBEffect, PlayHeartBreakEffect

GBAttachEffect = function(keys)
	local caster = keys.caster
	local GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( GBCastFx, false )
	end)

	if keys.ability == caster:FindAbilityByName("lancer_5th_gae_bolg") then
		caster:EmitSound("Lancer.GaeBolg")
	elseif keys.ability == caster:FindAbilityByName("lancelot_gae_bolg") then 
		caster:EmitSound("Lancelot.Growl_Local" )
	end
	if keys.caster:GetName() == "npc_dota_hero_sven" then
		EmitZlodemonTrueSoundEveryone("moskes_lanc_gae")
	end
end

OnGBComboHit = function(keys)
	if IsSpellBlocked(keys.target, keys.caster) then return end -- Linken effect checker
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local HBThreshold = target:GetMaxHealth() * keys.HBThreshold / 100
	local silenceDuration = keys.SilenceDuration


	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_wesen_gae_bolg_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	if caster.IsHeartSeekerAcquired == true then HBThreshold = HBThreshold + caster:GetAttackDamage()*ATTR_HEARTSEEKER_COMBO_AD_RATIO end

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 3.0)
	giveUnitDataDrivenModifier(caster, target, "silenced", silenceDuration)
	StartAnimation(caster, {duration=1.2, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.5})
	Timers:CreateTimer(1.6, function()
		StartAnimation(caster, {duration=3, activity=ACT_DOTA_RUN, rate=3})
	end)
	local soundQueue = math.random(1,4)

	if soundQueue ~= 4 then
		caster:EmitSound("Cu_Combo_" .. soundQueue)
		target:EmitSound("Cu_Combo_" .. soundQueue)
	else
		caster:EmitSound("Lancer.Heartbreak")
		target:EmitSound("Lancer.Heartbreak")
	end

	--caster:EmitSound("Lancer.Heartbreak")
	--target:EmitSound("Lancer.Heartbreak")
	caster:FindAbilityByName("lancer_5th_gae_bolg"):StartCooldown(27.0)
	if target:IsAlive() then
	  	Timers:CreateTimer(1.8, function() 
			if (caster:GetAbsOrigin().y < -2000 and target:GetAbsOrigin().y > -2000) or (caster:GetAbsOrigin().y > -2000 and target:GetAbsOrigin().y < -2000) then 
				StopSoundEvent("Lancer.Heartbreak", caster)
				StopSoundEvent("Lancer.Heartbreak", target)
				return 
			end
		    local lancer = Physics:Unit(caster)

		    caster:AddNewModifier(caster, keys.ability, "modifier_wesen_gae_bolg_pierce_anim", {})

		    caster:OnHibernate(function(unit)
		    	caster:SetPhysicsVelocity((keys.target:GetAbsOrigin() - keys.caster:GetAbsOrigin()):Normalized() * 3000)
		    	caster:PreventDI()
		    	caster:SetPhysicsFriction(0)
		    	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		    	caster:FollowNavMesh(false)	
		    	caster:SetAutoUnstuck(false)
		    	caster:OnPhysicsFrame(function(unit)
					local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
					local dir = diff:Normalized()
					unit:SetPhysicsVelocity(dir * 3000)

					Timers:CreateTimer(0.15, function()
						if diff:Length()>100 and (caster:GetAbsOrigin().y < -2000 and target:GetAbsOrigin().y > -2000) or (caster:GetAbsOrigin().y > -2000 and target:GetAbsOrigin().y < -2000) == false then
							caster:SetAbsOrigin(target:GetAbsOrigin() - target:GetForwardVector():Normalized()*100)
							FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
						end
					end)

					if diff:Length() < 100 then
				  		caster:RemoveModifierByName("pause_sealdisabled")
						unit:PreventDI(false)
						unit:SetPhysicsVelocity(Vector(0,0,0))
						unit:OnPhysicsFrame(nil)
						unit:OnHibernate(nil)
						unit:SetAutoUnstuck(true)
			        	FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)

				        if caster:IsAlive() then 
				        	local RedScreenFx = ParticleManager:CreateParticle("particles/custom/screen_red_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
				        	Timers:CreateTimer( 3.0, function()
								ParticleManager:DestroyParticle( RedScreenFx, false )
							end)
			        		target:EmitSound("Hero_Lion.Impale")
			        		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK2, rate=2})
							local runeAbil = caster:FindAbilityByName("lancer_5th_rune_of_flame")
							local healthDamagePct = runeAbil:GetLevelSpecialValueFor("ability_bonus_damage", runeAbil:GetLevel()-1)
							if caster.IsGaeBolgImproved == true then
							healthDamagePct = healthDamagePct * 2
							end

							giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)
				    		DoDamage(caster, target, keys.Damage + target:GetHealth() * healthDamagePct/100, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
							target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 1.0})

							PlayNormalGBEffect(target)
							if target:GetHealth() < HBThreshold then 
								PlayHeartBreakEffect(ability, caster, target)
							end
						end
					end
				end)
		    end)


			return
		end)
	end
end

PlayNormalGBEffect = function(target)
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)
	
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
end

PlayHeartBreakEffect = function(ability, killer, target)
	if target:HasModifier("modifier_avalon") then return end
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
		ParticleManager:DestroyParticle( hb, false )
	end)
	target:Execute(ability, killer, { bExecution = true })
end


function lancer_5th_wesen_gae_bolg:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: lancer_ability / GBAttachEffect
	GBAttachEffect({ caster = caster, ability = self, target = target })
	return true
end

function lancer_5th_wesen_gae_bolg:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: lancer_ability / OnGBComboHit
	OnGBComboHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		HBThreshold = self:GetSpecialValueFor("heartbreak_threshold_percentage"),
		SilenceDuration = self:GetSpecialValueFor("silence_duration")
	})
end

modifier_wesen_gae_bolg_anim = class({})

function modifier_wesen_gae_bolg_anim:IsHidden() return true end
function modifier_wesen_gae_bolg_anim:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_1 end

function modifier_wesen_gae_bolg_anim:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_wesen_gae_bolg_anim:GetOverrideAnimationRate()
	return 0.5
end

function modifier_wesen_gae_bolg_anim:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_wesen_gae_bolg_anim:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_wesen_gae_bolg_pierce_anim = class({})

function modifier_wesen_gae_bolg_pierce_anim:IsHidden() return true end
function modifier_wesen_gae_bolg_pierce_anim:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_3_END end

function modifier_wesen_gae_bolg_pierce_anim:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_wesen_gae_bolg_pierce_anim:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_wesen_gae_bolg_cooldown = class({})

function modifier_wesen_gae_bolg_cooldown:IsDebuff() return true end
function modifier_wesen_gae_bolg_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

-- lancelot_nine_lives — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_nine_lives = class({})

LinkLuaModifier("modifier_dash_anim", "abilities/lancelot/lancelot_nine_lives", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nine_anim", "abilities/lancelot/lancelot_nine_lives", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nine_anim2", "abilities/lancelot/lancelot_nine_lives", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nine_anim3", "abilities/lancelot/lancelot_nine_lives", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/berserker_ability.lua, scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnNineCast, OnNineStart, OnKnightUsed, ArsenalReturnMana, DoNineLanded, OnNineLanded, OnKnightClosed, DeductCourageDamageStack

OnNineCast = function(keys)
	local caster = keys.caster
	local casterName = caster:GetName()
	if casterName == "npc_dota_hero_doom_bringer" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_5, rate=0.2})
	elseif casterName == "npc_dota_hero_sven" then
		
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL_START, rate=0.2})
	elseif casterName == "npc_dota_hero_ember_spirit" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RUN, rate=0.2})
	end
end

OnNineStart = function(keys)
	ArsenalReturnMana(keys.caster)
	local caster = keys.caster
	local casterName = caster:GetName()
	local targetPoint = keys.ability:GetCursorPosition()
	local ability = keys.ability
	local berserker = Physics:Unit(caster)
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized() * distance*2
	caster.bNineStarted = false
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector()*distance*2)
	--caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 4.0)
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_dash_anim", {})
	if casterName == "npc_dota_hero_doom_bringer" then
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_5, rate=0.5})
	elseif casterName == "npc_dota_hero_sven" then
		caster:SetBodygroup(0,1)
		Timers:CreateTimer(1.3, function() 
			if not caster.bNineStarted  then
				caster:SetBodygroup(0,0)
				print("set back")
			end
		end)
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL_START, rate=0.5})
	elseif casterName == "npc_dota_hero_ember_spirit" then
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_RUN, rate=0.8})
	end

	function DoNineLanded(caster)
		caster:OnPreBounce(nil)
		caster:OnPhysicsFrame(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		Timers:RemoveTimer(caster.NineTimer)
		caster.NineTimer = nil
		if caster:IsAlive() then
			OnNineLanded(caster, keys.ability)
			return 
		end
		return
	end

	caster.NineTimer = Timers:CreateTimer(0.5, function()
		DoNineLanded(caster)
	end)

	--[[caster:OnPhysicsFrame(function(unit)
		if CheckDummyCollide(unit) then
			DoNineLanded(unit)
		end
	end)

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		DoNineLanded(unit)
	end)]]


	if caster:GetName() == "npc_dota_hero_ember_spirit" then
		caster:EmitSound("Archer.NineLives")
	end

	
	--[[Timers:CreateTimer(function()
		if travelCounter == 33 then OnNineLanded(caster, keys.ability) return end
		caster:SetAbsOrigin(caster:GetAbsOrigin() + forward) 
		travelCounter = travelCounter + 1
		
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		return 0.03
		end
	)]]
end

OnKnightUsed = function(keys)
        local caster = keys.caster
        local ply = caster:GetPlayerOwner()
        local ability = keys.ability

        if not caster.KnightLevel and not caster.ArsenalLevel then
                OnKnightClosed(keys)
                caster:FindAbilityByName("lancelot_knight_of_honor"):StartCooldown(ability:GetCooldown(ability:GetLevel()))
        end
end

ArsenalReturnMana = function(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end

	DoNineLanded = function(caster)
		caster:OnPreBounce(nil)
		caster:OnPhysicsFrame(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		Timers:RemoveTimer(caster.NineTimer)
		caster.NineTimer = nil
		if caster:IsAlive() then
			OnNineLanded(caster, keys.ability)
			return 
		end
		return
	end

OnNineLanded = function(caster, ability)
	local tickdmg = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)
	local lasthitdmg = ability:GetLevelSpecialValueFor("damage_lasthit", ability:GetLevel() - 1)
	local courageAbility = 0
	local courageDamage = 0
	if caster:GetName() == "npc_dota_hero_doom_bringer" then 
		courageAbility = caster:FindAbilityByName("berserker_5th_courage")
		courageDamage = courageAbility:GetSpecialValueFor("bonus_damage")
	end
	local returnDelay = 0.3
	if caster:GetName() == "npc_dota_hero_ember_spirit" then
		returnDelay = 0.1
	end
	local radius = ability:GetSpecialValueFor("radius")
	local lasthitradius = ability:GetSpecialValueFor("radius_lasthit")
	local stun = ability:GetSpecialValueFor("stun_duration")
	local nineCounter = 0
	local casterInitOrigin = caster:GetAbsOrigin() 
	local ilya = false
	caster.bNineStarted = true
	-- swap animation
	if caster:GetName() == "npc_dota_hero_doom_bringer" then 
		if caster:IsAlive() then
			StartAnimation(caster, {duration=3.5, activity=ACT_DOTA_CAST_ABILITY_6, rate=1.0})

			local ilya_chance = math.random(1,100)

			if ilya_chance <= 5 then				
				ilya = true
				tickdmg = tickdmg * 1.1
				lasthitdmg = lasthitdmg * 1.1
			end
		end
	end
	if caster:GetName() == "npc_dota_hero_sven" then
		EmitZlodemonTrueSoundEveryone("moskes_lanc_nine")
	end

	-- main timer
	Timers:CreateTimer(function()
		if caster:IsAlive() then -- only perform actions while caster stays alive
			local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle, 1, Vector(0,0,(nineCounter % 2) * 180))
			ParticleManager:SetParticleControl(particle, 2, Vector(1,1,radius))
			ParticleManager:SetParticleControl(particle, 3, Vector(radius / 350,1,1))
			if caster:GetName() == "npc_dota_hero_sven" and nineCounter < 7 and nineCounter %2 == 0 then 
				if math.random(0,1) == 0 then 
					StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL, rate=1.25})
				else
					StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=1.5})
				end
			elseif caster:GetName() == "npc_dota_hero_ember_spirit" then 
				StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3.0}) 
			end
			caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact") 
			if nineCounter == 7 then
				if caster:GetName() == "npc_dota_hero_sven" then 
					StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=4.5})
				end

			end
			if nineCounter == 8 then -- if it is last strike

				caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
				caster:RemoveModifierByName("pause_sealenabled") 
				ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 1500, 0, true)
				-- do damage to targets
				local damage = lasthitdmg 
				if caster:HasModifier("modifier_courage_damage_stack_indicator") then
					damage = damage + courageDamage/2
					DeductCourageDamageStack(caster)
				end 
				local lasthitTargets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, lasthitradius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 1, false)
				for k,v in pairs(lasthitTargets) do
					if v:GetName() ~= "npc_dota_ward_base" then
						if caster.IsProjectionImproved then 
							DoDamage(caster, v, damage + v:GetHealth() * 0.05, DAMAGE_TYPE_MAGICAL, 0, ability, false)
						else
							DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
						end
						v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 1.0 })
						--giveUnitDataDrivenModifier(caster, v, "stunned", 1.5)

						--[[if caster:GetName() ~= "npc_dota_hero_ember_spirit" then
							giveUnitDataDrivenModifier(caster, v, "revoked", 0.5)
						end]]
						-- push enemies back
						v:RemoveModifierByNameAndCaster("modifier_kb_immune", caster)
						if not IsKnockbackImmune(v) then
							local pushback = Physics:Unit(v)
							v:PreventDI()
							v:SetPhysicsFriction(0)
							v:SetPhysicsVelocity((v:GetAbsOrigin() - casterInitOrigin):Normalized() * 300)
							v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
							v:FollowNavMesh(false)
							Timers:CreateTimer(0.5, function()  
								v:PreventDI(false)
								v:SetPhysicsVelocity(Vector(0,0,0))
								v:OnPhysicsFrame(nil)
								FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
							end)
						end
					end
				end

				if caster:GetName() == "npc_dota_hero_doom_bringer" then
					--EmitGlobalSound("Berserker.Roar")
				elseif caster:GetName() == "npc_dota_hero_sven" then
					EmitGlobalSound("Lancelot.Roar1" )
					caster:SetBodygroup(0,0)
					StartAnimation(caster, {duration=0.7, activity=ACT_DOTA_CAST_CHAOS_METEOR, rate=3.0})
				elseif caster:GetName() == "npc_dota_hero_ember_spirit" then
					caster:EmitSound("Archer.NineFinish") 
				end

				ParticleManager:SetParticleControl(particle, 2, Vector(1,1,lasthitradius))
				ParticleManager:SetParticleControl(particle, 3, Vector(lasthitradius / 350,1,1))
				ParticleManager:ReleaseParticleIndex(particle)
				local lastparticle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/last_hit.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:ReleaseParticleIndex(lastparticle)

				-- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, lasthitradius, true, 0.5)
			else
				-- if its not last hit, do regular hit stuffs
				local damage = tickdmg -- store original tick damage 
				if caster:HasModifier("modifier_courage_damage_stack_indicator") then
					damage = damage + courageDamage/2
					DeductCourageDamageStack(caster)
				end 

				if nineCounter == 4 and caster:GetName() == "npc_dota_hero_doom_bringer" and not ilya then
					EmitGlobalSound("Heracles_NineLives_" .. math.random(1,3))
				elseif ilya and nineCounter == 3 then
					EmitGlobalSound("Heracles_Combo_Easter_1")
				end

				local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)
				for k,v in pairs(targets) do
					if caster.IsProjectionImproved then 
						DoDamage(caster, v, damage + v:GetHealth() * 0.05, DAMAGE_TYPE_MAGICAL, 0, ability, false)
					else
						DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
					end
					v:AddNewModifier(caster,ability, "modifier_kb_immune", {duration = 0.5})
					v:AddNewModifier(caster, v, "modifier_rooted", { Duration = 0.5 })
					if caster.ImproveKnightOfOwner then
						v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.2 })
					end
					giveUnitDataDrivenModifier(caster, v, "locked", 0.5)
					--v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.5 })
					--giveUnitDataDrivenModifier(caster, v, "stunned", 0.5)
					--[[if caster:GetName() ~= "npc_dota_hero_ember_spirit" then
						print("9 revoke")
						giveUnitDataDrivenModifier(caster, v, "revoked", 0.5)
					end]]
				end

				ParticleManager:SetParticleControl(particle, 2, Vector(1,1,radius))
				ParticleManager:SetParticleControl(particle, 3, Vector(radius / 350,1,1))
				-- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, radius, true, 0.5)
				ParticleManager:ReleaseParticleIndex(particle)


				nineCounter = nineCounter + 1
				return returnDelay
			end

		else
			if caster:GetName() == "npc_dota_hero_sven" then
				caster:SetBodygroup(0,0)
				
			end
		end
	end)
end

OnKnightClosed = function(keys)
        local caster = keys.caster
        caster.IsKnightOpen = false
        local a1 = caster:GetAbilityByIndex(0)
        local a2 = caster:GetAbilityByIndex(1)
        local a3 = caster:GetAbilityByIndex(2)
        local a4 = caster:GetAbilityByIndex(3)
        local a5 = caster:GetAbilityByIndex(4)
        local a6 = caster:GetAbilityByIndex(5)
        -- if knight attribute is not taken, caster.KnightLevel~=nil is false and therefore kills off queueing a 2nd skill. 
        caster:SwapAbilities(a1:GetName(), "lancelot_minigun", false ,true) 
        caster:SwapAbilities(a2:GetName(), "lancelot_parry", false, true) 
        caster:SwapAbilities(a3:GetName(), "lancelot_knight_of_honor", false, true)
        if caster.nukeAvail == true then 
            caster:SwapAbilities(a4:GetName(), "lancelot_nuke", false, true) 
        elseif caster:HasAbility("lancelot_blessing_of_fairy") then 
            caster:SwapAbilities(a4:GetName(), "lancelot_blessing_of_fairy", false, true) 
        else 
            caster:SwapAbilities(a4:GetName(), "fate_empty1", false, true) 
        end
        caster:SwapAbilities(a5:GetName(), "lancelot_arms_mastership", false, true) 
        
        if caster:HasModifier("modifier_arondite") then
            caster:SwapAbilities(a6:GetName(), "lancelot_arondight_overload", false, true )     
        else
            caster:SwapAbilities(a6:GetName(), "lancelot_arondite", false, true )     
        end
end

DeductCourageDamageStack = function(caster)
	local courageAbility = caster:FindAbilityByName("berserker_5th_courage")
	-- Deduce a stack from damage buff
	local currentStack = caster:GetModifierStackCount("modifier_courage_damage_stack_indicator", courageAbility)
	if currentStack == 1 then
		caster:RemoveModifierByName("modifier_courage_damage_stack_indicator")
	else
		caster:SetModifierStackCount("modifier_courage_damage_stack_indicator", courageAbility, currentStack-1)
	end
end


function lancelot_nine_lives:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function lancelot_nine_lives:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: berserker_ability / OnNineCast
	OnNineCast({ caster = caster, ability = self, target = caster, target_points = { point } })
	return true
end

function lancelot_nine_lives:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: berserker_ability / OnNineStart
	OnNineStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT"
	})
	-- DD RunScript: lancelot_ability / OnKnightUsed
	OnKnightUsed({ caster = caster, ability = self, target = caster, target_points = { point } })
end

modifier_dash_anim = class({})

function modifier_dash_anim:IsHidden() return true end
function modifier_dash_anim:GetOverrideAnimation() return ACT_DOTA_RUN end

function modifier_dash_anim:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_dash_anim:GetOverrideAnimationRate()
	return 0.5
end

function modifier_dash_anim:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_dash_anim:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_nine_anim = class({})

function modifier_nine_anim:GetOverrideAnimation() return ACT_DOTA_ATTACK end

function modifier_nine_anim:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_nine_anim:GetOverrideAnimationRate()
	return 2.5
end

function modifier_nine_anim:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.2" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.2, true)
	end
end

function modifier_nine_anim:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_nine_anim2 = class({})

function modifier_nine_anim2:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_3 end

function modifier_nine_anim2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_nine_anim2:GetOverrideAnimationRate()
	return 3.0
end

function modifier_nine_anim2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_nine_anim2:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_nine_anim3 = class({})

function modifier_nine_anim3:IsHidden() return true end
function modifier_nine_anim3:GetOverrideAnimation() return ACT_DOTA_ATTACK2 end

function modifier_nine_anim3:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_nine_anim3:GetOverrideAnimationRate()
	return 2.5
end

function modifier_nine_anim3:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.2" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.2, true)
	end
end

function modifier_nine_anim3:OnRefresh(kv)
	self:OnCreated(kv)
end

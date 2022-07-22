tamamo_soul_stream = class({})
modifier_soulstream_buff = class({})
modifier_tamamo_fire_debuff = class({})
modifier_tamamo_ice_debuff = class({})
modifier_tamamo_wind_debuff = class({})
modifier_tamamo_wind_particle = class({})

LinkLuaModifier("modifier_soulstream_buff", "abilities/tamamo/tamamo_soul_stream", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tamamo_fire_debuff", "abilities/tamamo/tamamo_soul_stream", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tamamo_ice_debuff", "abilities/tamamo/tamamo_soul_stream", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tamamo_wind_debuff", "abilities/tamamo/tamamo_soul_stream", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tamamo_wind_particle", "abilities/tamamo/tamamo_soul_stream", LUA_MODIFIER_MOTION_NONE)

function tamamo_soul_stream:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("range")
end

function tamamo_soul_stream:GetManaCost(iLevel)
	local hCaster = self:GetCaster()
	local fAddCost = 0

	if hCaster:HasModifier("modifier_soulstream_buff") then
		fAddCost = hCaster:GetModifierStackCount("modifier_soulstream_buff", hCaster) * 0
	end

	return 100 + fAddCost
end

function tamamo_soul_stream:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function tamamo_soul_stream:GetCastPoint()
	if self:GetCaster().IsWitchcraftAcquired then
		return 0
	end
	return 0.2
end

function tamamo_soul_stream:GetBehavior()
	if self:GetCaster().IsWitchcraftAcquired then
		return (DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE)
	end
	return (DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE)
end

--[[function tamamo_soul_stream:OnUpgrade()
	local hCaster = self:GetCaster()

	hCaster:FindAbilityByName("tamamo_fiery_heaven"):SetLevel(self:GetLevel())
	hCaster:FindAbilityByName("tamamo_frigid_heaven"):SetLevel(self:GetLevel())
	hCaster:FindAbilityByName("tamamo_gust_heaven"):SetLevel(self:GetLevel())
end]]

function tamamo_soul_stream:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=1.67, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
    return true
end

function tamamo_soul_stream:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function tamamo_soul_stream:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTargetLoc = self:GetCursorPosition()
	if (hTargetLoc - hCaster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("range") then
		hTargetLoc = hCaster:GetAbsOrigin() + (hTargetLoc - hCaster:GetAbsOrigin()):Normalized()*self:GetSpecialValueFor("range")
	end
	local hModifier
	local delay = 0

	if hCaster.IsWitchcraftAcquired then
		delay = 0.2
		StartAnimation(self:GetCaster(), {duration=1.67, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
	end

	Timers:CreateTimer(delay, function()
		hCaster:AddNewModifier(hCaster, self, "modifier_soulstream_buff", { Duration = self:GetSpecialValueFor("buff_dur")})

		local sCharmColor = "particles/custom/tamamo/charms_blue.vpcf" --default
		local tExtraData = { sExplosionColor = "particles/custom/tamamo/charms_blue_explosion.vpcf",
							 sCharmAbility = "tamamo_soul_stream" } -- default

		if hCaster:HasModifier("modifier_fiery_heaven_indicator") then
			sCharmColor = "particles/custom/tamamo/charms_red.vpcf"
			tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_red_explosion.vpcf"
			tExtraData["sDebuffName"] = "modifier_tamamo_fire_debuff"
			tExtraData["sCharmAbility"] = "tamamo_fiery_heaven"

			--[[hModifier = hCaster:FindModifierByName("modifier_fiery_heaven_indicator")
			if hModifier:GetStackCount() > 6 then
				hModifier:SetStackCount(hModifier:GetStackCount() - 6)
			else
				hCaster:RemoveModifierByName("modifier_fiery_heaven_indicator")
			end]]
		elseif hCaster:HasModifier("modifier_frigid_heaven_indicator") then 
			sCharmColor = "particles/custom/tamamo/charms_blue.vpcf"
			tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_blue_explosion.vpcf"
			tExtraData["sDebuffName"] = "modifier_tamamo_ice_debuff"
			tExtraData["sCharmAbility"] = "tamamo_frigid_heaven"

			--[[hModifier = hCaster:FindModifierByName("modifier_frigid_heaven_indicator")
			if hModifier:GetStackCount() > 6 then
				hModifier:SetStackCount(hModifier:GetStackCount() - 6)
			else
				hCaster:RemoveModifierByName("modifier_frigid_heaven_indicator")
			end]]
		elseif hCaster:HasModifier("modifier_gust_heaven_indicator") then
			sCharmColor = "particles/custom/tamamo/charms_green.vpcf"
			tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_green_explosion.vpcf"
			tExtraData["sDebuffName"] = "modifier_tamamo_wind_debuff"
			tExtraData["sCharmAbility"] = "tamamo_gust_heaven"

			--[[hModifier = hCaster:FindModifierByName("modifier_gust_heaven_indicator")
			if hModifier:GetStackCount() > 6 then
				hModifier:SetStackCount(hModifier:GetStackCount() - 6)
			else
				hCaster:RemoveModifierByName("modifier_gust_heaven_indicator")
			end]]
		elseif hCaster:HasModifier("modifier_void_heaven_indicator") then
			sCharmColor = "particles/custom/tamamo/charms_purple.vpcf"
			tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_purple_explosion.vpcf"
			--tExtraData["sDebuffName"] = "modifier_tamamo_ice_debuff"
			tExtraData["sCharmAbility"] = "tamamo_void_heaven"
		end
		
	    for i = 1, 6 do
	    	Timers:CreateTimer(0.1 * i, function()
	    		hCaster:EmitSound("Hero_Wisp.Spirits.Cast")
	    		local vPosition = RandomPointInCircle(hTargetLoc, self:GetAOERadius())
	        	local hDummy = CreateUnitByName("dummy_unit", vPosition, false, hCaster, hCaster, hCaster:GetTeamNumber())
			    hDummy:SetOrigin(vPosition)
			    hDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			    hDummy:AddNewModifier(hCaster, self, "modifier_kill", { Duration = 1.5 })
			    hDummy:SetAbsOrigin(GetGroundPosition(vPosition, hCaster))

			    local attach = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
			    if i%2 == 0 then
			    	attach = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
			    end

			    local projectile = {
			    	Target = hDummy,
					Source = hCaster,
					Ability = self,	
			        EffectName = sCharmColor,
			        iMoveSpeed = 1500,
					vSourceLoc= hCaster:GetAbsOrigin(),
					bDrawsOnMinimap = false,
			        bDodgeable = false,
			        bIsAttack = false,
			        iSourceAttachment = attach,
			        bVisibleToEnemies = true,
			        bReplaceExisting = false,
			        flExpireTime = GameRules:GetGameTime() + 3,
					bProvidesVision = false,
					ExtraData = tExtraData
			    }
			    ProjectileManager:CreateTrackingProjectile(projectile)

			    Timers:CreateTimer(6, function()
			        if hDummy then hDummy:RemoveSelf() end
			    end)
	    	end)
	    end
	end)
end

function tamamo_soul_stream:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	local hCaster = self:GetCaster()
	local fExplodeRadius = self:GetSpecialValueFor("explode_radius")
	local fDamage = self:GetSpecialValueFor("damage")
	local sExplosionColor = tData["sExplosionColor"] or "particles/custom/tamamo/charms_blue_explosion.vpcf"
	
	local hCharmDebuff = tData["sDebuffName"]
	local hCharmAbility = hCaster:FindAbilityByName(tData["sCharmAbility"])

	local fManaBurn = 25 + hCaster:GetIntellect() * 0.5

	if hCaster.IsSpiritTheftAcquired then
		fDamage = fDamage + fManaBurn
	end

	hTarget:EmitSound("Hero_Wisp.Spirits.Target")
	local explosionFx = ParticleManager:CreateParticle(sExplosionColor, PATTACH_ABSORIGIN_FOLLOW, nil)
	ParticleManager:SetParticleControl(explosionFx, 0, vLocation)

	if hCaster:HasModifier("modifier_fiery_heaven_indicator") then
		self:FireCharmProc(hTarget, vLocation, true)
	elseif hCaster:HasModifier("modifier_frigid_heaven_indicator") then
		self:IceCharmProc(hTarget, vLocation, true)
	elseif hCaster:HasModifier("modifier_gust_heaven_indicator") then
		self:WindCharmProc(hTarget, vLocation, true)
	elseif hCaster:HasModifier("modifier_void_heaven_indicator") then
		self:VoidCharmProc(hTarget, vLocation, true)
	end

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, fExplodeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for i = 1, #tEnemies do
		--[[if hCharmDebuff ~= nil and hCharmAbility ~= nil then
			tEnemies[i]:AddNewModifier(hCaster, hCharmAbility, hCharmDebuff, { Duration = hCharmAbility:GetSpecialValueFor("duration"), is_ss = true })
		end]]

		if hCaster.IsSpiritTheftAcquired then
			tEnemies[i]:SetMana(tEnemies[i]:GetMana() - fManaBurn)			
		end

		DoDamage(hCaster, tEnemies[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	if #tEnemies > 1 and hCaster.IsSpiritTheftAcquired then
		hCaster:GiveMana(fManaBurn)
	end
end

function tamamo_soul_stream:FireCharmProc(hTarget, vLocation, is_ss)
	local hCaster = self:GetCaster()
	local fExplodeRadius = self:GetSpecialValueFor("explode_radius")
	local fDamage = self:GetSpecialValueFor("damage")
	
	local hCharmDebuff = "modifier_tamamo_fire_debuff"
	local hCharmAbility = hCaster:FindAbilityByName("tamamo_fiery_heaven")

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, fExplodeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for i = 1, #tEnemies do
		if hCharmDebuff ~= nil and hCharmAbility ~= nil then
			tEnemies[i]:AddNewModifier(hCaster, hCharmAbility, hCharmDebuff, { Duration = hCharmAbility:GetSpecialValueFor("duration"), is_ss = is_ss })
		end
	end

	--[[local explodeFx = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
	ParticleManager:SetParticleControl( explodeFx, 0, hTarget:GetAbsOrigin())

	Timers:CreateTimer(1.2, function()
		ParticleManager:DestroyParticle(explodeFx, true)
		ParticleManager:ReleaseParticleIndex(explodeFx)
	   	return nil
	end)]]
	hTarget:EmitSound("Ability.LightStrikeArray")
	local explosion_fx = ParticleManager:CreateParticle("particles/custom/tamamo/combo/fire_explosion.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControl(explosion_fx, 0, hTarget:GetAbsOrigin())
		
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( explosion_fx, false )
		ParticleManager:ReleaseParticleIndex(explosion_fx)
	end)
end

function tamamo_soul_stream:IceCharmProc(hTarget, vLocation, is_ss)
	local hCaster = self:GetCaster()

	local hCharmDebuff = "modifier_tamamo_ice_debuff"
	local hCharmAbility = hCaster:FindAbilityByName("tamamo_frigid_heaven")

	local fDamage = hCharmAbility:GetSpecialValueFor("damage") + hCharmAbility:GetSpecialValueFor("int_ratio")*hCaster:GetIntellect()
	local fExplodeRadius = hCharmAbility:GetSpecialValueFor("radius")

	hTarget:EmitSound("Hero_Invoker.ColdSnap.Freeze")

	if is_ss then
		fDamage = fDamage/6
	end

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, fExplodeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for i = 1, #tEnemies do
		if not (tEnemies[i]:GetUnitName() == "iskander_infantry") then
			tEnemies[i]:AddNewModifier(hCaster, hCharmAbility, "modifier_tamamo_ice_debuff", {duration = hCharmAbility:GetSpecialValueFor("duration"), is_ss = is_ss})
		end
		DoDamage(hCaster, tEnemies[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, hCharmAbility, false)
	end
	local ParticleIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControl(ParticleIndex, 0, hTarget:GetAbsOrigin())
	ParticleManager:SetParticleControl(ParticleIndex, 1, Vector(fExplodeRadius, 1, fExplodeRadius))

	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle(ParticleIndex, true)
		ParticleManager:ReleaseParticleIndex(ParticleIndex)
	end)
end

function tamamo_soul_stream:WindCharmProc(hTarget, vLocation, is_ss)
	local hCaster = self:GetCaster()

	local hCharmDebuff = "modifier_tamamo_wind_debuff"
	local hCharmAbility = hCaster:FindAbilityByName("tamamo_gust_heaven")

	local fDamage = hCharmAbility:GetSpecialValueFor("damage") + hCharmAbility:GetSpecialValueFor("int_ratio")*hCaster:GetIntellect()
	local fExplodeRadius = hCharmAbility:GetSpecialValueFor("radius")

	if is_ss then
		fDamage = fDamage/6
	end

	local attacked_targets = {}

	local ParticleIndex = ParticleManager:CreateParticle("particles/tamamo/tamamo_lightning.vpcf", PATTACH_ABSORIGIN, hCaster)
	if not is_ss then
		ParticleManager:SetParticleControlEnt(ParticleIndex, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(ParticleIndex, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControl(ParticleIndex, 0, hTarget:GetAbsOrigin() + Vector(0, 0, 150))
		ParticleManager:SetParticleControl(ParticleIndex, 1, hTarget:GetAbsOrigin() + Vector(0, 0, 150))
	end

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(ParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(ParticleIndex)
	end)

	hTarget:EmitSound("Hero_Zuus.ArcLightning.Target")
	if not hTarget:IsMagicImmune() and not is_ss then
		DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_MAGICAL, 0, hCharmAbility, false)
	end

	attacked_targets[hTarget:entindex()] = true

	local curr_target = hTarget

	Timers:CreateTimer(FrameTime(), function()
		if hCaster and IsNotNull(hCaster) then
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), curr_target:GetAbsOrigin(), nil, fExplodeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
			for i = 1, #tEnemies do
				if not attacked_targets[tEnemies[i]:entindex()] and tEnemies[i]:CanBeSeenByAnyOpposingTeam() then
					if not (tEnemies[i]:GetUnitName() == "iskander_infantry") then
						local ParticleIndex2 = ParticleManager:CreateParticle("particles/tamamo/tamamo_lightning.vpcf", PATTACH_ABSORIGIN, curr_target)
						if is_ss and (curr_target == hTarget) then
							ParticleManager:SetParticleControl(ParticleIndex2, 0, hTarget:GetAbsOrigin() + Vector(0, 0, 150))
						else
							ParticleManager:SetParticleControlEnt(ParticleIndex2, 0, curr_target, PATTACH_POINT_FOLLOW, "attach_hitloc", curr_target:GetAbsOrigin(), true)
						end
						ParticleManager:SetParticleControlEnt(ParticleIndex2, 1, tEnemies[i], PATTACH_POINT_FOLLOW, "attach_hitloc", tEnemies[i]:GetAbsOrigin(), true)
						--ParticleManager:SetParticleControl(ParticleIndex2, 0, curr_target:GetAbsOrigin() + Vector(0, 0, 96))
						--ParticleManager:SetParticleControl(ParticleIndex2, 1, tEnemies[i]:GetAbsOrigin() + Vector(0, 0, 96))

						Timers:CreateTimer(1, function()
							ParticleManager:DestroyParticle(ParticleIndex2, false)
							ParticleManager:ReleaseParticleIndex(ParticleIndex2)
						end)
					end

					tEnemies[i]:EmitSound("Hero_Zuus.ArcLightning.Target")
					DoDamage(hCaster, tEnemies[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, hCharmAbility, false)
					attacked_targets[tEnemies[i]:entindex()] = true
					curr_target = tEnemies[i]
					return FrameTime()
				end
			end
		end
	end)
end

function tamamo_soul_stream:VoidCharmProc(hTarget, vLocation, is_ss)
	local hCaster = self:GetCaster()

	local hCharmAbility = hCaster:FindAbilityByName("tamamo_void_heaven")

	local fDamage = hCharmAbility:GetSpecialValueFor("damage") + hCharmAbility:GetSpecialValueFor("int_ratio")*hCaster:GetIntellect()

	if is_ss then
		fDamage = fDamage/6
	end

	local fExplodeRadius = self:GetSpecialValueFor("explode_radius")

	if is_ss then
		local ParticleIndex = ParticleManager:CreateParticle("particles/tamamo/tamamo_void_warp.vpcf", PATTACH_ABSORIGIN, hTarget)
		ParticleManager:SetParticleControl(ParticleIndex, 0, hTarget:GetAbsOrigin() + Vector(0, 0, 96))

		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(ParticleIndex, false)
			ParticleManager:ReleaseParticleIndex(ParticleIndex)
		end)

		local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, fExplodeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for i = 1, #tEnemies do
			if not tEnemies[i]:IsMagicImmune() then
				local diff = (tEnemies[i]:GetMaxHealth() - tEnemies[i]:GetHealth())/tEnemies[i]:GetMaxHealth()/2
				DoDamage(hCaster, tEnemies[i], fDamage*(diff + 1), DAMAGE_TYPE_MAGICAL, 0, hCharmAbility, false)
			end
		end
	else
		if not hTarget:IsMagicImmune() then
			local diff = (hTarget:GetMaxHealth() - hTarget:GetHealth())/hTarget:GetMaxHealth()/2
			DoDamage(hCaster, hTarget, fDamage*(diff + 1), DAMAGE_TYPE_MAGICAL, 0, hCharmAbility, false)
		end

		local ParticleIndex = ParticleManager:CreateParticle("particles/tamamo/tamamo_void_warp.vpcf", PATTACH_ABSORIGIN, hTarget)
		ParticleManager:SetParticleControlEnt(ParticleIndex, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)

		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(ParticleIndex, false)
			ParticleManager:ReleaseParticleIndex(ParticleIndex)
		end)
	end
end

-- Stacking buff 
function modifier_soulstream_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

if IsServer() then
	function modifier_soulstream_buff:OnCreated(args)
		self:SetStackCount(1)
	end

	function modifier_soulstream_buff:OnRefresh(args)
		self:SetStackCount(math.min((self:GetStackCount() or 0) + 1, 4))
	end
end

function modifier_soulstream_buff:GetModifierAttackSpeedBonus_Constant()
	return (self:GetStackCount() or 1) * self:GetAbility():GetSpecialValueFor("aspd_per_stack")
end

function modifier_soulstream_buff:GetModifierMoveSpeedBonus_Percentage()
	return (self:GetStackCount() or 1) * self:GetAbility():GetSpecialValueFor("mvsp_per_stack")
end

if IsServer() then 
	function modifier_soulstream_buff:OnAttackLanded(args)
		local hTarget = args.target
		local hCaster = args.attacker
		local soulstream_abil = hCaster:FindAbilityByName("tamamo_soul_stream")

		if hCaster:HasModifier("modifier_fiery_heaven_indicator") then

			soulstream_abil:FireCharmProc(hTarget, hTarget:GetAbsOrigin(), false)

		elseif hCaster:HasModifier("modifier_frigid_heaven_indicator") then

			soulstream_abil:IceCharmProc(hTarget, hTarget:GetAbsOrigin(), false)

		elseif hCaster:HasModifier("modifier_gust_heaven_indicator") then

			soulstream_abil:WindCharmProc(hTarget, hTarget:GetAbsOrigin(), false)

		elseif hCaster:HasModifier("modifier_void_heaven_indicator") then

			soulstream_abil:VoidCharmProc(hTarget, hTarget:GetAbsOrigin(), false)
			
		end
	end
end

-- Fire Charm Debuff
if IsServer() then
	function modifier_tamamo_fire_debuff:OnCreated(args)
		local hCaster = self:GetCaster()
		local hTarget = self:GetParent()
		self.is_ss = false
		if args.is_ss == 1 then
			self.is_ss = true
		end

		local fDamage = self:GetAbility():GetSpecialValueFor("damage") + self:GetAbility():GetSpecialValueFor("int_ratio")*hCaster:GetIntellect()
		if self.is_ss then
			fDamage = fDamage/6
		end
		if not hTarget:IsMagicImmune() then
			DoDamage(hCaster, hTarget, fDamage * 0.5, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end

		self:StartIntervalThink(0.5)
	end

	function modifier_tamamo_fire_debuff:OnRefresh(args)
	end

	function modifier_tamamo_fire_debuff:OnIntervalThink()
		local hCaster = self:GetCaster()
		local hTarget = self:GetParent()
		local fDamage = self:GetAbility():GetSpecialValueFor("damage") + self:GetAbility():GetSpecialValueFor("int_ratio")*hCaster:GetIntellect()
		if self.is_ss then
			fDamage = fDamage/6
		end
		if not hTarget:IsMagicImmune() then
			DoDamage(hCaster, hTarget, fDamage * 0.5, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end
	end
end

function modifier_tamamo_fire_debuff:IsDebuff()
	return true
end

function modifier_tamamo_fire_debuff:GetTexture()
	return "custom/tamamo_fiery_heaven"
end 

function modifier_tamamo_fire_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--Ice Charm Debuff
if IsServer() then
	function modifier_tamamo_ice_debuff:OnCreated(args)
		self.ParticleIndex = ParticleManager:CreateParticle("particles/custom/tamamo/frigid_heaven.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.ParticleIndex, 0, self:GetParent():GetAbsOrigin())
	end

	function modifier_tamamo_ice_debuff:OnRefresh(args)
	end

	function modifier_tamamo_ice_debuff:OnDestroy()
		ParticleManager:DestroyParticle(self.ParticleIndex, true)
		ParticleManager:ReleaseParticleIndex(self.ParticleIndex)
	end
end

function modifier_tamamo_ice_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_tamamo_ice_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_perc")
end

function modifier_tamamo_ice_debuff:IsDebuff()
	return true
end

function modifier_tamamo_ice_debuff:GetTexture()
	return "custom/tamamo_frigid_heaven"
end

--Wind Charm Debuff
if IsServer() then
	function modifier_tamamo_wind_debuff:OnCreated(args)
		self.ParticleIndex = ParticleManager:CreateParticle("particles/custom/tamamo/gust_heaven_static.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.ParticleIndex, 0, self:GetCaster():GetAbsOrigin())
		self:StartIntervalThink(0.5)
	end

	function modifier_tamamo_wind_debuff:OnRefresh(args)
	end

	function modifier_tamamo_wind_debuff:OnDestroy()		
		ParticleManager:DestroyParticle(self.ParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(self.ParticleIndex)
	end

	function modifier_tamamo_wind_debuff:OnIntervalThink()
		local hCaster = self:GetCaster()
		local hTarget = self:GetParent()
		local fZapAoe = self:GetAbility():GetSpecialValueFor("radius")
		local fDamage = self:GetAbility():GetSpecialValueFor("damage")

		DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		giveUnitDataDrivenModifier(hCaster, hTarget, "silenced", 1)

		local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, fZapAoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for i = 1, #tEnemies do	
			if tEnemies[i] ~= hTarget then
				DoDamage(hCaster, tEnemies[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				
				local iParticleIndex = ParticleManager:CreateParticle("particles/custom/tamamo/gust_heaven_arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
				ParticleManager:SetParticleControl(iParticleIndex, 0, hTarget:GetAbsOrigin())
				ParticleManager:SetParticleControl(iParticleIndex, 1, tEnemies[i]:GetAbsOrigin())

				giveUnitDataDrivenModifier(hCaster, tEnemies[i], "silenced", 0.25)
				tEnemies[i]:AddNewModifier(hTarget, self:GetAbility(), "modifier_tamamo_wind_particle", { Duration = 1,
																										  ParticleIndex = iParticleIndex })
				return
			end
		end	
	end
end

function modifier_tamamo_wind_debuff:IsDebuff()
	return true
end

function modifier_tamamo_wind_debuff:GetTexture()
	return "custom/tamamo_gust_heaven"
end

if IsServer() then
	function modifier_tamamo_wind_particle:OnCreated(args)
		self.ParticleIndex = args.ParticleIndex
	end

	function modifier_tamamo_wind_particle:OnDestroy()
		if self.ParticleIndex ~= nil then
			ParticleManager:DestroyParticle(self.ParticleIndex, true)
			ParticleManager:ReleaseParticleIndex(self.ParticleIndex)
		end
	end
end

function modifier_tamamo_wind_particle:IsHidden()
	return true
end
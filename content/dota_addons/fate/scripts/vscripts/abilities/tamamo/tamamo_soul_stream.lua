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
		fAddCost = hCaster:GetModifierStackCount("modifier_soulstream_buff", hCaster) * 50
	end

	return 100 + fAddCost
end

function tamamo_soul_stream:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function tamamo_soul_stream:OnUpgrade()
	local hCaster = self:GetCaster()

	hCaster:FindAbilityByName("tamamo_fiery_heaven"):SetLevel(self:GetLevel())
	hCaster:FindAbilityByName("tamamo_frigid_heaven"):SetLevel(self:GetLevel())
	hCaster:FindAbilityByName("tamamo_gust_heaven"):SetLevel(self:GetLevel())
end

function tamamo_soul_stream:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTargetLoc = self:GetCursorPosition()
	local hModifier

	hCaster:AddNewModifier(hCaster, self, "modifier_soulstream_buff", { Duration = self:GetSpecialValueFor("buff_dur")})

	local sCharmColor = "particles/custom/tamamo/charms_blue.vpcf" --default
	local tExtraData = { sExplosionColor = "particles/custom/tamamo/charms_blue_explosion.vpcf",
						 sCharmAbility = "tamamo_soul_stream" } -- default

	if hCaster:HasModifier("modifier_fiery_heaven_indicator") then
		sCharmColor = "particles/custom/tamamo/charms_red.vpcf"
		tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_red_explosion.vpcf"
		tExtraData["sDebuffName"] = "modifier_tamamo_fire_debuff"
		tExtraData["sCharmAbility"] = "tamamo_fiery_heaven"

		hModifier = hCaster:FindModifierByName("modifier_fiery_heaven_indicator")
		if hModifier:GetStackCount() > 6 then
			hModifier:SetStackCount(hModifier:GetStackCount() - 6)
		else
			hCaster:RemoveModifierByName("modifier_fiery_heaven_indicator")
		end
	elseif hCaster:HasModifier("modifier_frigid_heaven_indicator") then 
		sCharmColor = "particles/custom/tamamo/charms_purple.vpcf"
		tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_purple_explosion.vpcf"
		tExtraData["sDebuffName"] = "modifier_tamamo_ice_debuff"
		tExtraData["sCharmAbility"] = "tamamo_frigid_heaven"

		hModifier = hCaster:FindModifierByName("modifier_frigid_heaven_indicator")
		if hModifier:GetStackCount() > 6 then
			hModifier:SetStackCount(hModifier:GetStackCount() - 6)
		else
			hCaster:RemoveModifierByName("modifier_frigid_heaven_indicator")
		end
	elseif hCaster:HasModifier("modifier_gust_heaven_indicator") then
		sCharmColor = "particles/custom/tamamo/charms_green.vpcf"
		tExtraData["sExplosionColor"] = "particles/custom/tamamo/charms_green_explosion.vpcf"
		tExtraData["sDebuffName"] = "modifier_tamamo_wind_debuff"
		tExtraData["sCharmAbility"] = "tamamo_gust_heaven"

		hModifier = hCaster:FindModifierByName("modifier_gust_heaven_indicator")
		if hModifier:GetStackCount() > 6 then
			hModifier:SetStackCount(hModifier:GetStackCount() - 6)
		else
			hCaster:RemoveModifierByName("modifier_gust_heaven_indicator")
		end
	end
	
    for i = 1, 6 do
    	Timers:CreateTimer(0.1 * i, function()
    		hCaster:EmitSound("Hero_Wisp.Spirits.Cast")
    		local vPosition = RandomPointInCircle(hTargetLoc, self:GetAOERadius())
        	local hDummy = CreateUnitByName("dummy_unit", vPosition, false, hCaster, hCaster, hCaster:GetTeamNumber())
		    hDummy:SetOrigin(vPosition)
		    hDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		    hDummy:AddNewModifier(hCaster, self, "modifier_kill", { Duration = 1.5 })

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
		        bVisibleToEnemies = true,
		        bReplaceExisting = false,
		        flExpireTime = GameRules:GetGameTime() + 3,
				bProvidesVision = false,
				ExtraData = tExtraData
		    }
		    ProjectileManager:CreateTrackingProjectile(projectile)

		    Timers:CreateTimer(3, function()
		        if hDummy then hDummy:RemoveSelf() end
		    end)
    	end)
    end
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

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, fExplodeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for i = 1, #tEnemies do
		if hCharmDebuff ~= nil and hCharmAbility ~= nil then
			tEnemies[i]:AddNewModifier(hCaster, hCharmAbility, hCharmDebuff, { Duration = hCharmAbility:GetSpecialValueFor("duration") })
		end

		if hCaster.IsSpiritTheftAcquired then
			tEnemies[i]:SetMana(tEnemies[i]:GetMana() - fManaBurn)			
		end

		DoDamage(hCaster, tEnemies[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	if #tEnemies > 1 and hCaster.IsSpiritTheftAcquired then
		hCaster:GiveMana(fManaBurn)
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

-- Fire Charm Debuff
if IsServer() then
	function modifier_tamamo_fire_debuff:OnCreated(args)
		self:StartIntervalThink(0.25)
	end

	function modifier_tamamo_fire_debuff:OnRefresh(args)
	end

	function modifier_tamamo_fire_debuff:OnIntervalThink()
		local hCaster = self:GetCaster()
		local hTarget = self:GetParent()
		local fDamage = self:GetAbility():GetSpecialValueFor("damage") * 0.25
		DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
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

	function modifier_tamamo_ice_debuff:OnRefresh(arg)
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
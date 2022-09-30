LinkLuaModifier("modifier_mordred_mmb", "abilities/mordred/mordred_mmb_lightning", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mordred_mmb_cooldown", "abilities/mordred/mordred_mmb_lightning", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mordred_mmb_checker", "abilities/mordred/mordred_mmb_lightning", LUA_MODIFIER_MOTION_NONE)

mordred_mmb_lightning = class({})

function mordred_mmb_lightning:OnSpellStart()
	local caster = self:GetCaster()
	local nBeams = 0
	if caster:IsAlive() then
		nBeams = 0
		Timers:CreateTimer(function()
			if nBeams == 20 then return end
			self:FireSingleParticle()
			nBeams = nBeams + 1
			return 0.04
		end)
	end
	EmitGlobalSound("mordred_combo")
	caster:AddNewModifier(caster, self, "modifier_mordred_mmb_cooldown", {duration = self:GetCooldown(1)})

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))

	Timers:CreateTimer(3.46, function()
		EmitGlobalSound("mordred_clarent")
	end)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.0)

	StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})

	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * 2000)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer(1.0, function()
		if caster:IsAlive() then
			caster:AddNewModifier(caster, self, "modifier_mordred_mmb", {duration = 4})
		end
	end)

	Timers:CreateTimer("mordred_rush", {
		endTime = 1.0,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		caster:AddNewModifier(caster, self, "modifier_mordred_mmb_checker", {duration = 3})
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		caster:AddNewModifier(caster, self, "modifier_mordred_mmb_checker", {duration = 3})
		Timers:RemoveTimer("mordred_rush")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end

function mordred_mmb_lightning:FireSingleParticle()
	local caster = self:GetCaster()
	local casterFacing = caster:GetForwardVector()
	local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	local tPillarTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("width")/2, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for j = 1, #tPillarTargets do
		if not tPillarTargets[j]:HasModifier("modifier_mordred_mmb_checker") then
			DoDamage(caster, tPillarTargets[j], caster:FindAbilityByName("mordred_rush"):GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
			tPillarTargets[j]:AddNewModifier(caster, self, "modifier_mordred_mmb_checker", {duration = 1})
		end
	end
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	dummy:SetForwardVector(casterFacing)
	Timers:CreateTimer( function()
			if IsValidEntity(dummy) and not caster:HasModifier("modifier_mordred_mmb_checker") then
				local newLoc = dummy:GetAbsOrigin() + 2000 * 0.2 * casterFacing
				dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
				-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.Width, true, 0.15)
				return 0.2--0.015
			else
				return nil
			end
		end
	)
	
	local excalFxIndex = ParticleManager:CreateParticle("particles/custom/mordred/max_excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
	--local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			
	Timers:CreateTimer(0.57, function()
		ParticleManager:DestroyParticle( excalFxIndex, false )
		ParticleManager:ReleaseParticleIndex( excalFxIndex )
		Timers:CreateTimer( 0.1, function()
				dummy:RemoveSelf()
				return nil
			end
		)
		return nil
	end)
end

modifier_mordred_mmb = class({})

function modifier_mordred_mmb:IsHidden() return true end
function modifier_mordred_mmb:RemoveOnDeath() return true end

function modifier_mordred_mmb:OnCreated()
	self.parent = self:GetParent()
	if IsServer() then
		giveUnitDataDrivenModifier(self.parent, self.parent, "pause_sealdisabled", 4.0)
	end
	StartAnimation(self.parent, {duration=4.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.1})
	self.j = 0
	self.ChargeTime = 0
	self.interval = 0.1
	self.excalFxIndex = ParticleManager:CreateParticle("particles/custom/mordred/max_excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	if IsServer() then
		self:StartIntervalThink(self.interval)
	end
end

function modifier_mordred_mmb:FireSingleParticleKappa(i)
	local caster = self:GetParent()
	local casterFacing = caster:GetForwardVector()
	local vPillarLoc = caster:GetAbsOrigin() + RandomVector(self:GetAbility():GetSpecialValueFor("blast_radius") * 1/10*i)
	local dummy = CreateUnitByName("dummy_unit", vPillarLoc, false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	dummy:SetForwardVector((vPillarLoc - caster:GetAbsOrigin()):Normalized())
	
	local excalFxIndex = ParticleManager:CreateParticle("particles/custom/mordred/max_excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
	--local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			
	Timers:CreateTimer(0.57, function()
		ParticleManager:DestroyParticle( excalFxIndex, false )
		ParticleManager:ReleaseParticleIndex( excalFxIndex )
		Timers:CreateTimer( 0.1, function()
				dummy:RemoveSelf()
				return nil
			end
		)
		return nil
	end)
end

function modifier_mordred_mmb:OnIntervalThink()
	self.ChargeTime = self.ChargeTime + self.interval
	self.j = self.j+1
	if self.j == 10 then self.j = 1 end
	self:FireSingleParticleKappa(self.j)

	--[[local iPillarFx = ParticleManager:CreateParticle("particles/custom/mordred/purge_the_unjust/ruler_purge_the_unjust_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( iPillarFx, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl( iPillarFx, 1, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl( iPillarFx, 2, self.parent:GetAbsOrigin())

	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(iPillarFx, false)
		ParticleManager:ReleaseParticleIndex(iPillarFx)
	end)]]

	for i = 1,7 do
		self:KappaBride(i)
	end
end

function modifier_mordred_mmb:KappaBride(i)
	local vPillarLoc = self.parent:GetAbsOrigin() + RandomVector(self:GetAbility():GetSpecialValueFor("blast_radius") * 1/7*i)

	local tPillarTargets = FindUnitsInRadius(self.parent:GetTeam(), vPillarLoc, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for j = 1, #tPillarTargets do
		DoDamage(self.parent, tPillarTargets[j], self:GetAbility():GetSpecialValueFor("damage")*self.ChargeTime/4, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end

	--[[local iPillarFx = ParticleManager:CreateParticle("particles/custom/mordred/purge_the_unjust/ruler_purge_the_unjust_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( iPillarFx, 0, vPillarLoc)
	ParticleManager:SetParticleControl( iPillarFx, 1, vPillarLoc)
	ParticleManager:SetParticleControl( iPillarFx, 2, vPillarLoc)

	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(iPillarFx, false)
		ParticleManager:ReleaseParticleIndex(iPillarFx)
	end)]]
	local particle = ParticleManager:CreateParticle("particles/custom/mordred/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, self.parent)
    local target_point = vPillarLoc
    ParticleManager:SetParticleControl(particle, 0, Vector(target_point.x, target_point.y, target_point.z))
    ParticleManager:SetParticleControl(particle, 1, Vector(target_point.x, target_point.y, 2000))
    ParticleManager:SetParticleControl(particle, 2, Vector(target_point.x, target_point.y, target_point.z))
end

function modifier_mordred_mmb:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle( self.excalFxIndex, false )
		ParticleManager:ReleaseParticleIndex( self.excalFxIndex )
		local targets = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("blast_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local dmg = self.parent:GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_damage")/100*self.ChargeTime/4

		for k,v in pairs(targets) do
			local dist = (v:GetAbsOrigin() - self.parent:GetAbsOrigin()):Length2D() 
			if dist <= 700 then
				finaldmg = dmg
			elseif dist > 700 and dist <= 1300 then
				finaldmg = dmg*0.8
			elseif dist > 1300 and dist <= 2000 then
				finaldmg = dmg*0.6
			end

	   	 	DoDamage(self.parent, v, finaldmg , DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end

		local YellowScreenFx = ParticleManager:CreateParticle("particles/custom/screen_red_splash.vpcf", PATTACH_EYES_FOLLOW, self.parent)
		ScreenShake(self.parent:GetAbsOrigin(), 7, 2.0, 2, 10000, 0, true)
			
    	Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( YellowScreenFx, false )
		end)
	end
end

modifier_mordred_mmb_checker = class({})

function modifier_mordred_mmb_checker:IsHidden() return true end

modifier_mordred_mmb_cooldown = class({})

function modifier_mordred_mmb_cooldown:GetTexture()
	return "custom/mordred/mordred_max_mana_burst"
end

function modifier_mordred_mmb_cooldown:IsHidden()
	return false 
end

function modifier_mordred_mmb_cooldown:RemoveOnDeath()
	return false
end

function modifier_mordred_mmb_cooldown:IsDebuff()
	return true 
end

function modifier_mordred_mmb_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
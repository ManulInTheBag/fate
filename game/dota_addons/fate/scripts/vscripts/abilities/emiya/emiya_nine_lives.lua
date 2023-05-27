emiya_nine_lives = class({})

LinkLuaModifier("modifier_emiya_nine_lives", "abilities/emiya/emiya_nine_lives", LUA_MODIFIER_MOTION_NONE)

function emiya_nine_lives:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function emiya_nine_lives:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RAZE_3, rate=0.2})
    self.swordfx_left = ParticleManager:CreateParticle("particles/emiya/emiya_left_sword_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlEnt(self.swordfx_left, 0, caster, PATTACH_POINT_FOLLOW, "sword_left", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.swordfx_left, 1, caster, PATTACH_POINT_FOLLOW, "sword_left_end_overedge", Vector(0,0,0), true)
    self.swordfx_right = ParticleManager:CreateParticle("particles/emiya/emiya_right_sword_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlEnt(self.swordfx_right, 0, caster, PATTACH_POINT_FOLLOW, "sword_right", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.swordfx_right, 1, caster, PATTACH_POINT_FOLLOW, "sword_right_end_overedge", Vector(0,0,0), true)
	caster:SetBodygroup(0,3)
	Timers:CreateTimer(4, function()  
		if self.swordfx_left ~= nil and self.swordfx_right ~= nil then
			ParticleManager:DestroyParticle( self.swordfx_left, true)
			ParticleManager:ReleaseParticleIndex( self.swordfx_left)
			ParticleManager:DestroyParticle( self.swordfx_right, true)
			ParticleManager:ReleaseParticleIndex( self.swordfx_right)
		end
	end)
 

  
 
return
end

function emiya_nine_lives:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
	caster:SetBodygroup(0,1)
	if self.swordfx_left ~= nil and self.swordfx_right ~= nil then
		ParticleManager:DestroyParticle( self.swordfx_left, true)
		ParticleManager:ReleaseParticleIndex( self.swordfx_left)
		ParticleManager:DestroyParticle( self.swordfx_right, true)
		ParticleManager:ReleaseParticleIndex( self.swordfx_right)
	end
end

 

function emiya_nine_lives:OnSpellStart()
	local caster = self:GetCaster()
	local casterName = caster:GetName()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local berserker = Physics:Unit(caster)
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()*2
	local forward = (targetPoint - origin):Normalized() * distance
	local time = 0.5


	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector()*distance)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 2.1) --change to sealdisabled to return revoke here, if you want
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")
	caster:EmitSound("Archer.NineLives")
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_RAZE_3, rate=2.0})

	caster.NineTimer = Timers:CreateTimer(time, function()
		self:StartNineLives()
	end)

end

function emiya_nine_lives:StartNineLives()
	local caster = self:GetCaster()
	local time = 0
	Timers:CreateTimer(time, function()
		caster:OnPreBounce(nil)
		caster:OnPhysicsFrame(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		Timers:RemoveTimer(caster.NineTimer)
		caster.NineTimer = nil
	end)

	if caster:IsAlive() then
		self:NineLivesHits()
		return 
	end

	return
end

function emiya_nine_lives:NineLivesHits()
	local caster = self:GetCaster()
	local bonus_damage = 0--caster:GetIntellect()

	local casterInitOrigin = caster:GetAbsOrigin() 

	caster:AddNewModifier(caster, self, "modifier_emiya_nine_lives", { Duration = 3,
																 SmallDamage = self:GetSpecialValueFor("damage")+ (caster.IsProjectionAcquired and caster:GetStrength()*0.5 or 0),
																 LargeDamage = self:GetSpecialValueFor("damage_lasthit")+ (caster.IsProjectionAcquired and caster:GetStrength()*1.5 or 0),
																 SmallRadius = self:GetSpecialValueFor("radius"),
																 LargeRadius = self:GetSpecialValueFor("radius_lasthit")})
end


modifier_emiya_nine_lives = class({})

function modifier_emiya_nine_lives:OnCreated(args)
	if IsServer() then
		self.HitNumber = 1
		self.SmallDamage = args.SmallDamage
		self.LargeDamage = args.LargeDamage
		self.SmallRadius = args.SmallRadius
		self.LargeRadius = args.LargeRadius
		self:StartIntervalThink(0.2)
		StartAnimation(self:GetParent(), {duration = 1.8, activity=ACT_DOTA_WHIRLING_AXES_RANGED, rate = 5})
	end
end

function modifier_emiya_nine_lives:OnIntervalThink()
	local caster = self:GetParent()


	if self.HitNumber < 9 then
	
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self.SmallRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)

		for k,v in pairs(targets) do
			DoDamage(caster, v, self.SmallDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			giveUnitDataDrivenModifier(caster, v, "rooted", 0.3)
			if caster.IsProjectionAcquired then 	giveUnitDataDrivenModifier(caster, v, "locked", 0.3) end
			v:EmitSound("Hero_Juggernaut.OmniSlash.Damage")	
		end

 
		self.HitNumber = self.HitNumber + 1
	elseif self.HitNumber == 9 then
 
		 
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 1500, 0, true)			
		
		local lasthitTargets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self.LargeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 1, false)
		for k,v in pairs(lasthitTargets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, self.LargeDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				if caster.IsProjectionAcquired then 	giveUnitDataDrivenModifier(caster, v, "rooted", 0.3) end
				v:EmitSound("Hero_Juggernaut.OmniSlash.Damage")	
				v:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", { Duration = 1 })
				--giveUnitDataDrivenModifier(caster, v, "stunned", 1.5)			

				if not IsKnockbackImmune(v) then
					local pushback = Physics:Unit(v)
					v:PreventDI()
					v:SetPhysicsFriction(0)
					v:SetPhysicsVelocity((v:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized() * 300)
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
		if(caster.IsUBWActive ) then
			caster:SetBodygroup(0,1)
		end
		ParticleManager:DestroyParticle( self:GetAbility().swordfx_left, true)
		ParticleManager:ReleaseParticleIndex(  self:GetAbility().swordfx_left)
		ParticleManager:DestroyParticle(  self:GetAbility().swordfx_right, true)
		ParticleManager:ReleaseParticleIndex(   self:GetAbility().swordfx_right)
 		self:Destroy()
	end
end

function modifier_emiya_nine_lives:IsHidden()
	return true
end

function modifier_emiya_nine_lives:RemoveOnDeath()
	return true
end
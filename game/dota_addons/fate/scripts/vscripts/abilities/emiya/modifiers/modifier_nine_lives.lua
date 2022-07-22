modifier_nine_lives = class({})

function modifier_nine_lives:OnCreated(args)
	if IsServer() then
		self.HitNumber = 1
		self.SmallDamage = args.SmallDamage
		self.LargeDamage = args.LargeDamage
		self.SmallRadius = args.SmallRadius
		self.LargeRadius = args.LargeRadius
		self:StartIntervalThink(0.15)
	end
end

function modifier_nine_lives:OnIntervalThink()
	local caster = self:GetParent()
	local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)

	if self.HitNumber % 2 == 0 then
		StartAnimation(caster, { duration=0.1, activity=ACT_DOTA_ATTACK, rate=5})
	else
		StartAnimation(caster, { duration=0.1, activity=ACT_DOTA_ATTACK2, rate=5})
	end

	if self.HitNumber < 9 then
		caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact") 		
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self.LargeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)

		for k,v in pairs(targets) do
			DoDamage(caster, v, self.SmallDamage, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
			--v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.5 })
			--giveUnitDataDrivenModifier(caster, v, "stunned", 0.5)
		end

		ParticleManager:SetParticleControl(particle, 2, Vector(1,1,self.SmallRadius))
		ParticleManager:SetParticleControl(particle, 3, Vector(self.SmallRadius / 350,1,1))
		self.HitNumber = self.HitNumber + 1
	elseif self.HitNumber == 9 then
		caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
		caster:EmitSound("emiya_owarida")
		caster:RemoveModifierByName("pause_sealdisabled") 
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 1500, 0, true)			
		
		local lasthitTargets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self.LargeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 1, false)
		for k,v in pairs(lasthitTargets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, self.LargeDamage, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
				if caster.IsProjectionImproved then 
					v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 2 })
					--giveUnitDataDrivenModifier(caster, v, "stunned", 2)
				else
					v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 1.5 })
					--giveUnitDataDrivenModifier(caster, v, "stunned", 1)
				end	

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
		
		--caster:EmitSound("Archer.NineFinish") 

		ParticleManager:SetParticleControl(particle, 2, Vector(1,1,self.LargeRadius))
		ParticleManager:SetParticleControl(particle, 3, Vector(self.LargeRadius / 350,1,1))
		ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/last_hit.vpcf", PATTACH_ABSORIGIN, caster)
		
		self:Destroy()
	end
end

function modifier_nine_lives:IsHidden()
	return true
end

function modifier_nine_lives:RemoveOnDeath()
	return true
end
modifier_lu_bu_god_force = class({})

function modifier_lu_bu_god_force:OnCreated(args)
	if IsServer() then
		self.HitNumber = 1
		self.SmallDamage = args.SmallDamage
		self.LargeDamage = args.LargeDamage
		self.SmallRadius = args.SmallRadius
		self.LargeRadius = args.LargeRadius
		self:NormalHit()
		self:StartIntervalThink(0.5)
	end
		
	local caster = self:GetParent()
end

function modifier_lu_bu_god_force:NormalHit()
	local caster = self:GetParent()
	local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)
		--print("hit " .. self.HitNumber)
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self.LargeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)

		for k,v in pairs(targets) do
			DoDamage(caster, v, self.SmallDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.2 })
			--giveUnitDataDrivenModifier(caster, v, "stunned", 0.5)
		end

		ParticleManager:SetParticleControl(particle, 2, Vector(1,1,self.SmallRadius))
		ParticleManager:SetParticleControl(particle, 3, Vector(self.SmallRadius / 350,1,1))

end

function modifier_lu_bu_god_force:OnIntervalThink()
	local caster = self:GetParent()
	local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)

	if self.HitNumber < 4 then
		self:NormalHit()
		self.HitNumber = self.HitNumber + 1
	elseif self.HitNumber == 4 then
		--print("final hit")
		caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
		caster:RemoveModifierByName("pause_sealdisabled") 
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 1500, 0, true)			
		
		local lasthitTargets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self.LargeRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 1, false)
		for k,v in pairs(lasthitTargets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, self.LargeDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				
				v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.5 })
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

		ParticleManager:SetParticleControl(particle, 2, Vector(1,1,self.LargeRadius))
		ParticleManager:SetParticleControl(particle, 3, Vector(self.LargeRadius / 350,1,1))
		ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/last_hit.vpcf", PATTACH_ABSORIGIN, caster)
		self:Destroy()
	end
end

function modifier_lu_bu_god_force:IsHidden()
	return true
end

function modifier_lu_bu_god_force:RemoveOnDeath()
	return true
end

function modifier_lu_bu_god_force:PlayEffects1( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_normal.vpcf"
	local sound_cast = "Hero_Mars.Shield.Cast"
	if not caught then
		local sound_cast = "Hero_Mars.Shield.Cast.Small"
	end

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_lu_bu_god_force:PlayEffects2( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_ult.vpcf"
	local sound_cast = "Hero_Mars.Shield.Cast"
	if not caught then
		local sound_cast = "Hero_Mars.Shield.Cast.Small"
	end

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end
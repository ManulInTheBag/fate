LinkLuaModifier("modifier_arcueid_you", "abilities/arcueid/arcueid_you", LUA_MODIFIER_MOTION_NONE)

arcueid_you = class({})

function arcueid_you:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	
	caster:AddNewModifier(caster, self, "modifier_arcueid_you", {duration = 1.7})
	--caster:EmitSound("arcueid_ult_1")
	StartAnimation(caster, {duration=1.7, activity=ACT_DOTA_CAST_ABILITY_6, rate=1.0})
end

--[[function arcueid_you:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("arcueid_ult_1")
    return true
end

function arcueid_you:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("arcueid_ult_1")
end]]

modifier_arcueid_you = class({})

function modifier_arcueid_you:IsHidden() return true end
function modifier_arcueid_you:IsDebuff() return false end
function modifier_arcueid_you:RemoveOnDeath() return true end

function modifier_arcueid_you:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.damage = self.ability:GetSpecialValueFor("damage")
		self.speed = self.ability:GetSpecialValueFor("speed")

		self.hp = self.caster:GetHealth()

		self.z = 0

		self:StartIntervalThink(FrameTime())
		self.tick = 0
	end
end

function modifier_arcueid_you:OnIntervalThink()
	if IsServer() then
		self.hp = self.caster:GetHealth()
		local caster = self.caster
		local collide_damage = self.ability:GetSpecialValueFor("collide_damage")
		if caster.MonstrousStrengthAcquired then
			collide_damage = collide_damage + caster:GetStrength()*self.ability:GetSpecialValueFor("collide_mult")
		end
		self.tick = self.tick + 1
		local vector = caster:GetForwardVector()
		vector.z = 0
		local target = caster:GetAbsOrigin() + vector*self.speed*FrameTime()
		if (self.tick >= 34) and (self.tick <= 41) then
			self.z = self.z + 14*2
		end
		if (self.tick >= 42) and (self.tick <= 48) then
			self.z = self.z - 16*2
		end
		if GridNav:IsTraversable(target) and (not GridNav:IsBlocked(target)) then
			caster:SetAbsOrigin(GetGroundPosition(target, caster) + Vector(0, 0, self.z))
		end

		if (self.tick == 5) or (self.tick == 15) or (self.tick == 23) or (self.tick == 33) then
			if self.tick == 5 then
				caster:EmitSound("arcueid_ult_first")
			end
			if self.tick == 15 then
				caster:EmitSound("arcueid_ult_2")
			end
			if self.tick == 33 then
				caster:EmitSound("arcueid_ult_3")
			end
			caster:EmitSound("arcueid_swing")
			--[[local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle, 2, Vector(1,1,350))
			ParticleManager:SetParticleControl(particle, 3, Vector(350 / 350,1,1))]]
			local slash_fx = ParticleManager:CreateParticle("particles/arcueid/juggernaut_blade_fury_other.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
            ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
            ParticleManager:SetParticleControl(slash_fx, 5, Vector(300, 1, 1))
            if (self.tick == 5) or (self.tick == 15) then
            	ParticleManager:SetParticleControl(slash_fx, 10, Vector(0, 0, 0))
            elseif (self.tick == 23) then
            	ParticleManager:SetParticleControl(slash_fx, 10, Vector(180, 0, 0))
            elseif (self.tick == 33) then
            	ParticleManager:SetParticleControl(slash_fx, 10, Vector(90, 0, 0))
            end

			--caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact") 
			local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        350,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)
			for _, target in pairs(enemies) do
				--[[local origin_diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
				local origin_diff_norm = origin_diff:Normalized()
				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then]]
					--[[target:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = 0.25})
					caster:FindAbilityByName("arcueid_impulses"):Pepeg()
					local knockback = { should_stun = 0,
		                            knockback_duration = FrameTime()*5,
		                            duration = FrameTime()*5,
		                            knockback_distance = self.speed*FrameTime()*10,
		                            knockback_height = 0 or 0,
		                            center_x = caster:GetAbsOrigin().x,
		                            center_y = caster:GetAbsOrigin().y,
		                            center_z = caster:GetAbsOrigin().z }
		            target:RemoveModifierByName("modifier_knockback")

		            target:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)]]

		            if not IsKnockbackImmune(target) and (self:GetAbility():GetAutoCastState() == true) then
			            local casterfacing = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
						local pushTarget = Physics:Unit(target)
						local casterOrigin = caster:GetAbsOrigin()
						local initialUnitOrigin = target:GetAbsOrigin()
						target:PreventDI()
						target:SetPhysicsFriction(0)
						target:SetPhysicsVelocity(casterfacing:Normalized() * self.speed*2)
						target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
					    target:OnPhysicsFrame(function(unit) 
							local unitOrigin = unit:GetAbsOrigin()
							local diff = unitOrigin - initialUnitOrigin
							local n_diff = diff:Normalized()
							unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
							if diff:Length() > self.speed*FrameTime()*10 then
								unit:PreventDI(false)
								unit:SetPhysicsVelocity(Vector(0,0,0))
								unit:OnPhysicsFrame(nil)
								FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
							end
						end)	
						target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
							unit:SetBounceMultiplier(0)
							unit:PreventDI(false)
							unit:SetPhysicsVelocity(Vector(0,0,0))
							giveUnitDataDrivenModifier(caster, target, "stunned", self.ability:GetSpecialValueFor("collide_stun_duration"))
							target:EmitSound("Hero_EarthShaker.Fissure")
							DoDamage(caster, target, collide_damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)	
						end)
					end

					caster:FindAbilityByName("arcueid_impulses"):Pepeg(target)

		            for i = 0,2 do
		            	Timers:CreateTimer(FrameTime()*i*2, function()
		            		DoDamage(caster, target, self.damage/3, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
		            		if (i == 0) or (not target:HasModifier("modifier_master_intervention")) then
		            			--target:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = 0.25})
		            		end
		            		EmitSoundOn("arcueid_hit", target)
	                	end)
	                end
	            --end
			end
		end
		if (self.tick == 48) then
			caster:EmitSound("arcueid_ult_4")
			
			local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle, 2, Vector(1,1,450))
			ParticleManager:SetParticleControl(particle, 3, Vector(450 / 350,1,1))
			ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/last_hit.vpcf", PATTACH_ABSORIGIN, caster)

			caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
			local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        450,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)
			for _, target in pairs(enemies) do
				--local origin_diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
				--local origin_diff_norm = origin_diff:Normalized()
				if not IsKnockbackImmune(target) then
					local casterfacing = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
					local pushTarget = Physics:Unit(target)
					local casterOrigin = caster:GetAbsOrigin()
					local initialUnitOrigin = target:GetAbsOrigin()
					target:PreventDI()
					target:SetPhysicsFriction(0)
					target:SetPhysicsVelocity(casterfacing:Normalized() * self.speed*2)
					target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
				    target:OnPhysicsFrame(function(unit) 
						local unitOrigin = unit:GetAbsOrigin()
						local diff = unitOrigin - initialUnitOrigin
						local n_diff = diff:Normalized()
						unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
						if diff:Length() > 300 then
							unit:PreventDI(false)
							unit:SetPhysicsVelocity(Vector(0,0,0))
							unit:OnPhysicsFrame(nil)
							FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
						end
					end)	
					target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
						unit:SetBounceMultiplier(0)
						unit:PreventDI(false)
						unit:SetPhysicsVelocity(Vector(0,0,0))
						giveUnitDataDrivenModifier(caster, target, "stunned", self.ability:GetSpecialValueFor("collide_stun_duration"))
						target:EmitSound("Hero_EarthShaker.Fissure")
						DoDamage(caster, target, collide_damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)	
					end)
				end
				--if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					DoDamage(caster, target, self.ability:GetSpecialValueFor("damage_last"), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
					target:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = self.ability:GetSpecialValueFor("stun_duration")})
					caster:FindAbilityByName("arcueid_impulses"):Pepeg(target)
				--end
			end
		end
	end
end

function modifier_arcueid_you:CheckState()
	return {  [MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_SILENCED] = true, 
			[MODIFIER_STATE_MUTED] = true,
			[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_arcueid_you:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE}
end

function modifier_arcueid_you:GetModifierTurnRate_Percentage()
	return -50
end

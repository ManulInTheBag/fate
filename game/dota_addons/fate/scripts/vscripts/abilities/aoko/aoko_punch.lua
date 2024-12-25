aoko_punch = class({})

function aoko_punch:OnSpellStart()
	local caster = self:GetCaster()

	StartAnimation(caster, {duration=0.20, activity=ACT_SCRIPT_CUSTOM_5, rate=1.0})

	local enemies = FATE_FindUnitsInLine(
								        caster:GetTeamNumber(),
								        caster:GetAbsOrigin(),
								        caster:GetAbsOrigin() + caster:GetForwardVector()*350,
								        100,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_HERO,
										DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
										FIND_CLOSEST
    								)

    EmitSoundOn("jtr_slash", caster)

    if caster and IsValidEntity(caster) and enemies and #enemies>0 then
	    for _, target in pairs(enemies) do
		    target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })

		    local groundFx = ParticleManager:CreateParticle( "particles/aoko/aoko_blast.vpcf", PATTACH_ABSORIGIN, caster )
			--ParticleManager:SetParticleControl( groundFx, 0, caster:GetForwardVector())
			ParticleManager:SetParticleControl( groundFx, 5, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))

			if not IsKnockbackImmune(target) then
				local casterfacing = caster:GetForwardVector()
				local pushTarget = Physics:Unit(target)
				local casterOrigin = caster:GetAbsOrigin()
				local initialUnitOrigin = target:GetAbsOrigin()
				target:PreventDI()
				target:SetPhysicsFriction(0)
				target:SetPhysicsVelocity(casterfacing:Normalized() * 1000)
				target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
				target:OnPhysicsFrame(function(unit) 
					local unitOrigin = unit:GetAbsOrigin()
					local diff = unitOrigin - initialUnitOrigin
					local n_diff = diff:Normalized()
					unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
					if diff:Length() > 10 then
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
					--[[if not target:IsMagicImmune() then
						giveUnitDataDrivenModifier(caster, target, "stunned", ability:GetSpecialValueFor("stun_duration"))
						target:EmitSound("Hero_EarthShaker.Fissure")
						DoDamage(caster, target, self.collide_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
					end]]
				end)
			end
	    end
	end
end
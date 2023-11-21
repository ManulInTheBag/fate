nanaya_dashf = class({})

function nanaya_dashf:OnSpellStart()
	local caster = self:GetCaster()

	ProjectileManager:ProjectileDodge(caster)

	local point = self:GetCursorPosition()
	if point == caster:GetAbsOrigin() then
		point = caster:GetAbsOrigin() + caster:GetForwardVector()
	end
	
	local casterabs = caster:GetAbsOrigin()
	local direction = GetDirection(point, caster)
	caster:SetForwardVector(direction)
	caster:EmitSound("nanaya.jumpforward")
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
			
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)

	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, GetGroundPosition(caster:GetAbsOrigin()+ caster:GetForwardVector()*-250, nil))
	ParticleManager:SetParticleControl(jump2, 4, caster:GetAbsOrigin())

		local knockback = { should_stun = false,
		                                knockback_duration = 0.05,
		                                duration = 0.05,
		                                knockback_distance = -900,
		                                knockback_height = 0,
		                                center_x = point.x,
		                                center_y = point.y,
		                                center_z = caster:GetAbsOrigin().z }
										
										caster:AddNewModifier(caster, self, "modifier_knockback", knockback)
										
										
										local qdProjectile = 
	        {
	            Ability = self,
	            EffectName = nil,
	            --iMoveSpeed = 90,
	            vSpawnOrigin = caster:GetOrigin(),
	            fDistance =  900,
	            fStartRadius = 100,
	            fEndRadius = 100,
	            Source = caster,
	            bHasFrontalCone = true,
	            bReplaceExisting = true,
	            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	            iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	            fExpireTime = GameRules:GetGameTime() + 0.4,
	            bDeleteOnHit = false,
	            vVelocity = direction * 9000, 
	        }
			local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
										
										
										local hit = ParticleManager:CreateParticle("particles/test_partcheckfinal.vpcf", PATTACH_CUSTOMORIGIN, caster)
										ParticleManager:SetParticleControl(hit, 3, GetGroundPosition(caster:GetAbsOrigin()-caster:GetForwardVector()*200, nil)) 
	ParticleManager:SetParticleControl(hit, 5, GetGroundPosition(caster:GetAbsOrigin()+caster:GetForwardVector()*1200, nil)) 
										
	local sAbil1 = caster:GetAbilityByIndex(0)
	
	if sAbil1:GetAbilityName() == "nanaya_dashf" then
		caster:SwapAbilities("nanaya_dashf_return", "nanaya_dashf", true, false)
	end
	
	nanaya_return = casterabs
	
	Timers:CreateTimer(0.6, function()
	   	local sAbil2 = caster:GetAbilityByIndex(0)
		if sAbil2:GetAbilityName() == "nanaya_dashf" or sAbil2:GetAbilityName() == "nanaya_dashf_return" then
			caster:SwapAbilities("nanaya_dashf", "nanaya_dashf_return", true, false)
		end
	end)
end

function nanaya_dashf:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	local caster = self:GetCaster()
	if hTarget == nil then return end
	
	local dmg = self:GetSpecialValueFor("dmg") + math.floor(self:GetCaster():GetAgility()*self:GetSpecialValueFor("agi_modifier") )

	hTarget:EmitSound("nanaya.slash")
	--hTarget:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.5 })
	ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, hTarget)
	DoDamage(caster, hTarget, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
end

nanaya_dashf_return = class({})

function nanaya_dashf_return:OnSpellStart()
	local caster = self:GetCaster()

    FindClearSpaceForUnit(caster, nanaya_return , true) 
end
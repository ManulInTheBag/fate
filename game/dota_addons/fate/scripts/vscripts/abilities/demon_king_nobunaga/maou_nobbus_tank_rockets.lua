maou_nobbus_tank_rockets = class({})


function maou_nobbus_tank_rockets:OnSpellStart()
	local caster = self:GetCaster()

	local counter = 0
	local max_counter = self:GetSpecialValueFor("amount") * 2
	local time = 1
	local timeBetweenRockets = time/max_counter
 	caster:EmitSound("nobu_tank_1")
	Timers:CreateTimer(0, function()
		if counter >= max_counter then return end
		counter = counter + 1
		self:FindTargetAndShoot(counter%2 == 0)
		return timeBetweenRockets
	end)

end


function maou_nobbus_tank_rockets:FindTargetAndShoot(odd)
	local caster = self:GetCaster()

	local shootOrigin = caster:GetAbsOrigin()
	if odd then
		shootOrigin = caster:GetAbsOrigin()  + Vector(0,0, 50) + caster:GetForwardVector() * 30 + caster:GetRightVector() * 50
	else	
		shootOrigin = caster:GetAbsOrigin()  + Vector(0,0, 50) + caster:GetForwardVector() * 30 + caster:GetRightVector() * -50
	end
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
	if #targets > 0 then
			if targets[1]:GetName() ~= "npc_dota_ward_base" then

					local projectile1 = 
					{
							Target = targets[1],
							Ability = self,
							EffectName = "particles/econ/items/gyrocopter/hero_gyrocopter_atomic/gyro_rocket_barrage_atomic.vpcf",
							iMoveSpeed = 1000,
							vSourceLoc = shootOrigin,
							bDodgeable = true,
							Source = caster,  
							bDeleteOnHit = true,
							bReplaceExisting = false,
							flExpireTime = GameRules:GetGameTime() + 0.5,
						
		   			}
					 local proj  = FATE_ProjectileManager:CreateTrackingProjectile(projectile1)
			end
	end

end

function maou_nobbus_tank_rockets:OnProjectileHit_ExtraData(target, location, table)
	if target == nil then return end

		--target:EmitSound("merlin_orbs_explosion")
		local caster = self:GetCaster()
		local damage = self:GetSpecialValueFor("damage")  + caster.Level * self:GetSpecialValueFor("damage_per_caster_level")
		target:EmitSound("nobu_shoot_laser")

		-- local explosionFx = ParticleManager:CreateParticle("particles/merlin/orb_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
   		-- ParticleManager:SetParticleControl(explosionFx, 0, location)
 
      	 DoDamage(caster.Caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, caster.Ability, false)

 
 
end
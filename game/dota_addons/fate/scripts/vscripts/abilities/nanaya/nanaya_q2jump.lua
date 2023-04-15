LinkLuaModifier("modifier_q2jump", "abilities/nanaya/nanaya_q2jump", LUA_MODIFIER_MOTION_HORIZONTAL)



nanaya_q2jump = class ({})

function nanaya_q2jump:OnSpellStart()
	local caster = self:GetCaster()
	ProjectileManager:ProjectileDodge(caster)
	self.kappa = false
	caster:EmitSound("nanaya.kerikedaknormal")
	local check = caster:GetAnglesAsVector():Normalized()
	local check2 = caster:GetForwardVector()
	local targetpoint = self:GetCursorPosition()
	caster:AddNewModifier(caster, self, "modifier_q2jump", {duration = 2})
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	local hTarget = (targetpoint - caster:GetAbsOrigin()):Normalized()
	--local speed = 3500
	local speed = 3600
	local hKnifeProjectile =    {
			Source            = caster,
			Ability           = self,
			vSpawnOrigin      = caster:GetAbsOrigin() + Vector(0, 0, 0),
			
			iUnitTargetTeam   = self:GetAbilityTargetTeam(),
			iUnitTargetType   = DOTA_UNIT_TARGET_HERO,
			iUnitTargetFlags  = self:GetAbilityTargetFlags(),
			
			EffectName        = nil,
			fDistance         = 1300,
			fStartRadius      = 150,
			fEndRadius        = 150,
			vVelocity         = Vector(hTarget.x,hTarget.y,0) * (speed - 100),
			
			bHasFrontalCone   = false,
			
			bProvidesVision   = true,
			iVisionRadius     = iVisionRadius,
			iVisionTeamNumber = caster:GetTeamNumber()
		}
		local iKnifeProjectile = ProjectileManager:CreateLinearProjectile(hKnifeProjectile)
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)
	
	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, GetGroundPosition(caster:GetAbsOrigin()+ caster:GetForwardVector():Normalized()*-250, nil))
	ParticleManager:SetParticleControl(jump2, 4, caster:GetAbsOrigin())
	caster:EmitSound("nanaya.jumpforward")
	
	print (check)
	print (check2)
end

function nanaya_q2jump:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("nanaya_q_strike"):GetLevel() ~= self:GetLevel() then
      hCaster:FindAbilityByName("nanaya_q_strike"):SetLevel(self:GetLevel())
    end
end

function nanaya_q2jump:OnProjectileHitHandle(hTarget, vLocation, iProjectileHandle)
	local caster = self:GetCaster()
	local hit = 2
	if hTarget == nil or self.kappa == true then return true 
	else
		self.kappa = true
		local dmg = self:GetSpecialValueFor("dmg") + math.floor(self:GetCaster():GetAgility()*self:GetSpecialValueFor("agi_modifier"))
		hTarget:EmitSound("nanaya.hitleg")
		ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, hTarget)
		   ScreenShake(hTarget:GetOrigin(), 10, 1.0, 0.7, 2000, 0, true)
		  -- DoDamage(caster, hTarget, 400, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		  	  DoDamage(caster, hTarget, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)

	caster:RemoveModifierByName("modifier_q2jump")
	caster:Stop()
	caster:SetOrigin(hTarget:GetOrigin() - caster:GetForwardVector()*100)
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4, 1)
	Timers:CreateTimer(0, function()	
		if ( not caster:IsAlive()  or caster:IsStunned()) then return end
		if hit > 0 then
			hit = hit-1
			DoDamage(caster, hTarget, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
			--[[ApplyDamage({
                    victim = hTarget,
                    attacker = caster,
                    damage = dmg,
                    damage_type = DAMAGE_TYPE_PHYSICAL,
                    damage_flags = 0,
                    ability = self
                })]]


   ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, hTarget)
   ScreenShake(hTarget:GetOrigin(), 10, 1.0, 0.3, 2000, 0, true)
   hTarget:EmitSound("nanaya.hitleg")
    return 0.1
    else
    return end	
end)
if ( not caster:IsAlive()  or caster:IsStunned()) then return end
local knockback4 = { should_stun = true,
				knockback_duration = 0.05,
				duration = 0.05,
				knockback_distance = 25,
				knockback_height = 50,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
			center_z = 4000}	
	if false then
    	hTarget:AddNewModifier(caster, self, "modifier_knockback", knockback4)	
	end

	local knockback1 = { should_stun = false,
				knockback_duration = 1,
				duration = 1,
				knockback_distance = 250,
				knockback_height = 400,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
			center_z = caster:GetAbsOrigin().z }	

			local knockback2 = { should_stun = false,
				knockback_duration = 1,
				duration = 1,
				knockback_distance = 250,
				knockback_height = 200,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
				center_z = caster:GetAbsOrigin().z }	
				Timers:CreateTimer(0.01, function()
				hTarget:RemoveModifierByName("modifier_knockback")
				if not IsKnockbackImmune(hTarget) then
					if ( not caster:IsAlive()  or caster:IsStunned()) then return end
					hTarget:AddNewModifier(caster, self, "modifier_knockback", knockback1)	
					caster:AddNewModifier(caster, self, "modifier_knockback", knockback2)
				end
		end)
		
			Timers:CreateTimer(0.75, function()	
				if ( not caster:IsAlive()  or caster:IsStunned()) then return end

					
				hTarget:RemoveModifierByName("modifier_knockback")
				local vec = (caster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized()
				local knockback3 = { should_stun = false,
				knockback_duration = 0.05,
				duration = 0.05,
				knockback_distance = 500,
				knockback_height = 150,
				center_x = caster:GetAbsOrigin().x + vec.x * 800,
				center_y = caster:GetAbsOrigin().y + vec.y * 800,
				center_z = 4000 }	
				if not IsKnockbackImmune(hTarget)  then
                	hTarget:AddNewModifier(caster, self, "modifier_knockback", knockback3)	
				end
                caster:EmitSound("nanaya.jumphit")
                Timers:CreateTimer(0.05, function()	
                	hTarget:EmitSound("nanaya.hit")
                	ScreenShake(hTarget:GetOrigin(), 10, 1.0, 0.4, 2000, 0, true)
		    		--DoDamage(caster, hTarget, 700, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		   			--hTarget:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1 })
		  			DoDamage(caster, hTarget, dmg*2, DAMAGE_TYPE_MAGICAL, 0, self, false)

					--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*250)	
					--ParticleManager:SetParticleControlEnt(part, 5, self.parent, PATTACH_POINT_FOLLOW, "attach_leg1", self.parent:GetAbsOrigin(), true)
					local part = ParticleManager:CreateParticle("particles/test_part6.vpcf", PATTACH_CUSTOMORIGIN, caster)
					--ParticleManager:SetParticleControlEnt(part, 3, caster, PATTACH_POINT, "attach_leg", caster:GetAbsOrigin(), true)
					ParticleManager:SetParticleControl(part, 3, caster:GetAbsOrigin() + Vector(0, 0, 0))
					local part2 = ParticleManager:CreateParticle("particles/hit2.vpcf", PATTACH_CUSTOMORIGIN, caster)
					--ParticleManager:SetParticleControl(part2, 0, caster:GetAbsOrigin() + Vector(0, 0, 500))
					ParticleManager:SetParticleControlEnt(part2, 0, caster, PATTACH_POINT, "attach_knife", caster:GetAbsOrigin(), true)
		  			local part1 = ParticleManager:CreateParticle("particles/nanaya_jump_back.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, hTarget)
		 			ParticleManager:SetParticleControl(part1, 0, GetGroundPosition(hTarget:GetAbsOrigin(), nil))
		   			ParticleManager:SetParticleControl(part, 5, GetGroundPosition(hTarget:GetAbsOrigin(), nil))
            	end)
            end)

end
end


modifier_q2jump = class ({})

function modifier_q2jump:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_q2jump:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_q2jump:IsHidden()
	return true
end
function modifier_q2jump:CheckState()
    local state =   { 
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		--[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
	}
	return state
end

function modifier_q2jump:OnCreated(args)
	if not IsServer() then 
        return
    end 
	self.parent = self:GetParent()	
	self.hit = ParticleManager:CreateParticle("particles/test_part5.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*250)	
ParticleManager:SetParticleControlEnt(self.hit, 3, self.parent, PATTACH_POINT_FOLLOW, "attach_leg", self.parent:GetAbsOrigin(), true)
ParticleManager:SetParticleControlEnt(self.hit, 5, self.parent, PATTACH_POINT_FOLLOW, "attach_leg1", self.parent:GetAbsOrigin(), true)
	self.check = args.knife
	if self.check == nil then 
		self.ability = self:GetAbility()
		self.point = self.ability:GetCursorPosition()
		self.distances = 1000
		self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
		else
		self.point = Vector(args.pos_x, args.pos_y, 0)
		self.distances = 450
		
		self.direction = (self.parent:GetForwardVector() * 180):Normalized() 
		self.parent:SetOrigin(Vector(args.pos_x, args.pos_y, self.parent:GetAbsOrigin().z))
		self.target = args.target
	end
	--self.nanayaframechange = 0
	self:StartIntervalThink(FrameTime())
end


function modifier_q2jump:OnIntervalThink()
	self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
	
	--local nanaya_image = ParticleManager:CreateParticle("particles/nanaya_image.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	--ParticleManager:SetParticleControl(nanaya_image, 0, self.parent:GetAbsOrigin())
	--ParticleManager:SetParticleControl(nanaya_image, 4, self.point)
	--ParticleManager:SetParticleControl(nanaya_image, 2, Vector(self.nanayaframechange, 0, 0))
	--self.nanayaframechange = self.nanayaframechange + 1
end

function modifier_q2jump:UpdateHorizontalMotion(hero, times)
	if self.distances >= 0 then 
		local speed = 4000 * times
		local parent_pos = self.parent:GetAbsOrigin()
		
		self.next_pos = parent_pos + self.direction * speed
		self.distances = self.distances - speed
		self.parent:SetOrigin(self.next_pos)
		--self.parent:FaceTowards(self.point)
		else
		--ParticleManager:CreateParticle("particles/nanaya_jump_back.vpcf", PATTACH_ABSORIGIN, self.parent)
		self:Destroy()
	end
end

function modifier_q2jump:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
	end
end


function modifier_q2jump:OnDestroy()
	if IsServer() then
        self.parent:InterruptMotionControllers(true)
        	if self.hit ~= nil then
			ParticleManager:DestroyParticle(self.hit, true)
		end
	end
	
end

--[[function modifier_q_nanaya:GetOverrideAnimation()
	return ACT_SCRIPT_CUSTOM_14
	end
	
	function modifier_q_nanaya:GetOverrideAnimationRate()
	return 1
end]]




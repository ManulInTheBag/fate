LinkLuaModifier("jump_ahead_nanaya_modifier", "abilities/nanaya/nanaya_w_e_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_animation_knife", "abilities/nanaya/nanaya_w_e_knife", LUA_MODIFIER_MOTION_NONE)

jump_ahead_nanaya = class({})
function jump_ahead_nanaya:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "jump_ahead_nanaya_modifier", {})
	local justpoint = self:GetCursorPosition()
	local hTarget = (justpoint - caster:GetAbsOrigin()):Normalized()
	local speed = 3000
	caster:EmitSound("nanaya.jump")
	local projectile_name = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf"
	local projectile_speed = 450
	local projectile_vision = 450
	local sAbil = caster:GetAbilityByIndex(0):GetAbilityName()
        if sAbil == "nanaya_q_strike" then
	caster:SwapAbilities("nanaya_q_strike", "nanaya_q2jump", false, true)
end

local sAbil1 = caster:GetAbilityByIndex(2)
        if sAbil1:GetAbilityName() == "nanaya_e_jump" and caster.enanaya then
sAbil1:EndCooldown()
end

print (sAbil)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 then 
		if caster:FindAbilityByName("nanaya_combo"):IsCooldownReady() then
				caster:SwapAbilities("nanaya_combo", "jump_ahead_nanaya", true, false)
				Timers:CreateTimer(2, function()
					caster:SwapAbilities("nanaya_combo", "jump_ahead_nanaya", false, true)
				end)
		end
	end
	if caster:FindModifierByName("nanaya_blood_modifier"):GetStackCount() > 9 then
	Timers:CreateTimer(0.1, function()
		local hKnifeProjectile =    {
			Source            = caster,
			Ability           = self,
			vSpawnOrigin      = caster:GetAbsOrigin() + Vector(0, 0, 100),
			
			iUnitTargetTeam   = self:GetAbilityTargetTeam(),
			iUnitTargetType   = self:GetAbilityTargetType(),
			iUnitTargetFlags  = self:GetAbilityTargetFlags(),
			
			EffectName        = "particles/heroes/anime_hero_sniper/sniper_knife_projectile.vpcf",
			fDistance         = 1500,
			fStartRadius      = 150,
			fEndRadius        = 150,
			vVelocity         = Vector(hTarget.x,hTarget.y,0) * (speed - 100),
			
			bHasFrontalCone   = false,
			
			bProvidesVision   = true,
			iVisionRadius     = iVisionRadius,
			iVisionTeamNumber = caster:GetTeamNumber()
		}
		local iKnifeProjectile = ProjectileManager:CreateLinearProjectile(hKnifeProjectile)
	end)
end
end

function jump_ahead_nanaya:OnProjectileHitHandle(hTarget, vLocation, iProjectileHandle)
	local caster = self:GetCaster()
	if hTarget == nil then return true 
		else
		caster:RemoveModifierByName("jump_ahead_nanaya_modifier")
		local target = hTarget:GetAbsOrigin()
		local target_2 = hTarget:entindex()
		local dmg = self:GetSpecialValueFor("dmg_knife") + math.floor(self:GetCaster():GetAgility()*self:GetSpecialValueFor("agi_modifier"))
		local dmg2 = self:GetSpecialValueFor("dmg_hit") + math.floor(self:GetCaster():GetAgility()*self:GetSpecialValueFor("agi_modifier"))
		--DoDamage(caster, hTarget, 500, DAMAGE_TYPE_PHYSICAL, 0, self, false)
			DoDamage(caster, hTarget, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
			            --hTarget:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1 })

		caster:SetOrigin(target+caster:GetForwardVector()*180)
		
		local order = {   UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET ,
			TargetIndex = hTarget:entindex(),
			AbilityIndex = 0,
			Position = 0,
		Queue = 0, }
		
		ExecuteOrderFromTable(order)
		
		caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK2, 1.2)
		Timers:CreateTimer(0.25, function()
			
			local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
			
			
			ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)
			
			local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(jump2, 0, caster:GetAbsOrigin()+ caster:GetForwardVector()*-250)
			ParticleManager:SetParticleControl(jump2, 4, hTarget:GetAbsOrigin())
			
			
			local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN, hTarget)
			ParticleManager:SetParticleControl(dagon_particle, 1,  hTarget:GetAbsOrigin()+Vector(0, 0, 150))
			local particle_effect_intensity = 500
			ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
			
			local knockback1 = { should_stun = true,
				knockback_duration = 0.1,
				duration = 0.15,
				knockback_distance = 800,
				knockback_height = 0,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
			center_z = caster:GetAbsOrigin().z }								
			caster:EmitSound("nanaya.slash")
			--DoDamage(caster, hTarget, 500, DAMAGE_TYPE_PHYSICAL, 0, self, false)
				DoDamage(caster, hTarget, dmg2, DAMAGE_TYPE_MAGICAL, 0, self, false)
			local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)	
			
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( culling_kill_particle, false )
				ParticleManager:ReleaseParticleIndex(culling_kill_particle)		
			end)
			caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
			
		end)
		
		
		
	end
	--print (hTarget:GetFor
	return true
end



jump_ahead_nanaya_modifier = class({})
function jump_ahead_nanaya_modifier:GetPriority() return MODIFIER_PRIORITY_HIGH end
function jump_ahead_nanaya_modifier:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function jump_ahead_nanaya_modifier:IsHidden()
	return true
end
function jump_ahead_nanaya_modifier:CheckState()
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




function jump_ahead_nanaya_modifier:OnCreated(args)
	if not IsServer() then 
        return
    end 
	self.parent = self:GetParent()
	self.check = args.knife
	if self.check == nil then 
		self.ability = self:GetAbility()
		self.point = self.ability:GetCursorPosition()
		self.distances = self.ability:GetSpecialValueFor("blink_ahead")
		self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
		else
		self.point = Vector(args.pos_x, args.pos_y, 0)
		self.distances = 450
		
		self.direction = (self.parent:GetForwardVector() * 180):Normalized() 
		self.parent:SetOrigin(Vector(args.pos_x, args.pos_y, self.parent:GetAbsOrigin().z))
		self.target = args.target
	end
	self.nanayaframechange = 0
	self:StartIntervalThink(FrameTime())
end


function jump_ahead_nanaya_modifier:OnIntervalThink()
	self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
	
	local nanaya_image = ParticleManager:CreateParticle("particles/nanaya_image.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	ParticleManager:SetParticleControl(nanaya_image, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(nanaya_image, 4, self.point)
	ParticleManager:SetParticleControl(nanaya_image, 2, Vector(self.nanayaframechange, 20, 0))
	self.nanayaframechange = self.nanayaframechange + 1
end

function jump_ahead_nanaya_modifier:UpdateHorizontalMotion(hero, times)
	if self.distances >= 0 then 
		local speed = 1750 * times
		local parent_pos = self.parent:GetAbsOrigin()
		
		self.next_pos = parent_pos - self.direction * speed
		self.distances = self.distances - speed
		self.parent:SetOrigin(self.next_pos)
		self.parent:FaceTowards(self.point)
		else
		self.jump = ParticleManager:CreateParticle("particles/nanaya_jump_back.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
			ParticleManager:SetParticleControl(self.jump, 0, GetGroundPosition(self.parent:GetAbsOrigin(), nil))

		self:Destroy()
	end
end

function jump_ahead_nanaya_modifier:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
	end
end


function jump_ahead_nanaya_modifier:OnDestroy()
	
	if IsServer() then
        self.parent:InterruptMotionControllers(true)
	end
	
end

nanaya_knife = class({})

function nanaya_knife:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local hTarget = (point - caster:GetAbsOrigin()):Normalized()
	local speed = 3000
	local nanaya_knife = ParticleManager:CreateParticle("particles/nanaya_knifethrow.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(nanaya_knife, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * 75)
	ParticleManager:SetParticleControl(nanaya_knife, 1, caster:GetAbsOrigin() + (caster:GetForwardVector():Normalized()))
	caster:EmitSound("nanaya.knifethrow")
	
	-- get projectile_data
	local projectile_name = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf"
	local projectile_speed = 450
	local projectile_vision = 450
	
	-- Create Projectile
	local hKnifeProjectile =    {
		Source            = caster,
		Ability           = self,
		vSpawnOrigin      = caster:GetAbsOrigin() + caster:GetForwardVector()*90,
		
		iUnitTargetTeam   = self:GetAbilityTargetTeam(),
		iUnitTargetType   = self:GetAbilityTargetType(),
		iUnitTargetFlags  = self:GetAbilityTargetFlags(),
		
		EffectName        = "particles/heroes/anime_hero_sniper/sniper_knife_projectile.vpcf",
		fDistance         = 1500,
		fStartRadius      = 150,
		fEndRadius        = 150,
		vVelocity         = Vector(hTarget.x,hTarget.y,0) * (speed - 100),
		
		bHasFrontalCone   = false,
		
		bProvidesVision   = true,
		iVisionRadius     = iVisionRadius,
		iVisionTeamNumber = caster:GetTeamNumber()
	}
    local iKnifeProjectile = ProjectileManager:CreateLinearProjectile(hKnifeProjectile)
end

function nanaya_knife:OnProjectileHitHandle(hTarget, vLocation, iProjectileHandle)
	local caster = self:GetCaster()
	if hTarget == nil then return true 
		else

		ProjectileManager:ProjectileDodge(caster)

		local player = caster:GetPlayerOwner()
		local player2 = hTarget:GetPlayerOwner()
		local target = hTarget:GetAbsOrigin()
		local target_2 = hTarget:entindex()
		local dmg = self:GetSpecialValueFor("dmg") + math.floor(self:GetCaster():GetAgility()*self:GetSpecialValueFor("agi_modifier"))

				DoDamage(caster, hTarget, dmg/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
				DoDamage(caster, hTarget, dmg/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
        			            --hTarget:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1 })
		local culling_kill_particle = ParticleManager:CreateParticle("particles/nanaya_work_2_great.vpcf", PATTACH_ABSORIGIN, hTarget)
		ScreenShake(hTarget:GetOrigin(), 22, 1.0, 0.4, 1000, 0, true)
		
		local nanaya_hit = hTarget:GetAbsOrigin() + Vector(0, 0, (hTarget:GetOrigin().z) - 230) + caster:GetForwardVector()*-45
		ParticleManager:CreateParticleForPlayer("particles/screen_spla.vpcf", PATTACH_EYES_FOLLOW, caster, player)
		ParticleManager:CreateParticleForPlayer("particles/screen_spla.vpcf", PATTACH_EYES_FOLLOW, caster, player2)
		
		caster:SetOrigin(nanaya_hit)
		local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(jump2, 0, caster:GetAbsOrigin()+ caster:GetForwardVector()*-90)
		ParticleManager:SetParticleControl(jump2, 4, hTarget:GetAbsOrigin())
		local part = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin()+ caster:GetForwardVector()*-400)
		caster:AddNewModifier(caster, self, "modifier_nanaya_animation_knife", {duration = 0.35, enemy_health = hTarget:GetHealthPercent(), target = target_2, origin1 = nanaya_hit})
		
		hTarget:EmitSound("nanaya.knifehit")
	end
	return true
end

modifier_nanaya_animation_knife = class({})

function modifier_nanaya_animation_knife:IsHidden()
	return true
end
function modifier_nanaya_animation_knife:OnCreated(args)
	if IsServer() then 
		self.parent = self:GetParent()
		
		self.health = args.enemy_health
		self.origin = args.origin
		self.d = args.d
		
		self.vector = Vector(args.position_x, args.position_y, args.position_z)
		
		self.target = EntIndexToHScript(args.target)
		self.ability = self:GetAbility()
		if not self.parent:HasModifier("nanaya_blood_modifier_animemode") and self.parent:FindModifierByName("nanaya_blood_modifier"):GetStackCount() > 15
 then 
		self.parent:AddNewModifier(self.parent, self, "nanaya_blood_modifier_animemode", {})
	end
		print (self.health)
		
		
		print ("this is", args.enemy_health)
		if self.parent:FindModifierByName("nanaya_blood_modifier"):GetStackCount() == 30 then
			self.parent:AddNewModifier(self.parent, self, "modifier_combo", {Duration = 1.8})
			
			self.target:AddNewModifier(self.parent, self, "modifier_combo", {Duration = 1.8})
			self.parent:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_7, 0.64)
			else
			
		end
	end
	
	
	
	
	
	self:StartIntervalThink(0.1)
	
end

function modifier_nanaya_animation_knife:DeclareFunctions() 
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
	
	return funcs
end

function modifier_nanaya_animation_knife:CheckState()
	local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_INVULNERABLE] = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,

                    }
					   return state
end


function modifier_nanaya_animation_knife:OnIntervalThink()
	if IsServer() then 
	if self.parent:IsAlive() then
		local speed = FrameTime()*1000
		self.parent:SetOrigin(self.target:GetAbsOrigin() + Vector(0, 0, (self.target:GetOrigin().z) - 230) + self.parent:GetForwardVector()*-45)
		
	end
end
end


function modifier_nanaya_animation_knife:GetOverrideAnimation()
	return ACT_SCRIPT_CUSTOM_0
end

function modifier_nanaya_animation_knife:GetOverrideAnimationRate()
	return 2
end

function modifier_nanaya_animation_knife:OnDestroy()
	if IsServer() then
		--self.parent:SwapAbilities("nanaya_knife", "nanaya_clones", false, true)
		if self.parent:HasModifier("nanaya_jump_slashes_modifier") then return nil end
		
		local check = self.parent:GetAttachmentOrigin(1)
		if self.parent:FindModifierByName("nanaya_blood_modifier"):GetStackCount() == 30 and self.parent.rnanaya then
			--[[Timers:CreateTimer("check", {
				callback = function()
					print (1)
					
						if self.parent:IsAlive() then
							local speed = FrameTime()*1000
							self.parent:SetOrigin(self.target:GetAbsOrigin() + Vector(0, 0, (self.target:GetAttachmentOrigin(1).z - self.target:GetOrigin().z) - 125) + self.parent:GetForwardVector()*-45)
							return 0.05
					
					end
				end})]]
			print (check)
			
			Timers:CreateTimer(0.6, function() 
				Timers:RemoveTimer("check")
				local hit2 = ParticleManager:CreateParticle("particles/screen_spla.vpcf", PATTACH_EYES_FOLLOW, self.parent)
				local knife_hit = ParticleManager:CreateParticle("particles/test_part_small.vpcf", PATTACH_EYES_FOLLOW, self.parent)
				
				ParticleManager:SetParticleControl(knife_hit, 3, self.target:GetAbsOrigin()+self.parent:GetForwardVector()*300+Vector(0, 0, 400))
				
				FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin() - self.parent:GetForwardVector()*250 , true) 
				
				self.parent:EmitSound("nanaya.slash")
				ParticleManager:SetParticleControl(knife_hit, 5, GetGroundPosition(self.parent:GetAbsOrigin() - Vector(0, 0, 400), nil))
				
				--self.target:Kill(self, self.parent)
                self.damage = math.floor(self.parent:GetAgility()*20)
				  DoDamage(self.parent, self.target, self.damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
				  if self.parent:HasModifier("nanaya_blood_modifier_animemode") then self.parent:RemoveModifierByName("nanaya_blood_modifier_animemode")
				  	self.modifier = self.parent:FindModifierByName("nanaya_blood_modifier")
	self.modifier:SetStackCount(0)
				  end
			end)
			
			else
			
			self.parent:RemoveGesture(ACT_SCRIPT_CUSTOM_0)
			self.parent:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_2, 1)
			Timers:CreateTimer(0.3, function() 
				local nanaya_clone_jump = ParticleManager:CreateParticle("particles/blink_z1.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
				ParticleManager:SetParticleControl(nanaya_clone_jump, 1, GetGroundPosition(self.parent:GetAbsOrigin(), nil))
				if self.parent:HasModifier("nanaya_blood_modifier_animemode") and self.parent.rnanaya then 
					local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
					
					ParticleManager:SetParticleControl(nanaya_clone, 0, GetGroundPosition(self.parent:GetAbsOrigin(), nil)) --0.35
					ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, 9, 0))
					ParticleManager:SetParticleControl(nanaya_clone, 4, self.target:GetAbsOrigin())
						nanaya_clones:Clones(self.parent, self.target)
					else
					--nanaya_clones:ComboD(self.parent, self.target)
				end
			end)
			self.table = {knife = 1, 
				pos_x = self.target:GetAbsOrigin().x, 
				pos_y = self.target:GetAbsOrigin().y, 
			pos_z = self.target:GetAbsOrigin().z, }
			
			self.parent:AddNewModifier(caster, self, "jump_ahead_nanaya_modifier", self.table)
		end
	end
end

nanaya_clones = class ({})

function nanaya_clones:Clones(caster, units, secondtime)
local table = {12, 13, 21, 23, 24}	
local abil = caster:FindAbilityByName("nanaya_knife")
local knockback_push = 0
local knockback_push1 = caster:GetForwardVector()
local dmg = abil:GetSpecialValueFor("clone_dmg") + math.floor(caster:GetAgility()*abil:GetSpecialValueFor("clone_dmg_agi") )
--units:EmitSound("nanaya.combo2")

										local numberhit = 0
										local cloneanim = 14
										Timers:CreateTimer(0.1, function()
										if numberhit < 4 then
										if secondtime == nil then 
										knockback_push = units:GetAbsOrigin() - knockback_push1*120
										else
									
										end
										
										numberhit = numberhit + 1
										local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone.vpcf", PATTACH_CUSTOMORIGIN, caster)
										cloneanim = cloneanim + 1
										
ParticleManager:SetParticleControl(nanaya_clone, 0, knockback_push) --0.35
ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, table[numberhit], 0))
ParticleManager:SetParticleControl(nanaya_clone, 4, units:GetAbsOrigin())


local test = string.format("nanaya.clonetp%s", numberhit)
																			
units:EmitSound(test)
 
	local knockback = { should_stun = false,
	                                knockback_duration = 0.1,
	                                duration = 0.1,
	                                knockback_distance = 250,
	                                knockback_height = 0,

								    center_x = knockback_push.x,
									center_y = knockback_push.y,
	                                center_z = units:GetAbsOrigin().z }
									
        Timers:CreateTimer(0.15, function()
		ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, units)
		if numberhit == 4 then
		ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(2, table[numberhit], -19))
		local test_hit = ParticleManager:CreateParticle("particles/nanaya_hit_test.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, units)
		ParticleManager:SetParticleControl(test_hit, 1, units:GetAbsOrigin() + knockback_push1 * 120)
		ParticleManager:SetParticleControl(test_hit, 0, units:GetAbsOrigin())
		end
		--[[caster:PerformAttack (
		units,
		true,
		true,
		true,
		false,
		false,
		false,
		true
	)]]
		units:EmitSound("nanaya.slash")
		if not IsKnockbackImmune(units) then
	    	units:AddNewModifier(caster, self, "modifier_knockback", knockback)
		end
		ParticleManager:CreateParticle("particles/nanaya_e1.vpcf", PATTACH_ABSORIGIN, units)
		DoDamage(caster, units, dmg, DAMAGE_TYPE_MAGICAL, 0, caster:FindAbilityByName("nanaya_knife"), false)
		--DoDamage(caster, units, 250, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		ScreenShake(units:GetOrigin(), 10, 1.0, 0.1, 2000, 0, true)
				
		end)
		
return 0.4
else
if secondtime == nil then 
--nanaya_clones:Clones(caster, units, 1)
nanaya_clones:Final_clones(caster, units, knockback_push1)

end
end
end)
end

function nanaya_clones:Final_clones(caster, units, knockback_push1)

local abil = caster:FindAbilityByName("nanaya_knife")
--local check1 = GetGroundPosition(units:GetAbsOrigin() + units:GetForwardVector() * 450, nil) + Vector(0, 0, 300) --ПОНИЖЕНИЕ СТАРТОВОЙ
--local check2 = GetGroundPosition(units:GetAbsOrigin() + units:GetForwardVector() * 1500, nil) - Vector(0, 0, 250) --ПОВЫШЕНИЕ КОНЕЧНОЙ

local check1 = GetGroundPosition(units:GetAbsOrigin() + knockback_push1 * 450, nil) + Vector(0, 0, 300) --ПОНИЖЕНИЕ СТАРТОВОЙ
local check2 = GetGroundPosition(units:GetAbsOrigin() + knockback_push1 * 1500, nil) - Vector(0, 0, 250) --ПОВЫШЕНИЕ КОНЕЧНОЙ

local center_unit_z = units:GetAbsOrigin().z
Timers:CreateTimer(0.15, function()
units:EmitSound("nanaya.kerikedak")
local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone_attach.vpcf", PATTACH_CUSTOMORIGIN, caster)
knockback_push = units:GetAbsOrigin() - knockback_push1 * 180
ParticleManager:SetParticleControl(nanaya_clone, 0, units:GetAbsOrigin() - knockback_push1 * 20 )
ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(0, 24, 0))
ParticleManager:SetParticleControl(nanaya_clone, 4, units:GetAbsOrigin())
--ParticleManager:SetParticleControl(nanaya_clone, 5, units:GetAbsOrigin() + Vector(0, 0, 200))

Timers:CreateTimer(0.2, function()
ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, units)
units:EmitSound("nanaya.hitleg")
ScreenShake(units:GetOrigin(), 10, 1.0, 0.2, 2000, 0, true)
--DoDamage(caster, units, 500, DAMAGE_TYPE_PHYSICAL, 0, self, false)
DoDamage(caster, units, abil:GetSpecialValueFor("5th_clone_dmg")+ math.floor(caster:GetAgility()*abil:GetSpecialValueFor("clone_dmg_agi") ), DAMAGE_TYPE_MAGICAL, 0, abil, false)

local knockback = { should_stun = false,
	                                knockback_duration = 2,
	                                duration = 2,
	                                knockback_distance = 800,
	                                knockback_height = 400,
	                               
								    center_x = knockback_push.x,
									center_y = knockback_push.y,
	                                center_z = center_unit_z }
	                                units:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1.5 })
									ParticleManager:CreateParticle("particles/nanaya_jump_back.vpcf", PATTACH_ABSORIGIN, units)
									if not IsKnockbackImmune(units) then
										units:AddNewModifier(caster, self, "modifier_knockback", knockback)
									end
									Timers:CreateTimer(0.2, function()
									local nanaya_clone2 = ParticleManager:CreateParticle("particles/nanaya_image_clone_back.vpcf", PATTACH_CUSTOMORIGIN, caster)
								
ParticleManager:SetParticleControl(nanaya_clone2, 0, GetGroundPosition(units:GetAbsOrigin() - knockback_push1 * 20, nil))
ParticleManager:SetParticleControl(nanaya_clone2, 2, Vector(1, 25, 0))
ParticleManager:SetParticleControl(nanaya_clone2, 4, GetGroundPosition(units:GetAbsOrigin() + knockback_push1 * 1000, nil))
ParticleManager:SetParticleShouldCheckFoW(nanaya_clone2, false)

Timers:CreateTimer(0.9, function()
ParticleManager:DestroyParticle(nanaya_clone2, false)


	Timers:CreateTimer(0.7, function()
	ParticleManager:DestroyParticle(nanaya_clone2, false)
	local hit = ParticleManager:CreateParticle("particles/test_part_small.vpcf", PATTACH_CUSTOMORIGIN, caster)
	
ParticleManager:SetParticleControl(hit, 3, check1) 
ParticleManager:SetParticleControl(hit, 5, check2) 
	local hit2 = ParticleManager:CreateParticle("particles/screen_spla22.vpcf", PATTACH_EYES_FOLLOW,caster)

ParticleManager:SetParticleShouldCheckFoW(hit, false)
--units:StopSound("nanaya.combo2")
--local sex FindUnitsInLine(caster:GetTeam(), check1, check2, nil, 90, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
local sex = FindUnitsInLine(caster:GetTeam(), check1, check2, nil, 90, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0)
--local sex = FindUnitsInRadius(caster:GetTeam(), check2, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
  for k,v in pairs(sex) do
print (sex)
--DoDamage(caster, v, 1000, DAMAGE_TYPE_PHYSICAL, 0, self, false)
DoDamage(caster, v, abil:GetSpecialValueFor("6th_clone_dmg")+ math.floor(caster:GetAgility()*abil:GetSpecialValueFor("clone_dmg_agi") ), DAMAGE_TYPE_MAGICAL, 0, abil, false)
ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, v)
v:EmitSound("nanaya.finalhit")
print ("1")
print (Vector(0, 0, 200):Normalized())
end

	end)
	end)
									end)
									end)
end)
end


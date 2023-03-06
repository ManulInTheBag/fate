LinkLuaModifier("nanaya_slashes_modifier", "abilities/nanaya/nanaya_d", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_slashes_modifier1", "abilities/nanaya/nanaya_d", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_jump_revoke", "abilities/nanaya/nanaya_r", LUA_MODIFIER_MOTION_NONE)

nanaya_slashes = class ({})
function nanaya_slashes:OnAbilityPhaseStart()	
local caster = self:GetCaster()
niger = 0
caster:EmitSound("nanaya.hmm")
return true
end

function nanaya_slashes:GetCastPoint()
	local caster = self:GetCaster()
if caster:FindModifierByName("nanaya_blood_modifier"):GetStackCount() < 10 then 
	return 0.1
end
end

function nanaya_slashes:GetPlaybackRateOverride()
	local caster = self:GetCaster()
if caster:FindModifierByName("nanaya_blood_modifier"):GetStackCount() < 10 then 
	return 3
end
end

function nanaya_slashes:GetCastAnimation()
	local caster = self:GetCaster()
if caster:FindModifierByName("nanaya_blood_modifier"):GetStackCount() < 10 then 
	return ACT_DOTA_CAST_ABILITY_5
end
end

function nanaya_slashes:GetCastRange()  
return 600
end

function nanaya_slashes:GetAbilityTextureName()
		local caster = self:GetCaster()
		--local modifier = caster:FindModifierByName("nanaya_blood_modifier")
		--if caster:HasModifier("nanaya_blood_modifier_animemode") then 
			return "custom/nanaya/nanaya-D2"
		--else
			--return "custom/nanaya/nanaya-D"
end
--end

function nanaya_slashes:OnSpellStart()	


local target = self:GetCursorTarget()
if IsSpellBlocked(target) then return end
local caster = self:GetCaster()
local target_2 = target:entindex()


	
if caster:FindModifierByName("nanaya_blood_modifier"):GetStackCount() < 10 then 
--local slash = 8
caster:AddNewModifier(caster, self, "nanaya_jump_revoke", {duration = 0.8})
 local max_range = 450
local range = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
    if(range > max_range) then
        range = max_range
else
--local nanaya_set = target:GetAbsOrigin() + Vector(0, 0, (target:GetAttachmentOrigin(1).z - target:GetOrigin().z) - 125) + caster:GetForwardVector()*-45
	--caster:SetOrigin(nanaya_set)
    end	
	
	local blink_target = target:GetAbsOrigin()
local check1 = (blink_target - caster:GetAbsOrigin()):Length2D()
   print (check1)
	if (blink_target - caster:GetAbsOrigin()):Length2D() > 250 then 
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	caster:EmitSound("nanaya.jumpforward")
ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector())
ParticleManager:SetParticleControl(jump, 4, self:GetCursorPosition())
local point = self:GetCursorPosition()
--local point  = caster:GetAbsOrigin() + (((self.point - self.parent:GetAbsOrigin()):Normalized()) * self.distances)
local point2 = (point  - caster:GetAbsOrigin()):Length2D()
print (point2)
	local dist = self:GetSpecialValueFor("distance")
    blink_target = (target:GetAbsOrigin() - caster:GetForwardVector() * 180) 
    local knockback4 = { should_stun = false,
				knockback_duration = 0.05,
				duration = 0.05,
				knockback_distance = point2 - 125,
				knockback_height = 0,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * point2,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * point2,
			center_z = 0}	
    caster:AddNewModifier(caster, self, "modifier_knockback", knockback4)	
			--blink_target = (caster:GetAbsOrigin()) + (((blink_target - caster:GetAbsOrigin()):Normalized()) * 225)
		--FindClearSpaceForUnit(caster, blink_target , true) 
		end
	 
		caster:EmitSound("nanaya.zange")

--[[local sin = Physics:Unit(caster)
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(caster:GetForwardVector() * 1000)
    caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)
		
  Timers:CreateTimer("nanaya_zange", {
        endTime = 800/1000,
        callback = function()
        caster:OnPreBounce(nil)
        caster:SetBounceMultiplier(0)
        caster:PreventDI(false)
        caster:SetPhysicsVelocity(Vector(0,0,0))
        caster:RemoveModifierByName("pause_sealenabled")
     
        caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		return end 
		})
		
		caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
        Timers:RemoveTimer("nanaya_zange")
        unit:OnPreBounce(nil)
        unit:SetBounceMultiplier(0)
        unit:PreventDI(false)
        unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        --caster:RemoveModifierByName("pause_sealenabled")
		end)]]
									--caster:AddNewModifier(caster, self, "nanaya_slashes_modifier", {})
									--[[local knockback1 = { should_stun = false,
	                                knockback_duration = 0.65,
	                                duration = 0.9,
	                                knockback_distance = 500,
	                                knockback_height = 0,
	                                center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 180,
	                                center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 180,
	                                center_z = caster:GetAbsOrigin().z }
									caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)]]
									local particle = ParticleManager:CreateParticle("particles/check_slashes.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
ParticleManager:SetParticleControl(particle, 4, caster:GetAbsOrigin() + caster:GetForwardVector() * 1600)
local slash = self:GetSpecialValueFor("slash")

local target_script = target:entindex()
Timers:CreateTimer(0.05, function () 
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin() , true) 
	--caster:RemoveModifierByName("modifier_knockback")
	 local knockback1 = { should_stun = false,
				knockback_duration = 0.7,
				duration = 0.7,
				knockback_distance = 600,
				knockback_height = 0,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 1000,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 1000,
			center_z = 0}	
										caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)	

target:AddNewModifier(caster, self, "nanaya_slashes_modifier1", {duration = 0.6, target = target_script, vector = caster:entindex(), part = particle})
end)

local dmg = self:GetSpecialValueFor("dmg") + math.floor(self:GetCaster():GetAgility() * self:GetSpecialValueFor("agi_modifier"))
Timers:CreateTimer(0.1, function () 

if IsServer() then
if slash > 0 and target:HasModifier("nanaya_slashes_modifier1") then
	if (caster:GetOrigin() - target:GetAbsOrigin()):Length2D() > 750 then
			target:RemoveModifierByName("nanaya_slashes_modifier1")
		return nil
	end
	caster:EmitSound("nanaya.slash")

									--DoDamage(caster, target, 150, DAMAGE_TYPE_PHYSICAL, 0, self, false)
										ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, target)
										target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.3 })
									DoDamage(caster, target, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)


									slash = slash - 1
else
	--caster:OnPreBounce(nil)
	--caster:SetBounceMultiplier(0)
	  --caster:PreventDI(false)
	  --caster:SetPhysicsVelocity(Vector(0,0,0))
	  --caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
	  return nil	
		end

		
end
--print (slash)
return 0.08
	
end)

else
--caster:AddNewModifier(caster, self, "modifier_nanaya_animation_knife", {duration = 0.35, enemy_health = target:GetHealthPercent()-5, target = target_2, d = true})
local dmg = self:GetSpecialValueFor("clone_dmg") + math.floor(caster:GetAgility()*self:GetSpecialValueFor("clone_dmg_agi"))  
	--target:EmitSound("nanaya.knifehit")

nanaya_clones1:ComboD(caster, target, dmg)
end
end

nanaya_clones1 = class ({})



function nanaya_clones1:ComboD(caster, target, dmg)
	caster:AddNewModifier(caster, self, "nanaya_jump_revoke", {duration = 1.2})
	local table = {12, 13, 21}
	--local table = {13, 12, 13, 23, 24}	
		if not caster:HasModifier("nanaya_blood_modifier_animemode") and caster:FindModifierByName("nanaya_blood_modifier"):GetStackCount() > 15
 then 
		caster:AddNewModifier(caster, self, "nanaya_blood_modifier_animemode", {})
	end
	local knockback_push1 = caster:GetForwardVector()
	local numslash = 0
	local somerandom = {ACT_SCRIPT_CUSTOM_1, ACT_DOTA_CAST_ABILITY_3, ACT_SCRIPT_CUSTOM_1}
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 2)
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 0.2)
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 0.8)
	Timers:CreateTimer(0.05, function()
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 0.8)
	Timers:CreateTimer(0.1, function()
	--caster:AddEffects(32)
	--caster:SetBodygroup(1, 0)
	--target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.4 })
	caster:SetRenderAlpha(0)
	if not somerandom[numslash] == nil then
	--caster:RemoveGesture(somerandom[numslash])
	end
	if numslash < 3 then
	numslash = numslash+1
					--caster:StartGestureWithPlaybackRate(somerandom[numslash], 4-numslash)
	
	local nanaya_clone2 = ParticleManager:CreateParticle("particles/nanaya_image_clone1.vpcf", PATTACH_CUSTOMORIGIN, caster)
	local knife = ParticleManager:CreateParticle("particles/maybedashvpcffinal1.vpcf", PATTACH_CUSTOMORIGIN, caster)
--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*250)	
ParticleManager:SetParticleControlEnt(knife, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand", caster:GetAbsOrigin(), true)
ParticleManager:SetParticleControl(knife, 4, target:GetAbsOrigin())
											--cloneanim = cloneanim + 1
											
	ParticleManager:SetParticleControl(nanaya_clone2, 0, caster:GetAbsOrigin()) --0.35
	ParticleManager:SetParticleControl(nanaya_clone2, 2, Vector(0, table[numslash], 10))
	ParticleManager:SetParticleControl(nanaya_clone2, 4, target:GetAbsOrigin())
	
	knockback_push = target:GetAbsOrigin() - knockback_push1*120
	--caster:SetOrigin((target:GetAbsOrigin() - knockback_push1*(0+4))- caster:GetForwardVector()*30)
	caster:SetOrigin(knockback_push)
	
	local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clon2.vpcf", PATTACH_CUSTOMORIGIN, caster)
											--cloneanim = cloneanim + 1
											
	ParticleManager:SetParticleControl(nanaya_clone, 0, knockback_push) --0.35
	ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(4, table[numslash], 0))
	ParticleManager:SetParticleControl(nanaya_clone, 4, target:GetAbsOrigin())
	
	local test = string.format("nanaya.clonetp%s", numslash)
																				--print (ACT_DOTA_CAST_ABILITY_3)
	caster:EmitSound(test)
		local knockback = { should_stun = false,
										knockback_duration = 0.05,
										duration = 0.05,
										knockback_distance = 250,
										knockback_height = 0,
										center_x = knockback_push.x,
										center_y = knockback_push.y,
										center_z = target:GetAbsOrigin().z }
										
			Timers:CreateTimer(0.15, function()
			ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, target)
			if numslash == 3 then
			ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(4, table[numslash], 0))
			caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 5)
			local test_hit = ParticleManager:CreateParticle("particles/nanaya_hit_test.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(test_hit, 1, target:GetAbsOrigin() + knockback_push1 * 120)
			ParticleManager:SetParticleControl(test_hit, 0, target:GetAbsOrigin())
			end
		
			target:EmitSound("nanaya.slash")
			if not IsKnockbackImmune(target) then
				target:AddNewModifier(caster, self, "modifier_knockback", knockback)
			end
			--ParticleManager:CreateParticle("particles/nanaya_e1.vpcf", PATTACH_ABSORIGIN, target)
			DoDamage(caster, target, dmg, DAMAGE_TYPE_MAGICAL, 0, caster:FindAbilityByName("nanaya_slashes"), false)
			--[[ApplyDamage({
                    victim = target,
                    attacker = caster,
                    damage = dmg,
                    damage_type = DAMAGE_TYPE_PHYSICAL,
                    damage_flags = 0,
                    ability = self
                })]]
			ScreenShake(target:GetOrigin(), 10, 1.0, 0.1, 2000, 0, true)
					--ParticleManager:SetParticleControl(test_hit, 1, units:GetAbsOrigin() + units:GetForwardVector() * 180)
					end)
	return 0.3
	else
		caster:RemoveModifierByName("nanaya_jump_revoke")
	caster:RemoveEffects(32)
	caster:SetRenderAlpha(255)
	FindClearSpaceForUnit(caster, caster:GetOrigin(), true)
	if caster:HasModifier("nanaya_blood_modifier_animemode")
 then 
	nanaya_clones1:clones_2D(caster, target, knockback_push1, dmg)
	end
end
	end)
	end)
	--print (secondtime)
	
	--[[knockback_push1 = caster:GetForwardVector()*30
	
											local numberhit = 0
											local cloneanim = 14
											Timers:CreateTimer(0.1, function()
											if numberhit < 4 then
											knockback_push = target:GetAbsOrigin() - knockback_push1*(0+4)
										
											print (knockback_push)
											numberhit = numberhit + 1
											local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone.vpcf", PATTACH_CUSTOMORIGIN, caster)
											cloneanim = cloneanim + 1
											
	ParticleManager:SetParticleControl(nanaya_clone, 0, knockback_push) --0.35
	ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, table[numberhit], 0))
	ParticleManager:SetParticleControl(nanaya_clone, 4, target:GetAbsOrigin())
	
	
	local test = string.format("nanaya.clonetp%s", numberhit)
																				--print (ACT_DOTA_CAST_ABILITY_3)
	target:EmitSound(test)
	 
		local knockback = { should_stun = true,
										knockback_duration = 0.1,
										duration = 0.1,
										knockback_distance = 250,
										knockback_height = 0,
										center_x = knockback_push.x,
										center_y = knockback_push.y,
										center_z = target:GetAbsOrigin().z }
										
			Timers:CreateTimer(0.15, function()
			ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, target)
			caster:PerformAttack (
			taget,
			true,
			true,
			true,
			false,
			false,
			false,
			true
		)
			target:EmitSound("nanaya.slash")
			target:AddNewModifier(caster, self, "modifier_knockback", knockback)
			ParticleManager:CreateParticle("particles/nanaya_e1.vpcf", PATTACH_ABSORIGIN, target)
			DoDamage(caster, target, 250, DAMAGE_TYPE_PHYSICAL, 0, self, false)
			ScreenShake(target:GetOrigin(), 10, 1.0, 0.1, 2000, 0, true)
					--ParticleManager:SetParticleControl(test_hit, 1, units:GetAbsOrigin() + units:GetForwardVector() * 180)
			end)
			
	return 0.4
	
	end
	end)]]
	end
	
	function nanaya_clones1:clones_2D(caster, target, knockback_push1, dmg)
	local table = {12, 13, 12}
	local numberhit = 0
	local clone_dmg = dmg
	Timers:CreateTimer(0.1, function()
			--target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.4 })
											if numberhit < 3 then
											--knockback_push = units:GetAbsOrigin() - units:GetForwardVector() * 120
											knockback_push = target:GetAbsOrigin() + knockback_push1*120
											
											numberhit = numberhit + 1
											local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone.vpcf", PATTACH_CUSTOMORIGIN, caster)
											
											
	ParticleManager:SetParticleControl(nanaya_clone, 0, knockback_push) --0.35
	ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, table[numberhit], 0))
	ParticleManager:SetParticleControl(nanaya_clone, 4, target:GetAbsOrigin())
	
	--local nanaya_clone_jump = ParticleManager:CreateParticle("particles/blink_z1.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--ParticleManager:SetParticleControl(nanaya_clone_jump, 1, knockback_push)
	
	 
		local knockback = { should_stun = false,
										knockback_duration = 0.1,
										duration = 0.1,
										knockback_distance = 250,
										knockback_height = 0,
										--center_x = units:GetAbsOrigin().x - units:GetForwardVector().x * 180,
									   --center_y = units:GetAbsOrigin().y - units:GetForwardVector().y * 180,
										center_x = knockback_push.x,
										center_y = knockback_push.y,
										center_z = target:GetAbsOrigin().z }
										
			Timers:CreateTimer(0.15, function()
			ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, target)
	if numberhit == 3 then
			ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(4, table[numslash], 0))
			local test_hit = ParticleManager:CreateParticle("particles/nanaya_hit_test.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(test_hit, 1, target:GetAbsOrigin() - knockback_push1 * 120)
			ParticleManager:SetParticleControl(test_hit, 0, target:GetAbsOrigin())
			end
			target:EmitSound("nanaya.slash")
			if not IsKnockbackImmune(target) then
				target:AddNewModifier(caster, self, "modifier_knockback", knockback)
			end
			DoDamage(caster, target, dmg, DAMAGE_TYPE_MAGICAL, 0, caster:FindAbilityByName("nanaya_slashes"), false)
			--[[ApplyDamage({
                    victim = target,
                    attacker = caster,
                    damage = dmg,
                    damage_type = DAMAGE_TYPE_PHYSICAL,
                    damage_flags = 0,
                    ability = self
                })]]
			ScreenShake(target:GetOrigin(), 10, 1.0, 0.1, 2000, 0, true)
					--ParticleManager:SetParticleControl(test_hit, 1, units:GetAbsOrigin() + units:GetForwardVector() * 180)
			end)
			
	return 0.3
	
	end
	end)
	end


--end
--ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() +caster:GetForwardVector()*180)
--ParticleManager:SetParticleControl(particle, 0, caster:GetForwardVector()*180)

--end
--end


nanaya_slashes_modifier1 = class ({})


function nanaya_slashes_modifier1:OnCreated(args)
if IsServer() then 
	self.caster = self:GetParent()
self.target = EntIndexToHScript(args.target)
self.truecaster = EntIndexToHScript(args.vector)
self.particle = args.part
self:StartIntervalThink(0.05)
--self.target = EntIndexToHScript(args.target)
print (self.target)
self.sin1 = Physics:Unit(self.target)
self.target:SetPhysicsFriction(0)
    self.target:SetPhysicsVelocity(self.truecaster:GetForwardVector() * 1000)
    self.target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      self.target:SetGroundBehavior (PHYSICS_GROUND_LOCK)
	  
	  self.target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
	  	self.truecaster:RemoveModifierByName("modifier_knockback")
        unit:OnPreBounce(nil)
        unit:SetBounceMultiplier(0)
        unit:PreventDI(false)
        unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		end)
		end
	end
		
function nanaya_slashes_modifier1:OnIntervalThink()	
if not self.truecaster:IsAlive() or self.truecaster:IsStunned() then
self:Destroy() 
end		
end
		
function nanaya_slashes_modifier1:OnDestroy()
	if IsServer() then 
        self.target:OnPreBounce(nil)
      self.target:SetBounceMultiplier(0)
        self.target:PreventDI(false)
        self.target:SetPhysicsVelocity(Vector(0,0,0))
        self.target:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        self.truecaster:RemoveModifierByName("modifier_knockback")
		--self.truecaster:OnPreBounce(nil)
       -- self.truecaster:SetBounceMultiplier(0)
		--self.truecaster:PreventDI(false)
       -- self.truecaster:SetPhysicsVelocity(Vector(0,0,0))
      --  self.truecaster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		ParticleManager:DestroyParticle(self.particle, false)
	ParticleManager:ReleaseParticleIndex(self.particle)
		--FindClearSpaceForUnit(self.target, self.target:GetAbsOrigin(), true)
	end
		end
		

nanaya_slashes_modifier = class ({})

function nanaya_slashes_modifier:GetPriority() return MODIFIER_PRIORITY_HIGH end
function nanaya_slashes_modifier:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function nanaya_slashes_modifier:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
					   return state
end


function nanaya_slashes_modifier:OnCreated()
if IsServer() then
self.parent = self:GetParent()
self.ability = self:GetAbility()
self.point = self.ability:GetCursorPosition()
self.distances = 500
self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
self:StartIntervalThink(FrameTime())
end
end
function nanaya_slashes_modifier:OnIntervalThink()
	self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
	--self:UpdateHorizontalMotion(self:GetParent(), 0.02)
	end

function nanaya_slashes_modifier:UpdateHorizontalMotion(hero, times)
	  if self.distances >= 0 then 
	  local speed = 900 * times
            local parent_pos = self.parent:GetAbsOrigin()

            self.next_pos = parent_pos + self.direction * speed
			self.distances = self.distances - speed
    self.parent:SetOrigin(self.next_pos)
	self.parent:FaceTowards(self.point)
	else
	self:Destroy()
	end
	end
	
	function nanaya_slashes_modifier:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

	
	function nanaya_slashes_modifier:OnDestroy()
	--self.parent:SetOrigin(Vector(self.next_pos.x, self.next_pos.y, 128))
	if IsServer() then
        self.parent:InterruptMotionControllers(true)
		end
	end
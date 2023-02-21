LinkLuaModifier("nanaya_jump_slashes_modifier_back", "abilities/nanaya/nanaya_r", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_jump_slashes_modifier", "abilities/nanaya/nanaya_r", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_jump_revoke", "abilities/nanaya/nanaya_r", LUA_MODIFIER_MOTION_NONE)

nanaya_jump_revoke = class({})

function nanaya_jump_revoke:CheckState()
    local state =   { 
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		--[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
	}
	return state
end


nanaya_jump_slashes = class ({})

function nanaya_jump_slashes:OnSpellStart()
local caster = self:GetCaster()
self.kappa = false
caster:EmitSound("nanaya.rstart")
--[[if caster:HasModifier("modifier_nanaya_animation_knife") then 
--caster:FadeGesture(ACT_SCRIPT_CUSTOM_0)
caster:AddNewModifier(caster, self, "nanaya_jump_slashes_modifier", {knife = true})
caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_8, 2)
caster:RemoveModifierByName("modifier_nanaya_animation_knife")
else]]
caster:EmitSound("nanaya.jumpff")
local point = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*350, caster)
local jump = ParticleManager:CreateParticle("particles/shiki_afterearth2final.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControl(jump, 0, point)
local jump_clones = ParticleManager:CreateParticle("particles/nanaya_image_clone_rework.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
ParticleManager:SetParticleControl(jump_clones, 4, caster:GetAbsOrigin() + caster:GetForwardVector())
--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_6, 0.7)
--caster:AddNewModifier(caster, self, "nanaya_jump_slashes_modifier_back", {})									
caster:AddNewModifier(caster, self, "nanaya_jump_revoke", {duration = 1})
--local point1 = self:GetCursorPosition()
--local direction = (point1 - caster:GetOrigin()):Normalized()
local point = self:GetCursorPosition() + RandomVector(1)
local direction = (point - caster:GetAbsOrigin()):Normalized()
--[[local sin1 = Physics:Unit(caster)
			 caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x*-400,caster:GetForwardVector().y *-400, 0))
	--caster:SetPhysicsVelocity(caster))
    caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
     -- caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)
			Timers:CreateTimer("nanaya_zange1", {
			endTime = 0.8,
        callback = function()
        caster:OnPreBounce(nil)
		print (caster:GetAbsOrigin())
        caster:SetBounceMultiplier(0)
        caster:PreventDI(false)
        caster:SetPhysicsVelocity(Vector(0,0,0))
        --caster:RemoveModifierByName("pause_sealenabled")
     
        --caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		caster:AddNewModifier(caster, self, "nanaya_jump_slashes_modifier", {})
		return end 
		})]]
		
		local knockback = { should_stun = false,
	                                knockback_duration = 0.35,
	                                duration = 0.35,
	                                knockback_distance = 250,
	                                knockback_height = 90,
	                                center_x = caster:GetAbsOrigin().x + caster:GetForwardVector().x * 350,
	                                center_y = caster:GetAbsOrigin().y + caster:GetForwardVector().y * 350,
	                                center_z = caster:GetAbsOrigin().z }
									caster:AddNewModifier(caster, self, "modifier_knockback", knockback)
									
									Timers:CreateTimer(0.4, function()
										local nanaya_clone_jump = ParticleManager:CreateParticle("particles/blink_z1.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
				ParticleManager:SetParticleControl(nanaya_clone_jump, 1, GetGroundPosition(caster:GetAbsOrigin(), nil))
									caster:AddNewModifier(caster, self, "nanaya_jump_slashes_modifier", {})
									local qdProjectile = 
        {
            Ability = self,
            EffectName = nil,
            iMoveSpeed = 700,
            vSpawnOrigin = caster:GetOrigin(),
            fDistance =  1400,
            fStartRadius = 150,
            fEndRadius = 150,
            Source = caster,
            bHasFrontalCone = true,
            bReplaceExisting = true,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 2.0,
            bDeleteOnHit = true,
            vVelocity = direction * 800, 
			ExtraData = { nil }
        }
		local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
									caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_6, 1.44)
									end)
		--[[caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
        Timers:RemoveTimer("nanaya_zange1")
        unit:OnPreBounce(nil)
        unit:SetBounceMultiplier(0)
        unit:PreventDI(false)
        unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        --caster:RemoveModifierByName("pause_sealenabled")
		end)]]
end






function nanaya_jump_slashes:GetCastPoint()
local caster = self:GetCaster()
if caster:HasModifier("modifier_nanaya_animation_knife") then 
return 0.15
else
return 0.2
end
end

function nanaya_jump_slashes:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
local check = tData.knife
local slash = 7
if hTarget == nil or self.kappa == true then return end
self.kappa = true
hTarget:EmitSound("nanaya.finalhit")
--hTarget:AddNewModifier(caster, self, "modifier_stunned", { Duration = 2 })
local caster = self:GetCaster()
--local modifier = caster:FindModifierByName("nanaya_blood_modifier")
local dmg = self:GetSpecialValueFor("dmg")
--if modifier:GetStackCount()+slash > modifier:GetMaxStackCount() then
	--modifier:SetStackCount(modifier:GetMaxStackCount())
--else
--modifier:SetStackCount(modifier:GetStackCount()+slash)
--end
local particle = ParticleManager:CreateParticle("particles/test_part_small1.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin() - caster:GetForwardVector()*250 + Vector (0, 0, 400))

--ParticleManager:CreateParticle("particles/shiki_lost_gate/shiki_lostgate.vpcf", PATTACH_ABSORIGIN, hTarget)
--Timers:CreateTimer(0.1, function ()
--[[if slash > 0 then
hTarget:EmitSound("nanaya.r_hit")
DoDamage(caster, hTarget, 50 , DAMAGE_TYPE_MAGICAL, 0, self, false)
slash = slash-1
return 0.075
end
end)]]
caster:EmitSound("nanaya.trigger")
local ability = self
--DoDamage(caster, hTarget, 400, DAMAGE_TYPE_MAGICAL, 0, self, false)
	DoDamage(caster, hTarget, dmg, DAMAGE_TYPE_PHYSICAL, 0, self, false)

caster:FadeGesture(ACT_DOTA_CAST_ABILITY_6)
caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_10, 1.4)
--Timers:CreateTimer(0.6, function()
--caster:FadeGesture(ACT_SCRIPT_CUSTOM_10)
--end)

caster:RemoveModifierByName("nanaya_jump_slashes_modifier")
print (check)
if tData.knife ~= nil then 
FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + caster:GetForwardVector()*400 , true) 
--caster:Stop()
--caster:SetForwardVector(caster:GetForwardVector()*-1)
else
FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + caster:GetForwardVector()*500 , true) 
local hit2 = ParticleManager:CreateParticle("particles/screen_spla22.vpcf", PATTACH_EYES_FOLLOW, hTarget)
local culling_kill_particle = ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, hTarget)
ParticleManager:SetParticleControl(particle, 5, caster:GetAbsOrigin() + caster:GetForwardVector()*250 + Vector (0, 0, -100))
local part2 = ParticleManager:CreateParticle("particles/hit21.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(part2, 0, caster:GetAbsOrigin() + Vector(0, 0, 0))
			--ParticleManager:SetParticleControlEnt(part2, 0, caster, PATTACH_POINT, "attach_leg1", caster:GetAbsOrigin(), true)
end
--caster:Stop()
--caster:SetForwardVector(caster:GetForwardVector()*-1)
end
	
nanaya_jump_slashes_modifier_back = class ({})
function nanaya_jump_slashes_modifier_back:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function nanaya_jump_slashes_modifier_back:CheckState()
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

function nanaya_jump_slashes_modifier_back:OnCreated()
if IsServer() then
self.distances = 600
speed = 500 * FrameTime()
self.parent = self:GetParent()
self.point_1 = self.parent:GetAbsOrigin() - self.parent:GetForwardVector()*500
self.point = GetGroundPosition(self.point_1, self.parent)
self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
end
--[[local sin1 = Physics:Unit(self.parent)
			 self.parent:SetPhysicsFriction(0)
    self.parent:SetPhysicsVelocity(self.parent:GetForwardVector() * -250)
	--caster:SetPhysicsVelocity(caster))
    self.parent:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      self.parent:SetGroundBehavior (PHYSICS_GROUND_LOCK)]]
			self:StartIntervalThink(FrameTime())
			end
			
function nanaya_jump_slashes_modifier_back:OnIntervalThink()			
self:UpdateHorizontalMotion(self.parent, FrameTime())
end

function nanaya_jump_slashes_modifier_back:UpdateHorizontalMotion(hero, times)
if self.distances >= 0 then 
	  --speed = 640 * times
	  --speed = speed+0.2
            parent_pos = self.parent:GetAbsOrigin()

            self.next_pos = parent_pos + self.direction * speed 
			self.distances = self.distances - speed
    self.parent:SetOrigin(self.next_pos + Vector(0, 0, 3))
	--print (self.interesting)
	--print (speed)
	print (self.next_pos)
	--self.parent:FaceTowards(self.next_pos)
	else 
    self:Destroy()
	end
	end	
	
function nanaya_jump_slashes_modifier_back:OnDestroy()
--self.parent:OnPreBounce(nil)
        self.parent:SetBounceMultiplier(0)
        self.parent:PreventDI(false)
        self.parent:SetPhysicsVelocity(Vector(0,0,0))
end

nanaya_jump_slashes_modifier = class ({})
function nanaya_jump_slashes_modifier:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function nanaya_jump_slashes_modifier:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                         [MODIFIER_STATE_INVULNERABLE] = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    }
					   return state
end


function nanaya_jump_slashes_modifier:OnCreated(args)
if IsServer() then
self.parent = self:GetParent()
--print ("is", args.knife)
--self.parent:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_6, 0.7)
self.ability = self:GetAbility()
--self.point = self.ability:GetCursorPosition()
self.point_1 = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*1200
self.point = GetGroundPosition(self.point_1, self.parent) 
self.height = GetGroundHeight(self.point, self.parent)
--self.point = GetGroundPosition(self.point1, self.parent)
self.distances = 800
self.back = 400
self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
--self.direction = self.point:Normalized()
--print (self.point)
self.nanayaframechange = 0
speed = 800 * FrameTime()
self.checking = self.back/speed 
--self.vector = Vector(0, 0, 0.1)
--self.vector = Vector(0, 0, self.parent:GetAbsOrigin().z/self.checking)
checkout = 0
--Timers:CreateTimer(0.6, function() 
--[[local qdProjectile = 
        {
            Ability = self.ability,
            EffectName = nil, --"particles/custom/false_assassin/fa_quickdraw.vpcf",
            iMoveSpeed = 700,
            vSpawnOrigin = self.parent:GetOrigin(),
            fDistance =  600,
            fStartRadius = 150,
            fEndRadius = 150,
            Source = self.parent,
            bHasFrontalCone = true,
            bReplaceExisting = true,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 2.0,
            bDeleteOnHit = true,
            vVelocity = Vector(self.direction.x, self.direction.y, 0) * 700, 
			ExtraData = { knife = args.knife }
        }
		local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
end)]]
self.vector = Vector(0, 0, (256/self.checking)/self.checking)
self.vector_1 = Vector(0, 0, (256/self.checking)/self.checking)
self.interesting = self.parent:GetAbsOrigin().z/self.checking
--self.vector_forw = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*self.distances
--self.check_ground = GetGroundHeight(Vector(self.vector_forw.x, self.vector_forw.y, self.parent:GetAbsOrigin().z), nil)
--self.check_ground = GetGroundPosition(Vector(self.vector_forw.x, self.vector_forw.y, self.parent:GetAbsOrigin().z), nil)
--print ("this is", self.check_ground)
--print (self.vector_1)
print ("is", self.height)
print ("is2", self.point)
self:StartIntervalThink(FrameTime())
self.check2 = 0
self.anothercheck = 500/self.checking

--self.vector_start = self.vector/self.checking
--print (self.vector)
end
--self:StartIntervalThink(0.022)
end



function nanaya_jump_slashes_modifier:OnIntervalThink()
	self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
	self.nanaya_image = ParticleManager:CreateParticle("particles/nanaya_image.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.nanaya_image, 0, self.parent:GetOrigin() - self.parent:GetForwardVector()*35)
	ParticleManager:SetParticleControl(self.nanaya_image, 4, self.point)
	ParticleManager:SetParticleControl(self.nanaya_image, 2, Vector(self.nanayaframechange, 26, 0))
	self.nanayaframechange = self.nanayaframechange + 1
	print (self.nanayaframechange)
	--self:UpdateHorizontalMotion(self:GetParent(), 0.02)
	end



function nanaya_jump_slashes_modifier:UpdateHorizontalMotion(hero, times)
	  if self.distances >= 0 then 
	  --speed = 640 * times
	  speed = speed+0.2
            parent_pos = self.parent:GetAbsOrigin()

            self.next_pos = parent_pos + self.direction * speed 
			self.distances = self.distances - speed
    self.parent:SetOrigin(self.next_pos + Vector(0, 0, 4))
	--print (self.interesting)
	--print (speed)
	--self.parent:FaceTowards(self.next_pos)
	else 
    self:UpdateVerticalMotion(self:GetParent(), FrameTime())
	end
	end	
	
function nanaya_jump_slashes_modifier:UpdateVerticalMotion(hero, times)
    if self.check2 ==0 then
    --self.parent:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_7, 1)
	self.check2 = 1
	end
    --speed = 1000* times
	if self.back >= 0 then
	parent_pos = self.parent:GetAbsOrigin()
	self.vector = self.vector_1 + self.vector
	--self.vector = self.vector_start + self.vector
    --self.vector = parent_pos.z
            self.next_pos = parent_pos + self.direction * speed 
	self.back = self.back - speed
	--self.next_pos = parent_pos + self.direction * speed 
	self.check1 = self.next_pos - self.vector*2 
	self.parent:SetOrigin(self.next_pos - self.vector*2)
	--print (self.check1)
	--self.parent:FaceTowards(self.next_pos)
	else
	self:Destroy()
	end
	end
	function nanaya_jump_slashes_modifier:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

	
	function nanaya_jump_slashes_modifier:OnDestroy()
	--ParticleManager:DestroyParticle(self.nanaya_image, true)
	--self.parent:SetOrigin(Vector(self.next_pos.x, self.next_pos.y, 128))
	--self.parent:FadeGesture(ACT_DOTA_CAST_ABILITY_6)
	if IsServer() then
	self.parent:FadeGesture(ACT_SCRIPT_CUSTOM_8)
        self.parent:InterruptMotionControllers(true)
		end
	end

	
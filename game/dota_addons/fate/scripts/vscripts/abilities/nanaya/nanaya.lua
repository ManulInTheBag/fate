
LinkLuaModifier("modifier_nanaya_knife_set", "abilities/nanaya/nanaya", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_combo_modifier", "abilities/nanaya/nanaya", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("nanaya_anim_modifier", "abilities/nanaya/nanaya", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_combo_anim_modifier", "abilities/nanaya/nanaya", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_blood_modifier_animemode", "abilities/nanaya/nanaya_blood", LUA_MODIFIER_MOTION_NONE)





	




modifier_nanaya_knife_set = class({})

function modifier_nanaya_knife_set:OnCreated()
end


nanaya_clones = class ({})

function nanaya_clones:OnSpellStart()
local caster = self:GetCaster()

local units = self:GetCursorTarget()
local knockback1 = { should_stun = true,
	                                knockback_duration = 0.1,
	                                duration = 0.15,
	                                knockback_distance = 200,
	                                knockback_height = 0,
	                                center_x = units:GetAbsOrigin().x - caster:GetForwardVector().x * 180,
	                                center_y = units:GetAbsOrigin().y - caster:GetForwardVector().y * 180,
	                                center_z = units:GetAbsOrigin().z }								
units:EmitSound("nanaya.slash")
	    units:AddNewModifier(caster, self, "modifier_knockback", knockback1)
	 --nanaya_clones:Clones(caster, units)
end


 
 
										
										
										

									


		
--[[function nanaya_combo:Start(caster, target)
--local caster = 
--local target = self:GetCursorTarget()
print (caster)
local player_1 = caster:GetPlayerOwner()
local player_2 = target:GetPlayerOwner()
CustomGameEventManager:Send_ServerToPlayer(player_1, "disable_ui", {})
CustomGameEventManager:Send_ServerToPlayer(player_2, "disable_ui", {})
PlayerResource:SetCameraTarget(target:GetPlayerID(), target)
nanaya_combo:main(caster, target)
end
	
function nanaya_combo:main(caster, target, retreat)
--caster:Stop()
--caster:Stop()
--if IsServer() then
local caster = caster	
local target = target
if retreat == nil then 
--local ubwCenter = Vector(4000, -4398, 200)
--FindClearSpaceForUnit(caster, ubwCenter, true)
--FindClearSpaceForUnit(target, ubwCenter, true)
--target:SetAbsOrigin(Vector(-5000, -4398, 200))
--caster:SetAbsOrigin(self.pos)
self.pos = target:GetAbsOrigin() - target:GetForwardVector()*90
self.view  = target:GetForwardVector()
else
self.pos = target:GetAbsOrigin() + target:GetForwardVector()*90
--180
self.view = target:GetForwardVector()*-1
end
--print (self.view)
--caster:SetForwardVector(self.view)
caster:SetAbsOrigin(self.pos)
--FindClearSpaceForUnit(caster, self.pos, true)
--caster:Stop()
--caster:SetForwardVector(self.view)
--caster:Stop()

caster:SetForwardVector(self.view)
caster:Stop()
Timers:CreateTimer(0.01, function()
caster:SetForwardVector(self.view)
--FindClearSpaceForUnit(caster, self.pos, true)
--caster:SetForwardVector(self.view)

caster:Stop()	
end)
--140
local somerandom = {ACT_DOTA_CAST_ABILITY_3, ACT_SCRIPT_CUSTOM_1, ACT_DOTA_ATTACK, ACT_SCRIPT_CUSTOM_1, ACT_DOTA_CAST_ABILITY_3, ACT_DOTA_ATTACK}
--somerandom = {ACT_DOTA_ATTACK, ACT_SCRIPT_CUSTOM_1, ACT_DOTA_CAST_ABILITY_3, ACT_SCRIPT_CUSTOM_1, ACT_DOTA_CAST_ABILITY_3, ACT_DOTA_ATTACK}
clone_table = {15, 16, 15, 16, 15, 17}
--clone_table = {15, 16, 17, 16, 15, 17}
local numberhit = 0
                                 Timers:CreateTimer(0.01, function()
								 
								 if numberhit < 5 then 
								 numberhit = numberhit + 1
								--caster:FadeGesture(somerandom[numberhit])
								target:SetAbsOrigin(target:GetAbsOrigin() + caster:GetForwardVector()* 180)
								caster:SetAbsOrigin(target:GetAbsOrigin() - caster:GetForwardVector()* 180)
								 --testing = caster:GetCycle()
								 --[[local knockback = { should_stun = false,
	                                knockback_duration = 0.1,
	                                duration = 0.1,
	                                knockback_distance = 150,
	                                knockback_height = 0,
	                                center_x = target:GetAbsOrigin().x - caster:GetForwardVector().x * 180,
	                                center_y = target:GetAbsOrigin().y - caster:GetForwardVector().y * 180,
	                                center_z = caster:GetAbsOrigin().z }]]
									
									

 --[[local knockback2 = { should_stun = false,
	                                knockback_duration = 0.1,
	                                duration = 0.1, 
	                                knockback_distance = -150,
	                                knockback_height = 0,
	                                center_x = target:GetAbsOrigin().x,
	                                center_y = target:GetAbsOrigin().y,
	                                center_z = target:GetAbsOrigin().z }]]									
										
										--target:AddNewModifier(caster, self, "modifier_knockback", knockback)
										--caster:AddNewModifier(caster, self, "modifier_knockback", knockback2)
										--[[target:EmitSound("nanaya.slash")
										caster:PerformAttack (
		target,
		true,
		true,
		true,
		false,
		false,
		false,
		true
	)
	--575, 583
	--496, 511, framerate 5, hold at 499
										caster:StartGestureWithPlaybackRate(somerandom[numberhit], 3.2)
										--2.4
										--2.6
										--0.25
													
										local nanaya_clone2 = ParticleManager:CreateParticle("particles/nanaya_image_clone2.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControl(nanaya_clone2, 0, caster:GetOrigin())
ParticleManager:SetParticleControl(nanaya_clone2, 2, Vector(0, clone_table[numberhit], 0))
ParticleManager:SetParticleControl(nanaya_clone2, 4, target:GetAbsOrigin())
										return 0.2
                                    else
									if retreat == nil then 
									nanaya_combo:main(caster, target, 1)
									else
									--nanaya_combo:second_stage(caster, target)
									end
									end
									end)
									--end
									end
	
function nanaya_combo:second_stage(caster, target)
local caster = caster
local target = target
--if IsServer() then
caster:AddNewModifier(caster, self, "nanaya_combo_anim_modifier", {duration = 0.5})
--caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_2, 1)
--end
end

function nanaya_combo:second_stage_1(caster, target)
local whywont = {ACT_SCRIPT_CUSTOM_4, ACT_SCRIPT_CUSTOM_5, ACT_SCRIPT_CUSTOM_6}
local player_1 = caster:GetPlayerOwner()
local player_2 = target:GetPlayerOwner()
--local caster = caster
--local target = target
local heart = 0
EmitGlobalSound("nanaya.combo")
Timers:CreateTimer({
endTime = 1, 
--6.1
--502
callback = function()
ParticleManager:CreateParticle("particles/screen_black_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
--hTarget:GetAbsOrigin() + Vector (0,0, 45) + caster:GetForwardVector()*-45
--caster:StartGestureWithPlaybackRate(whywont[1], 1)

local throw = target:GetAbsOrigin() - caster:GetForwardVector()* 180
caster:SetAbsOrigin(throw)
Timers:CreateTimer(function()
if heart < 3 then
if heart == 1 then

EmitGlobalSound("nanaya.kekshi")
caster:SetOrigin(target:GetAbsOrigin() + Vector (0, 0, 65))

end
if heart == 2 then 
caster:SetAbsOrigin(throw)
EmitGlobalSound("nanaya.nanaya")
end
heart = heart+1
caster:StartGestureWithPlaybackRate(whywont[heart], 1)
EmitGlobalSound("nanaya.heart")
return 2
else
CustomGameEventManager:Send_ServerToPlayer(player_1, "enable_ui", {})
CustomGameEventManager:Send_ServerToPlayer(player_2, "enable_ui", {})
end
end)
--print ("work")
end
})
end

nanaya_combo_anim_modifier = class({})

function nanaya_combo_anim_modifier:GetPriority() return MODIFIER_PRIORITY_HIGH end



function nanaya_combo_anim_modifier:DeclareFunctions() 
  local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
  }
 
  return funcs
end

function nanaya_combo_anim_modifier:OnCreated()
if IsServer() then 
self.caster = self:GetParent()
self.check = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
self.target = self.check[1]
--print (self.target)
end
end

function nanaya_combo_anim_modifier:GetOverrideAnimation()
  --return somerandom[numberhit]
  return ACT_SCRIPT_CUSTOM_2
end

function nanaya_combo_anim_modifier:GetOverrideAnimationRate() 
  --return somerandom[numberhit]
  return 1
end

function nanaya_combo_anim_modifier:OnDestroy()
--print (self.caster)
if IsServer() then
self:GetParent():EmitSound("nanaya.hit")
								 local knockback = { should_stun = false,
	                                knockback_duration = 0.5,
	                                duration = 0.5,
	                                knockback_distance = 900,
	                                knockback_height = 0,
	                                center_x = self.target:GetAbsOrigin().x - self:GetParent():GetForwardVector().x * 180,
	                                center_y = self.target:GetAbsOrigin().y - self:GetParent():GetForwardVector().y * 180,
	                                center_z = self:GetParent():GetAbsOrigin().z }
									self.target:AddNewModifier(self.caster, self, "modifier_knockback", knockback)
									Timers:CreateTimer(0.1, function() 
									nanaya_combo:second_stage_1(self.caster, self.target)
                                    --StartAnimation(self.caster, {duration=1, activity=ACT_SCRIPT_CUSTOM_3, rate=1})
									--self.caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_3, 1)
									--print (1)
									end)
end
end
--[[function nanaya_combo:(target)
local nottarget = target
print (nottarget)
end]]
									
--[[nanaya_combo_modifier = class({})	
function nanaya_combo_modifier:GetPriority() return MODIFIER_PRIORITY_HIGH end
function nanaya_combo_modifier:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function nanaya_combo_modifier:CheckState()
  local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
						[MODIFIER_STATE_STUNNED] = true,
                    }
    return state			
end	]]

		
nanaya_return = nil

nanaya_dashf = class ({})

function nanaya_dashf:OnSpellStart()
local caster = self:GetCaster()
ProjectileManager:ProjectileDodge(caster)
local point = self:GetCursorPosition()
       -- self.return1 = nil
   -- else
local casterabs = caster:GetAbsOrigin()
local direction = GetDirection(point, caster) --(point - caster:GetAbsOrigin()):Normalized()
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
									
									local sAbil1 = caster:GetAbilityByIndex(4)
        if sAbil1:GetAbilityName() == "nanaya_dashf" then
		caster:SwapAbilities("nanaya_dashf_return", "nanaya_dashf", true, false)
end
     nanaya_return = casterabs
     Timers:CreateTimer(0.4, function()
     	local sAbil2 = caster:GetAbilityByIndex(4)
      if sAbil2:GetAbilityName() == "nanaya_dashf" or sAbil2:GetAbilityName() == "nanaya_dashf_return" then
		caster:SwapAbilities("nanaya_dashf", "nanaya_dashf_return", true, false)
end

end)
--end
end

function nanaya_dashf:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
local caster = self:GetCaster()
if hTarget == nil then return end
local dmg = self:GetSpecialValueFor("dmg") + math.floor(self:GetCaster():GetAgility()*self:GetSpecialValueFor("agi_modifier") )

hTarget:EmitSound("nanaya.slash")
--hTarget:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.5 })
ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, hTarget)
print (hTarget)
DoDamage(caster, hTarget, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
--DoDamage(caster, hTarget, 400, DAMAGE_TYPE_MAGICAL, 0, self, false)

end



nanaya_dashf_return = class ({})
function nanaya_dashf_return:OnSpellStart()
local caster = self:GetCaster()

        FindClearSpaceForUnit(caster, nanaya_return , true) 
end




	







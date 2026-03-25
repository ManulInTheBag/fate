LinkLuaModifier("modifier_combo", "abilities/nanaya/nanaya_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_combo_attack", "abilities/nanaya/nanaya_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_combo_cd", "abilities/nanaya/nanaya_combo", LUA_MODIFIER_MOTION_NONE)


nanaya_combo = class ({})

function nanaya_combo:OnSpellStart()
local caster = self:GetCaster()
caster:AddNewModifier(caster, self, "nanaya_combo_attack", { duration = self:GetSpecialValueFor("counter_duration")})		
caster:AddNewModifier(caster, self, "nanaya_combo_cd", { duration = self:GetCooldown(1)})		
local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
masterCombo:EndCooldown()
masterCombo:StartCooldown(self:GetCooldown(1))
end					


function nanaya_combo:Alternate(caster, target, ability)
--EmitGlobalSound("nanaya.combo_music")
PlayerResource:SetCameraTarget(target:GetPlayerID(), caster)
PlayerResource:SetCameraTarget(caster:GetPlayerID(), caster)
local combo_part = ParticleManager:CreateParticle(nil, PATTACH_ABSORIGIN_FOLLOW, target)
EmitGlobalSound("nanaya.combo_execute")
print ("that", caster:GetOrigin())
--ParticleManager:SetParticleControl(combo_part, 2, GetGroundPosition(target:GetOrigin(), nil))
       -- ParticleManager:SetParticleControl(combo_part, 0, GetGroundPosition(Vector(-4910.000000, -4398.000000, 170.000000), nil))
--caster:SetRenderAlpha(0)
caster:Stop()
target:AddNewModifier(caster, caster, "modifier_combo", {Duration = 3})
caster:AddNewModifier(caster, caster, "modifier_combo", {Duration = 3})
target:Stop()
--local check4 = nil
local sec2 = target:GetAbsOrigin()
local sec1 = caster:GetOrigin()
--caster:SetAbsOrigin(Vector(-5000, -4100, 170))
--target:SetAbsOrigin(Vector(-5000, -4398, 170))
local targetabs = target:GetAbsOrigin()
--local nanaya_hit = target:GetAbsOrigin() + Vector(0, 0, (target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")).z - target:GetOrigin().z) - 75) + caster:GetForwardVector()
	--local nanaya_hit = target:GetAbsOrigin() + Vector(0, 0, (target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_origin")).z - target:GetOrigin().z) - 75) + caster:GetForwardVector()
--local combo_nanaya = ParticleManager:CreateParticle("particles/nanayatest.vpcf", PATTACH_CUSTOMORIGIN, caster)
--local pepega_angle = QAngle(0, 0, 0)
	caster:SetAbsAngles(0, 0, 0)
	caster:Stop()
	target:SetAbsAngles(0, 0, 0)
caster:SetForwardVector(Vector(-1, 0, 0))
			target:SetForwardVector(Vector(1, 0, 0))
local targetforwardvector = target:GetForwardVector()
			local player = target:GetPlayerOwner()
			local player2 = caster:GetPlayerOwner()
			local ff2 = math.floor(target:GetLocalAngles().y)
--CustomGameEventManager:Send_ServerToPlayer(player2, "disable_ui", {angles = ff2})
--CustomGameEventManager:Send_ServerToPlayer(player, "disable_ui", {angles = ff2})
--target:SetAbsOrigin(Vector(-5000, -4398, -1000))
local nanaya_knife2 = nil


--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*90)
--ParticleManager:SetParticleControl(combo_nanaya, 4, targetabs)				
caster:Stop()
caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_16, 1.4)
caster:SetOrigin(targetabs + targetforwardvector*90)

        --[-4910.000000 -4398.000000 170.000000]
        --ParticleManager:ReleaseParticleIndex(combo_part)
target:Stop()
Timers:CreateTimer(0.15, function()
caster:EmitSound("nanaya.kekshi1")
local nanaya_knife = ParticleManager:CreateParticle("particles/nanaya_last_arc.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControlEnt(nanaya_knife, 0, caster, PATTACH_POINT, "attach_knife", caster:GetAbsOrigin(), true)

local nanaya_knife1 = ParticleManager:CreateParticle("particles/nanaya_last_arc2.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControlEnt(nanaya_knife1, 0, caster, PATTACH_POINT_FOLLOW, "attach_knife", caster:GetAbsOrigin(), true)

Timers:CreateTimer(0.30, function()
local knife = ParticleManager:CreateParticle("particles/maybedashvpcffinalfinal.vpcf", PATTACH_CUSTOMORIGIN, caster)
--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*250)	
ParticleManager:SetParticleControlEnt(knife, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand", caster:GetAbsOrigin(), true)
ParticleManager:SetParticleControl(knife, 4, target:GetAbsOrigin())
end)

Timers:CreateTimer(0.350, function()
	ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player)
ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player2)
--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*250)	

--local nanaya_clone2 = ParticleManager:CreateParticle("particles/nanaya_image_clone1.vpcf", PATTACH_CUSTOMORIGIN, caster)
										--cloneanim = cloneanim + 1
										
--ParticleManager:SetParticleControl(nanaya_clone2, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-60)  --0.35
--ParticleManager:SetParticleControl(nanaya_clone2, 2, Vector(0, 12, 24))
--ParticleManager:SetParticleControl(nanaya_clone2, 4, targetabs)
	--local nanaya_hit = target:GetAbsOrigin() + Vector(0, 0, (target:GetAttachmentOrigin(0).z - target:GetOrigin().z) + 100) + caster:GetForwardVector()*-45
	local nanaya_hit = target:GetAbsOrigin() + Vector(0, 0, (target:GetAttachmentOrigin(0).z - target:GetOrigin().z)) + caster:GetForwardVector()*-45
caster:SetOrigin(nanaya_hit)
nanaya_knife2 = ParticleManager:CreateParticle("particles/test_part2.vpcf", PATTACH_CUSTOMORIGIN, caster)

ParticleManager:SetParticleControl(nanaya_knife2, 0, targetabs + Vector (0, 0, 100))



local check = target:GetAttachmentOrigin(target:ScriptLookupAttachment("ATTACH_HITLOC"))
print (check)
check4 = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hand"))
print ()
--ParticleManager:SetParticleControl(combo_nanaya, 0, nanaya_hit)	
end)
end)
Timers:CreateTimer(1.20, function()
--DoDamage(caster, target, 100, DAMAGE_TYPE_MAGICAL, 0, ability, false)
ScreenShake(targetabs, 14, 20, 1, 2000, 0, true)
local nanaya_knife1 = ParticleManager:CreateParticle("particles/pa_arcana_phantom_strike_end2.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControlEnt(nanaya_knife1, 0, caster, PATTACH_POINT, "attach_hand", caster:GetAbsOrigin(), true)
--caster:SetOrigin(nanaya_hit)
Timers:CreateTimer(0.5, function()
--ParticleManager:DestroyParticle(combo_nanaya, true)
--local nanaya_knife12 = ParticleManager:CreateParticle("particles/nanayatest1.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--ParticleManager:SetParticleControl(nanaya_knife12, 4, targetabs)
--ParticleManager:SetParticleControl(nanaya_knife12, 0, targetabs + targetforwardvector*250)
--caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_28, 6)
local nanaya_knife10 = ParticleManager:CreateParticle("particles/maybedashvpcffinalfinal.vpcf", PATTACH_CUSTOMORIGIN, caster)
ParticleManager:SetParticleControlEnt(nanaya_knife10, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand", caster:GetAbsOrigin(), true)
ParticleManager:SetParticleControl(nanaya_knife10, 4, targetabs + targetforwardvector*300)
	ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player)
ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player2)
--ParticleManager:SetParticleControl(combo_nanaya, 0, targetabs + targetforwardvector*250)	
		--caster:SetAbsAngles(0, 0, 0)
	--target:SetAbsAngles(0, 0, 0)
--caster:SetForwardVector(Vector(-1, 0, 0))
			--target:SetForwardVector(Vector(1, 0, 0))
					--caster:SetAbsAngles(0, 0, 0)
								ParticleManager:DestroyParticle(combo_part, true)
	caster:Stop()
	caster:SetForwardVector(Vector(-1, 0, 0))
	target:SetOrigin(sec2)
caster:SetOrigin(target:GetAbsOrigin() + caster:GetForwardVector()*-300)
--targetabs = target:GetAbsOrigin()

--caster:SetOrigin(targetabs + targetforwardvector*250)
--caster:SetOrigin(GetGroundPosition(sec1 - caster:GetForwardVector()*250, caster))
--FindClearSpaceForUnit(caster, sec1 - caster:GetForwardVector()*250, true)
--ParticleManager:ReleaseParticleIndex(combo_part)


Timers:CreateTimer(0.40, function()
--ParticleManager:ReleaseParticleIndex(combo_part)
--target:SetOrigin(sec2)
--caster:SetOrigin(target:GetAbsOrigin() + target:GetForwardVector()*250)
--FindClearSpaceForUnit(caster, sec2, true)
--FindClearSpaceForUnit(target, sec2, true)
--ParticleManager:DestroyParticle(nanaya_knife12, true)
--caster:SetRenderAlpha(255)
--target:RemoveEffects(32)
--local check1 = ParticleManager:CreateParticle("particles/centaur_double_edge_ti9_bloodspray_tgt.vpcf", PATTACH_CUSTOMORIGIN, target)
	--ParticleManager:SetParticleControl(check1, 0, target:GetAbsOrigin() + Vector (0, 0, 150))
--ParticleManager:DestroyParticle(check1, true)
Timers:CreateTimer(0.20, function()

local check1 = ParticleManager:CreateParticle("particles/ls_ti10_immortal_infest_groundfollow_trace.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
--ParticleManager:SetParticleControl(check1, 4, target:GetAbsOrigin())
ParticleManager:SetParticleControl(check1, 0, target:GetAbsOrigin())
 
	--ParticleManager:SetParticleControlForward(effect_cast, 1, (target:GetForwardVector()*-1):Normalized() )
local check2 = target:GetAbsOrigin() - target:GetForwardVector()*400
	--ParticleManager:SetParticleControl(check1, 5, Vector(1000, 0, 300))
	--ParticleManager:SetParticleControl(check1, 5, (target:GetAbsOrigin() - target:GetForwardVector()*250) + Vector(0, 0, 1000))
	print (check2.x)
	--target:SetOrigin(GetGroundPosition(sec2, target))
	    	--target:Kill(self, caster)
	    	DoDamage(caster, target, target:GetMaxHealth(), DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
	    	

--CustomGameEventManager:Send_ServerToPlayer(player, "nanaya_screen", {})
end)
Timers:CreateTimer(0.0350, function()
	--target:SetOrigin(GetGroundPosition(sec2, target))
	--caster:SetOrigin(target:GetAbsOrigin() + target:GetForwardVector()*300)
	--ParticleManager:CreateParticle( "particles/ls_ti10_immortal_infest_groundfollow_trace", PATTACH_ABSORIGIN_FOLLOW, target)
	--CustomGameEventManager:Send_ServerToPlayer(player, "nanaya_screen", {})
--CustomGameEventManager:Send_ServerToPlayer(player2, "enable_ui", {})
--CustomGameEventManager:Send_ServerToPlayer(player, "enable_ui", {})
Timers:CreateTimer(0.120, function()
		 local effect_cast = ParticleManager:CreateParticle( "particles/justcheck.vpcf", PATTACH_CUSTOMORIGIN, target)
	--[[ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_origin",
		target:GetOrigin(), -- unknown
		true -- unknown, true
	)]]
	ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin() + Vector(0, 0, 150))
		ParticleManager:SetParticleControlForward(effect_cast, 1, (target:GetOrigin()-caster:GetOrigin()):Normalized() )
		--target:Kill(self, caster)
		PlayerResource:SetCameraTarget(caster:GetPlayerID(), nil)
PlayerResource:SetCameraTarget(target:GetPlayerID(), nil)
end)
end)

end)
--PlayerResource:SetCameraTarget(target:GetPlayerOwnerID(), nil)
end)
end)
end
	
function nanaya_combo:Secret(caster, target, ability) --IN WORK
    EmitGlobalSound("nanaya.combo2")
	caster:AddNewModifier(caster, self, "nanaya_jump_revoke", {duration = 1.2})
	--local combo_part = ParticleManager:CreateParticle("particles/combo_nanaya.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	local player = target:GetPlayerOwner()
	local player2 = caster:GetPlayerOwner()
	local ff2 = math.floor(target:GetLocalAngles().y)
	local nanaya_clone = nil
	local return1 = caster:GetOrigin()
	local hit = nil
	local numhit = 120
	caster:SetAbsOrigin(Vector(-5000, -4398, 200))
	--caster:SetRenderAlpha(0)
	caster:EmitSound("nanaya.ikuzo")
	local dummy = CreateUnitByName("npc_dummy_unit", caster:GetOrigin(), true, caster, caster, caster:GetTeamNumber())
CustomGameEventManager:Send_ServerToPlayer(player2, "disable_ui", {angles = ff2})
CustomGameEventManager:Send_ServerToPlayer(player, "disable_ui", {angles = ff2})
target:SetForwardVector(Vector(1, 0, 0))
target:FaceTowards(Vector(1, 0, 0))
--target:SetAbsOrigin(Vector(-5000, -4398, 200))
--target:AddNewModifier(caster, caster, "modifier_combo", {Duration = 5})
	--local table = {12, 13, 21, 13, 23}
	local table = {12, 13, 46, 12, 23}
	--local table = {13, 12, 13, 23, 24}	
	local knockback_push1 = (Vector(-1, 0, 0))
	local numslash = 0
	local somerandom = {ACT_SCRIPT_CUSTOM_1, ACT_DOTA_CAST_ABILITY_3, ACT_SCRIPT_CUSTOM_1, ACT_DOTA_CAST_ABILITY_3, ACT_SCRIPT_CUSTOM_19}
	PlayerResource:SetCameraTarget(target:GetPlayerID(), target)
PlayerResource:SetCameraTarget(caster:GetPlayerID(), target)
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 2)
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 0.2)
	nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clon21.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 0.8)
	print (caster:GetRenderAlpha())
	Timers:CreateTimer(0.1, function()
	--caster:AddEffects(32)
	--caster:SetBodygroup(1, 0)
	--caster:SetRenderAlpha(0)
	if not somerandom[numslash] == nil then
	--caster:RemoveGesture(somerandom[numslash])
	end
	if numslash < 5 then
	numslash = numslash+1
					--caster:StartGestureWithPlaybackRate(somerandom[numslash], 4-numslash)
	print (somerandom[numslash])
	
	local nanaya_clone2 = ParticleManager:CreateParticle("particles/nanaya_image_clone1.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--local nanaya_clone2 = ParticleManager:CreateParticle(nil, PATTACH_CUSTOMORIGIN, caster)
											--cloneanim = cloneanim + 1
											
	ParticleManager:SetParticleControl(nanaya_clone2, 0, GetGroundPosition(dummy:GetAbsOrigin(), nil))--0.35
	ParticleManager:SetParticleControl(nanaya_clone2, 2, Vector(0, table[numslash], 10))
	ParticleManager:SetParticleControl(nanaya_clone2, 4, target:GetAbsOrigin())
	
	knockback_push = target:GetAbsOrigin() - knockback_push1*120
	--caster:SetOrigin((target:GetAbsOrigin() - knockback_push1*(0+4))- caster:GetForwardVector()*30)
	dummy:SetOrigin(knockback_push)
   -- caster:SetOrigin(knockback_push)
	if numslash ~= 5 then
   
	--nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clon2.vpcf", PATTACH_CUSTOMORIGIN, caster)
											--cloneanim = cloneanim + 1
	else
	nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clon22.vpcf", PATTACH_CUSTOMORIGIN, caster)
		--ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark2.vpcf", PATTACH_EYES_FOLLOW, caster, player)
--ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark2.vpcf", PATTACH_EYES_FOLLOW, caster, player2)
local nanaya_clone4 = ParticleManager:CreateParticle("particles/nanaya_work_21.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	dummy:EmitSound("nanaya.dzan")
	end										
	ParticleManager:SetParticleControl(nanaya_clone, 0, GetGroundPosition(knockback_push, nil)) --0.35
	ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(4, table[numslash], 0))
	ParticleManager:SetParticleControl(nanaya_clone, 4, target:GetAbsOrigin())
	
	local test = string.format("nanaya.clonetp%s", numslash)
																				--print (ACT_DOTA_CAST_ABILITY_3)
	--caster:EmitSound(test)
		local knockback = { should_stun = true,
										knockback_duration = 0.05,
										duration = 0.05,
										knockback_distance = 250,
										knockback_height = 0,
										center_x = knockback_push.x,
										center_y = knockback_push.y,
										center_z = target:GetAbsOrigin().z }
										
			Timers:CreateTimer(0.15, function()
			ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			if numslash == 5 then
			ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, table[numslash], 0))
			local test_hit = ParticleManager:CreateParticle("particles/nanaya_hit_test.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(test_hit, 1, target:GetAbsOrigin() + knockback_push1 * 120)
			ParticleManager:SetParticleControl(test_hit, 0, target:GetAbsOrigin())
			end
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
			target:EmitSound("nanaya.slash")
			target:AddNewModifier(caster, self, "modifier_knockback", knockback)
			--ParticleManager:CreateParticle("particles/nanaya_e1.vpcf", PATTACH_ABSORIGIN, target)
			--DoDamage(caster, target, 5, DAMAGE_TYPE_PHYSICAL, 0, self, false)
			ScreenShake(target:GetOrigin(), 10, 1.0, 0.1, 2000, 0, true)
					--ParticleManager:SetParticleControl(test_hit, 1, units:GetAbsOrigin() + units:GetForwardVector() * 180)
					end)
	return 0.25
	else
		caster:RemoveModifierByName("nanaya_jump_revoke")
		 dummy:ForceKill(true)
	--caster:RemoveEffects(32)
	--caster:SetRenderAlpha(255)
	--FindClearSpaceForUnit(caster, caster:GetOrigin(), true)
	--nanaya_clones:clones_2D(caster, target, knockback_push1)
	end
	end)

	Timers:CreateTimer(2, function()
		hit1 = ParticleManager:CreateParticle("particles/nanaya_combo_212.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		--[[if numhit > 1 then
		local baza = target:GetAbsOrigin()
		hit = ParticleManager:CreateParticle("particles/nanaya_combo_21.vpcf", PATTACH_CUSTOMORIGIN, caster)
  --  ParticleManager:SetParticleControl(hit, 3, Vector(3, table[numslash], 0))
    local x = math.random(-350, 350)
    local y = math.random(-350, 350)
    local Vector1 = Vector(target:GetAbsOrigin().x-x*math.random(1, 2), target:GetAbsOrigin().y-y*math.random(1, 2), math.random(400, 700))
    local Vector2 = Vector(target:GetAbsOrigin().x+x*-math.random(-4, 4), target:GetAbsOrigin().y+y*-math.random(-2, 2), 0)
    ParticleManager:SetParticleControl(hit, 3, Vector1)
     ParticleManager:SetParticleControl(hit, 4, Vector2)
     numhit = numhit - 1
     print (x, y)

    return 0.01
    end]]
			Timers:CreateTimer(2, function()
		CustomGameEventManager:Send_ServerToPlayer(player2, "enable_ui", {})
		--target:SetOrigin(sec2)
		--caster:SetOrigin(target:GetAbsOrigin() + target:GetForwardVector()*250)
		--ParticleManager:DestroyParticle(nanaya_knife12, true)
		caster:SetAbsOrigin(return1)
		caster:SetRenderAlpha(255)
		PlayerResource:SetCameraTarget(caster:GetPlayerID(), nil)
		PlayerResource:SetCameraTarget(target:GetPlayerID(), nil)
	end)
	end)
end

modifier_combo = class({})
function modifier_combo:CheckState()
 local funcs2 = {
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true, 
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ROOTED] = false,
	[MODIFIER_STATE_INVULNERABLE] = true,
  }
  return funcs2
  end

  nanaya_combo_attack = class({})
	
function nanaya_combo_attack:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
	  return funcs
end

function nanaya_combo_attack:GetModifierIncomingDamage_Percentage() 
    if IsServer() then        
        return -100
		end
		end
		
function nanaya_combo_attack:FilterUnits(caster, target)    
    local filter = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS, caster:GetTeamNumber())
print ("dsa")
return true
end		
		
		
function nanaya_combo_attack:OnTakeDamage(args)	
 if IsServer() then 
        local caster = self:GetParent()
        local target = args.attacker
		if args.unit ~= self:GetParent() then return end
		local damageTaken = args.original_damage
		if damageTaken >= 50 and caster:GetHealth() ~= 0 and self:FilterUnits(caster, target) then
		nanaya_combo:Alternate(caster, target, self:GetAbility())
		--nanaya_combo:Secret(caster, target, self:GetAbility())
		print ("check")
		self:Destroy()
		end
		end
		end

		nanaya_combo_cd = class({})

function nanaya_combo_cd:GetTexture()
	return "custom/nanaya/nanaya_combo"
end

function nanaya_combo_cd:IsHidden()
	return false 
end

function nanaya_combo_cd:RemoveOnDeath()
	return false
end

function nanaya_combo_cd:IsDebuff()
	return true 
end

function nanaya_combo_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
pepeg_combo_final_gachi = class({})

LinkLuaModifier("modifier_pepegillusionist", "abilities/modifier_pepegillusionistu", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pepegillusionist_cd", "abilities/modifier_pepegillusionistu_cd", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pepevision", "abilities/modifier_pepevision", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enkidu_hold", "abilities/gilgamesh/modifiers/modifier_enkidu_hold", LUA_MODIFIER_MOTION_NONE)



function pepeg_combo_final_gachi:Fisting(fisting_caster, fisting_target)
local hCaster = fisting_caster--self:GetCaster()
local target = fisting_target --self:GetCursorTarget()
hCaster:AddNewModifier(hCaster, nil, "modifier_pepevision", { Duration = 10.1})
target:AddNewModifier(hCaster, nil, "modifier_pepevision", { Duration = 10.1})
target:AddNewModifier(hCaster, nil, "modifier_enkidu_hold", { Duration = 10.1 })
--hCaster:MoveToTargetToAttack(target)

--[[Timers:CreateTimer(0.25, function() 

giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 10.1)
end)]]

Timers:CreateTimer(4.1, function() 
EmitGlobalSound("pepeg.fisting300")
end)


--hCaster:AddNewModifier(hCaster, self, "modifier_pepegillusionist_cd", { Duration = self:GetCooldown(1)})

hCaster:SetOrigin(target:GetOrigin() + Vector(0, 260, 0))
EmitGlobalSound("pepeg.doyoulike")

local testings = 0
local stopOrder = {
 		UnitIndex = target:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_STOP 
		}
		ExecuteOrderFromTable(stopOrder)
		
                Timers:CreateTimer(function() 
                if testings == 5 or not hCaster:IsAlive() or target:IsNull() or not target:IsAlive() then return end 
				
	    local hPepeg = CreateUnitByName("npc_dota_hero_doom"--[[hCaster:GetName()]], target:GetOrigin() + Vector(hPepeg, hPepeg, hPepeg), true, hCaster,	nil, hCaster:GetTeamNumber())
            
            hPepeg:SetPlayerID(hCaster:GetPlayerID())
	    hPepeg:SetForceAttackTarget(target)
		hPepeg:AddNewModifier(hCaster, nil, "modifier_disarmed", { duration = 4.1 })
	    hPepeg:AddNewModifier(hCaster, nil, "modifier_pepegillusionist", { duration = 10.1})
        hPepeg:MakeIllusion()
	hPepeg:SetControllableByPlayer(hCaster:GetPlayerID(), false)
	    
        testings = testings + 1
		
		return 0.01
		end)
		
         
		end 
		
		
		
gilgamesh_enkidu = class({})
modifier_gilgamesh_combo_window = class({})

LinkLuaModifier("modifier_enkidu_hold", "abilities/gilgamesh/modifiers/modifier_enkidu_hold", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilgamesh_combo_window", "abilities/gilgamesh/gilgamesh_enkidu", LUA_MODIFIER_MOTION_NONE)

function gilgamesh_enkidu:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
	
	return filter
end

function gilgamesh_enkidu:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function gilgamesh_enkidu:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self.stopOrder_self = {
		UnitIndex = caster:entindex(), 
		OrderType = DOTA_UNIT_ORDER_STOP
	}

	if IsSpellBlocked(target) then
		ExecuteOrderFromTable(self.stopOrder_self)  return
		 end
	caster:EmitSound("Gilgamesh_Enkidu_2")

	local stopOrder = {
 		UnitIndex = target:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_STOP
 	}


 	ExecuteOrderFromTable(stopOrder) 

 	target:AddNewModifier(caster, self, "modifier_enkidu_hold", { Duration = self:GetSpecialValueFor("duration") })
 	self.elapsed = 0.51

 	--if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
 	--	if caster:FindAbilityByName("gilgamesh_combo_final_hour"):IsCooldownReady() then
 	--		caster:AddNewModifier(caster, self, "modifier_gilgamesh_combo_window", { Duration = 3 })
 	--	end 		
	--end
end

function gilgamesh_enkidu:OnChannelThink(fInterval)

	self.elapsed = self.elapsed + fInterval
	if self.elapsed > 0.5 then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		if( not target:HasModifier("modifier_enkidu_hold")) then
			ExecuteOrderFromTable(self.stopOrder_self) 
		end
		DoDamage(caster, target, target:GetMaxHealth()*self:GetSpecialValueFor("damage")/100, DAMAGE_TYPE_MAGICAL, 0, self, false)

		self.elapsed = 0
	end
end

function gilgamesh_enkidu:OnChannelFinish(bInterrupted)
    local target = self:GetCursorTarget()
    target:RemoveModifierByName("modifier_enkidu_hold")
end

if IsServer() then 
	function modifier_gilgamesh_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("gilgamesh_combo_final_hour", "gilgamesh_gram", true, false)
	end

	function modifier_gilgamesh_combo_window:OnDestroy()
		local caster = self:GetParent()
		caster:SwapAbilities("gilgamesh_combo_final_hour", "gilgamesh_gram", false, true)
	end
end


function modifier_gilgamesh_combo_window:IsHidden()
	return true
end

function modifier_gilgamesh_combo_window:RemoveOnDeath()
	return true 
end
LinkLuaModifier("modifier_saito_formlessness_invis", "abilities/saito/saito_formlessness", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_formlessness_tracker", "abilities/saito/saito_formlessness", LUA_MODIFIER_MOTION_NONE)
 
LinkLuaModifier("modifier_saito_illusion_disarm", "abilities/saito/saito_formlessness", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_repeated", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)


saito_formlessness = class({})

function saito_formlessness:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function saito_formlessness:GetCastPoint()
	if self:CheckSequence() == self:GetSpecialValueFor("number_of_slashes") then
		if(self:GetCaster():HasModifier("modifier_saito_combo")) then
		
			return 0.3
	
		else
			return 0.6
		end
	elseif self:CheckSequence()>0 then
		return 0.03
	else
		return 0.3
	end
end

function saito_formlessness:GetManaCost(iLevel)
	if self:CheckSequence() == self:GetSpecialValueFor("number_of_slashes")then
		return 0
	elseif self:CheckSequence()>0 then
		return 0
	else
		return 800
	end
end


function saito_formlessness:GetBehavior()
	if self:CheckSequence()  == self:GetSpecialValueFor("number_of_slashes") then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	elseif self:CheckSequence() > 0 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_POINT
	end
end


function saito_formlessness:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function saito_formlessness:GetCustomCastError()
    return "#Invalid_Target"
end

function saito_formlessness:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_saito_formlessness_tracker")   then
		local stack = caster:GetModifierStackCount("modifier_saito_formlessness_tracker", caster) +1
		return stack
	else 
		return -1
	end	
end

function saito_formlessness:GetCastAnimation()
	if self:CheckSequence()  == self:GetSpecialValueFor("number_of_slashes") then
		return ACT_DOTA_CAST_ABILITY_4_END
	elseif self:CheckSequence() > 0 then
		return ACT_DOTA_CAST_ABILITY_7
	else
		return nil
	end
end

function saito_formlessness:GetCastRange(vLocation, hTarget)
	if self:CheckSequence()  == self:GetSpecialValueFor("number_of_slashes") then
		return self:GetSpecialValueFor("last_range")
	elseif self:CheckSequence() > 0 then
		return self:GetSpecialValueFor("range")
	else
		return 0
	end
end

function saito_formlessness:GetAbilityTextureName()
	if self:CheckSequence() == self:GetSpecialValueFor("number_of_slashes") then		
		return  "custom/saito/saito_formlessness_slash4"
	elseif self:CheckSequence()==1 then
		return  "custom/saito/saito_formlessness_slash1"
	elseif self:CheckSequence()==2 then
		return  "custom/saito/saito_formlessness_slash2"
	elseif self:CheckSequence()==3 then
		return  "custom/saito/saito_formlessness_slash3" 
	else
		return "custom/saito/saito_formlessness" 
	end
end
 


function saito_formlessness:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_saito_formlessness_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_saito_formlessness_tracker", {Duration = (self:GetSpecialValueFor("duration") )})
		caster:SetModifierStackCount("modifier_saito_formlessness_tracker", ability, 0)
 
	elseif modifier:GetStackCount() <self:GetSpecialValueFor("number_of_slashes")  then
		caster:SetModifierStackCount("modifier_saito_formlessness_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function saito_formlessness:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	if(self:CheckSequence() == 4) then
		caster:StopSound("saito_cast_ulti")
		caster:EmitSound("saito_last_slash_phrase")
	end
	--if(self:CheckSequence() ~= -1) then return true end
 
	if(IsServer) then
        if(caster:HasModifier("modifier_saito_fdb_repeated")) then
            self.modifierRepeated = caster:FindModifierByName("modifier_saito_fdb_repeated")
            self.stackCount = self.modifierRepeated:GetStackCount()
			 
        end
    end
    return true
end

function saito_formlessness:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
 	if( caster:GetModifierStackCount("modifier_saito_formlessness_tracker", caster) == 3) then
		caster:StopSound("saito_last_slash_phrase")
	end

    self.modifierRepeated = nil
    self.stackCount = 0
	local abilitycd = caster:GetAbilityByIndex(1):GetCooldown(caster:GetAbilityByIndex(1):GetLevel()-1)
 

	if( not caster:HasModifier("modifier_saito_fdb_repeated") and caster:GetModifierStackCount("modifier_saito_fdb", caster) ~= caster:FindModifierByName("modifier_saito_fdb"):GetMaxStackCount()) then

		caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
		caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
		caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
		caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
		caster:RemoveModifierByName("modifier_saito_fdb_lastE")
		caster:RemoveModifierByName("modifier_saito_fdb_lastW")
		caster:FindModifierByName("modifier_saito_fdb"):SetStackCount(self:GetParent():FindModifierByName("modifier_saito_fdb"):GetMaxStackCount())
	end
end


function saito_formlessness:OnSpellStart()
	local caster = self:GetCaster()

	if self:CheckSequence() == self:GetSpecialValueFor("number_of_slashes") then
		self:SaitoFormlessnessLastSlash()
	elseif self:CheckSequence() > 0 then
		self:SaitoFormlessnessSlash()
	else
		self:SaitoFormlessnessStart()
	end
end


function saito_formlessness:SaitoFormlessnessStart()

	local caster = self:GetCaster()
	self:SequenceSkill()
	self:EndCooldown()
	self:StartCooldown( self:GetSpecialValueFor("slashes_start_delay"))
	local pid = caster:GetPlayerID()
	local target = self:GetCursorPosition()
	self.isRefreshed = 0
	caster:AddNewModifier(caster, self, "modifier_saito_formlessness_invis", {duration =(self:GetSpecialValueFor("duration") )})
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.gachi == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_omaewa_mou"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	if(self.modifierRepeated ~= nil) then
    
        caster:RemoveModifierByName("modifier_saito_fdb_repeated")
        caster:AddNewModifier(caster, self.modifierRepeated.ability, "modifier_saito_fdb_repeated", { } )
        caster:FindModifierByName("modifier_saito_fdb_repeated"):SetStackCount(self.stackCount)
        self.modifierRepeated = nil
        self.stackCount = 0
 
   end
   	caster:EmitSound("saito_cast_ulti")
	   local dist = self:GetSpecialValueFor("blink_dist")  

		if (target - caster:GetAbsOrigin()):Length2D() > dist then
			target = caster:GetAbsOrigin() + (((target - caster:GetAbsOrigin()):Normalized()) * dist)
		end
		 
			FindClearSpaceForUnit(caster, target, true)
	 
	--local illusion = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
	
	--illusion:SetPlayerID(pid) 
	--illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = 0, incoming_damage = 100 })
	--illusion:MakeIllusion()
	--illusion:SetControllableByPlayer(pid, true)
	--caster.illusion = illusion
	--illusion:SetOwner(caster)
	--illusion:SetForwardVector(caster:GetForwardVector())
	--illusion:AddNewModifier(caster, illusion, "modifier_saito_illusion_disarm", {})
	--illusion:SetOwner(caster) -- Attempt to change color of illusion on minimap but failed, worked for ZC but not for this. Wtf.

	--for i=1, (caster:GetLevel()-1) do
	--	illusion:HeroLevelUp(false)
	--end

	--for i = 1, #itemModifiers do
	--	if caster:HasModifier(itemModifiers[i]) then
	--		ability:ApplyDataDrivenModifier(caster, illusion, itemModifiers[i], {duration = caster:FindModifierByName(itemModifiers[i]):GetRemainingTime()})		
	--	end
	--end

	--for itemSlot=0,5 do
	--	local item = caster:GetItemInSlot(itemSlot)
	--	if item ~= nil then
	--		local itemName = item:GetName()
	--		local newItem = CreateItem(itemName, illusion, illusion)
	--		local currCharge = item:GetCurrentCharges()
	--		CreateItemAtSlot(illusion, itemName, itemSlot, currCharge, 1, 1)
	--	end
	--end

	--for abilitySlot=0,10 do
	--	if abilitySlot == 9 then goto skip9 end --skip presence_detection_passive
	--	local abilityCopy = caster:GetAbilityByIndex(abilitySlot)
	--	if abilityCopy ~= nil then 
	--		local abilityLevel = abilityCopy:GetLevel()
	--		local abilityName = abilityCopy:GetAbilityName()
	--		local illusionAbility = illusion:FindAbilityByName(abilityName)
	--		illusionAbility:SetLevel(abilityLevel)
	--	end
	--	::skip9::
	--end

	--illusion:SetBaseStrength(caster:GetBaseStrength())
	--illusion:SetBaseIntellect(caster:GetBaseIntellect())
	--illusion:SetBaseAgility(caster:GetBaseAgility())
	--illusion:ModifyAgility(0)  

	--illusion:SetMaxHealth(caster:GetMaxHealth())
	--illusion:SetMana(caster:GetMana())

	--illusion:SetBaseHealthRegen(caster:GetHealthRegen() - caster:GetStrength() * (0.03))  
	--illusion:SetBaseManaRegen(caster:GetManaRegen() + caster:GetIntellect() * (0.25 - 0.04))  
	--illusion:SetPhysicalArmorBaseValue(caster:GetPhysicalArmorBaseValue()) 
	--illusion:SetBaseMoveSpeed(caster:GetBaseMoveSpeed()) 
--	illusion:SetBaseDamageMin(caster:GetBaseDamageMin())
--	illusion:SetBaseDamageMax(caster:GetBaseDamageMax())

end

function saito_formlessness:SaitoFormlessnessSlash()
	local caster = self:GetCaster()
	local DamageType = DAMAGE_TYPE_MAGICAL
	self:SequenceSkill()
	self:EndCooldown()
	 
	self:StartCooldown( self:GetSpecialValueFor("cd_between_slashes"))
	local damage = self:GetSpecialValueFor("damage")
	local target = self:GetCursorTarget()
 
	if(caster.ShinsengumiAcquired) then
		damage = damage  +  caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
	end
	if IsSpellBlocked(target) then return end
	local slashes = ParticleManager:CreateParticle("particles/saito/saito_formless_slash_new.vpcf", PATTACH_CUSTOMORIGIN, nil) 
 
 
	  ParticleManager:SetParticleControl(slashes, 0, target:GetAbsOrigin()   )
      ParticleManager:SetParticleControl(slashes, 1,  target:GetAbsOrigin())
	  --ParticleManager:SetParticleControlEnt(slashes, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	  --ParticleManager:SetParticleControlEnt(slashes, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	  ParticleManager:SetParticleControl(slashes, 5,   target:GetRightVector()*Vector(-120,-120,0))
	  ParticleManager:SetParticleControl(slashes, 6,   target:GetRightVector() *Vector(120,120,0))

	DoDamage(caster, target, damage, DamageType, 0, self, false)
	giveUnitDataDrivenModifier(caster, target, "locked", 0.5)
	if(caster.MasteryAcquired) then
		giveUnitDataDrivenModifier(caster,target, "rooted", self:GetSpecialValueFor("root_duration"))
	end

	if(IsServer) then
		if(caster:HasModifier("modifier_saito_fdb_repeated")) then
			caster:RemoveModifierByName("modifier_saito_fdb_repeated")
			caster:AddNewModifier(caster, self.modifierRepeated.ability, "modifier_saito_fdb_repeated", { } )
			caster:FindModifierByName("modifier_saito_fdb_repeated"):SetStackCount(self.stackCount)
			self.modifierRepeated = nil
			self.stackCount = 0

		end
	end

	Timers:CreateTimer( self:GetSpecialValueFor("cd_between_slashes"), function()
		local slashes = ParticleManager:CreateParticle("particles/saito/saito_formless_slash_new.vpcf", PATTACH_CUSTOMORIGIN, nil) 
	  ParticleManager:SetParticleControl(slashes, 0, target:GetAbsOrigin()   )
     ParticleManager:SetParticleControl(slashes, 1,   target:GetAbsOrigin())
	-- ParticleManager:SetParticleControlEnt(slashes, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	 --ParticleManager:SetParticleControlEnt(slashes, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	 ParticleManager:SetParticleControl(slashes, 5,   target:GetRightVector()*Vector(-120,-120,0))
	 ParticleManager:SetParticleControl(slashes, 6,   target:GetRightVector() *Vector(120,120,0))
	DoDamage(caster, target, damage, DamageType, 0, self, false)



	end)


end


    
function saito_formlessness:SaitoFormlessnessLastSlash()
	local caster = self:GetCaster()
	local DamageType = DAMAGE_TYPE_MAGICAL
	local damage = self:GetSpecialValueFor("damage_last_slash")
	if(caster.ShinsengumiAcquired) then
		damage = damage + caster:GetModifierStackCount("modifier_saito_fdb_repeated",caster) *self:GetSpecialValueFor("damage_per_stack") +  caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale_last")
	end
	local target = self:GetCursorTarget()
	local angle = VectorToAngles(caster:GetForwardVector()).y
	--local illusion  = caster.illusion 
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.gachi == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_nani"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	 
	caster:RemoveModifierByName("modifier_saito_formlessness_tracker")
	caster:RemoveModifierByName("modifier_saito_formlessness_invis")
	--if IsValidEntity(illusion) and not illusion:IsNull() then 
	--	caster.illusion:ForceKill(false)
	--end
	if IsSpellBlocked(target) then return end
	DoDamage(caster, target, damage, DamageType, 0, self, false)
	target:EmitSound("saito_last_slash")

	giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("lock_duration"))
	if(caster.MasteryAcquired) then
		giveUnitDataDrivenModifier(caster,target, "rooted", self:GetSpecialValueFor("root_duration"))
	end
	
	if(IsServer) then
		if(caster:HasModifier("modifier_saito_fdb_repeated")) then
			caster:RemoveModifierByName("modifier_saito_fdb_repeated")
			caster:AddNewModifier(caster, self.modifierRepeated.ability, "modifier_saito_fdb_repeated", { } )
			caster:FindModifierByName("modifier_saito_fdb_repeated"):SetStackCount(self.stackCount)
			self.modifierRepeated = nil
			self.stackCount = 0

		end
	end
	local slashes = ParticleManager:CreateParticle("particles/saito/saito_formless_slash_last.vpcf", PATTACH_CUSTOMORIGIN, nil)
	local range = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
	ParticleManager:SetParticleControl(slashes, 0, target:GetAbsOrigin()- caster:GetForwardVector()*100   )
    ParticleManager:SetParticleControl(slashes, 1,  Vector(0,angle-90,0))
    ParticleManager:SetParticleControl(slashes, 2,  Vector(180,0,0))
 
 
	
end



modifier_saito_formlessness_invis = class({})
 
if IsServer() then 
	function modifier_saito_formlessness_invis:OnCreated(args)
		self.State = {[MODIFIER_STATE_INVISIBLE] = true}
		 


	end
end

 

function modifier_saito_formlessness_invis:CheckState()
	return self.State
end


function modifier_saito_formlessness_invis:OnDestroy()
	--local illusion =  self:GetCaster().illusion 
	--if IsValidEntity(illusion) and not illusion:IsNull() then 
	--	illusion:ForceKill(false)
	--end

end

function modifier_saito_formlessness_invis:OnTakeDamage(args)
 
    if( args.attacker ~= self:GetParent()) then return end
	if(args.inflictor == nil) then
		self.State = {}
		Timers:CreateTimer("saito_invis", {
			endTime =  1 ,
			callback = function()
				self.State = {[MODIFIER_STATE_INVISIBLE] = true} 
			end})
			return
	end
    if(args.inflictor:GetName() == "saito_formlessness" ) then   
		return 
 
	else
		self.State = {}
		Timers:CreateTimer("saito_invis", {
			endTime =  1 ,
			callback = function()
				self.State = {[MODIFIER_STATE_INVISIBLE] = true} 
				 
		 end})
	end
	

    


end

function modifier_saito_formlessness_invis:GetTexture()
	return "custom/saito/saito_formlessness"
end
 

 
function modifier_saito_formlessness_invis:DeclareFunctions()	
	local funcs =  {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
	return funcs
end

function modifier_saito_formlessness_invis:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_bonus")
end


 

function modifier_saito_formlessness_invis:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end


function modifier_saito_formlessness_invis:IsHidden() return false end
function modifier_saito_formlessness_invis:IsDebuff() return false end
function modifier_saito_formlessness_invis:RemoveOnDeath() return true end


modifier_saito_formlessness_tracker = class({})


function modifier_saito_formlessness_tracker:OnDestroy()
	if(self:GetAbility().isRefreshed ~= 1) then
		self:GetParent():FindAbilityByName("saito_formlessness"):StartCooldown(self:GetParent():FindAbilityByName("saito_formlessness"):GetCooldown(1))
	end
	 

end
function modifier_saito_formlessness_tracker:GetTexture()
	local caster = self:GetAbility()
	if caster:CheckSequence() == caster:GetSpecialValueFor("number_of_slashes") then		
		return  "custom/saito/saito_formlessness_slash4"
	elseif caster:CheckSequence()==1 then
		return  "custom/saito/saito_formlessness_slash1"
	elseif caster:CheckSequence()==2 then
		return  "custom/saito/saito_formlessness_slash2"
	elseif caster:CheckSequence()==3 then
		return  "custom/saito/saito_formlessness_slash3" 
	else
		return "custom/saito/saito_formlessness" 
	end
end
 


function modifier_saito_formlessness_tracker:IsHidden() return false end
function modifier_saito_formlessness_tracker:IsDebuff() return false end
function modifier_saito_formlessness_tracker:RemoveOnDeath() return true end


modifier_saito_illusion_disarm = class({})

function modifier_saito_illusion_disarm:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end	


function modifier_saito_illusion_disarm:IsHidden() return true end
function modifier_saito_illusion_disarm:IsDebuff() return false end
function modifier_saito_illusion_disarm:RemoveOnDeath() return true end
 

 
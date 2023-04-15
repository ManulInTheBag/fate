LinkLuaModifier("nanaya_blood_modifier", "abilities/nanaya/nanaya_blood", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_blood_modifier_animemode", "abilities/nanaya/nanaya_blood", LUA_MODIFIER_MOTION_NONE)


nanaya_blood = class ({})

function nanaya_blood:Spawn()
	if IsServer() then
	self:SetLevel(1)
end
end



function nanaya_blood:GetIntrinsicModifierName()
    return "nanaya_blood_modifier"
end	

nanaya_blood_modifier = class ({})
--[[function nanaya_blood_modifier:DeclareFunctions()
    return { MODIFIER_EVENT_ON_MANA_GAINED ,
	}
end]]



function nanaya_blood_modifier:IsHidden() return false end
function nanaya_blood_modifier:IsDebuff() return false end

function nanaya_blood_modifier:DeclareFunctions()
    local func = {  MODIFIER_EVENT_ON_TAKEDAMAGE,
                    MODIFIER_PROPERTY_ATTACKSPEED_BASE_OVERRIDE, 
                    MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
    return func
end

function nanaya_blood_modifier:GetModifierAttackSpeed_Limit()
        return 1
end

function nanaya_blood_modifier:GetModifierAttackSpeedBaseOverride()
        return 1
    end


function nanaya_blood_modifier:GetModifierBonusStats_Agility()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function nanaya_blood_modifier:OnCreated()
	self.parent = self:GetParent()
	self:SetStackCount(0)
end


function nanaya_blood_modifier:GetMaxStackCount()
	return self:GetAbility():GetSpecialValueFor("stack_max")
end

	function nanaya_blood_modifier:OnTakeDamage(keys)
		if IsServer() then
			if keys.attacker == self.parent and keys.unit and keys.unit:GetTeamNumber() ~= self.parent:GetTeamNumber() and not keys.unit:IsBuilding() 
				and bit.band(keys.damage_flags or DOTA_DAMAGE_FLAG_NONE, DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT) == 0 then
				local stacks = self:GetStackCount()
				if self.nanaya ~= nil then 
				ParticleManager:DestroyParticle(self.nanaya, true)
	--ParticleManager:ReleaseParticleIndex(nanaya)
				end
				Timers:RemoveTimer("nanaya")
				if(stacks < self:GetMaxStackCount()) then
					self:SetStackCount(stacks+1)
				end
				self.nanaya = ParticleManager:CreateParticle("particles/nanaya_blood2.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
				Timers:CreateTimer("nanaya", {
					endTime = self:GetAbility():GetSpecialValueFor("stacks_duration"), 
					callback = function()
						self:SetStackCount(0)
						if self.parent:HasModifier("nanaya_blood_modifier_animemode") then self.parent:RemoveModifierByName("nanaya_blood_modifier_animemode") end
					end})
			end			
		end
	end	
	
nanaya_blood_modifier_animemode = class ({})

function nanaya_blood_modifier_animemode:IsHidden() return false end
function nanaya_blood_modifier_animemode:IsDebuff() return false end

function nanaya_blood_modifier_animemode:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, MODIFIER_EVENT_ON_ORDER, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, 
		}
		return func
end

function nanaya_blood_modifier_animemode:GetModifierPercentageCooldown()
	return 30
end

function nanaya_blood_modifier_animemode:OnOrder(args)
	  if args.unit ~= self:GetParent() or self.sex ~= true or args.unit:IsCommandRestricted() or args.unit:IsStunned() then return end
	  if (args.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION) then
	  	self.sex = false
	if (args.new_pos - self.parent:GetAbsOrigin()):Length2D() > self.dist then 
		args.new_pos = self:GetParent():GetAbsOrigin() + (((args.new_pos - self:GetParent():GetAbsOrigin()):Normalized()) * self.dist)
		local nanaya_knife10 = ParticleManager:CreateParticle("particles/maybedashvpcffinal1.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
		local nanaya_clone_jump = ParticleManager:CreateParticle("particles/blink_z1.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	  	ParticleManager:SetParticleControlEnt(nanaya_knife10, 0, caster, PATTACH_POINT, "attach_hand", self.parent:GetAbsOrigin(), true)
	  	ParticleManager:SetParticleControl(nanaya_clone_jump, 1, GetGroundPosition(self.parent:GetAbsOrigin(), nil))
					local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
					
					ParticleManager:SetParticleControl(nanaya_clone, 0, GetGroundPosition(self.parent:GetAbsOrigin(), nil)) --0.35
					ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, 9, 0))
					ParticleManager:SetParticleControl(nanaya_clone, 4, args.new_pos)
	  	FindClearSpaceForUnit(self:GetParent(), args.new_pos, true) 
	  	self.parent:EmitSound("nanaya.jumpforward")
	  	ParticleManager:SetParticleControl(nanaya_knife10, 4, args.new_pos)
	  	print ("sex")
	end

end
end

if IsServer() then 
	function nanaya_blood_modifier_animemode:OnAbilityFullyCast(args)
		if args.unit ~= self:GetParent() or args.ability:IsItem() then return end
        self.sex = true
        --print (self.sex)
	end
end
--[[function nanaya_blood_modifier_animemode:GetEffectName()
    return "particles/nanaya_eyes_main.vpcf"
end


function nanaya_blood_modifier_animemode:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end]]

function nanaya_blood_modifier_animemode:OnCreated()
	self.dist = 450
	self.parent = self:GetParent()
	CustomGameEventManager:Send_ServerToPlayer(self.parent:GetPlayerOwner(), "emit_horn_sound", {sound="nanaya_pizza"})
    if IsServer() then
	local sAbil = self.parent:GetAbilityByIndex(4):GetAbilityName()
	print (sAbil)
	 if sAbil == "nanaya_dashf" then
		self.parent:SwapAbilities("nanaya_jump_slashes", "nanaya_dashf", true, false)
	else
		if sAbil == "nanaya_dashf_return" then
			self.parent:SwapAbilities("nanaya_jump_slashes", "nanaya_dashf_return", true, false)
end
end
end
	local sAbil1 = self.parent:GetAbilityByIndex(3)
        if sAbil1:GetAbilityName() == "nanaya_slashes" then
sAbil1:EndCooldown()
end
	self.nanaya_right_eye = ParticleManager:CreateParticle("particles/nanaya_eyes.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
ParticleManager:SetParticleControlEnt(self.nanaya_right_eye, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_right_eye", self.parent:GetAbsOrigin(), true)

    self.nanaya_left_eye = ParticleManager:CreateParticle("particles/nanaya_eyes.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(self.nanaya_left_eye, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_left_eye", self.parent:GetAbsOrigin(), true)
	--print (self.nanaya_right_eye)
	
end

function nanaya_blood_modifier_animemode:GetModifierMoveSpeed_Absolute()
    return 600
end

function nanaya_blood_modifier_animemode:GetTexture()
    return "custom/nanaya/nanaya_eyes_upgrade"
end

function nanaya_blood_modifier_animemode:OnRemoved()
	--print (self.nanaya_right_eye)
	ParticleManager:DestroyParticle(self.nanaya_left_eye, false)
	ParticleManager:ReleaseParticleIndex(self.nanaya_left_eye)
	ParticleManager:DestroyParticle(self.nanaya_right_eye, false)
	ParticleManager:ReleaseParticleIndex(self.nanaya_right_eye)
	self.parent:SwapAbilities("nanaya_jump_slashes", "nanaya_dashf", false, true)

end
		
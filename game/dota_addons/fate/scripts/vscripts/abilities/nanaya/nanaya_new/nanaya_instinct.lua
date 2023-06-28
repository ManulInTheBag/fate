LinkLuaModifier("modifier_nanaya_instinct_passive", "abilities/nanaya/nanaya_new/nanaya_instinct", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_instinct", "abilities/nanaya/nanaya_new/nanaya_instinct", LUA_MODIFIER_MOTION_NONE)

nanaya_instinct = class({})

function nanaya_instinct:GetIntrinsicModifierName()
    return "modifier_nanaya_instinct_passive"
end

--

modifier_nanaya_instinct_passive = class ({})

function modifier_nanaya_instinct_passive:IsHidden() return false end
function modifier_nanaya_instinct_passive:IsDebuff() return false end

function modifier_nanaya_instinct_passive:DeclareFunctions()
    local func = {  MODIFIER_EVENT_ON_TAKEDAMAGE,
                    MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
    return func
end

function modifier_nanaya_instinct_passive:GetModifierBonusStats_Agility()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_nanaya_instinct_passive:OnCreated()
	self.parent = self:GetParent()
	self:SetStackCount(0)
end


function modifier_nanaya_instinct_passive:GetMaxStackCount()
	return self:GetAbility():GetSpecialValueFor("stack_max")
end

function modifier_nanaya_instinct_passive:OnTakeDamage(keys)
	if IsServer() then
		if keys.attacker == self.parent and keys.unit and keys.unit:GetTeamNumber() ~= self.parent:GetTeamNumber() and not keys.unit:IsBuilding() 
			and bit.band(keys.damage_flags or DOTA_DAMAGE_FLAG_NONE, DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT) == 0 then
			
			local stacks = self:GetStackCount()
			if self.nanaya ~= nil then 
				ParticleManager:DestroyParticle(self.nanaya, true)
			end
			Timers:RemoveTimer("nanaya")
			if(stacks < self:GetMaxStackCount()) then
				self:SetStackCount(stacks+1)
			end
			if self:GetStackCount() >= 15 and not self.parent:HasModifier("modifier_nanaya_instinct") then
				self.parent:AddNewModifier(self.parent, self:GetAbility(), "modifier_nanaya_instinct", {})
			end
			self.nanaya = ParticleManager:CreateParticle("particles/nanaya_blood2.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
			Timers:CreateTimer("nanaya", {
				endTime = self:GetAbility():GetSpecialValueFor("stacks_duration"), 
				callback = function()
					
					self:SetStackCount(0)
					if self.parent:HasModifier("modifier_nanaya_instinct") then
						self.parent:RemoveModifierByName("modifier_nanaya_instinct")
					end
				end}
			)
		end			
	end
end

--

modifier_nanaya_instinct = class ({})

function modifier_nanaya_instinct:IsHidden() return false end
function modifier_nanaya_instinct:IsDebuff() return false end

function modifier_nanaya_instinct:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
    				--MODIFIER_EVENT_ON_ORDER, 
    				--MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, 
    				MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, 
		}
		return func
end

function modifier_nanaya_instinct:GetModifierPercentageCooldown()
	return self:GetAbility():GetSpecialValueFor("cd_reduction_pct")
end

--[[function modifier_nanaya_instinct:OnOrder(args)
	if args.unit ~= self:GetParent() or self.sex ~= true or args.unit:IsCommandRestricted() or args.unit:IsStunned() then return end

	if (args.order_type == DOTA_UNIT_ORDER_ATTACK_MOVE) then--or (args.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION) then
	  	self:NanayaBlink(args.new_pos)
	end
	if (args.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET) then
	  	self:NanayaBlink(args.target:GetAbsOrigin() + (self.parent:GetAbsOrigin() - args.target:GetAbsOrigin()):Normalized()*100)
	end
end]]

function modifier_nanaya_instinct:NanayaBlink(location)
	self.sex = false

	if (location - self.parent:GetAbsOrigin()):Length2D() > self.dist then 
		location = self:GetParent():GetAbsOrigin() + (((location - self:GetParent():GetAbsOrigin()):Normalized()) * self.dist)
	end

	local nanaya_knife10 = ParticleManager:CreateParticle("particles/maybedashvpcffinal1.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())

	local nanaya_clone_jump = ParticleManager:CreateParticle("particles/blink_z1.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	ParticleManager:SetParticleControlEnt(nanaya_knife10, 0, caster, PATTACH_POINT, "attach_hand", self.parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(nanaya_clone_jump, 1, GetGroundPosition(self.parent:GetAbsOrigin(), nil))

	local nanaya_clone = ParticleManager:CreateParticle("particles/nanaya_image_clone.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	ParticleManager:SetParticleControl(nanaya_clone, 0, GetGroundPosition(self.parent:GetAbsOrigin(), nil)) --0.35
	ParticleManager:SetParticleControl(nanaya_clone, 2, Vector(3, 9, 0))
	ParticleManager:SetParticleControl(nanaya_clone, 4, location)
		  	
	FindClearSpaceForUnit(self:GetParent(), location, true)

	self.parent:EmitSound("nanaya.jumpforward")

	ParticleManager:SetParticleControl(nanaya_knife10, 4, location)
end

if IsServer() then 
	function modifier_nanaya_instinct:OnAbilityFullyCast(args)
		if args.unit ~= self:GetParent() or args.ability:IsItem() then return end
        self.sex = true
	end
end

function modifier_nanaya_instinct:OnCreated()
	self.dist = 450
	self.parent = self:GetParent()
	--CustomGameEventManager:Send_ServerToPlayer(self.parent:GetPlayerOwner(), "emit_horn_sound", {sound="nanaya_pizza"})
    if IsServer() then
    	self.parent:SetMaterialGroup("WhiteShadow")
    	self.sex = true
		local sAbil1 = self.parent:GetAbilityByIndex(0)
	    if sAbil1:GetAbilityName() == "nanaya_slashes" then
			sAbil1:EndCooldown()
		end
		self.nanaya_right_eye = ParticleManager:CreateParticle("particles/nanaya_eyes.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
		ParticleManager:SetParticleControlEnt(self.nanaya_right_eye, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_right_eye", self.parent:GetAbsOrigin(), true)

	    self.nanaya_left_eye = ParticleManager:CreateParticle("particles/nanaya_eyes.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
		ParticleManager:SetParticleControlEnt(self.nanaya_left_eye, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_left_eye", self.parent:GetAbsOrigin(), true)

		local instinct_enter = ParticleManager:CreateParticle("particles/nanaya/nanaya_instinct_white_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:ReleaseParticleIndex(instinct_enter)
	end
end

function modifier_nanaya_instinct:GetModifierMoveSpeed_Absolute()
    return 600
end

function modifier_nanaya_instinct:GetTexture()
    return "custom/nanaya/nanaya_eyes_upgrade"
end

function modifier_nanaya_instinct:OnRemoved()
	if not IsServer() then return end
	--print (self.nanaya_right_eye)
	self:GetParent():SetMaterialGroup("BlackShadow")
	ParticleManager:DestroyParticle(self.nanaya_left_eye, false)
	ParticleManager:ReleaseParticleIndex(self.nanaya_left_eye)
	ParticleManager:DestroyParticle(self.nanaya_right_eye, false)
	ParticleManager:ReleaseParticleIndex(self.nanaya_right_eye)
	local instinct_quit = ParticleManager:CreateParticle("particles/nanaya/nanaya_instinct_black_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:ReleaseParticleIndex(instinct_quit)
end
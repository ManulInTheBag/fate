LinkLuaModifier("modifier_lancelot_parry", "abilities/lancelot/lancelot_parry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lancelot_parry_particle", "abilities/lancelot/lancelot_parry", LUA_MODIFIER_MOTION_NONE)



lancelot_parry = class({})



function lancelot_parry:CastFilterResultLocation(vLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_lancelot_minigun") then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function lancelot_parry:GetCustomCastErrorLocation(vLocation)
    return "#Minigun_Active"
end

function lancelot_parry:OnSpellStart()
	local caster = self:GetCaster()
	local tpoint = self:GetCursorPosition()

	local dir = (tpoint - caster:GetAbsOrigin()):Normalized()
	dir.z = 0
	if not (tpoint == caster:GetAbsOrigin()) then
		caster:SetForwardVector(dir)
	end

	caster:AddNewModifier(caster, self, "modifier_lancelot_parry", {duration = self:GetChannelTime()})
	caster:AddNewModifier(caster, self, "modifier_lancelot_parry_particle", {duration = self:GetChannelTime()})

	caster:EmitSound("lancelot_parry_voice")
	caster:EmitSound("lancelot_parry_start")

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 and not caster:HasModifier("modifier_arondite") then
        if caster:FindAbilityByName("lancelot_f16"):IsCooldownReady() and caster.nukeAvail ~= true then            
            local abilname = "fate_empty1"
            if caster:FindAbilityByName("lancelot_blessing_of_fairy") then abilname = "lancelot_blessing_of_fairy" end
            caster:SwapAbilities("lancelot_f16", abilname, true, false)
            caster.nukeAvail = true
            local newTime =  GameRules:GetGameTime()
            Timers:CreateTimer({
                endTime = 8,
                callback = function()
                if caster:FindAbilityByName("lancelot_blessing_of_fairy") then abilname = "lancelot_blessing_of_fairy" end
                caster:SwapAbilities("lancelot_f16", abilname, false, true)                
                caster.nukeAvail = false
            end
            })        
        end
    end
end

function lancelot_parry:OnChannelFinish()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_lancelot_parry")
	caster:RemoveModifierByName("modifier_lancelot_parry_particle")
end

function lancelot_parry:Counter()
	local caster = self:GetCaster()
	local dir = caster:GetForwardVector()



	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.3)  
	EndAnimation(caster)
	StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_GHOST_SHIP, rate=1.8})
	local aoe_radius = 400
	caster:EmitSound("lancelot_parry")
	local damage = self:GetSpecialValueFor("damage")

	local particle = ParticleManager:CreateParticle("particles/lancelot/lancelot_slash_parry.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(), dir)
	ParticleManager:ReleaseParticleIndex(particle)

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
  				local origin_diff_norm = origin_diff:Normalized()
   				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					giveUnitDataDrivenModifier(caster, v, "rooted", self:GetSpecialValueFor("root_dur"))
					giveUnitDataDrivenModifier(caster, v, "disarmed", self:GetSpecialValueFor("root_dur"))
					caster:PerformAttack( v, true, true, true, true, false, false, false )
				end
			end
		end


	HardCleanse(caster)
	Timers:CreateTimer(FrameTime(), function()
		HardCleanse(caster)
	end)

	
end

modifier_lancelot_parry = class({})

function modifier_lancelot_parry:IsHidden() return false end
function modifier_lancelot_parry:IsDebuff() return false end

function modifier_lancelot_parry:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_lancelot_parry:OnCreated()

end

function modifier_lancelot_parry:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_lancelot_parry:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end
function modifier_lancelot_parry:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.original_damage--block_now
            	local damage = keys.original_damage - block_now

            	local IsBScrollIgnored = false
            	if keys.damage_type == DAMAGE_TYPE_MAGICAL then
			        if keys.inflictor then
			        	if BIgnoreCheck(keys.inflictor) then
			        		IsBScrollIgnored = true
			        	end


				        if IsBScrollIgnored == false and keys.target:HasModifier("modifier_b_scroll") then 
				            local originalDamage = damage - keys.target.BShieldAmount
				            keys.target.BShieldAmount = keys.target.BShieldAmount - damage
				            if keys.target.BShieldAmount <= 0 then
				                damage = originalDamage
				                keys.target:RemoveModifierByName("modifier_b_scroll")
				            else 
				                damage = 0
				            end
				        end
				    end
			    end
				damage = damage - self.hAbility:GetSpecialValueFor("shield_damage_decrease_flat_value")
				self:ActivateCounter()
				if damage > 0 then
					local dmgtable = {
						attacker = keys.attacker,
						victim = keys.target,
						damage = damage,
						damage_type = keys.damage_type,
						damage_flags = keys.damage_flags,
						ability = keys.inflictor
					}
					self:Destroy()
					ApplyDamage(dmgtable)
				end
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_lancelot_parry:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield_amount")
    


	if IsServer() then
		--self.hCaster:EmitSound("lancelot_parry_sfx")
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_lancelot_parry:OnRefresh(hTable)
	self:OnCreated(hTable)
end

function modifier_lancelot_parry:ActivateCounter()
	self.hAbility:EndChannel(false)
	self.hAbility:Counter()
end

--

modifier_lancelot_parry_particle = class({})

function modifier_lancelot_parry_particle:IsHidden() return true end
function modifier_lancelot_parry_particle:IsDebuff() return false end

function modifier_lancelot_parry_particle:OnCreated()
	self.caster = self:GetCaster()

	if IsServer() then
		if not self.shield_fx then

		    self.shield_fx = ParticleManager:CreateParticle( "particles/lancelot/shield/lancelot_parry.vpcf", PATTACH_CUSTOMORIGIN, self.caster ) 
		    ParticleManager:SetParticleControlEnt(self.shield_fx, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_hand", Vector(0,0,0), false)

		    self:AddParticle(self.shield_fx, false, false, -1, false, false)
		end
	end
end


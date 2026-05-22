LinkLuaModifier("modifier_diarmuid_parry", "abilities/diarmuid/diarmuid_parry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diarmuid_parry_particle", "abilities/diarmuid/diarmuid_parry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diarmuid_parry_marker", "abilities/diarmuid/diarmuid_parry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diarmuid_parry_marker_effect", "abilities/diarmuid/diarmuid_parry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diarmuid_parry_marker_effect_skin", "abilities/diarmuid/diarmuid_parry", LUA_MODIFIER_MOTION_NONE)
diarmuid_parry = class({})

function diarmuid_parry:GetAOERadius()
	return self:GetSpecialValueFor("first_hit_radius")

end

function diarmuid_parry:OnSpellStart()
	local caster = self:GetCaster()


	

	caster:AddNewModifier(caster, self, "modifier_diarmuid_parry", {duration = self:GetSpecialValueFor("duration")})
	caster:AddNewModifier(caster, self, "modifier_diarmuid_parry_particle", {duration  = self:GetSpecialValueFor("duration")})

	caster:EmitSound("diar_parry_activate")
	caster:EmitSound("diar_parry_voice")

	local particle = ParticleManager:CreateParticle("particles/diarmuid/parry/diar_parry_cast.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleShouldCheckFoW(particle, false)
	ParticleManager:ReleaseParticleIndex(particle)

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self:GetSpecialValueFor("first_hit_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
	for k,v in pairs(targets) do
		if v:GetName() ~= "npc_dota_ward_base" then
			DoDamage(caster, v, self:GetSpecialValueFor("damage_cast"), DAMAGE_TYPE_MAGICAL, 0, self, false)
			v:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

		end
	end

	
end


function diarmuid_parry:Counter()
	local caster = self:GetCaster()
	local dir = caster:GetForwardVector()
	caster:RemoveModifierByName("modifier_diarmuid_parry_particle")

	local aoe_radius = self:GetSpecialValueFor("first_hit_radius")
	caster:EmitSound("diar_parry_prock")

	HardCleanse(caster)
	Timers:CreateTimer(FrameTime(), function()
		HardCleanse(caster)
	end)


	local damage = self:GetSpecialValueFor("damage")
	local projectilename = "particles/zlodemon/diar_combo/gae_buidhe_slash_counter.vpcf"
	if caster:HasModifier("modifier_hero_selection_skin") then
		projectilename = "particles/zlodemon/diar_combo/gae_buidhe_slash_counter_skin.vpcf"
	end
	local particle = ParticleManager:CreateParticle(projectilename, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(), dir)
	ParticleManager:ReleaseParticleIndex(particle)
	
	
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
	for k,v in pairs(targets) do
		if v:GetName() ~= "npc_dota_ward_base" then
			DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			giveUnitDataDrivenModifier(caster, v, "disarmed", self:GetSpecialValueFor("disarm_duration"))
			if caster.IsParryUpgraideAcquired then
				v:AddNewModifier(caster, self, "modifier_diarmuid_parry_marker", {duration = 5})
					if caster:HasModifier("modifier_hero_selection_skin") then
						v:AddNewModifier(caster, self, "modifier_diarmuid_parry_marker_effect_skin", {duration = 5})
					else
						v:AddNewModifier(caster, self, "modifier_diarmuid_parry_marker_effect", {duration = 5})
					end
			end
		end
	end
end

modifier_diarmuid_parry = class({})

function modifier_diarmuid_parry:IsHidden() return false end
function modifier_diarmuid_parry:IsDebuff() return false end

function modifier_diarmuid_parry:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_diarmuid_parry:OnCreated()

end

function modifier_diarmuid_parry:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end

function modifier_diarmuid_parry:GetModifierIncomingDamageConstant(keys)
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

				self:ActivateCounter()
			
					local dmgtable = {
						attacker = keys.attacker,
						victim = keys.target,
						damage = damage - self.hAbility:GetSpecialValueFor("shield_damage_decrease_flat_value"),
						damage_type = keys.damage_type,
						damage_flags = keys.damage_flags,
						ability = keys.inflictor
					}
					self:Destroy()
					ApplyDamage(dmgtable)
				
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_diarmuid_parry:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield_amount")
    


	if IsServer() then
		--self.hCaster:EmitSound("diarmuid_parry_sfx")
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_diarmuid_parry:OnRefresh(hTable)
	self:OnCreated(hTable)
end

function modifier_diarmuid_parry:ActivateCounter()

	self.hAbility:Counter()
end

--

modifier_diarmuid_parry_particle = class({})

function modifier_diarmuid_parry_particle:IsHidden() return true end
function modifier_diarmuid_parry_particle:IsDebuff() return false end

function modifier_diarmuid_parry_particle:OnCreated()
	self.caster = self:GetCaster()

	if IsServer() then
		if not self.shield_fx then

		    self.shield_fx = ParticleManager:CreateParticle( "particles/diarmuid/diar_parry/diar_parry_shield.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.caster ) 
		    ParticleManager:SetParticleControlEnt(self.shield_fx, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), false)

		    self:AddParticle(self.shield_fx, true, false, -1, false, false)
		end
	end
end



modifier_diarmuid_parry_marker = class({})
function modifier_diarmuid_parry_marker:IsHidden() return false end
function modifier_diarmuid_parry_marker:IsDebuff() return false end
function modifier_diarmuid_parry_marker:RemoveOnDeath() return true end


function modifier_diarmuid_parry_marker:CheckState()
	return {				[MODIFIER_STATE_INVISIBLE] = false,
                               [MODIFIER_STATE_TRUESIGHT_IMMUNE] = false,}
end

function modifier_diarmuid_parry_marker:GetModifierProvidesFOWVision()
    return  1
end
function modifier_diarmuid_parry_marker:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
           }
end

modifier_diarmuid_parry_marker_effect = class({})
function modifier_diarmuid_parry_marker_effect:IsHidden() return true end
function modifier_diarmuid_parry_marker_effect:IsDebuff() return false end
function modifier_diarmuid_parry_marker_effect:RemoveOnDeath() return true end


function modifier_diarmuid_parry_marker_effect:GetEffectName()
	return "particles/zlodemon/zlodemon_overhead_duel_diarmuid.vpcf"
end

function modifier_diarmuid_parry_marker_effect:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_diarmuid_parry_marker_effect_skin = class({})
function modifier_diarmuid_parry_marker_effect_skin:IsHidden() return true end
function modifier_diarmuid_parry_marker_effect_skin:IsDebuff() return false end
function modifier_diarmuid_parry_marker_effect_skin:RemoveOnDeath() return true end


function modifier_diarmuid_parry_marker_effect_skin:GetEffectName()
	return "particles/zlodemon/zlodemon_overhead_duel_diarmuid_skin.vpcf"
end

function modifier_diarmuid_parry_marker_effect_skin:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end


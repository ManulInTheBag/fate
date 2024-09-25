LinkLuaModifier("modifier_king_hassan_block", "abilities/kinghassan/khsn_slash", LUA_MODIFIER_MOTION_NONE)
khsn_slash = class({})

function khsn_slash:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=0.8, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
    return true
end

function khsn_slash:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end


function khsn_slash:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = ability:GetCursorPosition()
	local width = ability:GetSpecialValueFor("width")
	local cast_delay = ability:GetSpecialValueFor("cast_delay")
	local range = ability:GetSpecialValueFor("length")
	local speed = ability:GetSpecialValueFor("speed")

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 0.5)
    caster:EmitSound("KingHassan.Azrael")

	local azrael = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = 9999,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = range - width + 50,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 3.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 9999
	}

	FreezeAnimation(caster, cast_delay)	

    local particle = ParticleManager:CreateParticle("particles/kinghassan/azrael/hassanultarea.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, targetPoint + Vector(0,0,50))

	Timers:CreateTimer( cast_delay - 0.15, function()
		UnfreezeAnimation(caster)
		if caster:IsAlive() then
			azrael.vSpawnOrigin = caster:GetAbsOrigin() 
			azrael.vVelocity = caster:GetForwardVector() * speed
			local projectile = ProjectileManager:CreateLinearProjectile(azrael)
			ParticleManager:SetParticleControl(projectile, 2, GetRotationPoint(caster:GetAbsOrigin(), range ,caster:GetAnglesAsVector().x))

			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)

				
					-- Create Particle for projectile
			local casterFacing = caster:GetForwardVector()
			local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			dummy:SetForwardVector(casterFacing)
			dummy:SetAbsOrigin(caster:GetAbsOrigin())
					
			local excalFxIndex = ParticleManager:CreateParticle( "particles/kinghassan/azrael/hassanult.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
			ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(width * 4,6,4))
			caster:EmitSound("KingHassan.AzraelCut")

			Timers:CreateTimer( 0.5, function()
				ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
				Timers:CreateTimer( 0.2, function()
					if IsValidEntity(dummy) then
						dummy:RemoveSelf()
					end
					return nil
				end)
				return nil
			end)
			return 
		end
		return nil
	end)
end

function khsn_slash:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	local caster = self:GetCaster()
	local target = hTarget
	local ability = self 
	local stun_duration = ability:GetSpecialValueFor("stun")
	local damage = ability:GetSpecialValueFor("damage")

	if not IsValidEntity(target) or target:IsNull() then return end

	if target == nil then return end

	--[[if caster.IsOldManOfTheMountainAcquired then
		local bonus_agi = ability:GetSpecialValueFor("bonus_agi") * caster:GetAgility()
		DoDamage(caster, target, bonus_agi , DAMAGE_TYPE_PURE, 0, ability, false) 			
	end]]
	caster:AddNewModifier(caster, self, "modifier_king_hassan_block", {})
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
end


modifier_king_hassan_block = class({})

function modifier_king_hassan_block:IsHidden() return false end
function modifier_king_hassan_block:IsDebuff() return false end

function modifier_king_hassan_block:OnCreated()

end

function modifier_king_hassan_block:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT
					}
	return hFunc
end
--[[function modifier_jeanne_mrex:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end]]
function modifier_king_hassan_block:GetModifierIncomingSpellDamageConstant(keys)
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

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end
--[[function modifier_jeanne_mrex:GetModifierMagical_ConstantBlock(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.damage
            if block_check > 0 then
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
                self:Destroy()
            end

            return block_now
        end
	end
end]]

function modifier_king_hassan_block:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	if not self.fBarrierBlock then
		self.fBarrierBlock = 0
	end

	self.fBarrierBlock = math.min(self.fBarrierBlock + self.hAbility:GetSpecialValueFor("block_per_unit"), self.hAbility:GetSpecialValueFor("block_max"))
    
    if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/king_hassan/khsn_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl(self.iShieldPFX, 0, self.hParent:GetAbsOrigin())

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	else
		local flashFX = ParticleManager:CreateParticle("particles/kinghassan/khsn_shield_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
		ParticleManager:SetParticleControl(flashFX, 0, self.hParent:GetAbsOrigin())

		ParticleManager:ReleaseParticleIndex(flashFX)
	end

	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_king_hassan_block:OnRefresh(hTable)
	self:OnCreated(hTable)
end
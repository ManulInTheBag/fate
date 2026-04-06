LinkLuaModifier("modifier_aoko_facebreaker_shield", "abilities/aoko/aoko_facebreaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_facebreaker_debuff_immunity", "abilities/aoko/aoko_facebreaker", LUA_MODIFIER_MOTION_NONE)

aoko_facebreaker = class({})

function aoko_facebreaker:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_jumpback"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_jumpback"):SetLevel(self:GetLevel())
    end
end

function aoko_facebreaker:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

function aoko_facebreaker:OnSpellStart()
	local caster = self:GetCaster()

	local tpoint = self:GetCursorPosition()

	local dir = (tpoint - caster:GetAbsOrigin()):Normalized()
	dir.z = 0
	if not (tpoint == caster:GetAbsOrigin()) then
		caster:SetForwardVector(dir)
	end

	caster:EmitSound("aoko_facebreaker")

	if caster.FirstStarAcquired then
		caster:AddNewModifier(caster, self, "modifier_aoko_facebreaker_shield", {duration = self:GetSpecialValueFor("attribute_shield_duration")})
		caster:AddNewModifier(caster, self, "modifier_aoko_facebreaker_debuff_immunity", {duration = self:GetChannelTime()})
	end
end

function aoko_facebreaker:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()

	--caster:RemoveModifierByName("modifier_aoko_facebreaker_shield")

	if not bInterrupted then
		local circuits = caster:FindAbilityByName("aoko_circuits")
		local stacks = self:GetSpecialValueFor("stack_gain")

		local range = self:GetSpecialValueFor("range")
		local width = self:GetSpecialValueFor("width")
		local damage = self:GetSpecialValueFor("damage")
		local stun_duration = self:GetSpecialValueFor("stun_duration")

		local tpoint = self:GetCursorPosition()

		local dir = (tpoint - caster:GetAbsOrigin()):Normalized()
		dir.z = 0
		if not (tpoint == caster:GetAbsOrigin()) then
			caster:SetForwardVector(dir)
		end

		local range = self:GetSpecialValueFor("range")
		local width = self:GetSpecialValueFor("width")

		local ori = caster:GetAbsOrigin()
		dir = caster:GetForwardVector()

		local breaker_fx = ParticleManager:CreateParticle("particles/aoko/aoko_facebreaker.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(breaker_fx, 0, ori + dir*range)
		ParticleManager:SetParticleControl(breaker_fx, 1, ori)
		ParticleManager:SetParticleControl(breaker_fx, 2, Vector(0, width, 0))

		ParticleManager:ReleaseParticleIndex(breaker_fx)

		local breaker_fx2 = ParticleManager:CreateParticle("particles/aoko/aoko_facebreaker.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(breaker_fx2, 0, ori - dir*range)
		ParticleManager:SetParticleControl(breaker_fx2, 1, ori)
		ParticleManager:SetParticleControl(breaker_fx2, 2, Vector(0, width, 0))

		ParticleManager:ReleaseParticleIndex(breaker_fx2)

		local ori = caster:GetAbsOrigin()

		local ori_2 = ori + dir*100

		local pepega = false

		local enemies = FATE_FindUnitsInLine(
									        caster:GetTeamNumber(),
									        ori - range*dir,
									        ori + range*dir,
									        width,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_HERO,
											DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
											FIND_CLOSEST
	    								)

		for _, enemy in pairs(enemies) do
			enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = stun_duration })
			DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

			EmitSoundOn("aoko_facebreaker_sfx", enemy)

			if not pepega then
				circuits:GainStacks(stacks)
				pepega = true
			end

			local dir_2 = (enemy:GetAbsOrigin() - ori):Normalized()
			local pos = ori_2 + dir_2*50
			if( not IsKnockbackImmune(enemy)) then
				FindClearSpaceForUnit(enemy, GetGroundPosition(pos, enemy), true)
			end
		end
	end
end

--

modifier_aoko_facebreaker_shield = class({})

function modifier_aoko_facebreaker_shield:IsHidden() return false end
function modifier_aoko_facebreaker_shield:IsDebuff() return false end

function modifier_aoko_facebreaker_shield:OnCreated()

end

function modifier_aoko_facebreaker_shield:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_aoko_facebreaker_shield:GetModifierIncomingDamageConstant(keys)
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
                self.hCaster:RemoveModifierByName("modifier_aoko_facebreaker_debuff_immunity")
                ApplyDamage(dmgtable)
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_aoko_facebreaker_shield:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("attribute_shield_amount")
    
    --[[if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/custom/jeanne/jeanne_luminosite_eternelle_barrier.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl( self.iShieldPFX, 0, self.hCaster:GetAbsOrigin() )

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	end]]

	if IsServer() then
		--self.hCaster:EmitSound("aoko_shield_sfx")
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_aoko_facebreaker_shield:OnRefresh(hTable)
	self:OnCreated(hTable)
end

modifier_aoko_facebreaker_debuff_immunity = class({})

function modifier_aoko_facebreaker_debuff_immunity:IsHidden() return true end
function modifier_aoko_facebreaker_debuff_immunity:IsDebuff() return false end

function modifier_aoko_facebreaker_debuff_immunity:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end
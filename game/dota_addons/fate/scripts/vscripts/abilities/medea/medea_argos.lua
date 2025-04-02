LinkLuaModifier("modifier_argos_armor", "abilities/medea/medea_argos", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_argos_shield", "abilities/medea/medea_argos", LUA_MODIFIER_MOTION_NONE)
medea_argos = class({})

function medea_argos:OnSpellStart()
    local caster = self:GetCaster()
	local ability = self
	local ply = caster:GetPlayerOwner()
    local max_shield = self:GetSpecialValueFor("max_shield")
    local shield_amount = self:GetSpecialValueFor("shield_amount")
    if caster:HasModifier("modifier_argos_shield") then
        shield_amount = shield_amount + caster:GetModifierStackCount("modifier_argos_shield", caster)
        if shield_amount > max_shield then
            shield_amount = max_shield
        end
    end
	if caster.IsArgosImproved then 
		max_shield = max_shield + 150 
		shield_amount = shield_amount + 100
		caster:AddNewModifier(caster, self, "modifier_argos_armor", {duration = self:GetSpecialValueFor("armor_duration")})
	end
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if ability == caster:FindAbilityByName("medea_argos") and caster:FindAbilityByName("medea_hecatic_graea"):IsCooldownReady() and caster:FindAbilityByName("medea_hecatic_graea_combo"):IsCooldownReady() then
			caster:SwapAbilities("medea_hecatic_graea", "medea_hecatic_graea_combo", false, true) 
			caster.IsHGComboEnabled = true
			Timers:CreateTimer({
				endTime = 5,
				callback = function()
				caster:SwapAbilities("medea_hecatic_graea", "medea_hecatic_graea_combo", true, false) 
				caster.IsHGComboEnabled = false
			end
			})			
		end
	end
	caster:AddNewModifier(caster, self, "modifier_argos_shield", {duration = -1, shield = shield_amount})
	caster.argosShieldAmount = shield_amount

	-- Create particle
	if caster.argosDurabilityParticleIndex == nil then
		local prev_amount = 0.0
		Timers:CreateTimer( function()
				-- Check if shield still valid
				if caster.argosShieldAmount > 0 and caster:HasModifier( "modifier_argos_shield" ) then
					-- Check if it should update
					if prev_amount ~= caster.argosShieldAmount then
						-- Change particle
						local digit = 0
						if caster.argosShieldAmount > 999 then
							digit = 4
						elseif caster.argosShieldAmount > 99 then
							digit = 3
						elseif caster.argosShieldAmount > 9 then
							digit = 2
						else
							digit = 1
						end
						if caster.argosDurabilityParticleIndex ~= nil then
							-- Destroy previous
							ParticleManager:DestroyParticle( caster.argosDurabilityParticleIndex, true )
							ParticleManager:ReleaseParticleIndex( caster.argosDurabilityParticleIndex )
						end
						-- Create new one
						caster.argosDurabilityParticleIndex = ParticleManager:CreateParticle( "particles/custom/caster/caster_argos_durability.vpcf", PATTACH_CUSTOMORIGIN, caster )
						ParticleManager:SetParticleControlEnt( caster.argosDurabilityParticleIndex, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true )
						ParticleManager:SetParticleControl( caster.argosDurabilityParticleIndex, 1, Vector( 0, math.floor( caster.argosShieldAmount ), 0 ) )
						ParticleManager:SetParticleControl( caster.argosDurabilityParticleIndex, 2, Vector( 1, digit, 0 ) )
						ParticleManager:SetParticleControl( caster.argosDurabilityParticleIndex, 3, Vector( 100, 100, 255 ) )
						
						prev_amount = caster.argosShieldAmount	
					end
					
					return 0.1
				else
					if caster.argosDurabilityParticleIndex ~= nil then
						ParticleManager:DestroyParticle( caster.argosDurabilityParticleIndex, true )
						ParticleManager:ReleaseParticleIndex( caster.argosDurabilityParticleIndex )
						caster.argosDurabilityParticleIndex = nil
					end
					return nil
				end
			end
		)
	end


end



modifier_argos_shield = class({})

function modifier_argos_shield:IsHidden() return false end
function modifier_argos_shield:IsDebuff() return false end

function modifier_argos_shield:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end


function modifier_argos_shield:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
 
function modifier_argos_shield:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.damage
                self:SetStackCount(block_check)
                self:GetCaster().argosShieldAmount = block_check
                self.fBarrierBlock = block_check
            else
            	blocked = keys.damage--block_now
            	local damage = keys.damage - block_now
				if damage > 0 then
					local dmgtable = {
						attacker = keys.attacker,
						victim = keys.target,
						damage = damage,
						damage_type = keys.damage_type,
						damage_flags = keys.damage_flags,
						ability = keys.inflictor
					}
                    self:GetCaster().argosShieldAmount = 0
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

function modifier_argos_shield:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = hTable.shield
    if IsServer() then
        self:SetStackCount(self.fBarrierBlock)
    end
end
function modifier_argos_shield:OnRefresh(hTable)
	self:OnCreated(hTable)
end

function modifier_argos_shield:GetEffectName()
	return "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf"
end
function modifier_argos_shield:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_argos_armor = modifier_argos_armor or class({})


function modifier_argos_armor:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()

		
		self.fArmor   = self:GetAbility():GetSpecialValueFor("armor")


	end
end
function modifier_argos_armor:OnRefresh(tTable)
	self:OnCreated(tTable)
end




function modifier_argos_armor:IsHidden() return false end
function modifier_argos_armor:IsDebuff() return false end
function modifier_argos_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,

	}
end


function modifier_argos_armor:GetModifierPhysicalArmorBonus()
	if IsServer() then
        CustomNetTables:SetTableValue("sync","medea_argos", { armor = self:GetAbility():GetSpecialValueFor("armor")  })
    	return self.fArmor
	elseif IsClient() then
		local armor = CustomNetTables:GetTableValue("sync","medea_argos").armor
		return armor
	end
end


arturia_alter_mana_discharge = class({})

LinkLuaModifier("modifier_derange_discharge", "abilities/arturia_alter/arturia_alter_mana_discharge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_derange_discharge_2", "abilities/arturia_alter/arturia_alter_mana_discharge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_derange", "abilities/arturia_alter/arturia_alter_derange", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_mana_discharge:OnSpellStart()

	if self:GetCaster():FindModifierByName("modifier_derange") ~= nil then

			self.mana_drain = self:GetCaster():GetMaxMana()*0.05
			self:GetCaster():RemoveModifierByName("modifier_derange")
			self:GetCaster():AddNewModifier(caster, self, "modifier_derange_discharge", {})

			self.cast = ParticleManager:CreateParticle("particles/custom/saber_alter/god_is_great/boom_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())

			LoopOverPlayers(function(player, playerID, playerHero)
        		if playerHero.gachi == true then
            		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound = "a_negri"})
       			end
    	end)
	end

end

function arturia_alter_mana_discharge:CastFilterResult()
    local caster = self:GetCaster()
    if IsServer() and not caster:FindModifierByName("modifier_derange") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function arturia_alter_mana_discharge:GetCustomCastError()
	return "Can only be activated in Derange"
end

modifier_derange_discharge = class({})

function modifier_derange_discharge:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODFIER_EVENT_ON_RESPAWN,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_derange_discharge:CheckState()
    local state =   { 
                        
						[MODIFIER_STATE_SILENCED] = true,

                    }
    return state
end

function modifier_derange_discharge:IsHidden() return false end
function modifier_derange_discharge:IsDebuff() return false end
function modifier_derange_discharge:RemoveOnDeath() return true end
function modifier_derange_discharge:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.mana = self:GetParent():GetMaxMana()
	self.mana_discharge = 0
	if IsServer() then
		self:StartIntervalThink(0.25)
	end
end


function modifier_derange_discharge:OnIntervalThink()

	if self.parent:GetMana() < self:GetAbility().mana_drain then
		self.mana_discharge = self.mana_discharge + self.parent:GetMana()
		self:GetParent():SpendMana(self:GetParent():GetMana(), self)

		if self.mana_discharge >= self.mana/2
			then self.mana_discharge = self.mana/2
		end

		self.mana_discharge = self.mana_discharge + self.ability:GetSpecialValueFor("damage")

		local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self.parent:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    	for k,v in pairs(targets) do            
        	DoDamage(self.parent, v, self.mana_discharge, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
        	v:AddNewModifier(self.parent, self.ability, "modifier_stunned", {Duration = self.ability:GetSpecialValueFor("stun_duration")})
        	self.parent:AddNewModifier(self.parent, self.ability, "modifier_stunned", {Duration = self.ability:GetSpecialValueFor("stun_duration")})
    	end
    	self.parent:AddNewModifier(self.parent, self.ability, "modifier_stunned", {Duration = self.ability:GetSpecialValueFor("stun_duration_self")})
     	self.explosionFx = ParticleManager:CreateParticle("particles/custom/saber_alter/god_is_great/boom.vpcf", PATTACH_CUSTOMORIGIN, nil)
    	ParticleManager:SetParticleControl(self.explosionFx, 0, self:GetParent():GetAbsOrigin())
    	ParticleManager:SetParticleControl(self.explosionFx, 1, Vector(600,600,0))
    	ParticleManager:DestroyParticle(self.explosionFx, false)
       	ParticleManager:ReleaseParticleIndex(self.explosionFx)
       	self:GetAbility():EmitSound("maelstorm")
       	self:GetAbility():EmitSound("Hero_Leshrac.Split_Earth")
       	self:Destroy()
	else
		self:GetParent():SpendMana(self:GetAbility().mana_drain, self.ability)
		self.mana_discharge = self.mana_discharge + self.ability.mana_drain
		self.ability.mana_drain = self.ability.mana_drain * 1.1
    end
end

function modifier_derange_discharge:OnDestroy()
ParticleManager:DestroyParticle(self:GetAbility().cast, true)
ParticleManager:ReleaseParticleIndex(self:GetAbility().cast)
self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_derange_discharge_2", {duration = 2.5})
end

function modifier_derange_discharge:GetModifierAttackSpeedBonus_Constant()
	return self:GetParent():GetAbilityByIndex(0):GetSpecialValueFor("as") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_1")/100
end

function modifier_derange_discharge:GetModifierMoveSpeedBonus_Percentage()
	return self:GetParent():GetAbilityByIndex(0):GetSpecialValueFor("ms") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_2")/100
end

function modifier_derange_discharge:GetModifierPreAttack_BonusDamage()
	return self:GetParent():GetAbilityByIndex(0):GetSpecialValueFor("dmg") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_3")/100
end

function modifier_derange_discharge:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_bonus")
end

function modifier_derange_discharge:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr_bonus")
end

function modifier_derange_discharge:GetTexture()
	return "custom/saber_alter_derange"
end

function modifier_derange_discharge:GetEffectName()
	return "particles/items2_fx/satanic_buff.vpcf"
end

modifier_derange_discharge_2 = class({})

function modifier_derange_discharge_2:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODFIER_EVENT_ON_RESPAWN,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_derange_discharge_2:IsHidden() return false end
function modifier_derange_discharge_2:IsDebuff() return false end
function modifier_derange_discharge_2:RemoveOnDeath() return true end

function modifier_derange_discharge_2:GetModifierAttackSpeedBonus_Constant()
	return self:GetParent():GetAbilityByIndex(0):GetSpecialValueFor("as") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_1")/100
end

function modifier_derange_discharge_2:GetModifierMoveSpeedBonus_Percentage()
	return self:GetParent():GetAbilityByIndex(0):GetSpecialValueFor("ms") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_2")/100
end

function modifier_derange_discharge_2:GetModifierPreAttack_BonusDamage()
	return self:GetParent():GetAbilityByIndex(0):GetSpecialValueFor("dmg") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_3")/100
end

function modifier_derange_discharge_2:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_bonus")
end

function modifier_derange_discharge_2:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr_bonus")
end

function modifier_derange_discharge_2:GetTexture()
	return "custom/saber_alter_derange"
end

function modifier_derange_discharge_2:GetEffectName()
	return "particles/items2_fx/satanic_buff.vpcf"
end
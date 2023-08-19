LinkLuaModifier("modifier_arash_stella_stacks", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_toughness", "abilities/arash/arash_toughness", LUA_MODIFIER_MOTION_NONE)
arash_toughness = class({})

function arash_toughness:OnSpellStart()
	local caster = self:GetCaster()
	local stacks = 0
	if caster:HasModifier("modifier_arash_stella_stacks") then
		stacks = caster:GetModifierStackCount("modifier_arash_stella_stacks", caster)
	end
	local buffDuration = self:GetSpecialValueFor("duration")
	local mr = self:GetSpecialValueFor("base_mr") + self:GetSpecialValueFor("mr_per_stack") * stacks
	local armor = self:GetSpecialValueFor("base_armor") + self:GetSpecialValueFor("armor_per_stack") * stacks
	local heal = self:GetSpecialValueFor("base_heal") + self:GetSpecialValueFor("heal_per_stack") * stacks
	caster:Heal(heal, caster)
	caster:AddNewModifier(caster, self, "modifier_arash_toughness", {duration  = buffDuration, mr = mr, armor = armor})
	caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
end


modifier_arash_toughness = class({})

function modifier_arash_toughness:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_arash_toughness:OnCreated(args)
	if not IsServer() then return end
	self.mr = args.mr
	self.armor = args.armor
	CustomNetTables:SetTableValue("sync","arash", { mr = self.mr, armor = self.armor})
end

function modifier_arash_toughness:GetModifierMagicalResistanceBonus()
	if IsServer() then        
        return self.mr
    elseif IsClient() then
        local mr = CustomNetTables:GetTableValue("sync","arash").mr
        return mr 
    end
end

function modifier_arash_toughness:GetModifierPhysicalArmorBonus()
    if IsServer() then        
        return self.armor
    elseif IsClient() then
        local armor = CustomNetTables:GetTableValue("sync","arash").armor
        return armor 
    end
end

function modifier_arash_toughness:IsDebuff()                                                             return false end
function modifier_arash_toughness:IsPurgable()                                                           return false end
function modifier_arash_toughness:IsPurgeException()                                                     return false end
function modifier_arash_toughness:RemoveOnDeath()                                                        return true end
function modifier_arash_toughness:IsHidden()															  return false end

function modifier_arash_toughness:GetEffectName()
	return "particles/arash/arash_toughness_buff.vpcf"
end

function modifier_arash_toughness:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
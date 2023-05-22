modifier_tea_party_enemy = class({})

if IsServer() then
	function modifier_tea_party_enemy:OnCreated(args)
		self.PartyCenterX = args.PartyCenterX
		self.PartyCenterY = args.PartyCenterY
		self.PartyCenterZ = args.PartyCenterZ
		self.PartySize = args.PartySize

		self:StartIntervalThink(0.05)

		self.raped = false
	end

	function modifier_tea_party_enemy:OnIntervalThink()	
		local parent = self:GetParent()
		local PartyCenter = Vector(self.PartyCenterX, self.PartyCenterY, self.PartyCenterZ)

		if math.abs((parent:GetAbsOrigin() - PartyCenter):Length2D()) > self.PartySize then
			self:Destroy()
		end
		if not parent:IsMagicImmune() then
			if parent:GetName() == "npc_dota_hero_juggernaut" then
				parent:SetMana(parent:GetMana() - 3)
			else
				parent:SetMana(parent:GetMana() - self:GetAbility():GetSpecialValueFor("mana_per_second")/20)
			end
			if parent:GetMana() < 1 and parent:HasModifier("modifier_tea_party_enemy") and not self.raped == true then
				self:ReaperScythe()
			end
		end
	end
end

function modifier_tea_party_enemy:ReaperScythe()
	self.raped = true
	local target = self:GetParent()
	local damage = (self:GetAbility():GetCaster():GetIntellect() - target:GetIntellect())*self:GetAbility():GetSpecialValueFor("damage_per_int")
	DoDamage(self:GetAbility():GetCaster(), target, damage, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
	giveUnitDataDrivenModifier(self:GetCaster(), target, "revoked", 2)
	giveUnitDataDrivenModifier(self:GetCaster(), target, "silenced", 2)
	target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_tea_party_model", { Duration = 2})
end

function modifier_tea_party_enemy:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
			 }
end

function modifier_tea_party_enemy:GetModifierProvidesFOWVision()
	return 1
end

--[[function modifier_aestus_domus_aurea_enemy:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.ResistReduc
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").magic_resist
        return magic_resist 
	end
end

function modifier_aestus_domus_aurea_enemy:GetModifierPhysicalArmorBonus()
	if IsServer() then
		return self.ArmorReduc
	elseif IsClient() then
		local armor_reduction = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").armor_reduction
        return armor_reduction 
	end
end

function modifier_aestus_domus_aurea_enemy:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.MovespeedReduc
	elseif IsClient() then
		local movespeed = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").movespeed
        return movespeed 
	end
end]]

function modifier_tea_party_enemy:IsHidden()
	return false
end

function modifier_tea_party_enemy:IsDebuff()
	return true
end

function modifier_tea_party_enemy:RemoveOnDeath()
	return true
end

function modifier_tea_party_enemy:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_tea_party_enemy:GetTexture()
	return "custom/alice/alice_tea_party"
end

-------------------------------------------------------

modifier_tea_party_model = class({})

function modifier_tea_party_model:OnCreated()
	self.parent = self:GetParent()
	self.oldscale = self.parent:GetModelScale()
	self.parent:SetModelScale(0.78)
end


function modifier_tea_party_model:OnDestroy() 
 
	self.parent:SetModelScale(self.oldscale)
end


function modifier_tea_party_model:DeclareFunctions()
	local funcs = {
				MODIFIER_PROPERTY_MODEL_CHANGE
	}

	return funcs
end

function modifier_tea_party_model:GetModifierModelChange()
	self.model_fx = "models/nurseryrhyme/nurseryrhyme.vmdl"
	return self.model_fx
end

 
function modifier_tea_party_model:IsHidden()
	return true
end

function modifier_tea_party_model:IsDebuff()
	return true
end

function modifier_tea_party_model:RemoveOnDeath()
	return true
end

function modifier_tea_party_model:GetAttributes()
  	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
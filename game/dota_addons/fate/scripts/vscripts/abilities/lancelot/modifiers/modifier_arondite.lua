modifier_arondite = class({})

function modifier_arondite:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			 MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			 MODIFIER_PROPERTY_MODEL_CHANGE }
end

function modifier_arondite:GetModifierModelChange()
  return "models/lancelot/lancelot.vmdl"--"models/updated_by_seva_and_hudozhestvenniy_film_spizdili/lancelot/lancelotunanim.vmdl"
end

if IsServer() then
	function modifier_arondite:CheckState()
		return self.state
	end

	function modifier_arondite:OnCreated(args)	
		self.StrengthBonus = args.StrengthBonus
		self.AgilityBonus = args.AgilityBonus
		self.IntelligenceBonus = args.IntelligenceBonus
		self.BonusDamage = args.BonusDamage

		CustomNetTables:SetTableValue("sync","arondite_stats", { str_bonus = self.StrengthBonus,
																 agi_bonus = self.AgilityBonus,
																 int_bonus = self.IntelligenceBonus,
																 bonus_damage = self.BonusDamage })

		self.SwordParticle = ParticleManager:CreateParticle("particles/custom/lancelot/lancelot_arondite.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
	    ParticleManager:SetParticleControlEnt(self.SwordParticle, 0, self:GetParent(), PATTACH_CUSTOMORIGIN_FOLLOW, "attach_arondight", self:GetParent():GetOrigin(), true)
	
	    if args.KotlAttribute then
	    	self.state = { [MODIFIER_STATE_MAGIC_IMMUNE] = true }
	    	self:GetParent():RemoveModifierByName("modifier_zabaniya_curse")
	    	HardCleanse(self:GetParent())
	    	self:StartIntervalThink(0.5)

	    	self.nRagePFX = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_rage.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	    					for i = 0, 2 do
		    					ParticleManager:SetParticleControlEnt(
	                                                                self.nRagePFX,
	                                                                i,
	                                                                self:GetParent(),
	                                                                PATTACH_POINT_FOLLOW,
	                                                                "attach_hitloc",
	                                                                Vector(0,0,0), -- unknown
	                                                                false -- unknown, true
	                                                                )
	    					end
	    	Timers:CreateTimer(2, function()
	    		self:RemoveBKBPfx()
	    		self.state={}
	    	end)
	    end
	end

	function modifier_arondite:OnRefresh(args)
		self:RemoveBKBPfx()
		self:RemoveParticles()
		self:OnCreated(args)
	end

	function modifier_arondite:OnDestroy()
		self:RemoveParticles()
	end

	function modifier_arondite:RemoveBKBPfx()
		if type(self.nRagePFX) == "number" then
			ParticleManager:DestroyParticle( self.nRagePFX, false )
			ParticleManager:ReleaseParticleIndex( self.nRagePFX )
			self.nRagePFX = nil
		end
	end

	function modifier_arondite:RemoveParticles()
		ParticleManager:DestroyParticle( self.SwordParticle, false )
		ParticleManager:ReleaseParticleIndex( self.SwordParticle )
		self.SwordParticle = nil
	end

	function modifier_arondite:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end		
		local caster = self:GetParent()
		caster:FindAbilityByName("lancelot_arondite"):CreateFireProjectile()
	end

	function modifier_arondite:OnIntervalThink()
       HardCleanse(self:GetParent())
	end
end



function modifier_arondite:GetModifierBonusStats_Strength()
	if IsServer() then       
        return self.StrengthBonus
    elseif IsClient() then
        local str_bonus = CustomNetTables:GetTableValue("sync","arondite_stats").str_bonus
        return str_bonus 
    end
end

function modifier_arondite:GetModifierBonusStats_Agility()
	if IsServer() then       
        return self.AgilityBonus
    elseif IsClient() then
        local agi_bonus = CustomNetTables:GetTableValue("sync","arondite_stats").agi_bonus
        return agi_bonus 
    end
end

function modifier_arondite:GetModifierBonusStats_Intellect()
	if IsServer() then       
        return self.IntelligenceBonus
    elseif IsClient() then
        local int_bonus = CustomNetTables:GetTableValue("sync","arondite_stats").int_bonus
        return int_bonus 
    end
end

function modifier_arondite:GetModifierPreAttack_BonusDamage()
	if IsServer() then       
        return self.BonusDamage
    elseif IsClient() then
        local bonus_damage = CustomNetTables:GetTableValue("sync","arondite_stats").bonus_damage
        return bonus_damage 
    end
end

function modifier_arondite:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_arondite:IsPurgable()
    return true
end

function modifier_arondite:IsDebuff()
    return false
end

function modifier_arondite:RemoveOnDeath()
    return true
end

function modifier_arondite:GetEffectName()
	return "particles/custom/lancelot/lancelot_arondite_ambient.vpcf"
end

function modifier_arondite:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end

function modifier_arondite:GetTexture()
    return "custom/lancelot_arondite"
end
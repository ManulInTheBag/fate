modifier_prot_wind_resist = class({})

function modifier_prot_wind_resist:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_prot_wind_resist:OnCreated(args)
	if IsServer() then
		self.MagicResist = 0
		self:StartIntervalThink(0.25)
	end
end

function modifier_prot_wind_resist:OnIntervalThink()
	local caster = self:GetParent()
	local bIsVisibleToEnemy = false
	LoopOverPlayers(function(player, playerID, playerHero)
		-- if enemy hero can see astolfo, set visibility to true
		if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() then
			if playerHero:CanEntityBeSeenByMyTeam(caster) then
				bIsVisibleToEnemy = true
				return
			end
		end
	end)

	if bIsVisibleToEnemy then
		--print("revealed")
		self.MagicResist = math.max(self.MagicResist - 5, 0)
	else
		--print("hidden")
		self.MagicResist = math.min(self.MagicResist + 5, 40)
	end
	
	CustomNetTables:SetTableValue("sync","prot_wind_resist", { mresist = self.MagicResist })
end

function modifier_prot_wind_resist:GetModifierMagicalResistanceBonus()
	if IsServer() then       
        return self.MagicResist
    elseif IsClient() then
        local mresist = CustomNetTables:GetTableValue("sync","prot_wind_resist").mresist
        return mresist 
    end
end

function modifier_prot_wind_resist:IsHidden()
	return true
end

function modifier_prot_wind_resist:IsPermanent()
	return true
end

function modifier_prot_wind_resist:RemoveOnDeath()
	return false
end

function modifier_prot_wind_resist:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
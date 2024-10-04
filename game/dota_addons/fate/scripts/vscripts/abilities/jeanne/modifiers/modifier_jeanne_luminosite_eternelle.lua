modifier_jeanne_luminosite_eternelle = class({})

LinkLuaModifier("modifier_jeanne_luminosite_eternelle_slow", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_luminosite_eternelle_barrier", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_mrex_allies", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_regen_allies", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_mana_regen_allies", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle", LUA_MODIFIER_MOTION_NONE)
function modifier_jeanne_luminosite_eternelle:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.hp_heal = self:GetAbility():GetSpecialValueFor("heal_per_second")
	if self.parent.IsDivineSymbolAcquired then
		self.hp_heal = self.hp_heal*1.5
	end
	
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	local ori = caster:GetAbsOrigin()
	
	self.hp_heal = self:GetAbility():GetSpecialValueFor("heal_per_second")

	self.parent:AddNewModifier(self.parent, self:GetAbility(), "modifier_jeanne_luminosite_eternelle_barrier", {duration = self:GetAbility():GetSpecialValueFor("channel_duration")})
	
	local targets = DOTA_UNIT_TARGET_HERO

	--[[local sacredZoneFx = ParticleManager:CreateParticle("particles/custom/ruler/luminosite_eternelle/sacred_zone.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(sacredZoneFx, 0, ori)
	ParticleManager:SetParticleControl(sacredZoneFx, 1, Vector(1,1,radius))
	ParticleManager:SetParticleControl(sacredZoneFx, 14, Vector(radius,radius,0))
	ParticleManager:SetParticleControl(sacredZoneFx, 4, Vector(-radius * .9,0,0) + ori) -- Cross arm lengths
	ParticleManager:SetParticleControl(sacredZoneFx, 5, Vector(radius * .9,0,0) + ori)
	ParticleManager:SetParticleControl(sacredZoneFx, 6, Vector(0,-radius * .9,0) + ori)
	ParticleManager:SetParticleControl(sacredZoneFx, 7, Vector(0,radius * .9,0) + ori)
	self:AddParticle(sacredZoneFx, false, false, -1, false, false)]]
	--self.CurrentFlagParticle = sacredZoneFx

	local sacredBubble = ParticleManager:CreateParticle("particles/jeanne/jeanne_luminocite_magnetic.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(sacredBubble, 0, ori)
	ParticleManager:SetParticleControl(sacredBubble, 1, Vector(radius,0,0))
	self:AddParticle(sacredBubble, false, false, -1, false, false)
	--self.BubbleFlagParticle = sacredBubble
	
	local healFx = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_luminosite_eternelle_final_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( healFx, 0, caster:GetAbsOrigin())
	
	Timers:CreateTimer( 6.0, function()
		ParticleManager:DestroyParticle( healFx, false )
		ParticleManager:ReleaseParticleIndex( healFx )
	end)

	-- Find Units in Radius
	local allies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self.parent:GetAbsOrigin() ,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
		targets,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	
	if allies == nil then
	end

	caster:EmitSound("jeanne_heal_beep")
	
	for _,ally in pairs(allies) do
		-- Add modifier
		ally:Heal(self.hp_heal, caster)
	end
	
-- Find Units in Radius
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self.parent:GetAbsOrigin() ,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		targets,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	
	for _,enemy in pairs(enemies) do
		-- Add modifier			
		enemy:AddNewModifier(caster, self:GetAbility(), "modifier_jeanne_luminosite_eternelle_slow", { Duration = 1 })
		if self.parent.IsSaintImproved then
			giveUnitDataDrivenModifier(caster, enemy, "rooted", self:GetAbility():GetSpecialValueFor("first_root_duration"))
		end

	end
	self.counter = 0
	self:StartIntervalThink(1.0)
	self:PlayEffects()
end

function modifier_jeanne_luminosite_eternelle:OnRefresh()
	if not IsServer() then return end
	self.counter = 0
	self.parent = self:GetParent()
	self.hp_heal = self:GetAbility():GetSpecialValueFor("heal_per_second")
	if self.parent.IsDivineSymbolAcquired then
		self.hp_heal = self.hp_heal*1.5
	end

	self.parent:AddNewModifier(self.parent, self:GetAbility(), "modifier_jeanne_luminosite_eternelle_barrier", {duration = self:GetAbility():GetSpecialValueFor("channel_duration")})
	
	self:StartIntervalThink(1.0)
end

function modifier_jeanne_luminosite_eternelle:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveModifierByName("modifier_jeanne_luminosite_eternelle_barrier")
	end
end

function modifier_jeanne_luminosite_eternelle:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	self.counter =  self.counter + 1

	local targets = DOTA_UNIT_TARGET_HERO
	
	caster:EmitSound("jeanne_heal_beep")
	
	local healFx = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_luminosite_eternelle_final_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( healFx, 0, caster:GetAbsOrigin())
	
	Timers:CreateTimer( 6.0, function()
		ParticleManager:DestroyParticle( healFx, false )
		ParticleManager:ReleaseParticleIndex( healFx )
	end)

	-- Find Units in Radius
	local allies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self.parent:GetAbsOrigin() ,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
		targets,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	
-- Find Units in Radius
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self.parent:GetAbsOrigin() ,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		targets,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	
	for _,enemy in pairs(enemies) do
		-- Add modifier		
		if self.counter == 2 and self.parent.IsSaintImproved then
			giveUnitDataDrivenModifier(caster, enemy, "disarmed", self:GetAbility():GetSpecialValueFor("first_root_duration"))
		end	
		enemy:AddNewModifier(caster, self:GetAbility(), "modifier_jeanne_luminosite_eternelle_slow", { Duration = 1 })
	end
	
	if allies == nil then
	end
	
	for _,ally in pairs(allies) do
		-- Add modifier
		if self.counter == 1 and self.parent.IsSaintImproved then
			if ally ~= self.parent then
				ally:AddNewModifier(caster, self:GetAbility(), "modifier_jeanne_mrex_allies", {Duration = 5})
			end
		end
		if self.counter == 3 and self.parent.IsSaintImproved then
			if ally ~= self.parent then
				ally:AddNewModifier(caster, self:GetAbility(), "modifier_jeanne_regen_allies", {Duration = 2})
			end
		end
		if self.counter == 4 and self.parent.IsSaintImproved then
			if ally ~= self.parent then
				ally:AddNewModifier(caster, self:GetAbility(), "modifier_jeanne_mana_regen_allies", {Duration = 2})
			end
		end
		ally:Heal(self.hp_heal, caster)
	end
end

function modifier_jeanne_luminosite_eternelle:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_jeanne_luminosite_eternelle:IsDebuff()
	return false
end

function modifier_jeanne_luminosite_eternelle:IsPermanent()
	return false
end

function modifier_jeanne_luminosite_eternelle:RemoveOnDeath()
	return true
end

function modifier_jeanne_luminosite_eternelle:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_jeanne_luminosite_eternelle:PlayEffects()

	local caster = self:GetCaster()

	local particle_cast = "particles/custom/jeanne/jeanne_luminosite_eternelle.vpcf"
	
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end



modifier_jeanne_luminosite_eternelle_barrier = class({})

function modifier_jeanne_luminosite_eternelle_barrier:IsHidden() return false end
function modifier_jeanne_luminosite_eternelle_barrier:IsDebuff() return false end

function modifier_jeanne_luminosite_eternelle_barrier:OnCreated()

end

function modifier_jeanne_luminosite_eternelle_barrier:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_jeanne_luminosite_eternelle_barrier:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end
function modifier_jeanne_luminosite_eternelle_barrier:GetModifierIncomingSpellDamageConstant(keys)
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
--[[function modifier_jeanne_luminosite_eternelle_barrier:GetModifierMagical_ConstantBlock(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.damage
            if block_check > 0 then
                self:SetStackCount(block_check)
            else
                self:Destroy()
            end

            return block_now
        end
	end
end]]

function modifier_jeanne_luminosite_eternelle_barrier:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield_amount")
    
    if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/custom/jeanne/jeanne_luminosite_eternelle_barrier.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl( self.iShieldPFX, 0, self.hCaster:GetAbsOrigin() )

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	end

	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_jeanne_luminosite_eternelle_barrier:OnRefresh(hTable)
	self:OnCreated(hTable)
end

modifier_jeanne_mrex_allies = class({})

function modifier_jeanne_mrex_allies:IsHidden() return false end
function modifier_jeanne_mrex_allies:IsDebuff() return false end

function modifier_jeanne_mrex_allies:OnCreated()

end

function modifier_jeanne_mrex_allies:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT
					}
	return hFunc
end
--[[function modifier_jeanne_mrex:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end]]
function modifier_jeanne_mrex_allies:GetModifierIncomingSpellDamageConstant(keys)
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

function modifier_jeanne_mrex_allies:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	if not self.fBarrierBlock then
		self.fBarrierBlock = 0
	end

	self.fBarrierBlock = math.min(self.fBarrierBlock + self.hAbility:GetSpecialValueFor("barrier_per_cast"), self.hAbility:GetSpecialValueFor("barrier_cap"))
    
    if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/jeanne/jeanne_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl(self.iShieldPFX, 0, self.hParent:GetAbsOrigin())

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	else
		local flashFX = ParticleManager:CreateParticle("particles/jeanne/jeanne_shield_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
		ParticleManager:SetParticleControl(flashFX, 0, self.hParent:GetAbsOrigin())

		ParticleManager:ReleaseParticleIndex(flashFX)
	end

	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_jeanne_mrex_allies:OnRefresh(hTable)
	self:OnCreated(hTable)
end

modifier_jeanne_regen_allies = class({})

function modifier_jeanne_regen_allies:IsHidden() return false end
function modifier_jeanne_regen_allies:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_jeanne_regen_allies:RemoveOnDeath() return true end
function modifier_jeanne_regen_allies:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_jeanne_regen_allies:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
				}
	return func
end
function modifier_jeanne_regen_allies:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("regen")
end

modifier_jeanne_mana_regen_allies = class({})

function modifier_jeanne_mana_regen_allies:IsHidden() return false end
function modifier_jeanne_mana_regen_allies:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_jeanne_mana_regen_allies:RemoveOnDeath() return true end
function modifier_jeanne_mana_regen_allies:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_jeanne_mana_regen_allies:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
				}
	return func
end
function modifier_jeanne_mana_regen_allies:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("regen")
end
hijikata_duel = class({})

LinkLuaModifier("modifier_hijikata_duel", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_duel_aura", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_duel_leash", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_shinsengumi_aura", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_shinsengumi_flag_buff", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_disengage", "abilities/hijikata/hijikata_duel", LUA_MODIFIER_MOTION_NONE)
function hijikata_duel:OnSpellStart()
	self.caster = self:GetCaster()
	local ability = self
	if self.AuraDummy ~= nil and not self.AuraDummy:IsNull() then 
		self:RemoveDuel()
    end
    self.target = self:GetCursorTarget()
    self.caster:EmitSound("hijikata_flag")
    local targetpos = (-self.target:GetAbsOrigin() + self.caster:GetAbsOrigin())/2 + self.target:GetAbsOrigin()
    local duration = self:GetSpecialValueFor("duration")
    local modifier = self.caster:FindModifierByName("modifier_hijikata_laws")
    local radius = self:GetSpecialValueFor("radius")
    if modifier.duel_restriction == false then
        modifier:IncrementStackCount()
		modifier:TakeDamage()
        modifier.duel_restriction = true
    end

    self.target:AddNewModifier(self.caster, self, "modifier_hijikata_duel_leash", { duration = duration, radius = radius, center_x = targetpos.x, center_y = targetpos.y})
    self.caster:AddNewModifier(self.caster, self, "modifier_hijikata_duel_leash", { duration = duration, radius = radius, center_x = targetpos.x, center_y = targetpos.y})
    self.caster:AddNewModifier(self.caster, self, "modifier_hijikata_duel", { duration = duration,auraRadius = radius})


    --EmitSoundOnLocationWithCaster(targetpos, "hijikata_prepare_for_battle", self.caster)
	self.caster:EmitSound("hijikata_prepare_for_battle")
	AddFOWViewer(2, targetpos, radius, duration, false)
	AddFOWViewer(3, targetpos, radius, duration, false)
    self.AuraDummy = CreateUnitByName("sight_dummy_unit", targetpos, false, nil, nil, self.caster:GetTeamNumber())
	self.AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.AuraDummy:SetDayTimeVisionRange(radius)
	self.AuraDummy:SetNightTimeVisionRange(radius)
	self.AuraDummy:AddNewModifier(self.caster, self, "modifier_item_ward_true_sight", {true_sight_range = radius, duration = duration})
    self.castfx = ParticleManager:CreateParticle("particles/hijikata/hijikata_duel.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.AuraDummy )
    ParticleManager:SetParticleControl(self.castfx, 19, Vector(radius,duration,radius))
    --ParticleManager:ReleaseParticleIndex(self.castfx)
	self.AuraDummy:AddNewModifier(self.caster, self, "modifier_hijikata_duel_aura", { duration = duration, --aura for aura modifiers
																				 auraRadius = radius})
	if self.caster.IsShinsengumiAcquired then
		self.AuraDummy:AddNewModifier(self.caster, self, "modifier_hijikata_shinsengumi_aura", { duration = duration, --aura for aura modifiers
																								auraRadius = radius})
	end
    local duelself = ParticleManager:CreateParticle("particles/hijikata/hijikata_duel_text.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.caster )
    ParticleManager:SetParticleControl(duelself, 2, Vector(3,0,0))
    ParticleManager:SetParticleControl(duelself, 3, targetpos + Vector(0,0, radius/2))

    ParticleManager:ReleaseParticleIndex(duelself)

end

function hijikata_duel:RemoveDuel(winner)
	self.caster:StopSound("hijikata_prepare_for_battle")
	if self.caster:HasModifier("modifier_hijikata_duel") then
		self.caster:RemoveModifierByName("modifier_hijikata_duel")
	end
	if self.caster:HasModifier("modifier_hijikata_duel_leash") then
		self.caster:RemoveModifierByName("modifier_hijikata_duel_leash")
	end
	if self.target:HasModifier("modifier_hijikata_duel_leash") then
		self.target:RemoveModifierByName("modifier_hijikata_duel_leash")
	end
	if self.castfx then 
		ParticleManager:DestroyParticle(self.castfx, false)
		ParticleManager:ReleaseParticleIndex(self.castfx)
	end
	self:DeclareWinner(winner)
	if self.AuraDummy ~= nil and not self.AuraDummy:IsNull() then 
		self.AuraDummy:RemoveModifierByName("modifier_hijikata_duel_aura")

		local pepe = self.AuraDummy
		if pepe then
			pepe:RemoveSelf()
		end
	end
end

function hijikata_duel:DeclareWinner(winner)
	--print(winner)
	if winner == nil then return end
	winner:EmitSound("nobu_innovation_cast")
	if self.caster.IsShinsengumiAcquired then
		if winner ~= nil and winner:IsAlive() then
			--print("add disengage")
			winner:AddNewModifier(self.caster, self, "modifier_hijikata_disengage", { duration = self:GetSpecialValueFor("regen_duration")})
		end
	end
end

modifier_hijikata_duel_aura = class({})

function modifier_hijikata_duel_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY 
end

function modifier_hijikata_duel_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_hijikata_duel_aura:OnCreated(args)
    self.radius = args.auraRadius
end


function modifier_hijikata_duel_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_hijikata_duel_aura:GetAuraRadius()
	return  self.radius
end

function modifier_hijikata_duel_aura:GetModifierAura()
	return "modifier_hijikata_duel"
end

function modifier_hijikata_duel_aura:IsHidden()
	return true
end

function modifier_hijikata_duel_aura:RemoveOnDeath()
	return true
end

function modifier_hijikata_duel_aura:IsDebuff()
	return false 
end

function modifier_hijikata_duel_aura:IsAura()
	return true 
end

function modifier_hijikata_duel_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_hijikata_shinsengumi_aura = class({})

function modifier_hijikata_shinsengumi_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_hijikata_shinsengumi_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_hijikata_shinsengumi_aura:OnCreated(args)
    self.radius = args.auraRadius
end


function modifier_hijikata_shinsengumi_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_hijikata_shinsengumi_aura:GetAuraRadius()
	return  self.radius
end

function modifier_hijikata_shinsengumi_aura:GetModifierAura()
	return "modifier_hijikata_shinsengumi_flag_buff"
end

function modifier_hijikata_shinsengumi_aura:IsHidden()
	return true
end

function modifier_hijikata_shinsengumi_aura:RemoveOnDeath()
	return true
end

function modifier_hijikata_shinsengumi_aura:IsDebuff()
	return false 
end

function modifier_hijikata_shinsengumi_aura:IsAura()
	return true 
end

function modifier_hijikata_shinsengumi_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

 
modifier_hijikata_shinsengumi_flag_buff = class({})

function modifier_hijikata_shinsengumi_flag_buff:IsHidden()
    return false 
end

function modifier_hijikata_shinsengumi_flag_buff:OnCreated()
    self.armor = self:GetAbility():GetSpecialValueFor("armor")
	self.mr = self:GetAbility():GetSpecialValueFor("mr")
	self.ms = self:GetAbility():GetSpecialValueFor("ms")
    self.parent = self:GetParent()
end

function modifier_hijikata_shinsengumi_flag_buff:RemoveOnDeath()
    return true
end

function modifier_hijikata_shinsengumi_flag_buff:IsDebuff()
    return false 
end

function modifier_hijikata_shinsengumi_flag_buff:IsHidden()
    return false 
end

function modifier_hijikata_shinsengumi_flag_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_shinsengumi_flag_buff:DeclareFunctions()
	return {	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
				MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_hijikata_shinsengumi_flag_buff:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_hijikata_shinsengumi_flag_buff:GetModifierMagicalResistanceBonus()
	return self.mr
end
function modifier_hijikata_shinsengumi_flag_buff:GetModifierMoveSpeedBonus_Percentage(keys)
    return self.ms
end



modifier_hijikata_disengage = class({})

function modifier_hijikata_disengage:IsHidden()
    return false 
end

function modifier_hijikata_disengage:OnCreated()
    self.hp = self:GetAbility():GetSpecialValueFor("health_regen")
	self.mp = self:GetAbility():GetSpecialValueFor("mana_regen")
    self.parent = self:GetParent()
end

function modifier_hijikata_disengage:RemoveOnDeath()
    return true
end

function modifier_hijikata_disengage:IsDebuff()
    return false 
end

function modifier_hijikata_disengage:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_disengage:DeclareFunctions()
	return {	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT ,
				MODIFIER_PROPERTY_MANA_REGEN_CONSTANT  }
end

function modifier_hijikata_disengage:GetModifierConstantHealthRegen()
	return self.hp
end

function modifier_hijikata_disengage:GetModifierConstantManaRegen()
	return self.mp
end
function modifier_hijikata_disengage:GetEffectName()
    return "particles/hijikata/hijikata_duel_victory.vpcf"
end

function modifier_hijikata_disengage:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

modifier_hijikata_duel = class({})

function modifier_hijikata_duel:IsHidden()
    return false 
end

function modifier_hijikata_duel:OnCreated()
    self.dmg_res = self:GetAbility():GetSpecialValueFor("dmg_res")
	self.dmg_increase = self:GetAbility():GetSpecialValueFor("dmg_increase")
    self.parent = self:GetParent()
    self.hijikata = self:GetAbility().caster
    self.initialTarget = self:GetAbility().target
end

function modifier_hijikata_duel:RemoveOnDeath()
    return true
end

function modifier_hijikata_duel:IsDebuff()
    return true 
end

function modifier_hijikata_duel:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_duel:OnDestroy()

end

function modifier_hijikata_duel:DeclareFunctions()
   	return {	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE  }
end
function modifier_hijikata_duel:GetModifierIncomingDamage_Percentage(args) 
    local attacker = args.attacker
    local target = args.target
    --  if target:IsNotNull() ~= true then return end
    if  attacker == self.hijikata then 
		if target == self.initialTarget then
			return self.dmg_increase
		else
			return -self.dmg_res 
		end
	end
    if target == self.hijikata then
       if attacker == self.initialTarget then
			return self.dmg_increase
	   else
			return -self.dmg_res 
	   end
    end
    return 
end

modifier_hijikata_duel_leash = class({})


function modifier_hijikata_duel_leash:IsHidden()
	return true
end

function modifier_hijikata_duel_leash:IsDebuff()
	return true
end

function modifier_hijikata_duel_leash:IsStunDebuff()
	return false
end

function modifier_hijikata_duel_leash:IsPurgable()
	if not IsServer() then return end
	return false
end




function modifier_hijikata_duel_leash:OnCreated( kv )
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.duelend = false
	self.purgable = false
	if kv.purgable then self.purgable = kv.purgable==1 end

	-- load values
	self.radius = kv.radius or 300
	if kv.center_x and kv.center_y then
		self.center = Vector( kv.center_x, kv.center_y, 0 )
	else
		self.center = self:GetParent():GetOrigin()
	end

	-- consts
	self.max_speed = 550
	self.min_speed = 0.1
	self.max_min = self.max_speed-self.min_speed
	self.half_width = 50
    self:StartIntervalThink(FrameTime())
end

function modifier_hijikata_duel_leash:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_hijikata_duel_leash:OnRemoved()
end

function modifier_hijikata_duel_leash:OnDestroy()
	if self:GetCaster():IsAlive() ~= true then
		--print("hijikata died")
		 self:GetAbility():RemoveDuel(self:GetAbility().target)
		 self.duelend = true
		 --self:GetAbility():DeclareWinner(self:GetAbility().target)
		 self:Destroy()
	end

	if self:GetAbility().target:IsAlive() ~= true then
		--print("target died")
		self:GetAbility():RemoveDuel(self:GetCaster())
		self.duelend = true
		--self:GetAbility():DeclareWinner(self:GetCaster())
		self:Destroy()
   end
   self:GetAbility():RemoveDuel()
	if not IsServer() then return end
	if self.endCallback then
		self.endCallback()
	end
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_hijikata_duel_leash:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
	}

	return funcs
end

function modifier_hijikata_duel_leash:GetModifierMoveSpeed_Limit( params )
	if not IsServer() then return end

	-- get data
	local parent_vector = self.parent:GetOrigin()-self.center
	local parent_direction = parent_vector:Normalized()
	local actual_distance = parent_vector:Length2D()
	local wall_distance = self.radius-actual_distance



	-- calculate facing angle
	local parent_angle = VectorToAngles(parent_direction).y
	local unit_angle = self:GetParent():GetAnglesAsVector().y
	local wall_angle = math.abs( AngleDiff( parent_angle, unit_angle ) )

	-- calculate movespeed limit
	local limit = 0
	if wall_angle<=90 then
		-- facing outside
		if wall_distance<0 then
			-- at max radius
			limit = self.min_speed
			-- self:RemoveMotions()
		else
			-- about to max radius, interpolate
			limit = (wall_distance/self.half_width)*self.max_min + self.min_speed
		end
	end

	return limit
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_hijikata_duel_leash:CheckState()
	local state = {
		[MODIFIER_STATE_TETHERED] = false,
	}

	return state
end

--------------------------------------------------------------------------------
-- Helper
function modifier_hijikata_duel_leash:SetEndCallback( func )
	self.endCallback = func
end

function modifier_hijikata_duel_leash:OnIntervalThink()	
    local parent = self:GetParent()
   

    if math.abs((parent:GetAbsOrigin() - self.center):Length2D()) > self.radius then
        local diff = parent:GetAbsOrigin() - self.center
        diff = diff:Normalized()

        parent:SetAbsOrigin(self.center + diff * self.radius)
        FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
    end
end

function modifier_hijikata_duel_leash:GetEffectName()
    return "particles/hijikata/hijikata_duel_leash_onhero_effect.vpcf"
end

function modifier_hijikata_duel_leash:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

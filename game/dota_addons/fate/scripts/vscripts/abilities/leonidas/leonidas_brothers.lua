leonidas_brothers = class({})
LinkLuaModifier("modifier_leonidas_brother", "abilities/leonidas/leonidas_brothers", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_leonidas_brother_self", "abilities/leonidas/leonidas_brothers", LUA_MODIFIER_MOTION_NONE)

function leonidas_brothers:GetIntrinsicModifierName()
	return "modifier_leonidas_brother_self"
end
function leonidas_brothers:CheckComboIsReadyIncrement(hUnit, iPreviousStackShouldBe)
    local iPreviousStackShouldBe = iPreviousStackShouldBe or 0

    if IsNotNull(hUnit)
        and hUnit:GetStrength() >= 29.1
        and hUnit:GetAgility() >= 29.1
        and hUnit:GetIntellect() >= 29.1 then
        local iStacksNow = hUnit:GetModifierStackCount("modifier_leonidas_enomotia_combo_indicator", hUnit)
        if iStacksNow == iPreviousStackShouldBe then
            return hUnit:SetModifierStackCount("modifier_leonidas_enomotia_combo_indicator", hUnit, iStacksNow + 1)
        end
    end
end

function leonidas_brothers:OnOwnerDied()
	local hCaster = self:GetCaster()
	if IsNotNull(hCaster.soldier2) and hCaster.soldier2:IsAlive() then
		hCaster.soldier2:Kill(nil, hCaster)
	end
	if IsNotNull(hCaster.soldier1) and hCaster.soldier1:IsAlive() then
		hCaster.soldier1:Kill(nil, hCaster)
	end
end

function leonidas_brothers:OnSpellStart()
	local caster = self:GetCaster()
	local life_duration = self:GetSpecialValueFor("duration")
	local soldier_barrier = caster:GetMaxHealth() *self:GetSpecialValueFor("health_percentage")/100
	local caster_pos = caster:GetAbsOrigin()
	local right_vec = caster:GetRightVector()
	if IsNotNull(caster.soldier1) then
		caster.soldier1:Kill(nil, caster)
		caster.soldier1 = nil
	end
	if IsNotNull(caster.soldier2) then
		caster.soldier2:Kill(nil, caster)
		caster.soldier2 = nil
	end
	self:CheckComboIsReadyIncrement(caster, 0)
	local position1 = caster_pos + right_vec * 125
	local position2 = caster_pos + right_vec * -125
	local soldier1 = CreateUnitByName("leonidas_brother_soldier", position1, true, nil, nil, caster:GetTeamNumber())
	local soldier2 = CreateUnitByName("leonidas_brother_soldier", position2, true, nil, nil, caster:GetTeamNumber())
	soldier1:SetMaxHealth(10)
	soldier1:SetBaseMaxHealth(10)
	soldier1:SetHealth(10)
	soldier1:SetBaseDamageMax(caster:GetBaseDamageMax()/2) 
	soldier1:SetBaseDamageMin(caster:GetBaseDamageMin()/2) 
	soldier1:SetBaseAttackTime( 1 - 0.03 * caster:GetLevel())
	
	soldier1:SetBaseMagicalResistanceValue(self:GetSpecialValueFor("mr")) 
	soldier1:SetPhysicalArmorBaseValue(self:GetSpecialValueFor("armor")) 
	soldier2:SetMaxHealth(10)
	soldier2:SetBaseMaxHealth(10)
	soldier2:SetHealth(10)
	soldier2:SetBaseDamageMax(caster:GetBaseDamageMax()/2) 
	soldier2:SetBaseDamageMin(caster:GetBaseDamageMin()/2) 
	soldier2:SetBaseAttackTime( 1 - 0.03 * caster:GetLevel())

	soldier2:SetBaseMagicalResistanceValue(self:GetSpecialValueFor("mr")) 
	soldier2:SetPhysicalArmorBaseValue(self:GetSpecialValueFor("armor")) 
	soldier1:SetOwner(caster)
	soldier2:SetOwner(caster)
	FindClearSpaceForUnit(soldier1, position1, true)
	FindClearSpaceForUnit(soldier2, position2, true)
	caster.soldier1 = soldier1
	caster.soldier2 = soldier2
	soldier1:AddNewModifier(caster, self, "modifier_kill", { duration = life_duration })
	soldier2:AddNewModifier(caster, self, "modifier_kill", { duration = life_duration })
	soldier1:AddNewModifier(caster, self, "modifier_leonidas_brother", { duration = life_duration,  barrier = soldier_barrier, right = 1})
	soldier2:AddNewModifier(caster, self, "modifier_leonidas_brother", { duration = life_duration, barrier = soldier_barrier, right = -1})
end


modifier_leonidas_brother = class({})

function modifier_leonidas_brother:IsDebuff()
	return true
end
function modifier_leonidas_brother:IsHidden()
	return true
end

function modifier_leonidas_brother:CheckState()
	local state = {
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_NO_UNIT_COLLISION ] = true,
	}
 
	return state
end


function modifier_leonidas_brother:OnCreated(table)
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.fBarrierBlock = table.barrier
	self.maxdistance = 150
    self.state = 0 -- 0 == following leonidas, 1 == standing on the ground
	self.right = table.right
	self.caster_pos = self.caster:GetAbsOrigin()
	self.barrier_give_counter = 0
	self.moveOrderDistance = 20
	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
	self:StartIntervalThink(FrameTime())
end

function modifier_leonidas_brother:OnIntervalThink()
	if self.state == 0 then 
		local new_caster_pos = self.caster:GetAbsOrigin()
		if (new_caster_pos - self.caster_pos):Length2D() > self.moveOrderDistance then 
			self.parent:SetBaseMoveSpeed(self.caster:GetIdealSpeed()) 
			self.caster_pos = new_caster_pos
			self.moveOrderDistance = 20
			self.parent:MoveToPosition(self.caster:GetAbsOrigin() + self.caster:GetRightVector() * self.right * 125)
		end
		local distance = (self.parent:GetAbsOrigin() - (self.caster:GetAbsOrigin() + self.caster:GetRightVector() * self.right * 125)):Length2D()
		if distance > 600 then
			AbilityBlink(self.parent,self.caster:GetAbsOrigin() + self.caster:GetRightVector() * self.right * 125, 2000)
		end
		if distance > self.maxdistance then
			self.parent:SetBaseMoveSpeed(self.caster:GetIdealSpeed() + 150) 
		end
	elseif self.state == 1 then
		if self.barrier_give_counter >= 5 then 
			self:StartIntervalThink(-1)
			return
		end
		local particle = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_brother_shield_give_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(particle, 1, Vector(self.ability:GetSpecialValueFor("radius"),0,0))
		ParticleManager:ReleaseParticleIndex(particle)
		StartAnimation(self.parent, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=0.7}) 
		local Block = self.ability:GetSpecialValueFor("enomotia_shield_block") + ( GetAttributeValue(self.caster, "leonidas_math_attribute",
		"soldiers_bonus_barrier_per_int", -1, 0, false) * self.caster:GetIntellect(false))
		local ALLIES = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _, hEntity in pairs(ALLIES) do

			if IsNotNull(hEntity) then
				--[[
				local modifier = hEntity:FindModifierByName("modifier_leonidas_enomotia_shield")
				if IsNotNull(modifier) then
					modifier:SetStackCount(modifier:GetStackCount() +Block )
					modifier:SetDuration(modifier:GetDuration(), true)
				else
					]]
					hEntity:AddNewModifier(self.caster, self.ability, "modifier_leonidas_enomotia_shield",
					{duration = self.ability:GetSpecialValueFor("enomotia_shield_duration"),
					nDamageBlock = Block })
				--end
			end
		end
		local ENEMIES = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for _, hEntity in pairs(ENEMIES) do
			DoDamage(self.caster, hEntity, Block, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end
		
		self.barrier_give_counter = self.barrier_give_counter + 1
	else
		local ENEMIES = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, 1000,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		if #ENEMIES > 0 then
			self.parent:MoveToTargetToAttack(ENEMIES[1])
		end
	end
end

function modifier_leonidas_brother:OnRefresh(hTable)
	self:OnCreated(hTable)
end
function modifier_leonidas_brother:ShareBarriers()
	self:StartIntervalThink(-1)
	self:StartIntervalThink(0.5)
	self.barrier_give_counter = 0
	StartAnimation(self.parent, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=0.7}) 
	local particle = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_brother_shield_give_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(particle, 1, Vector(self.ability:GetSpecialValueFor("radius"),0,0))
	ParticleManager:ReleaseParticleIndex(particle)
	local Block = self.ability:GetSpecialValueFor("enomotia_shield_block") + ( GetAttributeValue(self.caster, "leonidas_math_attribute",
		"soldiers_bonus_barrier_per_int", -1, 0, false) * self.caster:GetIntellect(false))
	local ALLIES = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("radius"),
	DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, hEntity in pairs(ALLIES) do
		
		if IsNotNull(hEntity) then
			--[[
			local modifier = hEntity:FindModifierByName("modifier_leonidas_enomotia_shield")
			if IsNotNull(modifier) then
				modifier:SetStackCount(modifier:GetStackCount() +Block )
				modifier:SetDuration(modifier:GetDuration(), true)
			else
				]]
				hEntity:AddNewModifier(self.caster, self.ability, "modifier_leonidas_enomotia_shield",
				{duration = self.ability:GetSpecialValueFor("enomotia_shield_duration"),
				 nDamageBlock = Block })
			--end
		end
	end
	local ENEMIES = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("radius"),
	DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for _, hEntity in pairs(ENEMIES) do
		DoDamage(self.caster, hEntity, Block, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end


function modifier_leonidas_brother:DeclareFunctions()
	local hFunc = 	{	
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_leonidas_brother:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.damage--block_now
            	local damage = keys.damage - block_now

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

function modifier_leonidas_brother:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	local caster = self:GetParent()

	if IsNotNull(args.target) then
		if args.target:IsAlive() and not (self.state == 1) then
			DoDamage(caster, args.target, self:GetAbility():GetSpecialValueFor("soldier_attack_damage"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				EmitSoundOn("Anime_Hero_Leonidas.Attack", self:GetParent())
		end
	end


end



modifier_leonidas_brother_self = class({})

function modifier_leonidas_brother_self:IsDebuff()
	return false
end
function modifier_leonidas_brother_self:IsHidden()
	return true
end

function modifier_leonidas_brother_self:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	local caster = self:GetParent()
	if IsNotNull(caster.soldier1) then
		if IsNotNull(args.target) then
			if args.target:IsAlive() and caster.soldier1:IsAlive() and not (caster.soldier1:FindModifierByName("modifier_leonidas_brother").state == 1) then
				caster.soldier1:MoveToTargetToAttack(args.target)
				caster.soldier1:FindModifierByName("modifier_leonidas_brother").moveOrderDistance = 450
				
			end
		end
	
	end
	if IsNotNull(caster.soldier2) then
		if IsNotNull(args.target) then
			if args.target:IsAlive() and caster.soldier2:IsAlive() and not (caster.soldier2:FindModifierByName("modifier_leonidas_brother").state == 1) then
				caster.soldier2:MoveToTargetToAttack(args.target)
				caster.soldier2:FindModifierByName("modifier_leonidas_brother").moveOrderDistance = 450
			end
		end
	
	end

end
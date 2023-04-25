LinkLuaModifier("modifier_altera_rift_anim", "abilities/altera/altera_rift", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift", "abilities/altera/altera_rift", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift_displace", "abilities/altera/altera_rift", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_altera_rift_str_buff", "abilities/altera/altera_rift", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift_agi_buff", "abilities/altera/altera_rift", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift_int_buff", "abilities/altera/altera_rift", LUA_MODIFIER_MOTION_NONE)

altera_rift = class({})

function altera_rift:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("altera_mars_effect")
	return true
end

function altera_rift:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("altera_mars_effect")
end

function altera_rift:GetAOERadius()
	return self:GetSpecialValueFor("damage_radius")
end

function altera_rift:OnSpellStart()
	--delay 0.9
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	caster:AddNewModifier(caster, self, "modifier_altera_rift_anim", {duration = 0.6})

	Timers:CreateTimer(0.6, function()
		if self.AuraDummy ~= nil and not self.AuraDummy:IsNull() then 
			self.AuraDummy:RemoveModifierByName("modifier_altera_rift")
			local pepe = self.AuraDummy
			Timers:CreateTimer(1, function()
				if pepe then
					pepe:RemoveSelf()
				end
			end)
		end

		self.AuraDummy = CreateUnitByName("sight_dummy_unit", target, false, nil, nil, caster:GetTeamNumber())
		self.AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		self.AuraDummy:SetDayTimeVisionRange(0)
		self.AuraDummy:SetNightTimeVisionRange(0)

		self.AuraDummy:AddNewModifier(caster, self, "modifier_altera_rift", { Duration = self:GetSpecialValueFor("duration"), --aura for aura modifiers
																				 AuraRadius = self:GetSpecialValueFor("radius")})

		local pepe2 = self.AuraDummy
		self.AuraDummy:AddNewModifier(caster, self, "modifier_kill", { Duration = self:GetSpecialValueFor("duration") + 1 })
	end)
end

modifier_altera_rift_anim = class({})

function modifier_altera_rift_anim:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_altera_rift_anim:IsHidden() return true end

modifier_altera_rift = class({})

if IsServer() then
	function modifier_altera_rift:OnCreated(args)
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.origin = self.parent:GetAbsOrigin()
		self.ability = self:GetAbility()
		self.aura_radius = args.AuraRadius
		self.caster_team = self.caster:GetTeamNumber()
		self.speed = 100

		self.form = "neutral"
        self.particlename = "particles/altera/altera_rift_test.vpcf"
        self.particlename2 = "particles/altera/altera_rift.vpcf"

        if self.caster:HasModifier("modifier_altera_form_str") then
        	self.form = "str"
        	self.particlename = "particles/altera/altera_rift_red.vpcf"
        end
        if self.caster:HasModifier("modifier_altera_form_agi") then
        	self.form = "agi"
        	self.particlename = "particles/altera/altera_rift_green.vpcf"
        end
        if self.caster:HasModifier("modifier_altera_form_int") then
        	self.form = "int"
        	self.particlename = "particles/altera/altera_rift_blue.vpcf"
        end

		self.particle = ParticleManager:CreateParticle(self.particlename, PATTACH_CUSTOMORIGIN, self.caster)
		ParticleManager:SetParticleControl(self.particle, 0, self.origin)
		ParticleManager:SetParticleControl(self.particle, 1, Vector(self.aura_radius, self.aura_radius, self.aura_radius))

		self.particle2 = ParticleManager:CreateParticle(self.particlename2, PATTACH_WORLDORIGIN, self.caster)
		ParticleManager:SetParticleControl(self.particle2, 0, self.origin)

		self.counter = 0
		self:StartIntervalThink(0.1)

		EmitSoundOnLocationWithCaster(self.origin, "chrono_ti11", self.caster )
		EmitSoundOnLocationWithCaster(self.origin, "Hero_Leshrac.Split_Earth", self.caster)

		self:Explode(1)
	end

	function modifier_altera_rift:Explode(mult)
		local particlename = "particles/tamamo/tamamo_mantra_void_warp.vpcf"

		local shouldstun = false
		local radius = self.ability:GetSpecialValueFor("damage_radius")

		local damage = self.ability:GetSpecialValueFor("damage")
		if self.caster.RefractionAcquired then
			damage = damage + self.ability:GetSpecialValueFor("atr_damage_mult")*(self.caster:GetStrength() + self.caster:GetAgility() + self.caster:GetIntellect())
		end
		damage = damage*mult
		if self.form == "str" then
		   	particlename = "particles/altera/altera_rift_red_warp.vpcf"
		   	shouldstun = true
		end
		if self.form == "agi" then
		   	particlename = "particles/altera/altera_rift_green_warp.vpcf"
		end
		if self.form == "int" then
		   	particlename = "particles/altera/altera_rift_blue_warp.vpcf"
		end

		local warpFx = ParticleManager:CreateParticle(particlename, PATTACH_ABSORIGIN, self.parent) 
	    ParticleManager:SetParticleControl(warpFx, 0, self.origin)
	    ParticleManager:SetParticleControl(warpFx, 1, Vector(radius/10, 0, 0))

	    Timers:CreateTimer(1, function()
	    	ParticleManager:DestroyParticle(warpFx, false)
	    	ParticleManager:ReleaseParticleIndex(warpFx)
	    end)

		local enemies = FindUnitsInRadius(self.caster:GetTeam(), self.origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	    for _, enemy in pairs(enemies) do
	        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
				DoDamage(self.caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

				local knockback = { should_stun = shouldstun,
		            knockback_duration = 0.5,
		            duration = 0.5,
		            knockback_distance = -300,
		            knockback_height = 50,
		            center_x = self.origin.x,
		            center_y = self.origin.y,
		            center_z = self.origin.z }

		        enemy:RemoveModifierByName("modifier_knockback")

		        enemy:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)
	        end
	    end
	end

	function modifier_altera_rift:OnIntervalThink()
		local team = DOTA_UNIT_TARGET_TEAM_ENEMY

		if self.form == "int" then
			team = DOTA_UNIT_TARGET_TEAM_BOTH
		end

		local dmgproc = false
		self.counter = self.counter + 0.1
		if self.counter >= 0.5 then
			self.counter = 0
			dmgproc = true
		end

		local damage = self.ability:GetSpecialValueFor("damage_per_second")*0.5

		local enemies = FindUnitsInRadius(self.caster:GetTeam(), self.origin, nil, self.aura_radius, team, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

	    for _, enemy in pairs(enemies) do
	        if enemy:GetTeamNumber() == self.caster_team then
                --enemy:Heal(self.damage, self.ability)
                enemy:AddNewModifier(self.caster, self.ability, "modifier_altera_rift_int_buff", {duration = self.ability:GetSpecialValueFor("lingering_duration")})
            else
            	if dmgproc then
                	DoDamage(self.caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
                end
				if self.form == "str" then
					--enemy:AddNewModifier(self.caster, self.ability, "modifier_altera_rift_displace", {duration = FrameTime()*2})
				end
            end
	    end
	    if (self.caster:GetAbsOrigin() - self.origin):Length2D() < self.aura_radius then
			if self.form == "str" then
				self.caster:AddNewModifier(self.caster, self.ability, "modifier_altera_rift_str_buff", {duration = self.ability:GetSpecialValueFor("lingering_duration")})
			end
			if self.form == "agi" then
				self.caster:AddNewModifier(self.caster, self.ability, "modifier_altera_rift_agi_buff", {duration = self.ability:GetSpecialValueFor("lingering_duration")})
			end
		end
	end

	function modifier_altera_rift:OnDestroy()
		--[[local sound_stop = "Hero_Enigma.Black_Hole.Stop"
		EmitSoundOn( sound_stop, self:GetParent() )]]
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
		ParticleManager:DestroyParticle(self.particle2, false)
		ParticleManager:ReleaseParticleIndex(self.particle2)
		if self.caster.RefractionAcquired then
			self:Explode(1/2)
		end
	end
end


modifier_altera_rift_displace = class({})
function modifier_altera_rift_displace:IsHidden() return true end
function modifier_altera_rift_displace:IsDebuff() return false end
function modifier_altera_rift_displace:IsPurgable() return false end
function modifier_altera_rift_displace:IsPurgeException() return false end
function modifier_altera_rift_displace:RemoveOnDeath() return true end
function modifier_altera_rift_displace:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_altera_rift_displace:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function modifier_altera_rift_displace:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_altera_rift_displace:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("str_slow")
end
function modifier_altera_rift_displace:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.dummy = self.ability.AuraDummy
    self.origin = self.dummy:GetAbsOrigin()
    --EmitSoundOn("nero_dash", self.parent)

    if IsServer() then
        self.speed          = 0

        self.direction      = (self.origin - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        --self:StartIntervalThink(FrameTime())
        
        --[[if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end]]
    end
end
function modifier_altera_rift_displace:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_altera_rift_displace:OnRefresh(table)
    self.dummy = self.ability.AuraDummy
    if self.dummy then
    	self.origin = self.dummy:GetAbsOrigin()
    end
end
function modifier_altera_rift_displace:UpdateHorizontalMotion(me, dt)
    if IsServer() then
    	self.distance = (self.parent:GetAbsOrigin() - self.origin):Length2D()
        if self.distance >= 50 then
        	self.direction      = (self.origin - self.parent:GetAbsOrigin()):Normalized()
        	self.direction.z    = 0
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt

            --[[if distance_will < 0 then
                next_pos = self.point
            end]]

            --[[print(self.parent:GetAbsOrigin())
            print(next_pos)]]

            self.parent:SetOrigin(next_pos)
            --FindClearSpaceForUnit(self.parent, next_pos, true)
            --self.parent:FaceTowards(self.point)

            --self:PlayEffects()
        end
    end
end
function modifier_altera_rift_displace:PlayEffects()
	local enemies = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.AttackedTargets[enemy:entindex()] then
            self.AttackedTargets[enemy:entindex()] = true

            self.damage = self.ability:GetSpecialValueFor("damage")

            if not enemy:IsMagicImmune() then
				DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			end
        end
    end
end
function modifier_altera_rift_displace:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_altera_rift_displace:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
    end
end

----

modifier_altera_rift_str_buff = class({})

function modifier_altera_rift_str_buff:IsHidden() return false end
function modifier_altera_rift_str_buff:IsDebuff() return false end

function modifier_altera_rift_str_buff:DeclareFunctions()
	return {
		--MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		--MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
end

function modifier_altera_rift_str_buff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("str_magres_bonus")
end

function modifier_altera_rift_str_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("str_armor_bonus")
end

function modifier_altera_rift_str_buff:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("str_regen_bonus")
end

--[[function modifier_altera_rift_str_buff:OnCreated()
end]]

modifier_altera_rift_agi_buff = class({})

function modifier_altera_rift_agi_buff:IsHidden() return false end
function modifier_altera_rift_agi_buff:IsDebuff() return false end

function modifier_altera_rift_agi_buff:CheckState()
    local state =   {  
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    }
    return state
end


function modifier_altera_rift_agi_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE}
end

function modifier_altera_rift_agi_buff:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_altera_rift_agi_buff:GetModifierMoveSpeed_Absolute()
	return self:GetAbility():GetSpecialValueFor("agi_ms")
end

function modifier_altera_rift_agi_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("agi_as_bonus")
end

function modifier_altera_rift_agi_buff:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return nil end
	self.target = args.target
	DoDamage(self:GetParent(), self.target, self:GetAbility():GetSpecialValueFor("agi_onhit_damage"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
end

--

modifier_altera_rift_int_buff = class({})

function modifier_altera_rift_int_buff:CheckState()
    local state =   {  
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    }
    return state
end

function modifier_altera_rift_int_buff:IsHidden() return false end
function modifier_altera_rift_int_buff:IsDebuff() return false end

function modifier_altera_rift_int_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
end

function modifier_altera_rift_int_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("int_ms_bonus")
end

function modifier_altera_rift_int_buff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("int_magres_bonus")
end
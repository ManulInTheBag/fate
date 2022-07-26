LinkLuaModifier("modifier_jeanne_jump_buff", "abilities/jeanne_alter/jeanne_jump", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_jump_cooldown", "abilities/jeanne_alter/jeanne_jump", LUA_MODIFIER_MOTION_NONE)

jeanne_jump = class({})

--[[function jeanne_jump:OnAbilityPhaseStart()
	local caster = self:GetCaster()
    caster:EmitSound("Ruler.Luminosite")
    --caster:EmitSound("Hero_Chen.HandOfGodHealHero")
    return true
end

function jeanne_jump:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    caster:StopSound("Ruler.Luminosite")
    --caster:StopSound("Hero_Chen.HandOfGodHealHero")
end]]

function jeanne_jump:OnSpellStart()
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("delay")
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local damage_per_second = self:GetSpecialValueFor("damage_per_second")
	local duration = self:GetSpecialValueFor("duration")
	local counter = 0
	local origin = caster:GetAbsOrigin()

	--print(self:GetCursorTargetingNothing())

	giveUnitDataDrivenModifier(caster, caster, "jump_pause_nosilence", delay)
	
	Timers:CreateTimer(delay, function()
		caster:EmitSound("jeanne_jump_sfx")
		local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                            origin, 
                                            nil, 
                                            radius, 
                                            self:GetAbilityTargetTeam(), 
                                            self:GetAbilityTargetType(), 
                                            self:GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)


		for _,enemy in ipairs(enemies) do
	           DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        end

        AddFOWViewer(2, origin, 10, duration, false)
    	AddFOWViewer(3, origin, 10, duration, false)

        local AuraDummy = CreateUnitByName("sight_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		AuraDummy:SetDayTimeVisionRange(radius)
		AuraDummy:SetNightTimeVisionRange(radius)

		local particle_cast1 = "particles/jeanne_alter/nightstalker_crippling_fear_aura.vpcf"

		local effect_cast1 = ParticleManager:CreateParticle( particle_cast1, PATTACH_ABSORIGIN_FOLLOW, AuraDummy )
		ParticleManager:SetParticleControl( effect_cast1, 2, Vector( radius, 0, 0 ) )

		local particle_cast = "particles/jeanne_alter/doom_scorched_earth.vpcf"

		-- Create Particle
		local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, AuraDummy )
		ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )

        Timers:CreateTimer(0.01, function()

        	if ((caster:GetAbsOrigin() - origin):Length2D() > radius) and not caster.CursedGroundAcquired then
        		ParticleManager:DestroyParticle(effect_cast, false)
        		ParticleManager:DestroyParticle(effect_cast1, false)
        		Timers:CreateTimer(0.3, function()
        			AuraDummy:ForceKill(false)
            		AuraDummy:AddEffects(EF_NODRAW)
            	end)
        		return
        	end

        	counter = counter + 0.5

        	if counter > duration then
        		ParticleManager:DestroyParticle(effect_cast, false)
        		ParticleManager:DestroyParticle(effect_cast1, false)
        		Timers:CreateTimer(0.3, function()
        			AuraDummy:ForceKill(false)
            		AuraDummy:AddEffects(EF_NODRAW)
            	end)
        		return
        	end

        	local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                            origin, 
                                            nil, 
                                            radius, 
                                            self:GetAbilityTargetTeam(), 
                                            self:GetAbilityTargetType(), 
                                            self:GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)

        	for _,enemy in ipairs(enemies2) do
	           	DoDamage(caster, enemy, damage_per_second*0.5, DAMAGE_TYPE_MAGICAL, 0, self, false)
        	end

        	--[[if caster.DragonWitchAcquired then
	        	local allies = FindUnitsInRadius(caster:GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

	        	for _,ally in ipairs(allies) do
		           	ally:Heal(self:GetSpecialValueFor("heal_per_second")*0.25, caster)
	        	end
	        end]]

	        if ((caster:GetAbsOrigin() - origin):Length2D() <= radius) then
	        	--caster:Heal(self:GetSpecialValueFor("heal_per_second")*0.5, caster)

	        	caster:AddNewModifier(caster, self, "modifier_jeanne_jump_buff", {duration = 0.6, origin_x = origin.x, origin_y = origin.y, origin_z = origin.z})
	        end
        	return 0.5
        end)
    end)
end

modifier_jeanne_jump_buff = class({})

function modifier_jeanne_jump_buff:DeclareFunctions()
	return { --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED,
			 --MODIFIER_EVENT_ON_TAKEDAMAGE
              }
end

function modifier_jeanne_jump_buff:OnTakeDamage(args)
	if IsServer() then
       	if args.unit ~= self:GetParent() then return end
       	--print(args.damage)
       	if args.damage < self:GetAbility():GetSpecialValueFor("damage_threshold") then return end

       	self:Explode()
    end
end

function modifier_jeanne_jump_buff:OnCreated(args)
	if IsServer() then
        self.attack_sequence = false
		self.origin = Vector(args.origin_x, args.origin_y, args.origin_z)
		--[[self.attack_speed = self:GetAbility():GetSpecialValueFor("base_as")
		CustomNetTables:SetTableValue("sync","mordred_mana_burst_as", { as_bonus = self.attack_speed })]]
	end
end

--[[function modifier_jeanne_jump_buff:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self:GetAbility():GetSpecialValueFor("base_as")
	else
		local as_bonus = CustomNetTables:GetTableValue("sync","mordred_mana_burst_as").as_bonus
        return as_bonus
    end
end]]

function modifier_jeanne_jump_buff:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
    --[[if self.attack_sequence == false then
        self.attack_sequence = true
        return
    end
    self.attack_sequence = false]]
	local caster_position = args.attacker:GetAbsOrigin()
	self.damage = self:GetAbility():GetSpecialValueFor("base_damage")

	--EmitSoundOn("mordred_lightning", args.target)

	--[[local lightning_Fx = ParticleManager:CreateParticle("particles/custom/mordred/zuus_arc_lightning.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( lightning_Fx, 0, args.attacker:GetAbsOrigin())
    ParticleManager:SetParticleControl( lightning_Fx, 1, args.target:GetAbsOrigin())]]

	DoDamage(args.attacker, args.target, self.damage , DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)

	self:Explode()

	--[[local zuus_static_field = ParticleManager:CreateParticle("particles/custom/mordred/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, args.attacker)
	ParticleManager:SetParticleControl(zuus_static_field, 0, Vector(caster_position.x, caster_position.y, caster_position.z))		
	ParticleManager:SetParticleControl(zuus_static_field, 1, Vector(caster_position.x, caster_position.y, caster_position.z) * 100)]]
end

function modifier_jeanne_jump_buff:Explode()
	local caster = self:GetParent()
    if caster:HasModifier("modifier_jeanne_jump_cooldown") then return end
    caster:AddNewModifier(caster, self:GetAbility(), "modifier_jeanne_jump_cooldown", {duration = self:GetAbility():GetSpecialValueFor("proc_cd")})
	local enemies2 = FindUnitsInRadius(  self:GetParent():GetTeamNumber(),
                                            self.origin, 
                                            nil, 
                                            self:GetAbility():GetSpecialValueFor("radius"),
                                            self:GetAbility():GetAbilityTargetTeam(), 
                                            self:GetAbility():GetAbilityTargetType(), 
                                            self:GetAbility():GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)
	caster:EmitSound("Gawain_Sun_Explode")

    local explosionFx = ParticleManager:CreateParticle("particles/jeanne_alter/jeanne_jump_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(explosionFx, 0, self.origin)

    for _,enemy in ipairs(enemies2) do
	  	DoDamage(self:GetParent(), enemy, self:GetAbility():GetSpecialValueFor("damage_per_second")/2, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    end

    if caster.CursedGroundAcquired then
    	local allies = FindUnitsInRadius(caster:GetTeam(), self.origin, nil, self:GetAbility():GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

	    for _,ally in ipairs(allies) do
		   	ally:Heal(self:GetAbility():GetSpecialValueFor("heal_per_second")*0.5, caster)
	    end
	    caster:Heal(self:GetAbility():GetSpecialValueFor("heal_per_second")*0.5, caster)
	end
end

modifier_jeanne_jump_cooldown = class({})
function modifier_jeanne_jump_cooldown:IsHidden() return true end
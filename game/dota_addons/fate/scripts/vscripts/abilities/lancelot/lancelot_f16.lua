LinkLuaModifier("modifier_f16_barrage", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_cd", "abilities/lancelot/modifiers/modifier_f16_cd", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_forward_cmd_disable", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_forward", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_f16_mana", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_owner", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

modifier_f16_owner = class({})

function modifier_f16_owner:OnDestroy()
    self.parent = self:GetParent()
    FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
end

function modifier_f16_owner:IsHidden() return true end

lancelot_f16 = class({})

function lancelot_f16:OnSpellStart()
	local caster = self:GetCaster()
	local f16 = CreateUnitByName("f16_at_vinta", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())

    local kappapride = "at_vinta"..math.random(1,2)
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound=kappapride})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

    local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    caster:AddNewModifier(caster, self, "modifier_f16_cd", {duration = self:GetCooldown(1)})
    caster:FindAbilityByName("lancelot_combo_arondite_overload"):SetLevel(5)
		
	f16:SetControllableByPlayer(caster:GetPlayerID(), true)
	f16:SetOwner(caster)
	FindClearSpaceForUnit(f16, f16:GetAbsOrigin(), true)
    f16:SetForwardVector(caster:GetForwardVector())
			
			-- Level abilities
	f16:FindAbilityByName("lancelot_f16_barrage"):SetLevel(caster:FindAbilityByName("lancelot_smg_barrage"):GetLevel())
	f16:FindAbilityByName("lancelot_f16_nuke"):SetLevel(caster:FindAbilityByName("lancelot_double_edge"):GetLevel())
    f16:FindAbilityByName("lancelot_f16_mana"):SetLevel(caster:FindAbilityByName("lancelot_knight_of_honor"):GetLevel())  
	f16:FindAbilityByName("lancelot_f16_forward"):SetLevel(caster:FindAbilityByName("lancelot_arondite"):GetLevel())

	f16:AddNewModifier(hCaster, self, "modifier_kill", { duration = 30.0 })
end

lancelot_f16_barrage = class({})

function lancelot_f16_barrage:OnSpellStart()
	local caster = self:GetCaster()
	local vDirection = caster:GetForwardVector()

	caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
	local torpedo_projectile1 = {	Ability 		  = self,
									EffectName		  = "particles/heroes/anime_hero_enterprise/enterprise_torpedo.vpcf",
									vSpawnOrigin 	  = caster:GetAbsOrigin(),
									vVelocity 		  = vDirection:Normalized() * 2000 * Vector(1,1,0),
									fDistance 		  = 2000,
									fStartRadius 	  = 300,
									fEndRadius 		  = 300,
									Source 			  = caster,
									iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
									iUnitTargetType   = DOTA_UNIT_TARGET_ALL,
									iUnitTargetFlags  = nil,
									bDeleteOnHit	  = true,
									bProvidesVision	  = false,
									iVisionRadius	  = 300,
									iVisionTeamNumber = caster:GetTeamNumber() }

	ProjectileManager:CreateLinearProjectile(torpedo_projectile1)

	Timers:CreateTimer(0.2, function()
		caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
		local torpedo_projectile2 = {	Ability 		  = self,
									EffectName		  = "particles/heroes/anime_hero_enterprise/enterprise_torpedo.vpcf",
									vSpawnOrigin 	  = caster:GetAbsOrigin(),
									vVelocity 		  = vDirection:Normalized() * 2000 * Vector(1,1,0),
									fDistance 		  = 2000,
									fStartRadius 	  = 300,
									fEndRadius 		  = 300,
									Source 			  = caster,
									iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
									iUnitTargetType   = DOTA_UNIT_TARGET_ALL,
									iUnitTargetFlags  = nil,
									bDeleteOnHit	  = true,
									bProvidesVision	  = false,
									iVisionRadius	  = 300,
									iVisionTeamNumber = caster:GetTeamNumber() }

		ProjectileManager:CreateLinearProjectile(torpedo_projectile2)
	end)
	Timers:CreateTimer(0.4, function()
		caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
		local torpedo_projectile3 = {	Ability 		  = self,
									EffectName		  = "particles/heroes/anime_hero_enterprise/enterprise_torpedo.vpcf",
									vSpawnOrigin 	  = caster:GetAbsOrigin(),
									vVelocity 		  = vDirection:Normalized() * 2000 * Vector(1,1,0),
									fDistance 		  = 2000,
									fStartRadius 	  = 300,
									fEndRadius 		  = 300,
									Source 			  = caster,
									iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
									iUnitTargetType   = DOTA_UNIT_TARGET_ALL,
									iUnitTargetFlags  = nil,
									bDeleteOnHit	  = true,
									bProvidesVision	  = false,
									iVisionRadius	  = 300,
									iVisionTeamNumber = caster:GetTeamNumber() }

		ProjectileManager:CreateLinearProjectile(torpedo_projectile3)
	end)
end

function lancelot_f16_barrage:OnProjectileHit(hTarget, vLocation)
	if not hTarget then
		return nil
	end
	local caster = self:GetCaster()

	--caster:EmitSound("Hero_Gyrocopter.CallDown.Damage")
	EmitSoundOnLocationWithCaster(vLocation, "karna_vasavi_explosion", caster)

	local damage_radius = self:GetSpecialValueFor("damage_radius")
	local damage = self:GetSpecialValueFor("damage")

	local particle_cast = "particles/econ/items/lina/lina_ti7/lina_spell_light_strike_array_ti7.vpcf"

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
						ParticleManager:SetParticleControl( effect_cast, 0, vLocation )
						ParticleManager:SetParticleControl( effect_cast, 1, Vector( damage_radius, 0, 0 ) )
						ParticleManager:ReleaseParticleIndex( effect_cast )

	local targets = FindUnitsInRadius(caster:GetTeam(), vLocation, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        if not v:IsMagicImmune() then v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.5}) end
    end

	return true
end

function lancelot_f16_barrage:GetIntrinsicModifierName()
	return "modifier_f16_barrage"
end

modifier_f16_barrage = class({})

function modifier_f16_barrage:IsHidden() return true end

function modifier_f16_barrage:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0.3)
	end
end

function modifier_f16_barrage:OnIntervalThink()
	self.parent = self:GetParent()
	if not self.parent:IsAlive() then
        self.parent:AddEffects(EF_NODRAW)
        return
    end
	local ability = self.parent:GetOwner():FindAbilityByName("lancelot_smg_barrage")
    local frontward = self.parent:GetForwardVector()
    local range = ability:GetSpecialValueFor("range")
    local start_radius = ability:GetSpecialValueFor("start_radius")
    local end_radius = ability:GetSpecialValueFor("end_radius")
	local smg = 
    {
        Ability = ability,
        --EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
        iMoveSpeed = 2000,
        vSpawnOrigin = self.parent:GetAbsOrigin(),
        fDistance = range,
        fStartRadius = start_radius,
        fEndRadius = end_radius,
        Source = self.parent,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
        bDeleteOnHit = false,
        vVelocity = self.parent:GetForwardVector() * 2000
    }
   
    ProjectileManager:CreateLinearProjectile(smg)

    self.parent:EmitSound("Heckler_Koch_MP5_Unsuppressed")

    local current_point = self.parent:GetAbsOrigin()
    local currentForwardVec = self.parent:GetForwardVector()
    local current_radius = start_radius
    local current_distance = 0
    local forwardVec = ((self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*range) - current_point ):Normalized()
    local end_point = current_point + range * forwardVec
    local difference = end_radius - start_radius
    
    -- Loop creating particles
    while current_distance < range do
        -- Create particle
        local particleIndex = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_smg.vpcf", PATTACH_CUSTOMORIGIN, self.parent )
        ParticleManager:SetParticleControl( particleIndex, 0, current_point )
        ParticleManager:SetParticleControl( particleIndex, 1, Vector(current_radius, 0, 0 ) )
        
        Timers:CreateTimer( 1.0, function()
            ParticleManager:DestroyParticle( particleIndex, false )
            ParticleManager:ReleaseParticleIndex( particleIndex )
            return nil
        end)
        
        -- Update current point
        current_point = current_point + current_radius * forwardVec
        current_distance = current_distance + current_radius
        current_radius = start_radius + current_distance / range * difference
    end
    
    -- Create particle
    local particleIndex = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_smg.vpcf", PATTACH_CUSTOMORIGIN, self.parent )
    ParticleManager:SetParticleControl( particleIndex, 0, end_point )
    ParticleManager:SetParticleControl( particleIndex, 1, Vector( end_radius, 0, 0 ) )
        
    Timers:CreateTimer( 1.0, function()
        ParticleManager:DestroyParticle( particleIndex, true )
        ParticleManager:ReleaseParticleIndex( particleIndex )
        return nil
    end)
end

lancelot_f16_nuke = class({})

function lancelot_f16_nuke:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()

    if (targetPoint - caster:GetAbsOrigin()):Length2D() > 700 then
        targetPoint = (targetPoint - caster:GetAbsOrigin()):Normalized()*700 + caster:GetAbsOrigin()
    end

	EmitGlobalSound("Lancelot.Nuke_Alert") 
    if math.random(1,2) == 1 then
        EmitGlobalSound("Nuclear_Launch_Detected")
    else
        EmitGlobalSound("Tactical_Nuke_Incoming")
    end

    local nukeMarker = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_nuke_calldown_marker_c.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nukeMarker, 0, targetPoint)
    ParticleManager:SetParticleControl( nukeMarker, 1, Vector(300, 300, 300))
    -- Destroy particle after delay
    Timers:CreateTimer( 3.0, function()
        ParticleManager:DestroyParticle( nukeMarker, false )
        ParticleManager:ReleaseParticleIndex( nukeMarker )
    end)

	Timers:CreateTimer(3.0, function()
        EmitGlobalSound("Lancelot.Nuke_Impact")
        local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, 1500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do
            DoDamage(caster, v, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
            if not v:IsMagicImmune() then v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.0}) end
        end
        -- particle
        local impactFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion_second.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(2500, 2500, 1500))
        ParticleManager:SetParticleControl( impactFxIndex, 2, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 3, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 4, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 5, Vector(2500, 2500, 2500))

        local mushroom = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( mushroom, 0, targetPoint)

        -- Destroy particle after delay
        Timers:CreateTimer( 2.0, function()
            ParticleManager:DestroyParticle( impactFxIndex, false )
            ParticleManager:ReleaseParticleIndex( impactFxIndex )
            ParticleManager:DestroyParticle( mushroom, false )
            ParticleManager:ReleaseParticleIndex( mushroom )
        end)
    end)
end

lancelot_f16_forward = class({})

function lancelot_f16_forward:OnSpellStart()
	local caster = self:GetCaster()
	Timers:CreateTimer(1, function()
		LoopOverPlayers(function(player, playerID, playerHero)
	    	--print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	        	-- apply legion horn vsnd on their client
	        	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Saiyan"})
	        	--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	        end
    	end)
    end)
    caster:AddNewModifier(caster, caster, "modifier_forward_cmd_disable", {duration = 2.0})
	--caster:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 2.0})
	Timers:CreateTimer(2, function()
		EmitGlobalSound("Lancelot.Nuke_Impact")
		local targetPoint = caster:GetAbsOrigin()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, self:GetSpecialValueFor("damage_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do
            DoDamage(caster, v, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
            if not v:IsMagicImmune() then v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 3.0}) end
        end
        -- particle
        local impactFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion_second.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(2500, 2500, 1500))
        ParticleManager:SetParticleControl( impactFxIndex, 2, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 3, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 4, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 5, Vector(2500, 2500, 2500))

        local mushroom = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( mushroom, 0, targetPoint)

        caster:ForceKill(true)
        FindClearSpaceForUnit(caster:GetOwner(), caster:GetAbsOrigin(), true)
        caster:GetOwner():FindAbilityByName("lancelot_combo_arondite_overload"):StartCombo()

        -- Destroy particle after delay
        Timers:CreateTimer( 2.0, function()
            ParticleManager:DestroyParticle( impactFxIndex, false )
            ParticleManager:ReleaseParticleIndex( impactFxIndex )
            ParticleManager:DestroyParticle( mushroom, false )
            ParticleManager:ReleaseParticleIndex( mushroom )
        end)
	end)
end

modifier_forward_cmd_disable=class({})
function modifier_forward_cmd_disable:CheckState()
    return { [MODIFIER_STATE_COMMAND_RESTRICTED] = true }
end

function lancelot_f16_forward:GetIntrinsicModifierName()
	return "modifier_f16_forward"
end

modifier_f16_forward = class({})

function modifier_f16_forward:IsHidden() return true end

function modifier_f16_forward:RemoveOnDeath() return true end

function modifier_f16_forward:OnCreated()
	self:StartIntervalThink(FrameTime())
end

function modifier_f16_forward:OnIntervalThink()
	self.parent = self:GetParent()
	if self.parent:IsAlive() then
		local speed = FrameTime()*1000
		self.parent:SetOrigin(Vector(self.parent:GetAbsOrigin().x, self.parent:GetAbsOrigin().y, 600) + self.parent:GetForwardVector()*speed)
		giveUnitDataDrivenModifier(self.parent:GetOwner(), self.parent:GetOwner(), "jump_pause", FrameTime()*2)
        self.parent:GetOwner():AddNewModifier(self.parent, self, "modifier_f16_owner", {duration = FrameTime()*2})
		self.parent:GetOwner():SetOrigin(Vector(self.parent:GetAbsOrigin().x, self.parent:GetAbsOrigin().y, 5000) + self.parent:GetForwardVector()*speed)
		self.parent:GetOwner():SetForwardVector(self.parent:GetForwardVector())
	end
end

lancelot_f16_mana = class({})

function lancelot_f16_mana:GetIntrinsicModifierName()
    return "modifier_f16_mana"
end

modifier_f16_mana = class({})

function modifier_f16_mana:IsHidden() return true end

function modifier_f16_mana:DeclareFunctions()
    return {MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS}
end

function modifier_f16_mana:GetModifierExtraHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_f16_mana:OnCreated()
    if IsServer() then
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_f16_mana:OnIntervalThink()
    local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    for k,v in pairs(targets) do
        self:GetParent():AddNewModifier(v, nil, "modifier_vision_provider", {duration = 0.2})
    end
end
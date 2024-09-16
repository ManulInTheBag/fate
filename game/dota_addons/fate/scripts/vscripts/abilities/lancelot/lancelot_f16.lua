LinkLuaModifier("modifier_f16_barrage", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_cd", "abilities/lancelot/modifiers/modifier_f16_cd", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_forward_cmd_disable", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_forward", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_mana", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_owner", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_f16_timer", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lancelot_minigun_f16", "abilities/lancelot/lancelot_f16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lancelot_minigun_slow", "abilities/lancelot/lancelot_minigun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_flame_shred", "abilities/lancelot/modifiers/modifier_eternal_flame_shred", LUA_MODIFIER_MOTION_NONE)
modifier_f16_owner = class({})

function modifier_f16_owner:DeclareFunctions()
    --return {MODIFIER_PROPERTY_VISUAL_Z_DELTA}
end
function modifier_f16_owner:GetVisualZDelta()
    return 700
end
function modifier_f16_owner:OnCreated()
    self.parent = self:GetParent()
    self.parent:AddNoDraw()
end
function modifier_f16_owner:OnDestroy()
    self.parent = self:GetParent()
    self.parent:RemoveNoDraw()
    FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
end
function modifier_f16_owner:CheckState()
    return { [MODIFIER_STATE_INVULNERABLE] = true,
             [MODIFIER_STATE_NO_HEALTH_BAR] = true,
             [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
             [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
             [MODIFIER_STATE_UNSELECTABLE] = true }
end
 

function modifier_f16_owner:IsHidden() return true end

lancelot_f16 = class({})


function lancelot_f16:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    self.cast = ParticleManager:CreateParticle("particles/lancelot/f16_cast_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    return true
end
function lancelot_f16:OnAbilityPhaseInterrupted()

    ParticleManager:DestroyParticle(self.cast, false)
    ParticleManager:ReleaseParticleIndex(self.cast)
end




function lancelot_f16:OnSpellStart()
	local caster = self:GetCaster()
	local f16 = CreateUnitByName("f16_at_vinta", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
    ParticleManager:DestroyParticle(self.cast, false)
    ParticleManager:ReleaseParticleIndex(self.cast)
    local kappapride = "at_vinta"..math.random(1,2)
    caster.f16 = f16
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
	f16:FindAbilityByName("lancelot_f16_barrage"):SetLevel(caster:FindAbilityByName("lancelot_minigun"):GetLevel())
	f16:FindAbilityByName("lancelot_f16_nuke"):SetLevel(caster:FindAbilityByName("lancelot_double_edge"):GetLevel())
    f16:FindAbilityByName("lancelot_f16_mana"):SetLevel(caster:FindAbilityByName("lancelot_knight_of_honor"):GetLevel())  
	f16:FindAbilityByName("lancelot_f16_forward"):SetLevel(caster:FindAbilityByName("lancelot_arondite"):GetLevel())
    f16:AddNewModifier(caster, caster:FindAbilityByName("lancelot_minigun"), "modifier_lancelot_minigun_f16", { duration = 30.0 })
	f16:AddNewModifier(hCaster, self, "modifier_kill", { duration = 30.0 })
    f16:AddNewModifier(caster, self, "modifier_f16_timer", {duration = 30})
end

modifier_f16_timer = class({})

function modifier_f16_timer:GetIntrinsicModifierName()
    return "modifier_f16_timer"
end

function modifier_f16_timer:IsHidden() return false end
function modifier_f16_timer:IsDebuff() return false end

lancelot_f16_barrage = class({})

function lancelot_f16_barrage:OnSpellStart()
	local caster = self:GetCaster()
	local vDirection = caster:GetForwardVector()
    EmitZlodemonTrueSoundEveryone("moskes_lanc_rocket")
	caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
	local torpedo_projectile1 = {	Ability 		  = self,
									EffectName		  = "particles/lancelot/rocket.vpcf",
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
        if( not caster:IsAlive()) then
            return end
        local vDirection = caster:GetForwardVector()
		caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
		local torpedo_projectile2 = {	Ability 		  = self,
                                      EffectName		  = "particles/lancelot/rocket.vpcf",
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
        if( not caster:IsAlive()) then
            return end
        local vDirection = caster:GetForwardVector()
		caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
		local torpedo_projectile3 = {	Ability 		  = self,
                                      EffectName		  = "particles/lancelot/rocket.vpcf",
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

	local particle_cast = "particles/lancelot/explosion_fx.vpcf"

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
    if not IsServer() then return end
	self.parent = self:GetParent()
	if not self.parent:IsAlive() then
        self.parent:AddEffects(EF_NODRAW)
        return
    end
end

lancelot_f16_nuke = class({})

function lancelot_f16_nuke:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
    EmitZlodemonTrueSoundEveryone("moskes_lanc_bomb")
    if (targetPoint - caster:GetAbsOrigin()):Length2D() > 700 then
        targetPoint = (targetPoint - caster:GetAbsOrigin()):Normalized()*700 + caster:GetAbsOrigin()
    end

	EmitGlobalSound("Lancelot.Nuke_Alert") 
    if math.random(1,2) == 1 then
        EmitGlobalSound("Nuclear_Launch_Detected")
    else
        EmitGlobalSound("Tactical_Nuke_Incoming")
    end

    --local nukeMarker = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_nuke_calldown_marker_c.vpcf", PATTACH_CUSTOMORIGIN, nil )
    local nukeMarker = ParticleManager:CreateParticle( "particles/lancelot/lancelot_marker.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleShouldCheckFoW(nukeMarker, false)
    ParticleManager:SetParticleControl( nukeMarker, 0, targetPoint)
    ParticleManager:SetParticleControl( nukeMarker, 1, Vector(1500, 0, -1500))
    ParticleManager:ReleaseParticleIndex( nukeMarker )
    -- Destroy particle after delay
   
	Timers:CreateTimer(3.0, function()
        --ParticleManager:DestroyParticle( nukeMarker, false )
       
        EmitGlobalSound("Lancelot.Nuke_Impact")
        local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, 1500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do
            DoDamage(caster, v, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
            if not v:IsMagicImmune() then v:AddNewModifier(caster, v, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")}) end
        end
        -- particle
        local impactFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion_second.vpcf", PATTACH_WORLDORIGIN, nil )
        ParticleManager:SetParticleShouldCheckFoW(impactFxIndex, false)
        ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(2500, 2500, 1500))
        ParticleManager:SetParticleControl( impactFxIndex, 2, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 3, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 4, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 5, Vector(2500, 2500, 2500))
        ParticleManager:ReleaseParticleIndex( impactFxIndex )

        local mushroom = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_explosion.vpcf", PATTACH_WORLDORIGIN, nil )
        ParticleManager:SetParticleShouldCheckFoW(mushroom, false)
        ParticleManager:SetParticleControl( mushroom, 0, targetPoint)
        ParticleManager:ReleaseParticleIndex( mushroom )
     

        

        
       
    end)
end

lancelot_f16_forward = class({})

function lancelot_f16_forward:OnSpellStart()
	local caster = self:GetCaster()
	Timers:CreateTimer(2, function()
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

		local targetPoint = caster:GetAbsOrigin()
        if( not caster:IsAlive()) then
            return end
        EmitGlobalSound("Lancelot.Nuke_Impact")
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

--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
function modifier_f16_forward:SetDirectionByAngles(hUnit, vDirection) --Explained why I am using that in the first ability modifier.
    vDirection = VectorToAngles(vDirection)
    return hUnit:SetAbsAngles(vDirection[1], vDirection[2], vDirection[3])
end

function modifier_f16_forward:DeclareFunctions()
    return {MODIFIER_PROPERTY_VISUAL_Z_DELTA}
end
function modifier_f16_forward:CheckState()
    return {[MODIFIER_STATE_ROOTED] = true}
end
function modifier_f16_forward:IsHidden() return true end

function modifier_f16_forward:RemoveOnDeath() return true end

function modifier_f16_forward:OnCreated()
    if IsServer() then
        self.nInterval = 0.01
    	self:StartIntervalThink(self.nInterval)
        self:OnIntervalThink()
    end
end

function modifier_f16_forward:OnIntervalThink()
    if not IsServer() then return end

    self.hF16  = self:GetParent()
    self.hLanc = self.hF16:GetOwner()--PlayerResource:GetSelectedHeroEntity(self.hF16:GetMainControllingPlayer())

	if self.hLanc and self.hF16:IsAlive() and self.hLanc:IsAlive() then
        giveUnitDataDrivenModifier(self.hLanc, self.hLanc, "jump_pause", 0.02)
        self.hLanc:AddNewModifier(self.hLanc, self:GetAbility(), "modifier_f16_owner", {duration = 0.02})

        local vDirection = self.hF16:GetForwardVector()
		local nSpeed     = self.nInterval * 1000

        local vLoc = GetGroundPosition(self.hF16:GetAbsOrigin(), self.hF16)
        local vNewLoc = vLoc + vDirection * nSpeed

        self:SetDirectionByAngles(self.hF16, vDirection)
        self:SetDirectionByAngles(self.hLanc, vDirection)

        if true then --GridNav:IsTraversable(vNewLoc) and not GridNav:IsBlocked(vNewLoc) then
            --self.hF16:SetAbsOrigin(vNewLoc)
            
            self.hLanc:SetAbsOrigin(vNewLoc)-- NOTE: Cause microrofls

            FindClearSpaceForUnit(self.hF16, vNewLoc, false)
            --FindClearSpaceForUnit(self.hLanc, vNewLoc, false)
        else

        end
	end
end
function modifier_f16_forward:GetVisualZDelta(keys)
    return 600
end

lancelot_f16_mana = class({})

function lancelot_f16_mana:GetIntrinsicModifierName()
    return "modifier_f16_mana"
end

modifier_f16_mana = class({})

function modifier_f16_mana:IsHidden() return false end

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



modifier_lancelot_minigun_f16 = class({})

function modifier_lancelot_minigun_f16:IsHidden()                                                           return false end
function modifier_lancelot_minigun_f16:IsDebuff()                                                           return false end
function modifier_lancelot_minigun_f16:RemoveOnDeath()                                                      return true end

function modifier_lancelot_minigun_f16:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    self.__jopa = {}

    self.sAttach         = "attach_minigun"
    self.sProjectileName = "particles/heroes/anime_hero_lancelot/lancelot_minigun_projectile.vpcf"

    if IsServer() then
        if not (self.hCaster:GetAbilityByIndex(0):GetName() == "lancelot_minigun_end") then
            self.hCaster:SwapAbilities("lancelot_minigun", "lancelot_minigun_end", false, true)
        end

        self.vPoint    = self.vPoint or self.hAbility:GetCursorPosition() + self.hCaster:GetForwardVector()
        self.fDistance = self.hAbility:GetSpecialValueFor("range")*1.7
        self.fSpeed    = self.hAbility:GetSpecialValueFor("speed")*1.5
        self.fWidth    = self.hAbility:GetSpecialValueFor("width")

        self.iPatrons   = self.hAbility:GetSpecialValueFor("bullets_per_second")
        self.flInterval = 1 / self.iPatrons

        self.fBaseDamage   = self.hAbility:GetSpecialValueFor("base_damage")
        self.damage_perc   = self.hAbility:GetSpecialValueFor("atk_damage")/100

        self.hPatronProjectileTable =   {
                                            --EffectName        = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf",--"particles/heroes/anime_hero_guts/guts_crossbow_projectile.vpcf",
                                            source            = self.hParent,
                                            caster            = self.hParent,
                                            ability           = self.hAbility,
                                            --vSpawnOrigin      = self.hParent:GetAttachmentOrigin(self.hParent:ScriptLookupAttachment("attach_attack1")),

                                            iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
                                            iUnitTargetType   = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_OTHER,
                                            iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,

                                            distance         = self.fDistance,
                                            startRadius      = self.fWidth,
                                            endRadius        = self.fWidth,
                                            DeleteOnHit = true,

                                            ExtraData         = {
                                                                    iShoot_PFX  = 0,
                                                                    fDamage     = self.fBaseDamage
                                                                }
                                        }

        self.sEmitSound = "lancelot_minigun_loop"
        self.sound_timer = 0
        EmitSoundOn(self.sEmitSound, self.hParent)

        self.interval_timer = 0
        self.full_timer = 0

        Timers:CreateTimer(FrameTime(), function()
            if self then
                self:OnIntervalThink()
            end
        end)
        self:StartIntervalThink(FrameTime())
    end
end
function modifier_lancelot_minigun_f16:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_lancelot_minigun_f16:OnIntervalThink()
    if IsServer() then

        self.sound_timer = self.sound_timer + FrameTime()
        if self.sound_timer >= 1.7 then
            self.sound_timer = 0
            EmitSoundOn(self.sEmitSound, self.hParent)
        end

        self.full_timer = self.full_timer + FrameTime()
        self.interval_timer = self.interval_timer + FrameTime()

        if not (self.interval_timer >= self.flInterval) then return end
        self.interval_timer = 0

        self.__jopa = self.__jopa or {}
        self.jopa1 = DoUniqueString("jopa2")
        local jopa1 = self.jopa1
        self.__jopa[jopa1] = {}
        local vDirection = self.hParent:GetForwardVector()
        local pfx, bullet = self:shootBullet(vDirection)
        --self.__jopa[jopa1][pfx] = bullet
        local vDirection = self.hParent:GetForwardVector() + self.hParent:GetRightVector()*0.3
        local pfx, bullet = self:shootBullet(vDirection)
        --self.__jopa[jopa1][pfx] = bullet
        local vDirection = self.hParent:GetForwardVector()+ self.hParent:GetRightVector()*-0.3
        local pfx, bullet = self:shootBullet(vDirection)
        --self.__jopa[jopa1][pfx] = bullet
        local vDirection = self.hParent:GetForwardVector() + self.hParent:GetRightVector()*0.15
        local pfx, bullet = self:shootBullet(vDirection)
        --self.__jopa[jopa1][pfx] = bullet
        local vDirection = self.hParent:GetForwardVector()+ self.hParent:GetRightVector()*-0.15
        local pfx, bullet = self:shootBullet(vDirection)
        --self.__jopa[jopa1][pfx] = bullet
        
    end
end

function modifier_lancelot_minigun_f16:shootBullet(vDirection)


    local vAttach = self.hParent:GetAttachmentOrigin(self.hParent:ScriptLookupAttachment(self.sAttach))
    local vPoint  = vAttach + vDirection * self.fDistance + Vector(0,0,-300)

    local iShoot_PFX =  ParticleManager:CreateParticle(self.sProjectileName, PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                        ParticleManager:SetParticleShouldCheckFoW(iShoot_PFX, false)
                        ParticleManager:SetParticleControlEnt(
                                                                iShoot_PFX, 
                                                                0, 
                                                                self.hParent, 
                                                                PATTACH_POINT_FOLLOW, 
                                                                self.sAttach, 
                                                                Vector(0, 0, 0), 
                                                                false
                                                            )
                        ParticleManager:SetParticleControl(iShoot_PFX, 1, vPoint)
                        ParticleManager:SetParticleControl(iShoot_PFX, 2, Vector(self.fSpeed, 0, 0))

    self.hPatronProjectileTable.sourceLoc = vAttach
    self.hPatronProjectileTable.direction    = vDirection
    self.hPatronProjectileTable.distance    = self.fDistance
    self.hPatronProjectileTable.speed    = self.fSpeed

    self.hPatronProjectileTable.ExtraData.iShoot_PFX = iShoot_PFX
    self.hPatronProjectileTable.ExtraData.fDamage    = self.fBaseDamage + self.hCaster:GetAverageTrueAttackDamage(self.hCaster)*self.damage_perc

    local bullet = FATE_ProjectileManager:CreateLinearProjectile(self.hPatronProjectileTable)
    return iShoot_PFX, bullet
end
function modifier_lancelot_minigun_f16:OnDestroy()
    if IsServer()
        and IsNotNull(self.hCaster) then

        if not (self.hCaster:GetAbilityByIndex(0):GetName() == "lancelot_minigun") then
            self.hCaster:SwapAbilities("lancelot_minigun", "lancelot_minigun_end", true, false)
        end


        StopSoundOn(self.sEmitSound, self.hParent)
    end
end
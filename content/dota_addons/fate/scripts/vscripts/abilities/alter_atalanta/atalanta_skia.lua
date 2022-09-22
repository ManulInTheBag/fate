LinkLuaModifier("modifier_atalanta_skia", "abilities/alter_atalanta/atalanta_skia", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_atalanta_skia_cd", "abilities/alter_atalanta/atalanta_skia", LUA_MODIFIER_MOTION_NONE)

atalanta_skia = class({})

function atalanta_skia:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    elseif caster:GetAbsOrigin().y < -2000 then
    	return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function atalanta_skia:GetCustomCastErrorLocation(hLocation)
	if self:GetCaster():GetAbsOrigin().y < -2000 then
		return "#Inside_Reality_Marble"
	end
    return "#Wrong_Target_Location"
end

function atalanta_skia:OnSpellStart()
	--self:GetCaster():EmitSound("atalanta_skia_channel")
	local caster = self:GetCaster()
	local ability = self
	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(ability:GetCooldown(1))
    caster:AddNewModifier(caster, self, "modifier_atalanta_skia_cd", {duration = ability:GetCooldown(1)})
    caster:FindAbilityByName("atalanta_jump"):StartCooldown(caster:FindAbilityByName("atalanta_jump"):GetCooldown(caster:FindAbilityByName("atalanta_jump"):GetLevel()))
end

function atalanta_skia:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function atalanta_skia:OnChannelFinish(bInterrupted)
	if bInterrupted then
		--self:GetCaster():StopSound("atalanta_skia_channel")
		return
	end
	self:GetCaster().skia_target = self:GetCursorPosition()
	EmitGlobalSound("atalanta_skia")
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_atalanta_skia", {duration = 3.25})
	Timers:CreateTimer(1.45, function()
		LoopOverPlayers(function(player, playerID, playerHero)
	        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
	            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="john_cena"})
	            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	        end
    	end)
	end)
end

modifier_atalanta_skia = class({})

function modifier_atalanta_skia:IsHidden() return true end

function modifier_atalanta_skia:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.target = self.parent.skia_target
		self.time_elapsed = 0
		self.kappa = false
		StartAnimation(self.parent, {duration=3.75, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.3})
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_atalanta_skia:CheckState()
    local state = { --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                    --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                    --[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_ROOTED] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_INVULNERABLE] = true,
			 		[MODIFIER_STATE_NO_HEALTH_BAR]	= true,
                    [MODIFIER_STATE_STUNNED] = true
                }
    return state
end

function modifier_atalanta_skia:OnIntervalThink()
	self.time_elapsed = self.time_elapsed + FrameTime()
	if self.time_elapsed >= 3.25 then
		self:Destroy()
		return
	end
	if self.kappa == false then
		self.kappa = true
		local belleFxIndex = ParticleManager:CreateParticle( "particles/atalanta/rider_bellerophon_1.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.parent )
		ParticleManager:SetParticleControlEnt( belleFxIndex, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true )
		ParticleManager:SetParticleControlEnt( belleFxIndex, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true )
		Timers:CreateTimer(3.25, function()
			ParticleManager:DestroyParticle( belleFxIndex, false )
			ParticleManager:ReleaseParticleIndex( belleFxIndex )
		end)
	end
	local direction = (self.target - GetGroundPosition(self.parent:GetAbsOrigin(), self.parent)):Normalized()
	local distance = (GetGroundPosition(self.parent:GetAbsOrigin(), self.parent) - self.target):Length2D()

	local old_position = self.parent:GetAbsOrigin()
	local new_position = old_position + direction*distance*FrameTime()/(3.25 - self.time_elapsed)

	if self.time_elapsed < 2.15 then
		new_position = new_position + Vector(0, 0, 150)
	else
		local z_dist = self.parent:GetAbsOrigin().z - self.target.z
		new_position = new_position + Vector(0, 0, -z_dist*FrameTime()/(3.25-self.time_elapsed))
	end
	self.parent:SetAbsOrigin(new_position)
end

function modifier_atalanta_skia:OnDestroy()
	if not self.parent:IsAlive() then return end

	ScreenShake(self.parent:GetOrigin(), 20, 2.0, 3.0, 2000, 0, true)
	FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
	self.parent:EmitSound("Misc.Crash")

	local hit_fx = ParticleManager:CreateParticle("particles/atalanta/atalanta_earthshock.vpcf", PATTACH_ABSORIGIN, self.parent )
	ParticleManager:SetParticleControl( hit_fx, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl( hit_fx, 1, Vector(self:GetAbility():GetSpecialValueFor("radius"), 500, 300))
	local explodeFx1 = ParticleManager:CreateParticle("particles/atalanta/lancer_gae_bolg_hit.vpcf", PATTACH_ABSORIGIN, self.parent )
	ParticleManager:SetParticleControl( explodeFx1, 0, self.parent:GetAbsOrigin())

	Timers:CreateTimer(3, function()
		ParticleManager:DestroyParticle( hit_fx, false )
		ParticleManager:DestroyParticle( explodeFx1, false )
		ParticleManager:ReleaseParticleIndex(hit_fx)
		ParticleManager:ReleaseParticleIndex(explodeFx1)
	end)

	local enemies2 = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self:GetAbility():GetSpecialValueFor("radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)

		for _,enemy in ipairs(enemies2) do
	            local knockback = { should_stun = self.parent.EvolutionAcquired,
	                                knockback_duration = 1.0,
	                                duration = 1.0,
	                                knockback_distance = self.parent.TornadoAcquired and -500 or 0,
	                                knockback_height = self.parent.EvolutionAcquired and 50 or 0,
	                                center_x = self.parent:GetAbsOrigin().x,
	                                center_y = self.parent:GetAbsOrigin().y,
	                                center_z = self.parent:GetAbsOrigin().z }

	            enemy:AddNewModifier(self.parent, self.ability, "modifier_knockback", knockback)
        end


	local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self:GetAbility():GetSpecialValueFor("radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)

    for _,enemy in ipairs(enemies) do
        self.damage = self:GetAbility():GetSpecialValueFor("damage")
        DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
        for i = 1,self:GetAbility():GetSpecialValueFor("curse_stacks") do
        	self.parent:FindAbilityByName("atalanta_curse"):Curse(enemy)
        end
    end
end

modifier_atalanta_skia_cd = class({})

function modifier_atalanta_skia_cd:GetTexture()
    return "custom/alter_atalanta/atalanta_skia"
end

function modifier_atalanta_skia_cd:IsHidden()
    return false 
end

function modifier_atalanta_skia_cd:RemoveOnDeath()
    return false
end

function modifier_atalanta_skia_cd:IsDebuff()
    return true 
end

function modifier_atalanta_skia_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
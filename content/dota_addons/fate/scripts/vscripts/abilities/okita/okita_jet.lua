LinkLuaModifier("modifier_jet_anim", "abilities/okita/okita_jet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jet_kappa", "abilities/okita/okita_jet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jet_checker", "abilities/okita/okita_jet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_jet_cd", "abilities/okita/okita_jet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_stunned", "abilities/okita/okita_jet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

--timing 2.850 - 8.000, 8.000 - 8.300, 8.300 - 13.000, 13.100 - 13.750, 13.750 - 15.700

-- Vector 0000000000320560 [-8093.434570 -1504.492432 384.000000]
-- Vector 000000000035E700 [7195.466309 6928.266602 384.000000]

okita_jet = class({})

function okita_jet:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    elseif caster:GetAbsOrigin().y < -2000 then
    	return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_jet:GetCustomCastErrorLocation(hLocation)
	if self:GetCaster():GetAbsOrigin().y < -2000 then
		return "#Inside_Reality_Marble"
	end
    return "#Wrong_Target_Location"
end

function okita_jet:OnSpellStart()
	local caster = self:GetCaster()
	EmitGlobalSound("okita_jet_cast_new")
	self.channelTime = 0
	--local kappapride = "at_vinta"..math.random(1,2)
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound=kappapride})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	self.fx = ParticleManager:CreateParticle("particles/okita/okita_jet_fly.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.fx, 0, caster:GetAbsOrigin())
	self.fx1 = ParticleManager:CreateParticle("particles/okita/okita_jet_cast_runes.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.fx1, 0, caster:GetAbsOrigin())
	--[[Timers:CreateTimer(12.95, function()
		ParticleManager:DestroyParticle(self.fx, false)
	end)]]

	caster:AddNewModifier(caster, self, "modifier_jet_anim", {duration = 5.15})
	caster:AddNewModifier(caster, self, "modifier_okita_jet_cd", {duration = self:GetCooldown(1)})
end

function okita_jet:OnChannelThink(fInterval)
    self.channelTime = self.channelTime + fInterval
    --giveUnitDataDrivenModifier(self:GetCaster(), self:GetCaster(), "locked", 0.3)
end

function okita_jet:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	StopGlobalSound("okita_jet_cast_new")
	ParticleManager:DestroyParticle(self.fx, false)
	ParticleManager:ReleaseParticleIndex(self.fx)
	ParticleManager:DestroyParticle(self.fx1, false)
	ParticleManager:ReleaseParticleIndex(self.fx1)
	caster:RemoveModifierByName("modifier_jet_anim")

	if self.channelTime < 1 then return end

	EmitGlobalSound("okita_jet_4")

	local dist = self:GetSpecialValueFor("dist_min") + (self:GetSpecialValueFor("dist_max") - self:GetSpecialValueFor("dist_min"))*(self.channelTime-1)/(self:GetSpecialValueFor("max_channel_time") - 1)
	local target = self:GetCursorPosition()
	local dist2 = (target - caster:GetAbsOrigin()):Length2D()
	if dist > dist2 then
		dist = dist2
	end
	--[[if bInterrupted then
		caster:RemoveModifierByName("modifier_jet_anim")
		StopGlobalSound("okita_jet_cast")
		return
	end]]
	--[[local point1 = Vector(-8039.434570, -1504.492432, 256.000000)
	local point2 = Vector(7195.466309, 6928.266602, 256.000000)
	local point = point1
	local dist1 = (point1 - target):Length2D()
	local dist2 = (point2 - target):Length2D()
	local dist = dist1
	if dist2 > dist1 then
		point = point2
		dist = dist2
	end
	local dist3 = (caster:GetAbsOrigin() - point):Length2D()

	local point3 = caster:GetAbsOrigin() + caster:GetForwardVector()*(-14400 + (caster:GetAbsOrigin() - target):Length2D())
	point = point3
	dist3 = (caster:GetAbsOrigin() - point):Length2D()
	dist = (point- target):Length2D()
	--local belleFxIndex = ParticleManager:CreateParticle( "particles/custom/rider/rider_bellerophon_1_alternate.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster )
	--ParticleManager:SetParticleControlEnt( belleFxIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
	--ParticleManager:SetParticleControlEnt( belleFxIndex, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
	--Timers:CreateTimer(7.7, function()
	--	ParticleManager:DestroyParticle( belleFxIndex, false )
	--	ParticleManager:ReleaseParticleIndex( belleFxIndex )
	--end)
	EmitGlobalSound("okita_jet_3")]]
	caster:AddNewModifier(caster, self, "modifier_jet_kappa", {	duration = 7.4,
																Target_x = target.x,
																Target_y = target.y,
																Target_z = target.z,
																			dist = dist})
	--[[Timers:CreateTimer(7.41, function()
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)]]
end

modifier_jet_anim = class({})

function modifier_jet_anim:IsHidden() return true end
function modifier_jet_anim:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_jet_anim:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_3
end
function modifier_jet_anim:GetOverrideAnimationRate()
    return 0.1
end
function modifier_jet_anim:OnCreated()
	self.parent = self:GetParent()
	self:StartIntervalThink(FrameTime())
end
function modifier_jet_anim:OnIntervalThink()
	self:VerticalMotion(self.parent, FrameTime())
end
function modifier_jet_anim:VerticalMotion(me, dt)
	if IsServer() then
		if self.parent:GetAbsOrigin().z < 384 then
			self.parent:SetAbsOrigin(self.parent:GetAbsOrigin() + Vector(0,0,4))
		end
	end
end

modifier_jet_kappa = class({})
function modifier_jet_kappa:IsHidden() return true end
function modifier_jet_kappa:IsDebuff() return false end
function modifier_jet_kappa:IsPurgable() return false end
function modifier_jet_kappa:IsPurgeException() return false end
function modifier_jet_kappa:RemoveOnDeath() return true end
function modifier_jet_kappa:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_jet_kappa:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_jet_kappa:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_jet_kappa:OnCreated(args)
	if IsServer() then
		self.parent = self:GetParent()
		self.leap_z = 384
		self.pos = self.parent:GetAbsOrigin()
		self.dist_elapsed = 0
		self.dist = args.dist
		self.target = Vector(args.Target_x, args.Target_y, args.Target_z)
		--self.point = Vector(args.Target_0_x, args.Target_0_y, args.Target_0_z)
		self.time_elapsed = 0
		--self.fly_time = 4.7
		self.kappa = false
		self.radius = self:GetAbility():GetSpecialValueFor("radius")
		self.speed = self:GetAbility():GetSpecialValueFor("speed")
		self:StartIntervalThink(FrameTime())
		self.fx = ParticleManager:CreateParticle("particles/okita/okita_jet_fly.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.fx, 0, self.parent:GetAbsOrigin())
	end
end
function modifier_jet_kappa:OnDestroyed()
	if IsServer() then
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		ParticleManager:DestroyParticle(self.fx, false)
		ParticleManager:ReleaseParticleIndex(self.fx)
	end
end
function modifier_jet_kappa:OnIntervalThink()
	if self.parent:HasModifier("modifier_aestus_domus_aurea_enemy") and not self.fucked then
		--EmitGlobalSound("astronomia")
		self.fucked = true
		Timers:CreateTimer(0.5, function()
		 	self:Destroy()
		end)
	end
	local enemy = PickRandomEnemy(self.parent)
    if enemy then
        self.parent:AddNewModifier(enemy, nil, "modifier_vision_provider", { duration = 3 })
    end
	if true then
		self.dist_elapsed = self.dist_elapsed + (self.parent:GetAbsOrigin() - self.pos):Length2D()
		self.pos = self.parent:GetAbsOrigin()
		if self.dist_elapsed >= self.dist then
			FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
			ParticleManager:DestroyParticle(self.fx, false)
			ParticleManager:ReleaseParticleIndex(self.fx)
			self:Destroy()
			Timers:CreateTimer(FrameTime(), function()
				FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
			end)
		end
		self.parent:FaceTowards(self.target)
		self:HorizontalMotion(self.parent, FrameTime())
		--self:VerticalMotion(self.parent, FrameTime())
		local enemy = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		local damage = 700+(self.parent.IsKikuIchimonjiAcquired and self.parent:GetAgility()*2.5 or 0) --self.parent:FindAbilityByName("okita_sandanzuki"):GetSpecialValueFor("base_damage")
		for i = 1,#enemy do
			if not enemy[i]:HasModifier("modifier_jet_checker") then
				--DoDamage(self.parent, enemy[i], self.speed*0.4, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				enemy[i]:AddNewModifier(self.parent, self, "modifier_jet_checker", {duration = 1})
				self.slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
	    		ParticleManager:SetParticleControl(self.slashIndex, 0, enemy[i]:GetAbsOrigin())
	    		ParticleManager:SetParticleControl(self.slashIndex, 1, Vector(500,0,150))
	    		ParticleManager:SetParticleControl(self.slashIndex, 2, Vector(0.2,0,0))
	   			Timers:CreateTimer(0.4, function()
	       			local particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, self.parent)
	       			ParticleManager:SetParticleControl(particle, 0, enemy[i]:GetAbsOrigin())
	    		end)
	    		Timers:CreateTimer(0.8, function()
	       			DoDamage(self.parent, enemy[i], damage, DAMAGE_TYPE_MAGICAL, 0, self.parent:FindAbilityByName("okita_jet"), false)
	       			enemy[i]:RemoveModifierByName("modifier_master_intervention")
	       			enemy[i]:EmitSound("okita_jet_impact")
	       			enemy[i]:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	    		end)
	    		Timers:CreateTimer(0.9, function()
	       			DoDamage(self.parent, enemy[i], damage, DAMAGE_TYPE_MAGICAL, 0, self.parent:FindAbilityByName("okita_jet"), false)
	       			enemy[i]:RemoveModifierByName("modifier_master_intervention")
	       			enemy[i]:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	    		end)
	    		Timers:CreateTimer(1.0, function()
	       			DoDamage(self.parent, enemy[i], damage, DAMAGE_TYPE_MAGICAL, 0, self.parent:FindAbilityByName("okita_jet"), false)
	       			enemy[i]:RemoveModifierByName("modifier_master_intervention")
	       			enemy[i]:EmitSound("Tsubame_Focus")
	    		end)
	    	end
	    end
		--[[local unitGroup = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		--self:HorizontalMotion(self.parent, FrameTime())
		--self:VerticalMotion(self.parent, FrameTime())
		for i=1,#unitGroup do
			self:HorizontalMotion(unitGroup[i], FrameTime())
			self:VerticalMotion(unitGroup[i], FrameTime())
			if unitGroup[i] ~= self.parent then
				unitGroup[i]:AddNewModifier(self.parent, self, "modifier_okita_stunned", {duration = 2*FrameTime()})
			end
		end]]
	else
		--[[if not self.kappa then
			EmitGlobalSound("okita_jet_4")
			self.radius = 1
			effectIndex_b = ParticleManager:CreateParticle("particles/thd2/heroes/marisa/marisa_04_spark_wind_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
			ParticleManager:SetParticleControl(effectIndex_b, 0, self.parent:GetOrigin() + Vector(self.parent:GetForwardVector().x * 92,self.parent:GetForwardVector().y * 92,150))
			ParticleManager:SetParticleControl(effectIndex_b, 8, self.parent:GetForwardVector())
			Timers:CreateTimer(2, function()
				if effectIndex_b then
					ParticleManager:DestroyParticle(effectIndex_b, false)
				end
			end)
			self.kappa = true
		end
		local unitGroup = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, 1, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		--self:HorizontalMotion(self.parent, FrameTime())
		--self:VerticalMotion(self.parent, FrameTime())
		for i=1,#unitGroup do
			self:HorizontalMotion(unitGroup[i], FrameTime())
			self:VerticalMotion(unitGroup[i], FrameTime())
			if unitGroup[i] ~= self.parent then
				unitGroup[i]:AddNewModifier(self.parent, self, "modifier_okita_stunned", {duration = 2*FrameTime()})
			end
		end]]
	end
	--self.time_elapsed = self.time_elapsed + FrameTime()
end
function modifier_jet_kappa:HorizontalMotion(me, dt)
	local new_location = me:GetAbsOrigin() + (self.target - self.parent:GetAbsOrigin()):Normalized() * self.speed * FrameTime()
	me:SetAbsOrigin(new_location)
	--[[if self.time_elapsed < self.time1 then
		local new_location = me:GetAbsOrigin() + (self.point - self.parent:GetAbsOrigin()):Normalized() * self.speed * FrameTime()
		me:SetAbsOrigin(new_location)
	elseif self.time_elapsed < self.fly_time then
		local new_location = me:GetAbsOrigin() + (self.target - self.parent:GetAbsOrigin()):Normalized() * self.speed * FrameTime()
		me:SetAbsOrigin(new_location)
	elseif self.time_elapsed - self.fly_time < 2 then
		local new_location = me:GetAbsOrigin() + self.parent:GetForwardVector()*800*(1-(self.time_elapsed - self.fly_time)/2)*FrameTime()
		me:SetAbsOrigin(new_location)
	end]]
end
function modifier_jet_kappa:VerticalMotion(me, dt)
	if self.time_elapsed < self.fly_time then
		return
	elseif self.time_elapsed - self.fly_time < 2 then
		self.leap_z = self.leap_z + 7*(1 - (2-self.time_elapsed)/2)
		me:SetAbsOrigin(GetGroundPosition(me:GetAbsOrigin(), me) + Vector(0,0,self.leap_z))
		me:AddNewModifier(self.parent, self:GetAbility(), "modifier_okita_stunned", {duration = 3})
	end
end

modifier_jet_checker = class({})
function modifier_jet_checker:IsHidden() return true end
function modifier_jet_checker:IsDebuff() return true end

modifier_okita_jet_cd = class({})

function modifier_okita_jet_cd:GetTexture()
	return "custom/okita/okita_jet"
end

function modifier_okita_jet_cd:IsHidden()
	return false 
end

function modifier_okita_jet_cd:RemoveOnDeath()
	return false
end

function modifier_okita_jet_cd:IsDebuff()
	return true 
end

function modifier_okita_jet_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_okita_stunned = class({})
function modifier_okita_stunned:IsHidden() return false end
function modifier_okita_stunned:IsDebuff() return false end
function modifier_okita_stunned:CheckState()
    local state =   { [MODIFIER_STATE_STUNNED] = true,
                    }
    return state
end
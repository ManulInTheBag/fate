LinkLuaModifier("modifier_okita_jce_active", "abilities/okita/okita_channel_slashes", LUA_MODIFIER_MOTION_NONE)

okita_jce = class({})

--[[function okita_jce:OnAbilityPhaseStart()
	EmitSoundOn("okita_attack_4", self:GetCaster())
	return true
end

function okita_jce:OnAbilityPhaseInterrupted()
	StopSoundOn("okita_attack_4", self:GetCaster())
end]]

function okita_jce:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function okita_jce:CastFilterResult()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_okita_sandanzuki_charge") or caster:HasModifier("modifier_okita_sandanzuki_pepeg") then
    	return UF_SUCESS--UF_FAIL_CUSTOM
    else
    	return UF_SUCCESS
    end
end

function okita_jce:GetCustomCastError()
	local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") then
    	return "#Sandanzuki_Active_Error"
    end
end

function okita_jce:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	self.origin = self:GetCursorPosition()--caster:GetAbsOrigin()

	local direction = (self.origin - caster:GetAbsOrigin())
    local dist = math.min(self:GetSpecialValueFor("range"), direction:Length2D())
    direction.z = 0
    direction = direction:Normalized()

    self.origin = GetGroundPosition( caster:GetAbsOrigin() + direction*dist, nil )

	local hit_count = self:GetSpecialValueFor("hit_count")
	local duration = self:GetSpecialValueFor("duration")
	self.hit_damage = self:GetSpecialValueFor("hit_damage")
	self.end_damage = 0
	self.radius = self:GetSpecialValueFor("radius")
	self.interval = duration/hit_count
	self.channelTime = self.interval

	if caster.IsReducedWindAcquired then
		caster:AddNewModifier(caster, self, "modifier_okita_jce_active", {duration = 0.5})
	end

	AddFOWViewer(2,self.origin, 10, 3, false)
    AddFOWViewer(3,self.origin, 10, 3, false)

    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="vergil_"..math.random(1,4)})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    --[[Timers:CreateTimer(duration, function()
    	self:JudgementCutEnd()
    end)]]
end

function okita_jce:OnChannelThink(fInterval)
    self.channelTime = self.channelTime + fInterval
    if self.channelTime >= self.interval then
    	local caster = self:GetCaster()
    	self.channelTime = 0
    	self.end_damage = self.end_damage + self:GetSpecialValueFor("base_damage")/self:GetSpecialValueFor("hit_count")

    	for j=1,5 do
			local angle = RandomInt(0, 360)
			local random1 = self.radius--RandomInt(200, radius-1)
			local random2 = RandomInt(0, self.radius-1)
			local startLoc = GetRotationPoint(self.origin,random1,angle)
			local endLoc = GetRotationPoint(self.origin,random2,angle + RandomInt(120, 240))
			local fxIndex = ParticleManager:CreateParticle( "particles/okita/okita_jce_slash.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl( fxIndex, 0, startLoc + Vector(0,0,self.radius*math.abs(math.sqrt(1 - (random1/self.radius)^2))))
			ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,self.radius*math.abs(math.sqrt(1 - (random2/self.radius)^2))))
			EmitSoundOnLocationWithCaster(self.origin, "Tsubame_Slash_" .. math.random(1,3), caster)
			--caster:EmitSound("Tsubame_Slash_" .. math.random(1,3))
		end
		
		local unitGroup = FindUnitsInRadius(caster:GetTeam(), self.origin, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for j = 1, #unitGroup do
			--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PHYSICAL, 0, self, false)
			--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PURE, 0, self, false)
			if not unitGroup[j]:IsMagicImmune() then
				if caster.IsTennenAcquired then
		            caster:PerformAttack( unitGroup[j], true, true, true, true, false, true, true )
		        end
				DoDamage(caster, unitGroup[j], self.hit_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end
		end
    end
    --giveUnitDataDrivenModifier(self:GetCaster(), self:GetCaster(), "locked", 0.3)
end

function okita_jce:OnChannelFinish(bInterrupted)
	self:JudgementCutEnd()
end

function okita_jce:JudgementCutEnd()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")

	caster:RemoveModifierByName("modifier_okita_jce_active")

	local count = 60 --20 + 40*self.channelTime/3

	--damage = damage*count/20

	for i=1,count/2 do
		Timers:CreateTimer(0.003*i, function()
			local angle = RandomInt(0, 360)
			local random1 = RandomInt(200, radius-1)
			local random2 = RandomInt(0, radius-1)
	        local startLoc = GetRotationPoint(self.origin,random1,angle)
	        local endLoc = GetRotationPoint(self.origin,random2,angle + RandomInt(120, 240))
	        local fxIndex = ParticleManager:CreateParticle( "particles/okita/okita_jce_slash.vpcf", PATTACH_ABSORIGIN, caster)
	        ParticleManager:SetParticleControl( fxIndex, 0, startLoc + Vector(0,0,radius*math.abs(math.sqrt(1 - (random1/radius)^2))))
	        ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,radius*math.abs(math.sqrt(1 - (random2/radius)^2))))
	        EmitSoundOnLocationWithCaster(self.origin, "Tsubame_Slash_" .. math.random(1,3), caster)
	        --caster:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	    end)
    end
    local unitGroup = FindUnitsInRadius(caster:GetTeam(), self.origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for i = 1, #unitGroup do
		--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PURE, 0, self, false)
		if not unitGroup[i]:IsMagicImmune() then
			if caster.IsTennenAcquired then
	            caster:PerformAttack( unitGroup[i], true, true, true, true, false, true, true )
	        end
			DoDamage(caster, unitGroup[i], self.end_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	end
end

modifier_okita_jce_active = class({})

function modifier_okita_jce_active:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()

	ProjectileManager:ProjectileDodge(self.parent)
	FATE_ProjectileManager:ProjectileDodge(self.parent)

	self:StartIntervalThink(FrameTime())
end

function modifier_okita_jce_active:OnIntervalThink()
	if not IsServer() then return end

	ProjectileManager:ProjectileDodge(self.parent)
	FATE_ProjectileManager:ProjectileDodge(self.parent)
end

function modifier_okita_jce_active:IsHidden() return true end
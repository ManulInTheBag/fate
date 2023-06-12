LinkLuaModifier("modifier_jce_active", "abilities/okita/okita_jce", LUA_MODIFIER_MOTION_NONE)

okita_jce = class({})

--[[function okita_jce:OnAbilityPhaseStart()
	EmitSoundOn("okita_attack_4", self:GetCaster())
	return true
end

function okita_jce:OnAbilityPhaseInterrupted()
	StopSoundOn("okita_attack_4", self:GetCaster())
end]]

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
	self.origin = caster:GetAbsOrigin()
	self.channelTime = 0

	local hit_count = self:GetSpecialValueFor("hit_count")
	local duration = self:GetSpecialValueFor("duration")
	local hit_damage = self:GetSpecialValueFor("hit_damage")
	local radius = self:GetSpecialValueFor("radius")
	local interval = duration/hit_count

	caster:AddNewModifier(caster, self, "modifier_jce_active", {})
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", self:GetSpecialValueFor("duration"))
	caster:AddEffects(EF_NODRAW)

	self.fxIndex = ParticleManager:CreateParticle("particles/okita/okita_chronosphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl( self.fxIndex, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl( self.fxIndex, 1, Vector(radius, radius, radius))

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
    for i = 0, (hit_count - 1) do
    	Timers:CreateTimer(interval*i, function()
    		for j=1,5 do
				local angle = RandomInt(0, 360)
				local random1 = RandomInt(200, radius-1)
				local random2 = RandomInt(0, radius-1)
			    local startLoc = GetRotationPoint(self.origin,random1,angle)
			    local endLoc = GetRotationPoint(self.origin,random2,angle + RandomInt(120, 240))
			    local fxIndex = ParticleManager:CreateParticle( "particles/okita/okita_jce_slash.vpcf", PATTACH_ABSORIGIN, caster)
			    ParticleManager:SetParticleControl( fxIndex, 0, startLoc + Vector(0,0,radius*math.abs(math.sqrt(1 - (random1/radius)^2))))
			    ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,radius*math.abs(math.sqrt(1 - (random2/radius)^2))))
			    caster:EmitSound("Tsubame_Slash_" .. math.random(1,3))
		    end
		    local unitGroup = FindUnitsInRadius(caster:GetTeam(), self.origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
			for j = 1, #unitGroup do
				--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PHYSICAL, 0, self, false)
				--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PURE, 0, self, false)
				if not unitGroup[j]:IsMagicImmune() then
					DoDamage(caster, unitGroup[j], hit_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				end
			end
    	end)
	end
    Timers:CreateTimer(duration, function()
    	self:JudgementCutEnd()
    end)
end

--[[function okita_jce:OnChannelThink(fInterval)
    self.channelTime = self.channelTime + fInterval
    giveUnitDataDrivenModifier(self:GetCaster(), self:GetCaster(), "locked", 0.3)
end]]

function okita_jce:JudgementCutEnd()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("base_damage")-- + caster:GetAverageTrueAttackDamage(caster)

	--[[if caster.IsTennenAcquired then
		damage = damage + caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("attribute_attack_damage")/100
	end]]

	caster:RemoveModifierByName("modifier_jce_active")
	caster:RemoveEffects(EF_NODRAW)
	Timers:CreateTimer(0.01, function()
		ParticleManager:DestroyParticle(self.fxIndex, false)
		ParticleManager:ReleaseParticleIndex(self.fxIndex)
	end)

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
	        caster:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	    end)
    end
    local unitGroup = FindUnitsInRadius(caster:GetTeam(), self.origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for i = 1, #unitGroup do
		--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		--DoDamage(caster, unitGroup[i], damage/3, DAMAGE_TYPE_PURE, 0, self, false)
		if not unitGroup[i]:IsMagicImmune() then
			DoDamage(caster, unitGroup[i], damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	end
end

--[[function okita_seigan:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local ability = self
	local slashes = ability:GetSpecialValueFor("base_slashes")
	local damage = ability:GetSpecialValueFor("damage")*caster:GetAverageTrueAttackDamage(caster)
	if caster.IsTennenAcquired and caster:HasModifier("modifier_tennen_active") then
		damage = damage + ability:GetSpecialValueFor("damage_big_bonus")
	end
	local damage_big = ability:GetSpecialValueFor("damage_big")*caster:GetAverageTrueAttackDamage(caster)
	if caster.IsTennenAcquired and caster:HasModifier("modifier_tennen_active") then
		damage_big = damage_big + ability:GetSpecialValueFor("damage_big_bonus")
	end
	local modifier = caster:FindModifierByName("modifier_tennen_stacks")
	local stacks = modifier and modifier:GetStackCount() or 0
	for i=1, slashes + stacks do
		Timers:CreateTimer(0.01*i, function()
			DoDamage(caster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
            CreateSlashFx(caster, hTarget:GetAbsOrigin() + RandomVector(300), hTarget:GetAbsOrigin() + RandomVector(300))
            hTarget:EmitSound("Tsubame_Slash_" .. math.random(1,3))
		end)
	end
	DoDamage(caster, hTarget, damage_big, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	hTarget:EmitSound("Tsubame_Focus")
end]]

modifier_jce_active = class({})

function modifier_jce_active:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true }
end

function modifier_jce_active:IsHidden() return true end
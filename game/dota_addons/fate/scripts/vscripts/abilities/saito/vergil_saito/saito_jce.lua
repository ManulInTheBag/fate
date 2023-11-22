saito_jce = class({})

function saito_jce:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function saito_jce:OnSpellStart()
    local caster = self:GetCaster()

    EmitSoundOn("Saito.Style.Cast.Voice", caster)
    --EmitGlobalSound("Saito.Style.Cast")

    caster:AddNewModifier(caster, self, "modifier_saito_jce_channeling", {duration = self.BaseClass.GetChannelTime(self)})

    local cd = self:GetSpecialValueFor("decreased_cooldown")

    local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(cd)
    self:EndCooldown()
    self:StartCooldown(cd)

    caster:AddNewModifier(caster, self, "modifier_saito_jce_cd", {duration = cd})
end

function saito_jce:OnChannelFinish(bInterrupted)
    local caster   = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:RemoveModifierByName("modifier_saito_jce_channeling")

    if not bInterrupted then
        caster:AddNewModifier(caster, self, "modifier_saito_jce", {duration = duration})

        local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	    masterCombo:EndCooldown()
	    masterCombo:StartCooldown(self:GetCooldown(-1))
	    self:EndCooldown()
	    self:StartCooldown(self:GetCooldown(-1))

	    caster:RemoveModifierByName("modifier_saito_jce_window")

	    caster:AddNewModifier(caster, self, "modifier_saito_jce_cd", {duration = self:GetCooldown(1)})
    else
        for i = 1, 5 do
            StopSoundOn("saito_jce_impact", hCaster)
        end
    end
end

LinkLuaModifier("modifier_saito_jce_channeling", "abilities/saito/vergil_saito/saito_jce", LUA_MODIFIER_MOTION_NONE)

modifier_saito_jce_channeling = class({})

function modifier_saito_jce_channeling:OnCreated()
    if IsServer() then
    	self.caster = self:GetCaster()
    	self.ability = self:GetAbility()
        self.radius    = self.ability:GetAOERadius()
        self.loc = self.caster:GetAbsOrigin()

        --EmitSoundOn("Saito.Blast.Cast", self.caster)
        self.duration = self:GetDuration()

        if not self.fx then
            self.fx =  ParticleManager:CreateParticle("particles/saito/vergil_saito/saito_jce_cast.vpcf", PATTACH_WORLDORIGIN, nil)
                                        ParticleManager:SetParticleShouldCheckFoW(self.fx, false)
                                        ParticleManager:SetParticleControl(self.fx, 0, self.loc)
                                        ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius, self.radius, self.radius))

            self:AddParticle(self.fx, false, false, -1, false, false)
        end
        self:StartIntervalThink(FrameTime())
    end
end
function modifier_saito_jce_channeling:OnIntervalThink()
	if not IsServer() then return end

	self.duration = self.duration - FrameTime()
	if self.duration <= 0.5 then
		EmitSoundOn("saito_jce_impact", self.caster)
		self:StartIntervalThink(-1)
	end
end
function modifier_saito_jce_channeling:OnDestroy()
    if IsServer() then
    end
end

LinkLuaModifier("modifier_saito_jce", "abilities/saito/vergil_saito/saito_jce", LUA_MODIFIER_MOTION_NONE)

modifier_saito_jce = class({})

function modifier_saito_jce:IsHidden() return true end
function modifier_saito_jce:IsDebuff() return false end

function modifier_saito_jce:CheckState()
    local state =   {
                        [MODIFIER_STATE_STUNNED]       = true,
                        [MODIFIER_STATE_INVULNERABLE]  = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true
                    }
    return state
end

function modifier_saito_jce:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.radius = self.ability:GetSpecialValueFor("radius")
	self.loc = self.caster:GetAbsOrigin()

	self.duration = self:GetDuration()

	local enemies = FindUnitsInRadius(self.caster:GetTeam(), self.loc, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

	for k, v in pairs(enemies) do
		v:AddNewModifier(self.caster, self.ability, "modifier_saito_jce_enemy", {duration = self.duration})
	end

	self.caster:AddNoDraw()
    local vAttach_1 =   self.caster:GetAttachmentOrigin(self.caster:ScriptLookupAttachment("attach_attack1"))
    
    local iSlashPFX =   ParticleManager:CreateParticle("particles/heroes/anime_hero_vergil/vergil_jc_cast.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControlTransformForward(iSlashPFX, 0, vAttach_1 + self.caster:GetForwardVector() * 150, self.caster:GetForwardVector())
    ParticleManager:SetParticleControl(iSlashPFX, 1, Vector(150, 0, 0))
    ParticleManager:SetParticleShouldCheckFoW(iSlashPFX, false)
    ParticleManager:ReleaseParticleIndex(iSlashPFX)

    if not self.iSlashesPFX then
    	self.iSlashesPFX =  ParticleManager:CreateParticle("particles/saito/vergil_saito/saito_jce_slashes.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleShouldCheckFoW(self.iSlashesPFX, false)
        ParticleManager:SetParticleControl(self.iSlashesPFX, 0, self.loc)
        ParticleManager:SetParticleControl(self.iSlashesPFX, 1, Vector(self.radius, self.radius, self.radius))

        self:AddParticle(self.iSlashesPFX, true, false, -1, false, false)
    end

    self.interval = FrameTime()
    self.animation_delay = 0.75

    self.hVergil_JCE_ComboTable  = self.hVergil_JCE_ComboTable or   {
                                                                            fMaxRadius       = self.radius,
                                                                            iCurrentQuadrant = 1, -- Quadrants 1: NW, 2: NE, 3: SE, 4: SW
                                                                            vMainLoc         = self.loc,
                                                                            vPointOld        = self.loc,
                                                                            vPointNew        = self.loc + self.caster:GetForwardVector() * self.radius
                                                                        }

    self:PerformJCEMotion(self.caster, self.hVergil_JCE_ComboTable, true)
    
    self:StartIntervalThink(self.interval)
end

function modifier_saito_jce:OnIntervalThink()
	if not IsServer() then return end

	self.animation_delay = self.animation_delay - self.interval
	if self.animation_delay > 0 then
		self:PerformJCEMotion(self.caster, self.hVergil_JCE_ComboTable, false)
	else
		self.hVergil_JCE_ComboTable.vPointNew = self.loc
		self:PerformJCEMotion(self.caster, self.hVergil_JCE_ComboTable, true)

		self.caster:RemoveNoDraw()

		StartAnimation(self.caster, {duration=0.75, activity=ACT_DOTA_RAZE_1, rate=1.5})

		self:StartIntervalThink(-1)
	end
end

function modifier_saito_jce:PerformJCEMotion(hCaster, hVergil_JCE_ComboTable, bIsFirstOrLast)
    if IsServer()
        and IsNotNull(hCaster) then

        local fMaxRadius       = hVergil_JCE_ComboTable.fMaxRadius
        local iCurrentQuadrant = hVergil_JCE_ComboTable.iCurrentQuadrant
        local vMainLoc         = hVergil_JCE_ComboTable.vMainLoc

        if type(fMaxRadius) ~= "number"
            or type(iCurrentQuadrant) ~= "number"
            or type(vMainLoc) ~= "userdata" then
            return error("Can't use JCE COMBO JC Because something not exist ["..tostring(fMaxRadius)..", "..tostring(iCurrentQuadrant)..", "..tostring(vMainLoc).."]")
        end

                --=========================================================--
                local fDistance_Min = fMaxRadius * 0.5
                local fDistance_Max = fMaxRadius-- - fDistance_Min
                --=========================================================--
                local fDistance_Random = RandomFloat(fDistance_Min, fDistance_Max)
                --=========================================================--
                local fAngle_Random    = math.rad(RandomInt(0, 90))
                --=========================================================--
                local fLoc_DX_Random   = fDistance_Random * math.cos(fAngle_Random)
                local fLoc_DY_Random   = fDistance_Random * math.sin(fAngle_Random)
                --=========================================================--
                local vPointOld = hVergil_JCE_ComboTable.vPointOld
                local vPointNew = hVergil_JCE_ComboTable.vPointNew
                --=========================================================--
                if not bIsFirstOrLast then 
                    if iCurrentQuadrant == 1 then          -- NW
                        vPointNew = Vector( vMainLoc.x - fLoc_DX_Random, vMainLoc.y + fLoc_DY_Random, vMainLoc.z )
                    elseif iCurrentQuadrant == 2 then      -- NE
                        vPointNew = Vector( vMainLoc.x + fLoc_DX_Random, vMainLoc.y + fLoc_DY_Random, vMainLoc.z )
                    elseif iCurrentQuadrant == 3 then      -- SE
                        vPointNew = Vector( vMainLoc.x + fLoc_DX_Random, vMainLoc.y - fLoc_DY_Random, vMainLoc.z )
                    else                                -- SW
                        vPointNew = Vector( vMainLoc.x - fLoc_DX_Random, vMainLoc.y - fLoc_DY_Random, vMainLoc.z )
                    end
                    --=========================================================--
                    hVergil_JCE_ComboTable.iCurrentQuadrant = ( hVergil_JCE_ComboTable.iCurrentQuadrant + 1 ) % 4
                end
                --=========================================================--
                local fSlashLineDist  = GetDistance(vPointNew, vPointOld) * 0.5
                local vSlashLinePoint = vPointOld + ( GetDirection(vPointNew, vPointOld) * -fSlashLineDist )
                local iSlashLinePFX =   ParticleManager:CreateParticle("particles/saito/vergil_saito/saito_jce_slash_step.vpcf", PATTACH_WORLDORIGIN, nil)
                                        ParticleManager:SetParticleShouldCheckFoW(iSlashLinePFX, false)
                                        ParticleManager:SetParticleControl(iSlashLinePFX, 0, vSlashLinePoint)
                                        ParticleManager:SetParticleControl(iSlashLinePFX, 1, vPointNew)
                                        ParticleManager:SetParticleControl(iSlashLinePFX, 2, vPointNew)
                                        ParticleManager:ReleaseParticleIndex(iSlashLinePFX)
                --=========================================================--
                hVergil_JCE_ComboTable.vPointOld = vPointNew--vSlashLinePoint

                local vec = (-vSlashLinePoint + vPointNew):Normalized()
                local iSlashPFX =   ParticleManager:CreateParticle("particles/heroes/anime_hero_vergil/vergil_jc_cast.vpcf", PATTACH_WORLDORIGIN, nil)
			    ParticleManager:SetParticleControlTransformForward(iSlashPFX, 0, vSlashLinePoint + vec * 150, vec)
			    ParticleManager:SetParticleControl(iSlashPFX, 1, Vector(150, 0, 0))
			    ParticleManager:SetParticleShouldCheckFoW(iSlashPFX, false)
			    ParticleManager:ReleaseParticleIndex(iSlashPFX)
                --=========================================================--
        return hVergil_JCE_ComboTable
    end
end

function modifier_saito_jce:OnDestroy()
    if IsServer() then
    	self.caster:RemoveNoDraw() --if something went wrong this should fix nodraw

        local iFlashPFX =   ParticleManager:CreateParticle("particles/heroes/anime_hero_vergil/vergil_jc_end_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
                            ParticleManager:SetParticleControlEnt(  iFlashPFX,
                                                                    0,
                                                                    self.caster,
                                                                    PATTACH_POINT_FOLLOW,
                                                                    "attach_attack1",
                                                                    Vector(0,0,0),
                                                                    true )
                            ParticleManager:SetParticleControl(iFlashPFX, 1, Vector(self.radius, 0, 0))
                            ParticleManager:ReleaseParticleIndex(iFlashPFX)
        
        EmitSoundOn("saito_jce_release", self.caster)
    end
end

LinkLuaModifier("modifier_saito_jce_enemy", "abilities/saito/vergil_saito/saito_jce", LUA_MODIFIER_MOTION_NONE)

modifier_saito_jce_enemy = class({})

function modifier_saito_jce_enemy:IsHidden() return false end
function modifier_saito_jce_enemy:IsDebuff() return true end

function modifier_saito_jce_enemy:CheckState()
    local hState =  {
                        [MODIFIER_STATE_STUNNED]       = true,
                        [MODIFIER_STATE_FROZEN]        = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true
                    }
    return hState
end

function modifier_saito_jce_enemy:OnRemoved()
	if not IsServer() then return end
	
	local ability = self:GetAbility()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local damage = ability:GetSpecialValueFor("damage")

	EmitSoundOn("saito_jce_release", parent)

	DoDamage(caster, parent, damage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_NONE, ability, false)

    local iTotalDamageDeposit_Release_PFX = ParticleManager:CreateParticle("particles/saito/vergil_saito/saito_jce_release.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:ReleaseParticleIndex(iTotalDamageDeposit_Release_PFX)
end

LinkLuaModifier("modifier_saito_jce_cd", "abilities/saito/vergil_saito/saito_jce", LUA_MODIFIER_MOTION_NONE)

modifier_saito_jce_cd = class({})

function modifier_saito_jce_cd:GetTexture()
	return "custom/saito/saito_style"
end

function modifier_saito_jce_cd:IsHidden()
	return false 
end

function modifier_saito_jce_cd:RemoveOnDeath()
	return false
end

function modifier_saito_jce_cd:IsDebuff()
	return true 
end

function modifier_saito_jce_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
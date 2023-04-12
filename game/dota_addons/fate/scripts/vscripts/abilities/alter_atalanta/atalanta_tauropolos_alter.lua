LinkLuaModifier("modifier_tauropolos_alter", "abilities/alter_atalanta/atalanta_tauropolos_alter", LUA_MODIFIER_MOTION_NONE)

atalanta_tauropolos_alter = class({})

function atalanta_tauropolos_alter:CastFilterResult()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_tauropolos_alter") then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function atalanta_tauropolos_alter:GetCustomCastError()
	return "Only one instance of Tauropolos can exist at one time"
end

function atalanta_tauropolos_alter:OnAbilityPhaseStart()
    
    if( self:GetCaster():HasModifier( "modifier_atalanta_jump")) then
        
         EmitSoundOn("atalanta_ultimate_"..math.random(1,2),  self:GetCaster())
    else
        self:GetCaster():EmitSound("atalanta_ultimate_"..math.random(1,2))
    end
    return true
end

function atalanta_tauropolos_alter:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("atalanta_ultimate_1")
    self:GetCaster():StopSound("atalanta_ultimate_2")
end

function atalanta_tauropolos_alter:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_tauropolos_alter", {duration = self:GetSpecialValueFor("duration")})
end

modifier_tauropolos_alter = class({})
function modifier_tauropolos_alter:IsHidden() return true end
function modifier_tauropolos_alter:IsDebuff() return false end
function modifier_tauropolos_alter:RemoveOnDeath() return true end
function modifier_tauropolos_alter:OnCreated()
    if IsServer() then
        self.radius = self:GetAbility():GetAOERadius()
        self.caster = self:GetCaster()
        self.parent = self:GetParent()
        self.frametime = 1
        self.frametime_mana = 0
        self.interval = 0.15
        self.damage = self:GetAbility():GetSpecialValueFor("damage")
        self.min_dist = self:GetAbility():GetSpecialValueFor("min_dist")
        self.max_dist = self:GetAbility():GetSpecialValueFor("max_dist")
        self.explosion_radius = self:GetAbility():GetSpecialValueFor("explosion_radius")
        self.target_loc = self:GetParent():GetAbsOrigin()
        self.quadrant = 1  -- Quadrants 1: NW, 2: NE, 3: SE, 4: SW

        self:StartIntervalThink(0.5)
    end
end
function modifier_tauropolos_alter:OnIntervalThink()
    if IsServer() then
        if not self:GetCaster() or not self:GetCaster():IsAlive() then
            self:Destroy()
        end

        local firestorm_fx = ParticleManager:CreateParticle("particles/atalanta/abyssal_underlord_firestorm_wave.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl( firestorm_fx, 0, self.target_loc)
        ParticleManager:SetParticleControl( firestorm_fx, 4, Vector(self.max_dist, 0, 0))

        Timers:CreateTimer(1.0, function()
            ParticleManager:DestroyParticle(firestorm_fx, false)
            ParticleManager:ReleaseParticleIndex(firestorm_fx)
        end)
       
        for pepega = 1,8 do
           	local castDistance = RandomInt(self.min_dist, self.max_dist)
            local angle = RandomInt(0, 90)
            local dy = castDistance * math.sin(angle)
            local dx = castDistance * math.cos(angle)
            local attackPoint = Vector(0, 0, 0)

            if self.quadrant == 1 then          -- NW
                attackPoint = Vector( self.target_loc.x - dx, self.target_loc.y + dy, self.target_loc.z )
            elseif self.quadrant == 2 then      -- NE
                attackPoint = Vector( self.target_loc.x + dx, self.target_loc.y + dy, self.target_loc.z )
            elseif self.quadrant == 3 then      -- SE
                attackPoint = Vector( self.target_loc.x + dx, self.target_loc.y - dy, self.target_loc.z )
            else                                -- SW
                attackPoint = Vector( self.target_loc.x - dx, self.target_loc.y - dy, self.target_loc.z )
            end

            self.quadrant = 4 % (self.quadrant + 1)

            Timers:CreateTimer(0.02*pepega, function()
                EmitSoundOnLocationWithCaster(attackPoint, "Ability.Powershot.Alt", self.caster)
                local iPillarFx = ParticleManager:CreateParticle("particles/atalanta/ruler_purge_the_unjust_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
                ParticleManager:SetParticleControl( iPillarFx, 0, attackPoint)
                ParticleManager:SetParticleControl( iPillarFx, 1, attackPoint)
                ParticleManager:SetParticleControl( iPillarFx, 2, attackPoint)

                Timers:CreateTimer(1.0, function()
                    ParticleManager:DestroyParticle(iPillarFx, false)
                    ParticleManager:ReleaseParticleIndex(iPillarFx)
                end)
            end)
        end

		Timers:CreateTimer(0, function()
			local units = FindUnitsInRadius(self.caster:GetTeam(),
                                        self.target_loc, 
                                        nil, 
                                        self.max_dist, 
                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                        DOTA_UNIT_TARGET_ALL, 
                                        DOTA_UNIT_TARGET_FLAG_NONE, 
                                        0, 
                                        false)

		    for _,unit in pairs(units) do
                if not unit:HasModifier("modifier_protection_from_arrows_active") then
    		     	DoDamage(self.caster, unit, self.damage + (self.caster.CursedMoonAcquired and 60 or 0), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    		      	for i = 1,(self:GetAbility():GetSpecialValueFor("curse_stacks") + (self.caster.CursedMoonAcquired and 5 or 0)) do
    		           	self.caster:FindAbilityByName("atalanta_curse"):Curse(unit)
                        --[[if self.caster.CursedMoonAcquired then
                            self.caster:FindAbilityByName("atalanta_curse"):Curse(unit)
                        end]]
    		 	    end
                end
		    end
		end)
    end
end
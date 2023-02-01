LinkLuaModifier("modifier_khsn_ambush", "abilities/kinghassan/khsn_ambush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_ambush_as", "abilities/kinghassan/khsn_ambush", LUA_MODIFIER_MOTION_NONE)

khsn_ambush = class({})

function khsn_ambush:OnSpellStart()
	local caster = self:GetCaster()

	local fade_delay = self:GetSpecialValueFor("fade_delay")
    caster:EmitSound("KingHassan.WSFX")

	--Timers:CreateTimer(fade_delay, function()
		if caster:IsAlive() then
			caster:AddNewModifier(caster, self, "modifier_khsn_ambush", {duration = self:GetSpecialValueFor("duration")})
		end
	--end)
end

khsn_ambush_blink = class({})

function khsn_ambush_blink:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function khsn_ambush_blink:GetCustomCastErrorLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if IsServer() and IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) then
            return "#Is_Locked"
        end
    end
    return "#Wrong_Target_Location"
end

function khsn_ambush_blink:OnSpellStart()
	local hCaster = self:GetCaster()
    local ability = self
    local targetpoint = self:GetCursorPosition()



    local particle = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/pa_crimson_witness_2021/pa_crimson_witness_blur_ambient_fleks.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(particle, 3, hCaster:GetAbsOrigin())
    local particle1 = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_death_black_steam.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(particle1, 3, hCaster:GetAbsOrigin())

    hCaster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
    local tParams = {
        sInEffect = "particles/units/heroes/hero_dragon_knight/dragon_knight_loadout.vpcf",   --NAGASIREN MIRROR IMAGE AND BLACKFOGS
        sOutEffect = "particles/units/heroes/hero_dragon_knight/dragon_knight_loadout.vpcf"
    }

	local fRange = ability:GetSpecialValueFor("range")
	if hCaster.BoundaryAcquired then
		fRange = fRange + 300
	end
 	AbilityBlink(hCaster,targetpoint, fRange, tParams)


	Timers:CreateTimer( 0.1, function()
    	ParticleManager:SetParticleControl(particle, 3, hCaster:GetAbsOrigin())
    	ParticleManager:SetParticleControl(particle1, 3, hCaster:GetAbsOrigin())
	end
	)
	Timers:CreateTimer(300, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		ParticleManager:DestroyParticle(particle1, false)
		ParticleManager:ReleaseParticleIndex(particle1)
	end)
end

modifier_khsn_ambush = class({})

function modifier_khsn_ambush:DeclareFunctions()
    local funcs = {}
    funcs = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_EVENT_ON_ATTACK,
            --MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
            --MODIFIER_EVENT_ON_TAKEDAMAGE
            }
    return funcs
end

function modifier_khsn_ambush:CheckState()
   	return { [MODIFIER_STATE_INVISIBLE] = true,
    		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    		 }
end

if IsServer() then
    function modifier_khsn_ambush:OnCreated(table)     
        local caster = self:GetParent()

        if not (caster:GetAbilityByIndex(0):GetName() == "khsn_ambush_blink") then
        	caster:SwapAbilities("khsn_ambush", "khsn_ambush_blink", false, true)
        end
    end

    function modifier_khsn_ambush:OnAttackLanded(args)	
        local caster = self:GetParent()
        if args.attacker ~= self:GetParent() then return end

        local target = args.target
        if caster == target then return end

        --DoDamage(caster, target, self.bonusDamage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
        --target:EmitSound("Hero_TemplarAssassin.Meld.Attack")
        self:Destroy()
    end

    function modifier_khsn_ambush:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then
        	if args.ability:GetName() ~= "khsn_ambush" then
            	self:Destroy()
            end
        end
    end

    function modifier_khsn_ambush:OnDestroy()
        local caster = self:GetParent()
        
        if not (caster:GetAbilityByIndex(0):GetName() == "khsn_ambush") then
        	caster:SwapAbilities("khsn_ambush", "khsn_ambush_blink", true, false)
        end
        if caster.BoundaryAcquired then
        	caster:AddNewModifier(caster, self:GetAbility(), "modifier_khsn_ambush_as", {duration = self:GetAbility():GetSpecialValueFor("attr_duration")})
        end
    end
end

function modifier_khsn_ambush:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end

-----------------------------------------------------------------------------------
function modifier_khsn_ambush:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_khsn_ambush:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_khsn_ambush:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_khsn_ambush:IsPurgable()
    return true
end

function modifier_khsn_ambush:IsDebuff()
    return false
end

function modifier_khsn_ambush:RemoveOnDeath()
    return true
end

function modifier_khsn_ambush:GetTexture()
    return "custom/true_assassin_ambush"
end
-----------------------------------------------------------------------------------

modifier_khsn_ambush_as = class({})

function modifier_khsn_ambush_as:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_khsn_ambush_as:IsHidden() return false end
function modifier_khsn_ambush_as:IsDebuff() return false end

function modifier_khsn_ambush_as:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attr_as")
end
LinkLuaModifier("modifier_khsn_ambush", "abilities/kinghassan/khsn_ambush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_ambush_block", "abilities/kinghassan/khsn_ambush", LUA_MODIFIER_MOTION_NONE)

khsn_ambush = class({})

function khsn_ambush:OnSpellStart()
	local caster = self:GetCaster()

	local fade_delay = self:GetSpecialValueFor("fade_delay")
    caster:EmitSound("KingHassan.WSFX")

	--Timers:CreateTimer(fade_delay, function()
		if caster:IsAlive() then
			caster:AddNewModifier(caster, self, "modifier_khsn_ambush", {duration = self:GetSpecialValueFor("duration")})
            if caster.BoundaryAcquired then
                caster:AddNewModifier(caster, self, "modifier_item_ward_true_sight", {true_sight_range = self:GetSpecialValueFor("attribute_true_sight_range"), duration = self:GetSpecialValueFor("attribute_true_sight_duration")})
            end
		end
	--end)
    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("khsn_combo_arena"):IsCooldownReady()  
	    	and caster:GetAbilityByIndex(4):GetName() == "khsn_bc" then
			caster:SwapAbilities("khsn_bc", "khsn_combo_arena", false, true)
			Timers:CreateTimer(3, function()
				if caster:GetAbilityByIndex(4):GetName() ~= "khsn_combo_arena_recast" then
					caster:SwapAbilities("khsn_bc", "khsn_combo_arena", true, false)
				end
			end)
		end
	end
end

modifier_khsn_ambush = class({})

function modifier_khsn_ambush:DeclareFunctions()
    local funcs = {}
    funcs = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
            }
    return funcs
end

function modifier_khsn_ambush:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_range")
end

function modifier_khsn_ambush:CheckState()
    if not IsServer() then return end

    return self.state
end

if IsServer() then
    function modifier_khsn_ambush:OnCreated(table)     
        local caster = self:GetParent()
        self.ability = self:GetAbility()

        self.state = {[MODIFIER_STATE_INVISIBLE] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true}

        if not (caster:GetAbilityByIndex(0):GetName() == "khsn_ambush_blink") then
        	--caster:SwapAbilities("khsn_ambush", "khsn_ambush_blink", false, true)
        end

        self:StartIntervalThink(self.ability:GetSpecialValueFor("invis_duration"))
    end

    function modifier_khsn_ambush:OnRefresh()
        self:OnCreated()
    end

    function modifier_khsn_ambush:OnIntervalThink()
        self.state = {}
    end

    function modifier_khsn_ambush:OnAttackLanded(args)	
        local caster = self:GetParent()
        if args.attacker ~= self:GetParent() then return end

        local target = args.target
        if caster == target then return end

        self.state = {}

        local damage = self.ability:GetSpecialValueFor("damage")

        local position = target:GetAbsOrigin() - target:GetForwardVector()*50

        LoopOverPlayers(function(player, playerID, playerHero)
            if playerHero.zlodemon == true    then
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_q" })
            end
        end)

        local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_trail_scepter.vpcf", PATTACH_ABSORIGIN, caster )
        ParticleManager:SetParticleControl( slashFx, 0, caster:GetAbsOrigin())
        ParticleManager:SetParticleControl( slashFx, 1, position)

        local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
        ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

        FindClearSpaceForUnit(caster, position, true)
        caster:FaceTowards(target:GetAbsOrigin())

        EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_SkeletonKing.Hellfire_BlastImpact", caster)
        LoopOverPlayers(function(player, playerID, playerHero)
            if playerHero.zlodemon == true   then
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_e_backstab" })
            end
        end)
        caster:AddNewModifier(caster, self.ability, "modifier_khsn_ambush_block", {duration = self.ability:GetSpecialValueFor("shield_duration")})

        local particle_name = "particles/kinghassan/khsn_shadowraze.vpcf"
        if caster:HasModifier("modifier_hero_selection_skin") then
            particle_name = "particles/zlodemon/yujiro/yujiro_slam.vpcf"
        end
        local burn_fx = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, target)
        ParticleManager:SetParticleControl(burn_fx, 0, target:GetAbsOrigin())

        local particle_name_2 = "particles/kinghassan/khsn_flame_kappa.vpcf"
        local vector = Vector(0,0,1000)
        if caster:HasModifier("modifier_hero_selection_skin") then
            particle_name_2 = "particles/yujiro/yujiro_flame_ambush.vpcf"
            vector = target:GetForwardVector() * 100
        end
        local flame_fx = ParticleManager:CreateParticle(particle_name_2, PATTACH_ABSORIGIN, target)
        ParticleManager:SetParticleControl(flame_fx, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControl(flame_fx, 1, vector)

        DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

        self:Destroy()
    end

    function modifier_khsn_ambush:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then
        	if args.ability:GetName() ~= "khsn_ambush" and args.ability:GetName() ~= "khsn_mde_end" then
            	self.state = {}
            end
        end
    end

    function modifier_khsn_ambush:OnDestroy()
        local caster = self:GetParent()
        
        --if not (caster:GetAbilityByIndex(0):GetName() == "khsn_ambush") then
        --	caster:SwapAbilities("khsn_ambush", "khsn_ambush_blink", true, false)
        --end
        --[[if caster.BoundaryAcquired then
        	caster:AddNewModifier(caster, self:GetAbility(), "modifier_khsn_ambush_as", {duration = self:GetAbility():GetSpecialValueFor("attr_duration")})
        end]]
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

modifier_khsn_ambush_block = class({})

function modifier_khsn_ambush_block:IsHidden() return false end
function modifier_khsn_ambush_block:IsDebuff() return false end

function modifier_khsn_ambush_block:OnCreated()

end

function modifier_khsn_ambush_block:DeclareFunctions()
    local hFunc =   {   
                        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
                    }
    return hFunc
end
function modifier_khsn_ambush_block:GetModifierIncomingDamageConstant(keys)
    if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
                blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
                blocked = keys.original_damage--block_now
                local damage = keys.original_damage - block_now
                local dmgtable = {
                    attacker = keys.attacker,
                    victim = keys.target,
                    damage = damage,
                    damage_type = keys.damage_type,
                    damage_flags = keys.damage_flags,
                    ability = keys.inflictor
                }
                self:Destroy()
                ApplyDamage(dmgtable)
            end

            return -1*blocked
        end
    else
        return self:GetStackCount()
    end
end
function modifier_khsn_ambush_block:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if not self.fBarrierBlock then
        self.fBarrierBlock = 0
    end

    self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield")
    
    if not self.iShieldPFX then
        self.iShieldPFX = ParticleManager:CreateParticle( "particles/king_hassan/khsn_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
        ParticleManager:SetParticleControl(self.iShieldPFX, 0, self.hParent:GetAbsOrigin())

        self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
    else
        local flashFX = ParticleManager:CreateParticle("particles/kinghassan/khsn_shield_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
        ParticleManager:SetParticleControl(flashFX, 0, self.hParent:GetAbsOrigin())

        ParticleManager:ReleaseParticleIndex(flashFX)
    end

    if IsServer() then
        self:SetStackCount(self.fBarrierBlock)
    end
end
function modifier_khsn_ambush_block:OnRefresh(hTable)
    self:OnCreated(hTable)
end
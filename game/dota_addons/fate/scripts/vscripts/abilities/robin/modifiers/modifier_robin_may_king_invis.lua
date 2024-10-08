-----------------------------
--    Modifier: May King Invis    --
-----------------------------

modifier_robin_may_king_invis = class({})

function modifier_robin_may_king_invis:DeclareFunctions()
    return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

if IsServer() then
    function modifier_robin_may_king_invis:OnCreated(table)     
        self.bonusDamage = table.bonusDamage
        self:StartIntervalThink(table.fadeDelay)
    end

    function modifier_robin_may_king_invis:OnIntervalThink()
    	local caster = self:GetParent()
		local hCaster = self:GetParent()

    	self.state = { [MODIFIER_STATE_INVISIBLE] = true,
    					  [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    					}
    end

    function modifier_robin_may_king_invis:CheckState()
    	return self.state
    end

    function modifier_robin_may_king_invis:OnTakeDamage(args)
        if args.unit ~= self:GetParent() then return end

        local damageTaken = args.original_damage
        if damageTaken > self:GetAbility():GetSpecialValueFor("break_threshold") then
            self:Destroy()
        end
    end
end

-----------------------------------------------------------------------------------
function modifier_robin_may_king_invis:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_robin_may_king_invis:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_robin_may_king_invis:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_robin_may_king_invis:IsPurgable()
    return true
end

function modifier_robin_may_king_invis:IsDebuff()
    return false
end

function modifier_robin_may_king_invis:RemoveOnDeath()
    return true
end

function modifier_robin_may_king_invis:GetTexture()
    return "custom/robin/robin_may_king"
end
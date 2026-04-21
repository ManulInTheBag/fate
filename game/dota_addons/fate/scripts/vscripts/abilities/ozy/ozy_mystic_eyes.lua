LinkLuaModifier("modifier_ozy_mystic_eyes","abilities/ozy/ozy_mystic_eyes", LUA_MODIFIER_MOTION_NONE)
ozy_mystic_eyes = class({})

function ozy_mystic_eyes:OnMysticEyesProck(target)
	local caster = self:GetCaster()
	target:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
	local particle = ParticleManager:CreateParticle("particles/ozy/ozy_mystic_eyes_target.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleShouldCheckFoW(particle, false)
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		
	end)
end

function ozy_mystic_eyes:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_ozy_mystic_eyes", { Duration = self:GetSpecialValueFor("duration") })
	

end


modifier_ozy_mystic_eyes = class({})

function modifier_ozy_mystic_eyes:IsHidden()
	return false 
end

function modifier_ozy_mystic_eyes:RemoveOnDeath()
	return true
end
function modifier_ozy_mystic_eyes:GetEffectName()
    return "particles/zlodemon/immunity_sphere_buff_sun.vpcf"
end
function modifier_ozy_mystic_eyes:GetEffectAttachType()
    return PATTACH_CUSTOMORIGIN_FOLLOW
end



function modifier_ozy_mystic_eyes:IsDebuff() 
	return false
end




function modifier_ozy_mystic_eyes:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end


function modifier_ozy_mystic_eyes:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()


end
function modifier_ozy_mystic_eyes:OnRefresh(hTable)
	self:OnCreated(hTable)
end


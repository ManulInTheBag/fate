------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_renvor", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_renvor = class({})
function modifier_renvor:IsHidden() return true end
function modifier_renvor:IsDebuff() return false end
function modifier_renvor:IsPurgable() return false end
function modifier_renvor:IsPurgeException() return false end
function modifier_renvor:RemoveOnDeath() return false end
function modifier_renvor:OnCreated(table)
	if IsServer() then
 

	local particleName = "particles/zlodemon/modifier_renvor.vpcf"
 
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    --ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
	end
end
function modifier_renvor:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, false )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_hvick", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_hvick = class({})
function modifier_hvick:IsHidden() return true end
function modifier_hvick:IsDebuff() return false end
function modifier_hvick:IsPurgable() return false end
function modifier_hvick:IsPurgeException() return false end
function modifier_hvick:RemoveOnDeath() return false end
function modifier_hvick:OnCreated(table)
	if IsServer() then
 

	local particleName = "particles/zlodemon/modifier_hvick.vpcf"
 
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    --ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
	end
end
function modifier_hvick:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, false )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end
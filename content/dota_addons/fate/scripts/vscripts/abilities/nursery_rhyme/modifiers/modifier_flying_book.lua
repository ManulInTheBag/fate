------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_rhyme_flying_book", "abilities/nursery_rhyme/modifiers/modifier_flying_book.lua", LUA_MODIFIER_MOTION_NONE)

modifier_rhyme_flying_book = class({})
function modifier_rhyme_flying_book:IsHidden() return true end
function modifier_rhyme_flying_book:IsDebuff() return false end
function modifier_rhyme_flying_book:IsPurgable() return false end
function modifier_rhyme_flying_book:IsPurgeException() return false end
function modifier_rhyme_flying_book:RemoveOnDeath() return false end
function modifier_rhyme_flying_book:OnCreated(table)
	if IsServer() then

	--[[local book_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_wex_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(book_particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_orb1", self:GetParent():GetAbsOrigin(), false)]]

	local particleName = "particles/rhyme/flying_book_normal.vpcf"

	local num_books = 1
	
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( self.pfx, 1, Vector( num_books, 0, 0 ) )
	for i=1, num_books do
		ParticleManager:SetParticleControl( self.pfx, 8+i, Vector( 1, 0, 0 ) )
	end

	--self:AddParticle(pfx, false, false, -1, false, false)
	end
end
function modifier_rhyme_flying_book:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, false )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end
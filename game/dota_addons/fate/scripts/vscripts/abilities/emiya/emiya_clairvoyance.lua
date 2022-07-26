emiya_clairvoyance = class({})

LinkLuaModifier("modifier_hrunting_window", "abilities/emiya/modifiers/modifier_hrunting_window", LUA_MODIFIER_MOTION_NONE)

function emiya_clairvoyance:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function emiya_clairvoyance:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local targetLoc = self:GetCursorPosition()

	if caster:HasModifier("modifier_hrunting_attribute") then
		--caster:SwapAbilities("emiya_clairvoyance", "emiya_hrunting", false, true) 
		caster:AddNewModifier(caster, self, "modifier_hrunting_window", { Duration = self:GetSpecialValueFor("duration") })
	end

	if ClairUsed(caster:GetTeamNumber(), self:GetSpecialValueFor("duration")) then
		--self:EndCooldown() 
		--caster:GiveMana(100)
		SendErrorMessage(caster:GetPlayerOwnerID(), "#another_clair_used")
		return
	end

	local visiondummy = SpawnVisionDummy(caster, targetLoc, radius, self:GetSpecialValueFor("duration"), caster:HasModifier("modifier_eagle_eye"))
	
	local circleFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_clairvoyance_circle.vpcf", PATTACH_CUSTOMORIGIN, visiondummy )
	ParticleManager:SetParticleControl( circleFxIndex, 0, visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( circleFxIndex, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( circleFxIndex, 2, Vector( 8, 0, 0 ) )
	ParticleManager:SetParticleControl( circleFxIndex, 3, Vector( 100, 255, 255 ) )
	
	local dustFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_clairvoyance_dust.vpcf", PATTACH_CUSTOMORIGIN, visiondummy )
	ParticleManager:SetParticleControl( dustFxIndex, 0, visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( dustFxIndex, 1, Vector( radius, radius, radius ) )
	
	visiondummy.circle_fx = circleFxIndex
	visiondummy.dust_fx = dustFxIndex
	ParticleManager:SetParticleControl( dustFxIndex, 1, Vector( radius, radius, radius ) )
			
	-- Destroy particle after delay
	Timers:CreateTimer(self:GetSpecialValueFor("duration"), function()
		ParticleManager:DestroyParticle( circleFxIndex, false )
		ParticleManager:DestroyParticle( dustFxIndex, false )
		ParticleManager:ReleaseParticleIndex( circleFxIndex )
		ParticleManager:ReleaseParticleIndex( dustFxIndex )
		return nil
	end)

	EmitSoundOnLocationWithCaster(targetLoc, "Hero_KeeperOfTheLight.BlindingLight", visiondummy)
end
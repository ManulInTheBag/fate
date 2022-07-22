master_intervention = class({})

LinkLuaModifier("modifier_master_intervention", "abilities/master/modifiers/modifier_master_intervention", LUA_MODIFIER_MOTION_NONE)

local revokes = {
    "modifier_enkidu_hold",
    "rb_sealdisabled",
    "revoked",
    "round_pause",
    "modifier_nss_shock",
    "modifier_ubw_chronosphere"
}

function master_intervention:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then hero = caster.HeroUnit end

	for i = 1, #revokes do
		if hero:HasModifier(revokes[i]) then
			self:EndCooldown()
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
			return
		end
	end

	if not hero:IsAlive() then return end

	hero:EmitSound("Hero_Abaddon.AphoticShield.Cast")
	HardCleanse(hero)
	hero:RemoveModifierByName("modifier_zabaniya_curse")
	hero:AddNewModifier(caster, self, "modifier_master_intervention", { Duration = self:GetSpecialValueFor("duration") })
	local dispel = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_death_coil_explosion.vpcf", PATTACH_ABSORIGIN, hero )
    ParticleManager:SetParticleControl( dispel, 1, hero:GetAbsOrigin())

    Timers:CreateTimer( 2.0, function()
        ParticleManager:DestroyParticle( dispel, false )
        ParticleManager:ReleaseParticleIndex( dispel )
    end)

    if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end
end
arash_mobility_boost_active = class({})



function arash_mobility_boost_active:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local ability = self
    local speed = self:GetSpecialValueFor("speed")  
    local max_range = self:GetSpecialValueFor("range")  
    self.move_vector = (point - caster:GetAbsOrigin()):Normalized()
	self.rushfx = ParticleManager:CreateParticle("particles/arash/arash_rush_self.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
	local castfx = ParticleManager:CreateParticle("particles/arash/arash_rush_start.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControl(castfx, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(castfx)
    local castfx2 = ParticleManager:CreateParticle("particles/arash/arash_rush_start_2.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlTransformForward(castfx2, 1, caster:GetAbsOrigin(),self.move_vector)
	ParticleManager:ReleaseParticleIndex(castfx2)
    caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
	local rush_time = max_range/speed
    StartAnimation(caster, {duration=rush_time, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=1.0})
    if caster:HasModifier("modifier_arash_mobility_boost") then
        caster:RemoveModifierByName("modifier_arash_mobility_boost")
    end
    caster:EmitSound("arash_dash")
    giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", rush_time)
    local knockback = { should_stun = false,
				knockback_duration = rush_time,
				duration = rush_time,
				knockback_distance = -max_range,
				knockback_height = 0,
				center_x = point.x,
				center_y = point.y,
			    center_z = point.z}
    caster:AddNewModifier(caster, self, "modifier_knockback", knockback)	            
    Timers:CreateTimer(rush_time, function()
        ParticleManager:DestroyParticle(  self.rushfx , true)
        ParticleManager:ReleaseParticleIndex(  self.rushfx )
    end)
 
 

end


function arash_mobility_boost_active:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil then return end
    local caster = self:GetCaster()
    local damage = caster:FindAbilityByName("arash_independent_action"):GetSpecialValueFor("second_damage")
    hTarget:EmitSound("arash_attack")

    DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

    return true
end
 
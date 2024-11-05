demon_king_combo = class({})

---LinkLuaModifier("modifier_demon_king_materialization", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)

function demon_king_combo:OnSpellStart()
    local caster = self:GetCaster()
    self.castfx = ParticleManager:CreateParticle("particles/demon_king_nobunaga/combo_kostya_spawn_ground.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(self.castfx, 0, caster:GetAbsOrigin()+caster:GetForwardVector()*-300)
    ParticleManager:SetParticleControl(self.castfx, 1, Vector(133,0,0))
end

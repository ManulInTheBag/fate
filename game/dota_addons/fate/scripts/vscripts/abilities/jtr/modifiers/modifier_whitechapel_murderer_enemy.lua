modifier_whitechapel_murderer_enemy = class({})

--[[local tFemaleServant = {
	"npc_dota_hero_legion_commander",
    "npc_dota_hero_spectre",
    "npc_dota_hero_templar_assassin",
    "npc_dota_hero_crystal_maiden",
    "npc_dota_hero_lina",
    "npc_dota_hero_enchantress",
    "npc_dota_hero_mirana",
    "npc_dota_hero_windrunner",
    "npc_dota_hero_drow_ranger",
    "npc_dota_hero_phantom_assassin",
    "npc_dota_hero_naga_siren",
    "npc_dota_hero_riki",
}

function modifier_whitechapel_murderer_enemy:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end]]
function modifier_whitechapel_murderer_enemy:IsDebuff() return true end
if IsServer() then
	function modifier_whitechapel_murderer_enemy:OnCreated(args)
		self.OriginalVision = self:GetParent():GetDayTimeVisionRange()

        if self:GetParent():HasModifier("modifier_murderer_mist") then
            self.modifier = self:GetParent():FindModifierByName("modifier_murderer_mist")
            self.OriginalVision = self.modifier.base_range_day
            print(self.OriginalVision)
        end

        self.vision_range = math.min(self.OriginalVision, 600)

		self:GetParent():SetDayTimeVisionRange(self.vision_range)
		self:GetParent():SetNightTimeVisionRange(self.vision_range)
        --self:StartIntervalThink(0.49)
	end

    --[[function modifier_whitechapel_murderer_enemy:OnIntervalThink()
        self:GetParent():SetDayTimeVisionRange(self.vision_range)
        self:GetParent():SetNightTimeVisionRange(self.vision_range)
    end]]
    function modifier_whitechapel_murderer_enemy:OnRefresh()
    end

	function modifier_whitechapel_murderer_enemy:OnDestroy()
		self:GetParent():SetDayTimeVisionRange(self.OriginalVision)		
		self:GetParent():SetNightTimeVisionRange(self.OriginalVision)
	end
end

--[[function modifier_whitechapel_murderer_enemy:GetModifierProvidesFOWVision()
    for i=1, #tFemaleServant do
        if self:GetParent():GetName() == tFemaleServant[i] then
            return 1
        end
    end
    
    return 0
end]]

function modifier_whitechapel_murderer_enemy:GetTexture()
    return "custom/jtr/whitechapel_murderer"
end
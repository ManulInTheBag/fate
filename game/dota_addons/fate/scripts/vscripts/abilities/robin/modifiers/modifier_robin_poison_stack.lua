-----------------------------
--    Modifier: Innate Poison    --
-----------------------------

modifier_robin_poison_stack = class({})

require("libraries/effect_bars")

-- Стаки яда показывает ряд эффектов над хелсбаром (libraries/effect_bars.lua +
-- panorama effect_bars.js). Потолок 30, с атрибутом Yew Bow - 50 (так режут
-- multishot / its_a_trap / mysterious_substance); атрибут живёт на Робине,
-- поэтому флаг для клиента ставит сервер.
function modifier_robin_poison_stack:OnCreated()
	if not IsServer() then return end
	EffectBars:Track(self)
	self:PublishCap()
end

function modifier_robin_poison_stack:OnRefresh()
	if not IsServer() then return end
	self:PublishCap()
end

function modifier_robin_poison_stack:PublishCap()
	local hCaster = self:GetCaster()
	local sa = IsNotNull(hCaster) and hCaster:HasModifier("modifier_robin_yew_bow_attribute")
	EffectBars:SetExtra(self:GetParent(), "robin_sa", sa and 1 or 0)
end

function modifier_robin_poison_stack:OnDestroy()
	if not IsServer() then return end
	EffectBars:Untrack(self)
end

function modifier_robin_poison_stack:IsDebuff()
    return true
end

function modifier_robin_poison_stack:RemoveOnDeath()
    return false
end

function modifier_robin_poison_stack:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_robin_poison_stack:IsHidden()
    return false
end

function modifier_robin_poison_stack:GetEffectName()
	return "particles/custom/robin/robin_yew_bow_poison.vpcf"
end

function modifier_robin_poison_stack:GetTexture()
    return "custom/robin/robin_poison_stack"
end
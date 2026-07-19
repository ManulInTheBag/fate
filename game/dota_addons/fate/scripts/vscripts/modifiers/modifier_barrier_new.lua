
-- локальная копия IsNotNull: глобальная есть не во всех VM (клиентская VM
-- модификаторов не грузит libraries/util), а OnDestroy исполняется в обеих
local function Barrier_IsNotNull(hScript)
	local sType = type(hScript)
	if sType ~= "nil" then
		if sType == "table" and type(hScript.IsNull) == "function" then
			return not hScript:IsNull()
		end
		return true
	end
	return false
end

modifier_barrier_new = class({})
function modifier_barrier_new:GetAttributes()                                                                  return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_barrier_new:IsHidden() return false end
function modifier_barrier_new:IsDebuff() return false end

function modifier_barrier_new:GetPriority() return MODIFIER_PRIORITY_ULTRA end

function modifier_barrier_new:OnCreated(args)
	self.state = {}
	self.bBroken = false

	self.decreaseDamageOnProck = args.decreaseDamageOnProck
	self.beforeBScroll = args.beforeBScroll
	self.ShouldEndChannel = args.ShouldEndChannel
	if args.debuff_immune then
		self.state = {[MODIFIER_STATE_DEBUFF_IMMUNE] =true }
	end
	self.fBarrierBlock = args.shield_amount
	self.HasCounter = args.HasCounter
	self.hAbility = self:GetAbility()

	if IsServer() then
		if self.fBarrierBlock == nil then
			self:Destroy()
			return
		end
		if self.fBarrierBlock <= 0 then
			self:Destroy()
		end
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_barrier_new:OnDestroy()
	if not IsServer() then return end
	if Barrier_IsNotNull(self.hAbility) and type(self.hAbility.OptionalDestroy) == "function" then
		self.hAbility:OptionalDestroy(self:GetParent())
	end
end

function modifier_barrier_new:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_barrier_new:CheckState()
	return self.state
end
function modifier_barrier_new:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            -- барьер пробит в этом же кадре, отложенный Destroy ещё не сработал:
            -- урон проходит без блока
            if self.bBroken then
                return 0
            end
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.original_damage--block_now
            	local damage = keys.original_damage - block_now
				local bRemoveBScroll = false
				if self.beforeBScroll then
            		local IsBScrollIgnored = false
					if keys.damage_type == DAMAGE_TYPE_MAGICAL then
						if keys.inflictor then
							-- inflictor не всегда ability (бывает модификатор) — у него нет GetAbilityName
							if type(keys.inflictor.GetAbilityName) == "function" and BIgnoreCheck(keys.inflictor) then
								IsBScrollIgnored = true
							end


							if IsBScrollIgnored == false and keys.target:HasModifier("modifier_b_scroll") then
								local originalDamage = damage - keys.target.BShieldAmount
								keys.target.BShieldAmount = keys.target.BShieldAmount - damage
								if keys.target.BShieldAmount <= 0 then
									damage = originalDamage
									bRemoveBScroll = true
								else
									damage = 0
								end
							end
						end
					end
				end
				damage = damage - self.decreaseDamageOnProck
				self.bBroken = true
				self:SetStackCount(0)
				self.fBarrierBlock = 0
				-- Каунтер, снятие канала, Destroy, снятие B-скролла и добивающий
				-- ApplyDamage нельзя вызывать из этого колбэка: движок в этот момент
				-- итерирует модификаторы юнита для текущего события урона, и
				-- вложенный пайплайн урона / удаление модификаторов под итерацией
				-- роняет сервер. Всё откладывается на следующий тик таймера.
				local hAbility         = self.hAbility
				local hParent          = self:GetParent()
				local bHasCounter      = (self.HasCounter == 1)
				local bShouldEndChannel = self.ShouldEndChannel
				local dmgtable = nil
				if damage > 0 then
					dmgtable = {
						attacker = keys.attacker,
						victim = keys.target,
						damage = damage,
						damage_type = keys.damage_type,
						damage_flags = keys.damage_flags,
						ability = keys.inflictor
					}
				end
				Timers:CreateTimer(0, function()
					if bRemoveBScroll and Barrier_IsNotNull(hParent) then
						hParent:RemoveModifierByName("modifier_b_scroll")
					end
					if bShouldEndChannel and Barrier_IsNotNull(hAbility) then
						hAbility:EndChannel(false)
					end
					if bHasCounter and Barrier_IsNotNull(hAbility) and Barrier_IsNotNull(hParent) then
						hAbility:Counter(hParent)
					end
					if Barrier_IsNotNull(self) then
						self:Destroy()
					end
					if dmgtable and Barrier_IsNotNull(dmgtable.victim) and dmgtable.victim:IsAlive() and Barrier_IsNotNull(dmgtable.attacker) then
						ApplyDamage(dmgtable)
					end
				end)
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end


function modifier_barrier_new:OnRefresh(hTable)
	self:OnCreated(hTable)
end


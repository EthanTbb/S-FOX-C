local GameLogic = {}


--**************    扑克类型    ******************--
--混合牌型
GameLogic.OX_VALUEO				= 0
--三条牌型
GameLogic.OX_THREE_SAME			= 102
--四条牌型
GameLogic.OX_FOUR_SAME			= 103
--天王牌型
GameLogic.OX_FOURKING			= 104
--天王牌型
GameLogic.OX_FIVEKING			= 105


--最大手牌数目
GameLogic.MAX_CARDCOUNT			= 5
--牌库数目
GameLogic.FULL_COUNT			= 52
--正常手牌数目
GameLogic.NORMAL_COUNT			= 5

--取模
function GameLogic:mod(a,b)
    return a - math.floor(a/b)*b
end
--获得牌的数值（1 -- 13）
function GameLogic:getCardValue(cbCardData)
    return self:mod(cbCardData, 16)
end

--获得牌的颜色（0 -- 4）
function GameLogic:getCardColor(cbCardData)
    return math.floor(cbCardData/16)
end
--获得牌的逻辑值
function GameLogic:getCardLogicValue(cbCardData)
	local cbCardValue = self:getCardValue(cbCardData)

	if cbCardValue > 10 then
		cbCardValue = 10
	end

	return cbCardValue
end
--拷贝表
function GameLogic:copyTab(st)
    local tab = {}
    for k, v in pairs(st) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = self:copyTab(v)
        end
    end
    return tab
 end
--获取牛牛
function GameLogic:getOxCard(cbCardData)
	local bTemp = {}
	local bTempData = self:copyTab(cbCardData)
	local bSum = 0
	for i = 1, 5 do
		bTemp[i] = self:getCardLogicValue(cbCardData[i])
		bSum = bSum + bTemp[i]
	end

	for i = 1, 5 - 1 do
		for j = i + 1, 5 do
			if self:mod(bSum - bTemp[i] - bTemp[j], 10) == 0 then
				local bCount = 1
				for k = 1, 5 do
					if k ~= i and k ~= j then
						cbCardData[bCount] = bTempData[k]
						bCount = bCount + 1
					end
				end
				cbCardData[4] = bTempData[i]
				cbCardData[5] = bTempData[j]
				return true
			end
		end
	end

	return false
end
--获取类型
function GameLogic:getCardType(cbCardData)
	local bKingCount = 0
	local bTenCount = 0
	for i = 1, 5 do
		if self:getCardValue(cbCardData[i]) > 10 then
			bKingCount = bKingCount + 1
		elseif self:getCardValue(cbCardData[i]) == 10 then
			bTenCount = bTenCount + 1
		end
	end
	if bKingCount == 5 then
		return GameLogic.OX_FIVEKING
	elseif bKingCount == 4 and bTenCount == 1 then
		return GameLogic.OX_FOURKING
	end

	local bTemp = {}
	local bSum = 0
	for i = 1, 5 do
		bTemp[i] = self:getCardLogicValue(cbCardData[i])
		bSum = bSum + bTemp[i]
	end

	for i = 1, 4 do
		for j = i + 1, 5 do
			if self:mod(bSum - bTemp[i] - bTemp[j], 10) == 0 then
				return bTemp[i] + bTemp[j] > 10 and bTemp[i] + bTemp[j] - 10 or bTemp[i] + bTemp[j]
			end
		end
	end

	return GameLogic.OX_VALUEO
end
return GameLogic
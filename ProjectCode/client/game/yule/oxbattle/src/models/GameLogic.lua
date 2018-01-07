local GameLogic = {}

--扑克类型
GameLogic.BRNN_CT_ERROR     = 0						--错误类型
GameLogic.BRNN_CT_POINT		= 1						--点数类型
GameLogic.BRNN_CT_SPECIAL_NIU1 = 2					--牛一
GameLogic.BRNN_CT_SPECIAL_NIU2 = 3					--牛二
GameLogic.BRNN_CT_SPECIAL_NIU3 = 4					--牛三
GameLogic.BRNN_CT_SPECIAL_NIU4 = 5					--牛四
GameLogic.BRNN_CT_SPECIAL_NIU5 = 6					--牛五
GameLogic.BRNN_CT_SPECIAL_NIU6 = 7					--牛六
GameLogic.BRNN_CT_SPECIAL_NIU7 = 8					--牛七
GameLogic.BRNN_CT_SPECIAL_NIU8 = 9					--牛八
GameLogic.BRNN_CT_SPECIAL_NIU9 = 10					--牛九
GameLogic.BRNN_CT_SPECIAL_NIUNIU = 11				--牛牛
GameLogic.BRNN_CT_SPECIAL_NIUNIUXW = 12				--小王牛
GameLogic.BRNN_CT_SPECIAL_NIUNIUDW = 13				--大王牛
GameLogic.BRNN_CT_SPECIAL_NIUYING = 14				--银牛
GameLogic.BRNN_CT_SPECIAL_NIUKING = 15				--金牛
GameLogic.BRNN_CT_SPECIAL_BOMEBOME = 16				--炸弹

-- 获取牌值(1-15)
function GameLogic.GetCardValue(nCardData)
	local lCardData = nCardData
	if lCardData == 0x41 then
		lCardData = 0x4E
	elseif lCardData == 0x42 then
		lCardData = 0x4F
	end
    return yl.POKER_VALUE[lCardData]
end

-- 获取花色(0-4)
function GameLogic.GetCardColor(nCardData)
	local lCardData = nCardData
	if lCardData == 0x41 then
		lCardData = 0x4E
	elseif lCardData == 0x42 then
		lCardData = 0x4F
	end
    return yl.CARD_COLOR[lCardData]
end

--获得牌的逻辑值
function GameLogic:GetCardLogicValue( cbCardData )	
	local cbCardValue = self.GetCardValue(cbCardData)
	local cbCardColor = self.GetCardColor(cbCardData)

	if cbCardValue > 10 then
		cbCardValue = 10
	end
	if cbCardColor == 0x4 then
		cbCardValue = 11
	end
	return cbCardValue
end

function GameLogic:GetCardNewValue( cbCardData )
	local cbCardValue = self.GetCardValue(cbCardData)
	local cbCardColor = self.GetCardColor(cbCardData)

	if cbCardColor == 0x4 then
		cbCardValue = cbCardValue + 2
	end
	return cbCardValue
end

--逻辑值排序
function GameLogic:SortCardList( cbCardData, cbCardCount)
	local cbSortValue = {}
    for i=1,cbCardCount do
        local value = self:GetCardNewValue(cbCardData[i])
        table.insert(cbSortValue, i, value)
    end
	
	--排序操作
	local bSorted = true;
	local cbLast = cbCardCount - 1;
	repeat
		bSorted = true;
		for i=1,cbLast do
			if (cbSortValue[i] < cbSortValue[i+1])
				or ((cbSortValue[i] == cbSortValue[i + 1]) and (cbCardData[i] < cbCardData[i + 1])) then
				--设置标志
				bSorted = false;

				--扑克数据
				cbCardData[i], cbCardData[i + 1] = cbCardData[i + 1], cbCardData[i];				

				--排序权位
				cbSortValue[i], cbSortValue[i + 1] = cbSortValue[i + 1], cbSortValue[i];
			end
		end
		cbLast = cbLast - 1;
	until bSorted ~= false;
end

function GameLogic:RetType(iType)
	local typeList = {}
	for i=1,10 do
		typeList[i] = GameLogic.BRNN_CT_POINT + i
	end
	typeList[0] = GameLogic.BRNN_CT_SPECIAL_NIUNIU
	iType = math.mod(iType, 10)
	return typeList[iType]
end

--获取牛类型
function GameLogic:GetCardType( cbCardData, cbCardCount)
	if cbCardCount ~= 5 then
		return self.BRNN_CT_ERROR
	end
	self:SortCardList(cbCardData, cbCardCount)
	local cbSortValue = {}
    for i=1,cbCardCount do
        local value = self:GetCardNewValue(cbCardData[i])
        table.insert(cbSortValue, i, value)
    end

	if (cbSortValue[1] == cbSortValue[cbCardCount-1]) 
		or (cbSortValue[2] == cbSortValue[cbCardCount]) then
		return self.BRNN_CT_SPECIAL_BOMEBOME
	end

	if self.GetCardColor(cbCardData[1]) == 0x4 and self.GetCardColor(cbCardData[2]) == 0x4 then
		if cbSortValue[3] == cbSortValue[4] then
			cbCardData[1], cbCardData[2], cbCardData[3], cbCardData[4] = cbCardData[3], cbCardData[4], cbCardData[1], cbCardData[2]
			return self.BRNN_CT_SPECIAL_BOMEBOME
		end
		if cbSortValue[4] == cbSortValue[5] then
			cbCardData[1], cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = cbCardData[4], cbCardData[5], cbCardData[1], cbCardData[2], cbCardData[3]
			return self.BRNN_CT_SPECIAL_BOMEBOME
		end
	end
	if self.GetCardColor(cbCardData[1]) == 0x4 then
		if cbSortValue[2] == cbSortValue[4] then
			cbCardData[1], cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[1], cbCardData[5]
			return self.BRNN_CT_SPECIAL_BOMEBOME
		end
		if cbSortValue[3] == cbSortValue[5] then
			cbCardData[1], cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = cbCardData[3], cbCardData[4], cbCardData[5], cbCardData[1], cbCardData[2]
			return self.BRNN_CT_SPECIAL_BOMEBOME
		end
	end

	local blBig = true
	local iCount = 0
	local iValueTen = 0
	for i=1,cbCardCount do
		local bcGetValue = self:GetCardLogicValue(cbCardData[i])
		if bcGetValue ~= 10 and bcGetValue ~= 11 then
			blBig = false
			break
		else
			if cbSortValue[i] == 10 then
				iValueTen = iValueTen + 1
			end
		end
		iCount = iCount + 1
	end
	if blBig == true then
		if iValueTen == 0 then
			return self.BRNN_CT_SPECIAL_NIUKING
		end
		if iValueTen == 1 then
			return self.BRNN_CT_SPECIAL_NIUYING
		end
	end

	--优先处理王， 王是癞子
	if self.GetCardColor(cbCardData[1]) == 0x4 then
		if self.GetCardColor(cbCardData[2]) == 0x4 then
			cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = cbCardData[4], cbCardData[5], cbCardData[2], cbCardData[3]
			return self.BRNN_CT_SPECIAL_NIUNIUDW
		end

		--任意两张组成10 ，则是牛牛
		for i=2, cbCardCount-1 do
			for j=i+1,cbCardCount do
				if math.mod(self:GetCardLogicValue(cbCardData[i]) + self:GetCardLogicValue(cbCardData[j]), 10) == 0 then
					local  temp = {}
					local count = 1
					for k=2,cbCardCount do
						if k ~= i and k ~= j then
							temp[count] = cbCardData[k]
							count = count + 1
						end
					end
					cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = temp[1], temp[2], cbCardData[i], cbCardData[j]
					if cbSortValue[1] == 0x11 then --大王
						return self.BRNN_CT_SPECIAL_NIUNIUDW
					end
					return self.BRNN_CT_SPECIAL_NIUNIUXW
				end
			end
		end

		--任意三张组成10，则是牛牛
		for i=2, cbCardCount-2 do
			for j=i+1,cbCardCount-1 do
				for k=j+1,cbCardCount do
					if math.mod(self:GetCardLogicValue(cbCardData[i]) + self:GetCardLogicValue(cbCardData[j]) + self:GetCardLogicValue(cbCardData[k]), 10) == 0 then
						cbCardData[1], cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = cbCardData[i], cbCardData[j], cbCardData[k], cbCardData[1], cbCardData[14-i-j-k]
						if cbSortValue[1] == 0x11 then --大王
							return self.BRNN_CT_SPECIAL_NIUNIUDW
						end
						return self.BRNN_CT_SPECIAL_NIUNIUXW
					end
				end
			end
		end

		--没有牛，则取最大点数
		local bigvalue = 0
		local temp = {}
		for i=2,cbCardCount-1 do
			for j=i+1,cbCardCount do
				local iValuePoint = math.mod(self:GetCardLogicValue(cbCardData[i]) + self:GetCardLogicValue(cbCardData[j]), 10)
				if  iValuePoint > bigvalue then
					bigvalue = iValuePoint
					temp[1] = i
					temp[2] = j
				end
			end
		end
		local  valuetemp = {}
		local count = 1
		for k=2,cbCardCount do
			if k ~= temp[1] and k ~= temp[1] then
				valuetemp[count] = cbCardData[k]
				count = count + 1
			end
		end
		cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = valuetemp[1], valuetemp[2], cbCardData[temp[1]], cbCardData[temp[2]]
		local cardtype = self:GetCardLogicValue(cbCardData[4])
		cardtype = cardtype + self:GetCardLogicValue(cbCardData[5])
		return self:RetType(cardtype)
	---没有癞子处理	
	else
		local bTemp = {}
		local bSum = 0
		for i = 1, cbCardCount do
			bTemp[i] = self:GetCardLogicValue(cbCardData[i])
			bSum = bSum + bTemp[i]
		end

		for i = 1, cbCardCount-1 do
			for j = i + 1, cbCardCount do
				if math.mod(bSum - bTemp[i] - bTemp[j], 10) == 0 then
					local nnpoint = bTemp[i] + bTemp[j] > 10 and bTemp[i] + bTemp[j] - 10 or bTemp[i] + bTemp[j]
					local  valuetemp = {}
					local count = 1
					for k=1,cbCardCount do
						if k ~= i and k ~= j then
							valuetemp[count] = cbCardData[k]
							count = count + 1
						end
					end
					cbCardData[1], cbCardData[2], cbCardData[3], cbCardData[4], cbCardData[5] = valuetemp[1], valuetemp[2], valuetemp[3], cbCardData[i], cbCardData[j]
					return self:RetType(bTemp[i]+bTemp[j])
				end
			end
		end
		return self.BRNN_CT_POINT
	end
end

--获取倍数
function GameLogic:getMultiple( cbTypeVale )
	local iMultiple = 0
	if cbTypeVale >= self.BRNN_CT_SPECIAL_NIUNIU then
		iMultiple = 10
	elseif cbTypeVale >= self.BRNN_CT_SPECIAL_NIU1 and cbTypeVale <= self.BRNN_CT_SPECIAL_NIU9 then
		iMultiple = cbTypeVale - 1
	else
		iMultiple = 1
	end
	return iMultiple
end

-- first > next  返回 -1
-- first < next  返回 1
function GameLogic:CompareCard(cbFirstCardData, cbFirstValue, cbNextCardData, cbNextValue)
	local cbCount = #cbFirstCardData
	if cbCount ~= 5 then
		return 0
	end
	cbCount = #cbNextCardData
	if cbCount ~= 5 then
		return 0
	end

	local iMultiple = 0
	local tFirstCardData = clone(cbFirstCardData)
	local tNextCardData = clone(cbNextCardData)
	local cbFirstCartType = cbFirstValue
	local cbNextCardType = cbNextValue
	if cbFirstCartType > cbNextCardType then
		iMultiple = self:getMultiple(cbFirstCartType)
		return -1, iMultiple
	elseif cbFirstCartType < cbNextCardType then
		iMultiple = self:getMultiple(cbNextCardType)
		return 1, iMultiple	
	elseif cbFirstCartType == cbNextCardType then
		iMultiple = self:getMultiple(cbFirstCartType)

		self:SortCardList(tFirstCardData, 5)
		self:SortCardList(tNextCardData, 5)
		local cbFirstValue = self:GetCardNewValue(tFirstCardData[1])
		local cbNextValue = self:GetCardNewValue(tNextCardData[1])
		local cbFirstColor = self.GetCardColor(tFirstCardData[1])
		local cbNextColor = self.GetCardColor(tNextCardData[1])

		if  cbFirstValue > cbNextValue	then
			return -1, iMultiple
		elseif  cbFirstValue == cbNextValue then
			if cbFirstColor > cbNextColor then
				return -1, iMultiple
			else
				return 1,iMultiple
			end
		else
			return 1, iMultiple
		end
	end
	return 0
end
return GameLogic
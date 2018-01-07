local GameLogic = {}

local cmd = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.CMD_Game")

--**************    扑克类型    ******************--

--牌库数目
GameLogic.FULL_COUNT			= 48

--拷贝表
function GameLogic:copyTab(st)
    local tab = {}
    for k, v in pairs(st) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = GameLogic:copyTab(v)
        end
    end
    return tab
 end

--取模
function GameLogic:mod(a,b)
    return a - math.floor(a/b)*b
end

--打印表
function GameLogic:printTable(table)
	for v, k in pairs(table) do
		if type(k) == "table" then
			print("v", v)
			GameLogic:printTable(k)
		elseif k ~= 0 then
			print("v, k", v, k)
		end
	end
end

--获得牌的颜色（0 -- 4）
function GameLogic:GetCardColor(cbCardData)
    return math.floor(cbCardData/16)
end

--获得牌的数值（1 -- 13）
function GameLogic:GetCardValue(cbCardData)
    return GameLogic:mod(cbCardData, 16)
end

--获得牌的逻辑数值
function GameLogic:GetCardLogicValue(cbCardData)
	local nValue = GameLogic:GetCardValue(cbCardData)
	return nValue <= 2 and nValue + 13 or nValue
end

--排列扑克
function GameLogic:SortCardList(cbCardData)
	if nil == cbCardData then
		return false
	end

	--转换数值
	local cbCardLogicValue = {}
	for i = 1, #cbCardData do
		cbCardLogicValue[i] = GameLogic:GetCardLogicValue(cbCardData[i])
	end

	--排序操作
	local bSorted = false
	local bLast = #cbCardData - 1
	while bSorted == false do
		bSorted = true
		for i = 1, bLast do
			if cbCardLogicValue[i] < cbCardLogicValue[i + 1] or 
			cbCardLogicValue[i] == cbCardLogicValue[i + 1] and cbCardData[i] < cbCardData[i + 1] then
				--交换位置
				cbCardData[i], cbCardData[i + 1] = cbCardData[i + 1], cbCardData[i]
				cbCardLogicValue[i], cbCardLogicValue[i + 1] = cbCardLogicValue[i + 1], cbCardLogicValue[i]
				bSorted = false
			end
		end
		bLast = bLast - 1
	end

	return true
end

--分析扑克
function GameLogic:AnalyseCardData(cbCardData)
	--初始化
	local analyseResult = {}
	analyseResult.bFourCount = 0
	analyseResult.bThreeCount = 0
	analyseResult.bDoubleCount = 0
	analyseResult.bSignedCount = 0
	analyseResult.bFourLogicValue = {}
	for i = 1, 4 do
		analyseResult.bFourLogicValue[i] = 0
	end
	analyseResult.bThreeLogicValue = {}
	for i = 1, 5 do
		analyseResult.bThreeLogicValue[i] = 0
	end
	analyseResult.bDoubleLogicValue = {}
	for i = 1, 8 do
		analyseResult.bDoubleLogicValue[i] = 0
	end
	analyseResult.bSignedLogicValue = {}
	for i = 1, 16 do
		analyseResult.bSignedLogicValue[i] = 0
	end
	analyseResult.bFourCardData = {}
	for i = 1, 16 do
		analyseResult.bFourCardData[i] = 0
	end
	analyseResult.bThreeCardData = {}
	for i = 1, 16 do
		analyseResult.bThreeCardData[i] = 0
	end
	analyseResult.bDoubleCardData = {}
	for i = 1, 16 do
		analyseResult.bDoubleCardData[i] = 0
	end
	analyseResult.bSignedCardData = {}
	for i = 1, 16 do
		analyseResult.bSignedCardData[i] = 0
	end

	--扑克分析
	local i = 1
	while i <= #cbCardData do
		--变量定义
		local bSameCount = 1
		local bSameCardData = {cbCardData[i], 0, 0, 0}
		local bLogicValue = GameLogic:GetCardLogicValue(cbCardData[i])

		--获取同牌
		for j = i + 1, #cbCardData do
			--逻辑对比
			if GameLogic:GetCardLogicValue(cbCardData[j]) ~= bLogicValue then
				break
			end
			--设置扑克
			bSameCardData[bSameCount + 1] = cbCardData[j]
			bSameCount = bSameCount + 1
		end

		--保存结果
		if bSameCount == 1 then 		--一张
			analyseResult.bSignedLogicValue[analyseResult.bSignedCount + 1] = bLogicValue
			analyseResult.bSignedCardData[analyseResult.bSignedCount + 1] = bSameCardData[1]
			analyseResult.bSignedCount = analyseResult.bSignedCount + 1
		elseif bSameCount == 2 then 			--二张
			analyseResult.bDoubleLogicValue[analyseResult.bDoubleCount + 1] = bLogicValue
			for k = 1, 2 do
				analyseResult.bDoubleCardData[analyseResult.bDoubleCount*2 + k] = bSameCardData[k]
			end
			analyseResult.bDoubleCount = analyseResult.bDoubleCount + 1
		elseif bSameCount == 3 then 			--三张
			analyseResult.bThreeLogicValue[analyseResult.bThreeCount + 1] = bLogicValue
			for k = 1, 3 do
				analyseResult.bThreeCardData[analyseResult.bThreeCount*3 + k] = bSameCardData[k]
			end
			analyseResult.bThreeCount = analyseResult.bThreeCount + 1
		elseif bSameCount == 4 then 			--四张
			analyseResult.bFourLogicValue[analyseResult.bFourCount + 1] = bLogicValue
			for k = 1, 4 do
				analyseResult.bFourCardData[analyseResult.bFourCount*4 + k] = bSameCardData[k]
			end
			analyseResult.bFourCount = analyseResult.bFourCount + 1
		end

		--设置递增
		i = i + bSameCount
	end

	return analyseResult
end

function GameLogic:RemoveCard(bRemoveCard, bCardData)
	if nil == bRemoveCard or nil == bCardData then
		return false
	end

	local bRemoveCount = #bRemoveCard
	local bCardCount = #bCardData
	--校验数据
	if bRemoveCount > bCardCount then
		return false
	end
	--定义变量
	local bDeleteCount = 0
	local bTempCardData = {}
	for i = 1, bCardCount do
		bTempCardData[i] = bCardData[i]
	end
	--置零扑克
	for i = 1, bRemoveCount do
		for j = 1, bCardCount do
			if bRemoveCard[i] == bTempCardData[j] then
				bDeleteCount = bDeleteCount + 1
				bTempCardData[j] = 0
				break
			end
		end
	end
	if bDeleteCount ~= bRemoveCount then
		return false
	end
	--清零扑克
	local bCardPos = 1
	for i = 1, bCardCount do
		if bTempCardData[i] ~= 0 then
			bCardData[bCardPos] = bTempCardData[i]
			bCardPos = bCardPos + 1
		end
	end
	for i = bCardPos, bCardCount do
		bCardData[i] = nil
	end

	return true
end

--获取类型
function GameLogic:GetCardType(cbCardData)
	if nil == cbCardData or #cbCardData == 0 then
		return cmd.CT_ERROR
	end

	GameLogic:SortCardList(cbCardData)
	local cbCardCount = #cbCardData

	--简单牌型
	if cbCardCount == 1 then --单牌
		return cmd.CT_SINGLE
	elseif cbCardCount == 2 then --对牌
		local nValue1, nValue2 = GameLogic:GetCardLogicValue(cbCardData[1]) , GameLogic:GetCardLogicValue(cbCardData[2])
		return nValue1 == nValue2 and cmd.CT_DOUBLE_LINE or cmd.CT_ERROR
	end

	--分析扑克
	local analyseResult = GameLogic:AnalyseCardData(cbCardData)

	--炸弹判断
	if analyseResult.bFourCount == 1 and cbCardCount == 4 then
		return cmd.CT_BOMB
	end

	--三牌判断
	if analyseResult.bThreeCount > 0 then
		--连牌判断
		local bSeriesCard = false
		if analyseResult.bThreeCount == 1 or analyseResult.bThreeLogicValue[1] ~= 15 then
			local i = 1
			while i < analyseResult.bThreeCount do
				if analyseResult.bThreeLogicValue[i + 1] ~= analyseResult.bThreeLogicValue[1] - i then
					break
				end
				i = i + 1
			end
			if i == analyseResult.bThreeCount then
				bSeriesCard = true
			end
			--带牌判断
			if bSeriesCard == true then
				--数据定义
				local bSignedCount = cbCardCount - analyseResult.bThreeCount*3
				local bDoubleCount = analyseResult.bDoubleCount + analyseResult.bFourCount*2
				--类型分析
				if analyseResult.bThreeCount*3 == cbCardCount then
					return cmd.CT_THREE_LINE
				elseif analyseResult.bThreeCount == bSignedCount and
					analyseResult.bThreeCount*3 + bSignedCount == cbCardCount then
					return cmd.CT_THREE_LINE_TAKE_SINGLE
				elseif analyseResult.bThreeCount == bDoubleCount and
					analyseResult.bThreeCount*3 + bDoubleCount*2 == cbCardCount then
					return cmd.CT_THREE_LINE_TAKE_DOUBLE
				end
			end
		end
	end

	--两连判断
	if analyseResult.bDoubleCount > 0 then
		--连牌判断
		local bSeriesCard = false
		if analyseResult.bDoubleCount == 1 or analyseResult.bDoubleLogicValue[1] ~= 15 then
			local i = 1
			while i < analyseResult.bDoubleCount do
				if analyseResult.bDoubleLogicValue[i + 1] ~= analyseResult.bDoubleLogicValue[1] - i then
					break
				end
				i = i + 1
			end
			if i == analyseResult.bDoubleCount then
				bSeriesCard = true
			end
		end
		if bSeriesCard == true and analyseResult.bDoubleCount*2 == cbCardCount then
			return cmd.CT_DOUBLE_LINE
		end
	end

	--单连判断
	if analyseResult.bSignedCount >= 5 and analyseResult.bSignedCount == cbCardCount then
		--变量定义
		local bSeriesCard = false
		local bLogicValue = GameLogic:GetCardLogicValue(cbCardData[1])
		--连牌判断
		if bLogicValue ~= 15 then
			local i = 1
			while i < analyseResult.bSignedCount do
				if GameLogic:GetCardLogicValue(cbCardData[i + 1]) ~= bLogicValue - i then
					break
				end
				i = i + 1
			end
			if i == analyseResult.bSignedCount then
				bSeriesCard = true
			end
		end
		--单连判断
		if bSeriesCard == true then
			return cmd.CT_SINGLE_LINE
		end
	end

	return cmd.CT_ERROR
end

--对比扑克
function GameLogic:CompareCard(bFirstList, bNextList)
	if nil == bFirstList or nil == bNextList then
		return false
	end
	GameLogic:SortCardList(bFirstList)
	GameLogic:SortCardList(bNextList)
	local bFirstCount = #bFirstList
	local bNextCount = #bNextList

	--获取类型
	local bNextType = GameLogic:GetCardType(bNextList)
	local bFirstType = GameLogic:GetCardType(bFirstList)
	--类型判断
	if bFirstType == cmd.CT_ERROR then
		return false
	elseif bNextType == cmd.CT_ERROR then
		return true
	end
	--炸弹判断
	if bFirstType == cmd.CT_BOMB and bNextType ~= cmd.CT_BOMB then
		return true
	end
	if bFirstType ~= cmd.CT_BOMB and bNextType == cmd.CT_BOMB then
		return false
	end
	--规则判断
	if bFirstType ~= bNextType or bFirstCount ~= bNextCount then
		return false
	end
	
	--开始对比
	if bNextType == cmd.CT_BOMB or
		bNextType == cmd.CT_SINGLE or
		bNextType == cmd.CT_SINGLE_LINE or
		bNextType == cmd.CT_DOUBLE_LINE then
		local bNextLogicValue = GameLogic:GetCardLogicValue(bNextList[1])
		local bFirstLogicValue = GameLogic:GetCardLogicValue(bFirstList[1])
		return bFirstLogicValue > bNextLogicValue
	elseif bNextType == cmd.CT_THREE_LINE or
		bNextType == cmd.CT_THREE_LINE_TAKE_SINGLE or
		bNextType == cmd.CT_THREE_LINE_TAKE_DOUBLE then
		local nextResult = GameLogic:AnalyseCardData(bNextList)
		local firstResult = GameLogic:AnalyseCardData(bFirstList)
		return firstResult.bThreeLogicValue[1] > nextResult.bThreeLogicValue[1]
	end
end

--搜索可出之牌
function GameLogic:SearchOutCard(bCardData, bTurnCardData)
	--初始化结果
	local outCardResult = {}
	outCardResult.cbCardCount = 0
	outCardResult.cbResultCard = {}
	if nil == bCardData or nil == bTurnCardData then
		return outCardResult
	end

	local bCardCount = #bCardData
	GameLogic:SortCardList(bCardData)
	local bTurnCardCount
	--排序
	GameLogic:SortCardList(bTurnCardData)
	--计录长度
	bTurnCardCount = #bTurnCardData
	--长度判断
	if bTurnCardCount > bCardCount then
		return outCardResult
	end

	local bTurnOutType = GameLogic:GetCardType(bTurnCardData)
	if bTurnOutType == cmd.CT_ERROR then 			--错误类型（用于首出牌，出最小的牌）
		print("错误类型")
		--获取数值
		local bLogicValue = GameLogic:GetCardLogicValue(bCardData[bCardCount])
		--多牌判断
		local cbSameCount = 1
		for i = bCardCount - 1, 1 , -1 do
			if GameLogic:GetCardLogicValue(bCardData[i]) == bLogicValue then
				cbSameCount = cbSameCount + 1
			else
				break
			end
		end
		--完成处理
		for i = 1, cbSameCount do
			outCardResult.cbResultCard[i] = bCardData[bCardCount - i + 1]
		end
		outCardResult.cbCardCount = cbSameCount
	elseif bTurnOutType == cmd.CT_SINGLE then 				--单张
		print("单张")
		local bLogicValue = GameLogic:GetCardLogicValue(bTurnCardData[1])

		for i = bCardCount, 1, -1 do
			if GameLogic:GetCardLogicValue(bCardData[i]) > bLogicValue then
				outCardResult.cbResultCard[1] = bCardData[i]
				outCardResult.cbCardCount = 1
				break
			end
		end
	elseif bTurnOutType == cmd.CT_SINGLE_LINE then 			--单连
		print("单连")
		--获取数值
		local bLogicValue = GameLogic:GetCardLogicValue(bTurnCardData[bTurnCardCount])
		--搜索连牌
		for i = bCardCount, bTurnCardCount, -1 do
			local bBreak = false
			--获取数值
			local bHandLogicValue = GameLogic:GetCardLogicValue(bCardData[i])
			if bHandLogicValue > bLogicValue then
				--搜索连牌
				local bLineCount = 0
				for j = i, 1, -1 do
					local bValue = GameLogic:GetCardLogicValue(bCardData[j])
					if bValue >= 15 then  	--构造判断
						break
					end
					if bValue - bLineCount == bHandLogicValue then
						--增加连数
						outCardResult.cbResultCard[bLineCount + 1] = bCardData[j]
						bLineCount = bLineCount + 1
						--完成判断
						if bLineCount == bTurnCardCount then
							outCardResult.cbCardCount = bTurnCardCount
							bBreak = true
							break
						end
					end
				end
			end
			if bBreak then
				break
			end
		end
	elseif bTurnOutType == cmd.CT_DOUBLE_LINE then 		--对连
		print("对连")
		--获取数值
		local bLogicValue = GameLogic:GetCardLogicValue(bTurnCardData[bTurnCardCount]) --最小值
		--搜索连牌
		for i = bCardCount, bTurnCardCount, -1 do
			local bBreak = false
			--获取数值
			local bHandLogicValue = GameLogic:GetCardLogicValue(bCardData[i])
			--构造判断
			if bHandLogicValue > bLogicValue then
				--搜索连牌
				local bLineCount = 0
				for j = i, 2, -1 do
					if GameLogic:GetCardLogicValue(bCardData[j] - bLineCount) == bHandLogicValue and
						GameLogic:GetCardLogicValue(bCardData[j - 1] - bLineCount) == bHandLogicValue then
						--增加连数
						outCardResult.cbResultCard[bLineCount*2 + 1] = bCardData[j]
						outCardResult.cbResultCard[bLineCount*2 + 2] = bCardData[j - 1]
						bLineCount = bLineCount + 1
						--完成判断
						if bLineCount*2 == bTurnCardCount then
							outCardResult.cbCardCount = bTurnCardCount
							bBreak = true
							break
						end
					end
				end
			end
			if bBreak then
				break
			end
		end
	elseif bTurnOutType == cmd.CT_THREE_LINE or 		--三连
		bTurnOutType == cmd.CT_THREE_LINE_TAKE_SINGLE or  		--三带单
		bTurnOutType == cmd.CT_THREE_LINE_TAKE_DOUBLE then 			--三带对 
		print("三带")
		--获取数值
		local bLogicValue = 0
		for i = bTurnCardCount, 3, -1 do
			bLogicValue = GameLogic:GetCardLogicValue(bTurnCardData[i])
			if GameLogic:GetCardLogicValue(bTurnCardData[i - 1]) == bLogicValue and
				GameLogic:GetCardLogicValue(bTurnCardData[i - 2]) == bLogicValue then
				break
			end
		end
		--属性数值
		local bTurnLineCount = 0
		if bTurnOutType == cmd.CT_THREE_LINE_TAKE_SINGLE then
			bTurnLineCount = bTurnCardCount/4
		elseif bTurnOutType == cmd.CT_THREE_LINE_TAKE_DOUBLE then
			bTurnLineCount = bTurnCardCount/5
		else
			bTurnLineCount = bTurnCardCount/3
		end
		--搜索连牌
		for i = bCardCount, bTurnLineCount*3, -1 do
			local bBreak = false
			--获取数值
			local bHandLogicValue = GameLogic:GetCardLogicValue(bCardData[i])
			if bHandLogicValue > bLogicValue then
				--搜索连牌
				local bLineCount = 0
				for j = i, 3, -1 do
					--三牌判断
					if GameLogic:GetCardLogicValue(bCardData[j]) - bLineCount == bHandLogicValue and
						GameLogic:GetCardLogicValue(bCardData[j - 1]) - bLineCount == bHandLogicValue and
						GameLogic:GetCardLogicValue(bCardData[j - 2]) - bLineCount == bHandLogicValue then
						--增加连数
						outCardResult.cbResultCard[bLineCount*3 + 1] = bCardData[j - 2]
						outCardResult.cbResultCard[bLineCount*3 + 2] = bCardData[j - 1]
						outCardResult.cbResultCard[bLineCount*3 + 3] = bCardData[j]
						bLineCount = bLineCount + 1
						--完成判断
						if bLineCount == bTurnLineCount then
							--连牌设置
							outCardResult.cbCardCount = bLineCount*3
							--构造扑克
							local bLeftCount = bCardCount - outCardResult.cbCardCount
							local bLeftCardData = {}
							for i = 1, bCardCount do
								bLeftCardData[i] = bCardData[i]
							end
							GameLogic:RemoveCard(outCardResult.cbResultCard, bLeftCardData)
							--分析扑克
							local analyseResult = GameLogic:AnalyseCardData(bLeftCardData)
							--单牌处理
							if bTurnOutType == cmd.CT_THREE_LINE_TAKE_SINGLE then
								--提取单牌
								for k = analyseResult.bSignedCount, 1, -1 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bSignedCard = analyseResult.bSignedCardData[k]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bSignedCard
									outCardResult.cbCardCount = outCardResult.cbCardCount + 1
								end
								--提取对牌
								for k = analyseResult.bDoubleCount*2, 1, -1 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bSignedCard = analyseResult.bDoubleCardData[k]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bSignedCard
									outCardResult.cbCardCount = outCardResult.cbCardCount + 1
								end
								--提取三牌
								for k = analyseResult.bThreeCount*3, 1, -1 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bSignedCard = analyseResult.bThreeCardData[k]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bSignedCard
									outCardResult.cbCardCount = outCardResult.cbCardCount + 1
								end
								--提取四牌
								for k = analyseResult.bFourCount*4, 1, -1 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bSignedCard = analyseResult.bFourCardData[k]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bSignedCard
									outCardResult.cbCardCount = outCardResult.cbCardCount + 1
								end
							elseif bTurnOutType == cmd.CT_THREE_LINE_TAKE_DOUBLE then
								--提取对牌
								for k = analyseResult.bDoubleCount*2, 1, -2 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bCardData1 = analyseResult.bDoubleCardData[k]
									local bCardData2 = analyseResult.bDoubleCardData[k - 1]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bCardData2
									outCardResult.cbResultCard[outCardResult.cbCardCount + 2] = bCardData1
									outCardResult.cbCardCount = outCardResult.cbCardCount + 2
								end
								--提取三牌
								for k = analyseResult.bThreeCount*3, 1, -3 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bCardData1 = analyseResult.bThreeCardData[k]
									local bCardData2 = analyseResult.bThreeCardData[k - 1]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bCardData2
									outCardResult.cbResultCard[outCardResult.cbCardCount + 2] = bCardData1
									outCardResult.cbCardCount = outCardResult.cbCardCount + 2
								end
								--提取四牌
								for k = analyseResult.bFourCount*4, 1, -4 do
									--终止判断
									if outCardResult.cbCardCount == bTurnCardCount then
										break
									end
									--设置扑克
									local bCardData1 = analyseResult.bFourCardData[k]
									local bCardData2 = analyseResult.bFourCardData[k - 1]
									outCardResult.cbResultCard[outCardResult.cbCardCount + 1] = bCardData2
									outCardResult.cbResultCard[outCardResult.cbCardCount + 2] = bCardData1
									outCardResult.cbCardCount = outCardResult.cbCardCount + 2
								end
							end

							--完成判断
							if outCardResult.cbCardCount ~= bTurnCardCount then
								outCardResult.cbCardCount = 0
							end
							bBreak = true
							break
						end
					end
				end
			end
			if bBreak then
				break
			end
		end
	elseif bTurnOutType == cmd.CT_BOMB then 		--炸弹
		print("炸弹")
		--获取数值
		local bLogicValue = GameLogic:GetCardLogicValue(bTurnCardData[bTurnCardCount])
		--搜索炸弹
		for i = bCardCount , 4, -1 do
			--获取数值
			local bHandLogicValue = GameLogic:GetCardLogicValue(bCardData[i])
			--构造判断
			if bHandLogicValue > bLogicValue then
				--炸弹判断
				local j = i - 1
				while j >= i - 3 do
					if GameLogic:GetCardLogicValue(bCardData[j]) ~= bHandLogicValue then
						break
					end
					j = j - 1
				end
				--完成处理
				if j == i - 4 then
					outCardResult.cbCardCount = bTurnCardCount
					outCardResult.cbResultCard[1] = bCardData[i - 3]
					outCardResult.cbResultCard[2] = bCardData[i - 2]
					outCardResult.cbResultCard[3] = bCardData[i - 1]
					outCardResult.cbResultCard[4] = bCardData[i]
					break
				end
			end
		end
	end
	--炸弹管非炸弹
	if bTurnOutType ~= cmd.CT_BOMB and outCardResult.cbCardCount == 0 then
		print("comming?")
		for i = bCardCount , 4, -1 do
			--获取数值
			local bHandLogicValue = GameLogic:GetCardLogicValue(bCardData[i])
			--炸弹判断
			local j = i - 1
			while j >= i - 3 do
				if GameLogic:GetCardLogicValue(bCardData[j]) ~= bHandLogicValue then
					break
				end
				j = j - 1
			end
			--完成处理
			if j == i - 4 then
				outCardResult.cbCardCount = 4
				outCardResult.cbResultCard = {}
				outCardResult.cbResultCard[1] = bCardData[i - 3]
				outCardResult.cbResultCard[2] = bCardData[i - 2]
				outCardResult.cbResultCard[3] = bCardData[i - 1]
				outCardResult.cbResultCard[4] = bCardData[i]
				break
			end
		end
	end

	return outCardResult
end

return GameLogic
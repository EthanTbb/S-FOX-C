local GameLogic = GameLogic or {}
--最大牌数
GameLogic.MAX_CARDCOUNT			= 5
--牌值掩码
GameLogic.MASK_VALUE			= 0X0F
--花色掩码
GameLogic.MASK_COLOR			= 0XF0
--扑克类型
GameLogic.CT_SINGLE				= 1								--单牌类型
GameLogic.CT_ONE_DOUBLE			= 2								--对子类型
GameLogic.CT_TWO_DOUBLE			= 3								--两队类型
GameLogic.CT_THREE_TIAO			= 4								--三条类型
GameLogic.CT_SHUN_ZI			= 5								--顺子类型
GameLogic.CT_TONG_HUA			= 6								--同花类型
GameLogic.CT_HU_LU				= 7								--葫芦类型
GameLogic.CT_TIE_ZHI			= 8								--铁支类型
GameLogic.CT_TONG_HUA_SHUN		= 9								--同花顺型


GameLogic.tagAnalyseResult	=
{
	cbFourCount	= 0,					--四张数目
	cbThreeCount = 0,					--三张数目
	cbDoubleCount = 0,					--两张数目
	cbSignedCount = 0,					--单张数目
	cbFourLogicValue = {},				--四张列表
	cbThreeLogicValue = {},				--三张列表
	cbDoubleLogicValue = {},			--两张列表
	cbSignedLogicValue = {},			--单张列表
	cbFourCardData = {},	--四张列表
	cbThreeCardData = {},	--三张列表
	cbDoubleCardData = {},	--两张列表
	cbSignedCardData = {},	--单张列表
}

------------------------------------------------------------------
--类型函数

--获取类型
--param[cbCardDataTable] 扑克数据table
--param[cbCardCount] 扑克数据number
function GameLogic:GetCardType( cbCardDataTable)
	local cbCardCount = #cbCardDataTable
    self:SortCardList(cbCardDataTable)   --排序
	--五条牌型
	if cbCardCount == 5 then
		--变量定义
		local cbSameColor = true
		local cbLineCard = true
		local cbFirstColor = self:GetCardColor(cbCardDataTable[1])
		local cbFirstValue = self:GetCardValue(cbCardDataTable[1])
		--牌型分析
		for i=2,cbCardCount  do
			--数据分析
			if self:GetCardColor(cbCardDataTable[i]) ~= cbFirstColor then
				cbSameColor = false
			end
			local tempValue = self:GetCardValue(cbCardDataTable[i])
			if tempValue == 1 then
				tempValue = 14
			end
			if  cbFirstValue  + i-1 ~= tempValue  then
				cbLineCard = false
				--print("Value,i",i)
			end
			--结束判断
			if cbSameColor == false and cbLineCard == false then
				break
			end
		end
		--顺子类型
		if cbSameColor == false and cbLineCard == true then
			return GameLogic.CT_SHUN_ZI
		--同花类型
		elseif cbSameColor == true and cbLineCard == false then
			return GameLogic.CT_TONG_HUA
		--同花顺类型
		elseif cbSameColor == true and cbLineCard == true then
			return GameLogic.CT_TONG_HUA_SHUN
		end
	end
	--扑克分析
	local tempAnalyseResult = self:AnalysebCardData( cbCardDataTable, cbCardCount)
	--四条类型
	if(tempAnalyseResult.cbFourCount == 1) then
		return GameLogic.CT_TIE_ZHI
	end
	--两对类型
	if(tempAnalyseResult.cbDoubleCount == 2) then
		return GameLogic.CT_TWO_DOUBLE
	end
	--对牌类型
	if(tempAnalyseResult.cbDoubleCount == 1 and tempAnalyseResult.cbThreeCount == 0 ) then
		return GameLogic.CT_ONE_DOUBLE
	end
	--葫芦类型
	if(tempAnalyseResult.cbThreeCount == 1 ) then
		return tempAnalyseResult.cbDoubleCount == 1 and GameLogic.CT_HU_LU or GameLogic.CT_THREE_TIAO
	end
	return GameLogic.CT_SINGLE
end

--取模
function GameLogic:mod(a,b)
    return a - math.floor(a/b)*b
end
--获取数值
function GameLogic:GetCardValue( cbCardData )
	return self:mod(cbCardData, 16)
end

--获取花色
function GameLogic:GetCardColor( cbCardData )
	return math.floor(cbCardData/16)
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
------------------------------------------------------------------

------------------------------------------------------------------
--控制函数

--排列扑克
function GameLogic:SortCardList( cbCardDataTable )
	local cbCount = #cbCardDataTable;
	--数目过滤cmd.RES_PATH..
	if (cbCount == 0 or cbCount > 5) then
		return;
	end
	--转换数值
	local cbSortValue = {};
	for i=1,cbCount do		
		local tempValue = self:GetCardValue(cbCardDataTable[i])
		if tempValue == 1 then
			tempValue = 14
		end
		cbSortValue[i] = tempValue
	end
	--排序操作
	local bSorted = true;
	local cbLast = cbCount - 1;
	repeat
		bSorted = true;
		for i=1,cbLast do
			if (cbSortValue[i] > cbSortValue[i+1])
				or ((cbSortValue[i] == cbSortValue[i + 1]) and (cbCardDataTable[i] > cbCardDataTable[i + 1])) then
				--设置标志
				bSorted = false;
				--扑克数据
				cbCardDataTable[i], cbCardDataTable[i + 1] = cbCardDataTable[i + 1], cbCardDataTable[i];
				--排序权位
				cbSortValue[i], cbSortValue[i + 1] = cbSortValue[i + 1], cbSortValue[i];
			end
		end
		cbLast = cbLast - 1;
	until bSorted ~= false;
end

--混乱扑克
--param[cbCardData] 扑克数据table
function GameLogic:RandCardList( cbCardData )
	local cbCardCount = #cbCardData;
	--数目过滤
	if (cbCardCount == 0 or cbCardCount > 5) then
		return;
	end
	--混乱准备
	local temp_cbCardData = GameLogic.copyTab(cbCardData);
	--混乱扑克
	local cbRandCount = 1
	local cbPosition = 1
	while cbRandCount<cbCardCount do
		math.randomseed(os.time())
		cbPosition = math.random(1,100)%(#temp_cbCardData - cbRandCount) + 1
		cbCardData[cbPosition],cbCardData[#temp_cbCardData - cbRandCount] = cbCardData[#temp_cbCardData - cbRandCount],cbCardData[cbPosition]
	end
	return
end
------------------------------------------------------------------
--逻辑函数
------------------------------------------------------------------
--分析扑克
function GameLogic:AnalysebCardData( cbCardDataTable)
	local cbCardCount = #cbCardDataTable
	local m_AnalyseResult = self:copyTab(self.tagAnalyseResult);

	local startIndex = 1
	local repeatNum = cbCardCount
	repeat
		local bAnalyse = true
		--扑克分析
		for i=startIndex,repeatNum do
			--变量定义
			local cbSameCount = 1
			local cbSameCardData = {}
			table.insert(cbSameCardData,cbCardDataTable[i])
			local cbLogicValue = self:GetCardValue(cbCardDataTable[i])
			--获取同牌
			for j=i+1,repeatNum do
				--逻辑对比
				if self:GetCardValue(cbCardDataTable[j]) == cbLogicValue then
					--设置相同扑克的值
					cbSameCardData[cbSameCount] = cbCardDataTable[j]
					cbSameCount = cbSameCount + 1
				end

			end
			--保存结果
			if(cbSameCount == 1) then 	--单张
				m_AnalyseResult.cbSignedCount = m_AnalyseResult.cbSignedCount + 1
			elseif (cbSameCount == 2) then	--两张
				m_AnalyseResult.cbDoubleCount = m_AnalyseResult.cbDoubleCount + 1
			elseif (cbSameCount == 3) then	--三张
				m_AnalyseResult.cbThreeCount = m_AnalyseResult.cbThreeCount + 1	
			elseif (cbSameCount == 4) then	--四张
				m_AnalyseResult.cbFourCount = m_AnalyseResult.cbFourCount + 1	
			end
			--设置递增
			if i + cbSameCount  >= 5 then
				bAnalyse = false
				break
			end
			if cbSameCount > 2 then
				startIndex = i + cbSameCount  
				break
			end
		end
	until bAnalyse == false
	return m_AnalyseResult
end
------------------------------------------------------------------
return GameLogic;
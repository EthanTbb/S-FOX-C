local GameLogic = GameLogic or {}

--牌值掩码
GameLogic.MASK_VALUE			= 0X0F
--花色掩码
GameLogic.MASK_COLOR			= 0XF0
--最大手牌数目
GameLogic.MAX_CARDCOUNT			= 20
--牌库数目
GameLogic.FULL_COUNT			= 54
--正常手牌数目
GameLogic.NORMAL_COUNT			= 17

--排序类型
--大小排序
GameLogic.ST_ORDER				= 1
--数目排序
GameLogic.ST_COUNT				= 2
--自定排序
GameLogic.ST_CUSTOM				= 3

------------------------------------------------------------------
--类型函数

--获取类型
--param[cbCardDataTable] 扑克数据table
function GameLogic.GetCardType( cbCardDataTable )
	
end

--获取类型
function GameLogic.GetBackCardType( cbCardDataTable )
	-- body
end

--获取数值
function GameLogic.GetCardValue( cbCardData )
	return bit:_and(cbCardData, GameLogic.MASK_VALUE);
end

--获取花色
function GameLogic.GetCardColor( cbCardData )
	return bit:_and(cbCardData, GameLogic.MASK_COLOR);
end
------------------------------------------------------------------

------------------------------------------------------------------
--控制函数

function GameLogic.SortCardList( cbCardDataTable, cbSortType )
	local cbCount = #cbCardDataTable;
	--数目过滤cmd.RES_PATH..
	if (cbCount == 0 or cbCount > 10) then
		return;
	end

	cbSortType = cbSortType or GameLogic.ST_ORDER;
	if cbSortType == GameLogic.ST_CUSTOM then
		return;
	end

	--转换数值
	local cbSortValue = {};
	for i=1,cbCount do		
		cbSortValue[i] = GameLogic.GetCardValue(cbCardDataTable[i])
	end

	--排序操作
	local bSorted = true;
	local cbLast = cbCount - 1;
	repeat
		bSorted = true;
		for i=1,cbLast do
			if (cbSortValue[i] < cbSortValue[i+1])
				or ((cbSortValue[i] == cbSortValue[i + 1]) and (cbCardDataTable[i] < cbCardDataTable[i + 1])) then
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
------------------------------------------------------------------

------------------------------------------------------------------
--逻辑函数

--获取牌点
function GameLogic.GetCardPip( cbCardData )
	--计算牌点
    local cbCardValue = GameLogic.GetCardValue(cbCardData);
    if cbCardValue >= 10 then
    	return 0;
    else
    	return cbCardValue;
    end
end

--获取牌点
function GameLogic.GetCardListPip( cbCardDataTable )
	--变量定义
    local cbPipCount = 0;
    
    --获取牌点
    for i=1,#cbCardDataTable do
    	cbPipCount = math.mod((GameLogic.GetCardPip(cbCardDataTable[i])+cbPipCount), 10);
    end

    return cbPipCount;
end
------------------------------------------------------------------

return GameLogic;
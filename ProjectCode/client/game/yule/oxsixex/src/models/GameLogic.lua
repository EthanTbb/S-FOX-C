local GameLogic = {}

GameLogic.m_cbCardListData = {
	0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,	--方块 A - K
	0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,	--梅花 A - K
	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,	--红桃 A - K
	0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,	--黑桃 A - K
	0x4E,0x4F
};
--数值掩码
GameLogic.LOGIC_MASK_COLOR		= 0xF0								--花色掩码
GameLogic.LOGIC_MASK_VALUE		= 0x0F								--数值掩码

GameLogic.MAX_COUNT             = 5
--扑克类型
GameLogic.OX_VALUE_0		    = 0									--无牛牌型
GameLogic.OX_VALUE_BIG_0	    = 1									--无牛牌型
GameLogic.OX_VALUE_1			= 2									--牛一牌型
GameLogic.OX_VALUE_BIG_1		= 3									--牛一牌型
GameLogic.OX_VALUE_2			= 4									--牛二牌型
GameLogic.OX_VALUE_BIG_2		= 5									--牛二牌型
GameLogic.OX_VALUE_3			= 6									--牛三牌型
GameLogic.OX_VALUE_BIG_3		= 7									--牛三牌型
GameLogic.OX_VALUE_4			= 8									--牛四牌型
GameLogic.OX_VALUE_BIG_4		= 9									--牛四牌型
GameLogic.OX_VALUE_5			= 10								--牛五牌型
GameLogic.OX_VALUE_BIG_5		= 11								--牛五牌型
GameLogic.OX_VALUE_6			= 12								--牛六牌型
GameLogic.OX_VALUE_BIG_6	    = 13								--牛六牌型
GameLogic.OX_VALUE_7			= 14								--牛七牌型
GameLogic.OX_VALUE_BIG_7		= 15								--牛七牌型
GameLogic.OX_VALUE_8			= 16								--牛八牌型
GameLogic.OX_VALUE_BIG_8		= 17								--牛八牌型
GameLogic.OX_VALUE_9			= 18								--牛九牌型
GameLogic.OX_VALUE_BIG_9		= 19								--牛九牌型
GameLogic.OX_VALUE_10			= 20								--牛牛牌型
GameLogic.OX_VALUE_BIG_10		= 21								--牛牛牌型
GameLogic.OX_FOUR_KING			= 22								--四花牛牌
GameLogic.OX_FIVE_KING			= 23								--五花牛牌

--获取数值
function GameLogic.GetCardValue(cbCardData) 
    return bit:_and(cbCardData,GameLogic.LOGIC_MASK_VALUE)
end
--获取花色
function GameLogic.GetCardColor(cbCardData) 
    return bit:_and(cbCardData,GameLogic.LOGIC_MASK_COLOR)/16
end

--逻辑数值
function GameLogic.GetCardLogicValue(cbCardData) 
    --扑克属性
	local bCardValue=GameLogic.GetCardValue(cbCardData);

	--转换数值
    if bCardValue > 10 then
        return 10
    else
        return bCardValue
    end
end

--获取类型
function GameLogic.GetCardType(cbCardData,cbCardCount) 
    cbCardCount = cbCardCount or GameLogic.MAX_COUNT
    --王牌统计
	local cbKingCount = 0;
	for i = 1,GameLogic.MAX_COUNT do
		if cbCardData[i] == 0x4E or cbCardData[i] == 0x4F then
			cbKingCount = cbKingCount + 1
		end
	end
    assert(cbKingCount < 3, "GameLogic.GetCardType cbKingCount error!")

	--分类组合
	if cbKingCount == 2 then
		--设置变量
		local cbTempData = cbCardData

		if cbTempData[1] ~= 0x4E and cbTempData[1] ~= 0x4F and
			cbTempData[2] ~= 0x4E and cbTempData[2] ~= 0x4F and
			cbTempData[3] ~= 0x4E and cbTempData[3] ~= 0x4F then

			local cbValue0 = GameLogic.GetCardLogicValue(cbTempData[1]);
			local cbValue1 = GameLogic.GetCardLogicValue(cbTempData[2]);
			local cbValue2 = GameLogic.GetCardLogicValue(cbTempData[3]);

			if (cbValue0 + cbValue1 + cbValue2) % 10 == 0 then
				return GameLogic.OX_VALUE_10;
			end
		
		elseif cbTempData[4] ~= 0x4E and cbTempData[4] ~= 0x4F and
			cbTempData[5] ~= 0x4E and cbTempData[5] ~= 0x4F then

			local cbCount = (GameLogic.GetCardLogicValue(cbTempData[4]) + GameLogic.GetCardLogicValue(cbTempData[5])) % 10;
            if cbCount == 1 then
                return GameLogic.OX_VALUE_1;
            elseif cbCount == 2 then
                return GameLogic.OX_VALUE_2;
            elseif cbCount == 3 then
                return GameLogic.OX_VALUE_3;
            elseif cbCount == 4 then
                return GameLogic.OX_VALUE_4;
            elseif cbCount == 5 then
                return GameLogic.OX_VALUE_5;
            elseif cbCount == 6 then
                return GameLogic.OX_VALUE_6;
            elseif cbCount == 7 then
                return GameLogic.OX_VALUE_7;
            elseif cbCount == 8 then
                return GameLogic.OX_VALUE_8;
            elseif cbCount == 9 then
                return GameLogic.OX_VALUE_9;
            elseif cbCount == 0 then
                return GameLogic.OX_VALUE_10;
            else
                assert(false, "GameLogic.GetCardType cbCount error!")
            end
		else 
            return GameLogic.OX_VALUE_10;
        end
	elseif cbKingCount == 1 then
		--设置变量
		local cbTempData = cbCardData

		if cbTempData[1] ~= 0x4E and cbTempData[1] ~= 0x4F and
			cbTempData[2] ~= 0x4E and cbTempData[2] ~= 0x4F and
			cbTempData[3] ~= 0x4E and cbTempData[3] ~= 0x4F then
		
			local cbValue0 = GameLogic.GetCardLogicValue(cbTempData[1]);
			local cbValue1 = GameLogic.GetCardLogicValue(cbTempData[2]);
			local cbValue2 = GameLogic.GetCardLogicValue(cbTempData[3]);

			if (cbValue0 + cbValue1 + cbValue2) % 10 == 0 then
				return GameLogic.OX_VALUE_10;
			end
		
		else
			local cbCount = (GameLogic.GetCardLogicValue(cbTempData[4]) + GameLogic.GetCardLogicValue(cbTempData[5])) % 10;

            if cbCount == 1 then
                return GameLogic.OX_VALUE_1;
            elseif cbCount == 2 then
                return GameLogic.OX_VALUE_2;
            elseif cbCount == 3 then
                return GameLogic.OX_VALUE_3;
            elseif cbCount == 4 then
                return GameLogic.OX_VALUE_4;
            elseif cbCount == 5 then
                return GameLogic.OX_VALUE_5;
            elseif cbCount == 6 then
                return GameLogic.OX_VALUE_6;
            elseif cbCount == 7 then
                return GameLogic.OX_VALUE_7;
            elseif cbCount == 8 then
                return GameLogic.OX_VALUE_8;
            elseif cbCount == 9 then
                return GameLogic.OX_VALUE_9;
            elseif cbCount == 0 then
                return GameLogic.OX_VALUE_10;
            else
                assert(false, "GameLogic.GetCardType cbCount error!")
            end
        end
	elseif cbKingCount == 0 then
		--特殊牌型
		local cbTenCount = 0;
		local cbJQKCount = 0;
		for i=1,cbCardCount do
			if GameLogic.GetCardValue(cbCardData[i]) > 10 then
				cbJQKCount = cbJQKCount + 1
			elseif GameLogic.GetCardValue(cbCardData[i]) == 10 then
				cbTenCount = cbTenCount + 1
			end
		end
		if cbJQKCount==GameLogic.MAX_COUNT then
            return GameLogic.OX_FIVE_KING;
		elseif cbJQKCount==GameLogic.MAX_COUNT-1 and cbTenCount==1 then
             return GameLogic.OX_FOUR_KING;
        end

		--设置变量
		local cbTempData = cbCardData

		local cbValue0 = GameLogic.GetCardLogicValue(cbTempData[1]);
		local cbValue1 = GameLogic.GetCardLogicValue(cbTempData[2]);
		local cbValue2 = GameLogic.GetCardLogicValue(cbTempData[3]);

		if (cbValue0 + cbValue1 + cbValue2) % 10 == 0 then
			local cbCount = (GameLogic.GetCardLogicValue(cbTempData[4]) + GameLogic.GetCardLogicValue(cbTempData[5])) % 10
            if cbCount == 1 then
                return GameLogic.OX_VALUE_BIG_1;
            elseif cbCount == 2 then
                return GameLogic.OX_VALUE_BIG_2;
            elseif cbCount == 3 then
                return GameLogic.OX_VALUE_BIG_3;
            elseif cbCount == 4 then
                return GameLogic.OX_VALUE_BIG_4;
            elseif cbCount == 5 then
                return GameLogic.OX_VALUE_BIG_5;
            elseif cbCount == 6 then
                return GameLogic.OX_VALUE_BIG_6;
            elseif cbCount == 7 then
                return GameLogic.OX_VALUE_BIG_7;
            elseif cbCount == 8 then
                return GameLogic.OX_VALUE_BIG_8;
            elseif cbCount == 9 then
                return GameLogic.OX_VALUE_BIG_9;
            elseif cbCount == 0 then
                return GameLogic.OX_VALUE_BIG_10;
            else
                assert(false, "GameLogic.GetCardType cbCount error!")
            end
		end
	end

	return GameLogic.OX_VALUE_0;
end

--获取倍数
function GameLogic.GetTimes(cbCardData, cbCardCount)
	if cbCardCount ~= GameLogic.MAX_COUNT then
        return 0;
    end

	local bTimes = GameLogic.GetCardType(cbCardData, GameLogic.MAX_COUNT);
	if bTimes < GameLogic.OX_VALUE_10 then
        return 1;
	elseif bTimes == GameLogic.OX_VALUE_10 then
        return 2;
	elseif bTimes == GameLogic.OX_VALUE_BIG_10 then
        return 2;
	elseif bTimes == GameLogic.OX_FOUR_KING then
        return 2
	elseif bTimes == OX_FIVE_KING then
        return 2;
    end

	return 0;
end

--获取整数
function GameLogic.IsIntValue(cbCardData,cbCardCount)
	local sum=0;
	for i=1,cbCardCount do
		if GameLogic.GetCardColor(cbCardData[i]) == 0x40 then
            return true;
        end
		sum=sum + GameLogic.GetCardLogicValue(cbCardData[i])
	end
	assert(sum>0,"GameLogic.IsIntValue sum error!");
	return (sum%10==0)
end

--排列扑克
function GameLogic.SortCardList(cbCardData, cbCardCount)
	--转换数值
	local cbLogicValue = {}
	for i=1,cbCardCount do
        cbLogicValue[i] = GameLogic.GetCardValue(cbCardData[i]);	
    end

	--排序操作
	local cbTempData = 0
    local bLast=cbCardCount-1

    while(bLast>0)
    do
        for i=1,bLast do
			if (cbLogicValue[i]<cbLogicValue[i+1]) or
				((cbLogicValue[i]==cbLogicValue[i+1]) and (cbCardData[i]<cbCardData[i+1])) then
				--交换位置
				cbTempData=cbCardData[i];
				cbCardData[i]=cbCardData[i+1];
				cbCardData[i+1]=cbTempData;
				cbTempData=cbLogicValue[i];
				cbLogicValue[i]=cbLogicValue[i+1];
				cbLogicValue[i+1]=cbTempData;
			end	
		end
		bLast = bLast - 1
    end
end

--获取牛牛
function GameLogic.GetOxCard(cbCardData)
	--王牌统计
	local cbKingCount = 0;
	for i = 1,GameLogic.MAX_COUNT do
		if cbCardData[i] == 0x4E or cbCardData[i] == 0x4F then
			cbKingCount = cbKingCount + 1;
		end
	end
	assert(cbKingCount < 3,"GameLogic.GetOxCard cbKingCount error!");

	--分类组合
	if cbKingCount == 2 then
		--拷贝扑克
		local cbTempData = clone(cbCardData)
		GameLogic.SortCardList(cbTempData, GameLogic.MAX_COUNT);

		cbCardData[1] = cbTempData[3];
		cbCardData[2] = cbTempData[4];
		cbCardData[3] = cbTempData[1];
		cbCardData[4] = cbTempData[2];
		cbCardData[5] = cbTempData[5];

		return true;
	elseif cbKingCount == 1 then
		--设置变量
		local cbTempData = clone(cbCardData)
		GameLogic.SortCardList(cbTempData, GameLogic.MAX_COUNT);

		--牛牛牌型
		local cbSum = 0;
		local cbTemp = {0,0,0,0,0}
		
		for i = 2,GameLogic.MAX_COUNT do
			cbTemp[i] = GameLogic.GetCardLogicValue(cbTempData[i])
			cbSum = cbSum + cbTemp[i];
		end

		--三张成十
		for i = 2,GameLogic.MAX_COUNT do
			if (cbSum - cbTemp[i])%10 == 0 then
				local cbCount = 0;
				for j = 2,GameLogic.MAX_COUNT do
					if i ~= j then
						cbCardData[cbCount+1] = cbTempData[j];
                        cbCount = cbCount +1;
					end
				end

				cbCardData[cbCount+1] = cbTempData[i];
                cbCount = cbCount +1;
				cbCardData[cbCount+1] = cbTempData[1];
                cbCount = cbCount +1;

				return true;
			end
		end

		--两张成十
		for i = 2,GameLogic.MAX_COUNT - 1 do
			for j = i + 1,GameLogic.MAX_COUNT do
				if (cbSum - cbTemp[i] - cbTemp[j]) % 10 == 0 then
					local cbCount = 0;
					cbCardData[cbCount+1] = cbTempData[1];
                    cbCount = cbCount +1
					cbCardData[cbCount+1] = cbTempData[i];
                    cbCount = cbCount +1
					cbCardData[cbCount+1] = cbTempData[j];
                    cbCount = cbCount +1

					for k = 2,GameLogic.MAX_COUNT do
						if i ~= k and j ~= k then
							cbCardData[cbCount+1] = cbTempData[k];
                            cbCount = cbCount +1
						end
					end
					--ASSERT(cbCount == 5);

					return true;
				end
			end
		end

		--四中取大
		local cbBigCount = 0;
		local cbBigIndex1 = 0;
		local cbBigIndex2 = 0;
		for i = 2,GameLogic.MAX_COUNT do
			for j = i + 1,GameLogic.MAX_COUNT do
				local cbSumCount = (GameLogic.GetCardLogicValue(cbTempData[i]) + GameLogic.GetCardLogicValue(cbTempData[j])) % 10;
				if cbSumCount > cbBigCount then
					cbBigIndex1 = i;
					cbBigIndex2 = j;
					cbBigCount = cbSumCount;
				end
			end
		end

		local cbCount = 0;
		for i = 2, GameLogic.MAX_COUNT do
			if i ~= cbBigIndex1 and i ~= cbBigIndex2 then
				cbCardData[cbCount+1] = cbTempData[i];
                cbCount = cbCount + 1
			end
		end
		--ASSERT(cbCount == 3);

		cbCardData[cbCount+1] = cbTempData[1];
        cbCount = cbCount + 1
		cbCardData[cbCount+1] = cbTempData[cbBigIndex1];
        cbCount = cbCount + 1
		cbCardData[cbCount+1] = cbTempData[cbBigIndex2];
        cbCount = cbCount + 1

		return true;
	elseif cbKingCount == 0 then
		--普通牌型
		local cbSum = 0;
		local cbTemp = {0,0,0,0,0}
		local cbTempData = clone(cbCardData)

		for i = 1,GameLogic.MAX_COUNT do
			cbTemp[i] = GameLogic.GetCardLogicValue(cbCardData[i]);
			cbSum = cbSum + cbTemp[i];
		end

		--查找牛牛
		for i = 1,GameLogic.MAX_COUNT - 1 do
			for j = i + 1,GameLogic.MAX_COUNT do
				if (cbSum - cbTemp[i] - cbTemp[j]) % 10 == 0 then
					local cbCount = 0;
					for k = 1,GameLogic.MAX_COUNT do
						if k ~= i and k ~= j then
							cbCardData[cbCount+1] = cbTempData[k];
                            cbCount = cbCount + 1
						end
					end
					--ASSERT(cbCount == 3);

					cbCardData[cbCount+1] = cbTempData[i];
                    cbCount = cbCount + 1
					cbCardData[cbCount+1] = cbTempData[j];
                    cbCount = cbCount + 1
					return true;
				end
			end
		end
	end

	return false;
end

function GameLogic.getOxValue(cbValue)
	--牛牛数据
    local iValue = 0
    if cbValue == GameLogic.OX_VALUE_0 or cbValue == GameLogic.OX_VALUE_BIG_0 then
        iValue = 0;
    elseif cbValue == GameLogic.OX_VALUE_1 or cbValue == GameLogic.OX_VALUE_BIG_1 then
        iValue = 1
    elseif cbValue == GameLogic.OX_VALUE_2 or cbValue == GameLogic.OX_VALUE_BIG_2 then
        iValue = 2
    elseif cbValue == GameLogic.OX_VALUE_3 or cbValue == GameLogic.OX_VALUE_BIG_3 then
        iValue = 3
    elseif cbValue == GameLogic.OX_VALUE_4 or cbValue == GameLogic.OX_VALUE_BIG_4 then
        iValue = 4
    elseif cbValue == GameLogic.OX_VALUE_5 or cbValue == GameLogic.OX_VALUE_BIG_5 then
        iValue = 5
    elseif cbValue == GameLogic.OX_VALUE_6 or cbValue == GameLogic.OX_VALUE_BIG_6 then
        iValue = 6
    elseif cbValue == GameLogic.OX_VALUE_7 or cbValue == GameLogic.OX_VALUE_BIG_7 then
        iValue = 7
    elseif cbValue == GameLogic.OX_VALUE_8 or cbValue == GameLogic.OX_VALUE_BIG_8 then
        iValue = 8
    elseif cbValue == GameLogic.OX_VALUE_9 or cbValue == GameLogic.OX_VALUE_BIG_9 then
        iValue = 9
    elseif cbValue == GameLogic.OX_VALUE_10 or cbValue == GameLogic.OX_VALUE_BIG_10 
        or cbValue == GameLogic.OX_FOUR_KING or cbValue == GameLogic.OX_FIVE_KING then
        iValue = 10
    else
        iValue = 0xFF
    end

    return iValue
end
return GameLogic
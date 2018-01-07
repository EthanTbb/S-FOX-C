local GameLogic = GameLogic or {}

GameLogic.CT_PAIR_TEN		=		10				--对十
GameLogic.CT_PAIR_NIGHT		=		9				--对九
GameLogic.CT_PAIR_EIGHT		=		8				--对八
GameLogic.CT_PAIR_SEVEN		=		7				--对七
GameLogic.CT_PAIR_SISEX		=		6				--对六
GameLogic.CT_PAIR_FIVE		=		5				--对五
GameLogic.CT_PAIR_FOUR		=		4				--对四
GameLogic.CT_PAIR_THREE		=		3				--对三
GameLogic.CT_PAIR_TWO		=		2				--对二
GameLogic.CT_PAIR_ONE		=		1				--对一
GameLogic.CT_POINT			=		0				--点数类型
GameLogic.CT_PAIR			=		11

--骰子点数
GameLogic.DICE_COUNT		= 3						--骰子个数

GameLogic.DiceMutiple =
{
	{{3,8},{30,5},{31,5},{32,5},{33,5},{34,5}},
	{{30,5},{4,8} ,{35,5},{36,5},{37,5},{38,5}},
	{{31,5},{35,5},{5,8} ,{39,5},{40,5},{41,5}},
	{{32,5},{36,5},{39,5},{6,8} ,{42,5},{43,5}},
	{{33,5},{37,5},{40,5},{42,5},{7,8} ,{44,5}},
	{{34,5},{38,5},{41,5},{43,5},{44,5},{8,8} }
};

GameLogic.DiceMutipleEx =
{
	{16,50},{17,18},{18,14},{19,12},{20,8},
	{21,6}, {22,6} ,{23,6} ,{24,6} ,{25,8},
	{26,12},{27,14},{28,18},{29,50}
};

GameLogic.tagDiceMutiple = 
{
	cbAreaIndex = 0,
	nMutiple = 0
};



GameLogic.tagDiceDate = 
{
	cbDate = 0,
	cbCount = 1
}
--分析结果
GameLogic.tagAnalyseResult = 
{
	m_DiceValue = 
	{
		GameLogic.tagDiceDate,
		GameLogic.tagDiceDate,
		GameLogic.tagDiceDate
		-- cbDate = 0,
		-- cbCount = 1

	},
	cbUnEqualDice = 2,
	cbAllDiceValue = 0
}

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




--分析骰子
function GameLogic:DeduceWinner( nWinMultiple,cbDiceValue )
	--临时骰子数据
	local analyseResult = GameLogic:copyTab(GameLogic.tagAnalyseResult)
	for i=1,3 do
		analyseResult.m_DiceValue[i].cbDate = cbDiceValue[i]
	end
	--分析数值和是否相同
	for cbIndex=1,GameLogic.DICE_COUNT do
		for cbRecord= cbIndex+1,GameLogic.DICE_COUNT-cbIndex do
			if analyseResult.m_DiceValue[cbRecord] == cbDiceValue[cbIndex] then
				analyseResult.m_DiceValue[cbIndex].cbCount = analyseResult.m_DiceValue[cbIndex].cbCount + 1
				break
			end
			if analyseResult.cbUnEqualDice == cbRecord then
				analyseResult.cbUnEqualDice = analyseResult.cbUnEqualDice + 1
			end
		end
		analyseResult.cbAllDiceValue = analyseResult.cbAllDiceValue+cbDiceValue[cbIndex]
	end
	--判断对子和组合
	for cx=1,3 do
		for cy=cx+1,3 do
			local cbAreaIndex =GameLogic.DiceMutiple[cbDiceValue[cx]][cbDiceValue[cy]][1]
			nWinMultiple[cbAreaIndex] = GameLogic.DiceMutiple[cbDiceValue[cx]][cbDiceValue[cy]][2]
		end
	end
	--判断骰字面值
	if analyseResult.cbUnEqualDice ~= 2 then
		if analyseResult.cbAllDiceValue >= 11 and analyseResult.cbAllDiceValue <= 17 then
			nWinMultiple[1] = 1
		end
		if analyseResult.cbAllDiceValue >=4 and analyseResult.cbAllDiceValue <= 10 then
			nWinMultiple[2] = 1
		end
	end
	--单双
	if analyseResult.cbUnEqualDice ~= 2 then
		if analyseResult.cbAllDiceValue%2 == 0 then
			--print("双")
			nWinMultiple[52]=1
		end
		if analyseResult.cbAllDiceValue%2 == 1 then
			--print("单")
			nWinMultiple[51]=1
		end
	end
	if analyseResult.cbAllDiceValue >= 4 and analyseResult.cbAllDiceValue <= 17 then
		print("analyseResult.cbAllDiceValue",analyseResult.cbAllDiceValue)
		local cbAreaIndex = GameLogic.DiceMutipleEx[analyseResult.cbAllDiceValue-3][1]
		print(cbAreaIndex)
		nWinMultiple[cbAreaIndex]= GameLogic.DiceMutipleEx[analyseResult.cbAllDiceValue-3][2]
		print(nWinMultiple[cbAreaIndex])
	end
	--判断同三，同二，和单个
	for cbIndex=1,analyseResult.cbUnEqualDice do
		--最下方6个区域
		nWinMultiple[44+analyseResult.m_DiceValue[cbIndex].cbDate]=analyseResult.m_DiceValue[cbIndex].cbCount
		if analyseResult.m_DiceValue[cbIndex].cbCount == 3 then
			nWinMultiple[8+analyseResult.m_DiceValue[cbIndex].cbDate]=150
			nWinMultiple[15]=24
		end
	end
end

return GameLogic
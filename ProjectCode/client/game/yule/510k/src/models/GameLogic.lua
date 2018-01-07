--[[--
510k游戏逻辑
]]
local GameLogic = {}
GameLogic.m_b2Biggest = false
GameLogic._CardData = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, -- 方块
                        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, -- 梅花
                        0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, -- 红桃
                        0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, -- 黑桃
                        0x4E, 0x4F } -- 小王,大王

GameLogic.GAME_PLAYER         = 3    -- 游戏人数
GameLogic.CARD_COUNT_NORMAL   = 17   -- 常规牌数
GameLogic.CARD_COUNT_MAX      = 20   -- 最大牌数
GameLogic.CARD_FULL_COUNT     = 54   -- 全牌数目

-- 扑克类型
GameLogic.CT_ERROR            = 0    -- 错误类型
GameLogic.CT_SINGLE           = 1    -- 单牌类型
GameLogic.CT_DOUBLE           = 2    -- 对牌类型
GameLogic.CT_THREE            = 3    -- 三条类型
GameLogic.CT_SINGLE_LINE      = 4    -- 单连类型
GameLogic.CT_DOUBLE_LINE      = 5    -- 对连类型
GameLogic.CT_THREE_LINE       = 6    -- 三连类型
GameLogic.CT_THREE_TAKE_ONE   = 7    -- 三带一单
GameLogic.CT_THREE_TAKE_TWO   = 8    -- 三带一对
GameLogic.CT_THREE_LINE_TAKE_ONE   = 9    -- 飞机带翅膀1
GameLogic.CT_THREE_LINE_TAKE_TWO   = 10    -- 飞机带翅膀2

GameLogic.CT_510K_FALSE    = 11    --非同花510k
GameLogic.CT_510K_TRUE    = 12    --同花510k
GameLogic.CT_BOMB_CARD    = 13    -- 炸弹类型


-- 创建空扑克数组
function GameLogic:emptyCardList( count )
    local tmp = {}
    for i = 1, count do
        tmp[i] = 0
    end
    return tmp
end

-- 获取余数
function GameLogic:mod(a, b)
    return a - math.floor(a/b)*b
end

-- 获取整数
function GameLogic:ceil(a, b)
    return math.ceil(a/b) - 1
end

-- 获取牌值(1-15)
function GameLogic:GetCardValue(nCardData)
    --return bit:_and(nCardData, 0X0F)    -- 数值掩码
    return yl.POKER_VALUE[nCardData]
end

-- 获取花色(1-5)
function GameLogic:GetCardColor(nCardData)
    --return bit:_and(nCardData, 0XF0)    --花色掩码
    return yl.POKER_COLOR[nCardData]
end

-- 逻辑牌值(大小王、2、A、K、Q)
function GameLogic:GetCardLogicValue(nCardData)
    local nCardValue = self:GetCardValue(nCardData)
    if 0 == nCardValue then
        return nCardValue
    end
    local nCardColor = self:GetCardColor(nCardData)
    if nCardColor == 0x40 then
        return nCardValue + 2
    end
    local Biggest = 2
    if false == GameLogic.m_b2Biggest then
        Biggest = 1
    end
    return nCardValue <= Biggest and (nCardValue + 13) or nCardValue
end

-- 获取牌序 0x4F大王 0x4E小王 nil牌背 
function GameLogic:GetCardIndex(nCardData)
    if nCardData == 0x4E then
       return 53
    elseif nCardData == 0x4F then
       return 54
    elseif nCardData == nil then
       return 55
    end
    local nCardValue = self:GetCardValue(nCardData)
    local nCardColor = self:GetCardColor(nCardData)
    nCardColor = bit:_rshift(nCardColor, 4)
    return nCardColor * 13 + nCardValue
end

--扑克排序
function GameLogic:SortCardList(cbCardData, cbCardCount, cbSortType)
    local cbSortValue = {}
    for i=1,cbCardCount do
        local value = self:GetCardLogicValue(cbCardData[i])
        table.insert(cbSortValue, i, value)
    end
    if cbSortType == 0 then --大小排序
        for i=1,cbCardCount-1 do
            for j=1,cbCardCount-1 do
                if (cbSortValue[j] < cbSortValue[j+1]) or (cbSortValue[j] == cbSortValue[j+1] and cbCardData[j] < cbCardData[j+1]) then
                    local temp = cbSortValue[j]
                    cbSortValue[j] = cbSortValue[j+1]
                    cbSortValue[j+1] = temp
                    local temp2 = cbCardData[j]
                    cbCardData[j] = cbCardData[j+1]
                    cbCardData[j+1] = temp2
                end
            end
        end
    end
    return cbCardData
end

--某牌位置
function GameLogic:GetOneCardIndex(cbCardData,nCardData)
    local index = 1
    local value = self:GetCardLogicValue(nCardData)
    local i = 1
    while i <= #cbCardData do
        if nCardData == cbCardData[i] then
            index = i
            break
        end
        i = i + 1
    end
    return index
end

--插入位置
function GameLogic:GetAddIndex(cbCardData,nCardData)
    local index = #cbCardData+1
    local value = self:GetCardLogicValue(nCardData)
    local i = 1
    while i <= #cbCardData do
        local value2 = self:GetCardLogicValue(cbCardData[i])
        if (value > value2) or (value == value2 and nCardData > cbCardData[i])  then
            index = i
            break
        end
        i = i + 1
    end
    --print("插入位置:".. value ..",".. index)
    return index
end

--插入一张牌
function GameLogic:AddOneCard(cbCardData,nCardData,index)
    local cardDatas = {}
    local total = #cbCardData+1
    for i=1,total-1 do
        cardDatas[i] = cbCardData[i]
    end
    for i=total,index+1,-1 do
        cardDatas[i] = cardDatas[i-1]
    end
    cardDatas[index] = nCardData
    return cardDatas
end

--删除一张牌
function GameLogic:RemoveOneCard(cbCardData,index)
    local cardDatas = {}
    local total = #cbCardData-1
    for i=1,index-1 do
        cardDatas[i] = cbCardData[i]
    end
    for i=index,total do
        cardDatas[i] = cbCardData[i+1]
    end
    return cardDatas
end

--分析有序扑克
function GameLogic:AnalysebCardData(cbCardData, cbCardCount)
    --相同个数
    local cbBlockCount = {0,0,0,0}
    --相同的牌
    local cbCardDatas = {{},{},{},{}}
    local i = 1
    while i <= cbCardCount do
        local cbSameCount = 1
        local cbLogicValue = self:GetCardLogicValue(cbCardData[i])

        local j = i+1
        while j <= cbCardCount do
            local cbLogicValue2 = self:GetCardLogicValue(cbCardData[j])
            if cbLogicValue ~= cbLogicValue2 or 0 == cbLogicValue or 0 == cbLogicValue2 then
                break
            end
            cbSameCount = cbSameCount + 1
            j = j + 1
        end
        if cbSameCount > 4 then
            print("这儿有错误 超过4张同样的牌")
            local tagAnalyseResult = {}
            return tagAnalyseResult
        end
        cbBlockCount[cbSameCount] = cbBlockCount[cbSameCount] + 1
        local index = cbBlockCount[cbSameCount] - 1
        for k=1,cbSameCount do
            cbCardDatas[cbSameCount][index*cbSameCount+k] = cbCardData[i+k-1]
        end
        i = i + cbSameCount
    end
    --分析结构
    local tagAnalyseResult = {cbBlockCount,cbCardDatas}
    return tagAnalyseResult
end

--对比扑克
function GameLogic:CompareCard(cbFirstCard,cbFirstCount,cbNextCard,cbNextCount)

    local cbNextType = GameLogic:GetCardType(cbNextCard, cbNextCount)
    local cbFirstType = GameLogic:GetCardType(cbFirstCard, cbFirstCount)
    --print("CompareCard cbNextType "..cbNextType.." cbFirstType " ..cbFirstType )
    if true then
        ---[[
        if ((cbFirstType < GameLogic.CT_510K_FALSE) and (cbNextType >= GameLogic.CT_510K_FALSE)) then
            return true
        end
        if ((cbFirstType >= GameLogic.CT_510K_FALSE) and (cbNextType <= GameLogic.CT_510K_FALSE)) then
            return false
        end
        if ((cbFirstType >= GameLogic.CT_510K_FALSE) and (cbNextType >= GameLogic.CT_510K_FALSE)) then
            --print("=========== CompareCard GameLogic.CT_510K_TRUE ===========",GameLogic.CT_510K_TRUE)
            if cbFirstType ==  GameLogic.CT_510K_TRUE and cbNextType ==  GameLogic.CT_510K_TRUE then
                local colorFirst = GameLogic:GetCardColor(cbFirstCard[1])
                local colorNext = GameLogic:GetCardColor(cbNextCard[1])
                --print("====== 510k ======= colorFirst "..colorFirst.." colorNext "..colorNext)
                return  colorNext > colorFirst
            else
                return cbNextType>cbFirstType
            end
            
        end
        --]]
        --四连顺和三连带
        if cbFirstCount==12 and cbNextCount==12 and cbFirstType+cbNextType == GameLogic.CT_THREE_LINE_TAKE_ONE+GameLogic.CT_THREE_LINE then
        
            if cbNextType == CT_THREE_LINE then
                cbNextType = GameLogic.CT_THREE_LINE_TAKE_ONE
            end
        end
    end

    if cbNextType == GameLogic.CT_ERROR then
        return false
    end
    if cbFirstCount == 0 and cbNextType ~= GameLogic.CT_ERROR then
        return true
    end

    if cbFirstType ~= GameLogic.CT_BOMB_CARD and cbNextType == GameLogic.CT_BOMB_CARD then
        return true
    end
    if cbFirstType == GameLogic.CT_BOMB_CARD and cbNextType ~= GameLogic.CT_BOMB_CARD then
        return false
    end
    if cbFirstType == GameLogic.CT_BOMB_CARD and cbNextType == GameLogic.CT_BOMB_CARD then
        local cbNextLogicValue=GetCardLogicValue(cbFirstCard[1]);
        local cbFirstLogicValue=GetCardLogicValue(cbNextCard[1]);
        return cbNextLogicValue>cbFirstLogicValue
    end
    if cbFirstType ~= cbNextType or cbFirstCount ~= cbNextCount then
        return false
    end
    --开始对比
    if (cbNextType == GameLogic.CT_SINGLE) or (cbNextType == GameLogic.CT_DOUBLE) or (cbNextType == GameLogic.CT_THREE) or (cbNextType == GameLogic.CT_SINGLE_LINE) or (cbNextType == GameLogic.CT_DOUBLE_LINE) or (cbNextType == GameLogic.CT_THREE_LINE)  or cbNextType ==  GameLogic.CT_510K_TRUE or (cbNextType == GameLogic.CT_BOMB_CARD) then
       local cbNextLogicValue = GameLogic:GetCardLogicValue(cbNextCard[1])
       local cbFirstLogicValue = GameLogic:GetCardLogicValue(cbFirstCard[1])
       return cbNextLogicValue > cbFirstLogicValue
    elseif cbNextType ==  GameLogic.CT_510K_FALSE then
        return false
    elseif (cbNextType == GameLogic.CT_THREE_TAKE_ONE) or (cbNextType == GameLogic.CT_THREE_TAKE_TWO) or (cbNextType == GameLogic.CT_THREE_LINE_TAKE_ONE) or (cbNextType == GameLogic.CT_THREE_LINE_TAKE_TWO) then
        local nextResult = GameLogic:AnalysebCardData(cbNextCard, cbNextCount)
        local firstResult = GameLogic:AnalysebCardData(cbFirstCard, cbFirstCount)
        local cbNextLogicValue = GameLogic:GetCardLogicValue(nextResult[2][3][1])
        local cbFirstLogicValue = GameLogic:GetCardLogicValue(firstResult[2][3][1])
        return cbNextLogicValue > cbFirstLogicValue
    end
    return false
end

--获取类型
function GameLogic:GetCardType(cbCardData, cbCardCount)
    --简单牌型
    if cbCardCount == 0 then        --空牌
        return GameLogic.CT_ERROR
    elseif cbCardCount == 1 then    --单牌
        return GameLogic.CT_SINGLE
    elseif cbCardCount == 2 then    --对牌火箭
        if cbCardData[1] == 0x4F and cbCardData[2] == 0x4E then
            return GameLogic.CT_MISSILE_CARD
        end
        if GameLogic:GetCardLogicValue(cbCardData[1]) == GameLogic:GetCardLogicValue(cbCardData[2]) then
            return GameLogic.CT_DOUBLE
        end
    end

    local tagAnalyseResult = {}
    tagAnalyseResult = GameLogic:AnalysebCardData(cbCardData, cbCardCount)
    --四牌判断
    if tagAnalyseResult[1][4] > 0 then
        if tagAnalyseResult[1][4] == 1 and cbCardCount == 4 then
            return GameLogic.CT_BOMB_CARD
        end
        return GameLogic.CT_ERROR
    end
    --510k
    if tagAnalyseResult[1][1] == 3 and cbCardCount == 3 then
        if GameLogic:GetCardValue(tagAnalyseResult[2][1][1]) == 0x0D and GameLogic:GetCardValue(tagAnalyseResult[2][1][2]) == 0x0A and GameLogic:GetCardValue(tagAnalyseResult[2][1][3]) == 0x05 then
            local color  = GameLogic:GetCardColor(tagAnalyseResult[2][1][1])
            if GameLogic:GetCardColor(tagAnalyseResult[2][1][2]) ~= color or GameLogic:GetCardColor(tagAnalyseResult[2][1][3])  ~= color then 
                return GameLogic.CT_510K_FALSE
            end
            return GameLogic.CT_510K_TRUE
        end 
    end
    print("三牌判断 tagAnalyseResult[1][3]",tagAnalyseResult[1][3],"cbCardCount",cbCardCount)
    --三牌判断
    if tagAnalyseResult[1][3] >= 1 then
        print("三牌判断 tagAnalyseResult[1][3]",tagAnalyseResult[1][3],"cbCardCount",cbCardCount)
        if tagAnalyseResult[1][3] == 1 then
            if cbCardCount == 3 then
                return GameLogic.CT_THREE
            elseif cbCardCount == 4 then
                return GameLogic.CT_THREE_TAKE_ONE
            elseif cbCardCount == 5 then
                return GameLogic.CT_THREE_TAKE_TWO
            end
        end
        local cbCardData = tagAnalyseResult[2][3][1];
        --print("cbCardData ",cbCardData)
        local cbFirstLogicValue = GameLogic:GetCardLogicValue(cbCardData);

        --错误过虑
        if cbFirstLogicValue >= 15 then
            return GameLogic.CT_ERROR
        end

        --连牌判断
        --print("连牌判断")
        ---s[[
        for i = 1,tagAnalyseResult[1][3] - 1 do
            local cbCardData = tagAnalyseResult[2][3][i*3 + 1]
            --print("cbCardData ",cbCardData,"i",i)
            --print("cbFirstLogicValue",cbFirstLogicValue,"GameLogic:GetCardLogicValue,cbCardData",GameLogic:GetCardLogicValue(cbCardData)+i)
            if cbFirstLogicValue + i ~= (GameLogic:GetCardLogicValue(cbCardData)) then
                return GameLogic.CT_ERROR
            end
        end
        --]]
        --print("三牌判断 after1")
        if tagAnalyseResult[1][3]*3 == cbCardCount then
        --print("三牌判断 CT_THREE_LINE")
           return GameLogic.CT_THREE_LINE
        end
        if tagAnalyseResult[1][3]*4 == cbCardCount then
        --print("三牌判断 CT_THREE_LINE_TAKE_ONE")
           return GameLogic.CT_THREE_LINE_TAKE_ONE
        end
        if tagAnalyseResult[1][3]*5 == cbCardCount then
        --print("三牌判断2 CT_THREE_LINE_TAKE_TWO")
           return GameLogic.CT_THREE_LINE_TAKE_TWO
        end
        return GameLogic.CT_ERROR
    end
    --两张判断
    if tagAnalyseResult[1][2] >= 2 then
        local cbCard = tagAnalyseResult[2][2][1]
        local cbFirstLogicValue = GameLogic:GetCardLogicValue(cbCard)
        if cbFirstLogicValue >= 15 then
            return GameLogic.CT_ERROR
        end
        for i=2,tagAnalyseResult[1][2] do
            local cbCard = tagAnalyseResult[2][2][(i-1)*2+1]
            local cbNextLogicValue = GameLogic:GetCardLogicValue(cbCard)
            if cbFirstLogicValue ~= cbNextLogicValue+i-1 then
                return GameLogic.CT_ERROR
            end
        end
        if tagAnalyseResult[1][2]*2 == cbCardCount then
            return GameLogic.CT_DOUBLE_LINE
        end
        return GameLogic.CT_ERROR
    end
    --单张判断
    --[[
    if tagAnalyseResult[1][1] >= 5 and tagAnalyseResult[1][1] == cbCardCount then
        local cbCard = tagAnalyseResult[2][1][1]
        local cbFirstLogicValue = GameLogic:GetCardLogicValue(cbCard)
        if cbFirstLogicValue >= 15 then
            return GameLogic.CT_ERROR
        end
        for i=2,tagAnalyseResult[1][1] do
            local cbCard = tagAnalyseResult[2][1][i]
            local cbNextLogicValue = GameLogic:GetCardLogicValue(cbCard)
            if cbFirstLogicValue ~= cbNextLogicValue+i-1 then
                return GameLogic.CT_ERROR
            end
        end
        return GameLogic.CT_SINGLE_LINE
    end
    --]]
    return GameLogic.CT_ERROR
end

--出牌搜索
function GameLogic:SearchOutCard(cbHandCardData,cbHandCardCount,cbTurnCardData,cbTurnCardCount) 
    -- print("出牌搜索")
    -- for i=1,cbTurnCardCount do
    --     print("前家扑克 " .. GameLogic:GetCardLogicValue(cbTurnCardData[i]))
    -- end
    -- for i=1,cbHandCardCount do
    --     print("下家扑克 " .. GameLogic:GetCardLogicValue(cbHandCardData[i]))
    -- end
    --结果数目
    local cbResultCount = 1
    --扑克数目
    local cbResultCardCount = {}
    --结果扑克
    local cbResultCard = {}
    --搜索结果
    local tagSearchCardResult = {cbResultCount-1,cbResultCardCount,cbResultCard}
    --排序扑克
    local cbCardData = GameLogic:SortCardList(cbHandCardData, cbHandCardCount, 0)
    local cbCardCount = cbHandCardCount
    --出牌分析
    local cbTurnOutType = GameLogic:GetCardType(cbTurnCardData, cbTurnCardCount)
    if cbTurnOutType == GameLogic.CT_ERROR then --错误类型
        --print("上家为空")
        --是否一手出完
        if GameLogic:GetCardType(cbCardData, cbCardCount) ~= GameLogic.CT_ERROR  then
            cbResultCardCount[cbResultCount] = cbCardCount
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = cbCardData
            cbResultCount = cbResultCount+1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --如果最小牌不是单牌，则提取
        local cbSameCount = 1
        if cbCardCount > 1 and (GameLogic:GetCardLogicValue(cbCardData[cbCardCount]) == GameLogic:GetCardLogicValue(cbCardData[cbCardCount-1])) then
            cbSameCount = 2
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount][1] = cbCardData[cbCardCount]
            local cbCardValue = GameLogic:GetCardLogicValue(cbCardData[cbCardCount])
            local i = cbCardCount - 1
            while i >= 1 do
                if GameLogic:GetCardLogicValue(cbCardData[i]) == cbCardValue then
                    cbResultCard[cbResultCount][cbSameCount] = cbCardData[i]
                    cbSameCount = cbSameCount + 1
                end
                i = i - 1
            end
            cbResultCardCount[cbResultCount] = cbSameCount-1
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --单牌
        local cbTmpCount = 1
        if cbSameCount ~= 2 then
            --print("单牌Pan")
            local tagSearchCardResult1 = GameLogic:SearchSameCard(cbCardData, cbCardCount, 0, 1)
            cbTmpCount = tagSearchCardResult1[1]
            if cbTmpCount > 0 then
                cbResultCardCount[cbResultCount] = tagSearchCardResult1[2][1]
                cbResultCard[cbResultCount] = {}
                cbResultCard[cbResultCount] = tagSearchCardResult1[3][1]
                cbResultCount = cbResultCount + 1
                tagSearchCardResult[2] = cbResultCardCount
                tagSearchCardResult[3] = cbResultCard
            end
        end
        --对牌
        if cbSameCount ~= 3 then
            local tagSearchCardResult1 = GameLogic:SearchSameCard(cbCardData, cbCardCount, 0, 2)
            cbTmpCount = tagSearchCardResult1[1]
            if cbTmpCount > 0 then
                cbResultCardCount[cbResultCount] = tagSearchCardResult1[2][1]
                cbResultCard[cbResultCount] = {}
                cbResultCard[cbResultCount] = tagSearchCardResult1[3][1]
                cbResultCount = cbResultCount + 1
                tagSearchCardResult[2] = cbResultCardCount
                tagSearchCardResult[3] = cbResultCard
            end
        end
        --三条
        if cbSameCount ~= 4 then
            local tagSearchCardResult1 = GameLogic:SearchSameCard(cbCardData, cbCardCount, 0, 3)
            cbTmpCount = tagSearchCardResult1[1]
            if cbTmpCount > 0 then
                cbResultCardCount[cbResultCount] = tagSearchCardResult1[2][1]
                cbResultCard[cbResultCount] = {}
                cbResultCard[cbResultCount] = tagSearchCardResult1[3][1]
                cbResultCount = cbResultCount + 1
                tagSearchCardResult[2] = cbResultCardCount
                tagSearchCardResult[3] = cbResultCard
            end
        end
        --三带一单
        --print("三带一单")
        local tagSearchCardResult2 = GameLogic:SearchTakeCardType(cbCardData, cbCardCount, 0, 3, 1)
        cbTmpCount = tagSearchCardResult2[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult2[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult2[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --print("三带一对")
        --三带一对
        local tagSearchCardResult3 = GameLogic:SearchTakeCardType(cbCardData, cbCardCount, 0, 3, 2)
        cbTmpCount = tagSearchCardResult3[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult3[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult3[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --单连
        --print("单连")
        local tagSearchCardResult4 = GameLogic:SearchLineCardType(cbCardData, cbCardCount, 0, 1, 0)
        cbTmpCount = tagSearchCardResult4[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult4[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult4[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --连对
        --print("连对")
        local tagSearchCardResult5 = GameLogic:SearchLineCardType(cbCardData, cbCardCount, 0, 2, 0)
        cbTmpCount = tagSearchCardResult5[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult5[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult5[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --三连
        --print("三连")
        local tagSearchCardResult6 = GameLogic:SearchLineCardType(cbCardData, cbCardCount, 0, 3, 0)
        cbTmpCount = tagSearchCardResult6[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult6[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult6[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --飞机
        --print("飞机")
        local tagSearchCardResult7 = GameLogic:SearchThreeTwoLine(cbCardData, cbCardCount)
        cbTmpCount = tagSearchCardResult7[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult7[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult7[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end
        --炸弹
        if cbSameCount ~= 5 then
            --print("炸弹")
            local tagSearchCardResult1 = GameLogic:SearchSameCard(cbCardData, cbCardCount, 0, 4)
            cbTmpCount = tagSearchCardResult1[1]
            if cbTmpCount > 0 then
                cbResultCardCount[cbResultCount] = tagSearchCardResult1[2][1]
                cbResultCard[cbResultCount] = {}
                cbResultCard[cbResultCount] = tagSearchCardResult1[3][1]
                cbResultCount = cbResultCount + 1
                tagSearchCardResult[2] = cbResultCardCount
                tagSearchCardResult[3] = cbResultCard
            end
        end
       
        tagSearchCardResult[1] = cbResultCount - 1
        return tagSearchCardResult
    elseif cbTurnOutType == GameLogic.CT_SINGLE or cbTurnOutType == GameLogic.CT_DOUBLE or cbTurnOutType == GameLogic.CT_THREE then
        --单牌、对牌、三条
        local cbReferCard = cbTurnCardData[1]
        local cbSameCount = 1
        if cbTurnOutType == GameLogic.CT_DOUBLE then
            cbSameCount = 2
        elseif cbTurnOutType == GameLogic.CT_THREE then
            cbSameCount = 3
        end
        local tagSearchCardResult21 = GameLogic:SearchSameCard(cbCardData, cbCardCount, cbReferCard, cbSameCount)
        cbResultCount = tagSearchCardResult21[1]
        cbResultCount = cbResultCount + 1
        cbResultCardCount = tagSearchCardResult21[2]
        tagSearchCardResult[2] = cbResultCardCount
        cbResultCard = tagSearchCardResult21[3]
        tagSearchCardResult[3] = cbResultCard
        tagSearchCardResult[1] = cbResultCount - 1

    elseif cbTurnOutType == GameLogic.CT_SINGLE_LINE or cbTurnOutType == GameLogic.CT_DOUBLE_LINE or cbTurnOutType == GameLogic.CT_THREE_LINE then
        --单连、对连、三连
        local cbBlockCount = 1
        if cbTurnOutType == GameLogic.CT_DOUBLE_LINE then
            cbBlockCount = 2
        elseif cbTurnOutType == GameLogic.CT_THREE_LINE then
            cbBlockCount = 3
        end
        local cbLineCount = cbTurnCardCount/cbBlockCount
        local tagSearchCardResult31 = GameLogic:SearchLineCardType(cbCardData, cbCardCount, cbTurnCardData[1], cbBlockCount, cbLineCount)
        cbResultCount = tagSearchCardResult31[1]
        cbResultCount = cbResultCount + 1
        cbResultCardCount = tagSearchCardResult31[2]
        tagSearchCardResult[2] = cbResultCardCount
        cbResultCard = tagSearchCardResult31[3]
        tagSearchCardResult[3] = cbResultCard
        tagSearchCardResult[1] = cbResultCount - 1

    elseif cbTurnOutType == GameLogic.CT_THREE_TAKE_ONE or cbTurnOutType == GameLogic.CT_THREE_TAKE_TWO then
        --三带一单、三带一对
        if cbCardCount >= cbTurnCardCount then
            if cbTurnCardCount == 4 or cbTurnCardCount == 5 then
                local cbTakeCardCount = (cbTurnOutType == GameLogic.CT_THREE_TAKE_ONE) and 1 or 2
                local tagSearchCardResult41 = GameLogic:SearchTakeCardType(cbCardData, cbCardCount, cbTurnCardData[3], 3, cbTakeCardCount)
                cbResultCount = tagSearchCardResult41[1]
                cbResultCount = cbResultCount + 1
                cbResultCardCount = tagSearchCardResult41[2]
                tagSearchCardResult[2] = cbResultCardCount
                cbResultCard = tagSearchCardResult41[3]
                tagSearchCardResult[3] = cbResultCard
                tagSearchCardResult[1] = cbResultCount - 1
            else
                local cbBlockCount = 3
                local cbLineCount = cbTurnCardCount/(cbTurnOutType==GameLogic.CT_THREE_TAKE_ONE and 4 or 5)
                local cbTakeCardCount = cbTurnOutType==GameLogic.CT_THREE_TAKE_ONE and 1 or 2

                --搜索连牌
                local cbTmpTurnCard = cbTurnCardData
                cbTmpTurnCard = GameLogic:SortOutCardList(cbTmpTurnCard,cbTurnCardCount)
                local tmpSearchResult = GameLogic:SearchLineCardType(cbCardData,cbCardCount,cbTmpTurnCard[1],cbBlockCount,cbLineCount)
                cbResultCount2 = tmpSearchResult[1]
                --提取带牌
                local bAllDistill = true
                for i=1,cbResultCount2 do
                    local cbResultIndex = cbResultCount2-i+1
                    local cbTmpCardData = {}
                    for i=1,#cbCardData do
                        cbTmpCardData[i] = cbCardData[i]
                    end
                    local cbTmpCardCount = cbCardCount

                    --删除连牌
                    local removeResult = GameLogic:RemoveCard(tmpSearchResult[3][cbResultIndex],tmpSearchResult[2][cbResultIndex],cbTmpCardData,cbTmpCardCount)
                    cbTmpCardData = removeResult[2]
                    cbTmpCardCount = cbTmpCardCount - tmpSearchResult[2][cbResultIndex]
                    --分析牌
                    local TmpResult = GameLogic:AnalysebCardData(cbTmpCardData,cbTmpCardCount)
                    --提取牌
                    local cbDistillCard = {}
                    local cbDistillCount = 0
                    local j = cbTakeCardCount
                    while j <= 4 do
                        if TmpResult[1][j] > 0 then
                            if j == cbTakeCardCount and TmpResult[1][j] >= cbLineCount then
                                local cbTmpBlockCount = TmpResult[1][j]
                                for k=1,j*cbLineCount do
                                    cbDistillCard[k] = TmpResult[2][j][(cbTmpBlockCount-cbLineCount)*j+k]
                                end
                                cbDistillCount = j*cbLineCount
                                break
                            else
                                local k = 1
                                while k <= TmpResult[1][j] do
                                    local cbTmpBlockCount = TmpResult[1][j]
                                    for l=1,cbTakeCardCount do
                                        cbDistillCard[cbDistillCount+l] = TmpResult[2][j][(cbTmpBlockCount-k)*j+l]
                                    end
                                    cbDistillCount = cbDistillCount + cbTakeCardCount
                                    --提取完成
                                    if (cbDistillCount == cbTakeCardCount*cbLineCount) then
                                        break
                                    end
                                    k = k + 1
                                end
                            end
                        end
                        --提取完成
                        if (cbDistillCount == cbTakeCardCount*cbLineCount) then
                            break
                        end
                        j = j + 1
                    end
                    --提取完成
                    if (cbDistillCount == cbTakeCardCount*cbLineCount) then
                        --复制带牌
                        local cbCount = tmpSearchResult[2][cbResultIndex]
                        for n=1,cbDistillCount do
                            tmpSearchResult[3][cbResultIndex][cbCount+n] = cbDistillCard[n]
                        end
                        tmpSearchResult[2][cbResultIndex] = tmpSearchResult[2][cbResultIndex] + cbDistillCount
                    else
                        --否则删除连牌
                        bAllDistill = false
                        tmpSearchResult[2][cbResultIndex] = 0
                    end
                end
                --整理组合
                tmpSearchResult[1] = cbResultCount2
                for i=1,tmpSearchResult[1] do
                    if tmpSearchResult[2][i] ~= 0 then
                        tagSearchCardResult[2][cbResultCount] = tmpSearchResult[2][i]
                        tagSearchCardResult[3][cbResultCount] = tmpSearchResult[3][i]
                        cbResultCount = cbResultCount + 1
                    end
                end
                tagSearchCardResult[1] = cbResultCount - 1
            end
        end
    elseif cbTurnOutType == GameLogic.CT_510K_FALSE or cbTurnOutType == GameLogic.CT_510K_TRUE then
        local tagSearchCardResult2 = GameLogic:Search510K(cbCardData, cbCardCount,cbTurnOutType - GameLogic.CT_510K_FALSE + 1, GameLogic:GetCardColor(cbTurnCardData[3]))
        cbTmpCount = tagSearchCardResult2[1]
        if cbTmpCount > 0 then
            cbResultCardCount[cbResultCount] = tagSearchCardResult2[2][1]
            cbResultCard[cbResultCount] = {}
            cbResultCard[cbResultCount] = tagSearchCardResult2[3][1]
            cbResultCount = cbResultCount + 1
            tagSearchCardResult[2] = cbResultCardCount
            tagSearchCardResult[3] = cbResultCard
        end

        
    elseif cbTurnOutType == GameLogic.CT_FOUR_TAKE_ONE or cbTurnOutType == GameLogic.CT_FOUR_TAKE_TWO then
        --四带两单、四带两双
        local cbTakeCardCount = (cbTurnOutType == GameLogic.CT_FOUR_TAKE_ONE) and 1 or 2
        local cbTmpTurnCard = GameLogic:SortOutCardList(cbTurnCardData,cbTurnCardCount)
        local tagSearchCardResult51 = GameLogic:SearchTakeCardType(cbCardData, cbCardCount, cbTmpTurnCard[1], 4, cbTakeCardCount)
        cbResultCount = tagSearchCardResult51[1]
        cbResultCount = cbResultCount + 1
        cbResultCardCount = tagSearchCardResult51[2]
        tagSearchCardResult[2] = cbResultCardCount
        cbResultCard = tagSearchCardResult51[3]
        tagSearchCardResult[3] = cbResultCard
        tagSearchCardResult[1] = cbResultCount - 1
    end

    --搜索510k
    if (cbCardCount >= 3 and cbTurnOutType < GameLogic.CT_510K_FALSE) then
        local tagSearchCardResult2 = GameLogic:Search510K(cbCardData, cbCardCount, 0, 0)
        local cbTmpResultCount = tagSearchCardResult2[1]
        for i=1,cbTmpResultCount do
            cbResultCardCount[cbResultCount] = tagSearchCardResult2[2][i]
            tagSearchCardResult[2] = cbResultCardCount
            cbResultCard[cbResultCount] = tagSearchCardResult2[3][i]
            tagSearchCardResult[3] = cbResultCard
            cbResultCount = cbResultCount + 1
        end
        tagSearchCardResult[1] = cbResultCount - 1
    end
    --搜索炸弹
    if (cbCardCount >= 4 ) then
        local cbReferCard = 0
        if cbTurnOutType == GameLogic.CT_BOMB_CARD then
            cbReferCard = cbTurnCardData[1]
        end
        --搜索炸弹
        local tagSearchCardResult61 = GameLogic:SearchSameCard(cbCardData,cbCardCount,cbReferCard,4)
        local cbTmpResultCount = tagSearchCardResult61[1]
        for i=1,cbTmpResultCount do
            cbResultCardCount[cbResultCount] = tagSearchCardResult61[2][i]
            tagSearchCardResult[2] = cbResultCardCount
            cbResultCard[cbResultCount] = tagSearchCardResult61[3][i]
            tagSearchCardResult[3] = cbResultCard
            cbResultCount = cbResultCount + 1
        end
        tagSearchCardResult[1] = cbResultCount - 1
    end

    return tagSearchCardResult
end

--同牌搜索
function GameLogic:SearchSameCard(cbHandCardData, cbHandCardCount, cbReferCard, cbSameCardCount)
    --结果数目
    local cbResultCount = 1
    --扑克数目
    local cbResultCardCount = {}
    --结果扑克
    local cbResultCard = {}
    --搜索结果
    local tagSearchCardResult = {cbResultCount-1,cbResultCardCount,cbResultCard}
    --排序扑克
    local cbCardData = GameLogic:SortCardList(cbHandCardData, cbHandCardCount, 0)
    local cbCardCount = cbHandCardCount
    --分析结构
    local tagAnalyseResult = GameLogic:AnalysebCardData(cbCardData, cbCardCount)
    --dump(tagAnalyseResult, "tagAnalyseResult", 6)
    local cbReferLogicValue = (cbReferCard == 0 and 0 or GameLogic:GetCardLogicValue(cbReferCard))
    local cbBlockIndex = cbSameCardCount
    while cbBlockIndex <= 4 do
        for i=1,tagAnalyseResult[1][cbBlockIndex] do
            local cbIndex = (tagAnalyseResult[1][cbBlockIndex]-i)*cbBlockIndex+1
            local cbNowLogicValue = GameLogic:GetCardLogicValue(tagAnalyseResult[2][cbBlockIndex][cbIndex])
            if cbNowLogicValue > cbReferLogicValue then
                cbResultCardCount[cbResultCount] = cbSameCardCount
                tagSearchCardResult[2] = cbResultCardCount
                cbResultCard[cbResultCount] = {}
                cbResultCard[cbResultCount][1] = tagAnalyseResult[2][cbBlockIndex][cbIndex]
                for i=2,cbBlockIndex do
                    cbResultCard[cbResultCount][i] = tagAnalyseResult[2][cbBlockIndex][cbIndex+i-1]
                end --此处修改
                tagSearchCardResult[3] = cbResultCard
                cbResultCount = cbResultCount + 1
            end
        end
        cbBlockIndex = cbBlockIndex + 1
    end
    tagSearchCardResult[1] = cbResultCount - 1
    return tagSearchCardResult
end

--带牌类型搜索(三带一，四带一等)
function GameLogic:SearchTakeCardType(cbHandCardData, cbHandCardCount, cbReferCard, cbSameCount, cbTakeCardCount)
    --结果数目
    local cbResultCount = 1
    --扑克数目
    local cbResultCardCount = {}
    --结果扑克
    local cbResultCard = {}
    --搜索结果
    local tagSearchCardResult = {cbResultCount-1,cbResultCardCount,cbResultCard}
    if cbSameCount ~= 3 and cbSameCount ~= 4 then
        return tagSearchCardResult
    end
    if cbTakeCardCount ~= 1 and cbTakeCardCount ~= 2 then
        return tagSearchCardResult
    end
    if (cbSameCount == 4) and (cbHandCardCount < cbSameCount+cbTakeCardCount*2 or cbHandCardCount < cbSameCount+cbTakeCardCount) then
        return tagSearchCardResult
    end
    --排序扑克
    local cbCardData = GameLogic:SortCardList(cbHandCardData, cbHandCardCount, 0)
    local cbCardCount = cbHandCardCount
    
    local sameCardResult = {}
    sameCardResult = GameLogic:SearchSameCard(cbCardData, cbCardCount, cbReferCard, cbSameCount)
    local cbSameCardResultCount = sameCardResult[1]

    if cbSameCardResultCount > 0 then
        --分析结构
        local tagAnalyseResult = GameLogic:AnalysebCardData(cbCardData, cbCardCount)
        --需要牌数
        local cbNeedCount = cbSameCount + cbTakeCardCount
        if cbSameCount == 4 then
            cbNeedCount = cbNeedCount + cbTakeCardCount
        end
        --提取带牌
        for i=1,cbSameCardResultCount do
            local bMere = false
            local j = cbTakeCardCount
            while j <= 4 do
                local k = 1
                while k <= tagAnalyseResult[1][j]  do
                    --从小到大
                    local cbIndex = (tagAnalyseResult[1][j]-k)*j+1
                    if GameLogic:GetCardLogicValue(sameCardResult[3][i][1]) ~= GameLogic:GetCardLogicValue(tagAnalyseResult[2][j][cbIndex]) then
                        --复制带牌
                        local cbCount = sameCardResult[2][i]
                        for l=1,cbTakeCardCount do
                            sameCardResult[3][i][cbCount+l] = tagAnalyseResult[2][j][cbIndex+l-1]
                        end
                        sameCardResult[2][i] = sameCardResult[2][i] + cbTakeCardCount
                        if sameCardResult[2][i] >= cbNeedCount then
                            --复制结果
                            cbResultCardCount[cbResultCount] = sameCardResult[2][i]
                            tagSearchCardResult[2] = cbResultCardCount
                            cbResultCard[cbResultCount] = {}
                            cbResultCard[cbResultCount] = sameCardResult[3][i]
                            tagSearchCardResult[3] = cbResultCard
                            cbResultCount = cbResultCount + 1
                            tagSearchCardResult[1] = cbResultCount - 1
                            bMere = true
                            --下一组合
                            break
                        end
                    end
                    k = k+1
                end
                if bMere == true then
                    break
                end
                j = j + 1
            end
        end
    end
    tagSearchCardResult[1] = cbResultCount - 1
    return tagSearchCardResult
end

--连牌搜索
function GameLogic:SearchLineCardType(cbHandCardData, cbHandCardCount, cbReferCard, cbBlockCount, cbLineCount)
    --结果数目
    local cbResultCount = 1
    --扑克数目
    local cbResultCardCount = {}
    --结果扑克
    local cbResultCard = {}
    --搜索结果
    local tagSearchCardResult = {cbResultCount-1,cbResultCardCount,cbResultCard}
    --排序扑克
    local cbCardData = GameLogic:SortCardList(cbHandCardData, cbHandCardCount, 0)
    local cbCardCount = cbHandCardCount
    --连牌最少数
    local cbLessLineCount = 0
    if cbLineCount == 0 then
        if cbBlockCount == 1 then
            cbLessLineCount = 5
        elseif cbBlockCount == 2 then
            cbLessLineCount = 3
        else
            cbLessLineCount = 2
        end
    else
        cbLessLineCount = cbLineCount
    end
    --print("连牌最少数 " .. cbLessLineCount)
    local cbReferIndex = 3
    if cbReferCard ~= 0 then
        if (GameLogic:GetCardLogicValue(cbReferCard)-cbLessLineCount) >= 2 then
            cbReferIndex = GameLogic:GetCardLogicValue(cbReferCard)-cbLessLineCount+1+1
        end
    end 
    --超过A
    if cbReferIndex+cbLessLineCount > 15 then
        return tagSearchCardResult
    end
    --长度判断
    if cbHandCardCount < cbLessLineCount*cbBlockCount then
        return tagSearchCardResult
    end
   -- print("搜索顺子开始点 " .. cbReferIndex)
    local Distributing = GameLogic:AnalysebDistributing(cbCardData, cbCardCount)
    --搜索顺子
    local cbTmpLinkCount = 0
    local cbValueIndex=cbReferIndex
    local flag = false
    while cbValueIndex <= 13 do
        if cbResultCard[cbResultCount] == nil then
            cbResultCard[cbResultCount] = {}
        end
        if Distributing[2][cbValueIndex][6] < cbBlockCount then
            if cbTmpLinkCount < cbLessLineCount  then
                cbTmpLinkCount = 0
                flag = false
            else
                cbValueIndex = cbValueIndex - 1
                flag = true
            end
        else
            cbTmpLinkCount = cbTmpLinkCount + 1
            if cbLineCount == 0 then
                flag = false
            else
                flag = true
            end
        end
        if flag == true then
            flag = false
            if cbTmpLinkCount >= cbLessLineCount then
                --复制扑克
                local cbCount = 0
                local cbIndex=(cbValueIndex-cbTmpLinkCount+1)
                while cbIndex <= cbValueIndex do
                    local cbTmpCount = 0
                    local cbColorIndex=1
                    while cbColorIndex <= 4 do --在四色中取一个
                        local cbColorCount = 1
                        while cbColorCount <= Distributing[2][cbIndex][5-cbColorIndex] do
                            cbCount = cbCount + 1
                            cbResultCard[cbResultCount][cbCount] = GameLogic:MakeCardData(cbIndex,5-cbColorIndex-1)
                            tagSearchCardResult[3][cbResultCount] = cbResultCard[cbResultCount]
                            cbTmpCount = cbTmpCount + 1
                            if cbTmpCount == cbBlockCount then
                                break
                            end
                            cbColorCount = cbColorCount + 1
                        end
                        if cbTmpCount == cbBlockCount then
                            break
                        end
                        cbColorIndex = cbColorIndex + 1
                    end
                    cbIndex = cbIndex + 1
                end
                tagSearchCardResult[2][cbResultCount] = cbCount
                cbResultCount = cbResultCount + 1
                if cbLineCount ~= 0 then
                    cbTmpLinkCount = cbTmpLinkCount - 1
                else
                    cbTmpLinkCount = 0
                end
            end
        end
        cbValueIndex = cbValueIndex + 1
    end

    --特殊顺子(寻找A)
    if cbTmpLinkCount >= cbLessLineCount-1 and cbValueIndex == 14 then
        --print("特殊顺子(寻找A)")
        if (Distributing[2][1][6] >= cbBlockCount) or (cbTmpLinkCount >= cbLessLineCount) then
            if cbResultCard[cbResultCount] == nil then
                cbResultCard[cbResultCount] = {}
            end
            --复制扑克
            local cbCount = 0
            local cbIndex=(cbValueIndex-cbTmpLinkCount)
            while cbIndex <= 13 do
                local cbTmpCount = 0
                local cbColorIndex=1
                while cbColorIndex <= 4 do --在四色中取一个
                    local cbColorCount = 1
                    while cbColorCount <= Distributing[2][cbIndex][5-cbColorIndex] do
                        cbCount = cbCount + 1
                        cbResultCard[cbResultCount][cbCount] = GameLogic:MakeCardData(cbIndex,5-cbColorIndex-1)
                        tagSearchCardResult[3][cbResultCount] = cbResultCard[cbResultCount]

                        cbTmpCount = cbTmpCount + 1
                        if cbTmpCount == cbBlockCount then
                            break
                        end
                        cbColorCount = cbColorCount + 1
                    end
                    if cbTmpCount == cbBlockCount then
                        break
                    end
                    cbColorIndex = cbColorIndex + 1
                end
                cbIndex = cbIndex + 1
            end
            --复制A
            if Distributing[2][1][6] >= cbBlockCount then
                local cbTmpCount = 0
                local cbColorIndex=1
                while cbColorIndex <= 4 do --在四色中取一个
                    local cbColorCount = 1
                    while cbColorCount <= Distributing[2][1][5-cbColorIndex] do
                        cbCount = cbCount + 1
                        cbResultCard[cbResultCount][cbCount] = GameLogic:MakeCardData(1,5-cbColorIndex-1)
                        tagSearchCardResult[3][cbResultCount] = cbResultCard[cbResultCount]

                        cbTmpCount = cbTmpCount + 1
                        if cbTmpCount == cbBlockCount then
                            break
                        end
                        cbColorCount = cbColorCount + 1
                    end
                    if cbTmpCount == cbBlockCount then
                        break
                    end
                    cbColorIndex = cbColorIndex + 1
                end
            end
            tagSearchCardResult[2][cbResultCount] = cbCount
            cbResultCount = cbResultCount + 1
        end
    end
    tagSearchCardResult[1] = cbResultCount - 1
    return tagSearchCardResult
end

--飞机搜索
function GameLogic:SearchThreeTwoLine(cbHandCardData, cbHandCardCount)
    --print("飞机搜索")
    --结果数目
    local cbSearchCount = 0
    --扑克数目
    local cbResultCardCount = {}
    --结果扑克
    local cbResultCard = {}
    --搜索结果
    local tagSearchCardResult = {cbSearchCount,cbResultCardCount,cbResultCard}
    local tmpSingleWing = {cbSearchCount,cbResultCardCount,cbResultCard}
    local tmpDoubleWing = {cbSearchCount,cbResultCardCount,cbResultCard}

    --排序扑克
    local cbCardData = GameLogic:SortCardList(cbHandCardData, cbHandCardCount, 0)
    local cbCardCount = cbHandCardCount

    local cbTmpResultCount = 0

    --搜索连牌
    local tmpSearchResult = GameLogic:SearchLineCardType(cbHandCardData,cbHandCardCount,0,3,0)
    cbTmpResultCount = tmpSearchResult[1]
    if cbTmpResultCount > 0 then
        --提取带牌
        local i = 1
        while i <= cbTmpResultCount do
            local flag = true
            local cbTmpCardData = {}
            local cbTmpCardCount = cbHandCardCount
            --不够牌
            if cbHandCardCount-tmpSearchResult[2][i] < tmpSearchResult[2][i]/3 then
                local cbNeedDelCount = 3
                while (cbHandCardCount + cbNeedDelCount - tmpSearchResult[2][i]) < (tmpSearchResult[2][i]-cbNeedDelCount)/3 do
                    cbNeedDelCount = cbNeedDelCount + 3
                end
                --不够连牌
                if (tmpSearchResult[2][i]-cbNeedDelCount)/3 < 2 then
                    flag = false
                else
                    flag = true
                end
                if flag == true then
                    --拆分连牌
                    local removeResult= GameLogic:RemoveCard(tmpSearchResult[3][i],cbNeedDelCount,tmpSearchResult[3][i],tmpSearchResult[2][i])
                    tmpSearchResult[3][i] = removeResult[2]
                    tmpSearchResult[2][i] = tmpSearchResult[2][i] - cbNeedDelCount
                end
            end
            if flag == true then
                flag = false
                --删除连牌
                for temp=1,#cbHandCardData do
                    cbTmpCardData[temp] = cbHandCardData[temp]
                end
                local removeResult1= GameLogic:RemoveCard(tmpSearchResult[3][i],tmpSearchResult[2][i],cbTmpCardData,cbTmpCardCount)
                cbTmpCardData = removeResult1[2]
                cbTmpCardCount = cbTmpCardCount - tmpSearchResult[2][i]

                --组合飞机
                local cbNeedCount = tmpSearchResult[2][i]/3
                local cbResultCount = tmpSingleWing[1]+1
                tmpSingleWing[3][cbResultCount] = tmpSearchResult[3][i]
                for j=1,cbNeedCount do
                    tmpSingleWing[3][cbResultCount][tmpSearchResult[2][i]+j] = cbTmpCardData[cbTmpCardCount-cbNeedCount+j]
                end
                tmpSingleWing[2][i] = tmpSearchResult[2][i] + cbNeedCount
                tmpSingleWing[1] = tmpSingleWing[1]+1

                local flag2 = true
                --不够带翅膀
                if cbTmpCardCount < tmpSearchResult[2][i]/3*2 then
                    local cbNeedDelCount = 3
                    while (cbTmpCardCount + cbNeedDelCount - tmpSearchResult[2][i]) < (tmpSearchResult[2][i]-cbNeedDelCount)/3*2 do
                        cbNeedDelCount = cbNeedDelCount + 3
                    end
                    --不够连牌
                    if (tmpSearchResult[2][i]-cbNeedDelCount)/3 < 2 then
                        flag2 = false
                    else
                        flag2 = true
                    end
                    if flag2 == true then
                        --拆分连牌
                        local removeResult= GameLogic:RemoveCard(tmpSearchResult[3][i],cbNeedDelCount,tmpSearchResult[3][i],tmpSearchResult[2][i])
                        tmpSearchResult[3][i] = removeResult[2]
                        tmpSearchResult[2][i] = tmpSearchResult[2][i] - cbNeedDelCount

                        --重新删除连牌
                        for temp=1,#cbHandCardData do
                            cbTmpCardData[temp] = cbHandCardData[temp]
                        end
                        local removeResult2= GameLogic:RemoveCard(tmpSearchResult[3][i],tmpSearchResult[2][i],cbTmpCardData,cbTmpCardCount)
                        cbTmpCardData = removeResult2[2]
                        cbTmpCardCount = cbTmpCardCount - tmpSearchResult[2][i]
                    end
                end
                if flag2 == true then
                    flag2 = false
                    --分析牌
                    local TmpResult = {}
                    TmpResult = GameLogic:AnalysebCardData(cbTmpCardData, cbTmpCardCount)
                    --提取翅膀
                    local cbDistillCard = {}
                    local cbDistillCount = 0
                    local cbLineCount = tmpSearchResult[2][i]/3
                    local j = 2
                    while j <= 4 do
                        if TmpResult[1][j] > 0 then
                            if (j+1 == 3) and TmpResult[1][j] >= cbLineCount then
                                local  cbTmpBlockCount = TmpResult[1][j]
                                for k=1,j*cbLineCount do
                                    cbDistillCard[k] = TmpResult[2][j][(cbTmpBlockCount-cbLineCount)*j+k]
                                end
                                cbDistillCount = j*cbLineCount
                            else
                                local k = 1
                                while k <= TmpResult[1][j] do
                                    local cbTmpBlockCount = TmpResult[1][j]
                                    for l=1,2 do
                                        cbDistillCard[cbDistillCount+l] = TmpResult[2][j][(cbTmpBlockCount-k)*j+l]
                                    end
                                    cbDistillCount = cbDistillCount + 2

                                    --提取完成
                                    if cbDistillCount == 2*cbLineCount then
                                        break
                                    end
                                    k = k + 1
                                end
                            end
                        end
                        --提取完成
                        if cbDistillCount == 2*cbLineCount then
                            break
                        end
                        j = j + 1
                    end
                    
                    --提取完成
                    if cbDistillCount == 2*cbLineCount then
                        --print("复制两对")
                        --复制翅膀
                        tmpDoubleWing[1] = tmpDoubleWing[1]+1
                        cbResultCount = tmpDoubleWing[1]
                        tmpDoubleWing[3][cbResultCount] = tmpSearchResult[3][i]
                        for n=1,cbDistillCount do
                            tmpDoubleWing[3][cbResultCount][tmpSearchResult[2][i]+n] = cbDistillCard[n]
                        end
                        tmpDoubleWing[2][cbResultCount] = tmpSearchResult[2][i] + cbDistillCount
                    end
                end
            end
            i = i + 1
        end
        --复制结果
        for m=1,tmpDoubleWing[1] do
            tagSearchCardResult[1] = tagSearchCardResult[1] + 1
            local cbResultCount = tagSearchCardResult[1]
            tagSearchCardResult[3][cbResultCount] = tmpDoubleWing[3][m]
            tagSearchCardResult[2][cbResultCount] = tmpDoubleWing[2][m]
        end
        for m=1,tmpSingleWing[1] do
            tagSearchCardResult[1] = tagSearchCardResult[1] + 1
            local cbResultCount = tagSearchCardResult[1]
            tagSearchCardResult[3][cbResultCount] = tmpSingleWing[3][m]
            tagSearchCardResult[2][cbResultCount] = tmpSingleWing[2][m]
        end
    end
    return tagSearchCardResult
end

---[[
function GameLogic:Search510K(cbHandCardData,cbHandCardCount,mode,color)
    
    --结果数目
    local cbResultCount = 1
    --扑克数目
    local cbResultCardCount = {}
    --结果扑克
    local cbResultCard = {}
    --搜索结果
    local tagSearchCardResult = {cbResultCount - 1,cbResultCardCount,cbResultCard}

    --排序扑克
    local cbCardData = GameLogic:SortCardList(cbHandCardData, cbHandCardCount,0)
    local cbCardCount = cbHandCardCount

    --dump(cbCardData, "-------------- SortCardList  cbCardData -------------", 6)
    
    local count5 = 0
    local card5 = {0,0,0,0}
    local count10 = 0
    local card10 = {0,0,0,0}
    local countK = 0
    local cardK = {0,0,0,0}
    ---[[
    for i = 1, cbHandCardCount do
        if GameLogic:GetCardLogicValue(cbCardData[i]) == 5 then
            card5[count5 + 1] = cbCardData[i]
            count5 = count5 + 1;
        elseif GameLogic:GetCardLogicValue(cbCardData[i]) == 0x0A then
            card10[count10 + 1] = cbCardData[i]
            count10 = count10 + 1;
        elseif GameLogic:GetCardLogicValue(cbCardData[i]) == 0x0D then
            cardK[countK + 1]=cbCardData[i]
            countK = countK + 1
        end
    end
    --]]
    --dump(card5, "-- card5 --", 6)
    --dump(card10, "-- card10 --", 6)
    --dump(cardK, "-- cardK --", 6)
    --print("------------ Search510K count5 count10 countK--------------",count5,count10,countK)
    if count5 == 0 or count10 == 0 or countK == 0 then
        tagSearchCardResult[1] = 0
        return tagSearchCardResult
    end
    
    local bAddFalse = false
    for  i=1,count5 do
        local cbColor = GameLogic:GetCardColor(card5[i])
        local bFindTrue=false
        for  j= 1,count10 do
            if GameLogic:GetCardColor(card10[j]) == cbColor then
                for k = 1,countK do
                    if GameLogic:GetCardColor(cardK[k]) == cbColor then
                        bFindTrue = true
                        if mode <2 or cbColor > color then
                            if nil == tagSearchCardResult[3][cbResultCount] then
                                tagSearchCardResult[3][cbResultCount] = {}
                            end
                            
                            tagSearchCardResult[3][cbResultCount][1] = card5[i]
                            tagSearchCardResult[3][cbResultCount][2] = card10[j]
                            tagSearchCardResult[3][cbResultCount][3] = cardK[k]
                            tagSearchCardResult[2][cbResultCount] = 3
                            cbResultCount = cbResultCount + 1
                        end
                        break
                    end
                end
                if true == bFindTrue then
                    break
                end
            end
        end

        if false == bFindTrue and  false == bAddFalse and mode == 0 then--添加一个假的
            bAddFalse = true 
            --print("cbResultCount "..cbResultCount)
            if nil == tagSearchCardResult[3][cbResultCount] then
                tagSearchCardResult[3][cbResultCount] = {}
            end
            tagSearchCardResult[3][cbResultCount][1] = card5[i]
            tagSearchCardResult[3][cbResultCount][2] = card10[1]
            tagSearchCardResult[3][cbResultCount][3] = cardK[1]
            tagSearchCardResult[2][cbResultCount] = 3
            cbResultCount = cbResultCount + 1
        end
    end

    tagSearchCardResult[1] = cbResultCount
    dump(tagSearchCardResult, "Search510K tagSearchCardResult, ", 6)   
    return tagSearchCardResult
    
end

--分析分布
function GameLogic:AnalysebDistributing(cbCardData, cbCardCount)
    local cbCardCount1 = 0
    local cbDistributing = {}
    for i=1,15 do
        local distributing = {}
        for j=1,6 do
            distributing[j] = 0
        end
        cbDistributing[i] = distributing
    end
    local Distributing = {cbCardCount1,cbDistributing}
    for i=1,cbCardCount do
        if cbCardData[i]~=0 then
            local cbCardColor = GameLogic:GetCardColor(cbCardData[i])
            local cbCardValue = GameLogic:GetCardValue(cbCardData[i])
            --分布信息
            cbCardCount1 = cbCardCount1 + 1
            cbDistributing[cbCardValue][5+1] = cbDistributing[cbCardValue][6]+1
            local color = bit:_rshift(cbCardColor,4) + 1
            cbDistributing[cbCardValue][color] = cbDistributing[cbCardValue][color]+1
        end
    end
    Distributing[1] = cbCardCount1
    Distributing[2] = cbDistributing
    -- print("总数：" .. Distributing[1])
    -- for i=1,15 do
    --     print("每张总数：" .. Distributing[2][i][6])
    -- end
    return Distributing
end

--构造扑克
function GameLogic:MakeCardData(cbValueIndex,cbColorIndex)
    --print("构造扑克 " ..bit:_or(bit:_lshift(cbColorIndex,4),cbValueIndex)..",".. GameLogic:GetCardLogicValue(bit:_or(bit:_lshift(cbColorIndex,4),cbValueIndex)))
    return bit:_or(bit:_lshift(cbColorIndex,4),cbValueIndex)
end

---删除扑克
function GameLogic:RemoveCard(cbRemoveCard, cbRemoveCount, cbCardData, cbCardCount)
    local cbDeleteCount=0
    local cbTempCardData = {}
    for i=1,#cbCardData do
        cbTempCardData[i] = cbCardData[i]
    end
    local result = {false,cbCardData}
    --置零扑克
    local i = 1
    while i <= cbRemoveCount do
        local j = 1
        while j < cbCardCount do
            if cbRemoveCard[i] == cbTempCardData[j] then
                cbDeleteCount = cbDeleteCount + 1
                cbTempCardData[j] = 0
                break
            end
            j = j + 1
        end
        i = i + 1
    end
    if cbDeleteCount ~= cbRemoveCount then
        return result
    end
    --清理扑克
    local cbCardPos=1
    local datas = {}
    for i=1,cbCardCount do
        if cbTempCardData[i] ~= 0 then
            datas[cbCardPos] = cbTempCardData[i]
            cbCardPos = cbCardPos + 1
        end
    end
    result = {true,datas}
    return result
end 

--排列扑克
function GameLogic:SortOutCardList(cbCardData,cbCardCount)
    local resultCardData = {}
    local resultCardCount = 0
    --获取牌型
    local cbCardType = GameLogic:GetCardType(cbCardData,cbCardCount)
    if cbCardType == GameLogic.CT_THREE_TAKE_ONE or cbCardType == GameLogic.CT_THREE_TAKE_TWO then
        --分析牌
        local AnalyseResult = {}
        AnalyseResult = GameLogic:AnalysebCardData(cbCardData,cbCardCount)

        resultCardCount = AnalyseResult[1][3]*3
        resultCardData = AnalyseResult[2][3]
        
        for i=4,1,-1 do
            if i ~= 3 then
                if AnalyseResult[1][i] > 0 then
                    for j=1,AnalyseResult[1][i]*i do
                        resultCardData[resultCardCount+j] = AnalyseResult[2][i][j]
                    end
                    resultCardCount = resultCardCount + AnalyseResult[1][i]*i
                end
            end
        end
       
    elseif cbCardType == GameLogic.CT_FOUR_TAKE_ONE or cbCardType == GameLogic.CT_FOUR_TAKE_TWO then
        --分析牌
        local AnalyseResult = {}
        AnalyseResult = GameLogic:AnalysebCardData(cbCardData,cbCardCount)

        resultCardCount = AnalyseResult[1][4]*4
        resultCardData = AnalyseResult[2][4]
        
        for i=4,1,-1 do
            if i ~= 3 then
                if AnalyseResult[1][i] > 0 then
                    for j=1,AnalyseResult[1][i]*i do
                        resultCardData[resultCardCount+j] = AnalyseResult[2][i][j]
                    end
                    resultCardCount = resultCardCount + AnalyseResult[1][i]*i
                end
            end
        end
    end
    return resultCardData
end



return GameLogic
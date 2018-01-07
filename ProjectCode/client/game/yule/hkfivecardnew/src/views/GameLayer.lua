local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")

local GameLayer = class("GameLayer", GameModel)

local cmd = appdf.req(appdf.GAME_SRC.."yule.hkfivecardnew.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.hkfivecardnew.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.hkfivecardnew.src.views.layer.GameViewLayer")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationMgr = require(appdf.EXTERNAL_SRC .. "AnimationMgr")
local g_var = ExternalFun.req_var
-- 初始化界面
function GameLayer:ctor(frameEngine,scene)
    GameLayer.super.ctor(self,frameEngine,scene)
end

-- 创建场景
function GameLayer:CreateView()
    cc.FileUtils:getInstance():addSearchPath(device.writablePath..cmd.RES_PATH,true)
    return GameViewLayer:create(self)
        :addTo(self)
end

-- 初始化游戏数据
function GameLayer:OnInitGameEngine()

    GameLayer.super.OnInitGameEngine(self)

    self.m_wCurrentUser = yl.INVALID_CHAIR               --当前用户
    self.m_wWinnerUser = yl.INVALID_CHAIR               --赢的用户
    self.m_wAddUser = yl.INVALID_CHAIR                  --上一个加分的用户
    self.m_lUserScore = {0,0,0,0,0}                      --用户原来的分数
    self.m_UserCurScore = {0,0,0,0,0}                    --用户当前的分数
    self.m_cbPlayStatus = {0,0,0,0,0}                    --游戏状态
    self.m_lTableScore = {0,0,0,0,0}                     --下注数目
    self.m_giveUpPlayer = {0,0,0,0,0}                    --没参与游戏或者放弃游戏  
    self.m_lTotalScore = {0,0,0,0,0}                    --每个用户总共的下注
    self.m_handCardArray = {{},{},{},{},{}}              --各个玩家的手牌 是个5行5列的二维数组
    self.m_sendCardCount = 0                             --发牌次数
    self.m_lMaxCellScore = 0                             --单元上限
    self.m_lCellScore = 0                                --单元下注
    self.m_lUserMaxScore = 0                             --最大分数
    self.m_lUserMinScore = 0                             --最小分数
    self.m_lTurnMaxScore = 0                             --最大加注数，方便拉杆加注计算
    self.m_lTurnLessScore = 0                             --最小加注数，方便拉杆加注计算
    self.m_winnerChairId = yl.INVALID_CHAIR              --胜利用户 
    self.m_lAllTableScore = 0                            --桌面上的总共分数
    self.m_bIsGameBegin = false                          --游戏是否已经开始
    self.m_llLastScore = 0                               --上个玩家的押注
    self.m_llStartScore = 0                              --押注跟随的分数
    self.m_wMyChiarId = 0                                --玩家位置
    self.m_lOneTotalScore = 0                             --一轮总共的押注
end

-- 重置游戏数据
function GameLayer:OnResetGameEngine()
    GameLayer.super.OnResetGameEngine(self)

    self:KillGameClock()
    self.m_wCurrentUser = yl.INVALID_CHAIR              
    self.m_wCurrentUser = yl.INVALID_CHAIR              --当前用户            
    self.m_wWinnerUser = yl.INVALID_CHAIR               --赢的用户
    self.m_wAddUser = yl.INVALID_CHAIR                  --上一个加分的用户
    self.m_lUserScore = {0,0,0,0,0}                     --用户原来的分数
    self.m_UserCurScore = {0,0,0,0,0}                   --用户当前的分数
    self.m_cbPlayStatus = {0,0,0,0,0}                   --游戏状态
    self.m_lTableScore = {0,0,0,0,0}                    --下注数目
    self.m_giveUpPlayer = {0,0,0,0,0}                   --没参与游戏或者放弃游戏 
    self.m_lTotalScore = {0,0,0,0,0}                    --每个用户总共的下注
    self.m_handCardArray = {{},{},{},{},{}}             --各个玩家的手牌 是个5行5列的二维数组
    self.m_sendCardCount = 0                            --发牌次数
    self.m_lMaxCellScore = 0                            --单元上限
    self.m_lCellScore = 0                               --单元下注
    self.m_lUserMaxScore = 0                            --最大分数
    self.m_lUserMinScore = 0                            --最小分数
    self.m_lTurnMaxScore = 0                             --最大加注数，方便拉杆加注计算
    self.m_lTurnLessScore = 0                             --最小加注数，方便拉杆加注计算
    self.m_winnerChairId = yl.INVALID_CHAIR              --胜利用户 
    self.m_lAllTableScore = 0                            --桌面上的总共分数
    self.m_bIsGameBegin = false                          --游戏是否已经开始
    self.m_llLastScore = 0                               --上个玩家的押注
    self.m_llStartScore = 0                              --押注跟随的分数
    self.m_wMyChiarId = 0                                --玩家位置
    self.m_lOneTotalScore = 0                             --一轮总共的押注

    self._gameView:OnResetView()
end

-- 场景信息  
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    --初始化已有玩家
    for i = 1, cmd.GAME_PLAYER do
        local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), i-1)
        if nil ~= userItem then
            local wViewChairId = self:SwitchViewChairID(i-1)
            self._gameView:OnUpdateUser(wViewChairId, userItem)
            self.m_lUserScore[i] = userItem.lScore
            self.m_UserCurScore[i] = userItem.lScore

        end
    end

	if cbGameStatus == cmd.GAME_SCENE_FREE	then			    --空闲状态
        print("game status is free 当进入房间未开始玩游戏")
       local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_SatatusFree, dataBuffer)
        --dump(cmd_table)
        self.m_lCellScore = cmd_table.lCellScore
        self._gameView:SetCellScore(self.m_lCellScore)
        self._gameView.btnStart:setVisible(self:GetMeUserItem().cbUserStatus == yl.US_SIT)
        self:SetGameClock(self:GetMeChairID(),cmd.IDI_START_GAME,cmd.TIME_START_GAME)

	elseif cbGameStatus == cmd.GAME_SCENE_PLAY	then			--游戏状态
        print("game status is play! 当进入房间正在开始游戏")
        local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_SatatusPlay, dataBuffer)

        local MyChair = self:GetMeChairID() + 1
        if cmd_table.lTableScore[1][MyChair] > 0 then
            self.m_bIsGameBegin = true
        end

        --参数设置
        self.m_lDrawMaxScore = cmd_table.lDrawMaxScore
        self.m_lTurnLessScore = cmd_table.lTurnLessScore
        self.m_lCellScore = cmd_table.lCellScore
        self.m_wCurrentUser = cmd_table.wCurrentUser
        self.m_lDrawMaxScore = cmd_table.lDrawMaxScore
        self.m_lAllTableScore = 0
        self.m_lTableScore = {0,0,0,0,0}    
        self.m_giveUpPlayer = {0,0,0,0,0}   

        for i = 1, cmd.GAME_PLAYER do
            self.m_lTotalScore[i] = self.m_lUserScore[i] + self.m_lTableScore[i]
            self.m_cbPlayStatus[i] = cmd_table.cbPlayStatus[1][i]
            self.m_lTableScore[i]  = cmd_table.lTableScore[1][i]
            self.m_lTotalScore[i]  = cmd_table.lTableScore[1][i]
            self.m_lAllTableScore = self.m_lAllTableScore + self.m_lTableScore[i]
            --移除卡牌
            local cardTable = self._gameView.userCard[i].area:getChildren()
            for k,v in pairs(cardTable) do
                v:removeFromParent()
            end
        end

        self._gameView.btnStart:setVisible(false)

        --底注信息
        self._gameView:SetCellScore(self.m_lCellScore)
        self._gameView:SetMaxCellScore(self.m_lDrawMaxScore)

        self:updateOperatorText(self.m_wCurrentUser)

        --总计下注
        self._gameView:SetAllTableScore(self.m_lAllTableScore)

        local delayCount = 1
        local nCount = 1
        --发牌
        for i=1,cmd.GAME_PLAYER do
            local viewid = self:SwitchViewChairID(i-1)
            self._gameView:PlayerJetton(viewid,self.m_lTotalScore[i],true)
            --第一张牌
            if cmd_table.cbCardCount[1][i] ~= 0 then
                self.m_giveUpPlayer[i] = 1
                if i == self:GetMeChairID() then
                    self._gameView:SendCard(viewid,cmd_table.cbHandCardData[i][1],1,nCount*0.1,false,false)
                    self._gameView.userCard[i].card[1] = cmd_table.cbHandCardData[i][1]
                else
                    self._gameView:SendCard(viewid,cmd_table.cbHandCardData[i][1],1,nCount*0.1,false,false)
                end
            end
            --第二张牌
            for j=2,cmd_table.cbCardCount[1][i] do
                local cardValue = cmd_table.cbHandCardData[i][j]
                if cmd_table.cbPlayStatus[1][i] == 0 then
                    cardValue = 67
                end
                self._gameView:SendCard(viewid,cardValue,j,nCount*0.1,false,false)
                self._gameView.userCard[i].card[j] = cardValue
            end
            if self.m_sendCardCount < cmd_table.cbCardCount[1][i] then
                self.m_sendCardCount = cmd_table.cbCardCount[1][i]
            end
            nCount = nCount + 1
        end
        --控制按钮显示
        if cmd_table.wCurrentUser == self:GetMeChairID() then
            self._gameView:showOperateButton(true)
        end
        if cmd_table.wCurrentUser ~= cmd.INVALID_CHAIR then
            --设置计时器
            self:SetGameClock(self.m_wCurrentUser,cmd.IDI_USER_ADD_SCORE,cmd.TIME_USER_ADD_SCORE)
        end
	end

    --取消等待
    self:dismissPopWait()
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)
	if sub == cmd.SUB_S_GAME_START then 
        print("hkfivecardnew 游戏开始")
		self:onSubGameStart(dataBuffer)
	elseif sub == cmd.SUB_S_ADD_SCORE then 
        print("hkfivecardnew 加注")
		self:onSubAddScore(dataBuffer)
	elseif sub == cmd.SUB_S_GIVE_UP then 
        print("hkfivecardnew 弃牌")
        self:onGameSceneGiveUp(dataBuffer)
	elseif sub == cmd.SUB_S_SEND_CARD then 
        print("hkfivecardnew 发牌") 
		self:onSubSendCard(dataBuffer)
	elseif sub == cmd.SUB_S_GAME_END then 
        print("hkfivecardnew 游戏结束")
		self:onSubGameEnd(dataBuffer)
	elseif sub == cmd.SUB_S_GET_WINNER then 
        print("hkfivecardnew 得到赢家")
		self:onSubGetWinner(dataBuffer)
	else
		print("unknow gamemessage sub is"..sub)
	end
end

--游戏开始
function GameLayer:onSubGameStart(dataBuffer)
    --防作弊判断
    if self._gameFrame.bEnterAntiCheatRoom == true then
        self:dismissPopWait()
    end
    --数据流变成表形式
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GAMEStart, dataBuffer);

    self:OnResetGameEngine()


    self.m_bIsGameBegin = true      --游戏开始标识

    self.m_wCurrentUser = cmd_table.wCurrentUser        --当前用户
    self.m_lTurnMaxScore = cmd_table.lTurnMaxScore      --拉杆最大
    self.m_lTurnLessScore = cmd_table.lTurnLessScore     --拉杆最小
    self.m_lCellScore = cmd_table.lCellScore              --基础分数
    self._gameView.m_lCellScore = cmd_table.lCellScore
    local pScureCard = cmd_table.cbObscureCard          --底牌

    self.m_lDrawMaxScore = cmd_table.lDrawMaxScore     --加注最大值
    --底分
    self._gameView:SetCellScore(self.m_lCellScore)
    self._gameView:SetMaxCellScore(self.m_lDrawMaxScore)
    --换桌按钮
    self._gameView.btnChangetable:setEnabled(false)
    --更新底部提示文字
    self:updateOperatorText(self.m_wCurrentUser)

    --初始化已有玩家数据
    for i = 1, cmd.GAME_PLAYER do
        if self.m_lUserScore[i] == 0 then
            local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), i-1)
            if nil ~= userItem then
                local wViewChairId = self:SwitchViewChairID(i-1)
                self._gameView:OnUpdateUser(wViewChairId, userItem)
                self.m_lUserScore[i] = userItem.lScore
                self.m_UserCurScore[i] = userItem.lScore

                if self.m_lUserMaxScore < userItem.lScore then
                    self.m_lUserMaxScore = userItem.lScore
                end
                if i == 1 then
                   self.m_lUserMinScore =  userItem.lScore
                end
                if self.m_lUserMinScore > userItem.lScore then 
                    self.m_lUserMinScore = userItem.lScore
                end
            end
        end
    end

    for i = 1, cmd.GAME_PLAYER  do
        local chair = self:SwitchViewChairID(i-1)
        if cmd_table.cbCardData[1][i] ~= 0  then 
            self.m_lAllTableScore = self.m_lAllTableScore + self.m_lCellScore
            self.m_lTableScore[i] = self.m_lCellScore
            self.m_lTotalScore[i] = self.m_lTotalScore[i] + self.m_lCellScore
            self.m_UserCurScore[i] = self.m_UserCurScore[i] - self.m_lCellScore

            --用户下注
            self._gameView:SetUserTableScore(chair, self.m_lCellScore)
            --移动筹码
            self._gameView:PlayerJetton(chair,self.m_lTotalScore[i])
            --用户数据变化
            self._gameView:setUserScore(chair,self.m_UserCurScore[i])

        end
    end
    --总计下注
    self._gameView:SetAllTableScore(self.m_lAllTableScore)
    --分别发两张牌
    local delayCount = 1
    for i = 1, cmd.GAME_PLAYER do
        if cmd_table.cbCardData[1][i] ~= 0 then
            local chair = self:SwitchViewChairID(i-1)
            if chair == 3 then
                --自己底牌
                self._gameView:SendCard(chair,pScureCard,1,delayCount*0.1)
                delayCount = delayCount + 1

                self._gameView.userCard[i].card[1] = pScureCard
            else
                --其他玩家底牌
                self._gameView:SendCard(chair,67,1,delayCount*0.1) --67是背面
                delayCount = delayCount + 1

                self._gameView.userCard[i].card[1] = 67
            end
            --显示的牌
            self._gameView:SendCard(chair,cmd_table.cbCardData[1][i],2,delayCount*0.1)
            self._gameView.userCard[i].card[2] = cmd_table.cbCardData[1][i]
            delayCount = delayCount + 1

        end
    end
    self.m_sendCardCount = 2

    --设置计时器
    self:SetGameClock(self.m_wCurrentUser,cmd.IDI_USER_ADD_SCORE,cmd.TIME_USER_ADD_SCORE)

    if self.m_wCurrentUser == self:GetMeChairID() then
        self:UpdataControl()
    end
    --音效
    ExternalFun.playSoundEffect("GAME_START.wav")
end

--用户加注
function GameLayer:onSubAddScore(dataBuffer)
    --数据流变成表形式
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_AddScore, dataBuffer);
    local MyChair = self:GetMeChairID()
    local wAddUser = cmd_table.wAddScoreUser
    self.m_wAddUser = cmd_table.wAddScoreUser
    local viewid = self:SwitchViewChairID(wAddUser)
    --数据赋值
     self.m_llLastScore =   cmd_table.lTurnLessScore - self.m_lTotalScore[wAddUser+1]
   
    self.m_wCurrentUser = cmd_table.wCurrentUser
    --保存上一玩家押注 
    
    self.m_lTurnLessScore = cmd_table.lTurnLessScore

    self.m_UserCurScore[wAddUser+1] = self.m_UserCurScore[wAddUser+1] - self.m_llLastScore
    self.m_lTotalScore[wAddUser+1] = cmd_table.lTurnLessScore
    self.m_lTableScore[wAddUser+1] = self.m_lTableScore[wAddUser+1] + self.m_llLastScore

    self.m_lAllTableScore = self.m_lAllTableScore + self.m_llLastScore
    self._gameView:setUserScore(viewid,self.m_UserCurScore[wAddUser+1])   --设置头像的用户当前金币
    self._gameView:PlayerJetton(viewid, cmd_table.lUserScoreCount)
    
    self._gameView:SetAllTableScore(self.m_lAllTableScore)
    if self.m_llLastScore ~= 0 then
        self._gameView:SetUserTableScore(viewid, self.m_lTotalScore[wAddUser+1])  --设置押注的金币
    end


    --一轮的押注
    self.m_lOneTotalScore = self.m_lOneTotalScore + cmd_table.lUserScoreCount
    self.m_lUserScore[wAddUser+1] = cmd_table.lUserScoreCount

    --显示气泡 及梭哈动画
    if cmd_table.lUserScoreCount ~= 0 then 
        if self.m_lTotalScore[wAddUser+1]  >= self.m_lDrawMaxScore then --梭哈
            self._gameView:showTip(viewid,4)
            self._gameView:runShowHandAnimate(viewid) --梭哈动画
            ExternalFun.playSoundEffect("SHOW_HAND.wav")
        elseif cmd_table.lUserScoreCount == self.m_llStartScore then --跟注
            self._gameView:showTip(viewid,2)
            ExternalFun.playSoundEffect("FOLLOW.wav")
        else --加注
            self._gameView:showTip(viewid,3)
            ExternalFun.playSoundEffect("ADD_SCORE.wav")
        end
    else --不加
        self._gameView:showTip(viewid,1)
        ExternalFun.playSoundEffect("NO_ADD.wav")
    end
    --底部显示
    self:updateOperatorText(self.m_wCurrentUser)

    if self.m_llStartScore < cmd_table.lUserScoreCount then
        self.m_llStartScore = cmd_table.lUserScoreCount
    end
    --移除计时器
    self:KillGameClock()

    --更新操作控件
    if  self.m_wCurrentUser == MyChair then
        self._gameView:showOperateButton(true)
        self:UpdataControl()
    end
    --设置计时器
    self:SetGameClock(self.m_wCurrentUser, cmd.IDI_USER_ADD_SCORE, cmd.TIME_USER_ADD_SCORE)
end

--弃牌信息
function GameLayer:onGameSceneGiveUp(dataBuffer)
    --数据流变成表形式
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GiveUp, dataBuffer);

    local MyChair = self:GetMeChairID()
    local giveUpId = self:SwitchViewChairID(cmd_table.wGiveUpUser)
    self.m_giveUpPlayer[cmd_table.wGiveUpUser+1] = 0
    self.m_lDrawMaxScore = cmd_table.lDrawMaxScore
    self.m_lTurnMaxScore = cmd_table.lTurnMaxScore
    self.m_wCurrentUser = cmd_table.wCurrentUser
    --移除计时器
    self:KillGameClock()

    if cmd_table.wCurrentUser == MyChair then
        self._gameView:showOperateButton(true)
    end

    self._gameView:showTip(giveUpId,5)
    self:updateOperatorText(self.m_wCurrentUser)

    if wCurrentUser ~= yl.INVALID_USERID then
        self:SetGameClock(self.m_wCurrentUser, cmd.IDI_USER_ADD_SCORE, cmd.TIME_USER_ADD_SCORE)
    end
    local cardTable = self._gameView.userCard[giveUpId].area:getChildren()
    for k,v in pairs(cardTable) do
        v:showCardBack(true)
    end

    ExternalFun.playSoundEffect("GIVE_UP.wav")
end

--发牌信息
function GameLayer:onSubSendCard(dataBuffer)
    --数据流变成表形式
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_SendScore, dataBuffer)

    local MyChair = self:GetMeChairID()

    self.m_wCurrentUser = cmd_table.wCurrentUser
    self.m_lTurnMaxScore = cmd_table.lTurnMaxScore

    self.m_llStartScore = 0
    self.m_llLastScore = 0
    self.m_lOneTotalScore = 0

    self.m_wAddUser = yl.INVALID_CHAIR                     --上一个加分的用户

    self:updateOperatorText(self.m_wCurrentUser)
    --发牌
    local nCount = 0
    for i=1,cmd.GAME_PLAYER do
        if cmd_table.cbCardData[1][i] ~= 0 then
            local viewid = self:SwitchViewChairID(i-1)
            for index=1,cmd_table.cbSendCardCount do
                self._gameView:SendCard(viewid,cmd_table.cbCardData[index][i],self.m_sendCardCount+index,nCount*0.1)
                self._gameView.userCard[i].card[self.m_sendCardCount + index] = cmd_table.cbCardData[index][i]
            end
        end
    end

    self.m_sendCardCount = self.m_sendCardCount + cmd_table.cbSendCardCount

    if  self.m_wCurrentUser == MyChair then
        self:UpdataControl()
    end
    --设置计时器
    self:SetGameClock(self.m_wCurrentUser, cmd.IDI_USER_ADD_SCORE, cmd.TIME_USER_ADD_SCORE)

end

--游戏结算
function GameLayer:onSubGameEnd(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameEnd, dataBuffer)

    local MyChair = self:GetMeChairID()

    self.m_bIsGameBegin = false

    self:updateOperatorText(nil)       --隐藏底部提示

    local savetype = {}                --保存类型

    for i=1,cmd.GAME_PLAYER  do
        if cmd_table.lGameScore[1][i] > 0 then 
            self.m_winnerChairId = i
              
        elseif cmd_table.lGameScore[1][i] < 0 then
           --扣分的用户
        end
        --翻出底牌
        if self._gameView.userCard[i] ~= 0 and cmd_table.cbCardData[1][i] ~= 0 then --[[self.m_giveUpPlayer[i] ~= 0]]
            self._gameView.userCard[i].card[1] = cmd_table.cbCardData[1][i]
            local viewid = self:SwitchViewChairID(i-1)
            local secureCard = self._gameView.userCard[viewid].area:getChildByTag(1)
            if secureCard ~= nil  then
                secureCard:setCardValue(cmd_table.cbCardData[1][i])
                secureCard:showCardBack(false)
            end
            --排序和得到类型
            savetype[i] = GameLogic:GetCardType(self._gameView.userCard[i].card)
        else
            savetype[i] = 0
        end
    end
    --音效
    if self.m_winnerChairId == MyChair then
        ExternalFun.playSoundEffect("GAME_WIN.wav")
    else
        ExternalFun.playSoundEffect("GAME_LOSE.wav")
    end

    --赢家椅子
    local winChiarId = self:SwitchViewChairID(self.m_winnerChairId-1)
    --赢得筹码 
    self._gameView:WinTheChip(winChiarId)
    --结算分数显示
    for i=1,cmd.GAME_PLAYER do
        local viewid = self:SwitchViewChairID(i-1)
        if cmd_table.cbCardData[1][i] ~= 0 then
            self._gameView:setCardType(viewid,savetype[i])
        end
        if cmd_table.lGameScore[1][i] ~= 0 then
            self._gameView:SetUserEndScore(viewid,cmd_table.lGameScore[1][i])
        end
    end
    --设置底牌不能点
    self._gameView.m_touch:setTouchEnabled(false)
    --防作弊判断
    if self._gameFrame.bEnterAntiCheatRoom == false then
        self._gameView.btnChangetable:setEnabled(true)
    end
    --设置计时器
    self:SetGameClock(self:GetMeChairID(),cmd.IDI_START_GAME,cmd.TIME_START_GAME)

    ExternalFun.playSoundEffect("GAME_END.wav")
end

function GameLayer:onSubGetWinner(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GetWinner, dataBuffer)

    for i=1,cmd.GAME_PLAYER do
        if cmd_table.wChairOrder[1][i] == 1 then
            self.m_winnerChairId = i
            local MyChair = self:GetMeChairID()
            if self.m_winnerChairId == MyChair then
                ExternalFun.playSoundEffect("GAME_WIN.wav")
            else
                ExternalFun.playSoundEffect("GAME_LOSE.wav")
            end

            break
        end
    end

end

--获取信息
function GameLayer:onSubPlayerExit(dataBuffer)

    local wPlayerID = dataBuffer:readword()
    local wViewChairId = self:SwitchViewChairID(wPlayerID)
    self.m_cbPlayStatus[wPlayerID + 1] = 0
    self._gameFrame.nodePlayer[wViewChairId]:setVisible(false)
end

--发送准备
function GameLayer:onStartGame(bReady)
    self:KillGameClock()

    self._gameView.btnStart:setVisible(false)
    self._gameView:SetAllTableScore(0)
    self._gameView:SetCellScore(0)
    self._gameView:SetMaxCellScore(0)
    for i = 1 , cmd.GAME_PLAYER do
        self._gameView:SetUserTableScore(i, 0)
        self._gameView:setCardType(i)
        self._gameView:clearCard(i)
        self._gameView:SetUserEndScore(i)
    end

    if bReady == true then
        self:SendUserReady()
        print("-------发送准备消息成功--------")
        if self._gameFrame.bEnterAntiCheatRoom == true then
            self:showPopWait()
        end
    end
end

--跟注  
function GameLayer:onFollowScore()
    local MyChair = self:GetMeChairID()
    MyChair = MyChair + 1
    local viewid = self:SwitchViewChairID(MyChair)

    --删除计时器
    self:KillGameClock()
    --隐藏操作按钮
    self._gameView:showOperateButton(false)

    --跟随的分数
    local addScore = self.m_lTurnLessScore - self.m_lTotalScore[self.m_wAddUser+1]

    --判断是否在可范围内
    local myTotalScore = self.m_lTotalScore[MyChair]
    local totalScore  = myTotalScore + addScore

    if self.m_lTurnMaxScore and self.m_lTurnLessScore then  
        if totalScore >= self.m_lTurnMaxScore then
            addScore = self.m_lTurnMaxScore - myTotalScore
        elseif totalScore <= self.m_lTurnLessScore then
            addScore = self.m_lTurnLessScore - myTotalScore
        end
    end
    --发送数据
    local dataBuffer = CCmd_Data:create(8)
    dataBuffer:pushscore(addScore)
    self:SendData(cmd.SUB_C_ADD_SCORE,dataBuffer)
end
--不加
function GameLayer:onDoNotAddScore()
    local MyChair = self:GetMeChairID()
    local viewid = self:SwitchViewChairID(MyChair)
    --删除计时器
    self:KillGameClock()
    --隐藏操作按钮
    self._gameView:showOperateButton(false)
    self._gameView:showTip(viewid,1)
    --发送数据
    local dataBuffer = CCmd_Data:create(8)
    dataBuffer:pushscore(0)
    self:SendData(cmd.SUB_C_ADD_SCORE,dataBuffer)
end
--放弃操作  
function GameLayer:onGiveUp()
    local MyChair = self:GetMeChairID()
    local viewid = self:SwitchViewChairID(MyChair)
    --删除计时器
    self:KillGameClock()
    --隐藏操作按钮
    self._gameView:showTip(viewid,5)
    self._gameView:showOperateButton(false)
    --设置底牌不能点
    self._gameView.m_touch:setTouchEnabled(false)
    --发送数据
    local dataBuffer = CCmd_Data:create(0)
    self:SendData(cmd.SUB_C_GIVE_UP,dataBuffer)
end

--换位操作
function GameLayer:onChangeDesk()
    self._gameFrame:QueryChangeDesk()
end

--加注操作
function GameLayer:onAddScore(index)
    local MyChair = self:GetMeChairID()
    local viewid = self:SwitchViewChairID(MyChair)
    if self.m_wCurrentUser ~= MyChair or index == nil  then
        return
    end
    MyChair = MyChair + 1
    self:KillGameClock()
    --隐藏界面
    self._gameView.m_addChipNode:setVisible(false)
    self._gameView.m_bShowAddNode = false
    self._gameView.m_slider:setVisible(false)
    self._gameView:showOperateButton(false)
    self._gameView:showTip(viewid,3)
    --下注金额
    local scoreIndex = (not index and 0 or index)
    local addScore = self.m_lCellScore*scoreIndex + self.m_llLastScore
    local totalScore = addScore + self.m_lTotalScore[MyChair]

    --判断是否最大下注值
    if self.m_lTurnMaxScore and self.m_lTurnLessScore then
        if totalScore > self.m_lTurnMaxScore then
            addScore = self.m_lTurnMaxScore - self.m_lTotalScore[MyChair]
        elseif  totalScore < self.m_lTurnLessScore then
            addScore = self.m_lTurnLessScore - self.m_lTotalScore[MyChair]
        end
    end
    --发送数据
    local  dataBuffer= CCmd_Data:create(8)
    dataBuffer:pushscore(addScore)
    self:SendData(cmd.SUB_C_ADD_SCORE, dataBuffer)
end

--滑动加注
function GameLayer:onSlideAddScore()
    local MyChair = self:GetMeChairID()
    local viewid = self:SwitchViewChairID(MyChair)
    if self.m_wCurrentUser ~= MyChair  then
        return
    end
    MyChair = MyChair + 1
    self:KillGameClock()
    --隐藏界面
    self._gameView.m_addChipNode:setVisible(false)
    self._gameView.m_bShowAddNode = false
    self._gameView.m_slider:setVisible(false)
    self._gameView:showOperateButton(false)

    --下注金额

    local addScore = tonumber(self._gameView.m_slideBtn:getTitleText()) + self.m_llLastScore

    local totalScore = 0
    if self.m_wAddUser == yl.INVALID_CHAIR then
        totalScore = addScore + self.m_lTotalScore[MyChair]
    else

        if  tonumber(self._gameView.m_slideBtn:getTitleText()) == 0 then
            addScore = self.m_lTurnLessScore - self.m_lTotalScore[MyChair]
        end
        totalScore = addScore + self.m_lTotalScore[self.m_wAddUser+1]
    end
    --判断是否最大下注值
    if self.m_lTurnMaxScore and self.m_lTurnLessScore then
        if totalScore > self.m_lTurnMaxScore then
            addScore = self.m_lTurnMaxScore - self.m_lTotalScore[MyChair]
        elseif  totalScore < self.m_lTurnLessScore then
            addScore = self.m_lTurnLessScore - self.m_lTotalScore[MyChair]
        end
    end
    --发送数据
    local  dataBuffer= CCmd_Data:create(8)
    dataBuffer:pushscore(addScore)
    self:SendData(cmd.SUB_C_ADD_SCORE, dataBuffer)
end

--梭哈
function GameLayer:onShowHand()
    local MyChair = self:GetMeChairID()
    local viewid = self:SwitchViewChairID(MyChair)
    if self.m_wCurrentUser ~= MyChair  then
        return
    end
    MyChair = MyChair + 1
    --输出定时器
    self:KillGameClock()
    --下注金额
    local addScore = self.m_lDrawMaxScore - self.m_lTotalScore[MyChair] 
    --隐藏界面
    self._gameView.m_addChipNode:setVisible(false)
    self._gameView.m_bShowAddNode = false
    self._gameView:showOperateButton(false)
    self._gameView:showTip(viewid,4)
    --发送数据
    local  dataBuffer= CCmd_Data:create(8)
    dataBuffer:pushscore(addScore)
    self:SendData(cmd.SUB_C_ADD_SCORE, dataBuffer)
end

--获取赢家
function GameLayer:onGetWinner()
    --发送数据
    local  dataBuffer= CCmd_Data:create(8)
    dataBuffer:pushscore(0)
    self:SendData(cmd.SUB_S_GET_WINNER, dataBuffer)
end

--更新按钮控制
function GameLayer:UpdataControl()
    local MyChair = self:GetMeChairID() 
    if not MyChair or MyChair == yl.INVALID_CHAIR then
        print("UpdataControl myChair is"..(not MyChair and "nil" or "INVALID_CHAIR"))
        return
    end
    self._gameView:showOperateButton(true)             --底部按钮

    local minScore = 0
    local maxScore = 0

    if self.m_wAddUser == yl.INVALID_CHAIR then
        minScore = self.m_lTurnLessScore - self.m_lTotalScore[MyChair + 1]
        maxScore = self.m_lTurnMaxScore - self.m_lTotalScore[MyChair + 1]
        if self.m_llLastScore == 0 then
            minScore = self.m_lCellScore
        end
    else
        minScore = self.m_lTurnLessScore - self.m_lTotalScore[self.m_wAddUser+1]
        maxScore = self.m_lTurnMaxScore - self.m_lTotalScore[self.m_wAddUser+1]
        if self.m_llLastScore == 0 then
            minScore = self.m_lCellScore
        end
    end
    --四个带分数的加注按钮
    for i=1,4 do
        if maxScore  < self.m_lCellScore*i then
            self._gameView.btChip[i]:setEnabled(false)
        else
            self._gameView.btChip[i]:setEnabled(true)
        end
    end

    --是否显示加分按钮
    local isShowAddBtn = self.m_lTurnMaxScore > self.m_lTurnLessScore and self.m_lTurnLessScore -  self.m_lTurnMaxScore ~= 0  and self.m_lTurnMaxScore - self.m_lTurnLessScore > 0
    if not isShowAddBtn  then
        self._gameView.btnAddGold:setEnabled(false)
    else
        self._gameView.btnAddGold:setEnabled(true)
    end 
    self._gameView.m_slideBtn:setTitleText(minScore)
end

--点击加注按钮
function GameLayer:onAddScoreButton()
    self._gameView:showOperateButton(false)
    self._gameView.m_slider:setVisible(true)
    self._gameView.m_addChipNode:setVisible(true)
    self._gameView.btnAddGold:setVisible(false)

    if self._gameView.m_slideProBar ~= nil then
        self._gameView.m_slideProBar:setPercent(0)
    end
end

--聊天
function GameLayer:onUserChat(chatinfo,sendchair)
    if chatinfo and sendchair then
        local viewid = self:SwitchViewChairID(sendchair)
        if viewid and viewid ~= yl.INVALID_CHAIR then
            self._gameView:ShowUserChat(viewid,chatinfo.szChatString)
        end
    end
end

--聊天
function GameLayer:onUserExpression(expression,sendchair)
    if expression and sendchair then
        local viewid = self:SwitchViewChairID(sendchair)
        if viewid and viewid ~= yl.INVALID_CHAIR then
            self._gameView:ShowUserExpression(viewid,expression.wItemIndex)
        end
    end
end

--显示operatorText
function GameLayer:updateOperatorText(chairId)
    if chairId == yl.INVALID_CHAIR then
        return
    end
    if chairId == self:GetMeChairID() or chairId == nil then
        self._gameView.m_operatorText:setVisible(false)
    else
        local viewid = self:SwitchViewChairID(chairId)
        self._gameView.m_operatorText:setVisible(true)
        local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), chairId)
        if userItem.szNickName then
            self._gameView.m_operatorText:setString(string.format("等待玩家 %s 下注",userItem.szNickName))
        end
    end
end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time)
    GameLayer.super.SetGameClock(self,chair,id,time)
    local viewid = self:GetClockViewID()
    if viewid and viewid ~= yl.INVALID_CHAIR then
        local progress = self._gameView.m_TimeProgress[viewid]
        if progress ~= nil then
            progress:setPercentage(100)
            progress:setVisible(true)
            self._gameView.nodePlayer[viewid]:getChildByName("timeProBarBg"):setVisible(true)
            progress:runAction(cc.Sequence:create(cc.ProgressTo:create(time, 0), cc.CallFunc:create(function()
                progress:setVisible(false)
                self._gameView.nodePlayer[viewid]:getChildByName("timeProBarBg"):setVisible(false)
                self:OnEventGameClockInfo(viewid, id)
            end)))
        end
    end
end

--获得当前正在玩的玩家数量
function GameLayer:getPlayingNum()
    local num = 0
    for i = 1, cmd.GAME_PLAYER do
        if self.m_cbPlayStatus[i] == 1 then
            num = num + 1
        end
    end
    return num
end

-- 时钟处理
function GameLayer:OnEventGameClockInfo(chair,time,clockid)
    if time < 5 then
        ExternalFun.playSoundEffect("GAME_WARN.wav")
    end
    if clockid == cmd.IDI_START_GAME then
        if time == 0 then
            --退出防作弊
            self._gameFrame:setEnterAntiCheatRoom(false)
            self:onExitTable()
            return true
        end
    elseif clockid == cmd.IDI_DISABLE then
        if time == 0 then
            return true
        end
    elseif clockid == cmd.IDI_USER_ADD_SCORE then
        if time == 0 then
            if self.m_wCurrentUser == self:GetMeChairID() then
                self:onGiveUp()
                return true
            end
        end
    end
end
-- 关闭计时器
function GameLayer:KillGameClock(notView)
    local viewid = self:GetClockViewID()
    if viewid and viewid ~= yl.INVALID_CHAIR then
        local progress = self._gameView.m_TimeProgress[viewid]
        if progress ~= nil then
            progress:stopAllActions()
            progress:setVisible(false)
            self._gameView.nodePlayer[viewid]:getChildByName("timeProBarBg"):setVisible(false)
        end
    end
    GameLayer.super.KillGameClock(self,notView)
end


function GameLayer:onExitRoom()
    local seq = cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(function (  )
        self._gameFrame:onCloseSocket()
        self:stopAllActions()
        self:KillGameClock()
        self:dismissPopWait()
        self._scene:onChangeShowMode(yl.SCENE_ROOMLIST)
    end))
    self:runAction(seq)
end

--当金币少于100时，调用的函数
-- 退出桌子
function GameLayer:onExitTable()
    local MeItem = self:GetMeUserItem()
    if MeItem.lScore == 0 then
        --延迟
        local seq = cc.Sequence:create(
            cc.CallFunc:create(function (  )
                showToast(self, "不足100金币，无法继续游戏",1.5)
            end),
            cc.DelayTime:create(1.5),
            cc.CallFunc:create(function (  )
                self:stopAllActions()
                self:KillGameClock()

                local MeItem = self:GetMeUserItem()
                if MeItem and MeItem.cbUserStatus > yl.US_FREE then
                    local wait = self._gameFrame:StandUp(1)
                    if wait then
                        self:showPopWait()
                        return
                    end
                end
                self:dismissPopWait()
                self._scene:onKeyBack()
                
            end))
        self:runAction(seq)
    else
        --不延迟
        self:stopAllActions()
        self:KillGameClock()

        local MeItem = self:GetMeUserItem()
        --dump(MeItem)
        if MeItem and MeItem.cbUserStatus > yl.US_FREE then
            local wait = self._gameFrame:StandUp(1)
            if wait then
                self:showPopWait()
                return
            end
        end
        self:dismissPopWait()
        self._scene:onKeyBack()
    end
end

return GameLayer
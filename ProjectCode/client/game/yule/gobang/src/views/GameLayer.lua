--
-- Author: Tang
-- Date: 2016-12-08 15:41:34
--
local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.yule.gobang.src";
require("cocos.init")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = module_pre .. ".models.cmd_game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"

local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local QueryDialog   = require("app.views.layer.other.QueryDialog")
local g_var = ExternalFun.req_var
local GameFrame = appdf.req(module_pre .. ".models.GameFrame")

function GameLayer:ctor( frameEngine,scene )
    ExternalFun.registerNodeEvent(self)
    self.m_bLeaveGame     = false
    self.m_cbGameStatus   = 0
    self._color           = -1 --0白色，1黑色
    self._otherColor      = -1
    self._manualRecord    = {}
    self._steps           = {0,0}     --已下步数
    self.m_wLeftClock     = {0,0}
    self._stepRecordNear      = {{},{}} --下棋记录
    self.m_bpermitCoach   = false
    self.m_nCoachRestarin = 0
    self.m_bRegretTimeBeyond = false   --悔棋次数限制
    self.m_nPeaceTimeControl = 0

    self.m_wBlackUser     = yl.INVALID_CHAIR
    self.m_wPayCoachUser  = yl.INVALID_CHAIR
    self.m_wCurrentUser   = yl.INVALID_CHAIR
    self.m_wRegretUser    = yl.INVALID_CHAIR
 
    self._dataModle = GameFrame:create()    
    GameLayer.super.ctor(self,frameEngine,scene)
    self._roomRule = self._gameFrame._dwServerRule

    self._gameFrame:QueryUserInfo(self:GetMeUserItem().wTableID,yl.INVALID_CHAIR)

    self.cbUserAESKey = 
    {
        0x32, 0x43, 0xF6, 0xA8,
        0x88, 0x5A, 0x30, 0x8D,
        0x31, 0x31, 0x98, 0xA2,
        0xE0, 0x37, 0x07, 0x34
    }
end

--创建场景
function GameLayer:CreateView()
     self._gameView = GameViewLayer:create(self)
     self:addChild(self._gameView)
     return self._gameView
end

function GameLayer:resetData()
    self._stepRecordNear      = {{},{}} --下棋记录
    self._steps           = {0,0}     --已下步数
    self.m_bRegretTimeBeyond = false
    self.m_nPeaceTimeControl = 0
end

function GameLayer:getParentNode( )
    return self._scene
end

function GameLayer:sendNetData( cmddata )
    return self:getFrame():sendSocketData(cmddata)
end

function GameLayer:getDataMgr( )
    return self._dataModle
end

function GameLayer:getFrame( )
    return self._gameFrame
end

function GameLayer:onExit()
    print("gameLayer onExit()...................................")
    self:KillGameClock()
    self:dismissPopWait()
end

--退出桌子
function GameLayer:onExitTable()
    self:KillGameClock()
    self:showPopWait()

    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(2),
            cc.CallFunc:create(
                function ()   
                    self._gameFrame:StandUp(1)
                end
                ),
            cc.DelayTime:create(10),
            cc.CallFunc:create(
                function ()
                    --强制离开游戏(针对长时间收不到服务器消息的情况)
                    print("delay leave")
                    self:onExitRoom()
                end
                )
            )
        )
        return
    end

   self:onExitRoom()
end

--离开房间
function GameLayer:onExitRoom()
    self:getFrame():onCloseSocket()

    self._scene:onKeyBack()   
    self.m_bLeaveGame = true 
end


function GameLayer:OnEventGameClockInfo(chair,clocktime,clockID)
    if nil ~= self._gameView  and self._gameView.UpdataClockTime then
        self._gameView:UpdataClockTime(chair,clocktime)
    end
end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time)

    if time < 0 then
       return
    end

    self:KillGameClock()

    GameLayer.super.SetGameClock(self,chair,id,time)

     if nil ~= self._gameView  and self._gameView.setClockView then
        self._gameView:setClockView(chair,time)
     end
end
--------------------------------------------------------------------------------------------------------------------------
--场景消息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)

    print("the buffer len is ========================= >"..dataBuffer:getlen())
    print("场景数据:" .. cbGameStatus)

    self.m_cbGameStatus = cbGameStatus
    if cbGameStatus == g_var(cmd).GS_GAME_FREE  then                        --空闲状态
        self._dataModle:initSign()
        self:onEventGameSceneFree(dataBuffer);
    elseif cbGameStatus == g_var(cmd).GS_GAME_STATUS then                 
        self:onEventGameSceneStatus(dataBuffer);
    end
    self:dismissPopWait()
end

function GameLayer:onEventGameSceneFree(buffer)    --空闲 

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusFree, buffer)
    dump(cmd_table, "the free data is ============ >", 6)
    --初始秘钥
    for i = 1, 16 do
        self.cbUserAESKey[i] = buffer:readbyte()
    end

    self.m_wPayCoachUser = cmd_table.wBankerUser    
    self.m_wBlackUser = cmd_table.wBlackUser         --黑棋玩家
    self.m_bpermitCoach = cmd_table.bPermitCoach     --允许指导费
    self.m_nCoachRestarin = cmd_table.lCoachRestarin

    self:SetGameClock(self:GetMeUserItem().wChairID,0,30)

    --自己棋子颜色
    local color
    if self.m_wBlackUser == self:GetMeUserItem().wChairID then
       color = 1
    else 
       color = 0
    end

    self._color = color
    self._otherColor = 1 - color
    self._gameView:showChessColor(self:GetMeUserItem().wChairID,color)
    self._gameView:updateControl()

    self._gameView:showReadyBtn(true)
    
end

function GameLayer:onEventGameSceneStatus(buffer)   

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, buffer)
    dump(cmd_table, "the status data is ================== >    ", 6)

    print("the buffer len is  =============== >"..buffer:getlen())

    --初始秘钥
    for i = 1, 16 do
        self.cbUserAESKey[i] = buffer:readbyte()
    end

    self.m_wPayCoachUser = cmd_table.wBankerUser
    self.m_nCoachRestarin = cmd_table.lCoachRestarin
    self.m_wBlackUser = cmd_table.wBlackUser
    self.m_bpermitCoach = cmd_table.bPermitCoach
    self.m_wCurrentUser = cmd_table.wCurrentUser

    print("status self.m_nCoachRestarin is ========================== >"..self.m_nCoachRestarin)
    
    --自己棋子颜色
    local color
    if self.m_wBlackUser == self:GetMeUserItem().wChairID then
       color = 1
    else 
       color = 0
    end

    self._color = color
    self._otherColor = 1 - color
    self._gameView:showChessColor(self:GetMeUserItem().wChairID,color)

    --下棋记录
    for i=1,#self._manualRecord do
        local record = self._manualRecord[i]
        local pos  = record._pos
        local color = record._color

        if color == self._color then
            self._gameView:convertLogicPosToView(pos, color,true)
            self._steps[self:GetMeUserItem().wChairID+1] = self._steps[self:GetMeUserItem().wChairID+1] + 1
        elseif color == self._otherColor then

            self._gameView:convertLogicPosToView(pos, color)
            local wOtherSideChairID = math.mod((self:GetMeUserItem().wChairID+1),g_var(cmd).GAME_PLAER)
            self._steps[wOtherSideChairID+1] = self._steps[wOtherSideChairID+1] + 1
        end

    end

       --设置时间
    self.m_wLeftClock[1] = cmd_table.wLeftClock[1][1]
    self.m_wLeftClock[2] = cmd_table.wLeftClock[1][2]

     --局时
    self._gameView:setRoundTime(cmd_table.wGameClock)

     --步时
    self._gameView:setClockView(0,self.m_wLeftClock[1])
    self._gameView:setClockView(1,self.m_wLeftClock[2])

    self:SetGameClock(cmd_table.wCurrentUser,0,self.m_wLeftClock[cmd_table.wCurrentUser+1])
    
    self._gameView:showBoxAnim(self.m_wCurrentUser)
    self._gameView:updateControl()
end

---------------------------------------------------------------------------------------游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)  

    if self.m_bLeaveGame or nil == self._gameView then
        return
    end 

    if sub == g_var(cmd).SUB_S_GAME_START then 
        self.m_cbGameStatus = g_var(cmd).GS_GAME_STATUS --游戏开始
        self._dataModle:initSign()
        self:OnSubGameStart(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_PLACE_CHESS then     --放置棋子
        self:OnSubPlaceChess(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_REGRET_REQ then      --悔棋请求
        self:OnSubGameRegretReq(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_REGRET_FAILE then    --悔棋失败
        self:OnSubGameRegretFailure(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_REGRET_RESULT then   --悔棋结果
        self:OnSubRegretResult(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_PEACE_REQ then       --和棋请求
        self:OnSubPeaceReq(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_PEACE_ANSWER then    --和棋应答
        self:OnSubPeaceAnser(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_COACH then           --指导费
        self:OnSubGameCoach(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_CHESS_MANUAL then
        self:OnSubChessManual(dataBuffer)  
    elseif sub == g_var(cmd).SUB_S_UPDATEAESKEY then    --更新密钥  
        self:OnSubUpdateAesKey(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_GAME_END then        --游戏结束
        self.m_cbGameStatus = g_var(cmd).GS_GAME_FREE
        self:OnSubGameEnd(dataBuffer)
    else
        print("unknow gamemessage sub is ==>"..sub)
    end
end

function GameLayer:OnSubGameStart( dataBuffer )
    
     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameStart, dataBuffer)

     dump(cmd_table, "the data is ================== >", 6)


     self:resetData()

     self.m_wBlackUser =     cmd_table.wBlackUser
     self.m_wCurrentUser =   cmd_table.wBlackUser
     self.m_bpermitCoach =   cmd_table.bPermitCoach
     self.m_nCoachRestarin = cmd_table.lCoachRestarin
     self.m_wPayCoachUser =  cmd_table.wBankerUser 

      print("start self.m_nCoachRestarin is ========================== >"..self.m_nCoachRestarin)

     --自己棋子颜色
    local color
    if self.m_wBlackUser == self:GetMeUserItem().wChairID then
       color = 1
    else 
       color = 0
    end

    self._color = color
    self._otherColor = 1 - color
    self._gameView:showChessColor(self:GetMeUserItem().wChairID,color)

     --是否禁手  
     self.m_bRestrict = cmd_table.bRestrict

     --设置时间
     self.m_wLeftClock[1] = cmd_table.wGameClock
     self.m_wLeftClock[2] = cmd_table.wGameClock

     --局时
     self._gameView:setRoundTime(cmd_table.wGameClock)

     --步时
     self._gameView:setClockView(0,self.m_wLeftClock[1])
     self._gameView:setClockView(1,self.m_wLeftClock[2])

     self:SetGameClock(self.m_wCurrentUser,0,cmd_table.wGameClock)
     self._gameView:updateControl()

     self._gameView:showBoxAnim(self.m_wCurrentUser)

     self._gameView:showReady(0, 0)
     self._gameView:showReady(1, 0)
end

function GameLayer:OnSubPlaceChess(dataBuffer)

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceChess, dataBuffer)
    dump(cmd_table, "the placeChess data is ============= >     ", 6)

    self.m_wCurrentUser = cmd_table.wCurrentUser
    self.m_wPlaceUser =  cmd_table.wPlaceUser
    self:SetGameClock(self.m_wCurrentUser,0,self.m_wLeftClock[self.m_wCurrentUser+1])
    self._gameView:showBoxAnim(self.m_wCurrentUser)
    self._steps[cmd_table.wPlaceUser+1] = self._steps[cmd_table.wPlaceUser+1] + 1
  
    local  color = -1
    if cmd_table.wPlaceUser == self:GetMeUserItem().wChairID then
        color = self._color
        self._gameView:updateControl()

        self._gameView._bAllowPlaceChess = true
        return
    else
        color = self._otherColor    
    end    

    local pos = {cbXPos=cmd_table.cbXPos,cbYPos=cmd_table.cbYPos}
    self._gameView:convertLogicPosToView(pos,color)
end

function GameLayer:OnSubGameRegretReq(dataBuffer)
    self._gameView:ShowUserReq(g_var(cmd).RegretReq)
end

function GameLayer:OnSubGameRegretFailure(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_RegretFaile, dataBuffer)

    local failureCode = cmd_table.cbFaileReason

    local curScene = cc.Director:getInstance():getRunningScene()
    if g_var(cmd).FR_COUNT_LIMIT == failureCode then
        --悔棋次数过多，悔棋失败
        showToast(curScene, "悔棋次数过多,悔棋失败", 2)
        self.m_bRegretTimeBeyond = true
    end

    if g_var(cmd).FR_PLAYER_OPPOSE == failureCode then
        --玩家反对,悔棋失败
        showToast(curScene, "玩家反对,悔棋失败", 2)
        self._gameView:setRegretBtnEnable(true)
    end
end

function GameLayer:OnSubRegretResult(dataBuffer)

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_RegretResult, dataBuffer)

    self.m_wRegretUser  = cmd_table.wRegretUser
    self.m_wCurrentUser = cmd_table.wCurrentUser

    local round = (self.m_wPlaceUser == self.m_wRegretUser and 1 or 2)

    self._gameView:dealRegret(self.m_wRegretUser,round)

    self.m_wLeftClock[1] = cmd_table.wLeftClock[1][1]
    self.m_wLeftClock[2] = cmd_table.wLeftClock[1][2]

    --步时
    self._gameView:setClockView(0,self.m_wLeftClock[1])
    self._gameView:setClockView(1,self.m_wLeftClock[2])

    self:SetGameClock(self.m_wCurrentUser,0,self.m_wLeftClock[self.m_wCurrentUser+1])
    self._gameView:showBoxAnim(self.m_wCurrentUser)
    self._gameView:setRegretBtnEnable(true)
    self._gameView:updateControl()
end


function GameLayer:OnSubPeaceReq(dataBuffer)
    
    self._gameView:ShowUserReq(g_var(cmd).PeaceReq)
end

function GameLayer:OnSubPeaceAnser(dataBuffer)

    local curScene = cc.Director:getInstance():getRunningScene()
    showToast(curScene, "对方拒绝了您的和棋请求", 2)
    self._gameView:setPeaceBtnEnable(true)
   
end

function GameLayer:OnSubGameCoach( dataBuffer )
    
end 

function GameLayer:OnSubChessManual(dataBuffer)
    self._dataModle:initSign()
    if math.mod(dataBuffer:getlen(),3) ~= 0 then
        error("the size is error",0)
    end

    for i=1,math.floor(dataBuffer:getlen()/3) do
        local cmd_table  = ExternalFun.read_netdata(g_var(cmd).tagChessManual, dataBuffer)
    
        local pos = {cbXPos=cmd_table.cbXPos,cbYPos=cmd_table.cbYPos}
        local  color = 2-cmd_table.cbColor
        table.insert(self._manualRecord, {_pos=pos,_color=color})

     end   

end

function GameLayer:OnSubGameEnd(dataBuffer)

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameEnd, dataBuffer)

    --显示输赢
    self._gameView:showGameEnd(cmd_table)

    --局时
    self._gameView:setRoundTime(0)
    --步时
    self._gameView:setClockView(0,0)
    self._gameView:setClockView(1,0)

    self:SetGameClock(self:GetMeUserItem().wChairID,0,30)
    self._gameView:showBoxAnim(0,false)
    self._gameView:showReadyBtn(true)
    self._gameView:updateControl()
end

--更新秘钥
function GameLayer:OnSubUpdateAesKey(dataBuffer)
    for i = 1, 16 do
        self.cbUserAESKey[i] = dataBuffer:readbyte()
    end
end


--用户状态
function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)

    print("change user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    if newstatus.cbUserStatus == yl.US_FREE or newstatus.cbUserStatus == yl.US_NULL then

        if (oldstatus.wTableID ~= self:GetMeUserItem().wTableID) then
            return
        end

         self._gameView:deleteUserInfo(useritem)
         print("删除")
    else
        
        --刷新用户信息
        if useritem == self:GetMeUserItem() then
            return
        end
        self._gameView:showUserInfo(useritem)
        self._otherNick = useritem.szNickName
        if newstatus.cbUserStatus == yl.US_READY then
            self._gameView:showReady(useritem.wChairID, 1)
        end
    end    
end

--用户进入
function GameLayer:onEventUserEnter(tableid,chairid,useritem)

    print("the table id is ================ >"..tableid)

  --刷新用户信息
    if useritem == self:GetMeUserItem() or tableid ~= self:GetMeUserItem().wTableID then
        return
    end

    self._gameView:showUserInfo(useritem)
    self._otherNick = useritem.szNickName

    if useritem.cbUserStatus == yl.US_READY then
        self._gameView:showReady(useritem.wChairID, 1)
    end

    if self.m_wBlackUser ~= yl.INVALID_CHAIR then
        local color 
        if self.m_wBlackUser == chairid then
            color = 1
        else 
            color = 0
        end
        self._gameView:showChessColor(chairid, color)
    end
end

--用户分数
function GameLayer:onEventUserScore( item )
    if item.wTableID ~= self:GetMeUserItem().wTableID then
       return
    end
    self._gameView:updateScore(item)
end


-----------------------------------------------------------------------------------------------------------------------------

--获得加密Key
function GameLayer:getAesKey()
    --将数组转成字符串
    local strInput = ""
    for i = 1, #self.cbUserAESKey do
        strInput = strInput .. string.format("%d,", self.cbUserAESKey[i])
     end
     --加密
    local result = AesCipher(strInput)
    --将字符串转成数组
    local resultKey = {}
    local k = 1
    local num = 0
    for i = 1, string.len(result) do
        if string.sub(result, i, i) ~= ',' then
            local bt = string.byte(result, i) - string.byte("0")
            num = num*10 + bt
        else
            resultKey[k] = num
            k = k + 1
            num = 0
        end
    end

    return resultKey
end

return GameLayer
--
-- Author: Tang
-- Date: 2016-10-11 17:22:09
--
local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.yule.luxurycar.src";
require("cocos.init")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"

local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local QueryDialog   = require("app.views.layer.other.QueryDialog")
local g_var = ExternalFun.req_var
local GameFrame = appdf.req(module_pre .. ".models.GameFrame")

function GameLayer:ctor( frameEngine,scene )

    print("GameLayer:ctor...........................................")
    ExternalFun.registerNodeEvent(self)
    self.m_bLeaveGame = false
    self._dataModle = GameFrame:create()    
    GameLayer.super.ctor(self,frameEngine,scene)
    self._roomRule = self._gameFrame._dwServerRule

    --游戏变量
    self.m_cbLeftTime = 0     --倒计时时间
    self.m_nMultiple = 1
    self.m_lUserMaxScore = 0  --玩家金币
 
    self.m_wBankerUser = yl.INVLID_WORD  --当前庄家
    self.m_cbBankerTime = 0 --庄家局数
    self.m_lBankerWinScore = 0  --庄家成绩
    self.m_lBankerScore = 0     --庄家分数
    self.bEnableSysBanker = true --系统做庄
    self.m_lApplyBankerCondition = 0  --申请条件

    self.m_lCurrentAddscore = {0,0,0,0,0,0,0,0}  --已投筹码
    self.m_lAllJettonScore  = {0,0,0,0,0,0,0,0}  --总下注额
    self.m_lContinueRecord  = {0,0,0,0,0,0,0,0}  --续压记录

    self.m_RecordList = {}          --游戏记录

    self.m_bPlaceRecord = false

    --游戏结束
    self.m_lEndBankerScore = 0          --庄家成绩
    self.m_lEndUserScore = 0            --玩家成绩
    self.m_lEndUserReturnScore = 0      --返回积分
    self.m_lEndRevenue = 0              --游戏税收                                  

    --设置const数组
     local array = {10000,100000,1000000,5000000,10000000,50000000,100000000}
     self.BetArray = self:readOnly(array)

     self._gameFrame:QueryUserInfo( self:GetMeUserItem().wTableID,yl.INVALID_CHAIR)
end

--创建场景
function GameLayer:CreateView()
     self._gameView = GameViewLayer:create(self)
     self:addChild(self._gameView)
     return self._gameView
end

function GameLayer:resetData()
    
    self.m_lCurrentAddscore = {0,0,0,0,0,0,0,0}  --已投筹码
    self.m_lAllJettonScore  = {0,0,0,0,0,0,0,0}  --总下注额

    --游戏结束
    self.m_lEndBankerScore = 0          --庄家成绩
    self.m_lEndUserScore = 0            --玩家成绩
    self.m_lEndUserReturnScore = 0      --返回积分
    self.m_lEndRevenue = 0  
end

function GameLayer:getParentNode( )
    return self._scene
end

function GameLayer:getFrame( )
    return self._gameFrame
end

function GameLayer:getUserList()
    return self._gameFrame._UserList
end

function GameLayer:sendNetData( cmddata )
    return self:getFrame():sendSocketData(cmddata)
end

function GameLayer:getDataMgr( )
    return self._dataModle
end

function GameLayer:logData(msg)
    if nil ~= self._scene.logData then
        self._scene:logData(msg)
    end
end

function GameLayer:readOnly(t)
    local _table = {}
    local mt = {
        __index = t,
        __newindex = function()
            error(" the table is read only ")
        end
    }
    setmetatable(_table, mt)
    return _table
  end

---------------------------------------------------------------------------------------
function GameLayer:onExit()
    print("gameLayer onExit()...................................")
    self:KillGameClock()
    self:dismissPopWait()
end

--退出桌子
function GameLayer:onExitTable()
    self:KillGameClock()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(2),
            cc.CallFunc:create(
                function ()   
                    self:showPopWait()
                    --self:sendCancelOccupy()
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
end

------网络发送
--玩家下注
function GameLayer:sendUserBet( cbArea, lScore )
    local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_PlaceJetton)
    cmddata:pushbyte(cbArea)
    cmddata:pushscore(lScore)

    self:SendData(g_var(cmd).SUB_C_PLACE_JETTON, cmddata)
end

--超级抢庄
function GameLayer:sendRobBanker()
    local cmddata = CCmd_Data:create(0)

    self:SendData(g_var(cmd).SUB_C_SUPERROB_BANKER, cmddata)
end

--申请上庄
function GameLayer:sendApplyBanker(  )
    local cmddata = CCmd_Data:create(0)
    self:SendData(g_var(cmd).SUB_C_APPLY_BANKER, cmddata)
end

--取消申请
function GameLayer:sendCancelApply(  )
    local cmddata = CCmd_Data:create(0)
    self:SendData(g_var(cmd).SUB_C_CANCEL_BANKER, cmddata)
end

--申请坐下
function GameLayer:sendSitDown( index, wchair )
    local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_OccupySeat)
    cmddata:pushword(wchair)
    cmddata:pushbyte(index) 

    self:SendData(g_var(cmd).SUB_C_OCCUPYSEAT, cmddata)
end

function GameLayer:OnEventGameClockInfo(chair,clocktime,clockID)
    if nil ~= self._gameView  and self._gameView.UpdataClockTime then
        self._gameView:UpdataClockTime(clocktime)
    end

end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time,viewtype)

    GameLayer.super.SetGameClock(self,chair,id,time)
    if nil ~= self._gameView and nil ~= self._gameView.createClockView then
        self.m_cbLeftTime = time
        self._gameView:createClockView(time,viewtype)
    end
end
-------------------------------------------------------------------------------------
--银行 
function GameLayer:onSocketInsureEvent( sub,dataBuffer )
    print(sub)
    self:dismissPopWait()

    if sub == g_var(game_cmd).SUB_GR_USER_INSURE_SUCCESS then
        local cmd_table = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureSuccess, dataBuffer)
        self.bank_success = cmd_table

        self._gameView:onBankSuccess()

    elseif sub == g_var(game_cmd).SUB_GR_USER_INSURE_FAILURE then

        local cmd_table = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureFailure, dataBuffer)
        self.bank_fail = cmd_table

        self._gameView:onBankFailure()
    else
        print("unknow gamemessage sub is ==>"..sub)
    end
end

-------------------------------------------------------------------------------------场景消息

-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    print("场景数据:" .. cbGameStatus)

    self._gameView:removeAction()
    self:KillGameClock()
    
    self._gameView.m_cbGameStatus = cbGameStatus;
	if cbGameStatus == g_var(cmd).GS_GAME_FREE	then                        --空闲状态
        self:onEventGameSceneFree(dataBuffer);
	elseif cbGameStatus == g_var(cmd).GS_PLACE_JETTON 	then                      
        self:onEventGameSceneStatus(dataBuffer);
	elseif cbGameStatus >= g_var(cmd).GS_GAME_END	then                         
        self:onEventGameSceneStatus(dataBuffer);
	end
    self:dismissPopWait()
end

function GameLayer:onEventGameSceneFree(buffer)    --空闲 

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusFree, buffer)
    print("···cmd_table.nMultiple is ====================== >"..cmd_table.nMultiple)
    self.m_nMultiple = cmd_table.nMultiple
    self._dataModle._Multiple = cmd_table.nMultiple
    self.m_lUserMaxScore = cmd_table.lUserMaxScore  --玩家金币
    self.m_wBankerUser = cmd_table.wBankerUser  --当前庄家
    self.m_cbBankerTime = cmd_table.cbBankerTime --庄家局数
    self.m_lBankerWinScore = cmd_table.lBankerWinScore  --庄家成绩
    self.m_lBankerScore = cmd_table.lBankerScore     --庄家分数
    self.bEnableSysBanker = cmd_table.bEnableSysBanker --系统做庄
    self.m_lApplyBankerCondition = cmd_table.lApplyBankerCondition  --申请条件


    --刷新玩家信息
    self._gameView:updateScore(self:GetMeUserItem().lScore * self.m_nMultiple)


    --庄家信息
    local nick
    local userItem =  self._dataModle:getUserByChair(self:getUserList(),self.m_wBankerUser)
    if self.m_wBankerUser == 65535 then
        nick = "系统坐庄"
    else
      
       nick = userItem.szNickName
    end

    local str 
    if self.m_lBankerWinScore >= 0 then
        str = "+"..ExternalFun.numberThousands(self.m_lBankerWinScore)
    else
        str = ExternalFun.numberThousands(self.m_lBankerWinScore)
    end

    local str1 
    if self.m_lBankerScore >= 0 then
        str1 = "+"..ExternalFun.numberThousands(self.m_lBankerScore)
    else
        str1 = ExternalFun.numberThousands(self.m_lBankerScore)
    end

    local info = {nick,str,str1,string.format("%d", self.m_cbBankerTime),userItem}
    self._gameView:ShowBankerInfo(info)
     
    
	 self:SetGameClock(self:GetMeChairID(), g_var(cmd).CLOCK_FREE, cmd_table.cbTimeLeave,0)
     self._gameView:SetClockType(g_var(cmd).CLOCK_FREE)

     --弹出开奖界面
     self._gameView:AddViewSlipToHidden()
     self._gameView:RollApear()

     self._gameView:updateControl(g_var(cmd).Apply)

end

function GameLayer:onEventGameSceneStatus(buffer)   
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, buffer)
    print("···cmd_table.nMultiple is ====================== >"..cmd_table.nMultiple)
    self.m_nMultiple = cmd_table.nMultiple
    self._dataModle._Multiple = cmd_table.nMultiple
    self.m_lUserMaxScore = cmd_table.lUserMaxScore  --玩家金币
    self.m_wBankerUser = cmd_table.wBankerUser  --当前庄家
    self.m_cbBankerTime = cmd_table.cbBankerTime --庄家局数
    self.m_lBankerWinScore = cmd_table.lBankerWinScore  --庄家成绩
    self.m_lBankerScore = cmd_table.lBankerScore     --庄家分数
    self.bEnableSysBanker = cmd_table.bEnableSysBanker --系统做庄
    self.m_lApplyBankerCondition = cmd_table.lApplyBankerCondition  --申请条件


    --刷新玩家信息
    self._gameView:updateScore(self:GetMeUserItem().lScore * self.m_nMultiple)


     --庄家信息
    local nick
    local userItem =  self._dataModle:getUserByChair(self:getUserList(),self.m_wBankerUser)
    if self.m_wBankerUser == 65535 then
        nick = "系统坐庄"
    else
       
       nick = userItem.szNickName
    end

    local str 
    if self.m_lBankerWinScore >= 0 then
        str = "+"..ExternalFun.numberThousands(self.m_lBankerWinScore)
    else
        str = ExternalFun.numberThousands(self.m_lBankerWinScore)
    end

    local str1 
    if self.m_lBankerScore >= 0 then
        str1 = "+"..ExternalFun.numberThousands(self.m_lBankerScore)
    else
        str1 = ExternalFun.numberThousands(self.m_lBankerScore)
    end

    local info = {nick,str,str1,string.format("%d", self.m_cbBankerTime),userItem}
    self._gameView:ShowBankerInfo(info)


--倒计时类型
    local clockType =  g_var(cmd).CLOCK_ADDGOLD 
    if self._gameView.m_cbGameStatus == g_var(cmd).GS_GAME_END then

       clockType = g_var(cmd).GS_GAME_END
     

       self._gameView:SetEndInfo(cmd_table.lEndBankerScore,cmd_table.lEndUserScore)

       --设置倒计时
        if cmd_table.cbTimeLeave > 0 then
            self:SetGameClock(self:GetMeChairID(), clockType, cmd_table.cbTimeLeave,0)
            self._gameView:SetClockType(clockType)
        end

          --弹出开奖界面
       self._gameView.endindex = cmd_table.cbStopIndex
       self._gameView:AddViewSlipToHidden()
       self._gameView:RollApear()
    end

    --下注界面
    if  self._gameView.m_cbGameStatus == g_var(cmd).GS_PLACE_JETTON then
        self:SetGameClock(self:GetMeChairID(), clockType, cmd_table.cbTimeLeave,1)
        self._gameView:RollDisAppear()
        self._gameView:AddViewSlipToShow()

        self._gameView:updateControl(g_var(cmd).Jettons)
        self._gameView:updateControl(g_var(cmd).Continue)
    
    end


    self._gameView:updateControl(g_var(cmd).Apply)

end


--------------------------------------------------------------------------------------- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)  

    if self.m_bLeaveGame or nil == self._gameView then
        return
    end 

	if sub == g_var(cmd).SUB_S_GAME_FREE then  --游戏空闲
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_SCENE_FREE
		self:onSubGameFree(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_GAME_START then --游戏开始
        self._gameView.m_cbGameStatus = g_var(cmd).GS_PLACE_JETTON
        self:onSubGameStart(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_PLACE_JETTON then --游戏下注
        self:onSubGamePlaceJetton(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_PLACE_JETTON_FAIL then --下注失败
        self:onSubJettonFail(dataBuffer)  
    elseif sub == g_var(cmd).SUB_S_GAME_END then --游戏结束
         self._gameView.m_cbGameStatus = g_var(cmd).GS_GAME_END
        self:onSubGameEnd(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_SEND_RECORD then --游戏记录
         self:onSubGameRecord(dataBuffer)    
    elseif sub == g_var(cmd).SUB_S_CHANGE_BANKER then --切换庄家
         self:onSubChangeBanker(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_APPLY_BANKER then  --申请庄家
         self:onSubApplyBanker(dataBuffer)  
    elseif sub == g_var(cmd).SUB_S_CANCEL_BANKER then  --取消申请
         self:onSubCancelBanker(dataBuffer)    
	else

		print("unknow gamemessage sub is ==>"..sub)
	end
end

function GameLayer:onSubGameFree(dataBuffer)  --游戏空闲

     self:resetData()
     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameFree, dataBuffer)

     self._gameView:removeAction()
     self._gameView:restData()
     self._gameView:SetEndView(false)
     self:SetGameClock(self:GetMeChairID(), g_var(cmd).CLOCK_FREE, cmd_table.cbTimeLeave,0)
     self._gameView:SetClockType(g_var(cmd).CLOCK_FREE)

     self._gameView:updateControl(g_var(cmd).Jettons)
     self._gameView:updateControl(g_var(cmd).Continue)
     self._gameView:updateControl(g_var(cmd).Apply)

     self._gameView:playEffect("sound_res/BACK_GROUND_FREE.wav")


end

function GameLayer:onSubGameStart(dataBuffer) --游戏开始
    self:resetData()
    self._gameView:SetEndView(false)

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameStart, dataBuffer)

    self.m_wBankerUser = cmd_table.wBankerUser
    self.m_lBankerScore = cmd_table.lBankerScore
    self.m_lUserMaxScore = cmd_table.lUserMaxScore

  
    self._gameView:removeAction()
    self._gameView:restData()
    self:KillGameClock()
    self._gameView:RollDisAppear()
    self._gameView:AddViewSlipToShow()
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).CLOCK_FREE, cmd_table.cbTimeLeave,1)

    self._gameView:updateControl(g_var(cmd).Jettons)
    self._gameView:updateControl(g_var(cmd).Continue)
    self._gameView:updateControl(g_var(cmd).Apply)

    self._gameView:playEffect("sound_res/GAME_START.wav")
     self._gameView:playEffect("sound_res/betTime_music.wav")
end

function GameLayer:onSubGamePlaceJetton( dataBuffer ) --用户下注
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceJetton, dataBuffer)
    if cmd_table.wChairID ~= self:GetMeUserItem().wChairID then 
        self._gameView:playEffect("sound_res/ADD_GOLD.wav")
        self.m_lAllJettonScore[cmd_table.cbJettonArea] = self.m_lAllJettonScore[cmd_table.cbJettonArea] + cmd_table.lJettonScore*self.m_nMultiple
    else

        if not self.m_bPlaceRecord then
            self.m_lContinueRecord = {0,0,0,0,0,0,0,0}
            self.m_bPlaceRecord = true
        end

        self.m_lContinueRecord[cmd_table.cbJettonArea] = self.m_lContinueRecord[cmd_table.cbJettonArea] + cmd_table.lJettonScore*self.m_nMultiple  --续压记录
    end

--刷新筹码
    self._gameView:UpdateAreaJetton()

end


function GameLayer:onSubJettonFail( dataBuffer )
     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceJettonFail, dataBuffer)

     --还原数据
     if cmd_table.wPlaceUser == self:GetMeUserItem().wChairID then
        self.m_lAllJettonScore[cmd_table.cbJettonArea] =  self.m_lAllJettonScore[cmd_table.cbJettonArea] - cmd_table.lPlaceScore*self.m_nMultiple
        local viewIndex = self._gameView:GetViewAreaIndex(cmd_table.cbJettonArea)
        self.m_lCurrentAddscore[viewIndex] = self.m_lCurrentAddscore[viewIndex] - cmd_table.lPlaceScore*self.m_nMultiple
        --刷新显示
        self._gameView:UpdateAreaJetton()
     end
end

function GameLayer:onSubApplyBanker(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_ApplyBanker, dataBuffer)

    local useritem = self._dataModle:getUserByChair(self:getUserList(),cmd_table.wApplyUser)
    self._dataModle:insertBankerList(useritem)
    self._gameView._bankerView:reloadData()

    if cmd_table.wApplyUser == self:GetMeUserItem().wChairID then
        self._gameView:SetApplyStatus(self._gameView.applyed)
    end


end

function GameLayer:onSubCancelBanker( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_CancelBanker, dataBuffer)

    self._dataModle:removeBankList(self._dataModle:getUserByChair(self:getUserList(),cmd_table.wCancelUser))
    self._gameView._bankerView:reloadData()

    if cmd_table.wCancelUser == self:GetMeUserItem().wChairID then
        print("...自己取消上庄...")
        self._gameView:SetApplyStatus(self._gameView.unApply)
    end
end

function GameLayer:onSubChangeBanker( dataBuffer )
     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_ChangeBanker, dataBuffer)


     self.m_wBankerUser = cmd_table.wBankerUser
     self.m_lBankerScore = cmd_table.lBankerScore
     self.m_cbBankerTime = 0

    --从列表中删除当前庄家
     self._dataModle:removeBankList(self._dataModle:getUserByChair(self:getUserList(),self.m_wBankerUser))
     self._gameView._bankerView:reloadData()

 --昵称
    local nick
    local userItem =  self._dataModle:getUserByChair(self:getUserList(),self.m_wBankerUser)
    if self.m_wBankerUser == 65535 then
        nick = "系统坐庄"
    else
       nick = userItem.szNickName
    end

--庄家信息
    local str1 
    if self.m_lBankerScore >= 0 then
        str1 = "+"..ExternalFun.numberThousands(self.m_lBankerScore)
    else
        str1 = ExternalFun.numberThousands(self.m_lBankerScore)
    end

    local info = {nick,"+0",str1,string.format("%d", self.m_cbBankerTime),userItem}
    self._gameView:ShowBankerInfo(info)

end


function GameLayer:onSubGameEnd( dataBuffer ) --游戏结束
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameEnd, dataBuffer)
    --dump(cmd_table, "the cmd_table is ===============================================> ", 6)
    self._gameView.m_cbGameStatus = GS_GAME_END
    self.m_bPlaceRecord = false

    self.m_cbBankerTime = cmd_table.nBankerTime    
    self.m_lBankerWinScore  = cmd_table.lBankerTotallScore * self.m_nMultiple

      --庄家信息
    local nick
    local userItem =  self._dataModle:getUserByChair(self:getUserList(),self.m_wBankerUser)
    if self.m_wBankerUser == 65535 then
        nick = "系统坐庄"
         self.m_lBankerScore = 1000000000
    else
       
       nick = userItem.szNickName

        self.m_lBankerScore = userItem.lScore * self.m_nMultiple
    end

    local str 
    if self.m_lBankerWinScore >= 0 then
        str = "+"..ExternalFun.numberThousands(self.m_lBankerWinScore)
    else
        str = ExternalFun.numberThousands(self.m_lBankerWinScore)
    end

    local str1 
    if self.m_lBankerScore >= 0 then
        str1 = "+"..ExternalFun.numberThousands(self.m_lBankerScore)
    else
        str1 = ExternalFun.numberThousands(self.m_lBankerScore)
    end

    --庄家信息
    local info = {nick,str,str1,self.m_cbBankerTime,userItem}
    self._gameView:ShowBankerInfo(info)
           
    --弹出开奖界面
    self._gameView.endindex = cmd_table.cbStopIndex

    --插入记录
    self._gameView:addRcord(self._gameView.endindex)

    --倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).CLOCK_AWARD, cmd_table.cbTimeLeave,0)
    self._gameView:SetClockType(g_var(cmd).CLOCK_AWARD)

        --转盘界面
    self._gameView:AddViewSlipToHidden()
    self._gameView:RollApear()

    --更新按钮状态
    self._gameView:updateControl(g_var(cmd).Jettons)
    self._gameView:updateControl(g_var(cmd).Continue)
    self._gameView:updateControl(g_var(cmd).Apply)

    --结束信息
    self._gameView:SetEndInfo(cmd_table.lBankerScore,cmd_table.lUserScore)

end

function GameLayer:onSubGameRecord( dataBuffer )
     local recordCount = math.floor(dataBuffer:getlen()/1)
    if recordCount >= 1 then
        for i=1,recordCount do
          local record = ExternalFun.read_netdata(g_var(cmd).tagServerGameRecord,dataBuffer)
          self._gameView:addRcord(record.cbCarIndex)
        end
    end
end

--用户进入
function GameLayer:onEventUserEnter( wTableID,wChairID,useritem )
    print("add user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    --缓存用户
    self._dataModle:insertUserList(useritem)


    --刷新用户列表
    if nil ~= self._gameView._UserView then
        self._gameView._UserView:reloadData()
    end
   

end

--用户状态
function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)
    print("change user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    if newstatus.cbUserStatus == yl.US_FREE or newstatus.cbUserStatus == yl.US_NULL then
        self._dataModle:removeUserList(useritem)
        if nil ~= self._gameView._UserView then
            self._gameView._UserView:reloadData()
        end
          print("删除")
    else
        --刷新用户信息
        self._dataModle:insertUserList(useritem)

        if nil ~= self._gameView._UserView  then
            self._gameView._UserView:reloadData()
        end
       
    end    
end

--用户分数
function GameLayer:onEventUserScore( item )
    if item.dwUserID == self:GetMeUserItem().dwUserID then
        self._gameView:updateScore(item.lScore * self.m_nMultiple)
    end

    --刷新用户列表
    if self._gameView._UserView then
         self._gameView._UserView:reloadData()
    end
   
    --刷新庄家列表
    self._gameView._bankerView:reloadData()
end

--用户聊天
function GameLayer:onUserChat(chat, wChairId)

    if wChairId== self:GetMeUserItem().wChairID then  --过滤自己
        return
    end

    local useritem = self._dataModle:getUserByChair(self:getUserList(),wChairId)
    if not useritem then
        return
    end

    self._gameView:userChat(useritem.szNickName, chat.szChatString)
end

--用户表情
function GameLayer:onUserExpression(expression, wChairId)

    if wChairId== self:GetMeUserItem().wChairID then  --过滤自己
        return
    end

    local useritem = self._dataModle:getUserByChair(self:getUserList(),wChairId)
    if not useritem then
        return
    end
    
    self._gameView:userExpression(useritem.szNickName, expression.wItemIndex)
end




return GameLayer
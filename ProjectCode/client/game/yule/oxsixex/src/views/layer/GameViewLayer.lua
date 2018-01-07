local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)

local cmd = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.GameLogic")
local QBasePlayer  = import(".QBasePlayer")
local QMyPlayer    = import(".QMyPlayer")
local QOtherPlayer = import(".QOtherPlayer")
local NGResources = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.NGResources")
local PopupInfoHead = appdf.req(appdf.CLIENT_SRC.."external.PopupInfoHead")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")

GameViewLayer.cocosUiPath = "game/csb/gameLayer.csb"
GameViewLayer.TAG_NAME = 1
GameViewLayer.TAG_MONEY = 2
GameViewLayer.TAG_HEAD = 3
GameViewLayer.TAG_ZHUANG = 4
GameViewLayer.RES_PATH              = "game/yule/oxsixex/res/"

--第一张背景图下面的资源
GameViewLayer.UiTag = {
    eImageBj = 0,
    eBtnBack = 1,
    eBtnSet = 2,
    eBtnRobot = 3,
    eBtnChat = 4,
    eBtnStart = 5,
    eBtnLiangPai = 8,
    eBtnTishi = 9,
    eImageHeadBjBegin = 10,
    eImageHeadBjMy = 13,
    eImageHeadBjEnd = 15,
    eLayerZhunBei = 20,
    eImageAdNiuK = 21,
    eImageTipsWaitOxCard = 22,
    eBtnSoundOff = 23,
}

function GameViewLayer:onExit()
    print("GameViewLayer onExit")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/card.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/card2.png")
    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/game.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/game.png")
    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("public_res/public_res.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("public_res/public_res.png")

    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()

    local _searchPath = device.writablePath .. "game/yule/oxsixex/res/"
    --重置搜索路径
    local oldPaths = cc.FileUtils:getInstance():getSearchPaths();
    local newPaths = {};
    for k,v in pairs(oldPaths) do
        if tostring(v) ~= tostring(_searchPath) then
            table.insert(newPaths, v);
        end
    end
    cc.FileUtils:getInstance():setSearchPaths(newPaths);
end

function GameViewLayer:ctor(scene)
	self._scene = scene
    self.m_pClockLayer_ = nil
    self.m_pUserItem_ = self._scene._gameFrame:GetMeUserItem()
    self.m_nTableID = self.m_pUserItem_.wTableID
    self.m_nChairID = self.m_pUserItem_.wChairID	
    self.m_pPlayers = {}
    self.m_tHeadPos_ = {}
    self.m_tHeadPos_[0] = cc.p(550.0,display.height - 115.0)
    self.m_tHeadPos_[1] = cc.p(84.0,display.height - 240.0)
    self.m_tHeadPos_[2] = cc.p(84.0,display.height/2 - 85.0)
    self.m_tHeadPos_[3] = cc.p(430.0,90.0)
    self.m_tHeadPos_[4] = cc.p(1250.0,display.height/2 - 85.0)
    self.m_tHeadPos_[5] = cc.p(1250.0,display.height - 240.0)
    self:initUi()
    --节点事件
    local function onNodeEvent(event)
        if event == "exit" then
            self:onExit()
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function GameViewLayer:getGameLayerObj()
    return self._scene
end

function GameViewLayer:getHeadPos()
    return self.m_tHeadPos_
end

function GameViewLayer:initUi()
    self.rootLayer, self.resourceNode_ = ExternalFun.loadRootCSB(self.cocosUiPath, self)
    assert(self.resourceNode_, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))

    self:initBtn()

    local qImage = nil

    qImage = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eImageBj)
    if qImage then
        qImage:setPosition(display.center)
        qImage:setScaleX(display.width/1136)
        qImage:setScaleY(display.height/640)
    end

    --头像背景
    for i=GameViewLayer.UiTag.eImageHeadBjBegin,GameViewLayer.UiTag.eImageHeadBjEnd do
        qImage = self.resourceNode_:getChildByTag(i)
        if qImage then
            qImage:setPosition(self.m_tHeadPos_[i-GameViewLayer.UiTag.eImageHeadBjBegin])
            qImage:setVisible(false)
        end
    end

     --准备层
    local pointReady = {cc.p(518, 455), cc.p(56, 325), cc.p(56, 105), cc.p(738, 125), cc.p(1030, 105), cc.p(1030, 325)}
    local pLayer = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eLayerZhunBei)
    if pLayer then
        pLayer:setPosition(cc.p(126.0,95.0))
        for i = 1, 6 do
            local ready = pLayer:getChildByTag(i - 1)
            ready:move(pointReady[i])
            ready:setVisible(false)
        end
    end

    self:showPlayerInfo(cmd.MY_VIEW_CHAIRID,self.m_pUserItem_)

     --加载6个玩家
    local playerObj = nil
	for i = 1,cmd.GAME_PLAYER do
        local iViewID = i-1
        if iViewID == cmd.MY_VIEW_CHAIRID then
            playerObj = QMyPlayer:create(self.m_tHeadPos_[iViewID])
        else
            playerObj = QOtherPlayer:create(iViewID,self.m_tHeadPos_[iViewID])
        end
        self.m_pPlayers[iViewID] = playerObj
        self:addChild(playerObj)
    end

    --点击牌显示点数的框
    qImage = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eImageAdNiuK)
    if qImage then
        qImage:setPosition(cc.p(display.width/2,display.height/2))
    end

    --等待摊牌
    qImage = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eImageTipsWaitOxCard)
    if qImage then
        qImage:setPosition(cc.p(display.width/2,display.height/2-20.0))
    end

    --clock
    self.m_pImageClock_ = ccui.ImageView:create(NGResources.GameRes.sClockBjPath,ccui.TextureResType.plistType)
    self.m_pImageClock_:setPosition(cc.p(430.0,215.0))
    self.m_pImageClock_:setVisible(false)
    self:addChild(self.m_pImageClock_)

    self.m_pTextClock_ = ccui.TextAtlas:create()
    self.m_pTextClock_:setProperty("1", NGResources.GameRes.sClockNumPath, 18, 23, "0")
    self.m_pTextClock_:setPosition(cc.p(self.m_pImageClock_:getContentSize().width/2,self.m_pImageClock_:getContentSize().height/2))   
    self.m_pImageClock_:addChild(self.m_pTextClock_)

    --声音
    local bAble = GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble
    if GlobalUserItem.bVoiceAble then
        AudioEngine.playMusic(GameViewLayer.RES_PATH.."sound/BACK_MUSIC.wav", true)
    end
    self.btSound = ccui.CheckBox:create(GameViewLayer.RES_PATH.."public/bt_sound_0.png", 
                                        GameViewLayer.RES_PATH.."public/bt_sound_1.png", 
                                        GameViewLayer.RES_PATH.."public/bt_soundOff_0.png", 
                                        GameViewLayer.RES_PATH.."public/bt_soundOff_1.png", 
                                        GameViewLayer.RES_PATH.."public/bt_soundOff_1.png")
        :move(147, yl.HEIGHT - 51)
        :setTag(GameViewLayer.UiTag.eBtnSoundOff)
        :setColor(cc.c3b(255, 210, 150))
        :setSelected(not bAble)
        :addTo(self, 1)
    self.btSound:addTouchEventListener(handler(self,self.menuClick))
end

function GameViewLayer:initBtn()
    local qBtn = nil
    for i = GameViewLayer.UiTag.eBtnBack,GameViewLayer.UiTag.eBtnTishi do
        qBtn = self.resourceNode_:getChildByTag(i)
        if qBtn then
            if i == GameViewLayer.UiTag.eBtnBack then
                qBtn:setPressedActionEnabled(true)
                qBtn:setPosition(cc.p(54.0,display.height - 50.0))
            elseif i == GameViewLayer.UiTag.eBtnSet then
                qBtn:setPosition(cc.p(1035.0,display.height - 50.0))
                qBtn:setVisible(false)
            elseif i == GameViewLayer.UiTag.eBtnRobot then
                qBtn:setPosition(cc.p(1160.0,display.height - 48.0))
                qBtn:setVisible(false)
            elseif i == GameViewLayer.UiTag.eBtnChat then
                qBtn:setPosition(cc.p(1285.0,display.height - 55.0))
            elseif i == GameViewLayer.UiTag.eBtnStart then
                qBtn:setPosition(cc.p(1120.0,123.0)) 
                qBtn:setVisible(false)
            elseif i == GameViewLayer.UiTag.eBtnLiangPai then
                qBtn:setPosition(cc.p(1120.0,123.0))
                qBtn:setVisible(false)
            elseif i == GameViewLayer.UiTag.eBtnTishi then
                qBtn:setPosition(cc.p(1120.0,44.0))
                qBtn:setVisible(false)
            end

            qBtn:addTouchEventListener(handler(self,self.menuClick))
        end
    end
end

function GameViewLayer:menuClick(sender,type)
    if type == ccui.TouchEventType.ended then
        local node = sender
		local tar = node:getTag()
        if tar == GameViewLayer.UiTag.eBtnBack  then 
            self._scene:onBtnSendMessage(tar)
        elseif tar == GameViewLayer.UiTag.eBtnSet then
            print("GameViewLayer.UiTag.eBtnSet")
        elseif tar == GameViewLayer.UiTag.eBtnRobot then
            print("GameViewLayer.UiTag.eBtnRobot")
        elseif tar == GameViewLayer.UiTag.eBtnChat then
            if self.m_pChatLayer_ == nil then
                local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
                self.m_pChatLayer_ = GameChatLayer:create(self._scene._gameFrame)
                self:addChild(self.m_pChatLayer_,100)
            end
            self.m_pChatLayer_:showGameChat(true)
        elseif tar == GameViewLayer.UiTag.eBtnStart then
            self:showBtn(false)
            self._scene:onBtnSendMessage(tar)
            self._scene:KillGameClock()
        elseif tar == GameViewLayer.UiTag.eBtnLiangPai then
            self:OnOpenCard()
        elseif tar == GameViewLayer.UiTag.eBtnTishi then
            self:OnHintOx()
        elseif tar == GameViewLayer.UiTag.eBtnChangeDesk then
            self._scene:onBtnSendMessage(tar)
        elseif tar == GameViewLayer.UiTag.eBtnSoundOff then
            local effect = not (GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble)
            GlobalUserItem.setSoundAble(effect)
            GlobalUserItem.setVoiceAble(effect)
            if effect == true then
                AudioEngine.playMusic(GameViewLayer.RES_PATH.."sound/BACK_MUSIC.wav", true)
            end
        end
    end
end

function GameViewLayer:OnOpenCard()
    local tData = {}
    tData.bOX = 0
    local m_cbHandCardData = self._scene:getHandCardData()
    local t_hand = m_cbHandCardData[self.m_nChairID+1]
    if GameLogic.GetOxCard(t_hand) then    --有牛
        tData.bOX = 1
    end

    local iType = GameLogic.GetCardType(t_hand)
    local iValue = GameLogic.getOxValue(iType)

    
    tData.cbOxCardData = t_hand

    self._scene:onBtnSendMessage(GameViewLayer.UiTag.eBtnLiangPai,tData)

    self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:showCardTypeUI(iValue,iType)
    self:showAdNiuK(false)
    self._scene:KillGameClock();
    self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:showHandCardUI(t_hand)
    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/OPEN_CARD.wav")
end

--提示按钮
function GameViewLayer:OnHintOx()
    local m_cbHandCardData = self._scene:getHandCardData()
    
	if GameLogic.GetOxCard(m_cbHandCardData[self.m_nChairID+1]) then    --有牛
        self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:SetShootCard(m_cbHandCardData[self.m_nChairID+1],3)
	else                                                                --无牛
        self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:showCardTypeUI(0)
	end

    self:showAdNiuK(true)
end

function GameViewLayer:showBtn(bShowStart,bShowLiangP,bShowZb)
    local qBtn = nil

    if bShowStart ~= nil then
        qBtn = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eBtnStart)
        if qBtn then
            qBtn:setVisible(bShowStart)
            qBtn:setEnabled(bShowStart)
            qBtn:setBright(bShowStart)
        end
    end
   
    if bShowLiangP ~= nil then
        qBtn = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eBtnLiangPai)
        if qBtn then
            qBtn:setVisible(bShowLiangP)
            qBtn:setEnabled(bShowLiangP)
            qBtn:setBright(bShowLiangP)
        end

        -- qBtn = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eBtnTishi)
        -- if qBtn then
        --     qBtn:setVisible(bShowLiangP)
        --     qBtn:setEnabled(bShowLiangP)
        --     qBtn:setBright(bShowLiangP)
        -- end
    end 
end

function GameViewLayer:showFreeStatues()
    print("-------------------showFreeStatues-------------------")
    self:showBtn(true)
    self.m_nTableID = self._scene._gameFrame:GetTableID()
    self.m_nChairID = self._scene._gameFrame:GetChairID()
    print(self.m_nTableID,self.m_nChairID)
    self:updateUserInfo()
    self._scene:SetGameClock(self.m_nChairID,cmd.IDI_START_GAME,cmd.TIME_USER_START_GAME)
end

function GameViewLayer:showPlayStatues(t_data)
    print("-------------------showPlayStatues-------------------")
    if t_data == nil then
        return
    end

    self:showZhunBei(nil)
    self:showAdNiuK(false)

    local wBankerUser = self._scene:getBankUser()
    self:showZhuang(wBankerUser,true)

    local cbPlayStatus = t_data.cbPlayStatus
    local cbCardData = t_data.cbHandCardData

    self:updateUserInfo()

    --显示扑克
	for i = 1,cmd.GAME_PLAYER do
        local iViewID = self:GetPlayViewStation(i-1);
        if cbPlayStatus[i] == 1 then
            if cbCardData[i] then
                self.m_pPlayers[iViewID]:showHandCardUI(cbCardData[i])
            end

            if iViewID == cmd.MY_VIEW_CHAIRID then
                self:showBtn(false,true)
            end
        end
    end


    --时间设置
    self._scene:SetGameClock(self.m_nChairID,cmd.IDI_TIME_OPEN_CARD,cmd.TIME_USER_OPEN_CARD)
end

function GameViewLayer:showReady()
    self:showBtn(false,nil)
    self:showZhunBei(cmd.MY_VIEW_CHAIRID,true)
end

function GameViewLayer:showGameStart()
    print("-------------------showGameStart-------------------")
    for i = 1,cmd.GAME_PLAYER do
        self.m_pPlayers[i-1]:removeUI()
    end 
    self:showBtn(false,true)
    self:showZhunBei(nil)
    ------------------------------------------------------------
    local wBankerUser = self._scene:getBankUser()
    self:showZhuang(wBankerUser,true)

    local cbPlayStatus = self._scene:getPlayStatues()
    local cbCardData = self._scene:getHandCardData()
    --显示扑克
	for i = 1,cmd.GAME_PLAYER do
        local iViewID = self:GetPlayViewStation(i-1);
        if cbPlayStatus[i] == 1 then
            if cbCardData[i] then
                self.m_pPlayers[iViewID]:playSendCardAction(cbCardData[i])
            end
        end
    end

    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_START.wav")
    --时间设置
    self._scene:SetGameClock(self.m_nChairID,cmd.IDI_TIME_OPEN_CARD,cmd.TIME_USER_OPEN_CARD)
end

function GameViewLayer:showOpenCard(t_data)
    if t_data == nil then
        return
    end

    if t_data.wPlayerID ~= self.m_nChairID then
        local iViewID = self:GetPlayViewStation(t_data.wPlayerID)
        self.m_pPlayers[iViewID]:showTipsOpenCard(true)
    else
        self:showBtn(false,false)
        self:showAdNiuK(false)
        self:showStudioChild(GameViewLayer.UiTag.eImageTipsWaitOxCard,true)

        local m_cbHandCardData = self._scene:getHandCardData()
        local t_hand = m_cbHandCardData[t_data.wPlayerID+1]
        if t_hand == nil or t_hand[1] ==0 then
            return
        end
    
        self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:showDeskCardUI(t_hand,t_data.bOpen)
    end
end

function GameViewLayer:showGameEnd(t_data)
    if t_data == nil then
        return
    end

    self:showZhunBei(nil)
    self:showBtn(true,false)
    self:showAdNiuK(false)
    self:showStudioChild(GameViewLayer.UiTag.eImageTipsWaitOxCard,false)
    for i = 1,cmd.GAME_PLAYER do
        self.m_pPlayers[i-1]:showTipsOpenCard(false)
    end
    
    self._scene:SetGameClock(self.m_nChairID,cmd.IDI_START_GAME,cmd.TIME_USER_START_GAME)

    local cbPlayStatus = self._scene:getPlayStatues()
    local tOx = self._scene:getOx()
    --显示扑克
	for i = 1,cmd.GAME_PLAYER do
        if cbPlayStatus[i] == 1 then
            local iViewID = self:GetPlayViewStation(i-1);
            if t_data.cbCardData[i] then
                self.m_pPlayers[iViewID]:showDeskCardUI(t_data.cbCardData[i],tOx[i])
            end
            --显示牛几
            if i ~= self.m_nChairID+1 then
                if tOx[i] == 0 or tOx[i] == 255 then
                    self.m_pPlayers[iViewID]:showCardTypeUI(0)
                else
                    local m_cbHandCardData = self._scene:getHandCardData()
                    local t_hand = m_cbHandCardData[i]
                    if t_hand ~= nil and t_hand[1] ~=0 then
                        if GameLogic.GetOxCard(t_hand) then    --有牛
                            local iType = GameLogic.GetCardType(t_hand)
                            local iValue = GameLogic.getOxValue(iType)
                            print("showOpenCard.iType=====" .. iType,"showOpenCard.iValue=====" .. iValue)
                            self.m_pPlayers[iViewID]:showCardTypeUI(iValue,iType)
                            if iValue == 10 then
                                AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_OXOX.wav")
                            end
                        end    
                    end
                end
            end
        end
    end

    --显示结算 刷新钱
    local iMoney = 0
    local tScore = t_data.lGameScore
    for i = 1,cmd.GAME_PLAYER do
        if cbPlayStatus[i] == 1 and tScore[i] ~= 0 then
            local iViewID = self:GetPlayViewStation(i-1)
            self.m_pPlayers[iViewID]:showJskUI(tScore[i])
            if iViewID == cmd.MY_VIEW_CHAIRID then
                self.m_pUserItem_.lScore = self.m_pUserItem_.lScore + tScore[i]
                iMoney = self.m_pUserItem_.lScore
                self:setUserMoney(iViewID,iMoney)
                --自己是否赢了
                if tScore[i] > 0 then
                    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_WIN.wav")
                else
                    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_LOST.wav")
                end
            else
                local useritem = self._scene._gameFrame:getTableUserItem(self.m_nTableID,i-1)
                if useritem then
                    useritem.lScore = useritem.lScore + tScore[i]
                    iMoney = useritem.lScore
                    self:setUserMoney(iViewID,iMoney)
                end
            end
        end
    end

    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_END.wav")
    --清除数据
    self._scene:onResetData()
end

--强行退出
function GameViewLayer:dealGameExit(wPlayid)
    if wPlayid == nil then
        return
    end
    local iViewID = self:GetPlayViewStation(wPlayid)
    self.m_pPlayers[iViewID]:removeUI()
    self:showPlayerInfo(iViewID,nil,false)
end

function GameViewLayer:showChat(tData)
    if tData == nil then
        return
    end

    self.m_pChatLayer_:showGameChat(false)
    for i=1,cmd.GAME_PLAYER do
        local useritem = self._scene._gameFrame:getTableUserItem(self.m_nTableID,i-1)
        if useritem then
            if useritem.dwUserID  == tData.dwSendUserID  then
                local viewID = self:GetPlayViewStation(i-1)
                local qImageHeadbj = self.resourceNode_:getChildByTag(viewID+10)
                if qImageHeadbj:isVisible() then
                    self.m_pPlayers[viewID]:showChat(tData)
                end
                return
            end
        end
    end
end

function GameViewLayer:GetPlayViewStation(id)
    if id == self.m_nChairID then
		return cmd.MY_VIEW_CHAIRID
	else
		return (id - self.m_nChairID + cmd.MY_VIEW_CHAIRID + cmd.GAME_PLAYER)%cmd.GAME_PLAYER
	end
end

function GameViewLayer:updateUserInfo(charID)
    local useritem = nil
    local viewID = 0
    if charID then
        useritem = self._scene._gameFrame:getTableUserItem(self.m_nTableID,charID)
        viewID = self:GetPlayViewStation(charID)
        if useritem then
            self:showPlayerInfo(viewID,useritem)
            if useritem.cbUserStatus == yl.US_READY then
                self:showZhunBei(viewID,true)
                print("准备", viewID)
            end
        else
            self:showPlayerInfo(viewID,nil,false)
            self.m_pPlayers[viewID]:removeUI()
             self:showZhunBei(viewID,false)
        end
        return
    end

    for i=1,cmd.GAME_PLAYER do
        useritem = self._scene._gameFrame:getTableUserItem(self.m_nTableID,i-1)
        viewID = self:GetPlayViewStation(i-1)
        if viewID ~= GameViewLayer.UiTag.eImageHeadBjMy then
            if useritem then
                self:showPlayerInfo(viewID,useritem)
                if useritem.cbUserStatus == yl.US_READY then
                    self:showZhunBei(viewID,true)
                    print("准备", viewID)
                end
            else
                self:showPlayerInfo(viewID,nil,false)
                self:showZhunBei(viewID,false)
            end
         else
            self:showPlayerInfo(cmd.MY_VIEW_CHAIRID,self.m_pUserItem_)
        end
    end	
end

-----------------------------------------------------------------------------------------------------
function GameViewLayer:setUserNickname(viewid, nickname)
    local qImagebj = self.resourceNode_:getChildByTag(viewid+10)
    if qImagebj == nil then
        return
    end

    qImagebj:setVisible(true)
    local pText = qImagebj:getChildByTag(GameViewLayer.TAG_NAME)
    if not pText then
        print("the user name is nil!!")
        return
    end

    local name = string.EllipsisByConfig(nickname, 107, string.getConfig("fonts/round_body.ttf", 20))
    pText:setString(name)
    --pText:setAnchorPoint(cc.p(0.5, 0.5))
    --pText:move(61, 52)

    --限制宽度
    -- local width = pText:getContentSize().width
    -- if width > 107 then
    --     pText:setScaleX(107/width)
    -- elseif pText:getScaleX() ~= 1 then
    --     pText:setScaleX(1)
    -- end
end


function GameViewLayer:setUserMoney(viewid,iMoney)
    local qImagebj = self.resourceNode_:getChildByTag(viewid+10)
    if qImagebj == nil then
        return
    end

    qImagebj:setVisible(true)
    pText = qImagebj:getChildByTag(GameViewLayer.TAG_MONEY)
    if not pText then
        print("the user money is nil!!")
        return
    end

    --iMoney = self._scene:convertMoneyToString(iMoney)
    pText:setString(iMoney)
    --pText:setAnchorPoint(cc.p(0.5, 0.5))
    --pText:move(68, 20)
    
    --限制宽度
    local fixedWidth = 85
    local textWidth = pText:getContentSize().width
    if textWidth > fixedWidth then
        pText:setScaleX(fixedWidth/textWidth)
    elseif pText:getScaleX() ~= 1 then
        pText:setScaleX(1)
    end
end

function GameViewLayer:showPlayerInfo(id,useritem,bShow)
    local qImagebj = self.resourceNode_:getChildByTag(id+10)
    if qImagebj == nil then
        return
    end

    if bShow == false then
        qImagebj:setVisible(false)
        self:showHead(qImagebj,nil,nil,true)
    elseif useritem then
        qImagebj:setVisible(true)
        self:showHead(qImagebj,useritem,id)

        self:setUserNickname(id, useritem.szNickName)
        self:setUserMoney(id, useritem.lScore)
    end
end

function GameViewLayer:showHead(pImage,userObj,viewid,bRemove)
    local pHeadImage = pImage:getChildByTag(GameViewLayer.TAG_HEAD)
    if bRemove then
        if pHeadImage then
            pHeadImage:removeFromParent()
            pHeadImage = nil
        end
        return
    end
    
    --以存在就不需要绘制
    if pHeadImage then
        return
    end

    pHeadImage = PopupInfoHead:createNormal(userObj, 90)
    pHeadImage:setAnchorPoint(display.CENTER)
	--pHeadImage:setPosition(cc.p(60.0,114.0))
    pHeadImage:setPosition(cc.p(0, 28))
	pImage:addChild(pHeadImage)
    pHeadImage:setTag(GameViewLayer.TAG_HEAD)
    local vPosX,vPosY = pImage:getPosition()
    vPosY = vPosY - 30.0
    if viewid == cmd.VIEW_MIDDLE_RIGHT then
        pHeadImage:enableInfoPop(true, cc.p(vPosX - 426,vPosY + 81),display.RIGHT_BOTTOM)
    elseif viewid == cmd.VIEW_MIDDLE_LEFFT then
        pHeadImage:enableInfoPop(true, cc.p(vPosX + 37,vPosY + 81),display.LEFT_BOTTOM)
    elseif viewid == cmd.VIEW_TOP_RIGHT then
        pHeadImage:enableInfoPop(true, cc.p(vPosX - 468,vPosY - 60),display.RIGHT_BOTTOM)
    elseif viewid == cmd.VIEW_TOP_MIDDLE then
        pHeadImage:enableInfoPop(true, cc.p(vPosX,vPosY - 321),display.LEFT_TOP)
    elseif viewid == cmd.VIEW_TOP_LEFFT then
        pHeadImage:enableInfoPop(true, cc.p(vPosX + 60,vPosY - 60))
    elseif viewid == cmd.MY_VIEW_CHAIRID then
        pHeadImage:enableInfoPop(true, cc.p(vPosX + 27,vPosY + 81))
    end
end

--显示庄家标志
function GameViewLayer:showZhuang(charID,show)
    local qImagebj = nil
    local qImageZhuang = nil
    for i=1,cmd.GAME_PLAYER do
        qImagebj = self.resourceNode_:getChildByTag(i-1+10)
        if qImagebj then
            qImageZhuang = qImagebj:getChildByTag(GameViewLayer.TAG_ZHUANG)
            if qImageZhuang then
                qImageZhuang:setVisible(false)
            end
        end
    end

    if show and charID then
        local allCharId = self._scene:getPlayStatues()
        if allCharId[charID+1] == 0 then
            print("showZhuang!!!!!!ERROR")
            return
        end
        local viewID = self:GetPlayViewStation(charID)
        qImagebj = self.resourceNode_:getChildByTag(viewID+10)
        if qImagebj then
            qImageZhuang = qImagebj:getChildByTag(GameViewLayer.TAG_ZHUANG)
            if qImageZhuang then
                qImageZhuang:setLocalZOrder(1)
                qImageZhuang:setVisible(show)
                print("showZhuang!!!!!!")
            end
        end
    end
end

function GameViewLayer:getCardTypeSprite(iValue,iType)
    local bOx = false 
    local pSprite1 = nil
    local pSprite2 = nil
    local cardRect
    local pTexture  = cc.Director:getInstance():getTextureCache():addImage(NGResources.GameRes.sCardTypePath)
    if iType == GameLogic.OX_FIVE_KING then
        cardRect = cc.rect(11*47.0,0,47.0,42.0);
	    pSprite1 = cc.Sprite:createWithTexture(pTexture,cardRect)

        cardRect = cc.rect(12*47.0,0,47.0,42.0);
	    pSprite2 = cc.Sprite:createWithTexture(pTexture,cardRect)
        bOx = true
    elseif iValue == 0 then
	    pSprite1 = cc.Sprite:createWithSpriteFrameName(NGResources.GameRes.sTypeWuNiu)
        bOx = false
    else
        cardRect = cc.rect(10*47.0,0,47.0,42.0);
	    pSprite1 = cc.Sprite:createWithTexture(pTexture,cardRect)

        cardRect = cc.rect(iValue*47.0,0,47.0,42.0);
	    pSprite2 = cc.Sprite:createWithTexture(pTexture,cardRect)
        bOx = true
    end

    return pSprite1,pSprite2,bOx
end

function GameViewLayer:showAdNiuK(bShow)
    local qImage = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eImageAdNiuK)
    if qImage == nil then
        return
    end
    if bShow == false then
        qImage:setVisible(false)
        return
    end

    local pLay = qImage:getChildByTag(10)
    local pText = nil
    local cUpCard = self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:GetShootCard(true) 
    local upCount = #cUpCard
    if upCount == 0 then
        qImage:setVisible(false)
        return
    end
    if upCount<3 then
        for i=upCount+1,3 do
            pText = qImage:getChildByTag(i)
            if pText then
                pText:setString("")
            end
        end

        for i=1,upCount do
            local value = GameLogic.GetCardLogicValue(cUpCard[i])
            pText = qImage:getChildByTag(i)
            if pText then
                pText:setString(tostring(value))
            end
        end

        if pLay then
            pLay:setVisible(false)
        end
    else
        if upCount>3 then
            upCount = 3
        end

        for i=1,upCount do
            local value = GameLogic.GetCardLogicValue(cUpCard[i])
            pText = qImage:getChildByTag(i)
            if pText then
                pText:setString(tostring(value))
            end
        end

        local cDown = self.m_pPlayers[cmd.MY_VIEW_CHAIRID]:GetShootCard(false) 
        for i,v in pairs(cDown) do
            table.insert(cUpCard,v)
        end
        local iType = GameLogic.GetCardType(cUpCard)
        local iValue = GameLogic.getOxValue(iType)

        local pSprite1,pSprite2,bOx = self:getCardTypeSprite(iValue,iType)
        if pLay then
            pLay:removeAllChildren()
            if pSprite1 and pSprite2 then
                local cSize = pSprite1:getContentSize()
                pSprite1:setPosition(cc.p(-19, 0))
                pSprite2:setPosition(cc.p(19, 0))
                pLay:addChild(pSprite1)
                pLay:addChild(pSprite2)
            elseif pSprite1 then
                pSprite1:setPosition(cc.p(0, 0))
                pLay:addChild(pSprite1)
            end
            pLay:setVisible(true)
        end
    end
    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/CLICK_CARD.wav")
    qImage:setVisible(true)
end

function GameViewLayer:showStudioChild(tag,bShow)
    local pNode = self.resourceNode_:getChildByTag(tag)
    if pNode then
        pNode:setVisible(bShow)
    end
end

function GameViewLayer:showZhunBei(viewId,bShow)
    local pLayer = self.resourceNode_:getChildByTag(GameViewLayer.UiTag.eLayerZhunBei)
    if pLayer == nil then
        return
    end

    local pImage = nil
    if viewId == nil then
        for i=1,cmd.GAME_PLAYER do
            pImage = pLayer:getChildByTag(i-1)
            if pImage then
                pImage:setVisible(false)
            end
        end
    else
        pImage = pLayer:getChildByTag(viewId)
        if pImage then
            pImage:setVisible(bShow == true)
        end
    end
end

function GameViewLayer:OnUpdataClockView(viewid,time)
    if self.m_pImageClock_ == nil or self.m_pTextClock_ == nil then
        return
    end
    if not viewid or not time or viewid == yl.INVALID_CHAIR then
		self.m_pImageClock_:setVisible(false)
		self.m_pTextClock_:setString("")
	else
		self.m_pImageClock_:setVisible(true)
		self.m_pTextClock_:setString(tostring(time))
	end
end

return GameViewLayer
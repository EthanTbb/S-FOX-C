--
-- Author: Tang
-- Date: 2016-08-08 17:26:37
--游戏交互层


local GameLayer = class("GameLayer", function(frameEngine,scene)
  --创建物理世界
      cc.Director:getInstance():getRunningScene():initWithPhysics()
      cc.Director:getInstance():getRunningScene():getPhysicsWorld():setGravity(cc.p(0,-100))
        local gameLayer = display.newLayer()
        return gameLayer
end)  

local TAG_ENUM = 
{
  Tag_Fish = 200
}

require("cocos.init")
local module_pre = "game.yule.fishlk.src"     
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")

local cmd = module_pre..".models.CMD_LKGame"
local game_cmd = appdf.CLIENT_SRC..".plaza.models.CMD_GameServer"
local g_var = ExternalFun.req_var
local GameFrame = module_pre..".models.GameFrame"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local GameViewLayer = module_pre..".views.layer.GameViewLayer"
local Fish = module_pre..".views.layer.Fish"
local CannonLayer = module_pre..".views.layer.CannonLayer"
local scheduler = cc.Director:getInstance():getScheduler()
function GameLayer:ctor( frameEngine,scene )

  self.m_infoList = {}
  self.m_scheduleUpdate = nil
  self.m_secondCountSchedule = nil
  self._scene = scene
  self.m_bScene = false
  self.m_bSynchronous = false
  self.m_nSecondCount = 60
  self.m_catchFishCount = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  self._gameFrame = frameEngine
  self._gameFrame:setKindInfo(cmd.KIND_ID,cmd.VERSION)
  self._roomRule = self._gameFrame._dwServerRule

  self._gameView = g_var(GameViewLayer):create(self)
  :addTo(self)

  self._dataModel = g_var(GameFrame):create()

  self.m_pUserItem = self._gameFrame:GetMeUserItem()
  self.m_nTableID  = self.m_pUserItem.wTableID
  self.m_nChairID  = self.m_pUserItem.wChairID  

  
  self:setReversal()

--鱼层
  self.m_fishLayer = cc.Layer:create()
  self._gameView:addChild(self.m_fishLayer, 5)

  if self._dataModel.m_reversal then
     self.m_fishLayer:setRotation(180)
  end
    
  --自己信息
  self._gameView:initUserInfo()

   --创建定时器
  self:onCreateSchedule()

  --60秒未开炮倒计时
  self:createSecoundSchedule()

   --注册事件
  ExternalFun.registerTouchEvent(self,true)

  --注册通知
  self:addEvent()

    --打开调试模式
--cc.Director:getInstance():getRunningScene():getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)
 
end

function GameLayer:addEvent()


   --通知监听
  local function eventListener(event)


    --初始化界面
    self._gameView:initView()

     --添加炮台层
    self.m_cannonLayer = g_var(CannonLayer):create(self)
    self._gameView:addChild(self.m_cannonLayer, 6)

    --查询本桌其他用户
    self._gameFrame:QueryUserInfo( self.m_nTableID,yl.INVALID_CHAIR)


       --播放背景音乐
    AudioEngine.playMusic(cc.FileUtils:getInstance():fullPathForFilename(g_var(cmd).Music_Back_1),true)

    if not GlobalUserItem.bVoiceAble then
        
        AudioEngine.setMusicVolume(0)
        AudioEngine.pauseMusic() -- 暂停音乐
    end

  end

  local listener = cc.EventListenerCustom:create(g_var(cmd).Event_LoadingFinish, eventListener)
  cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)

end

--判断自己位置 是否需翻转
function GameLayer:setReversal( )
   
  if self.m_pUserItem then
    if self.m_pUserItem.wChairID < 3 then
        self._dataModel.m_reversal = true
    end
  end

  return self._dataModel.m_reversal

end

--添加碰撞
function GameLayer:addContact()

    local function onContactBegin(contact)
    
        local a = contact:getShapeA():getBody():getNode()
        local b = contact:getShapeB():getBody():getNode()
       
        local bullet = nil

        if a and b then
          if a:getTag() == g_var(cmd).Tag_Bullet then
            bullet = a
          end

          if b:getTag() == g_var(cmd).Tag_Bullet then
            bullet = b
          end

        end
        if nil ~= bullet then
           bullet:fallingNet()
           bullet:removeFromParent()
        end

        return true
    end

    local dispatcher = self:getEventDispatcher()
    self.contactListener = cc.EventListenerPhysicsContact:create()
    self.contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    dispatcher:addEventListenerWithSceneGraphPriority(self.contactListener, self)

end

--60开炮倒计时
function GameLayer:setSecondCount(dt)
     self.m_nSecondCount = dt

     if dt == 60 then
       local tipBG = self._gameView:getChildByTag(10000)
       if nil ~= tipBG then
          tipBG:removeFromParent()
       end
     end
end


--创建定时器
function GameLayer:onCreateSchedule()
  local isBreak0 = false
  local isBreak1 = true


--鱼队列
  local function dealCanAddFish()

    if isBreak0 then
       isBreak1 = false
      return
    end

     if #self._dataModel.m_waitList >=5 then
       isBreak0 = true
       isBreak1 = false
       return
    end

    table.sort( self._dataModel.m_fishCreateList, function ( a ,b )
      return a.nProductTime < b.nProductTime
    end )

    local function isCanAddtoScene(data)

    
      local iscanadd = false

      local time = currentTime()
      if data.nProductTime <= time and data.nProductTime ~= 0  then

          iscanadd = true
          return iscanadd
      end

       return iscanadd
    end

    local texture = cc.Director:getInstance():getTextureCache():getTextureForKey("game_res/fish_move1.png")
    local texture1 = cc.Director:getInstance():getTextureCache():getTextureForKey("game_res/fish_move2.png")
    local anim = cc.AnimationCache:getInstance():getAnimation("animation_fish_move26")
    if not texture or not texture1 or not anim then
       return
    end

    if 0 ~= #self._dataModel.m_fishCreateList  then
      local fishdata = self._dataModel.m_fishCreateList[1]
      table.remove(self._dataModel.m_fishCreateList,1)
      local iscanadd = isCanAddtoScene(fishdata)
      if iscanadd then
          local fish =  g_var(Fish):create(fishdata,self)
          fish:initAnim()
          fish:setTag(g_var(cmd).Tag_Fish)
          fish:initWithState()
          fish:initPhysicsBody()
          self.m_fishLayer:addChild(fish, fish.m_data.nFishType + 1)
          self._dataModel.m_fishList[fish.m_data.nFishKey] = fish
        else
          table.insert(self._dataModel.m_waitList, fishdata)
      end
    end 
  end

--等待队列
  local function dealWaitList( )

      if isBreak1 then
        isBreak0 = false
        return
      end

      if  #self._dataModel.m_waitList == 0 then
         
          isBreak0 = false
          isBreak1 = true
          return
      end

      if  #self._dataModel.m_waitList ~= 0 then
       
          for i=1, #self._dataModel.m_waitList do
             local fishdata = self._dataModel.m_waitList[i]
             table.insert(self._dataModel.m_fishCreateList,1,fishdata)
          end

         self._dataModel.m_waitList = {}
      end
  end

--定位大鱼
local function selectMaxFish()

     --自动锁定
      if self._dataModel.m_autolock  then

           local fish = self._dataModel.m_fishList[self._dataModel.m_fishIndex]

           if nil == fish then
              self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
              return
           end

           local rect = cc.rect(0,0,yl.WIDTH,yl.HEIGHT)
           local pos = cc.p(fish:getPositionX(),fish:getPositionY()) 
          
           if  not cc.rectContainsPoint(rect,pos) then
               self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
      
           end
         
      end
end



local function update(dt)

--筛选大鱼
  selectMaxFish()

--能加入显示的鱼群
  dealCanAddFish()

--需等待的鱼群
  dealWaitList()

end

--游戏定时器
	if nil == self.m_scheduleUpdate then
		self.m_scheduleUpdate = scheduler:scheduleScriptFunc(update, 0, false)
	end

end


function GameLayer:createSecoundSchedule() 

  local function setSecondTips() --提示

    if nil == self._gameView:getChildByTag(10000) then 

      local tipBG = cc.Sprite:create("game_res/secondTip.png")
      tipBG:setPosition(667, 630)
      tipBG:setTag(10000)
      self._gameView:addChild(tipBG,100)


      local watch = cc.Sprite:createWithSpriteFrameName("watch_0.png")
      watch:setPosition(60, 45)
      tipBG:addChild(watch)

      local animation = cc.AnimationCache:getInstance():getAnimation("watchAnim")
      if nil ~= animation then
         watch:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
      end

      local time = cc.Label:createWithTTF(string.format("%d秒",self.m_nSecondCount), "fonts/round_body.ttf", 20)
      time:setTextColor(cc.YELLOW)
      time:setAnchorPoint(0.0,0.5)
      time:setPosition(117, 55)
      time:setTag(1)
      tipBG:addChild(time)

      local buttomTip = cc.Label:createWithTTF("60秒未开炮,即将退出游戏", "fonts/round_body.ttf", 20)
      buttomTip:setAnchorPoint(0.0,0.5)
      buttomTip:setPosition(117, 30)
      tipBG:addChild(buttomTip)

    else

         local tipBG = self._gameView:getChildByTag(10000)
         local time = tipBG:getChildByTag(1)
         time:setString(string.format("%d秒",self.m_nSecondCount))      
    end

  end

  local function removeTip()

    local tipBG = self._gameView:getChildByTag(10000)
    if nil ~= tipBG then
      tipBG:removeFromParent()
    end

  end


  local function update(dt)

    if self.m_nSecondCount == 0 then --发送起立
      removeTip()
      self:onKeyBack()
      return
    end

    if self.m_nSecondCount - 1 >= 0 then 
      self.m_nSecondCount = self.m_nSecondCount - 1
    end

    if self.m_nSecondCount <= 10 then
       setSecondTips()
    end

  end

  if nil == self.m_secondCountSchedule then
    self.m_secondCountSchedule = scheduler:scheduleScriptFunc(update, 1.0, false)
  end

end

function GameLayer:unSchedule( )

--游戏定时器
	if nil ~= self.m_scheduleUpdate then
		scheduler:unscheduleScriptEntry(self.m_scheduleUpdate)
		self.m_scheduleUpdate = nil
	end

  --60秒倒计时定时器
  if nil ~= self.m_secondCountSchedule then 
      scheduler:unscheduleScriptEntry(self.m_secondCountSchedule)
      self.m_secondCountSchedule = nil
  end
end

function GameLayer:onEnter( )
	
  print("onEnter of gameLayer")

end

function GameLayer:onEnterTransitionFinish(  )
 
  print("onEnterTransitionFinish of gameLayer")

  --AudioEngine.playMusic(g_var(cmd).Music_Back_1,true)

--碰撞监听
  self:addContact()

end

function GameLayer:onExit()

  print("gameLayer onExit()....")

  --移除碰撞监听
	cc.Director:getInstance():getEventDispatcher():removeEventListener(self.contactListener)

  cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(g_var(cmd).Event_LoadingFinish)
 
  --释放游戏所有定时器
  self:unSchedule()

end


--触摸事件
function GameLayer:onTouchBegan(touch, event)

	return true
end

function GameLayer:onTouchMoved(touch, event)

end

function GameLayer:onTouchEnded(touch, event )
	
end

--用户进入
function GameLayer:onEventUserEnter( wTableID,wChairID,useritem )
 
    if wTableID ~= self.m_nTableID or  useritem.cbUserStatus == yl.US_LOOKON or not self.m_cannonLayer then
      return
    end

    self.m_cannonLayer:onEventUserEnter( wTableID,wChairID,useritem )

    self:setUserMultiple()
end

--用户状态
function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)

  if  useritem.cbUserStatus == yl.US_LOOKON or not self.m_cannonLayer then
    return
  end


  self.m_cannonLayer:onEventUserStatus(useritem,newstatus,oldstatus)

  self:setUserMultiple()

end

--用户分数
function GameLayer:onEventUserScore( item )
    print("fishlk onEventUserScore...")
end

--显示等待
function GameLayer:showPopWait()
    if self._scene and self._scene.showPopWait then
        self._scene:showPopWait()
    end
end

--关闭等待
function GameLayer:dismissPopWait()
    if self._scene and self._scene.dismissPopWait then
        self._scene:dismissPopWait()
    end
end

-- 初始化游戏数据
function GameLayer:onInitData()

end

--退出询问
function GameLayer:onQueryExitGame()
    -- body
end


-- 重置游戏数据
function GameLayer:onResetData()
    -- body
end

function GameLayer:setUserMultiple()

    if not self.m_cannonLayer then
      return
    end

  --设置炮台倍数
     for i=1,6 do
       local cannon = self.m_cannonLayer:getCannoByPos(i)
       local pos = i
       if nil ~= cannon then

          if self._dataModel.m_reversal then 
            pos = 6+1-i
          end

          if not  self._dataModel.m_secene.nMultipleIndex then
            return
          end

          cannon:setMultiple(self._dataModel.m_secene.nMultipleIndex[1][pos])
       end
     end
end

-- 场景信息

function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)

  print("场景数据")

   if self.m_bScene then
      self:dismissPopWait()
      return
    end

    self.m_bScene = true
  	local systime = currentTime()
    self._dataModel.m_enterTime = systime

    self._dataModel.m_secene = ExternalFun.read_netdata(g_var(cmd).GameScene,dataBuffer)

    if self._dataModel.m_secene.cbBackIndex ~= 0 then
     	  self._gameView:updteBackGround(self._dataModel.m_secene.cbBackIndex)
    end

    self._gameView:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][1])

    self:setUserMultiple(multiple)
      
    self:dismissPopWait()
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)

  if self.m_bLeaveGame or nil == self._gameView  then
	    return
  end 

  if sub == g_var(cmd).SUB_S_SYNCHRONOUS and not self.m_bSynchronous then
  	--同步信息
  	self:onSubSynchronous(dataBuffer)

  elseif sub == g_var(cmd).SUB_S_FISH_CREATE then
  	if math.mod(dataBuffer:getlen(),577) == 0 then --576 sizeof(CMD_S_FishCreate)
        --通知
      local event = cc.EventCustom:new(g_var(cmd).Event_FishCreate)
      cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
      
  		--鱼创建
  		self:onSubFishCreate(dataBuffer)
  	end

  elseif sub == g_var(cmd).SUB_S_FISH_CATCH	then --捕获鱼
    self:onSubFishCatch(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_EXCHANGE_SCENE then --切换场景
    self:onSubExchangeScene(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_FIRE then  --开炮
    self:onSubFire(dataBuffer)
   elseif sub == g_var(cmd).SUB_S_SUPPLY then --补给
    self:onSubSupply(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_STAY_FISH then --停留鱼
    self:onSubStayFish(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_UPDATE_GAME then
    self:onSubUpdateGame(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_MULTIPLE then  --倍数
    self:onSubMultiple(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_SUPPLY_TIP then --补给提示
    self:onSubSupplyTip(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_AWARD_TIP then  --获取奖励提示
    self:onSubAwardTip(dataBuffer)
  end
end



function GameLayer:onSubAwardTip( databuffer )
  local award = ExternalFun.read_netdata(g_var(cmd).CMD_S_AwardTip,databuffer)
  --dump(award, "award is =================================", 6)
  local mutiple = award.nFishMultiple

  if mutiple>=50 or (award.nFishType==19 and award.nScoreType==g_var(cmd).SupplyType.EST_Cold and award.wChairID==self.m_nChairID) then
    self._gameView:ShowAwardTip(award)
  end
end

function GameLayer:onSubSupplyTip(databuffer)

    if not self.m_cannonLayer then
      return
    end
   
     local tip = ExternalFun.read_netdata(g_var(cmd).CMD_S_SupplyTip,databuffer)

     local tipStr = ""
     if tip.wChairID == self.m_nChairID then
       tipStr = "获得一个补给箱！击中可能获得大量奖励哟！赶快击杀！"
      else
         local cannonPos = tip.wChairID
         if self._dataModel.m_reversal then 
           cannonPos = 5 - cannonPos
         end

         local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
         local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)
         local userItem = self._gameFrame._UserList[userid]

         if not userItem then
            return
         end
         tipStr = userItem.szNickName .." 获得了一个补给箱！羡慕吧，继续努力，你也可能得到！"
     end

     self._gameView:Showtips(tipStr)
end

function GameLayer:onSubMultiple( databuffer )

    local mutiple = ExternalFun.read_netdata(g_var(cmd).CMD_S_Multiple,databuffer)
    local cannonPos = mutiple.wChairID
    if self._dataModel.m_reversal then 
         cannonPos = 5 - cannonPos
    end
 
   if nil ~= self.m_cannonLayer then
      local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)

      if nil == cannon then
        return
      end

      cannon:setMultiple(mutiple.nMultipleIndex)
   end
 
    self._dataModel.m_secene.nMultipleIndex[1][mutiple.wChairID + 1] = mutiple.nMultipleIndex

    if mutiple.wChairID == self.m_nChairID then 
      self._gameView:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][mutiple.nMultipleIndex+1])
    end

end

function GameLayer:onSubUpdateGame( databuffer )
  local update = ExternalFun.read_netdata(g_var(cmd).CMD_S_UpdateGame,databuffer)
  self._dataModel.m_secene.nBulletVelocity = update.nBulletVelocity
  self._dataModel.m_secene.nBulletCoolingTime = update.nBulletCoolingTime
  self._dataModel.m_secene.nFishMultiple = update.nFishMultiple
  self._dataModel.m_secene.nMultipleValue = update.nMultipleValue
end

function GameLayer:onSubStayFish( databuffer )

  local stay = ExternalFun.read_netdata(g_var(cmd).CMD_S_StayFish,databuffer)

  local fish = self._dataModel.m_fishList[stay.nFishKey]
  if nil ~= fish then
      fish:Stay(stay.nStayTime)
  end

  
end
function GameLayer:onSubSupply(databuffer )
  
  if not self.m_cannonLayer then
    return
  end

  local supply =  ExternalFun.read_netdata(g_var(cmd).CMD_S_Supply,databuffer)

  local cannonPos = supply.wChairID
  if self._dataModel.m_reversal then 
       cannonPos = 5 - cannonPos
  end

  local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
  if not  cannon then
     return
  end
  cannon:ShowSupply(supply)

  local tipStr = nil

   local cannonPos = supply.wChairID
   if self._dataModel.m_reversal then 
     cannonPos = 5 - cannonPos
   end

   local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
   local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)
   local userItem = self._gameFrame._UserList[userid]

 

  if supply.nSupplyType == g_var(cmd).SupplyType.EST_Laser then
     if supply.wChairID == self.m_nChairID then
       tipStr = self.m_pUserItem.szNickName.."击中补给箱打出了激光！秒杀利器！赶快使用！"
    else
       tipStr = userItem.szNickName .." 击中补给箱打出了激光！秒杀利器!"
    end

  elseif supply.nSupplyType == g_var(cmd).SupplyType.EST_Laser then
    
      tipStr = userItem.szNickName.." 击中补给箱打出了加速！所有子弹速度翻倍！"
  elseif supply.nSupplyType == g_var(cmd).SupplyType.EST_Null then
   
      tipStr = "很遗憾！补给箱里面什么都没有！"

      self._dataModel:playEffect(g_var(cmd).SmashFail)

  end

  if nil ~= tipStr then 
    self._gameView:Showtips(tipStr)
  end

end

--同步时间
function GameLayer:onSubSynchronous( databuffer )
	  print("同步时间")
    self.m_bSynchronous = true
	  local synchronous = ExternalFun.read_netdata(g_var(cmd).CMD_S_FishFinish,databuffer)
	  if 0 ~= synchronous.nOffSetTime then
       print("同步时间1")
	  	 local offtime = synchronous.nOffSetTime
	  	 self._dataModel.m_enterTime = self._dataModel.m_enterTime - offtime
	  end

end

--创建鱼
function GameLayer:onSubFishCreate( dataBuffer )
  	 print("鱼创建")

    local fishNum = math.floor(dataBuffer:getlen()/577)
    if fishNum >= 1 then
    	for i=1,fishNum do
       
    	  local FishCreate =   ExternalFun.read_netdata(g_var(cmd).CMD_S_FishCreate,dataBuffer)
    
         local function dealproducttime ()
            local entertime = self._dataModel.m_enterTime
            local productTime = entertime + FishCreate.unCreateTime
            return productTime 
         end

         FishCreate.nProductTime = dealproducttime()

         table.insert(self._dataModel.m_fishCreateList, FishCreate)

         if FishCreate.nFishType == g_var(cmd).FishType.FishType_ShuangTouQiEn or FishCreate.nFishType == g_var(cmd).FishType.FishType_JinLong or FishCreate.nFishType == g_var(cmd).FishType.FishType_LiKui then
            local tips 

            if FishCreate.nFishType == g_var(cmd).FishType.FishType_ShuangTouQiEn then
                tips = "双头企鹅"
            elseif FishCreate.nFishType == g_var(cmd).FishType.FishType_JinLong then
                tips = "金龙"
            else
                tips = "李逵"
            end

            tips = tips.."即将出现,请玩家做好准备!!!"

            self._gameView:Showtips(tips)
         end
    	end
    end
end

--切换场景
function GameLayer:onSubExchangeScene( dataBuffer )

    print("场景切换")

    self._dataModel:playEffect(g_var(cmd).Change_Scene)
    local systime = currentTime()
    self._dataModel.m_enterTime = systime

    self._dataModel._exchangeSceneing = true

    local exchangeScene = ExternalFun.read_netdata(g_var(cmd).CMD_S_ChangeSecene,dataBuffer)
    self._gameView:updteBackGround(exchangeScene.cbBackIndex)

    local callfunc = cc.CallFunc:create(function()
        self._dataModel._exchangeSceneing = false
    end)

    self:runAction(cc.Sequence:create(cc.DelayTime:create(8.0),callfunc))

end

function GameLayer:onSubFire(databuffer)
  
  if not self.m_cannonLayer  then
    return
  end

  local fire =  ExternalFun.read_netdata(g_var(cmd).CMD_S_Fire,databuffer)
  if fire.wChairID == self.m_nChairID then
    return
  end
 
 local cannonPos = fire.wChairID
 if self._dataModel.m_reversal then 
   cannonPos = 5 - cannonPos
 end

 local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
 if nil ~= cannon then
    cannon:othershoot(fire)
 end
end

function GameLayer:onSubFishCatch( databuffer )
  
  --print("捕捉鱼...........................................")

    if not self.m_cannonLayer  then
      return
    end

    local catchNum = math.floor(databuffer:getlen()/18)

    if catchNum >= 1 then
        for i=1,catchNum do
           local catchData = ExternalFun.read_netdata(g_var(cmd).CMD_S_CatchFish,databuffer)
           local fish = self._dataModel.m_fishList[catchData.nFishIndex]

           if nil ~= fish then

             if fish.m_data.nFishType == g_var(cmd).FishType.FishType_ShuiHuZhuan then
                
                if #self._dataModel.m_fishCreateList > 0 then

                  for k,v in pairs(self._dataModel.m_fishCreateList) do
                    local fishdata = v
                    fishdata.nProductTime = fishdata.nProductTime + 5000
                  end

                end
                
                 if #self._dataModel.m_waitList > 0 then

                    for k,v in pairs(self._dataModel.m_waitList) do
                      local fishdata = v
                      fishdata.nProductTime = fishdata.nProductTime + 5000
                    end

                 end
             end

             if fish.m_data.nFishType == g_var(cmd).FishType.FishType_BaoXiang then
                local nFishKey = fish.m_data.nFishKey
                fish:removeFromParent()
                self._dataModel.m_fishList[nFishKey] = nil

                return
  
             end

             local random = math.random(5)
             local smallSound = string.format("sound_res/samll_%d.wav", random)  
             local bigSound = string.format("sound_res/big_%d.wav", fish.m_data.nFishType)

             if fish.m_data.nFishType <  g_var(cmd).FISH_KING_MAX then
                self._dataModel:playEffect(smallSound)
             else
                self._dataModel:playEffect(bigSound)
             end

             local fishPos = cc.p(fish:getPositionX(),fish:getPositionY())
  
             if self._dataModel.m_reversal then 
               fishPos = cc.p(yl.WIDTH-fishPos.x,yl.HEIGHT-fishPos.y)
             end
  
  
             if fish.m_data.nFishType > g_var(cmd).FishType.FishType_JianYu then
               self._dataModel:playEffect(g_var(cmd).CoinLightMove)
               local praticle = cc.ParticleSystemQuad:create("game_res/particles_test2.plist")
               praticle:setPosition(fishPos)
               praticle:setPositionType(cc.POSITION_TYPE_GROUPED)
               self:addChild(praticle,3)
             end

             local fishtype = fish.m_data.nFishType

             --鱼死亡处理
             fish:deadDeal()

             --金币动画
             local call = cc.CallFunc:create(function(  )
               self._gameView:ShowCoin(catchData.lScoreCount, catchData.wChairID, fishPos, fishtype)
             end)

             self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0),call))

             --获取炮台视图位置
             local cannonPos = catchData.wChairID
             if self._dataModel.m_reversal then 
                cannonPos = 5 - cannonPos
             end

             if catchData.wChairID == self.m_nChairID then   --自己

                 GlobalUserItem.lUserScore = GlobalUserItem.lUserScore + catchData.lScoreCount
         
                  --更新用户分数
                  self.m_cannonLayer:updateUserScore( GlobalUserItem.lUserScore,cannonPos+1 )

                  --捕获鱼收获
                  self._dataModel.m_getFishScore = self._dataModel.m_getFishScore + catchData.lScoreCount
                
                  --捕鱼数量
                  if fishtype <= 21 then 
                    self.m_catchFishCount[fishtype+1] = self.m_catchFishCount[fishtype+1] + 1
                  end
              else    --其他玩家
                
                  --获取用户
                  local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)

                  for k,v in pairs(self.m_cannonLayer._userList) do
                    local item = v
                    if item.dwUserID == userid  then
                        item.lScore = item.lScore + catchData.lScoreCount

                        --更新用户分数
                         self.m_cannonLayer:updateUserScore( item.lScore,cannonPos+1 )

                        break
                    end
                  end
             end
           end
        end
      end
end

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

function GameLayer:onExitTable()
     self._scene:onKeyBack()
end

function  GameLayer:onKeyBack()
    self._gameView:StopLoading(false)
    self._gameFrame:StandUp(1)
    return true
end


function GameLayer:getDataMgr( )
    return self._dataModel;
end

function GameLayer:sendNetData( cmddata )
    return self._gameFrame:sendSocketData(cmddata);
end

return GameLayer
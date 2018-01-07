


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
local module_pre = "game.yule.fishry.src"     
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")

local cmd = module_pre..".models.CMD_RYGame"
local game_cmd = appdf.CLIENT_SRC..".plaza.models.CMD_GameServer"
local g_var = ExternalFun.req_var
local GameFrame = module_pre..".models.GameFrame"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local GameViewLayer = module_pre..".views.layer.GameViewLayer"
local Fish = module_pre..".views.layer.Fish"
local PhysicsTest = module_pre..".views.layer.PhysicsTest"
local CannonLayer = module_pre..".views.layer.CannonLayer"
local PRELOAD = require(module_pre..".views.layer.PreLoading") 
local scheduler = cc.Director:getInstance():getScheduler()
function GameLayer:ctor( frameEngine,scene )

  self.cannonLayerZorder = 6
  self.fishLayerZorder = 5
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
  self.m_bLeaveGame = false

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
            if  bullet.m_bbullet and  bullet.m_bbullet.fallingNet then
                   bullet.m_bbullet:fallingNet()
            end
            bullet:fallingNet()
            if nil ~= bullet.m_bbullet and  bullet.m_bbullet.fallingNet then
                  bullet.m_bbullet:removeFromParent()
             end
           bullet:removeFromParent()
        end

        return true
    end

    local dispatcher = self:getEventDispatcher()
    self.contactListener = cc.EventListenerPhysicsContact:create()
    self.contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    dispatcher:addEventListenerWithSceneGraphPriority(self.contactListener, self)

end

function GameLayer:setSecondCount(dt)
     self.m_nSecondCount = dt

     if dt == 60 then
       local tipBG = self._gameView:getChildByTag(10000)
       if nil ~= tipBG then
          tipBG:removeFromParent()
       end
     end
end

function GameLayer:onCreateSchedule()
  local isBreak0 = false
  local isBreak1 = true


--鱼队列
  local function dealCanAddFish()
    --[[
    if isBreak0 then
       isBreak1 = false
      return
    end

     if #self._dataModel.m_waitList >=5 then
       isBreak0 = true
       isBreak1 = false
       return
    end
    --]]
    table.sort( self._dataModel.m_waitList, function ( a ,b )
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
    local removeList = {}

    for i = 1, #self._dataModel.m_waitList do
      local fishdata = self._dataModel.m_waitList[i]
      
      local iscanadd = isCanAddtoScene(fishdata)
      if iscanadd then
          table.insert(removeList,i)
          local fish =  g_var(Fish):create(fishdata,self)
          self.m_fishLayer:addChild(fish, fish.m_data.nFishType + 1)
          fish:initAnim()
          fish:setTag(g_var(cmd).Tag_Fish)
          fish:initWithState()
          fish:initPhysicsBody()
          self._dataModel.m_fishList[fish.m_data.nFishKey] = fish
      end
    end
    for i = 1, #removeList do
      table.remove(self._dataModel.m_waitList,removeList[i])
    end
    
    --[[
    if 0 ~= #self._dataModel.m_waitList then
      local fishdata = self._dataModel.m_waitList[1]
      table.remove(self._dataModel.m_waitList,1)
      local iscanadd = isCanAddtoScene(fishdata)
      if iscanadd then
          local fish =  g_var(Fish):create(fishdata,self)
          self.m_fishLayer:addChild(fish, fish.m_data.nFishType + 1)
          fish:initAnim()
          fish:setTag(g_var(cmd).Tag_Fish)
          fish:initWithState()
          fish:initPhysicsBody()
          self._dataModel.m_fishList[fish.m_data.nFishKey] = fish
        --else
          --table.insert(self._dataModel.m_waitList, fishdata)
      end
    end 
    --]]
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

           if nil ~= fish  and true == fish.m_bRemove then
              self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
              return
           end

           if nil ~= fish.m_data then 
              --print("selectMaxFish fishIndex ",fish.m_data.nFishKey)
           end

            local rect = cc.rect(0,0,yl.WIDTH,yl.HEIGHT)
            if false == fish.m_bRemove then
              local pos = cc.p(fish:getPositionX(),fish:getPositionY()) 
          
              if  not cc.rectContainsPoint(rect,pos) then
                  self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
              end
            else
              self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
            end
           
         
      end
end



local function update(dt)

if(false == PRELOAD.bLoadingFinish) then
  return 
end
--筛选大鱼
  selectMaxFish()

--能加入显示的鱼群
  dealCanAddFish()

--需等待的鱼群
  --dealWaitList()

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

      local animation = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).watchAnim)
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
  self.m_bLeaveGame = false
end

function GameLayer:onEnterTransitionFinish(  )
 
  print("onEnterTransitionFinish of gameLayer")

  --AudioEngine.playMusic(g_var(cmd).Music_Back_1,true)

--碰撞监听
  self:addContact()

end

function GameLayer:onExit()

  print("gameLayer onExit()....")
  self.m_bLeaveGame = true
  --移除碰撞监听
	cc.Director:getInstance():getEventDispatcher():removeEventListener(self.contactListener)

  cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(g_var(cmd).Event_LoadingFinish)
 
  --释放游戏所有定时器
  self:unSchedule()

end

--初始化游戏数据
--function GameLayer:OnResetGameEngine()
function GameLayer:OnResetGameEngine1()

  print("OnInitGameEngine")
  self._gameFrame.m_waitList = nil
  local temList = {}
  for k,v in pairs (self._dataModel.m_fishList)  do
    table.insert(temList,v)   
  end

  
  for i = 1,#self._dataModel.m_fishList do
    local fish = temList[i]
    fish:removeFromParent();
  end
  self._dataModel.m_fishList = {}

  for i = 1,g_var(cmd).GAME_PLAYER do
    if i ~= self.m_nChairID then 
      self.m_cannonLayer:HiddenCannonByChair(i)
    end
    
    local cannon = self.m_cannonLayer:getCannoByPos(i)
    local bulletList = cannon.m_firelist
    cannon.m_firelist = {}
    for j = 1,#bulletList do
      local bullet = bulletList[j]
      bullet:removeFromParent();
    end
  end
  GameLayer.super.OnResetGameEngine(self)
end

  --self.m_cannonLayer

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
end

--用户状态
function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)

  if  useritem.cbUserStatus == yl.US_LOOKON or not self.m_cannonLayer then
    return
  end
    self.m_cannonLayer:onEventUserStatus(useritem,newstatus,oldstatus)

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


-- 场景信息

function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)

  print("场景数据长度")
  local nLength = dataBuffer:getlen()
    print(nLength)
   if self.m_bScene then
      self:dismissPopWait()
      return
    end

    self.m_bScene = true
  	local systime = currentTime()
    self._dataModel.m_enterTime = systime

    --辅助读取int64
    local int64 = Integer64.new()
    self._dataModel.m_secene = ExternalFun.read_netdata(g_var(cmd).GameScene,dataBuffer)

     if self._dataModel.m_secene.cbBackIndex ~= 0 then
     	  self._gameView:updteBackGround(self._dataModel.m_secene.cbBackIndex)
     end

      self._gameView:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][self._dataModel.m_secene.nMultipleIndex+1])
      self:dismissPopWait()
      --[[
     for i=1,6 do
       local cannon = self.m_cannonLayer:getCannoByPos(i)
       local pos = i

       if nil ~= cannon then

          if self._dataModel.m_reversal then 
            pos = 6+1-i
          end
          
          cannon:setMultiple(self._dataModel.m_secene.nMultipleIndex)
          cannon:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][self._dataModel.m_secene.nMultipleIndex + 1])
          print(string.format("cannon %d", pos))
       end
     end

    
    --]]
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)
  --[[
      if true then
        return
      end
      ]]--
  if self.m_bLeaveGame or nil == self._gameView  then
	    return
  end 

  if sub == g_var(cmd).SUB_S_SYNCHRONOUS and not self.m_bSynchronous then
  	--同步信息
    print("同步信息")
  	self:onSubSynchronous(dataBuffer)

  elseif sub == g_var(cmd).SUB_S_FISH_CREATE then
    local nLength = dataBuffer:getlen()
    local modValue = math.mod(nLength,710)
  	if math.mod(dataBuffer:getlen(),710) == 0 then --710 sizeof(CMD_S_FishCreate)
      local event = cc.EventCustom:new(g_var(cmd).Event_FishCreate)
      cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
  		--鱼创建
  		self:onSubFishCreate(dataBuffer)
  	end
    elseif sub == g_var(cmd).SUB_S_FISH_FINISH then
      self:onSubFishFinish(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_FISH_CATCH	and true == PRELOAD.bLoadingFinish then
  --捕获鱼
    self:onSubFishCatch(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_EXCHANGE_SCENE then --切换场景
    self:onSubExchangeScene(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_FIRE and true == PRELOAD.bLoadingFinish then  --开炮
    self:onSubFire(dataBuffer)
   elseif sub == g_var(cmd).SUB_S_SUPPLY  and true == PRELOAD.bLoadingFinish then --补给
    self:onSubSupply(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_UPDATE_GAME then
    self:onSubUpdateGame(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_MULTIPLE then  --倍数
    self:onSubMultiple(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_SUPPLY_TIP  and true == PRELOAD.bLoadingFinish then --补给提示
    self:onSubSupplyTip(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_AWARD_TIP and true == PRELOAD.bLoadingFinish then  --获取奖励提示
    self:onSubAwardTip(dataBuffer)
  elseif sub == g_var(cmd).SUB_S_BANK_TAKE and true == PRELOAD.bLoadingFinish and false == self.m_bLeaveGame then  --银行操作
    self:onSubBankTake(dataBuffer)
  end
end

function GameLayer:onSubAwardTip( databuffer )
  local award = ExternalFun.read_netdata(g_var(cmd).CMD_S_AwardTip,databuffer)
  --dump(award, "award is =================================", 6)
  local mutiple = award.nFishMultiple

  if mutiple>=50 or (award.nFishType==19 and award.nScoreType==g_var(cmd).EST_Cold and award.wChairID==self.m_nChairID) then
    self._gameView:ShowAwardTip(award)
  end
end

function GameLayer:onSubBankTake(databuffer)
  local take = ExternalFun.read_netdata(g_var(cmd).CMD_S_BankTake,databuffer)
  self._dataModel.m_secene.lPlayCurScore[1][take.wChairID + 1] = self._dataModel.m_secene.lPlayCurScore[1][take.wChairID + 1] + take.lPlayScore

  local cannonPos = take.wChairID
  
  if self._dataModel.m_reversal then 
       cannonPos = 5 - cannonPos
  end
  local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
  if not  cannon then
     return
    end
    
  self.m_cannonLayer:updateUserScore( self._dataModel.m_secene.lPlayCurScore[1][take.wChairID + 1],cannonPos+1 )
  if take.wChairID == self.m_nChairID then
    GlobalUserItem.lUserScore = self._dataModel.m_secene.lPlayCurScore[1][take.wChairID + 1]
    if nil ~= self._gameView and false == self.m_bLeaveGame then
      self._gameView:refreshScore()
    end
    
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

  --dump( self._dataModel.m_secene, "the scene data is =================== >  ", 6)
  --dump( self._dataModel.m_secene.nMultipleValue, "the scene data is =================== >  ", 6)
  
  --dump( self._dataModel.m_secene.enumScoreType, "the scene enumScoreType is =================== >  ", 6)

  local mutiple = ExternalFun.read_netdata(g_var(cmd).CMD_S_Multiple,databuffer)
  local cannonPos = mutiple.wChairID
  print(string.format("切换炮台 %d 分数 %d 位置%d", mutiple.nMultipleIndex, self._dataModel.m_secene.nMultipleValue[1][mutiple.nMultipleIndex+1], cannonPos))
  
  if self._dataModel.m_reversal then 
       cannonPos = 5 - cannonPos
  end
  local cannon = nil
   if nil ~= self.m_cannonLayer then
      cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
    end
  if nil == cannon then
    return
  end
  if mutiple.wChairID ~= self.m_nChairID then 
    cannon:setMultiple(mutiple.nMultipleIndex)
  end
  --print("mymultiple is =========================================================================>"..self._dataModel.m_secene.nMultipleValue[1][mutiple.nMultipleIndex+1])

  --self._dataModel.m_secene.nMultipleValue[1][mutiple.wChairID + 1] = mutiple.nMultipleIndex
  --[[
  if mutiple.wChairID == self.m_nChairID then 
    self._gameView:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][mutiple.nMultipleIndex+1])
  end
  --]]
end

function GameLayer:onSubUpdateGame( databuffer )
  local update = ExternalFun.read_netdata(g_var(cmd).CMD_S_UpdateGame,databuffer)
  self._dataModel.m_secene.nBulletVelocity = update.nBulletVelocity
  self._dataModel.m_secene.nBulletCoolingTime = update.nBulletCoolingTime
  self._dataModel.m_secene.nFishMultiple = update.nFishMultiple
  self._dataModel.m_secene.nMultipleValue = update.nMultipleValue
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

 

  if supply.nSupplyType == g_var(cmd).EST_Laser then
     if supply.wChairID == self.m_nChairID then
       tipStr = self.m_pUserItem.szNickName.."击中补给箱打出了激光！秒杀利器！赶快使用！"
    else
       tipStr = userItem.szNickName .." 击中补给箱打出了激光！秒杀利器!"
    end

  elseif supply.nSupplyType == g_var(cmd).EST_Laser then
    
      tipStr = userItem.szNickName.." 击中补给箱打出了加速！所有子弹速度翻倍！"
  elseif supply.nSupplyType == g_var(cmd).EST_Null then
   
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
      local systime = currentTime()
    self._dataModel.m_enterTime = systime
    self.m_bSynchronous = true
end

--创建鱼
function GameLayer:onSubFishCreate( dataBuffer )
  	 print("鱼创建 长度 %d",dataBuffer:getlen())

    local fishNum = math.floor(dataBuffer:getlen()/710)
    if fishNum >= 1 then
    	for i=1,fishNum do
       
    	  local FishCreate =   ExternalFun.read_netdata(g_var(cmd).CMD_S_FishCreate,dataBuffer)
         FishCreate.nProductTime = 0
         table.insert(self._dataModel.m_waitList, FishCreate)

         if FishCreate.nFishType == g_var(cmd).FISH_YIN_JING or FishCreate.nFishType == g_var(cmd).FISH_JIN_JING or FishCreate.nFishType == g_var(cmd).FISH_MEI_REN_YU then
            local tips 

            if FishCreate.nFishType == g_var(cmd).FISH_YIN_JING then
                tips = "银鲸"
            elseif FishCreate.nFishType == g_var(cmd).FISH_JIN_JING then
                tips = "金鲸"
            else
                tips = "美人鱼"
            end

            tips = tips.."即将出现,请玩家做好准备!!!"

            self._gameView:Showtips(tips)
         end
    	end
    end
end

function GameLayer:onSubFishFinish(dataBuffer)
local FishFinish =   ExternalFun.read_netdata(g_var(cmd).CMD_S_FishFinish,dataBuffer)
local  nOffSetTime = FishFinish.nOffSetTime
local time = self._dataModel.m_enterTime
self._dataModel.m_enterTime = time - nOffSetTime
    for k,v in pairs (self._dataModel.m_waitList) do
      self._dataModel.m_waitList[k].nProductTime = self._dataModel.m_enterTime + self._dataModel.m_waitList[k].unCreateTime + self._dataModel.m_waitList[k].unCreateDelay

    end
end

--切换场景
function GameLayer:onSubExchangeScene( dataBuffer )

    print("场景切换")

    self._dataModel:playEffect(g_var(cmd).Change_Scene)
    local systime = currentTime()
    self._dataModel.m_enterTime = systime

    self._dataModel._exchangeSceneing = true

   local exchangeScene = ExternalFun.read_netdata(g_var(cmd).CMD_S_ExchangeScene,dataBuffer)
    self._gameView:updteBackGround(exchangeScene.cbBackIndex)

    local callfunc = cc.CallFunc:create(function()
        self._dataModel._exchangeSceneing = false
    end)

    self:runAction(cc.Sequence:create(cc.DelayTime:create(5.0),callfunc))

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
  
  
      local catchNum = math.floor(databuffer:getlen()/18)
      local showLight = false
      if catchNum >= 1 then
        for i=1,catchNum do
           local catchData = ExternalFun.read_netdata(g_var(cmd).CMD_S_CatchFish,databuffer)
           local scoreType = catchData.nScoreType
           local fish = self._dataModel.m_fishList[catchData.nFishIndex]
           if nil ~= fish and nil ~= fish.m_data then
            local fishKey = fish.m_data.nFishKey
            --print("捕捉鱼.................................fishKey ", fish.m_data.nFishKey )
            fish.m_bRemove = true
            local fishtype = fish.m_data.nFishType
            local scoretype = fish.m_data.nScoreType
            local position = cc.p(fish:getPositionX(),fish:getPositionY())
            if fish.m_data.bKiller and false == showLight then
              showLight = true
              self._gameView:showLight(fish.m_data.nFishType,fish.m_data.nFishIndex)
            end

            if fish.m_data.bSpecial then
              self._dataModel:playEffect(g_var(cmd).CoinLightMove)
            end

            if fish.m_data.nFishType ==  g_var(cmd).FISH_XIANG_ZI then
              fish.m_bRemove = true
              self._dataModel.m_fishList[fish.m_data.nFishKey] = nil
              table.remove(self._dataModel.m_fishList, fish.m_data.nFishKey)
              fish:removeFromParent()
              return
            end
            math.randomseed(os.time())
              
            if fish.m_data.nFishType ==  g_var(cmd).FISH_KING_MAX then
              local value = math.random(0,5)
              self._dataModel:playEffect(string.format("sound_res/small_%d.wav", value))

            elseif fish.m_data.nFishType ==  g_var(cmd).FISH_MEI_REN_YU then
              local value = math.random(0,3)
              self._dataModel:playEffect(string.format("sound_res/beauty_%d.wav", value))

            else
              self._dataModel:playEffect(string.format("sound_res/beauty_%d.wav", fish.m_data.nFishType))
            end

            if self._dataModel.m_reversal then
              position = cc.p(yl.WIDTH - fish:getPositionX(), yl.HEIGHT - fish:getPositionY())
            end

            if fish.m_data.bSpecial then
              local funcaction = cc.CallFunc:create(function()
                local particleSystem = cc.ParticleSystemQuad:create("game_res/particles_test1.plist")
                particleSystem:setPosition(position)
                particleSystem:setPositionType(cc.POSITION_TYPE_GROUPED)
                self:addChild(particleSystem,3)
        end)
              self:runAction(cc.Sequence:create(funcaction, cc.DelayTime:create(0.2), funcaction, cc.DelayTime:create(0.25) ,funcaction))
            end

            if fish.m_data.nFishType > 13 then
              local particleSystem = cc.ParticleSystemQuad:create("game_res/particles_test2.plist")
                particleSystem:setPosition(position)
                particleSystem:setPositionType(cc.POSITION_TYPE_GROUPED)
                self:addChild(particleSystem,2)
            end
            fish.m_bRemove = true
             fish:deadDeal()
             --金币动画
             local call = cc.CallFunc:create(function(  )
               self._gameView:ShowCoin(catchData.lScoreCount, catchData.wChairID, position, fishtype, scoretype)
             end)
             self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0),call))
             if catchData.wChairID == self.m_nChairID then
            --捕鱼数量
                  if fishtype <= 21 then 
                    self.m_catchFishCount[fishtype+1] = self.m_catchFishCount[fishtype+1] + 1
                  end
             end
          else


           end

            --获取炮台视图位置
             local cannonPos = catchData.wChairID
             if self._dataModel.m_reversal then 
                cannonPos = 5 - cannonPos
             end
             local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)

           if catchData.wChairID == self.m_nChairID then   --自己

                if scoreType == g_var(cmd).EST_YuanBao then
                  GlobalUserItem.lIngot = GlobalUserItem.lUserIngot + catchData.lScoreCount
                  if nil == cannon then
                    cannon:updateIngot(GlobalUserItem.lIngot)
                  end
                else
                  self._dataModel.m_secene.lPlayCurScore[1][catchData.wChairID + 1] = self._dataModel.m_secene.lPlayCurScore[1][catchData.wChairID + 1] + catchData.lScoreCount
                  --if nil == cannon then
                  --cannon:updateScore(self._dataModel.m_secene.lPlayCurScore[1][wChairID + 1])  
                  self.m_cannonLayer:updateUserScore( self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1],cannonPos+1 )
                  --end
                   
                end  

                 --self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1] = self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1] + catchData.lScoreCount
                  
                  --更新用户分数
                  

                  --捕获鱼收获
                  self._dataModel.m_getFishScore = self._dataModel.m_getFishScore + catchData.lScoreCount
                
                  
              else    --其他玩家
                
                  --获取用户
                  local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)

                  for k,v in pairs(self.m_cannonLayer._userList) do
                    local item = v
                    if item.dwUserID == userid  then
                      if scoreType ~= g_var(cmd).EST_YuanBao then
                        --item.lScore = item.lScore + catchData.lScoreCount
                        self._dataModel.m_secene.lPlayCurScore[1][catchData.wChairID + 1] = self._dataModel.m_secene.lPlayCurScore[1][catchData.wChairID + 1] + catchData.lScoreCount
                        --更新用户分数
                         self.m_cannonLayer:updateUserScore( self._dataModel.m_secene.lPlayCurScore[1][catchData.wChairID + 1],cannonPos+1 )
                      end
                        break
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
    return self._dataModel
end

function GameLayer:sendNetData( cmddata )
    return self._gameFrame:sendSocketData(cmddata)
end

return GameLayer
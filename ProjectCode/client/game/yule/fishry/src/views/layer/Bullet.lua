--
-- Author: Tang
-- Date: 2016-08-09 10:26:25
-- 子弹

local Bullet = class("Bullet", 	cc.Sprite)

local module_pre = "game.yule.fishry.src"			
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local cmd = module_pre..".models.CMD_RYGame"
local g_var = ExternalFun.req_var
local scheduler = cc.Director:getInstance():getScheduler()

Bullet.bulletType =
{
   Normal_Bullet = 0, --正常炮
   Bignet_Bullet = 1,--网变大
   Special_Bullet = 2--加速炮
}

local Type =  Bullet.bulletType

function Bullet:ctor(angle,cannon)
   self.m_Type = Type.Normal_Bullet
   self.m_fishIndex = g_var(cmd).INT_MAX --鱼索引
   self.m_cannonPos = -1 --炮台索引	
   self.m_index     = -1 --子弹索引
   self.m_netColor = cc.RED
   self.m_moveDir = cc.p(0,0)
   self.m_targetPoint = cc.p(0,0)
   self.m_isSelf = false

   self.orignalAngle = 0

   self.m_cannon = cannon
   self._dataModule = self.m_cannon._dataModel
   self._gameFrame  = self.m_cannon.frameEngine
   self.m_pUserItem = self._gameFrame:GetMeUserItem()
   self.m_isturn = false
   self.m_bbullet = nil
   self.m_bRemove = false
   --获取自己信息
   self.m_nTableID = 0
   self.m_nChairID = 0
   if nil ~= self._gameFrame:GetMeUserItem() and nil ~= self.m_pUserItem then
   	self.m_nTableID  = self.m_pUserItem.wTableID
  	self.m_nChairID  = self.m_pUserItem.wChairID
  else
  	print("GetMeUserItem nil")
   end
  		

--其他玩家信息
  	self.m_pOtherUserItem = nil
  
   	self.m_speed = self._dataModule.m_secene.nBulletVelocity[1][g_var(cmd).BULLET_MAX]/1000*25	--子弹速度
   	--print(string.format("self.m_speed %d", self.m_speed))

   self:initWithAngle(angle)

  self.m_netcolor = nil --网颜色
 
   	 --注册事件
    ExternalFun.registerTouchEvent(self,false)
end


function Bullet:initWithAngle(angle)
	-- body
	self:initWithSpriteFrameName("bullet_0.png")
	--self:initWithSpriteFrameName(file)
	self:setRotation(angle)
	
	self.m_moveDir = cc.pForAngle(math.rad(90-self:getRotation()))
	local panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).BulletAnim)
	if nil ~= panim then
		local action = cc.Animate:create(panim)
		self:runAction(action)
	end
end

function Bullet:setBbullet( bBullet )
	--子弹索引
	self.m_bbullet = bBullet
end

function Bullet:getBbullet()
	--子弹索引
	return self.m_bbullet 
end

function Bullet:setIndex( index )
	--子弹索引
	self.m_index = index
end

function Bullet:setIsSelf( isself )
	self.m_isSelf = isself
end

function Bullet:setNetColor( color )
	self.m_netColor = color
end

function Bullet:setFishIndex( index )
	self.m_fishIndex = index



end

function Bullet:clearMbullet()
	self.m_bbullet = nil
end

function Bullet:onEnter( )
	
	self:schedulerUpdate()

end


function Bullet:onExit( )
	self.m_bRemove = true
	self:unSchedule()
	--print("Bullet:onExit ",self.m_index)
	self:removeAllComponents()
end


function Bullet:schedulerUpdate() 
	local function updateBullet( dt )
		self:update(dt)
	end

	--定时器
	if nil == self.m_schedule then
		self.m_schedule = scheduler:scheduleScriptFunc(updateBullet, 0, false)
	end

end

function Bullet:unSchedule()
	if nil ~= self.m_schedule then
		scheduler:unscheduleScriptEntry(self.m_schedule)
	self.m_schedule = nil
	end
end

function Bullet:getBulletNum( )
	-- body
	local mutiple = math.floor(self.m_nMultipleIndex/2)+1
	return mutiple
end



function Bullet:setType( type )

	self.m_Type = type
	local pwarhead
	
	if self.m_Type == Type.Normal_Bullet or self.m_Type == Type.Bignet_Bullet then
		pwarhead = cc.Sprite:create("game_res/im_bullet.png")
	elseif	self.m_Type == Type.Special_Bullet  then
		pwarhead = cc.Sprite:create("game_res/im_bullet_red.png")
		self.m_speed = self.m_speed * 2
	end
	pwarhead:setPosition(cc.p(self:getContentSize().width / 2, self:getContentSize().height / 2))
	self:addChild(pwarhead)
end

function Bullet:initPhysicsBody()


	if self.m_fishIndex  ~= g_var(cmd).INT_MAX then

		return	
	end

	self:setPhysicsBody(cc.PhysicsBody:createBox(self:getContentSize()))
    self:getPhysicsBody():setCategoryBitmask(2)
    self:getPhysicsBody():setCollisionBitmask(0)
    self:getPhysicsBody():setContactTestBitmask(1)
    self:getPhysicsBody():setGravityEnable(false)
end

function Bullet:changeDisplayFrame( chairId , score)
	local nBulletNum = self:getBulletNum()
	local frame = string.format("Bullet%d_Normal_%d_b.png", nBulletNum,chairId + 1)
	self:setSpriteFrame(frame)
end

function Bullet:update( dt )
	--[[
	if self.m_bRemove == true then
		return
	end
	--]]
	if self.m_fishIndex == g_var(cmd).INT_MAX then

		self:normalUpdate(dt) --正常发射
	else
		self:followFish(dt) --锁定鱼
	end
end

--正常发射
function Bullet:normalUpdate( dt )
	
	local movedis = dt * self.m_speed
	local movedir = cc.p(self.m_moveDir.x*movedis,self.m_moveDir.y*movedis)  
	local pos = cc.p(self:getPositionX()+movedir.x,self:getPositionY()+movedir.y)
	self:setPosition(pos.x,pos.y)
	local rect = cc.rect(0,0,yl.WIDTH,yl.HEIGHT)
	pos = cc.p(self:getPositionX(),self:getPositionY())

	if not cc.rectContainsPoint(rect,pos) then
		if self.m_isturn == true and self._dataModule.m_secene.bUnlimitedRebound==false then			
			self:fallingNet()
			--print(string.format("self.m_bbullet is nil %s", tostring(self.m_bbullet == nil)))
			if self.m_bbullet ~= nil  and  nil ~= self.m_bbullet.fallingNet then --
				self.m_bbullet:fallingNet()
			end
			if self.m_bbullet ~= nil and false == self.m_bbullet.m_bRemove then
				self.m_bbullet:removeFromParent()
				if nil ~= self.m_bbullet.clearMbullet  then
					self.m_bbullet:clearMbullet()
				end
				self.m_bbullet = nil
			end
            self:removeFromParent()		--
		else 
			self.m_isturn = true
			if pos.x<0 or pos.x>yl.WIDTH then
			local angle = self:getRotation()
			self:setRotation(-angle)
				if pos.x<0 then
			  		 pos.x = 0
				else
					pos.x = yl.WIDTH
				end
			else
				local angle = self:getRotation()
				self:setRotation(-angle + 180)
				if pos.y<0 then
					pos.y = 0
				else
					pos.y = yl.HEIGHT
				end
			end

		self.m_moveDir = cc.pForAngle(math.rad(90-self:getRotation()))
		local movedis = dt * self.m_speed
		local moveDir = cc.p(self.m_moveDir.x*movedis,self.m_moveDir.y*movedis) 
		pos = cc.p(self:getPositionX()+moveDir.x,self:getPositionY()+moveDir.y)
		self:setPosition(pos.x,pos.y)
		end
	end

end

--锁定鱼
function Bullet:followFish(dt)
	if true == self.m_bRemove or true == self.m_cannon.parent.parent.m_bLeaveGame then
		return
	end
	local fish = self._dataModule.m_fishList[self.m_fishIndex]

	if nil ~= fish then
		if true == fish.m_bRemove then
			--print("followFish m_bMove Finish")
			self.m_fishIndex = g_var(cmd).INT_MAX
			self:initPhysicsBody()
			return
		end
	end

	if nil == fish or nil == fish.getPositionX then
		self.m_fishIndex = g_var(cmd).INT_MAX
		self:initPhysicsBody()
		return
	end
	
	if nil ~= fish.m_data then 
		--print("followFish fishIndex ",fish.m_data.nFishKey, tostring(self.m_bRemove),"self.m_index ", self.m_index)
	end
	local fishPos 
	if false == fish.m_bRemove then
		local rect = cc.rect(0,0,yl.WIDTH,yl.HEIGHT)
		if not cc.rectContainsPoint(rect, cc.p(fish:getPositionX(), fish:getPositionY())) then
			self.m_fishIndex = g_var(cmd).INT_MAX
			self:initPhysicsBody()
			return
		end
	else
		self.m_fishIndex = g_var(cmd).INT_MAX
		self:initPhysicsBody()
		return
	end
	
	
	fishPos = cc.p(fish:getPositionX(),fish:getPositionY())
	fish.m_followFishPos = fishPos
	if self._dataModule.m_reversal then
		fishPos = cc.p(yl.WIDTH - fishPos.x , yl.HEIGHT - fishPos.y)
	end

	local angle = self._dataModule:getAngleByTwoPoint(fishPos, cc.p(self:getPositionX(),self:getPositionY()))

	self:setRotation(angle)

	--[[self.m_cannon.m_fort:setRotation(angle - self.m_cannon.orignalAngle)
			self.m_cannon.orignalAngle = angle]]


	self.m_moveDir = cc.pForAngle(math.rad(90-angle))

	local movedis = dt * self.m_speed
	local movedir = cc.pMul(self.m_moveDir,movedis)

	self:setPosition(self:getPositionX()+movedir.x,self:getPositionY()+movedir.y)

	if cc.pGetDistance(fishPos,cc.p(self:getPositionX(),self:getPositionY())) <= movedis then
		self:setPosition(fishPos)
		self:fallingNet()
		self:removeFromParent()
	end

end

--撒网
function Bullet:fallingNet()
	---[[
	self:unSchedule()

	local parent = self:getParent()
	if parent == nil then
		return
	end


	local pnet
	if self.m_Type == Type.Normal_Bullet or self.m_Type == Type.Special_Bullet then
		pnet = cc.Sprite:create("game_res/im_net.png")
	elseif  self.m_Type == Type.Bignet_Bullet then
		pnet = cc.Sprite:create("game_res/im_net_big.png")
	end
	pnet:setScale(205/pnet:getContentSize().width)
	if self.m_Type == Type.Bignet_Bullet then
		pnet:setScale(pnet:getScale()*1.5)
	end

	local pcolor = cc.Sprite:create("game_res/im_net_dot.png")
	pcolor:setColor(self.m_netColor)
	pcolor:setPosition(cc.p(pnet:getContentSize().width/2,pnet:getContentSize().height/2))
	pnet:addChild(pcolor)

	local offset =  cc.pMul(self.m_moveDir,20)

	pnet:setPosition(cc.p(self:getPositionX() + offset.x, self:getPositionY() + offset.y))
	local scalTo = cc.ScaleTo:create(0.08,pnet:getScale()*1.16)
		local scalTo1 = cc.ScaleTo:create(0.08,pnet:getScale())
		local call = cc.CallFunc:create(function()		
  	       pnet:removeFromParent()
   		end)	
  
		local seq = cc.Sequence:create(scalTo,scalTo1,scalTo,call)
		pnet:runAction(seq)
		pnet:runAction(cc.Sequence:create(cc.DelayTime:create(0.16),cc.FadeTo:create(0.05,0)))
		parent:addChild(pnet,20)


	if self.m_isSelf then

		self:sendCathcFish(pnet:getPositionX(),pnet:getPositionY())

	end
	--]]
end

--发送捕获消息
function Bullet:sendCathcFish(posX,posY)
	local cmddata = CCmd_Data:create(12)
   	cmddata:setcmdinfo(yl.MDM_GF_GAME, g_var(cmd).SUB_C_CATCH_FISH);
   	local pos = cc.p(self:getPositionX(),self:getPositionY())
   	pos = cc.p(posX,posY)
   	pos = self._dataModule:convertCoordinateSystem(pos, 0, self._dataModule.m_reversal)
    	cmddata:pushint(self.m_index)
    	cmddata:pushshort(pos.x)
  	cmddata:pushshort(pos.y)
  	--print(string.format("sendCathcFish m_index %d pos.x %d pos.y %d m_reversal %s",self.m_index, pos.x, pos.y , tostring(self._dataModule.m_reversal)))
  	 local systime = currentTime()
   	local lossTime = systime - self._dataModule.m_enterTime
   	cmddata:pushint(lossTime)  
    --发送失败
    if nil ~= self._gameFrame then
    	if not self._gameFrame:sendSocketData(cmddata) then
    	if nil ~= self._gameFrame then
    		self._gameFrame._callBack(-1,"发送捕鱼信息失败")
    	end
		
		end
    end
	

end

return Bullet
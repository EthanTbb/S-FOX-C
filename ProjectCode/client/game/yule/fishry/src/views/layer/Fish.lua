--
-- Author: Tang
-- Date: 2016-08-09 10:45:28
--鱼

local Fish = class("Fish",function(fishData,target)
	local fish =  display.newSprite()
	return fish
end)

local FISHTAG = 
{
	TAG_GUAN = 10
}

local module_pre = "game.yule.fishry.src"			
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local cmd = module_pre..".models.CMD_RYGame"
local g_var = ExternalFun.req_var
local scheduler = cc.Director:getInstance():getScheduler()

function Fish:ctor(fishData,target)
	self.m_bezierArry = {}
	self.fishCreateData = fishData
	self.fishIndex = fishData
	self.m_schedule = nil
	self.m_light = nil
	self.m_guan = nil
	self.m_data = fishData   		
	self.m_producttime = fishData.nProductTime
	self.m_ydtime = 0 			--鱼游动时间
	self.m_pathIndex = 1
	self.m_nQucikClickNum = 0
	self.m_fTouchInterval = 0
	self:setPosition(cc.p(-500,-500))
	self:setTag(g_var(cmd).Tag_Fish)
	self._dataModel = target._dataModel
	self.m_bMoveFinish = false --是否游完移除
	self.m_bRemove = false
	self:initWithType(self.fishCreateData,target)
	self.m_followFishPos = cc.p(0,0)
	 --注册事件
    ExternalFun.registerTouchEvent(self,true)

end

function Fish:schedulerUpdate()

	local function updateFish(dt)

		self.m_ydtime = self.m_ydtime + dt * 1000
		local bezier =  self.m_data.TBzierPoint[1] -- table
		local tbp =  bezier[self.m_pathIndex]
	
		while self.m_ydtime > tbp.Time  do
			self.m_ydtime = self.m_ydtime - tbp.Time
			self.m_pathIndex = self.m_pathIndex + 1
		end

		if self.m_data.nBezierCount <= self.m_pathIndex-1 then 
			if(self._dataModel.m_fishIndex == self.m_data.nFishKey) then
				self._dataModel.m_fishIndex = g_var(cmd).INT_MAX
				self.m_bMoveFinish = true
			end
			--self._dataModel.m_fishList[self.m_data.nFishKey] = nil
			table.remove(self._dataModel.m_fishList, self.m_data.nFishKey)
			self:unScheduleFish()
			self.m_bRemove = true
			self:removeFromParent()
			print("******************fish removeFromParent********************")
			return
		end

		--路径百分比
		local percent = self.m_ydtime/tbp.Time

		local point = self:PointOnCubicBezier(self.m_pathIndex,percent)

		if self.m_data.fRotateAngle then
			local bzierpoint = bezier[1]
			local beginVec2 = cc.p(bzierpoint.BeginPoint.x,bzierpoint.BeginPoint.y)
			point = self:RotatePoint(beginVec2,self.m_data.fRotateAngle,point)
		end

		point = cc.p(point.x+self.m_data.PointOffSet.x,point.y+self.m_data.PointOffSet.y)
		local m_oldPoint = cc.p(self:getPositionX(),self:getPositionY())
		self:setConvertPoint(point)

		local nowPos = cc.p(self:getPositionX(),self:getPositionY())
		--if  nowPos.x ~= m_oldPoint.x and  nowPos.y ~= m_oldPoint.y  then
			local angle = self._dataModel:getAngleByTwoPoint(nowPos,m_oldPoint)
			self:setRotation(angle)
			if self.m_light ~= nil then
				--print(angle)
			self.m_light:setRotation(angle)
			end
		--end
		local pos = cc.p(self:getPositionX(),self:getPositionY())
		--if pos.x < m_oldPoint.x and not self._dataModel.m_reversal  then
			--self:setFlippedX(false)
		if pos.x < m_oldPoint.x and self._dataModel.m_reversal == false  then
			self:setFlippedX(false)
		elseif pos.x > m_oldPoint.x and self._dataModel.m_reversal then
			self:setFlippedX(false)
		else
			self:setFlippedX(true)
		end

		if self.m_guan ~= nil then
			self.m_guan:setFlippedX(self:isFlippedX())
		end
		
		if self.m_light ~= nil then
			self.m_light:setFlippedX(self:isFlippedX())
		end



	end

	--定时器
	if nil == self.m_schedule then
		self.m_schedule = scheduler:scheduleScriptFunc(updateFish, 0, false)
	end
end

function Fish:unScheduleFish()
	if nil ~= self.m_schedule then
	scheduler:unscheduleScriptEntry(self.m_schedule)
	self.m_schedule = nil
	end
end

function Fish:onEnter()
	local time = currentTime()
	self.m_ydtime = time - self.m_producttime
	self:schedulerUpdate()
end

function Fish:onExit( )
	--print("fish onExit()..index ", self.m_data.nFishKey )
	self.m_bRemove = true
	self:unScheduleFish()

end

function Fish:onTouchBegan(touch, event)
	print("fish touch began")

	local point = touch:getLocation()
	point = self:convertToNodeSpace(point)

	local rect = self:getBoundingBox()
	rect = cc.rect(0,0,rect.width,rect.height) 

	return cc.rectContainsPoint( rect, point )  


end

function Fish:onTouchEnded(touch, event )
	--切换成当前锁定目标

	self._dataModel.m_fishIndex	= self.m_data.nFishKey
	print("fish touch ended")
end


function Fish:initWithType( param,target)
	self:initBezierConfig(param)
end

function Fish:initBezierConfig( param )
	
	if type(param) ~= "table" then
		print("传入参数类型有误, the param should be a type of table")
		return
	end

	if not param.bRepeatCreate then --按原路径返回
		
		local beziers =  param.TBzierPoint[1] -- table
		local tmp = {} 
		for i=1,#beziers-1 do
			tmp[i] = beziers[i]
		end

		for i=1,#tmp do
			local config = tmp[i]
			table.insert(beziers,#tmp+2,config)
		end
		tmp = {}
		self.m_data.TBzierPoint[1] = beziers

	end

	for i=1,param.nBezierCount do
		local bezier =  param.TBzierPoint[1] -- table
		local tbp =  bezier[i]
	
		local bconfig = 
		{
			dAx = 0,
			dBx = 0,
			dCx = 0,
			dAy = 0,
			dBy = 0,
			dCy = 0
		}
	
		bconfig.dCx = 3.0 * (tbp.KeyOne.x - tbp.BeginPoint.x)
		bconfig.dBx = 3.0 * (tbp.KeyTwo.x - tbp.KeyOne.x) - bconfig.dCx
		bconfig.dAx = tbp.EndPoint.x - tbp.BeginPoint.x - bconfig.dCx - bconfig.dBx

		bconfig.dCy = 3.0 * (tbp.KeyOne.y - tbp.BeginPoint.y)
		bconfig.dBy = 3.0 * (tbp.KeyTwo.y - tbp.KeyOne.y) - bconfig.dCy
		bconfig.dAy = tbp.EndPoint.y - tbp.BeginPoint.y - bconfig.dCy - bconfig.dBy
		table.insert(self.m_bezierArry, bconfig)
	end
end

function Fish:PointOnCubicBezier(pathIndex,t)

	local bconfig = 
		{
			dAx = 0,
			dBx = 0,
			dCx = 0,
			dAy = 0,
			dBy = 0,
			dCy = 0
		}

    local result = {}
	local tSquard = 0
	local tCubed = 0
	local param = self.m_data
	bconfig = self.m_bezierArry[pathIndex]

	local bezier =  param.TBzierPoint[1] -- table
	local tbp =  bezier[pathIndex]
	tSquard = t*t
	tCubed = tSquard*t
	result.x = (bconfig.dAx * tCubed) + (bconfig.dBx * tSquard) + (bconfig.dCx * t) + tbp.BeginPoint.x
	result.y = (bconfig.dAy * tCubed) + (bconfig.dBy * tSquard) + (bconfig.dCy * t) + tbp.BeginPoint.y

	return result
end

function Fish:RotatePoint(pcircle,dradian,ptsome)

	local tmp = {}
	ptsome.x = ptsome.x - pcircle.x
	ptsome.y = ptsome.y - pcircle.y

	tmp.x = ptsome.x*math.cos(dradian) - ptsome.y*math.sin(dradian) + pcircle.x
	tmp.y = ptsome.x * math.sin(dradian) + ptsome.y*math.cos(dradian) + pcircle.y

	return tmp
end

function Fish:initAnim()
	local namestr 
	local aniName
	if self.m_data.nFishType == g_var(cmd).FISH_YUAN_BAO then
		print("元宝鱼")
		self:initWithFile("game_res/im_yb_fish.png",cc.rect(0,0,239,226) ) 
		local animation = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).YBFish)
		self:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
	else
		namestr = string.format("fish_%d_yd_0.png", self.m_data.nFishType)
		self:initWithSpriteFrameName(namestr)
		local pname = string.format("fish_%d_yd", self.m_data.nFishType)
		local panim = cc.AnimationCache:getInstance():getAnimation(pname)
		--print(string.format("panim == nil %s\n",tostring(panim ~= nil)))
		if panim ~= nil then
			--美人鱼
			if self.m_data.nFishType == 17 then
				print("美人鱼")
				local panim0 = cc.Animate:create(panim);
				local panim1 = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation("fish_18_yd"))
				local panim2 = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation(g_var(cmd).RenYu_Q_To_B))
				local panim3 = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation(g_var(cmd).RenYu_B_To_Q))
				local paction = cc.RepeatForever:create(cc.Sequence:create(panim0,panim0,panim2,panim1,panim1,panim3))
				self:runAction(paction)
			else
				local paction = cc.RepeatForever:create(cc.Animate:create(panim))
				self:runAction(paction)
			end
		end
	end	
	self:setOpacity(0)
	local pshowaction = cc.FadeTo:create(1.0,255)
	self:runAction(pshowaction)
end

--死亡处理
function Fish:deadDeal()
	self.m_bRemove = true
	self:setColor(cc.WHITE)
	self:stopAllActions()
	self:unScheduleFish()
	self._dataModel.m_fishList[self.m_data.nFishKey] = nil
	table.remove(self._dataModel.m_fishList, self.m_data.nFishKey)
 	
	if self.m_data.nFishType == g_var(cmd).FISH_YUAN_BAO then
		local panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).YBDie)
		self:setRotation(0)
		if panim ~= nil then
           			local paction1 = cc.Animate:create(panim);
           			local callfunc = cc.CallFunc:create(function()
           			self.m_bRemove = true
				self:removeFromParent()
			end)
            		local paction = cc.Sequence:create(paction1,callfunc);
           			self:runAction(paction);
        		end
	else
		local pname = string.format("fish_%d_die", self.m_data.nFishType)
		local panim = cc.AnimationCache:getInstance():getAnimation(pname)
		if panim ~= nil then
			local callfunc = cc.CallFunc:create(function()
				self.m_bRemove = true
				self:removeFromParent()
			end)
			local paction1 = cc.Repeat:create(cc.Animate:create(panim),2);
            		local paction = cc.Sequence:create(paction1, callfunc);
           			self:runAction(paction);
		end
	end

	if self.m_light ~= nil then
        	self.m_guan:removeFromParent();
        	self.m_light:removeFromParent();
        	self.m_guan = nil;
        	self.m_light = nil;
    	end
end

--设置物理属性
function Fish:initPhysicsBody()
	local fishtype = self.fishCreateData.nFishType
	local body = self._dataModel:getBodyByType(fishtype)

	if body == nil then
		--print(string.format("body %d is nil.......",fishtype ))	
		return
	end

	self:setPhysicsBody(body)

--设置刚体属性
    self:getPhysicsBody():setCategoryBitmask(1)
    self:getPhysicsBody():setCollisionBitmask(0)
    self:getPhysicsBody():setContactTestBitmask(2)
    self:getPhysicsBody():setGravityEnable(false)
end

function Fish:initWithState()
	
	local fishstate = self.fishCreateData.nFishState
	if self.fishCreateData.bSpecial == true or self.fishCreateData.bKiller == true then
		local frameName = string.format("fish_%d_yd_light_0.png",self.fishCreateData.nFishType)
		self.m_light = cc.Sprite:createWithSpriteFrameName(frameName)
		--print("m_light is nil %s ", tostring(m_light == nil))
		--print("self:getParent() %s ", tostring(self:getParent() == nil))
		self.m_light:setPosition(cc.p(self:getPositionX(), self:getPositionY()))
		self.m_light:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
		self:getParent():addChild(self.m_light, self.fishCreateData.nFishType)
		local ligthanim = cc.AnimationCache:getInstance():getAnimation(string.format("fish_%d_yd_light",self.fishCreateData.nFishType))
		local paction = cc.RepeatForever:create(cc.Animate:create(ligthanim))
		self.m_light:runAction(paction)
		--cc.blendFunc
		self.m_light:setScale(1.5)

		local plight = cc.Sprite:createWithSpriteFrameName(string.format("fish_%d_yd_light_0.png",self.fishCreateData.nFishType))
		plight:setPosition(self.m_light:getContentSize().width/2,self.m_light:getContentSize().height/2)
		self.m_light:addChild(plight)

		if self.fishCreateData.bSpecial == true then 
			self.m_guan = cc.Sprite:createWithSpriteFrameName(string.format("fish_%d_yd_crown.png",self.fishCreateData.nFishType))
			self.m_guan:setPosition(self:getContentSize().width/2,self:getContentSize().height/2)
			self:addChild(self.m_guan)
			self.m_light:setColor(cc.c3b(255, 255, 0))
			plight:setColor(cc.c3b(255, 255, 0))
		end
		if self.fishCreateData.bKiller == true then
			self.m_guan = cc.Sprite:createWithSpriteFrameName(string.format("fish_%d_bomb_0.png",self.fishCreateData.nFishType))
			self.m_guan:setPosition(self:getContentSize().width/2,self:getContentSize().height/2)
			self:addChild(self.m_guan)
			local bombanim = cc.AnimationCache:getInstance():getAnimation(string.format("fish_%d_bomb",self.fishCreateData.nFishType))
			local paction = cc.RepeatForever:create(cc.Animate:create(bombanim))
			self.m_guan:runAction(paction)
			self.m_light:setColor(cc.c3b(255, 0, 0))
			local lightaction = cc.TintBy:create(2.0,0,255,0)
			local lightaction1 = cc.TintBy:create(2.0,0,0,0)
			self.m_guan:runAction(cc.RepeatForever:create(cc.Sequence:create(lightaction,lightaction1)))

			plight:runAction(cc.RepeatForever:create(cc.Sequence:create(lightaction:clone(),lightaction1:clone() ) ) )
			plight:setColor(cc.c3b(255, 0, 0))

			local plight1 = cc.Sprite:createWithSpriteFrameName(string.format("fish_%d_yd_light_0.png",self.fishCreateData.nFishType))
			plight1:setPosition(self:getContentSize().width/2,self:getContentSize().height/2)
			plight1:setColor(cc.c3b(255, 0, 0))
			plight1:runAction(cc.RepeatForever:create(cc.Sequence:create(lightaction:clone(),lightaction1:clone() ) ) )
			self.m_light:addChild(plight1)
		end
	end
end

--转换坐标
function  Fish:setConvertPoint( point )
		
	 local WIN32_W = 1280
	 local WIN32_H = 800

	 local scalex = yl.WIDTH/WIN32_W
	 local scaley = yl.HEIGHT/WIN32_H

	 local pos = cc.p(point.x*scalex,(WIN32_H-point.y)*scaley) 
	 self:setPosition(pos)

	 if nil ~= self.m_light then
	 	self.m_light:setPosition(pos)
	 end
end


--鱼停留
function Fish:Stay(time)
	self:unScheduleFish()
	local call = cc.CallFunc:create(function()	
		self:schedulerUpdate()
	end)
	local delay = cc.DelayTime:create(time/1000)

	self:runAction(cc.Sequence:create(delay,call))


end

function Fish:dealproductime()
	self.m_producttime = self._dataModel.m_enterTime + self.m_data.nProductTime + self.m_data.unCreateDelay
end

return Fish

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

local module_pre = "game.yule.fishlk.src"			
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local cmd = module_pre..".models.CMD_LKGame"
local g_var = ExternalFun.req_var
local scheduler = cc.Director:getInstance():getScheduler()

function Fish:ctor(fishData,target)
	self.m_bezierArry = {}
	self.fishCreateData = fishData

	self.m_schedule = nil

	self.m_data = fishData   		
	self.m_producttime = fishData.nProductTime
	self.m_ydtime = 0 			--鱼游动时间
	self.m_pathIndex = 1
	self.m_nQucikClickNum = 0
	self.m_fTouchInterval = 0
	self:setPosition(cc.p(-500,-500))
	self:setTag(g_var(cmd).Tag_Fish)
	self._dataModel = target._dataModel

	self:initWithType(self.fishCreateData,target)

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
			self._dataModel.m_fishList[self.m_data.nFishKey] = nil
			self._dataModel.m_InViewTag[self.m_data.nFishKey] = nil
			self:unScheduleFish()
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


		if cc.rectContainsPoint( cc.rect(0,0,yl.WIDTH, yl.HEIGHT), point ) then
			if self.m_data.nFishType ~= g_var(cmd).FishType.FishType_YuanBao then
				self._dataModel._bFishInView = true
				self._dataModel.m_InViewTag[self.m_data.nFishKey] = 1
			end
			
		else
		    self._dataModel._bFishInView = false
		    self._dataModel.m_InViewTag[self.m_data.nFishKey] = nil
		end

		local nowPos = cc.p(self:getPositionX(),self:getPositionY())
		local angle = self._dataModel:getAngleByTwoPoint(nowPos,m_oldPoint)
		self:setRotation(angle)

		local pos = cc.p(self:getPositionX(),self:getPositionY())

		if pos.x < m_oldPoint.x and not self._dataModel.m_reversal  then
			self:setFlippedX(true)

		elseif pos.x < m_oldPoint.x and self._dataModel.m_reversal  then
			self:setFlippedX(false)

		elseif pos.x > m_oldPoint.x and self._dataModel.m_reversal then
			self:setFlippedX(true)
		else
			self:setFlippedX(false)
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
	--print("fish onExit()...........................")
	self._dataModel.m_InViewTag[self.m_data.nFishKey] = nil
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
	if self.m_data.nFishType ~= g_var(cmd).FishType.FishType_YuanBao then
	
		namestr = string.format("fishMove_%03d_1.png", self.m_data.nFishType+1)
		aniName = string.format("animation_fish_move%d", self.m_data.nFishType+1)
	else
		namestr = "fishMove_ignot_1.png"
		aniName = "fish_ignot_move"
	end	

	self:initWithSpriteFrameName(namestr)
	
	local animation = cc.AnimationCache:getInstance():getAnimation(aniName)
	if nil ~= animation then
	   if self.m_data.nFishType == g_var(cmd).FishType.FishType_BaoZhaFeiBiao then
	   	  	self:setOpacity(0)
	   	  	local rotate = cc.RotateBy:create(8.5,360)
			local repeatation = cc.RepeatForever:create(rotate)
			local copySelf = cc.Sprite:createWithSpriteFrameName(namestr)
			if nil ~= copySelf then
				local contentSize = self:getContentSize()
				copySelf:setPosition(cc.p(contentSize.width/2,contentSize.height/2))
				copySelf:runAction(repeatation)
				self:addChild(copySelf, 1)
			end
			
	   else
	   		local action = cc.RepeatForever:create(cc.Animate:create(animation))
	   		self:runAction(action)
	   		--渐变出现
	   		self:setOpacity(0)
	   		self:runAction(cc.FadeTo:create(0.2,255))
	   end
	end
end

--死亡处理
function Fish:deadDeal()
	
	self:setColor(cc.WHITE)
	self:stopAllActions()
	self:unScheduleFish()

	local aniName 
	if self.m_data.nFishType ~= g_var(cmd).FishType.FishType_YuanBao then
		aniName = string.format("animation_fish_dead%d",self.m_data.nFishType+1)
	else
		aniName = "fish_ignot_dead"
	end

	local ani = cc.AnimationCache:getInstance():getAnimation(aniName)
	local parent = self:getParent()

	--爆炸飞镖
	if self.m_data.nFishType == g_var(cmd).FishType.FishType_BaoZhaFeiBiao then
		local nKnife = 18
		local angle = 20
		local radius = 1200
		for i=1,nKnife do
			local sKnife = cc.Sprite:create("game_res/knife.png")
			sKnife:setAnchorPoint(0,0.5)
			sKnife:setPosition(self:getPositionX(),self:getPositionY())
			local pos = cc.p(self:getPositionX(),self:getPositionY())
			local purPos = cc.p(0,0)
			purPos.x = pos.x + radius * self._dataModel.m_cosList[20*i]
			purPos.y = pos.y + radius * self._dataModel.m_sinList[20*i]
			purPos = self._dataModel:convertCoordinateSystem(purPos, 1, self._dataModel.m_reversal)
			local callfunc = cc.CallFunc:create(function()
				sKnife:removeFromParent()
			end)

			sKnife:runAction(cc.Sequence:create(cc.MoveTo:create(1.5,purPos),callfunc))
			parent:addChild(sKnife)

		
			 local angle = math.atan2((purPos.y - sKnife:getPositionY()), (purPos.x - sKnife:getPositionX())) / 3.14 * 180
			 if angle < 0 then
			 	angle = angle - (90 + angle)
			 	if self._dataModel.m_reversal then
			 		angle = angle + 180
			 	end
			 	sKnife:setRotation(angle)
			 else
			 	angle = 90 - angle 
			 	if self._dataModel.m_reversal then
			 		angle = angle + 180
			 	end
			 	sKnife:setRotation(angle)
			 end
		end
		--全屏鱼的位置出现飞镖爆炸
		local nBoom = 14 + math.random(5)
		local delayTime = 0
		for i=1,nBoom do
			delayTime = math.random(4) * 0.13

			local boomAnim = cc.AnimationCache:getInstance():getAnimation("BombDartsAnim")
			local bomb = cc.Sprite:createWithSpriteFrameName("boom_darts0.png")
			local pos = cc.p(0,0)
			pos.x = 100 + math.random(1234)
			pos.y = 100 + math.random(650)
			bomb:setPosition(pos.x,pos.y)

			local call = cc.CallFunc:create(function()
				bomb:removeFromParent()
			end)

			local delayAction = cc.DelayTime:create(delayTime)
			local action = cc.Sequence:create(delayAction,cc.Animate:create(boomAnim),call)
			bomb:runAction(action)
			parent:addChild(bomb,41)

		end
	end

	if self.m_data.nFishType == g_var(cmd).FishType.FishType_ShuiHuZhuan then
		
		local radius = 580
		local nBomb = 12

		local pos = cc.p(self:getPositionX(),self:getPositionY())
		for i=1,nBomb do
			local boomAnim = cc.AnimationCache:getInstance():getAnimation("BlueIceAnim")
			local bomb = cc.Sprite:createWithSpriteFrameName("blue00.png")
			bomb:setPosition(self:getPositionX(),self:getPositionY())
			bomb:runAction(cc.Animate:create(boomAnim))
			parent:addChild(bomb,40)
			if boomAnim then
				local purPos = cc.p(0,0)
				purPos.x = pos.x + radius * self._dataModel.m_cosList[30*i]
				purPos.y = pos.y + radius * self._dataModel.m_sinList[30*i]

				local move = cc.MoveTo:create(0.8,purPos)

				local call = cc.CallFunc:create(function()	
					bomb:removeFromParent()
				end)

				bomb:runAction(cc.Sequence:create(move,call))
			end
		end
	end

	if (self.m_data.nFishType >=  g_var(cmd).FishType.FishType_JianYu and self.m_data.nFishType <=  g_var(cmd).FishType.FishType_LiKui) or self.m_data.nFishType ==  g_var(cmd).FishType.FishType_BaoZhaFeiBiao then
		
		local radius = 360
		local nBomb = 1
		if self.m_data.nFishType >=  g_var(cmd).FishType.FishType_JianYu and self.m_data.nFishType <=  g_var(cmd).FishType.FishType_DaJinSha then
			nBomb = 1
		elseif self.m_data.nFishType >  g_var(cmd).FishType.FishType_DaJinSha and self.m_data.nFishType <=  g_var(cmd).FishType.FishType_LiKui then
			nBomb = 6
		elseif self.m_data.nFishType ==  g_var(cmd).FishType.FishType_BaoZhaFeiBiao then
			nBomb = 8
			radius = 580
			
		end

		local pos = cc.p(self:getPositionX(),self:getPositionY())

		for i=1,nBomb do
			local boomAnim = cc.AnimationCache:getInstance():getAnimation("BombAnim")
			local bomb = cc.Sprite:createWithSpriteFrameName("boom00.png")
			bomb:setPosition(pos.x,pos.y)
			bomb:runAction(cc.Animate:create(boomAnim))
			parent:addChild(bomb,40)

			if boomAnim then
				local action = nil
				if nBomb == 1 then
					action = cc.DelayTime:create(0.8)
				else
					local purPos = cc.p(0,0)
					purPos.x = pos.x + self._dataModel.m_cosList[360/nBomb*i]
					purPos.y = pos.y + self._dataModel.m_sinList[360/nBomb*i]
					purPos = self._dataModel:convertCoordinateSystem(purPos, 2, self._dataModel.m_reversal)
					action = cc.MoveTo:create(0.8,purPos)

				end
				local call = cc.CallFunc:create(function()
					bomb:removeFromParent()
				end)
				bomb:runAction(cc.Sequence:create(action,call))
			end
		end
	end

	if nil ~= ani then

		local times = 4
		if self.m_data.nFishType == g_var(cmd).FishType.FishType_YuanBao then
			times = 1
		end
		local repeats = cc.Repeat:create(cc.Animate:create(ani),times)
		local call = cc.CallFunc:create(function()	

			self._dataModel.m_fishList[self.m_data.nFishKey] = nil
		   	self:unScheduleFish()
  	       	self:removeFromParent()
   		end)
		local action = cc.Sequence:create(repeats,call)
		self:runAction(action)

	else

		self._dataModel.m_fishList[self.m_data.nFishKey] = nil
		self:unScheduleFish()
		self:removeFromParent()
	end
end

--设置物理属性
function Fish:initPhysicsBody()
	local fishtype = self.fishCreateData.nFishType
	local body = self._dataModel:getBodyByType(fishtype)

	if body == nil then
		print("body is nil.......")
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
	if  fishstate ~= g_var(cmd).FishState.FishState_Normal then
		local contentsize = self:getContentSize()

		if fishstate == g_var(cmd).FishState.FishState_King then
			local guan = cc.Sprite:createWithSpriteFrameName("fish_king.png")
			guan:setPosition(cc.p(contentsize.width/2,contentsize.height/2))
			self:addChild(guan, -1)
			guan:runAction(cc.RepeatForever:create(cc.RotateBy:create(8.5,360)))

		elseif fishstate == g_var(cmd).FishState.FishState_Killer then
			local guan = cc.Sprite:createWithSpriteFrameName("fish_bomb_2.png")
			guan:setPosition(cc.p(contentsize.width/2,contentsize.height/2))
			self:addChild(guan, -1)
			guan:runAction(cc.RepeatForever:create(cc.RotateBy:create(8.5,360)))

		elseif fishstate == g_var(cmd).FishState.FishState_Aquatic then
			local guan = cc.Sprite:createWithSpriteFrameName("fishMove_026_1.png")
			local  anr  = guan:getAnchorPoint()
			guan:setPosition(cc.p(contentsize.width/2,contentsize.height/2))
			self:addChild(guan, 3)
			local anim = cc.AnimationCache:getInstance():getAnimation("animation_fish_move26")
			local action1 = cc.Repeat:create(cc.Animate:create(anim), 999999)
			local action2 = cc.Repeat:create(cc.RotateBy:create(8.5,360), 999999)
			guan:runAction(action1)
			guan:runAction(action2)
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


return Fish
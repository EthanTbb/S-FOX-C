--
-- Author: Tang
-- Date: 2016-12-14 17:13:37
--
-- 闹钟 00:00


local Clock = class("Clock", function(scene)
	local clock = display.newNode()
	return clock 
end)

Clock.Enum = 
{

	TAG_MOne = 1,
	TAG_MTwo = 2,
	TAG_SOne = 3,
	TAG_STwo = 4

}
local TAG = Clock.Enum
function Clock:ctor(scene)
	self._scene = scene

	self._min = 0
	self._sec = 0
	self:setContentSize(cc.size(24*5, 31))
	self:initClockTime()
end

function Clock:initClockTime()
	local mone
	local mtwo
	local sone
	local stwo

	if self._min < 10 then
		 mone = cc.Sprite:create("game_res/num.png",cc.rect(24,0,24,31))
		 mtwo = cc.Sprite:create("game_res/num.png",cc.rect(24*(self._min + 1),0,24,31))
	else
		mone = cc.Sprite:create("game_res/num.png",cc.rect(24*(math.floor(self._min/10)+1),0,24,31))
		mtwo = cc.Sprite:create("game_res/num.png",cc.rect(24*(math.mod(self._min,10) + 1),0,24,31))
	end

	mone:setTag(TAG.TAG_MOne)
	mone:setAnchorPoint(cc.p(1.0,0.5))
	mtwo:setTag(TAG.TAG_MTwo)
	mtwo:setAnchorPoint(cc.p(1.0,0.5))
	mone:setPosition(cc.p(23,16.5))
	mtwo:setPosition(cc.p(47,16.5))

	--间隔符号
	local timeSign = cc.Sprite:create("game_res/num.png",cc.rect(0,0,24,31))
	timeSign:setPosition(cc.p(59,16.5))
	self:addChild(timeSign)

	if self._sec < 10 then
		sone = cc.Sprite:create("game_res/num.png",cc.rect(24,0,24,31))
		stwo = cc.Sprite:create("game_res/num.png",cc.rect(24*(self._sec + 1),0,24,31))
	else
		sone = cc.Sprite:create("game_res/num.png",cc.rect(24*(math.floor(self._sec/10)+1),0,24,31))
		stwo = cc.Sprite:create("game_res/num.png",cc.rect(24*(math.mod(self._sec,10) + 1),0,24,31))
	end

	sone:setTag(TAG.TAG_SOne)
	sone:setAnchorPoint(cc.p(0.0,0.5))
	stwo:setTag(TAG.TAG_STwo)
	stwo:setAnchorPoint(cc.p(0.0,0.5))
	sone:setPosition(cc.p(71,16.5))
	stwo:setPosition(cc.p(95,16.5))

	self:addChild(mone)
	self:addChild(mtwo)
	self:addChild(sone)
	self:addChild(stwo)

end

function Clock:setTime(min,sec)
	self._min = min
	self._sec = sec

	self:updateClock()
end

function Clock:updateClock()
	local mone = self:getChildByTag(TAG.TAG_MOne)
	local mtwo = self:getChildByTag(TAG.TAG_MTwo)
	local sone = self:getChildByTag(TAG.TAG_SOne)
	local stwo = self:getChildByTag(TAG.TAG_STwo)
	
	if self._min < 10 then
		mone:initWithFile("game_res/num.png",cc.rect(24,0,24,31))
		mtwo:initWithFile("game_res/num.png",cc.rect(24*(self._min + 1),0,24,31))
	else
		mone:initWithFile("game_res/num.png",cc.rect(24*(math.floor(self._min/10)+1),0,24,31))
		mtwo:initWithFile("game_res/num.png",cc.rect(24*(math.mod(self._min,10) + 1),0,24,31))
	end

	if self._sec < 10 then
		sone:initWithFile("game_res/num.png",cc.rect(24,0,24,31))
		stwo:initWithFile("game_res/num.png",cc.rect(24*(self._sec + 1),0,24,31))
	else
		sone:initWithFile("game_res/num.png",cc.rect(24*(math.floor(self._sec/10)+1),0,24,31))
		stwo:initWithFile("game_res/num.png",cc.rect(24*(math.mod(self._sec,10) + 1),0,24,31))
	end

	mone:setAnchorPoint(cc.p(1.0,0.5))
	mtwo:setAnchorPoint(cc.p(1.0,0.5))
	sone:setAnchorPoint(cc.p(0.0,0.5))
	stwo:setAnchorPoint(cc.p(0.0,0.5))


	mone:setPosition(cc.p(23,16.5))
	mtwo:setPosition(cc.p(47,16.5))
	sone:setPosition(cc.p(71,16.5))
	stwo:setPosition(cc.p(95,16.5))

end





return Clock


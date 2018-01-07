--
-- Author: Tang
-- Date: 2016-12-14 15:52:37
--
local Chess = class("Chess",function(model)
		local Chess =  display.newNode()
    return Chess
end)

function Chess:ctor(model)
	self._xPos = 1
	self._yPos = 1

	self:setContentSize(cc.size(48, 48))
	self:setAnchorPoint(cc.p(0.5,0.5))

	self._dataModel = model

end

function Chess:getCurPos()
	return self._xPos,self._yPos
end

function Chess:setCurPos(x,y)

	if x > self._dataModel._nRows or y > self._dataModel._nColumns or x <=0 or y <= 0  then
		return
	end

	self._xPos = x
	self._yPos = y
	
end

return Chess
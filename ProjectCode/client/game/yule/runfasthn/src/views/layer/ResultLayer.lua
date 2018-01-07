local ResultLayer = class("ResultLayer", function(scene)
	local resultlayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 100)):setVisible(false)
	return resultlayer
end)

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.GameLogic")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")

ResultLayer.TAG_HEAD = 10
ResultLayer.TAG_SCORE = 11

function ResultLayer:onInitData()

end

function ResultLayer:ctor(scene)
	self._scene = scene
	self:onInitData()

	self._nodeUI = ExternalFun.loadCSB(self._scene.RES_PATH.."result/ResultLayer.csb", self)

	local btnExit = self._nodeUI:getChildByName("Button_exitResult")
	btnExit:addClickEventListener(function(ref)
		self:setVisible(false)
		self._scene._scene:onQueryExitGame()
	end)

	local btnContinue = self._nodeUI:getChildByName("Button_continue")
	btnContinue:addClickEventListener(function(ref)
		self:setVisible(false)
		self._scene:onUserReady()
	end)

	self.nodeUser = {}
	for i = 1, 3 do
		local str = string.format("FileNode_%d", i)
		self.nodeUser[i] = self._nodeUI:getChildByName(str)
	end
	self.nodeUser[1]:getChildByName("Sprite_userBg"):setSpriteFrame("Sprite_userBg_win.png")

	ExternalFun.registerTouchEvent(self, true)
end

function ResultLayer:onTouchBegan(touch, event)
	if not self:isVisible() then
		return false
	end

	local pos = touch:getLocation()
	local background = self._nodeUI:getChildByName("Sprite_resultBg")
	if cc.rectContainsPoint(background:getBoundingBox(), pos) then
		return false
	end

	self:setVisible(false)
	return true
end

function ResultLayer:setWinScore(id, num)
	local winScore = self.nodeUser[id]:getChildByName("AtlasLabel_score")
	winScore:setString("/"..string.formatNumberThousands(num, true, ".")) --"/"代表“+”或者“-”，“.”代表逗号
end

function ResultLayer:setResult(result, bMeWin)
	--赢者排头
	for i = 2, 3 do
		if result[i].lScore > 0 then
			result[i], result[1] = clone(result[1]), clone(result[i])
			break
		end
	end

	--绘制
	for i = 1, 3 do
		--输赢
		--self:setWinScore(i, result[i].lScore)
		local strFile = nil
		if result[i].lScore >= 0 then
			strFile = self._scene.RES_PATH.."result/num_winScore.png"
		else
			strFile = self._scene.RES_PATH.."result/num_loseScore.png"
			result[i].lScore = -result[i].lScore
		end
		local labAtscore = self.nodeUser[i]:getChildByTag(ResultLayer.TAG_SCORE)
		if labAtscore then
			labAtscore:removeFromParent()
		end
		local strNum = "/"..string.formatNumberThousands(result[i].lScore, true, ".") --"/"代表“+”或者“-”，“.”代表逗号
		labAtscore = cc.LabelAtlas:create(strNum, strFile, 16, 19, string.byte("."))
			:move(470, 33)
			:setAnchorPoint(cc.p(0, 0.5))
			:setTag(ResultLayer.TAG_SCORE)
			:addTo(self.nodeUser[i])

		--头像
		local head = self.nodeUser[i]:getChildByTag(ResultLayer.TAG_HEAD)
		if head then
			head:updateHead(result[i].userItem)
		else
			head = PopupInfoHead:createNormal(result[i].userItem, 50)
			head:setPosition(42, 33)			--初始位置
			head:enableHeadFrame(false)
			head:enableInfoPop(false)
			head:setTag(ResultLayer.TAG_HEAD)
			self.nodeUser[i]:addChild(head)
		end
		--昵称
		local labelNickname = self.nodeUser[i]:getChildByName("Text_nickname")
		labelNickname:setAnchorPoint(cc.p(0, 0.5))
		labelNickname:setString(result[i].userItem.szNickName)
	end

	--更换底框
	local spriteBg =  self._nodeUI:getChildByName("Sprite_resultBg")
	if bMeWin then
		spriteBg:setSpriteFrame("Sprite_resultBg_win.png")
	else
		spriteBg:setSpriteFrame("Sprite_resultBg_lose.png")
	end
	self:setVisible(true)
end

return ResultLayer
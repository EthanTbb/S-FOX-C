--
-- Author: tom
-- Date: 2017-02-27 17:26:42
--
local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.models.CMD_Game")
local SetLayer = class("SetLayer", function(scene)
	local setLayer = display.newLayer()
	return setLayer
end)

local SP_SWITCH_ON = "389_cbx_switch_1.png"
local SP_SWITCH_OFF = "389_cbx_switch_2.png"

function SetLayer:onInitData()
end

function SetLayer:onResetData()
end

function SetLayer:ctor(scene)
	self._scene = scene
	self:onInitData()

	self.colorLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 125))
		:setContentSize(display.width, display.height)
		:addTo(self)
	local this = self
	self.colorLayer:registerScriptTouchHandler(function(eventType, x, y)
		return this:onClickCallback(eventType, x, y)
	end)
	self._csbNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/SetLayer.csb")
		:addTo(self, 1)

	local btnClose = self._csbNode:getChildByName("bt_close")
	btnClose:addClickEventListener(function()
		this:hideLayer()
	end)

	self.sp_layerBg = self._csbNode:getChildByName("sp_setLayer_bg")
	self.sp_music = self._csbNode:getChildByName("sp_music")
	self.sp_effect = self._csbNode:getChildByName("sp_effect")
	--声音
	self:updateMusic()
	self:updateEffect()

	self:setVisible(false)
end

function SetLayer:onClickCallback(eventType, x, y)
	print(eventType)
	if eventType == "began" then
		return true
	end

	local pos = cc.p(x, y)
    local rectMusic = self.sp_music:getBoundingBox()
    local rectEffect = self.sp_effect:getBoundingBox()
    local rectLayerBg = self.sp_layerBg:getBoundingBox()
    if cc.rectContainsPoint(rectMusic, pos) then
		GlobalUserItem.setVoiceAble(not GlobalUserItem.bVoiceAble)
    	self:updateMusic()
    elseif cc.rectContainsPoint(rectEffect, pos) then
		GlobalUserItem.setSoundAble(not GlobalUserItem.bSoundAble)
    	self:updateEffect()
    elseif not cc.rectContainsPoint(rectLayerBg, pos) then
    	self:hideLayer()
    end

    return true
end

function SetLayer:showLayer()
	self.colorLayer:setTouchEnabled(true)
	self:setVisible(true)
end

function SetLayer:hideLayer()
	self.colorLayer:setTouchEnabled(false)
	self:setVisible(false)
	self:onResetData()
end

function SetLayer:updateMusic()
	--local bAble = GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble
	if GlobalUserItem.bVoiceAble then
		self.sp_music:setSpriteFrame(SP_SWITCH_ON)
		AudioEngine.playMusic(cmd.RES_PATH.."sound/BACK_PLAYING.wav", true)
	else
		self.sp_music:setSpriteFrame(SP_SWITCH_OFF)
	end
end

function SetLayer:updateEffect()
	if GlobalUserItem.bSoundAble then
		self.sp_effect:setSpriteFrame(SP_SWITCH_ON)
	else
		self.sp_effect:setSpriteFrame(SP_SWITCH_OFF)
	end
end

return SetLayer
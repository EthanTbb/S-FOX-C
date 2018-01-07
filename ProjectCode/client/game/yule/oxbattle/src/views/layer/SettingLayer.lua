--
-- Author: zhong
-- Date: 2016-07-08 17:16:26
--
--设置界面
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local SettingLayer = class("SettingLayer", cc.Layer)

SettingLayer.BT_EFFECT = 1
SettingLayer.BT_MUSIC = 2
SettingLayer.BT_CLOSE = 3
--构造
function SettingLayer:ctor(verstr)
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("SettingLayer.csb", self)

	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onBtnClick(sender:getTag(), sender)
		end
	end

	local layoutbg = csbNode:getChildByName("layout_bg")
	layoutbg:setTag(SettingLayer.BT_CLOSE)
	layoutbg:addTouchEventListener(btnEvent)

	local sp_bg = csbNode:getChildByName("setting_bg")
	sp_bg:setScale(0.1)
	sp_bg:runAction(cc.ScaleTo:create(0.17, 1.0))

	--关闭按钮
	local btn = sp_bg:getChildByName("close_btn")
	btn:setTag(SettingLayer.BT_CLOSE)
	btn:addTouchEventListener(btnEvent)

	--switch
    --音效
    self.m_btnEffect = sp_bg:getChildByName("effect_btn")
    self.m_btnEffect:setTag(SettingLayer.BT_EFFECT)
    self.m_btnEffect:addTouchEventListener(btnEvent)
    --音乐
    self.m_btnMusic = sp_bg:getChildByName("music_btn")
    self.m_btnMusic:setTag(SettingLayer.BT_MUSIC)
    self.m_btnMusic:addTouchEventListener(btnEvent)

    --版本
    self.m_txtversion = sp_bg:getChildByName("txt_version")
    self.m_txtversion:setString(verstr)

	self:refreshBtnState()
end

--
function SettingLayer:showLayer( var )
	self:setVisible(var)
end

function SettingLayer:onBtnClick( tag, sender )
	if SettingLayer.BT_CLOSE == tag then
		ExternalFun.playClickEffect()
		self:removeFromParent()
	elseif SettingLayer.BT_MUSIC == tag then
		local music = not GlobalUserItem.bVoiceAble;
		GlobalUserItem.setVoiceAble(music)
		self:refreshMusicBtnState()
		if GlobalUserItem.bVoiceAble == true then
			ExternalFun.playBackgroudAudio("GAME_BLACKGROUND.wav")
		end
	elseif SettingLayer.BT_EFFECT == tag then
		local effect = not GlobalUserItem.bSoundAble
		GlobalUserItem.setSoundAble(effect)
		self:refreshEffectBtnState()
	end
end

function SettingLayer:refreshBtnState(  )
	self:refreshEffectBtnState()
	self:refreshMusicBtnState()
end

function SettingLayer:refreshEffectBtnState(  )
	local str = nil
	if GlobalUserItem.bSoundAble then
		str = "bt_set_open.png"
	else
		str = "bt_set_close.png"
	end

	if nil ~= str then
		self.m_btnEffect:loadTextureDisabled(str,UI_TEX_TYPE_PLIST)
		self.m_btnEffect:loadTextureNormal(str,UI_TEX_TYPE_PLIST)
		self.m_btnEffect:loadTexturePressed(str,UI_TEX_TYPE_PLIST)
	end
end

function SettingLayer:refreshMusicBtnState(  )
	local str = nil
	if GlobalUserItem.bVoiceAble then
		str = "bt_set_open.png"
	else
		str = "bt_set_close.png"
	end
	if nil ~= str then
		self.m_btnMusic:loadTextureDisabled(str,UI_TEX_TYPE_PLIST)
		self.m_btnMusic:loadTextureNormal(str,UI_TEX_TYPE_PLIST)
		self.m_btnMusic:loadTexturePressed(str,UI_TEX_TYPE_PLIST)
	end
end

return SettingLayer
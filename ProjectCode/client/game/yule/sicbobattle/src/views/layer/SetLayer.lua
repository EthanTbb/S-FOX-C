--
-- Author: luo
-- Date: 2016年12月30日 15:18:32
--
--设置界面
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local SettingLayer = class("SettingLayer", function (  )
    local colorLayer = cc.LayerColor:create(cc.c4b(0,0,0,100))
    return colorLayer
end)

SettingLayer.BT_EFFECT = 1
SettingLayer.BT_MUSIC = 2
SettingLayer.BT_CLOSE = 3
--构造
function SettingLayer:ctor( verstr )
    --注册触摸事件
    ExternalFun.registerTouchEvent(self, true)
    --加载csb资源
    self._csbNode = ExternalFun.loadCSB("set/118_setLayer.csb", self)
    self._csbNode:setPosition(appdf.WIDTH/2,appdf.HEIGHT/2 )  
    --回调方法
    local cbtlistener = function (sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:OnButtonClickedEvent(sender:getTag(),sender)
        end
    end
    --背景
    local sp_bg = self._csbNode:getChildByName("Sprite_bg")
    self.m_spBg = sp_bg

    --关闭按钮
    local btn = self._csbNode:getChildByName("Button_close")
    btn:setTag(SettingLayer.BT_CLOSE)
    btn:addTouchEventListener(function (ref, eventType)
        if eventType == ccui.TouchEventType.ended then
            ExternalFun.playClickEffect()
            self:removeFromParent()
        end
    end)

    --音效
    self.m_btnEffect = self._csbNode:getChildByName("Button_sound")
    self.m_btnEffect:setTag(SettingLayer.BT_EFFECT)
    self.m_btnEffect:addTouchEventListener(cbtlistener)

    --音乐
    self.m_btnMusic = self._csbNode:getChildByName("Button_music")
    self.m_btnMusic:setTag(SettingLayer.BT_MUSIC)
    self.m_btnMusic:addTouchEventListener(cbtlistener)
    --按钮纹理
    if GlobalUserItem.bVoiceAble == true then 
        self.m_btnMusic:loadTextureNormal("118_set_open.png",ccui.TextureResType.plistType)
    else
        self.m_btnMusic:loadTextureNormal("118_set_close.png",ccui.TextureResType.plistType)
    end
    if GlobalUserItem.bSoundAble == true then 
        self.m_btnEffect:loadTextureNormal("118_set_open.png",ccui.TextureResType.plistType)
    else
        self.m_btnEffect:loadTextureNormal("118_set_close.png",ccui.TextureResType.plistType)
    end

    --游戏版本
    self.m_TextVer = self._csbNode:getChildByName("Text_version")
    self.m_TextVer:setString(verstr)
end

--
function SettingLayer:showLayer( var )
    self:setVisible(var)
end
--按钮回调方法
function SettingLayer:OnButtonClickedEvent( tag, sender )
    if SettingLayer.BT_MUSIC == tag then    --音乐
        local music = not GlobalUserItem.bVoiceAble
        GlobalUserItem.setVoiceAble(music)
        if GlobalUserItem.bVoiceAble == true then 
            ExternalFun.playBackgroudAudio("LOAD_BACK.mp3")
            sender:loadTextureNormal("118_set_open.png",ccui.TextureResType.plistType)
        else
            AudioEngine.stopMusic()
            sender:loadTextureNormal("118_set_close.png",ccui.TextureResType.plistType)
        end
    elseif SettingLayer.BT_EFFECT == tag then   --音效
        local effect = not GlobalUserItem.bSoundAble
        GlobalUserItem.setSoundAble(effect)
        if GlobalUserItem.bSoundAble == true then 
            sender:loadTextureNormal("118_set_open.png",ccui.TextureResType.plistType)
        else
            sender:loadTextureNormal("118_set_close.png",ccui.TextureResType.plistType)
        end
    end
end
--触摸回调
function SettingLayer:onTouchBegan(touch, event)
    return self:isVisible()
end

function SettingLayer:onTouchEnded(touch, event)
    local pos = touch:getLocation() 
    local m_spBg = self.m_spBg
    pos = m_spBg:convertToNodeSpace(pos)
    local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
    if false == cc.rectContainsPoint(rec, pos) then
        self:removeFromParent()
    end
end

return SettingLayer
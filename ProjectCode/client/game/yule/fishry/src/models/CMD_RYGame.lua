--
-- Author: Tang
-- Date: 2016-08-08 14:27:52
--

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd  = {}

--游戏版本
cmd.VERSION  			= appdf.VersionValue(6,6,0,3)
--游戏标识
cmd.KIND_ID				= 507
--游戏人数
cmd.GAME_PLAYER   		= 6
--房间名长度
cmd.SERVER_LEN			= 32

cmd.INT_MAX = 2147483647

cmd.BULLET_MAX = 8

cmd.Event_LoadingFish  = "Event_LoadingFinish"
cmd.Event_FishCreate   = "Event_FishCreate"

--音效
cmd.Small_0  = "sound_res/small_0.wav"
cmd.Small_1  = "sound_res/small_1.wav"
cmd.Small_2  = "sound_res/small_2.wav"
cmd.Small_3  = "sound_res/small_3.wav"
cmd.Small_4  = "sound_res/small_4.wav"
cmd.Small_5  = "sound_res/small_5.wav"
cmd.Big_7    = "sound_res/big_7.wav"
cmd.Big_8    = "sound_res/big_8.wav"
cmd.Big_9    = "sound_res/big_9.wav"
cmd.Big_10   = "sound_res/big_10.wav"
cmd.Big_11   = "sound_res/big_11.wav"
cmd.Big_12   = "sound_res/big_12.wav"
cmd.Big_13   = "sound_res/big_13.wav"
cmd.Big_14   = "sound_res/big_14.wav"
cmd.Big_15   = "sound_res/big_15.wav"
cmd.Big_16   = "sound_res/big_16.wav"
cmd.Beauty_0 = "sound_res/beauty_0.wav"
cmd.Beauty_1 = "sound_res/beauty_1.wav"
cmd.Beauty_2 = "sound_res/beauty_2.wav"
cmd.Beauty_3 = "sound_res/beauty_3.wav"

cmd.Load_Back      = "sound_res/LOAD_BACK.mp3"
cmd.Music_Back_1   = "sound_res/MUSIC_BACK_01.mp3"
cmd.Music_Back_2   = "sound_res/MUSIC_BACK_02.mp3"
cmd.Music_Back_3   = "sound_res/MUSIC_BACK_03.mp3"
cmd.Change_Scene   = "sound_res/CHANGE_SCENE.wav"
cmd.CoinAnimation  = "sound_res/CoinAnimation.wav"
cmd.Coinfly        = "sound_res/coinfly"
cmd.Fish_Special   = "sound_res/fish_special.wav"
cmd.Special_Shoot  = "sound_res/special_shoot.wav"
cmd.Combo          = "sound_res/combo.wav"
cmd.Shell_8        = "sound_res/SHELL_8.wav"
cmd.Small_Begin    = "sound_res/SMALL_BEGIN.wav"
cmd.SmashFail      = "sound_res/SmashFail.wav"

cmd.CoinLightMove  = "sound_res/CoinLightMove.wav"
cmd.Prop_armour_piercing = "sound_res/PROP_ARMOUR_PIERCING.wav"

cmd.RenYu_YD_Anim = "fish_17"       --美人鱼正面游动动画
cmd.RenYu_BYD_Anim = "fish_18"       --美人鱼背面游动动画

cmd.RenYu_B_To_Q = "fish_btoq"     --美人鱼前转身
cmd.RenYu_Q_To_B = "fish_qtob"     --美人鱼后转身

cmd.WaterAnim = "water"         --水波动画

cmd.FortAnim = "fort"          --炮台动画
cmd.FortLightAnim = "fort_0"        --激光炮动画
cmd.BulletAnim = "bullet"        --子弹尾动画
cmd.BombAnim = "bomb"          --爆炸动画
cmd.CopperAnim = "copper"        --铜币动画
cmd.SilverAnim =  "silver"        --银币动画
cmd.GoldAnim = "gold"          --金币动画
cmd.LightAnim = "light"         --激光准备发射动画

cmd.FishBall = "fishball"      --炸弹鱼死亡动画
cmd.FishLight  = "fishlight"     --炸弹鱼激光
    
cmd.YBFish = "ybfish"        --元宝鱼动画
cmd.YBDie = "ybdie"         --元宝鱼死亡动画
cmd.YBAnim  = "ybanim"        --元宝金币动画
cmd.watchAnim = "watchAnim"     --倒计时动画



--鱼索引
-- 正常鱼
cmd.FISH_XIAO_HUANG_YU			= 0								-- 小黄鱼
cmd.FISH_XIAO_LAN_YU			= 1								-- 小蓝鱼
cmd.FISH_XIAO_CHOU_YU			= 2								-- 小丑鱼
cmd.FISH_SI_LU_YU				= 3								-- 丝鲈鱼
cmd.FISH_SHENG_XIAN_YU			= 4								-- 神仙鱼
cmd.FISH_HE_TUN_YU				= 5								-- 河豚鱼
cmd.FISH_DENG_LONG_YU			= 6								-- 灯笼鱼
cmd.FISH_BA_ZHUA_YU				= 7								-- 八爪鱼
cmd.FISH_HAI_GUI				= 8								-- 海龟
cmd.FISH_SHUI_MU				= 9								-- 水母
cmd.FISH_JIAN_YU				= 10							-- 剑鱼
cmd.FISH_MO_GUI_YU				= 11							-- 魔鬼鱼
cmd.FISH_HAI_TUN				= 12							-- 海豚
cmd.FISH_SHA_YU					= 13							-- 鲨鱼
cmd.FISH_LAN_JING				= 14							-- 蓝鲸
cmd.FISH_YIN_JING				= 15							-- 银鲸
cmd.FISH_JIN_JING				= 16							-- 金鲸
cmd.FISH_MEI_REN_YU				= 17							-- 美人鱼

-- 特殊鱼
cmd.FISH_ZHA_DAN				= 18							-- 炸弹
cmd.FISH_XIANG_ZI				= 19							-- 补给箱
cmd.FISH_YUAN_BAO                    = 20                                        -- 元宝鱼

-- 鱼索引
cmd.FISH_KING_MAX				= 7								-- 最大灯笼鱼
cmd.FISH_NORMAL_MAX				= 18							-- 正常鱼索引
cmd.FISH_ALL_COUNT				= 21							-- 鱼最大数

-- 特殊鱼
cmd.SPECIAL_FISH_BOMB			= 0								-- 炸弹鱼
cmd.SPECIAL_FISH_CRAB			= 1								-- 螃蟹
cmd.SPECIAL_FISH_MAX			= 2								-- 最大数量

-- 渔网 
cmd.NET_COLOR_GREEN				= 0								-- 绿色网
cmd.NET_COLOR_BLUE				= 1								-- 蓝色网
cmd.NET_COLOR_YELLOW			= 2								-- 黄色网
cmd.NET_COLOR_RED				= 3								-- 红色网
cmd.NET_COLOR_PURPLE			= 4								-- 紫色网
cmd.NET_MAX_COLOR				= 5								-- 最大颜色数(随机值)

--语音
cmd.SPEECH_INDEX_MAX        = 9
-- 道具
cmd.PROP_ICE_NET				= 0								-- 冰网
cmd.PROP_BROKEN_ICE				= 1								-- 破冰器
cmd.PROP_CLOUDY_AGENT			= 2								-- 混浊剂
cmd.PROP_ARMOUR_PIERCING		= 3								-- 穿甲弹
cmd.PROP_EJECTION				= 4								-- 弹射弹
cmd.PROP_TRACKING				= 5								-- 追踪弹
cmd.PROP_SHOTGUN				= 6								-- 散弹
cmd.PROP_ACCELERA				= 7								-- 加速弹
cmd.PROP_COUNT_MAX				= 8								-- 总数




-- 倍数索引
cmd.MULTIPLE_MAX_INDEX			= 6	

cmd.S_TOP_LEFT					= 0								-- 服务器位置
cmd.S_TOP_CENTER				= 1								-- 服务器位置
cmd.S_TOP_RIGHT					= 2								-- 服务器位置
cmd.S_BOTTOM_LEFT				= 3								-- 服务器位置
cmd.S_BOTTOM_CENTER				= 4								-- 服务器位置
cmd.S_BOTTOM_RIGHT				= 5								-- 服务器位置

cmd.C_TOP_LEFT					= 0								-- 视图位置
cmd.C_TOP_CENTER				= 1								-- 视图位置
cmd.C_TOP_RIGHT					= 2								-- 视图位置
cmd.C_BOTTOM_LEFT				= 3								-- 视图位置
cmd.C_BOTTOM_CENTER				= 4								-- 视图位置
cmd.C_BOTTOM_RIGHT				= 5								-- 视图位置

-- 相对窗口
cmd.DEFAULE_WIDTH				= 1280						    -- 客户端相对宽
cmd.DEFAULE_HEIGHT				= 800							-- 客户端相对高	
cmd.OBLIGATE_LENGTH				= 300							-- 预留宽度

cmd.CAPTION_TOP_SIZE			= 25							-- 标题大小
cmd.CAPTION_BOTTOM_SIZE			= 40							-- 标题大小
 
 -- 音量
cmd.MAX_VOLUME     = 3000             
-- 炮弹
cmd.BULLET_ONE				= 0								-- 一号炮
cmd.BULLET_TWO				= 1								-- 二号炮
cmd.BULLET_THREE			= 2								-- 三号炮
cmd.BULLET_FOUR				= 3								-- 四号炮
cmd.BULLET_FIVE				= 4								-- 五号炮
cmd.BULLET_SIX				= 5								-- 六号炮
cmd.BULLET_SEVEN			= 6								-- 七号炮
cmd.BULLET_EIGHT			= 7								-- 八号炮
cmd.BULLET_MAX				= 8								-- 最大炮种类


-- 最大路径
cmd.BEZIER_POINT_MAX			= 10

--千炮消耗
cmd.QIAN_PAO_BULLET				= 1

--获取分数类型

--游戏玩家
cmd.PlayChair_Max 				= 6
cmd.PlayChair_Invalid			= 0xffff
cmd.PlayName_Len				  = 32
cmd.QianPao_Bullet     		= 1
cmd.Multiple_Max  				= 6

cmd.Tag_Fish              = 10
cmd.Tag_Bullet            = 11

cmd.Fish_MOVE_TYPE_NUM    = 26
cmd.Fish_DEAD_TYPE_NUM    = 22

--枚举
----------------------------------------------------------------------------------------------
cmd.TAG_START 					= 1

cmd.EST_Cold = 0
cmd.EST_Meadl = 1
cmd.EST_YuanBao = 2
cmd.EST_Laser = 3
cmd.EST_Bomb = 4
cmd.EST_Speed = 5
cmd.EST_Strong = 6
cmd.EST_Gift = 7
cmd.EST_Kill = 8
local enumScoreType =
{
	
	"EST_Cold",				--金币
      "EST_Meadl",                 --奖牌
      "EST_YuanBao",                --元宝
	"EST_Laser",			--激光
      "EST_Bomb",                --炸弹
      "EST_Speed",                 --加速
	"EST_Strong",			--强化
	"EST_Gift",				--赠送
      "EST_Kill",                     --杀手鱼
	"EST_NULL"
}

cmd.SupplyType =  ExternalFun.declarEnumWithTable(0,enumScoreType)

--房间类型
local enumRoomType = 
{
	"ERT_Unknown",						--无效
	"ERT_QianPao",						--千炮
	"ERT_Moni"							--模拟
}

cmd.RoomType = ExternalFun.declarEnumWithTable(0,enumRoomType)

local enumCannonType = 
{

  "Normal_Cannon", --正常炮
  "Bignet_Cannon",--网变大
  "Special_Cannon",--加速炮
  "Laser_Cannon",--激光炮
  "Laser_Shooting"--激光发射中
}
cmd.CannonType = ExternalFun.declarEnumWithTable(0,enumCannonType)

--道具类型
local enumPropObjectType =
{

	"POT_NULL",										-- 无效
	"POT_ATTACK",									-- 攻击
	"POT_DEFENSE",									-- 防御
	"POT_BULLET",									-- 子弹

}

cmd.PropObjectType = ExternalFun.declarEnumWithTable(0,enumPropObjectType)

--鱼类型
cmd.FishType = 
{
    FishType_XiaoHuangCiYu = 0,               -- 小黄刺鱼
    FishType_XiaoCaoYu = 1,                 --小草鱼
    FishType_ReDaiHuangYu = 2,                --热带黄鱼
    FishType_DaYanJinYu = 3 ,                 -- 大眼金鱼
    FishType_ReDaiZiYu = 4,                 -- 热带紫鱼
    FishType_XiaoChouYu = 5,                  -- 小丑鱼
    FishType_HeTun = 6,                   -- 河豚
    FishType_ShiTouYu = 7,                  -- 狮头鱼
    FishType_DengLongYu = 8,                  -- 灯笼鱼
    FishType_WuGui = 9,                   -- 乌龟
    FishType_ShengXianYu = 10,                  -- 神仙鱼
    FishType_HuDieYu = 11,                    -- 蝴蝶鱼
    FishType_LingDangYu = 12,                 -- 铃铛鱼
    FishType_JianYu = 13,                   -- 剑鱼
    FishType_MoGuiYu = 14 ,                   -- 魔鬼鱼
    FishType_DaBaiSha = 15 ,                  -- 大白鲨
    FishType_DaJinSha = 16,                 -- 大金鲨
    FishType_ShuangTouQiEn = 17,                -- 双头企鹅
    FishType_JuXingHuangJinSha = 18,              -- 巨型黄金鲨
    FishType_JinLong = 19 ,                   -- 金龙
    FishType_LiKui = 20,                    -- 李逵
    FishType_ShuiHuZhuan = 21,                  -- 水浒传
    FishType_ZhongYiTang = 22,                  -- 忠义堂
    FishType_BaoZhaFeiBiao = 23,                -- 爆炸飞镖
    FishType_BaoXiang = 24,                 -- 宝箱
    FishType_YuanBao = 25,                    -- 元宝鱼
    FishType_General_Max = 21,                  -- 普通鱼最大
    FishType_Normal_Max= 24,                  -- 正常鱼最大
    FishType_Max = 26,                      -- 最大数量
    FishType_Small_Max = 9,                 -- 小鱼最大索引
    FishType_Moderate_Max = 15,               -- 中鱼索
    FishType_Moderate_Big_Max = 18,             -- 中大鱼索
    FishType_Big_Max = 24,                    --大鱼索引
    FishType_Invalid  = -1                  --无效鱼
}
    
local enumFishState = 
{

	  "FishState_Normal",		-- 普通鱼
    "FishState_King",		-- 鱼王
    "FishState_Killer",		-- 杀手鱼
    "FishState_Aquatic",	-- 水草鱼
}
cmd.FishState = ExternalFun.declarEnumWithTable(0,enumFishState)
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--服务器命令结构

    cmd.SUB_S_SYNCHRONOUS 	= 101					-- 同步信息101
    cmd.SUB_S_FISH_CREATE	= 102					  -- 鱼创建102
    cmd.SUB_S_FAST_MOVE      = 103                            --快速移动
    cmd.SUB_S_FISH_CATCH  	= 104					-- 捕获鱼104
    cmd.SUB_S_FIRE		    = 105					  -- 开火105
    cmd.SUB_S_TRADE_BULLET       = 106                                  -- 换子弹106
    cmd.SUB_S_EXCHANGE_SCENE= 107					-- 转换场景107
    cmd.SUB_S_OVER          = 108    				-- 结算108
    cmd.SUB_S_FISH_FINISH = 109                         --创建完成109
    cmd.SUB_S_DELAY_BEGIN   = 110				-- 延迟110
    cmd.SUB_S_DELAY	    = 111					-- 延迟111
    cmd.SUB_S_USE_PROP = 112                            --道具
    cmd.SUB_S_BUY_PROP   = 113                           -- 购买道具
    cmd.SUB_S_SELECTED_PROP   = 114					-- 选中道具
    cmd.SUB_S_BEGIN_LASER	    = 115					-- 准备激光
    cmd.SUB_S_LASER		= 116					-- 激光
    cmd.SUB_S_BANK_TAKE		= 117					-- 银行取款117
    cmd.SUB_S_SPEECH           = 118
    cmd.SUB_S_SYSTEM		= 119					-- 系统消息119
    cmd.SUB_S_MULTIPLE		= 120					-- 倍数消息120
    cmd.SUB_S_SUPPLY_TIP	= 121					-- 补给提示121
    cmd.SUB_S_SUPPLY		= 122					-- 补给消息122
    cmd.SUB_S_AWARD_TIP		= 123					-- 分数提示123
    cmd.SUB_S_CONTROL		= 124					-- 控制消息124
    cmd.SUB_S_UPDATE_GAME	= 125					-- 更新游戏125
    cmd.SUB_S_ANDROID_CONFIG = 126              --机器人配置
    cmd.SUB_S_ANDROID_LEAVE = 127                     --机器人离场


-----------------------------------------------------------------------------------------------

--顶点
cmd.CDoulbePoint = 
{

	{k="x",t="double"},
	{k="y",t="double"}
}

cmd.ShortPoint = 
{

	{k="x",t="short"},
	{k="y",t="short"}
}

cmd.tagBezierPoint = 
{
 {k="BeginPoint",t="table",d=cmd.CDoulbePoint},
 {k="EndPoint",t="table",d=cmd.CDoulbePoint},
 {k="KeyOne",t="table",d=cmd.CDoulbePoint},
 {k="KeyTwo",t="table",d=cmd.CDoulbePoint},
 {k="Time",t="dword"}

}

--系统消息
cmd.CMD_S_System = 
{
  {k="dRoomIncome",t="double"},
  {k="dWholeTax",t="double"},
  {k="dTableInvest",t="double"},
  {k="dTableOutput",t="double"},
  {k="dPlayInvest",t="double"},
  {k="dPlayOutput",t="double"},
  {k="dTableIdle",t="double"},
}

--鱼创建
cmd.CMD_S_FishCreate = 
{
  {k="nFishKey",t="int"},
  {k="unCreateTime",t="int"},
  {k="unCreateDelay",t="int"},
  {k="wHitChair",t="word"},
  {k="nFishType",t="byte"},
  {k="bSpecial",t="bool"},
  {k="bKiller",t="bool"},
  {k="bRepeatCreate",t="bool"},
  {k="fRotateAngle",t="float"},
  {k="PointOffSet",t="table",d=cmd.ShortPoint},
  {k="nBezierCount",t="int"},
  {k="TBzierPoint",t="table",d=cmd.tagBezierPoint,l={cmd.BEZIER_POINT_MAX}}
}

--鱼创建完成
cmd.CMD_S_FishFinish = 
{
	{k="nOffSetTime",t="int"}
}

--捕获鱼
cmd.CMD_S_CatchFish = 
{
	{k="nFishIndex",t="int"},                          --鱼索引
	{k="wChairID",t="word"},                         --玩家位置
	{k="lScoreCount",t="score"},                    --获得数量
	{k="nScoreType",t="int"}  --获得类型
}

--开火
cmd.CMD_S_Fire = 
{
  {k="nBulletKey",t="int"},						-- 子弹关键值
  {k="nBulletScore",t="int"},					-- 子弹分数
  {k="cbBulletIndex",t="byte"},         -- 炮弹索引
  {k="nPropIndex",t="int"},					-- 倍数索引
  {k="nTrackFishIndex",t="int"},				-- 追踪鱼索引
  {k="crFishNetColoer",t="int"},        -- 追踪鱼索引
  {k="wChairID",t="word"},						-- 玩家位置
  {k="ptPos",t="table",d=cmd.ShortPoint}		-- 位置

}

--准备激光
cmd.CMD_S_BeginLaser = 
{

  {k="wChairID",t="word"},
  {k="ptPos",t="table",d=cmd.ShortPoint}  
}

--激光
cmd.CMD_S_Laser = 
{
  {k="wChairID",t="word"},
  {k="ptPos",t="talbe",d=cmd.ShortPoint}

}

--激光奖励
cmd.CMD_S_LaserReward = 
{
  {k="wChairID",t="word"},
  {k="lScore",t="score"},
}

--换炮台
cmd.CMD_S_TradeBullet = 
{
  {k="wChairID",t="word"},
  {k="cbBulletIndex",t="byte"},
}

--换网颜色
cmd.CMD_S_TradeNetColor = 
{
  {k="wChairID",t="word"},
  {k="cbNetColorIndex",t="byte"},
}

--转换场景
cmd.CMD_S_ExchangeScene = 
{
  {k="cbBackIndex",t="byte"},
}

--结算
cmd.CMD_S_Over = 
{
  {k="wChairID",t="word"},
}

--延迟
cmd.CMD_S_Delay = 
{
  {k="nDelay",t="int"},
  {k="wChairID",t="word"},
}

--选中道具
cmd.CMD_S_SelectedProp = 
{
  {k="wChairID",t="word"},
  {k="nPropIndex",t="int"},
}

--使用道具
cmd.CMD_S_UseProp = 
{
  {k="wUseChairID",t="word"},
  {k="wTargetChairID",t="word"},
  {k="nPropIndex",t="int"},
}

--购买道具
cmd.CMD_S_BuyProp = 
{
  {k="wChairID",t="word"},
  {k="nPropCount",t="int"},
  {k="nPropIndex",t="int"},
  {k="lPropScore",t="score"},
}

--银行去看
cmd.CMD_S_BankTake = 
{
  {k="wChairID",t="word"},
  {k="lPlayScore",t="score"},
}

--语音消息
cmd.CMD_S_Speech = 
{
  {k="wChairID",t="word"},
  {k="nSpeechIndex",t="int"},
}

--倍数选择
cmd.CMD_S_Multiple = 
{
  {k="wChairID",t="word"},
  {k="nMultipleIndex",t="int"}
}

--补给提示
cmd.CMD_S_SupplyTip = 
{
  {k="wChairID",t="word"}
}

--补给信息
cmd.CMD_S_Supply = 
{
  {k="wChairID",t="word"},
  {k="lSupplyCount",t="score"},
  {k="nSupplyType",t="int"},
  {k="PointSupply",t="table",d=cmd.ShortPoint}
}

--提示消息
cmd.CMD_S_AwardTip = 
{
  {k="wTableID",t="word"},
  {k="wChairID",t="word"},
  {k="szPlayName",t="string",s=32},
  {k="nFishType",t="byte"},
  {k="nFishMultiple",t="int"},
  {k="lFishScore",t="score"},
  {k="nScoreType",t="int"}
}

--更新游戏
cmd.CMD_S_UpdateGame = 
{
  {k="nMultipleValue",t="int",l={cmd.Multiple_Max}},
  {k="nCatchFishMultiple",t="int",l={2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}},
  {k="bUnlimitedRebound",t="bool"},
  {k="nBulletVelocity",t="int"},
  {k="nBulletCoolingTime",t="int"},
  {k="nMaxTipCount",t="int"}
}


--场景信息
cmd.GameScene = 
{
  {k="nRoomType",t="int"},
  {k="cbBackIndex",t="byte"},
  {k="lPlayScore",t="score"},
  {k="lPlayCurScore",t="score",l={cmd.GAME_PLAYER}},
  {k="lPlayStartScore",t="score",l={cmd.GAME_PLAYER}},
  {k="cbPlayBulletIndex",t="byte",l={cmd.GAME_PLAYER}},

  {k="lBuyBulletMoney",t="int",l={cmd.BULLET_MAX}},
  {k="nBulletVelocity",t="int",l={cmd.BULLET_MAX}},
  {k="nBulletCoolingTime",t="int",l={cmd.BULLET_MAX}},
  {k="nBulletRange",t="int",l={cmd.BULLET_MAX}},
  {k="nBulletScope",t="int",l={cmd.BULLET_MAX}},
  {k="nFishMultiple",t="int",l={2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}},
  {k="lCellScore",t="int"},
  {k="nPlayPropIndex",t="int",l={cmd.GAME_PLAYER}},
  {k="nPropConsume",t="int",l={cmd.PROP_COUNT_MAX}},
  {k="nPropCount",t="int",l={cmd.PROP_COUNT_MAX}},
  {k="lBulletConsume",t="score",l={cmd.GAME_PLAYER}},
  {k="lPropAcquire",t="score",l={cmd.GAME_PLAYER}},
  {k="lPlayFishCount",t="int",l={6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6}},
  {k="llPlayBulletCount",t="int",l={6,6,6,6,6,6,6,6}},
  {k="llPlayBulletMoney",t="int",l={6,6,6,6,6,6,6,6}},
  {k="szBrowseUrl",t="string",s=256},
  {k="wCanAcceptNumber",t="word"},
  {k="nMultipleValue",t="int",l={cmd.MULTIPLE_MAX_INDEX}},
  {k="nMultipleIndex",t="int"},
  {k="bCanSetMultiple",t="bool"},
  {k="bUnlimitedRebound",t="bool"},
  {k="lIngotCount",t="score"},
  {k="nMaxTipCount",t="int"},
  
 -- {k="lIngnetCount",t="score"}
}
----------------------------------------------------------------------------------------------
--客户端命令结构
cmd.SUB_C_CATCH_FISH = 101              --捕鱼信息
cmd.SUB_C_FIRE       = 102              --开火
cmd.SUB_C_BUY_BULLET = 103       --更换子弹
cmd.SUB_C_DELAY      = 104              -- 延迟
cmd.SUB_C_USE_PROP = 105             -- 道具
cmd.SUB_C_BUY_PROP = 106             --购买道具
cmd.SUB_C_SELECTED_PROP = 107             --选中道具
cmd.SUB_C_BEGIN_LASER= 108              -- 准备激光
cmd.SUB_C_LASER      = 109              -- 激光
cmd.SUB_C_FISH_BOMB = 110           --炸弹爆炸
cmd.SUB_C_SPEECH     = 111              -- 语音消息
cmd.SUB_C_MULTIPLE   = 112              -- 倍数消息
cmd.SUB_C_CONTROL = 113                 --控制消息
cmd.SUB_C_MISS_BULLET = 114               --子弹消失
cmd.SUB_C_APPLY_LEAVE = 115               --申请离开




-----------------------------------------------------------------------------------------------

print("********************************************************load cmd");
return cmd
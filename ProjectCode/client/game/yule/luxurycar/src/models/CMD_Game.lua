--
-- Author: Tang
-- Date: 2016-10-11 17:21:32

--豪车俱乐部
--
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd  = {}

--游戏版本
cmd.VERSION  			= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID				= 140
--游戏人数
cmd.GAME_PLAYER   		= 100
--房间名长度
cmd.SERVER_LEN			= 32

--状态定义
cmd.GS_GAME_FREE		= 0
cmd.GS_PLACE_JETTON     = 100   --下注状态
cmd.GS_GAME_END			= 101   --结束状态
cmd.GS_MOVECARD_END		= 102	--结束状态


--区域索引
cmd.ID_MASERATI         = 1		--玛莎拉蒂
cmd.ID_FERRARI			= 2		--法拉利
cmd.ID_LAMBORGHINI		= 3		--兰博基尼
cmd.ID_PORSCHE			= 4		--保时捷
cmd.ID_LANDROVER		= 5		--路虎		
cmd.ID_BMW				= 6		--宝马
cmd.ID_JAGUAR			= 7		--捷豹
cmd.ID_BENZ				= 8		--奔驰

cmd.AREA_MASERATI       = 0
cmd.AREA_FERRARI		= 1
cmd.AREA_LAMBORGHINI	= 2
cmd.AREA_PORSCHE		= 3
cmd.AREA_LANDROVER		= 4
cmd.AREA_BMW			= 5
cmd.AREA_JAGUAR			= 6
cmd.AREA_BENZ			= 7


cmd.AREA_COUNT		    = 8
cmd.AREA_ALL			= 8
cmd.JETTON_COUNT		= 7
cmd.ANIMAL_COUNT        = 16

cmd.RATE_TWO_PAIR		= 12

cmd.CLOCK_FREE			= 1
cmd.CLOCK_ADDGOLD		= 2
cmd.CLOCK_AWARD			= 3

cmd.RECORD_MAX			= 8

--记录信息
cmd.tagServerGameRecord = 
{
	{k = "cbCarIndex",t = "byte"}
}

------------------------------------------------------------------------------------------------
--服务器命令结构

cmd.SUB_S_GAME_FREE					=99										--游戏空闲
cmd.SUB_S_GAME_START				=100									--游戏开始
cmd.SUB_S_PLACE_JETTON				=101									--用户下注
cmd.SUB_S_GAME_END					=102									--游戏结束
cmd.SUB_S_APPLY_BANKER				=103									--申请庄家
cmd.SUB_S_CHANGE_BANKER				=104									--切换庄家
cmd.SUB_S_CHANGE_USER_SCORE			=105									--更新积分
cmd.SUB_S_SEND_RECORD				=106									--游戏记录
cmd.SUB_S_PLACE_JETTON_FAIL			=107									--下注失败
cmd.SUB_S_CANCEL_BANKER				=108									--取消申请
cmd.SUB_S_ADMIN_COMMDN				=110									--系统控制
cmd.SUB_S_WAIT_BANKER				=111									--等待上庄
cmd.SUB_S_ROBOT_BANKER          	=112                                	 --机器人


--失败结构
cmd.CMD_S_PlaceJettonFail	=
{
	{k="wPlaceUser",t="word"}, 			--下注玩家
	{k="cbJettonArea",t="byte"},			--下注区域
	{k="lPlaceScore",t="score"}			--当前下注						
};

--更新积分
cmd.CMD_S_ChangeUserScore	=
{

	{k="wChairID",t="word"},				--椅子号码
	{k="lScore",t="double"},				--玩家积分
	{k="wCurrentBankerChairID",t="word"},	--当前庄家
	{k="cbBankerTime",t="byte"},			--庄家局数
	{k="lCurrentBankerScore",t="double"}	--庄家分数		
};

--申请庄家
cmd.CMD_S_ApplyBanker =
{
	{k="wApplyUser",t="word"}		--申请玩家					
};

--取消申请
cmd.CMD_S_CancelBanker =
{
	{k="wCancelUser",t="word"}		--取消玩家					
};

--切换庄家
cmd.CMD_S_ChangeBanker = 
{	
	{k="wBankerUser",t="word"},		--当庄玩家
	{k="lBankerScore",t="score"}	--庄家金币				
};

--游戏状态
cmd.CMD_S_StatusFree = 
{
	--全局信息
	{k="cbTimeLeave",t="byte"},		--剩余时间					
	--玩家信息
	{k="lUserMaxScore",t="score"},	--玩家金币
					
	--庄家信息
	{k="wBankerUser",t="word"},		--当前庄家
	{k="cbBankerTime",t="word"},	--庄家局数
	{k="lBankerWinScore",t="score"},--庄家成绩
	{k="lBankerScore",t="score"},	--庄家分数
	{k="bEnableSysBanker",t="bool"},--系统做庄

	--控制信息
	{k="lApplyBankerCondition",t="score"}, --申请条件
	{k="lAreaLimitScore",t="score"},	   --区域限制
	{k="szGameRoomName",t="string",s=32},
	{k="szRoomTotalName",t="string",s=256},
	{k="nMultiple",t="int"}

};

--游戏状态
cmd.CMD_S_StatusPlay =
{
	--全局下注
	{k="lAllJettonScore",t="score",l={cmd.AREA_COUNT+1}}, 			--全体总注
	{k="lUserJettonScore",t="score",l={cmd.AREA_COUNT+1}},			--个人总注

	--玩家积分
	{k="lUserMaxScore",t="score"},									--最大下注
												
	--控制信息
	{k="lApplyBankerCondition",t="score"},							--申请条件
	{k="lAreaLimitScore",t="score"},								--区域限制
	
	{k="cbStopIndex",t="byte"},										--开奖位置
			
	--庄家信息
	{k="wBankerUser",t="word"},										--当前庄家
	{k="cbBankerTime",t="word"},									--庄家局数
	{k="lBankerWinScore",t="score"},								--庄家赢分
	{k="lBankerScore",t="score"},									--庄家分数
	{k="bEnableSysBanker",t="bool"},								--系统做庄
	

	--结束信息
	{k="lEndBankerScore",t="score"},								--庄家成绩
	{k="lEndUserScore",t="score"},									--玩家成绩
	{k="lEndUserReturnScore",t="score"},							--返回积分
	{k="lEndRevenue",t="score"},									--游戏税收
					
	
	--全局信息
	{k="cbTimeLeave",t="byte"},										--剩余时间
	{k="cbGameStatus",t="byte"},										--游戏状态

	{k="szGameRoomName",t="string",s=32},
	{k="szRoomTotalName",t="string",s=256},
	{k="nMultiple",t="int"}
					
};

--游戏空闲
cmd.CMD_S_GameFree = 
{
	{k="cbTimeLeave",t="byte"},										--剩余时间
	{k="lStorageCurrent",t="score"}
};

--游戏开始
cmd.CMD_S_GameStart = 
{
	{k="wBankerUser",t="word"},										--庄家位置
	{k="lBankerScore",t="score"},									--庄家金币
	{k="lUserMaxScore",t="score"},										
	{k="cbTimeLeave",t="byte"},										--剩余时间	
	{k="bContiueCard",t="bool"},									--继续发牌
	{k="nChipRobotCount",t="int"},									--人数上限 (下注机器人)
	{k="nAndriodCount",t="int"}										--机器人人数
			
};

--用户下注
cmd.CMD_S_PlaceJetton = 
{

	{k="wChairID",t="word"},										--用户位置
	{k="cbJettonArea",t="byte"},									--筹码区域
	{k="lJettonScore",t="score"},									--加注数目
	{k="cbAndroid",t="byte"}										--机器人
							
};

--游戏结束
cmd.CMD_S_GameEnd = 
{
	--下局信息
	{k="cbTimeLeave",t="byte"},										--剩余时间				

	--停止位置
	{k="cbStopIndex",t="byte"},										--桌面扑克

	--庄家信息
	{k="lBankerScore",t="score"},									--庄家成绩
	{k="lBankerTotallScore",t="score"},								--庄家成绩
	{k="nBankerTime",t="int"},										--做庄次数
					

	--玩家成绩
	{k="lUserScore",t="score"},										--玩家成绩
	{k="lUserReturnScore",t="score"},								--返回积分				

	--全局信息
	{k="lRevenue",t="score"}										--游戏税收
						
};

---------------------------------------------------------------------------------------------------------------
--客户端命令结构

cmd.SUB_C_PLACE_JETTON				=11									--用户下注
cmd.SUB_C_APPLY_BANKER				=12									--申请庄家
cmd.SUB_C_CANCEL_BANKER				=13									--取消申请
cmd.SUB_C_CLEAR_JETTON		    	=14									--清除下注

--用户下注
cmd.CMD_C_PlaceJetton = 
{
	{k="cbJettonArea",t="byte"}, 		--筹码区域
	{k="lJettonScore",t="score"}		--加注数目		
};


------------------------------------------------------------------------------------------------------------------
--按钮类型
cmd.Apply 		= 1		--申请
cmd.Jettons 	= 2		--下注
cmd.Continue 	= 3		--续压

------------------------------------------------------------------------------------------------------------------



return cmd
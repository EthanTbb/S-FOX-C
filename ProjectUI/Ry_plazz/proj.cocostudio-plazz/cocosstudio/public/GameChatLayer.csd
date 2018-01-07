<GameFile>
  <PropertyGroup Name="GameChatLayer" Type="Layer" ID="441c5e2e-2f8b-4453-9829-1d172c6b4f75" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.0000" />
      <ObjectData Name="Layer" ctype="GameLayerObjectData">
        <Size X="1334.0000" Y="750.0000" />
        <Children>
          <AbstractNodeData Name="Panel_1" ActionTag="171595120" Tag="2" IconVisible="False" PercentWidthEnable="True" PercentHeightEnable="True" PercentWidthEnabled="True" PercentHeightEnabled="True" LeftMargin="-1.7525" RightMargin="1.7526" TopMargin="-0.8763" BottomMargin="0.8763" ClipAble="False" BackColorAlpha="76" ComboBoxIndex="1" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
            <Size X="1334.0000" Y="750.0000" />
            <AnchorPoint />
            <Position X="-1.7525" Y="0.8763" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="-0.0013" Y="0.0012" />
            <PreSize X="1.0000" Y="1.0000" />
            <SingleColor A="255" R="0" G="0" B="0" />
            <FirstColor A="255" R="150" G="200" B="255" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="chat_bg" ActionTag="315933839" Tag="3" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="332.0000" RightMargin="332.0000" TopMargin="151.0000" BottomMargin="151.0000" ctype="SpriteObjectData">
            <Size X="670.0000" Y="448.0000" />
            <Children>
              <AbstractNodeData Name="btn_close" ActionTag="1057601345" Tag="8" IconVisible="False" LeftMargin="611.9991" RightMargin="-19.9991" TopMargin="-19.9762" BottomMargin="389.9762" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="8" RightEage="8" TopEage="7" BottomEage="7" Scale9OriginX="8" Scale9OriginY="7" Scale9Width="62" Scale9Height="64" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
                <Size X="78.0000" Y="78.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="650.9991" Y="428.9762" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.9716" Y="0.9575" />
                <PreSize X="0.1164" Y="0.1741" />
                <TextColor A="255" R="65" G="65" B="70" />
                <DisabledFileData Type="PlistSubImage" Path="chat_close.png" Plist="plaza/plaza.plist" />
                <PressedFileData Type="PlistSubImage" Path="chat_close_0.png" Plist="plaza/plaza.plist" />
                <NormalFileData Type="PlistSubImage" Path="chat_close.png" Plist="plaza/plaza.plist" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
              <AbstractNodeData Name="text_check" ActionTag="-1105486012" Tag="5" IconVisible="False" PositionPercentXEnabled="True" LeftMargin="84.6000" RightMargin="348.4000" TopMargin="19.5000" BottomMargin="361.5000" TouchEnable="True" ctype="CheckBoxObjectData">
                <Size X="237.0000" Y="67.0000" />
                <AnchorPoint ScaleX="1.0000" ScaleY="0.5000" />
                <Position X="321.6000" Y="395.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.4800" Y="0.8817" />
                <PreSize X="0.3537" Y="0.1496" />
                <NormalBackFileData Type="PlistSubImage" Path="chat_texts_1.png" Plist="plaza/plaza.plist" />
                <PressedBackFileData Type="PlistSubImage" Path="chat_texts_1.png" Plist="plaza/plaza.plist" />
                <DisableBackFileData Type="PlistSubImage" Path="chat_texts_1.png" Plist="plaza/plaza.plist" />
                <NodeNormalFileData Type="PlistSubImage" Path="chat_texts_0.png" Plist="plaza/plaza.plist" />
                <NodeDisableFileData Type="PlistSubImage" Path="chat_texts_0.png" Plist="plaza/plaza.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="record_check" ActionTag="-1729482646" Tag="7" IconVisible="False" PositionPercentXEnabled="True" LeftMargin="348.4001" RightMargin="84.6000" TopMargin="19.5000" BottomMargin="361.5000" TouchEnable="True" ctype="CheckBoxObjectData">
                <Size X="237.0000" Y="67.0000" />
                <AnchorPoint ScaleY="0.5000" />
                <Position X="348.4001" Y="395.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.5200" Y="0.8817" />
                <PreSize X="0.3537" Y="0.1496" />
                <NormalBackFileData Type="PlistSubImage" Path="chat_record_1.png" Plist="plaza/plaza.plist" />
                <PressedBackFileData Type="PlistSubImage" Path="chat_record_1.png" Plist="plaza/plaza.plist" />
                <DisableBackFileData Type="PlistSubImage" Path="chat_record_1.png" Plist="plaza/plaza.plist" />
                <NodeNormalFileData Type="PlistSubImage" Path="chat_record_0.png" Plist="plaza/plaza.plist" />
                <NodeDisableFileData Type="PlistSubImage" Path="chat_record_0.png" Plist="plaza/plaza.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="chat_area" ActionTag="1687085194" Tag="4" IconVisible="False" PositionPercentXEnabled="True" LeftMargin="36.5001" RightMargin="36.4999" TopMargin="91.0000" BottomMargin="103.0000" ctype="SpriteObjectData">
                <Size X="597.0000" Y="254.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="335.0001" Y="230.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.5000" Y="0.5134" />
                <PreSize X="0.8910" Y="0.5670" />
                <FileData Type="PlistSubImage" Path="chat_his.png" Plist="plaza/plaza.plist" />
                <BlendFunc Src="1" Dst="771" />
              </AbstractNodeData>
              <AbstractNodeData Name="edit_frame" ActionTag="-1713428463" Tag="10" IconVisible="False" LeftMargin="41.0984" RightMargin="215.9016" TopMargin="352.9254" BottomMargin="34.0747" ctype="SpriteObjectData">
                <Size X="413.0000" Y="61.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="247.5984" Y="64.5747" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.3695" Y="0.1441" />
                <PreSize X="0.6164" Y="0.1362" />
                <FileData Type="PlistSubImage" Path="chag_frame.png" Plist="plaza/plaza.plist" />
                <BlendFunc Src="1" Dst="771" />
              </AbstractNodeData>
              <AbstractNodeData Name="btn_send" ActionTag="-1524604112" Tag="11" IconVisible="False" LeftMargin="472.9000" RightMargin="40.1000" TopMargin="357.3529" BottomMargin="33.6471" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="8" RightEage="8" TopEage="7" BottomEage="7" Scale9OriginX="8" Scale9OriginY="7" Scale9Width="141" Scale9Height="43" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
                <Size X="157.0000" Y="57.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="551.4000" Y="62.1471" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.8230" Y="0.1387" />
                <PreSize X="0.2343" Y="0.1272" />
                <TextColor A="255" R="65" G="65" B="70" />
                <DisabledFileData Type="PlistSubImage" Path="chat_send.png" Plist="plaza/plaza.plist" />
                <PressedFileData Type="PlistSubImage" Path="chat_send_1.png" Plist="plaza/plaza.plist" />
                <NormalFileData Type="PlistSubImage" Path="chat_send.png" Plist="plaza/plaza.plist" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="667.0000" Y="375.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.5000" />
            <PreSize X="0.5022" Y="0.5973" />
            <FileData Type="PlistSubImage" Path="chat_bg.png" Plist="plaza/plaza.plist" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>
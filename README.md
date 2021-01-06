# Pogu Tables
## mastery
### Key Name
```mastrty:<uuid>```
### 기본값:
```
{

}
```
## chating_data
채팅에 관한 설정을 저장함
### Key Name
```chating_data:<uuid>```
### 기본값:
```
{
  "channel": "general", //  general|local|guild|admin
  "en_ko": "false",
  "selected_badge": null
  }
```
## setting_data
옵션이나 기타 데이터 관한 설정을 저장함
### Key Name
```setting_data:<uuid>```
### 기본값:
```
{
  "interface": {
    "resolution": 427,
    "hand": "right"
  },
  "chating": {
    "type": "general", // general|messenger
    "alignment": "none", // none|center|left|right
    "listening": {
      "general": true,
      "local": true,
      "guild": true,
      "admin": true
    },
    "observer_mode": false
  },
  "sound": {
    "chating": false
    "mention": true
  }
  "is_premium": false
}
```
# BungeeCord SubChannels of Forward Channel
## PlayerChatEvent
### 값
```
{
  "player": "채팅 입력한 플레이어",
  "message": "플레이어가 입력한 (enko 변환까지 된)메시지",
  "channel": "플레이어의 채널"
  "badge": "플레이어의 뱃지",
  "mentions": [],
  "item": {
    "name": "채팅에 표기될 아이템특문",
    "display": "해당 특문에 마우스 올렸을 때, 보여질 아이템 이름",
    "lore": [
      "해당 특문에 마우스 올렸을 때",
      "보여질 아이템 설명들"
    ]
  }
}
```
## PlayerStateChangeEvent
### 값
```
{
  "player": "플레이어 이름",
  "uuid": "플레이어 UUID",
  "type" "다양한 타입이 존재함"
}
```
### 타입 종류
#### join_by_logging_in
서버에 입장할시, 해당 플레이어가 서버에 들어왔으므로,
각각의 서버 유저 목록에 해당 플레이어를 추가 해야 한다는 것을 알림.
#### verify_resourcepack
서버 입장한 플레이어는 리소스팩 인증을 해야하는데, 리팩 인증을 완료한 플레이어만 채팅을 받거나 호출을 받거나 할수 있음,
인증 완료시, 모든 서버로 해당 플레이어가 채팅 및 호출을 받을수 있다는 것을 인식 할수 있도록 알림
#### shift
서버를 이동할려고 할시, 해당 플레이어가 서버 이동중이라는 상태로 변경하여
이동중엔 메시지나 호출을 받지 못하게 하며,
이동 완료시, 서버 이동으로 서버에 접속한건지 서버에 그냥 로그인 한건지 구별하기 위해 이동 시도시, 미리 알림
#### join_by_shifting
서버 이동 완료시, 성공적으로 이동 완료하여 서버에 접속했다는것을 알림
#### quit
접속 종료하여 각각의 서버 목록에서 해당 플레이어 데이터를 지워야 한다는것을 알림
이거 알릴땐 이미 플레이어 나간 이후라서
해당 플레이어로 플러그인 메시지 보내면 오프라인 플레이어라서 못 보내기 때문에
서버당 하나씩 배치한 임시 플레이어로 해당 플러그인 메시지를 보내야함
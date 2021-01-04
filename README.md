# Pogu Tables
## state
### KEY
```state:<uuid>```
### VALUE
서버에 입장할 시, ```verifing```
리소스팩 인증을 완료할 시, ```none```

서버를 이동할 시, ```shifting```
서버 이동한 후, ```none```

이동된 서버기준으로는 이동 여부에 상관 없이, ```player_join``` 이벤트가 똑같이 발동되기 때문에
```shifting``` 상태일 시, 리소스팩 인증 요청 및 인증 수락과정 없이 바로 인증 완료된 상태가 됨

타 플긴에서 플레이어 이동 할때 state.<uuid> 의 값을 ```shifting```으로 설정'만'해주세요
이후 서버 이동 후 ```none```로 바꾸는건 커헬에서 함

## mastery
```mastrty:<uuid>``` 처럼 키를 작성하며 기본값은 ```{}```

# BungeeCord SubChannel of Forward Channel
## Chat
### VALUE
```
{
  "player": "채팅 입력한 플레이어",
  "message": "플레이어가 입력한 (enko 변환까지 된)메시지",
  "channel": "플레이어의 채널"
  "badge": "플레이어의 뱃지",
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



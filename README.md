# CommandHelper
## Pogu Tables
### state
#### KEY
```state:<uuid>```
#### VALUE
서버에 입장할 시, ```verifing```
리소스팩 인증을 완료할 시, ```none```

서버를 이동할 시, ```shifting```
서버 이동한 후, ```none```

이동된 서버기준으로는 이동 여부에 상관 없이, ```player_join``` 이벤트가 똑같이 발동되기 때문에
```shifting``` 상태일 시, 리소스팩 인증 요청 및 인증 수락과정 없이 바로 인증 완료된 상태가 됨

타 플긴에서 플레이어 이동 할때 state.<uuid> 의 값을 ```shifting```으로 설정'만'해주세요
이후 서버 이동 후 ```none```로 바꾸는건 커헬에서 함

### mastery

```mastrty:<uuid>``` 처럼 키를 작성하며 기본값은 ```{}```
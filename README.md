# CommandHelper
## Pogu Tables
* state
state:<uuid> 처럼 키를 작성하며 기본값은 None

서버에 입장할 시, Verifing 상태가 되며
리소스팩 인증을 완료할 시, None로 돌아옴

서버를 이동할 시, Shifting 상태가 되며
서버 이동한 후, None로 돌아옴

이동된 서버기준으로는 이동 여부에 상관 없이, player_join 이벤트가 똑같이 발동되기 때문에
Shifting 상태일 시, 리소스팩 인증 요청 및 인증 수락과정 없이 바로 인증 완료된 상태가 됨


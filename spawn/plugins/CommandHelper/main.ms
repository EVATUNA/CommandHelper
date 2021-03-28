## Channel Register
if(!is_channel_registered('BungeeCord')) {
  register_channel('BungeeCord')
}

## Includes
# 데이터 처리, 프로시저 등록
include('includes/gameplay/main.ms')
include('includes/chat/main.ms')

## Final Include
# 이벤트, 테스크 바인드(프로시저 불러오기)
include('includes/data/main.ms')
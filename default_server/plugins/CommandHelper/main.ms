## Includes
# 데이터 처리, 프로시저 등록
#include('includes/gameplay/main.ms')
#include('includes/tip/main.ms')
#include('includes/chat/main.ms')
#include('includes/shop/main.ms')
#include('includes/gui/main.ms')
#include('includes/command/main.ms')

## Final Include
# 이벤트, 테스크 바인드(프로시저 불러오기)
#include('includes/data/main.ms')

@p = 'aaaa__'
broadcast(bukkitlinked_get_all_players())
broadcast(bukkitlinked_get_player_uuid(@p))
broadcast(bukkitlinked_get_player_name(puuid(@p)))

broadcast(bukkitlinked_is_player_op(puuid(@p)))
bukkitlinked_send_message(@p, 'asdf')
#bukkitlinked_connect_to_server(@p, 'main')
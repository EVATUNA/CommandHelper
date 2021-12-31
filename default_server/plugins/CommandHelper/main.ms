### Low Includes (auto_include.ms)

# gui 통합 시스템
include('includes/gui.ms')
# 스킬, 아이템 업데이트 시스템
include('includes/gameplay.ms')
# 플레이어 데이터 시스템
include('includes/data.ms')


### Normal Includes

# 몹 보상 처리
include('includes/mob/mob.ms')
# 야생(오버, 네더, 엔드 등)월드의 채광 시스템
include('includes/mining/mining.ms')
# 거주월드의 농사 시스템
include('includes/farming/farming.ms')
# 거주월드의 사냥 시스템
#include('includes/hunting/hunting.ms')
# 거주월드의 낚시 시스템
#include('includes/fishing/fishing.ms')

# 채팅 시스템
include('includes/chat.ms')
# 치장 시스템
#include('includes/decoration/decoration.ms')
# 상점 시스템
include('includes/shop/shop.ms')
# 명령어 시스템
include('includes/command.ms')


### High Include

# 이벤트, 테스크 바인드
include('includes/event.ms')
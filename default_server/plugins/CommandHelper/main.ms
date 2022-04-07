### Includes

# GUI 시스템
proc _gui_exists(@id) {
  return(array_contains(get_virtual_inventories(), @id))
}

bind('inventory_close', null, array('virtual': true), @event) {
  @player = @event['player']
  @id = pinventory_holder(@player)
  set_timeout(1, closure() {
    #if(has_bind("open.@id")) { unbind("open.@id") } #의미 없음
    if(has_bind("click.@id")) { unbind("click.@id") }
    if(has_bind("drag.@id")) { unbind("drag.@id") }
    if(has_bind("close.@id")) { unbind("close.@id") }
    if(_gui_exists(@id)) { delete_virtual_inventory(@id) }
  })
}

proc _show_gui(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure) {
  @id = @player.'.'.@gui_id.'.'.time()
  create_virtual_inventory(@id, @type, color('white').@texture_layer._color('#404040').@message, @inventory)
  @closure_arguments = array_merge(array(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id), array_get(@arguments, cslice(7, array_size(@arguments) - 1)))
  #기본 클로저 setter 인수: closure(@player, @gui_id, @type, @texture_layer, @message, @inventory, @closure, @id) @id 뒤에 추가로 기입 가능
  execute_array(@closure_arguments, @closure)
  popen_inventory(@player, @id)
}

proc _close_all_gui() {
  foreach(@id in get_virtual_inventories()) {
    foreach(@player in get_inventory_viewers(@id)) {
      close_pinv(@player)
    }
  }
}

# 로깅 시스템
include('includes/log/log.ms')

# 아이템 관리 시스템
include('includes/item/item.ms')

# 스킬 시스템
include('includes/skill/skill.ms')

# 튜나레벨 시스템
include('includes/level.ms')

# 인첸트 시스템
include('includes/enchant/enchant.ms')

# 수리
//
# 레벨변환
//

# 조합 시스템
include('includes/crafting/crafting.ms')

# 플레이어 데이터 시스템
include('includes/data.ms')

# 월드 시스템 (데스패널티, 필드효과)
include('includes/world_system/world_system.ms')

# 스폰 이벤트 (황금돼지, 랜덤텔포)
include('includes/spawn_region/spawn_region.ms')

# 야생월드의 채광 시스템
include('includes/mining/mining.ms')
# 야생월드의 벌목 시스템
#include('includes/lumbering/lumbering.ms')

# 거주월드의 농사 시스템
include('includes/farming/farming.ms')
# 거주월드의 사냥 시스템
include('includes/hunting/hunting.ms')
# 거주월드의 낚시 시스템
include('includes/fishing/fishing.ms')

# 음식 시스템
include('includes/food/food.ms')

# 음악 시스템
include('includes/music/music.ms')

# 몹 시스템
include('includes/mob/mob.ms')

# 채팅 시스템
include('includes/chat.ms')
# 오토퀴즈 시스템
include('includes/autoquiz/autoquiz.ms')
# 치장 시스템
#include('includes/decoration/decoration.ms')
# 상점 시스템
include('includes/shop/shop.ms')
# 떠상 시스템
include('includes/wandering_trader/wandering_trader.ms')

### High Include

# 이벤트, 테스크 바인드
include('includes/event.ms')

# 명령어 시스템
include('includes/command.ms')
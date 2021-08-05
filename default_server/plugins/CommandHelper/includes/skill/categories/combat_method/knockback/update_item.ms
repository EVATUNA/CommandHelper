# proc 내부에서 사용 가능한 변수:
# @player_data, @player, @uuid,
# @skill, @skill_spec, @point,
# @item, @vanilla_enchants

proc("_apply_item_update_by_@skill", @player_data, @player, @uuid, @skill, @skill_spec, @point, @item, @vanilla_enchants) {
  @melee_weapons = array(
    'WOODEN_SWORD',
    'WOODEN_SHOVEL',
    'WOODEN_PICKAXE',
    'WOODEN_AXE',
    'WOODEN_HOE',
    'STONE_SWORD',
    'STONE_SHOVEL',
    'STONE_PICKAXE',
    'STONE_AXE',
    'STONE_HOE',
    'GOLDEN_SWORD',
    'GOLDEN_SHOVEL',
    'GOLDEN_PICKAXE',
    'GOLDEN_AXE',
    'GOLDEN_HOE',
    'IRON_SWORD',
    'IRON_SHOVEL',
    'IRON_PICKAXE',
    'IRON_AXE',
    'IRON_HOE',
    'DIAMOND_SWORD',
    'DIAMOND_SHOVEL',
    'DIAMOND_PICKAXE',
    'DIAMOND_AXE',
    'DIAMOND_HOE',
    'NETHERITE_SWORD',
    'NETHERITE_SHOVEL',
    'NETHERITE_PICKAXE',
    'NETHERITE_AXE',
    'NETHERITE_HOE',
    'TRIDENT',
    'SHIELD',
  )
  if(array_contains(@melee_weapons, @item['name']) ) {
    @knockback = @skill_spec['effect_by_point'][@point]['passive']['knockback']
    if(array_index_exists(@vanilla_enchants, 'knockback')) {
      @vanilla_enchants['knockback']['elevel'] += @knockback
    } else {
      @vanilla_enchants['knockback'] = array(
        'etype': 'KNOCKBACK',
        'elevel': @knockback
      )
    }
  }
}
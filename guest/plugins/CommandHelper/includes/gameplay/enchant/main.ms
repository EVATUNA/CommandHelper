console('EvaEnchant loaded')

## Essence Data Load
@essences = array()
foreach(@file in list_files('essence_tables')) {
  @essence = replace(@file, '.json', '')
  async_read('essence_tables/'.@file, closure(@data) {
    @essences[@essence] = json_decode(@data)
  })
}

@enchantment_from_lore = array(
  '수선': 'mending',
  '치유': 'healing',
  '풍요': 'plenty',
  '용력': 'might',
  '방어': 'blocking',
  '날렵함': 'agility',
  '심안': 'mind_vision',
  '축복': 'blessing',
  '친수성': 'aqua_affinity',
  '유황불': 'brimstone',
  '깃털': 'feather',
  '원소 보호': 'elements_protection',
  '가시': 'throns',
  '내구성': 'unbreaking',
  '효율': 'efficiency',
  '화염': 'flame',
  '전격': 'shocking',
  '신성': 'holy',
  '독성': 'posion',
  '빙결': 'freeze',
  '융해 억제': 'anti_melting',
  '탈진': 'exhausting',
  '파멸': 'destruction',
  '약탈': 'looting',
  '행운': 'fortune',
  '섬세한 손길': 'silk_touch',
  '경험': 'experience',
  '무한': 'infinity',
  '다중발사': 'multishot',
  '관통': 'piercing',
  '밀어내기': 'punch',
  '힘': 'power',
  '빠른 장전': 'quick_charge'
)

proc _get_enchanted_item(@enchanting_item, @entries, @luck) {
  @total_weight = 0
  foreach(@key: @entry in @entries) {
    @weight = @entry['weight']
    if(array_index_exists(@entry, 'quality')) {
      @quality = @entry['quality']
    } else {
      @quality = 0
    }
    @weight = @weight + @quality * @luck # new_weight = quality x luck + weight
    if(@weight < 0) {
      @weight = 0
    }
    @entries[@key]['weight'] = @weight
    @total_weight += @weight
  }
  @result_weight = @total_weight * round(rand(), 5)
  @min_weight = 0
  @final_entry = null
  foreach(@entry in @entries) {
    @weight = @entry['weight']
    @max_weight = @min_weight + @weight
    if(@max_weight > @result_weight) {
      @final_entry = @entry
      break()
    } else {
      @min_weight = @max_weight
    }
  }

  @enchanted_item = @enchanting_item
  if(!is_null(@enchanting_item) && !is_null(@enchanting_item['meta']) && array_index_exists(@enchanting_item['meta'], 'modifiers')) {
    @lore_size = array_size(@enchanting_item['meta']['modifiers'])
  } else {
    @lore_size = 0
  } 
  if(!is_null(@final_entry)) {
    @enchanted_item['meta']['lore'][@lore_size] = ''
    @enchanted_item['meta']['lore'][@lore_size + 1] = '§f'.@final_entry['icon'].' '.hexcolor(@final_entry['color']).@final_entry['name']
    @descriptions = @final_entry['descriptions']
    foreach(@key: @description in @descriptions) {
      @enchanted_item['meta']['lore'][@lore_size + 2 + @key] = '§7'.@description
    }
  }
  return(@enchanted_item)
}

proc _update_item(@player, @uuid, @items, @players_item) {
  @enchantments = @players_item[@uuid]['enchantments']
  if(array_index_exists(@items, 'main_hand')) {
    @enchantments['main_hand'] = null
    if(!is_null(@items['main_hand']) && !is_null(@items['main_hand']['meta']) && !is_null(@items['main_hand']['meta']['modifiers']) && !is_null(@items['main_hand']['meta']['lore'])) {
      @modifiers = @items['main_hand']['meta']['modifiers']
      @lore = @items['main_hand']['meta']['lore']
      if(array_size(@lore) > array_size(@modifiers)) {
        @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
        @enchantments['main_hand'] = @enchantment
        @vanilla_enchants = array()
        switch(@enchantment) {
        case '내구성':
          @vanilla_enchants['unbreaking'] = array(
            'etype': 'DURABILITY',
            'elevel': 4
          )
          break()
        case '수선':
          @vanilla_enchants['unbreaking'] = array(
            'etype': 'DURABILITY',
            'elevel': 2
          )
          @vanilla_enchants['mending'] = array(
            'etype': 'MENDING',
            'elevel': 1
          )
          break()
        case '효율':
          @vanilla_enchants['efficiency'] = array(
            'etype': 'DIG_SPEED',
            'elevel': 3
          )
          @vanilla_enchants['sharpness'] = array(
            'etype': 'DAMAGE_ALL',
            'elevel': 1
          )
          break()
        case '용력':
          @vanilla_enchants['efficiency'] = array(
            'etype': 'DIG_SPEED',
            'elevel': 5
          )
          @vanilla_enchants['sharpness'] = array(
            'etype': 'DAMAGE_ALL',
            'elevel': 3
          )
          break()
        case '화염':
          @vanilla_enchants['fire_aspect'] = array(
            'etype': 'FIRE_ASPECT',
            'elevel': 1
          )
          break()
        case '유황불':
          @vanilla_enchants['fire_aspect'] = array(
            'etype': 'FIRE_ASPECT',
            'elevel': 5
          )
          break()
        case '행운':
          @vanilla_enchants['fortune'] = array(
            'etype': 'LOOT_BONUS_BLOCKS',
            'elevel': 2
          )
          @vanilla_enchants['looting'] = array(
            'etype': 'LOOT_BONUS_MOBS',
            'elevel': 2
          )
          break()
        }

        @items['main_hand']['meta']['enchants'] = @vanilla_enchants
        set_timeout(0, closure() {
          set_inventory_item(@uuid, pheld_slot(@player), @items['main_hand'])
        })
      }
    }
    @players_item[@uuid]['main_hand'] = @items['main_hand']
  }
  if(array_index_exists(@items, 'off_hand')) {
    @enchantments['off_hand'] = null
    if(!is_null(@items['off_hand']) && !is_null(@items['off_hand']['meta']) && !is_null(@items['off_hand']['meta']['modifiers']) && !is_null(@items['off_hand']['meta']['lore'])) {
      @modifiers = @items['off_hand']['meta']['modifiers']
      @lore = @items['off_hand']['meta']['lore']
      if(array_size(@lore) > array_size(@modifiers)) {
        @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
        @enchantments['off_hand'] = @enchantment
      }
    }
    @players_item[@uuid]['off_hand'] = @items['off_hand']
  }
  if(array_index_exists(@items, 'armor')) {
    @enchantments['armor'] = null
    if(!is_null(@items['armor']) && !is_null(@items['armor']['meta']) && !is_null(@items['armor']['meta']['modifiers']) && !is_null(@items['armor']['meta']['lore'])) {
      @modifiers = @items['armor']['meta']['modifiers']
      @lore = @items['armor']['meta']['lore']
      if(array_size(@lore) > array_size(@modifiers)) {
        @enchantment = substr(strip_colors(@lore[array_size(@modifiers) + 1]), 2)
        @enchantments['armor'] = @enchantment
      }
    }
    @players_item[@uuid]['armor'] = @items['armor']
  }
  foreach(@slot: @enchantment in @enchantments) {
    @players_item[@uuid]['enchantments'][@slot] = @enchantment
  }
  #broadcast(@players_item[@uuid])
}

/*
# armor
mending 수선
healing 치유
plenty 풍요
blocking 방어
agility 날렵함
mind_vision 심안
blessing 축복
aqua_affinity 친수성
brimstone 유황불
feather 깃털

protection 보호
elements_protection 원소 보호

throns 가시
unbreaking 내구성

# melee weapon
mending 수선
healing 치유
plenty 풍요
might 용력
flame 화염
shocking 전격
holy 신성
posion 독성
freeze 빙결
exhausting 탈진
destruction 파멸

looting 약탈
experience 경험

unbreaking 내구성

# tools
mending 수선
healing 치유
plenty 풍요
efficiency 효율
might 용력
flame 화염
shocking 전격
holy 신성
posion 독성
freeze 빙결
anti_melting 융해 억제
exhausting 탈진
destruction 파멸

looting 약탈
fortune 행운
silk_touch 섬세한 손길
experience 경험

unbreaking 내구성

# range weapons
mending 수선
healing 치유
plenty 풍요
infinity 무한
multishot 다중발사

looting 약탈
experience 경험

piercing 관통
punch 밀어내기

unbreaking 내구성
power 힘
quick_charge 빠른 장전
*/


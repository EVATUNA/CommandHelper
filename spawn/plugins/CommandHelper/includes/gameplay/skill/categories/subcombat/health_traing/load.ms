@max_health = @skill_spec['effect_by_point'][@point]['passive']['max_health']
set_entity_attribute_base(@uuid, 'GENERIC_MAX_HEALTH', @max_health)
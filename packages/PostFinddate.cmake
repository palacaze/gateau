# annoying compiler warning bug to disable
if (date_FOUND AND TARGET date::date)
    target_compile_options(date::date INTERFACE $<$<CXX_COMPILER_ID:GNU>:-Wno-stringop-overflow>)
    set_target_properties(date::date PROPERTIES SYSTEM ON)
endif()

//
//  A4LoadMeasureDefine.h
//  TestLoadCalculate
//
//  Created by jolin.ding on 2020/4/13.
//  Copyright © 2020 jolin.ding. All rights reserved.
//

#ifndef A4LoadMeasureDefine_h
#define A4LoadMeasureDefine_h

# if __arm64__
#   define ISA_MASK        0x0000000ffffffff8ULL
#   define ISA_MAGIC_MASK  0x000003f000000001ULL
#   define ISA_MAGIC_VALUE 0x000001a000000001ULL
#   define ISA_BITFIELD                                                      \
      uintptr_t nonpointer        : 1;                                       \
      uintptr_t has_assoc         : 1;                                       \
      uintptr_t has_cxx_dtor      : 1;                                       \
      uintptr_t shiftcls          : 33; /*MACH_VM_MAX_ADDRESS 0x1000000000*/ \
      uintptr_t magic             : 6;                                       \
      uintptr_t weakly_referenced : 1;                                       \
      uintptr_t deallocating      : 1;                                       \
      uintptr_t has_sidetable_rc  : 1;                                       \
      uintptr_t extra_rc          : 19
#   define RC_ONE   (1ULL<<45)
#   define RC_HALF  (1ULL<<18)

# elif __x86_64__
#   define ISA_MASK        0x00007ffffffffff8ULL
#   define ISA_MAGIC_MASK  0x001f800000000001ULL
#   define ISA_MAGIC_VALUE 0x001d800000000001ULL
#   define ISA_BITFIELD                                                        \
      uintptr_t nonpointer        : 1;                                         \
      uintptr_t has_assoc         : 1;                                         \
      uintptr_t has_cxx_dtor      : 1;                                         \
      uintptr_t shiftcls          : 44; /*MACH_VM_MAX_ADDRESS 0x7fffffe00000*/ \
      uintptr_t magic             : 6;                                         \
      uintptr_t weakly_referenced : 1;                                         \
      uintptr_t deallocating      : 1;                                         \
      uintptr_t has_sidetable_rc  : 1;                                         \
      uintptr_t extra_rc          : 8
#   define RC_ONE   (1ULL<<56)
#   define RC_HALF  (1ULL<<7)
#endif

typedef struct a4_method_t {
    SEL name;
    const char * types;
    IMP imp;
}a4_method_t;

typedef struct a4_method_list_t {
    uint32_t entsizeAndFlags;
    uint32_t count;
    a4_method_t first;
}a4_method_list_t;

typedef struct a4_category_t {
    const char *name;
    Class cls;
    a4_method_list_t *instanceMethods;
    a4_method_list_t *classMethods;
    // ignore others
    
}a4_category_t;

typedef union a4_isa_t {
    Class cls;
    uintptr_t bits;
    struct {
        ISA_BITFIELD;
    };
}a4_isa_t;

typedef struct a4_objc_class {
    a4_isa_t isa;
    Class cls;
    
}a4_objc_class;


#endif /* A4LoadMeasureDefine_h */

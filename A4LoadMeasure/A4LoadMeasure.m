//
//  A4LoadMeasure.m
//  A4LoadMeasure
//
//  Created by jolin.ding on 2020/4/13.
//  Copyright © 2020 jolin.ding. All rights reserved.
//

#import "A4LoadMeasure.h"
#import <mach-o/dyld.h>
#import <objc/message.h>
#import <mach-o/getsect.h>
#import "A4LoadMeasureDefine.h"

@interface A4LoadInfo ()
{
    @package
    SEL _swizzleSelector;
    IMP _originIMP;
    CFAbsoluteTime _duration;
    __unsafe_unretained Class _cls;
    Method _originMethod;
}
- (instancetype)initWithCategory:(a4_category_t *)cat;
- (instancetype)initWithClass:(Class)cls originMethod:(Method)method;
@end

@implementation A4LoadInfo

- (instancetype)initWithCategory:(a4_category_t *)cat
{
    if (self = [super init]) {
        _cls = cat->cls;
        _clsName = NSStringFromClass(cat->cls);
        _catName = [NSString stringWithCString:cat->name encoding:NSUTF8StringEncoding];
        _swizzleSelector = NSSelectorFromString([NSString stringWithFormat:@"A4LoadInfo_%@_%@_%x", _clsName, _catName, arc4random()]);
        _originIMP = cat->classMethods->first.imp;
        _originMethod = (Method)&cat->classMethods->first;
    }
    return self;
}

- (instancetype)initWithClass:(Class)cls originMethod:(Method)method
{
    if (self = [super init]) {
        _cls = cls;
        _clsName = NSStringFromClass(cls);
        _catName = nil;
        _swizzleSelector = NSSelectorFromString([NSString stringWithFormat:@"A4LoadInfo_%@_%x", _clsName, arc4random()]);
        _originIMP = method_getImplementation(method);
        _originMethod = method;
    }
    return self;
}

@end


@interface A4LoadMeasure : NSObject
@end

@implementation A4LoadMeasure

bool isSelfDefinedImage(const char * name)
{
    return !strstr(name, "/System/Library/") && !strstr(name, "/usr/lib/") && !strstr(name, "Library/PrivateFrameworks") && !strstr(name, "__lldb_") && !strstr(name, "A4LoadMeasure");
}

/// 获取所有自定义image的mach_header
/// @param outCount 自定义image的数量
struct mach_header ** allSelfDefinedImagesHeader(uint32_t * outCount)
{
    uint32_t imageCount = _dyld_image_count();
    uint32_t count = 0;
    if (!imageCount) return NULL;
    
    struct mach_header ** headers = malloc(sizeof(struct mach_header **) * imageCount);
    for (uint32_t i = 0; i < imageCount; i ++) {
        const char * name = _dyld_get_image_name(i);
        if (isSelfDefinedImage(name)) {
            struct mach_header * h = (struct mach_header *)_dyld_get_image_header(i);
            headers[count++] = h;
        }
    }
    headers[count] = NULL;
    if (outCount) *outCount = count;
    return headers;
}

void * getMachHeaderSectionData(struct mach_header * mhdr, const char * sectname, unsigned long * size)
{
    if (!sectname || !mhdr) return NULL;
    
    unsigned long byte = 0;
    void * data = getsectiondata((void *)mhdr, "__DATA", sectname, &byte);
    if (!data) {
        data = getsectiondata((void *)mhdr, "__DATA_CONST", sectname, &byte);
    }
    if (!data) {
        data = getsectiondata((void *)mhdr, "__DATA_DIRTY", sectname, &byte);
    }
    if (size) *size = byte;
    return data;
}

void hookAllLoadMethods(NSArray<A4LoadInfo *> * loadInfos)
{
    __block CFAbsoluteTime totalTime = 0;
    [loadInfos enumerateObjectsUsingBlock:^(A4LoadInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class metaCls = object_getClass(obj->_cls);
        SEL hookSelector = obj->_swizzleSelector;
        IMP hookIMP = imp_implementationWithBlock(^ (id originCls) {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            ((void (*)(id, SEL))objc_msgSend)(originCls, hookSelector);
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
            obj->_duration = (end - start) * 1000;
            totalTime += obj->_duration;
            if (obj.catName) {
                printf("%s(%s) %f milliseconds\n", [obj.clsName cStringUsingEncoding:NSUTF8StringEncoding], [obj.catName cStringUsingEncoding:NSUTF8StringEncoding], obj->_duration);
            }
            else {
                printf("\n%s %f milliseconds\n", [obj.clsName cStringUsingEncoding:NSUTF8StringEncoding], obj->_duration);
            }
        });
        
        BOOL addSuccess = class_addMethod(metaCls, hookSelector, hookIMP, method_getTypeEncoding(class_getInstanceMethod(metaCls, @selector(load))));
        if (addSuccess) {
            method_exchangeImplementations(class_getInstanceMethod(metaCls, hookSelector), obj->_originMethod);
        }
    }];
}

__attribute__((constructor)) static void calculateTotalTime()
{
    CFAbsoluteTime totalStartTime = CFAbsoluteTimeGetCurrent();
    // 获取所有自定义的 mach-o header
    NSMutableDictionary<NSNumber *, Class> * imps = [NSMutableDictionary dictionaryWithCapacity:10];
    NSMutableArray<A4LoadInfo *> * loadInfos = [NSMutableArray arrayWithCapacity:20];
    uint32_t count = 0;
    struct mach_header ** headers = allSelfDefinedImagesHeader(&count);
    // 从header中找到实现了load方法的类、分类
    for (uint32_t i = 0; i < count; i ++) {
        struct mach_header * header = headers[i];
        unsigned long byte = 0;
        // 分类
        a4_category_t ** category_list = (a4_category_t **)getMachHeaderSectionData(header, "__objc_nlcatlist", &byte);
        for (unsigned long j = 0; j < byte / sizeof(a4_category_t *); j ++) {
            a4_category_t * cat = category_list[j];
            if (!strcmp(sel_getName(cat->classMethods->first.name), "load")) {
                A4LoadInfo * info = [[A4LoadInfo alloc] initWithCategory:cat];
                [imps setObject:info->_cls forKey:@((uintptr_t)info->_originIMP)];
                [loadInfos addObject:info];
            }
        }
        // 类
        Class * clsList = (Class *)getMachHeaderSectionData(header, "__objc_nlclslist", &byte);
        for (unsigned long j = 0; j < byte / sizeof(Class); j ++) {
            Class cls = clsList[j];
            unsigned int outCount = 0;
            Method * method_list = class_copyMethodList(object_getClass(cls), &outCount);
            for (unsigned int k = 0; k < outCount; k ++) {
                Method method = method_list[k];
                const char * name = sel_getName(method_getName(method));
                IMP imp = method_getImplementation(method);
                if (!strcmp(name, "load") && !imps[@((uintptr_t)imp)] ) { // 需要去除分类中已经添加的
                    A4LoadInfo * info = [[A4LoadInfo alloc] initWithClass:cls originMethod:method];
                    [loadInfos addObject:info];
                }
            }
        }
    }
    // hook load 方法
    hookAllLoadMethods(loadInfos);
    
    // 输出总时间
    CFAbsoluteTime totalEndTime = CFAbsoluteTimeGetCurrent();
    printf("all measure cost time:%f milliseconds", (totalEndTime - totalStartTime) * 1000);
}

@end

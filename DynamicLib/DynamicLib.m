//
//  DynamicLib.m
//  DynamicLib
//
//  Created by jolin.ding on 2020/4/10.
//  Copyright © 2020 jolin.ding. All rights reserved.
//

#import "DynamicLib.h"

@implementation DynamicLib

+ (void)load
{
//    NSLog(@"---> %s", __func__);
}

@end


@interface DynamicLib (sleep_1s)

@end

@implementation DynamicLib (sleep_1s)

+ (void)load
{
    sleep(1);
//    NSLog(@"---> %s", __func__);
}

@end

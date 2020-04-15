//
//  Logger.m
//  LogComponent
//
//  Created by jolin.ding on 2020/4/13.
//  Copyright © 2020 jolin.ding. All rights reserved.
//

#import "Logger.h"

@implementation Logger

+ (void)load {
    usleep(1);
//    NSLog(@"---> %s", __func__);
}

@end

@interface Logger (console)

@end

@implementation Logger (console)

+ (void)load {
    usleep(666 * 1000);
//    NSLog(@"---> %s", __func__);
}

@end

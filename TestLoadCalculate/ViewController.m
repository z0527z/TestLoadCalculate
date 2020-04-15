//
//  ViewController.m
//  TestLoadCalculate
//
//  Created by jolin.ding on 2020/4/13.
//  Copyright © 2020 jolin.ding. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

+ (void)load {
//    NSLog(@"---> %s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


@end


@interface ViewController (sleep_300ms_1)

@end

@implementation ViewController (sleep_300ms_1)

+ (void)load {
    usleep(300 * 1000);
//    NSLog(@"---> %s", __func__);
}

@end

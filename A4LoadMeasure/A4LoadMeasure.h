//
//  A4LoadMeasure.h
//  A4LoadMeasure
//
//  Created by jolin.ding on 2020/4/13.
//  Copyright © 2020 jolin.ding. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for A4LoadMeasure.
FOUNDATION_EXPORT double A4LoadMeasureVersionNumber;

//! Project version string for A4LoadMeasure.
FOUNDATION_EXPORT const unsigned char A4LoadMeasureVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <A4LoadMeasure/PublicHeader.h>


@interface A4LoadInfo : NSObject
@property (nonatomic, unsafe_unretained, readonly) Class cls;
@property (nonatomic, copy, readonly) NSString * clsName;
@property (nonatomic, copy, readonly) NSString * catName;
@property (nonatomic, assign, readonly) CFAbsoluteTime duration;
@end

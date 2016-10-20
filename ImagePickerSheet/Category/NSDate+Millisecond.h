//
//  NSDate+Millisecond.h
//  MEMobile
//
//  Created by LamTsanFeng on 15/6/17.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Millisecond)
/** 毫秒转换为date */
+ (instancetype)dateWithTimeMillisecondSince1970:(long long)millisecs;
/** 获取当前毫秒 */
+ (long long)timeMillisecondSince1970;

/** 获取当前微妙 */
+ (long long)timeMicrosecondSince1970;
@end

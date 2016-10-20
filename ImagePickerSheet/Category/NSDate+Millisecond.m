//
//  NSDate+Millisecond.m
//  MEMobile
//
//  Created by LamTsanFeng on 15/6/17.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "NSDate+Millisecond.h"

@implementation NSDate (Millisecond)
/** 毫秒转换为date */
+ (instancetype)dateWithTimeMillisecondSince1970:(long long)millisecs
{
    NSTimeInterval timeInterval = millisecs / 1000;
    return [NSDate dateWithTimeIntervalSince1970:timeInterval];
}
/** 获取当前毫秒 */
+ (long long)timeMillisecondSince1970
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    return timeInterval * 1000;
}

/** 获取当前微妙 */
+ (long long)timeMicrosecondSince1970
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    return timeInterval * 1000000;
}

@end

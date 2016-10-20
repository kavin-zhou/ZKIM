//
//  ZKEmoticonHelper.h
//  ZKIM
//
//  Created by ZK on 16/10/20.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZKEmoticon.h"

@interface ZKEmoticonHelper : NSObject

+ (NSBundle *)emoticonBundle;
+ (NSArray<ZKEmoticonGroup *> *)emoticonGroups;

@end
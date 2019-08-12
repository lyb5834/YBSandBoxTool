//
//  YBSelectVC.h
//  SandBoxTool
//
//  Created by lyb on 2019/2/27.
//  Copyright © 2019年 zbjt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SBApp.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBSelectVC : NSViewController

@property (nonatomic, strong) SBApp * appItem;
@property (nonatomic, copy) void (^popoverShouldHiddenHandle) (YBSelectVC * selectVC);

@end

NS_ASSUME_NONNULL_END

//
//  YBSelectVC.m
//  SandBoxTool
//
//  Created by lyb on 2019/2/27.
//  Copyright © 2019年 zbjt. All rights reserved.
//

#import "YBSelectVC.h"

@interface YBSelectVC ()

@end

@implementation YBSelectVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)onOpenSanBoxAction:(NSButton *)sender {
    system([NSString stringWithFormat:@"open %@", self.appItem.sandBoxPath].UTF8String);
    NSLog(@"sandBoxPath = %@",self.appItem.sandBoxPath);
    if (self.popoverShouldHiddenHandle) {
        self.popoverShouldHiddenHandle(self);
    }
}

- (IBAction)onOpenPlistAction:(NSButton *)sender {
    NSString * plistPath = [self.appItem.sandBoxPath stringByAppendingFormat:@"/Library/Preferences/%@.plist",self.appItem.bundleId];
    NSLog(@"plistPath = %@",plistPath);
    system([NSString stringWithFormat:@"open %@",plistPath].UTF8String);
    if (self.popoverShouldHiddenHandle) {
        self.popoverShouldHiddenHandle(self);
    }
}

@end

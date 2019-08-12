//
//  SBTools.m
//  SandBoxTool
//
//  Created by wsong on 2018/7/7.
//  Copyright © 2018年 zbjt. All rights reserved.
//

#import "SBTools.h"

@implementation SBTools

// 执行一个命令
+ (void)executeCommand:(NSString *)command
                handle:(void (^)(NSString *path))handle {
    if ([self isMacOSMojave]) {
        system("xattr -w format_version 1 \"/Library/Application Support/CrashReporter/SubmitDiagInfo.domains\"");
    }
    // 获取系统上的tmp目录
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.txt"];
    // 将命令执行重定向至tmp目录的tmp文件
    system([NSString stringWithFormat:@"%@ > %@", command, path].UTF8String);
    NSLog(@"path: %@",path);
    // 将路径回调至外部使用
    if (handle) {
        handle(path);
    }
    // 删除tmp文件
    system([NSString stringWithFormat:@"rm %@", path].UTF8String);
}

+ (NSString *)getVersionString
{
    NSString *versionString;
    NSDictionary * sv = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    versionString = [sv objectForKey:@"ProductVersion"];
    versionString = [versionString stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSLog(@"versionString= %@", versionString);
    return versionString;
}

+ (BOOL)isMacOSMojave
{
    return [[self getVersionString] integerValue] >= 10140;
}

@end

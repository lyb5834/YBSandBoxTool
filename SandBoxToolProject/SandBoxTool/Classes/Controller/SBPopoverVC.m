//
//  SBPopoverVC.m
//  SandBoxTool
//
//  Created by wsong on 2018/3/27.
//  Copyright © 2018年 zbjt. All rights reserved.
//

#import "SBPopoverVC.h"
#import "SBSimulator.h"
#import "SBApp.h"
#import "SBTools.h"
#import "SBLabel.h"
#import "YBSelectVC.h"

@interface SBPopoverVC ()
<NSOutlineViewDataSource, NSOutlineViewDelegate>
/** 列表视图 */
@property (weak) IBOutlet NSOutlineView *outlineView;
/** 模拟器数组 */
@property (nonatomic, strong) NSMutableArray<SBSimulator *> *simulatorList;
/** 提示文字视图 */
@property (weak) IBOutlet SBLabel *tipLabel;

/** 弹出视图 */
@property (nonatomic, strong) NSPopover *popover;

/** 展开的模拟器*/
@property (nonatomic, strong) SBSimulator * expandedSimulator;

@end

@implementation SBPopoverVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 监听列表视图行选中事件，类似UITableView的didSelected代理方法
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outlineViewSelectionDidChange:)
                                                 name:NSOutlineViewSelectionDidChangeNotification
                                               object:nil];
    
    self.popover = [[NSPopover alloc] init];
    __weak typeof(self) weakSelf = self;
    
    // 当用户点击弹窗视图之外的区域，使得弹窗视图消失
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown
                                           handler:^(NSEvent * _Nonnull event) {
                                               if (weakSelf.popover.isShown) {
                                                   [weakSelf.popover close];
                                                   [weakSelf.outlineView deselectRow:weakSelf.outlineView.selectedRow];
                                               }
                                           }];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    // 进入视图时直接获取应用焦点
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    __weak typeof(self) weakSelf = self;
    [self prepareDataFinishHandle:^{
        [weakSelf.outlineView reloadData];
        if (weakSelf.expandedSimulator) {
            
            [weakSelf.simulatorList enumerateObjectsUsingBlock:^(SBSimulator * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([obj.name isEqualToString:weakSelf.expandedSimulator.name] &&
                    [obj.udid isEqualToString:weakSelf.expandedSimulator.udid] &&
                    [obj.systemVersion isEqualToString:weakSelf.expandedSimulator.systemVersion]) {
                    
                    //展开该列
                    [weakSelf.outlineView expandItem:obj];
                    *stop = YES;
                }
                
            }];
        }
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 列表视图行选中时调用
- (void)outlineViewSelectionDidChange:(NSNotification *)note {
    // 获取选中行对应的item
    SBApp *app = [self.outlineView itemAtRow:self.outlineView.selectedRow];
    // 判定沙盒目录不为空
//    if (app.sandBoxPath) {
//        // 打开沙盒目录
//        system([NSString stringWithFormat:@"open %@", app.sandBoxPath].UTF8String);
//        // 隐藏视图
//        if (self.shouldHidden) {
//            self.shouldHidden(self);
//        }
//    }
//    // 取消选中行, 类似tableView的deselect
//    [self.outlineView deselectRow:self.outlineView.selectedRow];
    
    __weak typeof(self) weakSelf = self;
    if (app.sandBoxPath) {
        YBSelectVC * selectVC = [[YBSelectVC alloc] init];
        selectVC.appItem = app;
        selectVC.popoverShouldHiddenHandle = ^(YBSelectVC * _Nonnull selectVC) {
            if (weakSelf.popover.isShown) {
                [weakSelf.popover close];
            }
            if (weakSelf.shouldHidden) {
                weakSelf.shouldHidden(self);
            }
            [weakSelf.outlineView deselectRow:weakSelf.outlineView.selectedRow];
        };
        self.popover.contentViewController = selectVC;
        
        NSRect rect = [self.outlineView frameOfOutlineCellAtRow:self.outlineView.selectedRow];
        NSTableRowView * cell = [self.outlineView rowViewAtRow:self.outlineView.selectedRow  makeIfNecessary:NO];
        [self.popover showRelativeToRect:rect ofView:cell preferredEdge:NSRectEdgeMinX];
    }
}

#pragma mark - <NSOutlineViewDataSource, NSOutlineViewDelegate>
// 获取每一小组的行数
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if ([item isKindOfClass:[SBSimulator class]]) {
        // 如果是模拟器组，返回app个数
        return ((SBSimulator *)item).appList.count;
    } else {
        // 判断当前用户是否设置了Xcode命令路径
        __block BOOL isSet = YES;
        [SBTools executeCommand:@"xcode-select -p"
                         handle:^(NSString *path) {
                             isSet = ![[[NSString stringWithContentsOfFile:path
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix:@"CommandLineTools"];
                         }];
        
        if (isSet) {
            // 如果设置了，返回模拟器组数
            self.tipLabel.text = @"请启动模拟器";
            self.tipLabel.hidden = self.simulatorList.count > 0;
            return self.simulatorList.count;
        } else {
            // 未设置，提示用户去设置
            self.tipLabel.text = @"请设置Xcode命令：Xcode -> Preferences -> locations -> Command Line Tools";
            return 0;
        }
    }
}
// 返回每一组是否可以展开
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    // 只有模拟器组可以展开，app是直接点击进入沙盒目录的
    return [item isKindOfClass:[SBSimulator class]];
}
// 返回每一组/行需要使用的数据模型
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if ([item isKindOfClass:[SBSimulator class]]) {
        // 如模拟器组，返回app模型
        return ((SBSimulator *)item).appList[index];
    } else {
        // 则返回模拟器模型
        return self.simulatorList[index];
    }
}
// 返回每一行显示的视图，类似tableView的cellForRow方法
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // 从复用队列中获取cell，如没有，自动创建一个，类似tableView的dequeue
    NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"cell" owner:self];
    
    cell.textField.stringValue = [NSString stringWithFormat:@"%@(%@)", [item name], [item isKindOfClass:[SBApp class]]? ((SBApp *)item).bundleId : ((SBSimulator *)item).systemVersion];
    return cell;
}
// 返回每一行是否可以选中
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return [item isKindOfClass:[SBApp class]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    self.expandedSimulator = item;
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    self.expandedSimulator = nil;
    return YES;
}

// 刷新列表
- (IBAction)reload:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self prepareDataFinishHandle:^{
        [weakSelf.outlineView reloadData];
        if (weakSelf.expandedSimulator) {
            
            [weakSelf.simulatorList enumerateObjectsUsingBlock:^(SBSimulator * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([obj.name isEqualToString:weakSelf.expandedSimulator.name] &&
                    [obj.udid isEqualToString:weakSelf.expandedSimulator.udid] &&
                    [obj.systemVersion isEqualToString:weakSelf.expandedSimulator.systemVersion]) {
                    
                    //展开该列
                    [weakSelf.outlineView expandItem:obj];
                    *stop = YES;
                }
                
            }];
        }
    }];
}

- (IBAction)quit:(NSButton *)sender {
    // 退出app
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - data
- (void)prepareDataFinishHandle:(void (^) (void))finishHandle
{
    dispatch_async(dispatch_queue_create("com.simulator.queue", DISPATCH_QUEUE_CONCURRENT), ^{
        
        __block NSData *data = nil;
        // 获取模拟器列表
        [SBTools executeCommand:@"xcrun simctl list --json"
                         handle:^(NSString *path) {
                             data = [NSData dataWithContentsOfFile:path];
                         }];
        
        NSDictionary *simulatorListSet = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:NSJSONReadingMutableContainers
                                                                           error:nil][@"devices"];
        [self.simulatorList removeAllObjects];
        
        for (NSString *simulatorListKey in simulatorListSet) {
            
            if ([simulatorListKey.lowercaseString containsString:@"ios"]) {
                for (NSDictionary *simulatorDict in simulatorListSet[simulatorListKey]) {
                    // 只获取启动的模拟器，因为之后的命令要求模拟器是启动状态
                    if ([simulatorDict[@"state"] caseInsensitiveCompare:@"booted"] == NSOrderedSame) {
                        SBSimulator *simulator = [SBSimulator simulatorWithDict:simulatorDict];
                        simulator.systemVersion = simulatorListKey;
                        [self.simulatorList addObject:simulator];
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finishHandle) {
                finishHandle();
            }
        });
        
    });
}

#pragma mark - Getter
- (NSMutableArray<SBSimulator *> *)simulatorList {
    if (_simulatorList == nil) {
        _simulatorList = [NSMutableArray array];
    }
    return _simulatorList;
}

@end

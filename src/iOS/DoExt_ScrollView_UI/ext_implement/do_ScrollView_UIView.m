//
//  TYPEID_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_ScrollView_UIView.h"

#import "doInvokeResult.h"
#import "doIPage.h"
#import "doIScriptEngine.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doUIContainer.h"
#import "doISourceFS.h"

@implementation do_ScrollView_UIView
{
    BOOL _direction;
    
    id<doIUIModuleView> _childView;
    id<doIUIModuleView> _headView;
    
    BOOL _isRefreshing;
}

- (instancetype)init
{
    if(self = [super init])
        self.delegate = self;
    return self;
}

#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    NSInteger childCount = _model.ChildUIModules.count;
    if(childCount > 1)
        [NSException raise:@"doScrollView" format:@"只允许加入一个子视图",nil];
    else if(childCount == 1)
    {
        doUIModule *childViewModel = [_model.ChildUIModules objectAtIndex:0];
        _childView = childViewModel.CurrentUIModuleView;
        [self addSubview:(UIView *) _childView];
    }
    else
        [NSException raise:@"doScrollView" format:@"没有子视图",nil];
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性
    //销毁model后，自动销毁view
    if(_headView)
    {
        [((UIView *)_headView) removeFromSuperview];
        [[_headView GetModel] Dispose];
        _headView = nil;
    }
}
//实现布局
- (void) OnRedraw
{
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    if(_childView)  [_childView OnRedraw];
    if(_headView)  [_headView OnRedraw];
    [self setContent];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
#pragma mark - Changed

- (void)change_isShowbar:(NSString *)isShowbar
{
    if([isShowbar isEqual:@"1"] || [isShowbar isEqual:@"true"])
    {
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = YES;
    }
    else
    {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
    }
}

- (void)change_direction:(NSString *)direction
{
    if([direction isEqualToString:@"horizontal"])
    {
        _direction = YES;
    }
    else if ([direction isEqualToString:@"vertical"])
    {
        _direction = NO;
    }
    [self setContent];
}

- (void)change_headerView:(NSString *)herderView
{
    id<doIPage> pageModel = _model.CurrentPage;
    doSourceFile *fileName = [pageModel.CurrentApp.SourceFS GetSourceByFileName:herderView];
    if(!fileName)
    {
        [NSException raise:@"scrollView" format:@"无效的headView路径:%@",herderView,nil];
        return;
    }
    doUIContainer *container = [[doUIContainer alloc] init:pageModel];
    [container LoadFromFile:fileName:nil:nil];
    doUIModule *headViewModel = container.RootView;
    if (headViewModel == nil)
    {
        [NSException raise:@"scrollView" format:@"创建viewModel失败",nil];
        return;
    }
    UIView *insertView = (UIView*)headViewModel.CurrentUIModuleView;
    _headView = headViewModel.CurrentUIModuleView;
    if (insertView == nil)
    {
        [NSException raise:@"scrollView" format:@"创建view失败"];
        return;
    }
    [self addSubview:insertView];
    [container LoadDefalutScriptFile:herderView];
    //const CGFloat *color = CGColorGetComponents([insertView.backgroundColor CGColor]);
    //self.backgroundColor = [UIColor colorWithRed:color[0]/255 green:color[1]/255 blue:color[3]/255 alpha:color[4]/255];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
/*
 1.参数节点
 doJsonNode *_dictParas = [parms objectAtIndex:0];
 在节点中，获取对应的参数
 NSString *title = [_dictParas GetOneText:@"title" :@"" ];
 说明：第一个参数为对象名，第二为默认值
 
 2.脚本运行时的引擎
 id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
 
 同步：
 3.同步回调对象(有回调需要添加如下代码)
 doInvokeResult *_invokeResult = [parms objectAtIndex:2];
 回调信息
 如：（回调一个字符串信息）
 [_invokeResult SetResultText:((doUIModule *)_model).UniqueKey];
 异步：
 3.获取回调函数名(异步方法都有回调)
 NSString *_callbackName = [parms objectAtIndex:2];
 在合适的地方进行下面的代码，完成回调
 新建一个回调对象
 doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
 填入对应的信息
 如：（回调一个字符串）
 [_invokeResult SetResultText: @"异步方法完成"];
 [_scritEngine Callback:_callbackName :_invokeResult];
 */
//同步
-(void)toBegin:(NSArray *)parms
{
    if(_direction)
        self.contentOffset = CGPointMake(0, self.contentOffset.y);
    else
        self.contentOffset = CGPointMake(self.contentOffset.x, 0);
    //同步方法会主动传一个回调对象过来，不需要新建
    doInvokeResult * _invokeResult = [parms objectAtIndex:2];
    //_invokeResult只需要填入数据即可，前端有他的引用，可以获取返回的内容
    [_invokeResult SetResultText:_model.UniqueKey];
}
- (void)toEnd:(NSArray *)parms
{
    if(_direction)
        self.contentOffset = CGPointMake(self.contentSize.width-self.frame.size.width, self.contentOffset.y);
    else
        self.contentOffset = CGPointMake(self.contentOffset.x, self.contentSize.height-self.frame.size.height);
}
- (void)getOffsetX:(NSArray *)_parms
{
    doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
    NSString *offsetX = [NSString stringWithFormat:@"%f",self.contentOffset.x];
    [_invokeResult SetResultText:offsetX];
}
- (void)getOffsetY :(NSArray *)_parms
{
    doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
    NSString *offsetY = [NSString stringWithFormat:@"%f",self.contentOffset.y];
    [_invokeResult SetResultText:offsetY];
}
- (void)rebound:(NSArray *)parms
{
    _isRefreshing = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }];
}
#pragma mark - scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(_headView && !_isRefreshing && scrollView.contentOffset.y<0)
    {
        if(scrollView.contentOffset.y >= ((UIView *)_headView).frame.size.height*(-1))
            [self fireEvent:0 :scrollView.contentOffset.y];
        else
            [self fireEvent:1 :scrollView.contentOffset.y];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if(scrollView.contentOffset.y < ((UIView *)_headView).frame.size.height*(-1) && !_isRefreshing && _headView)
    {
        [self fireEvent:2 :scrollView.contentOffset.y];
        self.contentInset = UIEdgeInsetsMake(((UIView *)_headView).frame.size.height, 0, 0, 0);
        _isRefreshing = YES;
    }
}
#pragma mark -
#pragma mark - private method
#pragma mark - 调整headView的大小
- (void)setContent
{
    UIView *childView = (UIView *)_childView;
    CGFloat w = childView.frame.origin.x+childView.frame.size.width;
    CGFloat h = childView.frame.origin.y+childView.frame.size.height;
    if(_direction)
    {
        if(_headView)
        {
            UIView *headView = (UIView *)_headView;
            CGFloat realH = self.frame.size.height;
            CGFloat realW = realH/headView.frame.size.height*headView.frame.size.width;
            headView.frame = CGRectMake(-realW, -0, realW, realH);
            
            if(w <= self.frame.size.width)
                w = self.frame.size.width+1;
        }
        self.contentSize = CGSizeMake(w, 0);
    }
    else
    {
        if(_headView)
        {
            UIView *headView = (UIView *)_headView;
            CGFloat realW = self.frame.size.width;
            CGFloat realH = realW/headView.frame.size.width*headView.frame.size.height;
            headView.frame = CGRectMake(0, -realH, realW, realH);
            
            if(h <= self.frame.size.height)
                h = self.frame.size.height+1;
        }
        self.contentSize = CGSizeMake(0, h);
    }
}

#pragma mark - 发送pull事件
- (void)fireEvent:(int)state :(CGFloat)y
{
    NSMutableDictionary *node = [[NSMutableDictionary alloc] init];
    [node setObject:@(state) forKey:@"state"];
    id s = !@(y)?@"":@(y);
    [node setObject:s forKey:@"y"];
    doInvokeResult* _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"pull":_invokeResult];
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}


@end

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
    
    doUIModule *_childViewModel;
    doUIModule *_headViewModel;
    
    BOOL _isRefreshing;
    NSString *_address;
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
        _childViewModel = [_model.ChildUIModules objectAtIndex:0];
        [self addSubview:(UIView *) _childViewModel.CurrentUIModuleView];
    }
    else
        [NSException raise:@"doScrollView" format:@"没有子视图",nil];

}
//销毁所有的全局对象
- (void) OnDispose
{
    _model = nil;
    //自定义的全局属性
    _childViewModel = nil;
    _headViewModel = nil;
    _address = nil;
}
//实现布局
- (void) OnRedraw
{
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
    //实现布局相关的修改
    [doUIModuleHelper OnRedraw:_childViewModel];
    [self setContent];
    
    [doUIModuleHelper OnRedraw:_headViewModel];
    UIView *headView = (UIView *)_headViewModel.CurrentUIModuleView;
    CGFloat realW = self.frame.size.width;
    CGFloat realH = realW/_headViewModel.RealWidth*_headViewModel.RealHeight;
    headView.frame = CGRectMake(0, -realH, realW, realH);
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
    if([isShowbar isEqual:@"YES"] || [isShowbar isEqual:@"true"])
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
    _headViewModel = container.RootView;
    _address = [NSString stringWithFormat:@"%@",[_headViewModel UniqueKey]];
    if (_headViewModel == nil)
    {
        [NSException raise:@"scrollView" format:@"创建viewModel失败",nil];
        return;
    }
    UIView *insertView = (UIView*)_headViewModel.CurrentUIModuleView;
    if (insertView == nil)
    {
        [NSException raise:@"scrollView" format:@"创建view失败"];
        return;
    }
    [self addSubview:insertView];
    //const CGFloat *color = CGColorGetComponents([insertView.backgroundColor CGColor]);
    //self.backgroundColor = [UIColor colorWithRed:color[0]/255 green:color[1]/255 blue:color[3]/255 alpha:color[4]/255];
    [self setContent];
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
    self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}
- (void)getHeaderView:(NSArray *)parms
{
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    [_invokeResult SetResultText:_address];
}

#pragma mark - scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UIView *_headView = (UIView *)_headViewModel.CurrentUIModuleView;
    if(_headView && !_isRefreshing)
    {
        if(scrollView.contentOffset.y >= _headView.frame.size.height*(-1))
            [self fireEvent:0 :scrollView.contentOffset.y];
        else
            [self fireEvent:1 :scrollView.contentOffset.y];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    UIView *_headView = (UIView *)_headViewModel.CurrentUIModuleView;
    if(scrollView.contentOffset.y < _headView.frame.size.height*(-1) && !_isRefreshing && _headView)
    {
        [self fireEvent:2 :scrollView.contentOffset.y];
        self.contentInset = UIEdgeInsetsMake(_headView.frame.size.height, 0, 0, 0);
        _isRefreshing = YES;
    }
}

#pragma mark -
#pragma mark - private method
- (void)setContent
{
    UIView *_childView = (UIView *)_childViewModel.CurrentUIModuleView;
    CGFloat w = _childView.frame.origin.x+_childView.frame.size.width;
    CGFloat h = _childView.frame.origin.y+_childView.frame.size.height;
    if(_direction)
    {
        if(_headViewModel)
            if(w <= self.frame.size.width)
                w = self.frame.size.width+1;
        self.contentSize = CGSizeMake(w, 0);
    }
    else
    {
        if(_headViewModel)
            if(h <= self.frame.size.height)
                h = self.frame.size.height+1;
        self.contentSize = CGSizeMake(0, h);
    }
}

- (void)fireEvent:(int)state :(CGFloat)y
{
    doJsonNode *node = [[doJsonNode alloc] init];
    [node SetOneInteger:@"state" :state];
    [node SetOneText:@"y" :[NSString stringWithFormat:@"%f",y]];
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
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (doJsonNode *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (doJsonNode *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
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

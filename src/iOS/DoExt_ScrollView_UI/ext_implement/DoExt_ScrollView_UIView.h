//
//  TYPEID_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DoExt_ScrollView_IView.h"
#import "DoExt_ScrollView_UIModel.h"
#import "doIUIModuleView.h"

@interface DoExt_ScrollView_View : UIScrollView<DoExt_ScrollView_IView,doIUIModuleView,UIScrollViewDelegate>
//可根据具体实现替换UIView
{
    @private
    __weak DoExt_ScrollView_UIModel *_model;
}

@end

//
//  UIScrollView_EmptyDataSetExtensions.m
//  LoadingContent
//
//  Created by IIlya Puchka on 15/02/16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

#import "UIScrollView_EmptyDataSetExtensions.h"

@class DZNEmptyDataSetView;

@interface UIScrollView()
@property (nonatomic, readonly) DZNEmptyDataSetView *emptyDataSetView;
@end

@implementation UIScrollView(ErrorView)

- (UIView *)errorView {
    return (UIView *)[self emptyDataSetView];
}

@end

@implementation UIScrollView(NoContentView)

- (UIView *)noContentView {
    return (UIView *)[self emptyDataSetView];
}

@end


//
//  UIScrollView_EmptyDataSetExtensions.h
//  LoadingContent
//
//  Created by IIlya Puchka on 15/02/16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView(NoContentView)

@property (nonatomic, readonly) UIView *noContentView;

@end

NS_ASSUME_NONNULL_END
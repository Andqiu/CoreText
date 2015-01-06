//
//  CoreTextView.h
//  CoreText
//
//  Created by test on 15/1/4.
//  Copyright (c) 2015年 kanon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTextView : UIView

@property (nonatomic,strong) NSAttributedString *attrEmotionString;
@property (nonatomic,strong) NSArray *clickArr;
-(void)comperString:(NSString *)string;

@end

@interface Body : NSObject
@property(nonatomic,strong)NSString *name;
@property(nonatomic,assign)NSRange range;
@end

@interface Theme : NSObject
@property(nonatomic,strong)NSString *themeTitle;
@property(nonatomic,assign)NSRange range;


@end
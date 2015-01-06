//
//  ViewController.m
//  CoreText
//
//  Created by test on 15/1/4.
//  Copyright (c) 2015年 kanon. All rights reserved.
//
#import <CoreText/CoreText.h>

#import "ViewController.h"
#import "CoreTextView.h"




@implementation Body
@end

@implementation Theme
@end

@interface ViewController (){
    CoreTextView *_coretextView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _coretextView = [[CoreTextView alloc] initWithFrame:CGRectMake(10, 200, 300, 100)];
    [_coretextView comperString:kContentText6 ];
    [self.view addSubview:_coretextView];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

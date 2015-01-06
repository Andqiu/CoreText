//
//  CoreTextView.m
//  CoreText
//
//  Created by test on 15/1/4.
//  Copyright (c) 2015年 kanon. All rights reserved.
//

#import "CoreTextView.h"
#import <CoreText/CoreText.h>


@implementation CoreTextView{
    CTTypesetterRef _typesetterRef;
    NSMutableArray *_selectionsViews;
    
    NSString *_originalEmojiString;
    
    NSMutableArray *_emojiNames;
    NSMutableArray *_emojiRanges;
}

-(instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        _selectionsViews = [NSMutableArray arrayWithCapacity:0];

        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMyself:)];
        [self addGestureRecognizer:tap];
        
        self.userInteractionEnabled = YES;
    }
    return self;
}

#pragma mark -  处理原始的string
// 获取点击时间的string数组
-(NSArray *)clickStringsFrom:(NSString *)newString{
    NSMutableArray *arr = [NSMutableArray array];
    
    // 评论的人与回复人
    Body *Cbody = [[Body alloc] init];
    Cbody.name = @"C大叔";
    NSRange range = NSMakeRange(0, Cbody.name.length);
    Cbody.range = range;
    
    Body *Bbody = [[Body alloc] init];
    Bbody.name = @"B大叔";
    NSRange Brange = NSMakeRange(Cbody.range.length + Cbody.range.location + 2, Bbody.name.length);
    Bbody.range = Brange;
    
    [arr addObject:Cbody];
    [arr addObject:Bbody];
    
    
    NSString *regerStr = newString;
    // 主题
    NSError *thmemError;
    NSRegularExpression *thmemRegular = [[NSRegularExpression alloc] initWithPattern:ClickThemeItemPattern options:0 error:&thmemError];
    NSArray *themeArr = [thmemRegular matchesInString:regerStr options:0 range:NSMakeRange(0, regerStr.length)];
    if (!thmemError && themeArr.count > 0) {
        
        for (int i = 0; i < themeArr.count; i++) {
            NSRange range = [themeArr[i] range];
            NSString *themeTitle = [regerStr substringWithRange:range];
            
            Theme *theme = [[Theme alloc] init];
            theme.range = range;
            theme.themeTitle = themeTitle;
            [arr addObject:theme];
        }
    }
    
    //@人物
    NSError *actError;
    NSRegularExpression *actRegular = [[NSRegularExpression alloc] initWithPattern:ClickActItemPattern options:0 error:&actError];
    
    NSArray *bodyArr = [actRegular matchesInString:regerStr options:0 range:NSMakeRange(0, regerStr.length)];
    if (!actError && bodyArr.count > 0) {
        
        for (int i = 0; i < bodyArr.count; i++) {
            NSRange range = [bodyArr[i] range];
            NSString *name = [regerStr substringWithRange:range];
            
            Body *theme = [[Body alloc] init];
            theme.range = range;
            theme.name = name;
            [arr addObject:theme];
        }
    }
    
    return arr;
    
}

// 生成attrEmotionString
-(NSAttributedString *)attrEmotionString:(NSString *)string withRanges:(NSArray *)ranges{
    
    NSMutableAttributedString  *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    CTFontRef helvetica = CTFontCreateWithName(CFSTR("Helvetica"),15, NULL);
    [attributedString addAttribute:(id)kCTFontAttributeName value: (id)CFBridgingRelease(helvetica) range:NSMakeRange(0,[attributedString.string length])];
    
    for (id obj in self.clickArr) {
        
        if ([obj isKindOfClass:[Body class]]) {
            
            Body *body = (Body *)obj;
            [attributedString addAttributes:@{(id)kCTForegroundColorAttributeName:[UIColor blueColor]} range:body.range];
            
        }else if ([obj isKindOfClass:[Theme class]]){
            
            Theme *theme = (Theme *)obj;
            [attributedString addAttributes:@{(id)kCTForegroundColorAttributeName:[UIColor greenColor]} range:theme.range];
        }
    }
    
    for(NSInteger i = 0; i < [ranges count]; i++)
    {
        NSRange range = NSRangeFromString([ranges objectAtIndex:i]);
        NSString *emotionName = [_emojiNames objectAtIndex:i];
        [attributedString addAttribute:AttributedImageNameKey value:emotionName range:range];
        [attributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)newEmotionRunDelegate() range:range];
    }

    
    return attributedString;
}

// 获取表情名称
-(void)getEmojiNames_ranges:(NSString *)string{
    
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:EmotionItemPattern options:0 error:nil];
    
    NSArray *regulars = [regular matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    if (regulars.count < 1) {
        
        return;
    }
    
    _emojiNames = [NSMutableArray arrayWithCapacity:0];
    _emojiRanges = [NSMutableArray arrayWithCapacity:0];
    for (NSTextCheckingResult *result in regulars) {
        
        // 得到表情的名字
        NSRange range = [result range];
        NSString *subString = [string substringWithRange:range];
        [_emojiNames addObject:subString];
        [_emojiRanges addObject:[NSValue valueWithRange:range]];
    }
    
}

//

- (NSString *)replaceCharactersAtIndexes:(NSArray *)indexes withString:(NSString *)aString
{
    NSAssert(indexes != nil, @"%s: indexes 不可以为nil", __PRETTY_FUNCTION__);
    NSAssert(aString != nil, @"%s: aString 不可以为nil", __PRETTY_FUNCTION__);
    
    
    NSUInteger offset = 0;
    NSMutableString *raw = [NSMutableString stringWithString:_originalEmojiString];
    
    NSInteger prevLength = 0;
    for(NSInteger i = 0; i < [indexes count]; i++)
    {
        @autoreleasepool {
            NSRange range = [[indexes objectAtIndex:i] rangeValue];
            prevLength = range.length;
            
            range.location -= offset;
            [raw replaceCharactersInRange:range withString:aString];
            offset = offset + prevLength - [aString length];
        }
    }
    
    
    return raw;
}

-(void)comperString:(NSString *)string{
    
    _originalEmojiString = string;
    
    // 获取表情字符数组与表情字符ranges
   [self getEmojiNames_ranges:string];
    
    // 用@" "替换表情字符
    NSString *newString = @"";
    if (_emojiNames.count < 1) {
        newString = string;
    }
    else
        newString = [self replaceCharactersAtIndexes:_emojiRanges withString:@" "];
    
    // 获取可点击字符的数组(数组元素对象参照Body类)
    self.clickArr = [self clickStringsFrom:newString];
    
    NSArray *newRanges = nil;
    newRanges = [[NSArray arrayWithArray:_emojiRanges] offsetRangesInArrayBy:[@" " length]];


    self.attrEmotionString = [self attrEmotionString:newString withRanges:newRanges];

    [self setNeedsDisplay];
}

#pragma mark - Run delegate  表情占位符字体代理

CTRunDelegateRef newEmotionRunDelegate()
{
    static NSString *emotionRunName = @"com.cocoabit.CBEmotionView.emotionRunName";
    
    CTRunDelegateCallbacks imageCallbacks;
    imageCallbacks.version = kCTRunDelegateVersion1;
    imageCallbacks.dealloc = WFRunDelegateDeallocCallback;
    imageCallbacks.getAscent = WFRunDelegateGetAscentCallback;
    imageCallbacks.getDescent = WFRunDelegateGetDescentCallback;
    imageCallbacks.getWidth = WFRunDelegateGetWidthCallback;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks,
                                                       (__bridge void *)(emotionRunName));
    
    return runDelegate;
}

void WFRunDelegateDeallocCallback( void* refCon )
{
    // CFRelease(refCon);
}

CGFloat WFRunDelegateGetAscentCallback( void *refCon )
{
    return 15;
}

CGFloat WFRunDelegateGetDescentCallback(void *refCon)
{
    return 0.0;
}

CGFloat WFRunDelegateGetWidthCallback(void *refCon)
{
    // EmotionImageWidth + 2 * ImageLeftPadding
    return  17.0;
}

#pragma mark - 绘制

// 通过表情名获得表情的图片
- (UIImage *)getEmotionForKey:(NSString *)key
{
    NSString *nameStr = [NSString stringWithFormat:@"%@.png",key];
    return [UIImage imageNamed:nameStr];
}

// 生成每个表情的 frame 坐标
static inline
CGPoint Emoji_Origin_For_Line(CTLineRef line, CGPoint lineOrigin, CTRunRef run)
{
    CGFloat x = lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL) + ImageLeftPadding;
    CGFloat y = lineOrigin.y - ImageTopPadding;
    return CGPointMake(x, y);
}

// 绘制每行中的表情
void Draw_Emoji_For_Line(CGContextRef context, CTLineRef line, id owner, CGPoint lineOrigin)
{
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    
    // 统计有多少个run
    NSUInteger count = CFArrayGetCount(runs);

    // 遍历查找表情run
    for(NSInteger i = 0; i < count; i++)
    {
        CTRunRef aRun = CFArrayGetValueAtIndex(runs, i);
        CFDictionaryRef attributes = CTRunGetAttributes(aRun);
        NSString *emojiName = (NSString *)CFDictionaryGetValue(attributes, AttributedImageNameKey);
        if (emojiName)
        {
            // 画表情
            CGRect imageRect = CGRectZero;
            imageRect.origin = Emoji_Origin_For_Line(line, lineOrigin, aRun);
            imageRect.size = CGSizeMake(EmotionImageWidth, EmotionImageWidth);
            CGImageRef img = [[owner getEmotionForKey:emojiName] CGImage];
            CGContextDrawImage(context, imageRect, img);
        }
    }
}

// @利用Line 绘制.... 还有一种方式利用CTFrame绘制
- (void)drawRect:(CGRect)rect {
    
    // 获取上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 翻转
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -15);
    
    //获取CTFramesetterRef
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attrEmotionString);
    
    //获取CTTypesetterRef
    _typesetterRef = CTFramesetterGetTypesetter(framesetterRef);
    
    // 使用 CTFramesetter 创建您要用于渲染文本的一个或多个帧
    
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat y = 0;
    CFIndex start = 0;
    NSInteger length = [self.attrEmotionString length];
    while (start < length)
    {
        // 推断一行能放多少字
        CFIndex count = CTTypesetterSuggestClusterBreak(_typesetterRef, start, w);
        
        // 根据字数创建行
        CTLineRef line = CTTypesetterCreateLine(_typesetterRef, CFRangeMake(start, count));
        
        //设置行的Position
        CGContextSetTextPosition(context, 0, y);
        
        // 画字
        CTLineDraw(line, context);
        
        // 画表情
        Draw_Emoji_For_Line(context, line, self, CGPointMake(0, y));
        
        start += count;
        y -= 15 +10;
        CFRelease(line);
        
    }
    
    UIGraphicsPopContext();
    
}

#pragma mark - 单机事件

-(void)tapMyself:(UITapGestureRecognizer *)tap{
    
    CGPoint point = [tap locationInView:self];
    
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat y = 0;
    CFIndex start = 0;
    NSInteger length = [self.attrEmotionString length];
    
    while (start < length)
    {
        
        // 推断一行能放多少字
        CFIndex count = CTTypesetterSuggestClusterBreak(_typesetterRef, start, w);
        
        // 根据字数创建行
        CTLineRef line = CTTypesetterCreateLine(_typesetterRef, CFRangeMake(start, count));
        
        CGFloat ascent, descent;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        
        CGRect rect = CGRectMake(0, -y, lineWidth, ascent+descent);
        
        // 判断是否点击在这行中
        if (CGRectContainsPoint(rect, point)) {
            
            // 获取点击到的字在这一行的索引
            CFIndex index = CTLineGetStringIndexForPosition(line, point);
            
            NSInteger i = [self checkClickStringContainsPointAtIndex:index];
            
            if (i>=0) {
                
                id obj = self.clickArr[i];
                
                NSRange temRange = NSMakeRange(NSNotFound, 0);
                
                    if ([obj isKindOfClass:[Body class]]) {
                        
                        Body *body = (Body *)obj;
                        temRange = body.range;
                        NSLog(@"%@",body.name);
                        
                    }else if ([obj isKindOfClass:[Theme class]]){
                        
                        Theme *theme = (Theme *)obj;
                        NSLog(@"%@",theme.themeTitle);
                         temRange = theme.range;
                    }
                
                    NSArray *rects   = [self getSelectedCGRectWithClickRange:temRange];
                    [self drawViewFromRects:rects withDictValue:nil];
                }
            }
        
        start += count;
        y -= 15 + 10;
        CFRelease(line);
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [_selectionsViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
        });
        
    }

}

-(NSInteger )checkClickStringContainsPointAtIndex:(CFIndex )index{
    
    for (id obj  in self.clickArr) {
        
         NSRange aRange  =  [obj range];
        
        if (index > aRange.location && index < aRange.location + aRange.length) {
                    
                return [self.clickArr indexOfObject:obj];
        }
    }
    
    return -1;
    
}

- (NSMutableArray *)getSelectedCGRectWithClickRange:(NSRange)tempRange{
    
    NSMutableArray *clickRects = [[NSMutableArray alloc] init];
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat y = 0;
    CFIndex start = 0;
    NSInteger length = [_attrEmotionString length];
    
    while (start < length)
    {
        
        CFIndex count = CTTypesetterSuggestClusterBreak(_typesetterRef, start, w);
        CTLineRef line = CTTypesetterCreateLine(_typesetterRef, CFRangeMake(start, count));
        start += count;
        
        // 获取line的cfrange
        CFRange lineRange = CTLineGetStringRange(line);
        
        //cfrange转换成nsrange
        NSRange range = NSMakeRange(lineRange.location==kCFNotFound ? NSNotFound : lineRange.location, lineRange.length);
        
        NSRange intersection = [self rangeIntersection:range withSecond:tempRange];
        if (intersection.length > 0)
        {
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, intersection.location, NULL);//获取整段文字中charIndex位置的字符相对line的原点的x值
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, intersection.location + intersection.length, NULL);
            
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGRect selectionRect = CGRectMake(xStart, -y, xEnd -  xStart , ascent + descent);//所画选择之后背景的 大小 和起始坐标
            [clickRects addObject:NSStringFromCGRect(selectionRect)];
            
        }
        
        y -= 15 + 10;
        CFRelease(line);
        
    }
    return clickRects;
    
}

//超出1行 处理
- (NSRange)rangeIntersection:(NSRange)first withSecond:(NSRange)second
{
    NSRange result = NSMakeRange(NSNotFound, 0);
    if (first.location > second.location)
    {
        NSRange tmp = first;
        first = second;
        second = tmp;
    }
    if (second.location < first.location + first.length)
    {
        result.location = second.location;
        NSUInteger end = MIN(first.location + first.length, second.location + second.length);
        result.length = end - result.location;
    }
    return result;
}


- (void)drawViewFromRects:(NSArray *)array withDictValue:(NSString *)value
{
    //用户名可能超过1行的内容 所以记录在数组里，有多少元素 就有多少view
    // selectedViewLinesF = array.count;
    
    for (int i = 0; i < [array count]; i++) {
        
        UIView *selectedView = [[UIView alloc] init];
        selectedView.frame = CGRectFromString([array objectAtIndex:i]);
        selectedView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
//
        [self addSubview:selectedView];
        [_selectionsViews addObject:selectedView];
        
    }
    
}


@end

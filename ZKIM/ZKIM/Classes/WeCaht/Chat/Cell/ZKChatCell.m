//
//  ZKChatCell.m
//  ZKIM
//
//  Created by ZK on 16/9/29.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import "ZKChatCell.h"
#import "ZKChatLayout.h"
#import "UIImageView+WebCache.h"

#define kMaxAudioBtnWidth    SCREEN_WIDTH*0.6
#define kMinAudioBtnWidth    70.f

@interface ZKChatCell ()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, assign) BOOL        isMine; //我的消息
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong) UILabel     *timeLabel;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UIButton *sendFailBtn;

// Text Cell
@property (nonatomic, strong) UIImageView *bubbleImageView;
@property (nonatomic, strong) YYLabel     *contentLabel;

// Image Cell
@property (nonatomic, strong) UIImageView *contentImageView;

// Voice Cell
@property (nonatomic, strong) UIButton *audioBtn;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIImageView *hornImageView; //!< 小喇叭

@end

@implementation ZKChatCell

#pragma mark - Init

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSeparatorStyleNone;
    
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.size = CGSizeMake(40.f, 40.f);
    _iconImageView.top = 10.f;
    _iconImageView.image = [UIImage imageNamed:@"me"];
    [self.contentView addSubview:_iconImageView];
    
    _bubbleImageView = [[UIImageView alloc] init];
    [self.contentView addSubview:_bubbleImageView];
    
    _contentLabel = [[YYLabel alloc] init];
    _contentLabel.backgroundColor = [UIColor clearColor];
    _contentLabel.displaysAsynchronously = NO;
    _contentLabel.fadeOnAsynchronouslyDisplay = NO;
    _contentLabel.ignoreCommonProperties = YES;
    [self.contentView addSubview:_contentLabel];
    
    _timeLabel = [[UILabel alloc] init];
    [self.contentView addSubview:_timeLabel];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    _timeLabel.font = [UIFont systemFontOfSize:12.f];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.backgroundColor = RGBCOLOR(195, 195, 195);
    _timeLabel.text = @"昨天 10:26";
    _timeLabel.top = 8.f;
    _timeLabel.height = 18.f;
    _timeLabel.layer.cornerRadius = 3.5f;
    _timeLabel.layer.masksToBounds = YES;
    
    _contentImageView = [UIImageView new];
    [self.contentView addSubview:_contentImageView];
    _contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    _contentImageView.clipsToBounds = YES;
    _contentImageView.backgroundColor = [UIColor redColor];
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_indicatorView];
    
    _sendFailBtn = [[UIButton alloc] init];
    [_sendFailBtn setImage:[UIImage imageNamed:@"MessageSendFail"] forState:UIControlStateNormal];
    _sendFailBtn.size = (CGSize){35.f, 35.f};
    [_sendFailBtn addTarget:self action:@selector(sendFailBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    _sendFailBtn.hidden = YES;
    _sendFailBtn.contentMode = UIViewContentModeCenter;
    [self.contentView addSubview:_sendFailBtn];
    
    _audioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.contentView addSubview:_audioBtn];
    _audioBtn.backgroundColor = [UIColor clearColor];
    _audioBtn.height = 55.f;
    
    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_contentLabel addGestureRecognizer:_longPress];
}

#pragma mark - Public

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *cellID = @"ZKChatCell";
    ZKChatCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[ZKChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    return cell;
}

#pragma mark - Gesture

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    
    UIMenuController *copyMenu = [UIMenuController sharedMenuController];
    
    UIMenuItem *copyItem = [[UIMenuItem alloc]
                            initWithTitle:@"复制"action:NSSelectorFromString(@"copyAction:")];
    UIMenuItem *deleteItem = [[UIMenuItem alloc]
                              initWithTitle:@"删除"action:NSSelectorFromString(@"deleteAction:")];
    
    [copyMenu setMenuItems:[NSArray arrayWithObjects:deleteItem, nil]];
    
    NSString *jsonValue = [@{@"text":_cellLayout.message.contentText, @"index":@(1)} json];
    
    [copyMenu setMenuItems:[NSArray arrayWithObjects:copyItem,deleteItem, nil]];
    
    BOOL labelResponse = [recognizer.view isKindOfClass:[UILabel class]] || [recognizer.view isKindOfClass:[YYLabel class]];
    if (labelResponse) {
        [_bubbleImageView becomeFirstResponder];
        [copyMenu setTargetRect:_bubbleImageView.bounds inView:_bubbleImageView];
        _bubbleImageView.accessibilityValue = jsonValue;
    }
    else{
        [recognizer.view becomeFirstResponder];
        [copyMenu setTargetRect:recognizer.view.bounds inView:recognizer.view];
        recognizer.view.accessibilityValue = jsonValue;
    }
    [copyMenu setMenuVisible:YES animated:YES];
    
    [self setSelected:YES animated:YES];
}

#pragma mark - Setter

- (void)setCellLayout:(ZKChatLayout *)cellLayout
{
    _cellLayout = cellLayout;
    _isMine = cellLayout.message.isMine;
    _contentLabel.textLayout = cellLayout.contentTextLayout;
    
    [self updateCellWithType:cellLayout.message.type];
}

- (void)updateCellWithType:(ZKMessageBodyType)type
{
    switch (type) {
        case ZKMessageBodyTypeText: {
            [self updateTextCell];
        } break;
        case ZKMessageBodyTypeImage: {
            [self updateImageCell];
        } break;
        case ZKMessageBodyTypeAudio: {
            [self updateAudioCell];
        } break;
            
        default:
            break;
    }
    
    _sendFailBtn.hidden = YES;
    BOOL showLoading = _cellLayout.message.emmsg.status == EMMessageStatusDelivering;
    if (showLoading) {
        [_indicatorView startAnimating];
    }
    else {
        [_indicatorView stopAnimating];
        if (_cellLayout.message.emmsg.status == EMMessageStatusFailed) {
            _sendFailBtn.hidden = NO;
        }
    }
}

- (void)updateAudioCell
{
    _contentLabel.hidden = YES;
    _bubbleImageView.hidden = YES;
    _contentImageView.hidden = YES;
    _audioBtn.hidden = NO;
    
    _audioBtn.width = [self calculateAudioWidth];
    
    [_audioBtn setBackgroundImage:[self getTextBubbleImage] forState:UIControlStateNormal];
    
    if (_cellLayout.message.needShowTime) {
        _timeLabel.hidden    = NO;
        NSDate *time = [NSDate dateWithTimeStamp:_cellLayout.message.timestamp];
        NSString *timeStr = [self stringWithDate:time];
        _timeLabel.text = timeStr;
        _timeLabel.width = [timeStr stringWidthWithFont:_timeLabel.font height:MAXFLOAT]+8.f;
        _timeLabel.centerX = SCREEN_WIDTH*0.5;
        _audioBtn.top = 35.f;
        _iconImageView.top = _audioBtn.top;
    }
    else {
        _timeLabel.hidden     = YES;
        _audioBtn.top = 10.f;
        _iconImageView.top = _audioBtn.top;
    }
    
    _indicatorView.centerY = CGRectGetMidY(_bubbleImageView.frame);
    _sendFailBtn.centerY = _indicatorView.centerY;
    
    if (_isMine) {
        _iconImageView.right   = SCREEN_WIDTH - 10.f;
        _audioBtn.right = CGRectGetMinX(_iconImageView.frame)-5.f;
        _indicatorView.right = CGRectGetMinX(_bubbleImageView.frame);
        _sendFailBtn.right = _indicatorView.right;
    }
    else {
        _iconImageView.left   = 10.f;
        _audioBtn.left = CGRectGetMaxX(_iconImageView.frame)+5.f;
    }
}

- (void)updateImageCell
{
    _contentLabel.hidden = YES;
    _bubbleImageView.hidden = YES;
    _audioBtn.hidden = YES;
    _contentImageView.hidden = NO;
    
    ZKMessage *message = _cellLayout.message;
    EMImageMessageBody *body = (EMImageMessageBody *)_cellLayout.message.emmsg.body;
    if ([FileManager fileExistsAtPath:body.localPath]) {
        _contentImageView.image = [UIImage imageWithContentsOfFile:body.localPath];
    }
    else {
        if (message.thumbnailImage) {
            _contentImageView.image = message.thumbnailImage;
        }
        else if (message.thumbnailRemotePath.length) {
            [_contentImageView setImageURL:[NSURL URLWithString:message.thumbnailRemotePath]];
        }
        else if (message.largeImage) {
            _contentImageView.image = message.largeImage;
        }
        else if (message.largeImageRemotePath.length) {
            [_contentImageView setImageURL:[NSURL URLWithString:message.largeImageRemotePath]];
        }
    }
    _contentImageView.size = _cellLayout.imageSize;
    
    if (_cellLayout.message.needShowTime) {
        _timeLabel.hidden    = NO;
        NSDate *time = [NSDate dateWithTimeStamp:_cellLayout.message.timestamp];
        NSString *timeStr = [self stringWithDate:time];
        _timeLabel.text = timeStr;
        _timeLabel.width = [timeStr stringWidthWithFont:_timeLabel.font height:MAXFLOAT]+8.f;
        _timeLabel.centerX = SCREEN_WIDTH*0.5;
        _contentImageView.top = 35.f;
        _iconImageView.top    = _contentImageView.top;
    }
    else {
        _timeLabel.hidden     = YES;
        _contentImageView.top = 10.f;
        _iconImageView.top    = _contentImageView.top;
    }
    
    _indicatorView.centerY = CGRectGetMidY(_bubbleImageView.frame);
    _sendFailBtn.centerY = _indicatorView.centerY;
    
    if (_isMine) {
        _iconImageView.right   = SCREEN_WIDTH - 10.f;
        _contentImageView.right = CGRectGetMinX(_iconImageView.frame)-5.f;
        _indicatorView.right = CGRectGetMinX(_bubbleImageView.frame);
        _sendFailBtn.right = _indicatorView.right;
    }
    else {
        _iconImageView.left   = 10.f;
        _contentImageView.left = CGRectGetMaxX(_iconImageView.frame)+5.f;
    }
    [self addMaskLayerForImageView];
}

- (void)updateTextCell
{
    _contentLabel.hidden = NO;
    _bubbleImageView.hidden = NO;
    _contentImageView.hidden = YES;
    _audioBtn.hidden = YES;
    
    _bubbleImageView.image = [self getTextBubbleImage];
    
    CGFloat labelWidth    = _cellLayout.contentTextLayout.textBoundingSize.width;
    CGFloat labelHeight   = _cellLayout.contentTextLayout.textBoundingSize.height;
    _contentLabel.size    = _cellLayout.contentTextLayout.textBoundingSize;
    _bubbleImageView.size = CGSizeMake(labelWidth+40.f, labelHeight+40.f);
    
    if (_cellLayout.message.needShowTime) {
        _timeLabel.hidden    = NO;
        NSDate *time = [NSDate dateWithTimeStamp:_cellLayout.message.timestamp];
        NSString *timeStr = [self stringWithDate:time];
        _timeLabel.text = timeStr;
        _timeLabel.width = [timeStr stringWidthWithFont:_timeLabel.font height:MAXFLOAT]+8.f;
        _timeLabel.centerX = SCREEN_WIDTH*0.5;
        _bubbleImageView.top = 35.f;
        _iconImageView.top   = _bubbleImageView.top;
        _contentLabel.top    = _bubbleImageView.top+15.f;
    }
    else {
        _timeLabel.hidden    = YES;
        _bubbleImageView.top = 10.f;
        _iconImageView.top   = _bubbleImageView.top;
        _contentLabel.top    = _bubbleImageView.top+15;
    }
    
    _indicatorView.centerY = CGRectGetMidY(_bubbleImageView.frame);
    _sendFailBtn.centerY = _indicatorView.centerY;
    
    if (_isMine) {
        _iconImageView.right   = SCREEN_WIDTH - 10.f;
        _bubbleImageView.right = CGRectGetMinX(_iconImageView.frame)-5.f;
        _contentLabel.right    = CGRectGetMinX(_iconImageView.frame)-25.f;
        _indicatorView.right = CGRectGetMinX(_bubbleImageView.frame);
        _sendFailBtn.right = _indicatorView.right;
    }
    else {
        _iconImageView.left   = 10.f;
        _bubbleImageView.left = CGRectGetMaxX(_iconImageView.frame)+5.f;
        _contentLabel.left    = CGRectGetMaxX(_iconImageView.frame)+25.f;
    }
}

#pragma mark - Private

- (CGFloat)calculateAudioWidth
{
    int voiceDuration = _cellLayout.message.audioDuration;
    CGFloat width = 0;
    
    if (voiceDuration > 2) {
        __block CGFloat length;
        CGFloat lengthUnit = 10.f;
        // 1-2 长度固定, 2-10s每秒增加一个单位, 10-60s每10s增加一个单位
        do {
            if (voiceDuration <= 10) {
                length = lengthUnit*(voiceDuration-2);
                break;
            }
            if (voiceDuration > 10) {
                length = lengthUnit*(10-2) + lengthUnit*((voiceDuration-2)/10);
                break;
            }
        } while (NO);
        width = kMinAudioBtnWidth+length;
    }
    else {
        width = kMinAudioBtnWidth;
    }
    return width;
}

- (void)addMaskLayerForImageView
{
    UIImage *bubbleImage = [self getImageBubbleImage];
    UIEdgeInsets edgeInsets = bubbleImage.capInsets;
    //    为图片添加遮罩
    CALayer* iconLayer = [CALayer layer];
    iconLayer.frame = _contentImageView.bounds;
    iconLayer.contents = (id)bubbleImage.CGImage;
    iconLayer.contentsScale = [UIScreen mainScreen].scale;
    
    iconLayer.contentsCenter = CGRectMake(edgeInsets.left/bubbleImage.size.width,
                                          edgeInsets.top/bubbleImage.size.height,
                                          1.0/bubbleImage.size.width,
                                          1.0/bubbleImage.size.height);
    _contentImageView.layer.mask = iconLayer;
}

- (UIImage *)getTextBubbleImage
{
    UIImage *oriImage = nil;
    if (_isMine) {
        oriImage = [[UIImage imageNamed:@"SenderTextNodeBkg"] tintedImageWithColor:RGBACOLOR(35, 130, 251, .87) style:UIImageTintStyleKeepingAlpha];
    }
    else {
        oriImage = [UIImage imageNamed:@"ReceiverTextNodeBkg"];
    }
    CGSize size = oriImage.size;
    UIImage *bubbleImage = [oriImage resizableImageWithCapInsets:UIEdgeInsetsMake(size.height*0.5, size.width*0.5, size.height*0.5, size.width*0.5)];
    return bubbleImage;
}

- (UIImage *)getImageBubbleImage
{
    UIImage *oriImage = nil;
    if (_isMine) {
        oriImage = [UIImage imageNamed:@"chat_bubble_right_bg"];
    }
    else {
        oriImage = [UIImage imageNamed:@"chat_bubble_left_bg"];
    }
    CGSize size = oriImage.size;
    UIImage *bubbleImage = [oriImage resizableImageWithCapInsets:UIEdgeInsetsMake(size.height*0.5, size.width*0.5, size.height*0.5, size.width*0.5)];
    
    return [bubbleImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (NSString *)stringWithDate:(NSDate *)date
{
    NSString *dateStr = @"";
    if ([date dayIndexSinceNow] < 0) {
        //超过两天
        switch ([date dayIndexSinceNow]) {
            case -1:
                dateStr = [date stringWithDateFormat:@"昨天 HH:mm"];
                break;
            case -2:
                dateStr = [date stringWithDateFormat:@"前天 HH:mm"];
                break;
            default:
                if ([[date allDateComponent] year] != [[[NSDate date] allDateComponent] year]) {
                    dateStr = [date stringWithDateFormat:@"yyyy年MM月dd日 HH:mm"];
                }else{
                    dateStr = [date stringWithDateFormat:@"MM月dd日 HH:mm"];
                }
                break;
        }
    } else {
        dateStr = [dateStr stringByAppendingString:([date stringWithDateFormat:@"HH:mm"]?:@"")];
    }
    return dateStr;
}

#pragma mark - Actions

- (void)sendFailBtnClick:(UIButton *)btn
{
    ZKAlertView *alertView = [ZKAlertView initWithMessage:@"是否重新发送该条信息?" iconType:ZKAlertIconTypeAttention cancelButtonTitle:@"取消" otherButtonTitles:@"重发", nil];
    [alertView showWithCompletionBlock:^(NSInteger buttonIndex) {
        DLog(@"=======%zd", buttonIndex);
    }];
}

@end

////////////////////

@implementation UIImageView (Message)
#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return true;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyAction:)){
        return YES;
    }
    if (action == @selector(deleteAction:)){
        return YES;
    }
    return NO;
}

- (void)copyAction:(id)sender
{
    NSDictionary *dic = [self.accessibilityValue object];
    
    [[UIPasteboard generalPasteboard] setString:dic[@"text"]];
}

- (void)deleteAction:(id)sender
{
    NSDictionary *dic = [self.accessibilityValue object];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dele" object:dic[@"index"]];
}

@end


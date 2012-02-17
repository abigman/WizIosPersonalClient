//
//  NewNoteView.m
//  Wiz
//
//  Created by dong zhao on 11-11-16.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "NewNoteView.h"
#import "UIView-TagExtensions.h"
#import "WizIndex.h"
#import "Globals/WizGlobalData.h"
#import "Globals/WizGlobals.h"
#import "TagSelectView.h"
#import "AttachmentsView.h"
#import "WizApi.h"
#import "SelectFloderView.h"
#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "PickViewController.h"
#import "VoiceRecognition.h"
#import "WizDictionaryMessage.h"
#import "RecentDcoumentListView.h"
#import "CommonString.h"
#import "WizPhoneNotificationMessage.h"
#import "WizPadCheckAttachments.h"


#define KEYHIDDEN 209
#define ATTACHMENTTEMPFLITER @"attchmentTempFliter"
#define HIDDENTTAG  300
#define NOHIDDENTTAG 301

#define INFOVIEWHEIGN  110
#define ATTACHMENTSVIEWHEIGH 145
@implementation NewNoteView
@synthesize session;
@synthesize recorder;
@synthesize accountUserId;
@synthesize timer;
@synthesize recoderLabel;
@synthesize titleTextFiled;
@synthesize bodyTextField;
@synthesize attachmentsCountLabel;
@synthesize documentTags;
@synthesize documentFloder;
@synthesize currentRecodingFilePath;
@synthesize isNewDocument;
@synthesize attachmentsSourcePaths;
@synthesize documentGUID;
@synthesize voiceInput;
@synthesize keyControl;
@synthesize addAttachmentView;
@synthesize addDocumentInfoView;
@synthesize inputContentView;
@synthesize attachmentsTableviewEntryButton;
@synthesize currentTime ;
@synthesize firtResponser;
-(void) dealloc
{
    self.firtResponser = nil;
    self.session = nil;
    self.recorder = nil;
    self.accountUserId = nil;
    self.titleTextFiled = nil;
    self.bodyTextField = nil;
    self.attachmentsCountLabel = nil;
    self.currentRecodingFilePath = nil;
    self.recoderLabel = nil;
    self.attachmentsSourcePaths =nil;
    self.voiceInput = nil;
    self.keyControl=nil;
    self.addDocumentInfoView = nil;
    self.addAttachmentView = nil;
    self.inputContentView = nil;
    self.attachmentsTableviewEntryButton = nil;
    self.currentTime = 0.0;
    [super dealloc];
}


-(void) displayAttachmentsCount
{
    if (nil == self.attachmentsSourcePaths) {
        NSLog(@"nil");
    }
    NSString* displayString = [NSString stringWithFormat:@"%@:%d",NSLocalizedString(@"Attachments", nil), [self.attachmentsSourcePaths count]];
    [self.attachmentsTableviewEntryButton setTitle:displayString forState:UIControlStateNormal];
}

-(void) updateAttachment:(NSString*) filePath
{   
    [self.attachmentsSourcePaths addObject:filePath];
    [self displayAttachmentsCount];
}

-(void) stopRecording
{
    [self.recorder stop];
    [self.timer invalidate];
    self.currentTime = 0.0f;
    [self updateAttachment:self.currentRecodingFilePath];
}

-(BOOL) startAudioSession
{
    NSError* error;
    self.session = [AVAudioSession sharedInstance];
    if(![self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error])
    {
        return NO;
    }
    if(![self.session setActive:YES error:&error])
    {
        return NO;
    }
    
    return self.session.inputIsAvailable;
}

-(void) updateTime
{
    self.currentTime += 0.1f;
    self.recoderLabel.text = [WizIndex timerStringFromTimerInver:self.currentTime];
}

-(BOOL) record
{
    NSError* error;
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    self.recoderLabel.text = @"start";
    [settings setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];
    [settings setValue:[NSNumber numberWithInt:1 ] forKey:AVNumberOfChannelsKey];
    [settings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    NSString* objectPath = [WizIndex documentFilePath:self.accountUserId documentGUID:ATTACHMENTTEMPFLITER];
    [WizGlobals ensurePathExists:objectPath];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateString = [formatter stringFromDate:[NSDate date]];
    [formatter release];
    NSString* audioFileName = [objectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.aif",dateString]];
    self.currentRecodingFilePath = [[audioFileName mutableCopy] autorelease];
    NSURL* url = [NSURL fileURLWithPath:audioFileName];
    self.recorder = [[[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error ] autorelease];
    if(!self.recorder)
    {
        return NO;
    }
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    if(![self.recorder prepareToRecord])
    {
        return NO;
    }
    if(![self.recorder record])
    {
        return NO;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    self.currentTime = 0.0f;
    [error release];
    return YES;
}


- (void) audioStartRecode
{
    UIImageView* first = (UIImageView*)[self.view viewWithTag:100];
    UIImageView* second = (UIImageView*) [self.view viewWithTag:101];
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:second cache:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:1.0];
    [first setAlpha:0.0f];
    [second setAlpha:1.0f];
    [self.view exchangeSubviewAtIndex:[[self.view subviews] indexOfObject:first]
                   withSubviewAtIndex:[[self.view subviews] indexOfObject:second] ];
    [UIView commitAnimations];
    [self record];
}

-(void) audioStopRecord
{
    UIImageView* first = (UIImageView*)[self.view viewWithTag:101];
    UIImageView* second = (UIImageView*) [self.view viewWithTag:100];
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:second cache:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:1.0];
    [first setAlpha:0.0f];
    [second setAlpha:1.0f];
    [self.view exchangeSubviewAtIndex:[[self.view subviews] indexOfObject:first]
                   withSubviewAtIndex:[[self.view subviews] indexOfObject:second] ];
    [UIView commitAnimations];
    [self stopRecording];
}

-(UIImage*) imageReduceRect:(NSString*) imageName
{
    UIImage* image = [UIImage imageNamed:imageName];
    return image;
    
}

-(void) keyHideOrShow
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3];
    [self.keyControl layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    [self.bodyTextField setFrame:CGRectMake(0.0, 31, 320, self.view.frame.size.height-30)];
    [self.keyControl setFrame:CGRectMake( 250, self.view.frame.size.height - 35, 50, 25)];
    [self.voiceInput setFrame:CGRectMake( 250, self.view.frame.size.height - 35, 50, 25)];
    self.voiceInput.hidden = YES;
    self.keyControl.hidden = YES;
    [UIView commitAnimations];
    [self.titleTextFiled resignFirstResponder];
    [self.bodyTextField resignFirstResponder];
}

-(void) tagViewSelect
{
    TagSelectView* tagView = [[TagSelectView alloc] initWithStyle:UITableViewStyleGrouped];
    tagView.documentTagsGUID = self.documentTags;
    tagView.accountUserId = self.accountUserId;
    [self.navigationController pushViewController:tagView animated:YES];
    [tagView release];
}

-(void) floderViewSelected
{
    SelectFloderView*  floderView = [[SelectFloderView alloc] initWithStyle:UITableViewStyleGrouped];
    floderView.accountUserID = self.accountUserId;
    floderView.selectedFloderString = self.documentFloder;
    [self.navigationController pushViewController:floderView animated:YES];
    [floderView release];
}
-(void) photoViewSelected
{
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];    
	ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    [albumController setParent:elcPicker];
	[elcPicker setDelegate:self];
    [self.navigationController presentModalViewController:elcPicker animated:YES];
    [albumController release];
    [elcPicker release];
}



- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    
	[self dismissModalViewControllerAnimated:YES];
}
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    for(NSDictionary* each in info)
    {
        WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
        UIImage* image = [each objectForKey:@"UIImagePickerControllerOriginalImage"];
        image = [image compressedImage:[index imageQualityValue]];
        NSString* objectPath = [WizIndex documentFilePath:self.accountUserId documentGUID:ATTACHMENTTEMPFLITER];
        [WizGlobals ensurePathExists:objectPath];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString* dateString = [formatter stringFromDate:[NSDate date]];
        [formatter release];
        NSString* fileNamePath = [objectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",dateString]];
        [UIImagePNGRepresentation(image) writeToFile:fileNamePath atomically:YES];
        [self updateAttachment:fileNamePath];
    }
    [self elcImagePickerControllerDidCancel:picker];
}
-(void) attachmentsViewSelect
{
    WizPadCheckAttachments* checkAttachments = [[WizPadCheckAttachments alloc] init];
    checkAttachments.source = self.attachmentsSourcePaths;
    [self.navigationController pushViewController:checkAttachments animated:YES];
    [checkAttachments release];
}
-(void) addSelcetorToView:(SEL)sel :(UIView*)view
{
    UITapGestureRecognizer* tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:sel] autorelease];
    tap.numberOfTapsRequired =1;
    tap.numberOfTouchesRequired =1;
    [view addGestureRecognizer:tap];
    view.userInteractionEnabled = YES;
}
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    image = [image compressedImage:[index imageQualityValue]];
    NSString* objectPath = [WizIndex documentFilePath:self.accountUserId documentGUID:ATTACHMENTTEMPFLITER];
    [WizGlobals ensurePathExists:objectPath];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateString = [formatter stringFromDate:[NSDate date]];
    [formatter release];
    NSString* fileNamePath = [objectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",dateString]];
    [UIImagePNGRepresentation(image) writeToFile:fileNamePath atomically:YES];
    [self updateAttachment:fileNamePath];
    [picker dismissModalViewControllerAnimated:YES];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil,nil);
    [picker.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

-(void) takePhotoViewSelcevted
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController* picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

- (void) buildAddAttachmentsView
{
    if (nil == self.addAttachmentView) {
        
        UIView* addAttach = [[UIView alloc] initWithFrame:CGRectMake(0.0, -ATTACHMENTSVIEWHEIGH, 320, 100)];
        self.addAttachmentView = addAttach;
        [addAttach release];
        UIImageView* bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attachBack"]];
        bg.frame = CGRectMake(0.0, 0.0, 320, 110);
        [self.addAttachmentView addSubview:bg];
        [bg release];
        self.addAttachmentView.tag = HIDDENTTAG;
        self.addAttachmentView.backgroundColor = [UIColor colorWithRed:215.0/255 green:215.0/255 blue:215.0/255 alpha:1.0];
    }
    UIImageView* audioRecording = [[UIImageView alloc] initWithFrame:CGRectMake(5, 1, 102, 107)];
    audioRecording.backgroundColor = [UIColor clearColor];
    audioRecording.tag = 101;
    UIImageView* back = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"recorderTimeBack"]];
    back.frame = CGRectMake(10, 30, 80, 30);
    [audioRecording addSubview:back];
    [back release];
    [self addSelcetorToView:@selector(audioStopRecord) :audioRecording];
    audioRecording.userInteractionEnabled = YES;
    UILabel* stopLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 70, 100, 20)];
    stopLabel.backgroundColor = [UIColor clearColor];
    [stopLabel setFont:[UIFont systemFontOfSize:13]];
    [stopLabel setTextColor:[UIColor grayColor]];
    stopLabel.textAlignment = UITextAlignmentCenter;
    stopLabel.text = NSLocalizedString(@"Tap to stop", nil);
    [audioRecording addSubview:stopLabel];
    UILabel* recoderL = [[UILabel alloc]initWithFrame:CGRectMake(22, 35, 60, 20)] ;
    
    self.recoderLabel = recoderL;
    [recoderL release];
    [audioRecording addSubview:self.recoderLabel];
    [self.recoderLabel setFont:[UIFont systemFontOfSize:21]];
    self.recoderLabel.backgroundColor = [UIColor clearColor];
    
    [self.addAttachmentView addSubview:audioRecording];
    [audioRecording setAlpha:0.0f];
    
    //recoding start
    UIImageView* audioRecordStart = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 100, 90)];
    audioRecordStart.image = [self imageReduceRect:@"recorder"];
    audioRecordStart.tag = 100;
    [self addSelcetorToView:@selector(audioStartRecode) :audioRecordStart];
    audioRecordStart.userInteractionEnabled = YES;
    [self.addAttachmentView addSubview:audioRecordStart];
    UILabel* startLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 70, 100, 20)];
    startLabel.backgroundColor = [UIColor clearColor];
    [startLabel setFont:[UIFont systemFontOfSize:13]];
    [startLabel setTextColor:[UIColor grayColor]];
    startLabel.textAlignment = UITextAlignmentCenter;
    startLabel.text = NSLocalizedString(@"Record", nil);
    [audioRecordStart addSubview:startLabel];
    [audioRecording release];
    [audioRecordStart release];
    [startLabel release];
    [stopLabel release];
    // photo
    UIImageView* photo = [[UIImageView alloc] initWithFrame:CGRectMake(105  , 5, 100, 90)];
    photo.image = [self imageReduceRect:@"picture"];
    [self addSelcetorToView:@selector(photoViewSelected) :photo];
    [self.addAttachmentView addSubview:photo];
    UILabel* pictureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 70, 100, 20)];
    pictureLabel.backgroundColor = [UIColor clearColor];
    [pictureLabel setFont:[UIFont systemFontOfSize:13]];
    [pictureLabel setTextColor:[UIColor grayColor]];
    pictureLabel.textAlignment = UITextAlignmentCenter;
    pictureLabel.text = NSLocalizedString(@"Camera roll", nil);
    [photo addSubview:pictureLabel];
    [pictureLabel release];
    [photo release];
    
    UIImageView* buttonBack = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attachmentsButtonBack"]];
    buttonBack.frame = CGRectMake(5, 115, 310, 30);
    [self.addAttachmentView addSubview:buttonBack];
    [buttonBack release];
    self.attachmentsTableviewEntryButton = [[[UIButton alloc] initWithFrame:CGRectMake(5, 115, 310, 30)] autorelease];
    
    [self.attachmentsTableviewEntryButton setTitle:@"ddd" forState:UIControlStateNormal];
    [self.attachmentsTableviewEntryButton addTarget:self action:@selector(attachmentsViewSelect) forControlEvents:UIControlEventTouchUpInside];
    [self.addAttachmentView addSubview:self.attachmentsTableviewEntryButton];
    
    //takephoto
    UIImageView* takePhoto = [[UIImageView alloc]initWithFrame:CGRectMake(210, 5, 100, 90)];
    takePhoto.image = [self imageReduceRect:@"attachTakePhoto"];
    [self addSelcetorToView:@selector(takePhotoViewSelcevted) :takePhoto];
    [self.addAttachmentView addSubview:takePhoto];
    UILabel* photoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 70, 100, 20)];
    photoLabel.backgroundColor = [UIColor clearColor];
    [photoLabel setFont:[UIFont systemFontOfSize:13]];
    [photoLabel setTextColor:[UIColor grayColor]];
    photoLabel.textAlignment = UITextAlignmentCenter;
    photoLabel.text = NSLocalizedString(@"Snapshot", nil);
    [takePhoto addSubview:photoLabel];
    [photoLabel release];
    [takePhoto release];
    
    [self.view addSubview:self.addAttachmentView];
}

- (void) addAttachemntsViewDisappear
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.addAttachmentView cache:YES];
    [UIView setAnimationDuration:0.4];
    self.addAttachmentView.frame = CGRectMake(0.0, -ATTACHMENTSVIEWHEIGH, 320, INFOVIEWHEIGN);
    self.inputContentView.frame = CGRectMake(0.0, 0.0, 320, 400);
    self.addAttachmentView.tag = HIDDENTTAG;
    [UIView commitAnimations];
    
    
}

- (void) addAttachmentsViewAppear
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.addAttachmentView cache:YES];
    [UIView setAnimationDuration:0.4];
    if (HIDDENTTAG != self.addDocumentInfoView.tag) {
        self.addDocumentInfoView.frame = CGRectMake(0.0, -INFOVIEWHEIGN, 320, INFOVIEWHEIGN);
        self.addDocumentInfoView.tag = HIDDENTTAG;
    }
    self.addAttachmentView.frame = CGRectMake(0.0, 0.0, 320, ATTACHMENTSVIEWHEIGH);
    self.inputContentView.frame = CGRectMake(0.0, ATTACHMENTSVIEWHEIGH, 320, self.view.frame.size.height - ATTACHMENTSVIEWHEIGH);
    [self.view bringSubviewToFront:addAttachmentView];
    [self keyHideOrShow];
    self.addAttachmentView.tag = NOHIDDENTTAG;
    [UIView commitAnimations];
    
}

- (void) addAttachmentsViewAnimation
{
    if (HIDDENTTAG == self.addAttachmentView.tag) {
        [self addAttachmentsViewAppear ];
    }
    else
    {
        [self addAttachemntsViewDisappear];
    }
}


- (void) addDocumentInfoDisappear
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.addAttachmentView cache:YES];
    [UIView setAnimationDuration:0.4];
    self.addDocumentInfoView.frame = CGRectMake(0.0, -INFOVIEWHEIGN, 320, INFOVIEWHEIGN);
    self.inputContentView.frame = CGRectMake(0.0, 0.0, 320, 400);
    self.addDocumentInfoView.tag = HIDDENTTAG;
    [UIView commitAnimations];
    
    
}

- (void) addDocumentInfoAppear
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.addAttachmentView cache:YES];
    [UIView setAnimationDuration:0.4];
    if (HIDDENTTAG != self.addAttachmentView.tag) {
        self.addAttachmentView.frame = CGRectMake(0.0, -ATTACHMENTSVIEWHEIGH, 320, ATTACHMENTSVIEWHEIGH);
        self.addAttachmentView.tag = HIDDENTTAG;
    }
    self.addDocumentInfoView.frame = CGRectMake(0.0, 0.0, 320, INFOVIEWHEIGN);
    self.inputContentView.frame = CGRectMake(0.0, INFOVIEWHEIGN, 320, 250);
    [self.view bringSubviewToFront:addDocumentInfoView];
    [self keyHideOrShow];
    self.addDocumentInfoView.tag = NOHIDDENTTAG;
    [UIView commitAnimations];
    
    
}

- (void) addDocumentInfoViewAnimation
{
    if (HIDDENTTAG == self.addDocumentInfoView.tag) {
        [self addDocumentInfoAppear];
    }
    else
    {
        [self addDocumentInfoDisappear];
    }
}



- (void) buildAddDocumentInfoView
{
    if (nil == self.addDocumentInfoView) {
        self.addDocumentInfoView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, -INFOVIEWHEIGN, 320, INFOVIEWHEIGN)] autorelease];
        self.addDocumentInfoView.tag = HIDDENTTAG;
        UIImageView* backGroud = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newNoteDetailBackgroud"]]autorelease];
        backGroud.frame = CGRectMake(0.0,0.0, 320, 110);
        [self.addDocumentInfoView addSubview:backGroud];
        self.addDocumentInfoView.backgroundColor = [UIColor colorWithRed:215.0/255 green:215.0/255 blue:215.0/255 alpha:1.0];
    }
    // floader
    UIImageView* floder = [[UIImageView alloc]initWithFrame:CGRectMake(60, 4, 100, 100)];
    floder.image = [self imageReduceRect:@"newNoteFolder"];
    [self addSelcetorToView:@selector(floderViewSelected) :floder];
    [self.addDocumentInfoView addSubview:floder];
    UILabel* folderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 70, 100, 20)];
    folderLabel.backgroundColor = [UIColor clearColor];
    [folderLabel setFont:[UIFont systemFontOfSize:13]];
    [folderLabel setTextColor:[UIColor grayColor]];
    folderLabel.textAlignment = UITextAlignmentCenter;
    folderLabel.text = NSLocalizedString(@"Folder", nil);
    [floder addSubview:folderLabel];
    [folderLabel release];
    [floder release];
    
    //tag
    UIImageView* tag = [[UIImageView alloc]initWithFrame:CGRectMake(160, 4, 100, 100)];
    tag.image = [self imageReduceRect:@"newNoteTag"];
    UILabel* tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 70, 100, 20)];
    tagLabel.backgroundColor = [UIColor clearColor];
    [tagLabel setFont:[UIFont systemFontOfSize:13]];
    [tagLabel setTextColor:[UIColor grayColor]];
    tagLabel.textAlignment = UITextAlignmentCenter;
    tagLabel.text = NSLocalizedString(@"Tag", nil);
    [tag addSubview:tagLabel];
    [tagLabel release];
    [self addSelcetorToView:@selector(tagViewSelect) :tag];
    [self.addDocumentInfoView addSubview:tag];
    [tag release];
    [self.view addSubview:self.addDocumentInfoView];
    
}
- (void) buildNavigationButtons
{
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(self.navigationItem.titleView.frame.size.width/2 - 40, 0, 90, 30)];//allocate titleView
	
    
	//Create Round UIButton
	UIButton *btnNormal = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btnNormal setImage:[UIImage imageNamed:@"newNoteAttach"] forState:UIControlStateNormal];
	[btnNormal setFrame:CGRectMake(0, 0, 40, 30)];
	[btnNormal addTarget:self action:@selector(addAttachmentsViewAnimation) forControlEvents:UIControlEventTouchUpInside];
	[btnNormal setTitle:@"Normal" forState:UIControlStateNormal];
	[titleView addSubview:btnNormal];
	
	//Create Builtin type UIButton
	UIButton *btnBuiltinType = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[btnBuiltinType setFrame:CGRectMake(45, 0, 40, 30)];
	[btnBuiltinType addTarget:self action:@selector(addDocumentInfoViewAnimation) forControlEvents:UIControlEventTouchUpInside];
	[titleView addSubview:btnBuiltinType];
	
	
	//Set to titleView
	self.navigationItem.titleView = titleView;
	[titleView release];//release titleView
}

- (void) setUserInterfaceEnableSelf:(BOOL)enable
{
    for (UIView* each in [self.navigationItem.titleView subviews]) {
        if ([each isKindOfClass:[UIButton class]]) {
            each = (UIButton*)each;
            each.userInteractionEnabled = enable;
        }
    }
    self.navigationItem.leftBarButtonItem.enabled = enable;
    self.navigationItem.rightBarButtonItem.enabled = enable;
    self.titleTextFiled.enabled = enable;
    self.bodyTextField.userInteractionEnabled = enable;
    self.keyControl.userInteractionEnabled = enable;
}

- (void) buildInputContentView
{
    if (nil == self.inputContentView) {
        self.inputContentView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 400)] autorelease];
    }
    //titile input
    self.titleTextFiled = [[[UITextField alloc] initWithFrame:CGRectMake(0.0, 5, 320, 30)] autorelease];
    //    self.titleTextFiled.borderStyle = UITextBorderStyleLine;
    self.titleTextFiled.placeholder = NSLocalizedString(@"No title file", nil);
    self.titleTextFiled.delegate = self;
    [self.inputContentView addSubview:self.titleTextFiled];
    //body text input
    UIView* breakLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 30, 320, 1)] autorelease];
    breakLine.backgroundColor = [UIColor lightGrayColor];
    [self.inputContentView addSubview:breakLine];
    UITextView* edit = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 31, 320, self.view.frame.size.height - 31)];
	edit.returnKeyType = UIReturnKeyDefault;
	[self.inputContentView addSubview:edit];
    edit.font = [UIFont systemFontOfSize:17];
	self.bodyTextField = edit;
    self.bodyTextField.delegate = self;
	[edit release];
    [self.view addSubview:self.inputContentView];
}

- (NSString*) insertStringToOldWithRange:(NSString*)oldString inserString:(NSString*) insertString range:(NSRange)selectedRange
{
    NSString* newBody = nil;
    if (insertString == nil) {
        insertString= @"";
    }
    NSUInteger location = selectedRange.location;
    NSUInteger selectedLength = selectedRange.length;
    NSRange preRange = NSMakeRange(0, location);
    if (selectedLength == 0) {
        if (location > 0) {
            NSRange nextRange = NSMakeRange(location, oldString.length - location);
            NSString* preStr = [oldString substringWithRange:preRange];
            NSString* nextStr = [oldString substringWithRange:nextRange];
            newBody = [NSString stringWithFormat:@"%@%@%@",preStr,insertString,nextStr];
        }
        else
        {
            newBody = [NSString stringWithFormat:@"%@%@",insertString,oldString];
        }
    }
    else
    {
        NSRange preRange = NSMakeRange(0, location);
        NSRange nextRange = NSMakeRange(location + selectedLength, oldString.length - location- selectedLength);
        NSString* preStr = [oldString substringWithRange:preRange];
        NSString* nextStr = [oldString substringWithRange:nextRange];
        newBody = [NSString stringWithFormat:@"%@%@%@",preStr,insertString,nextStr];
    }
    return newBody;
}
- (void) startVoiceInput
{
    if ([self.titleTextFiled isFirstResponder]) {
        self.firtResponser = self.titleTextFiled;
    }
    else if ([self.bodyTextField isFirstResponder])
    {
        self.firtResponser = self.bodyTextField;
    }
    [self.voiceInput startRecognition];
    [self setUserInterfaceEnableSelf:NO];
    [self keyHideOrShow];
}



- (void) voiceInputOver:(NSString *)result
{
    [self setUserInterfaceEnableSelf:YES];
    if (self.firtResponser == self.titleTextFiled) {
        self.titleTextFiled.text = result;
    }
    if (self.firtResponser == self.bodyTextField) {
      NSString* string =   [self insertStringToOldWithRange:self.bodyTextField.text inserString:result range:self.bodyTextField.selectedRange];
        self.bodyTextField.text = string;
    }
}
-(void) buildInterface
{
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self buildAddAttachmentsView];
    [self buildAddDocumentInfoView];
    [self buildNavigationButtons];
    [self buildInputContentView];
    //key control
    self.keyControl = [[[UIImageView alloc] initWithFrame:CGRectMake(250 , self.view.frame.size.height - 35, 50, 25)] autorelease];
    self.keyControl.image = [UIImage imageNamed:@"keyHidden"];
    [self.view addSubview:self.keyControl];
    keyControl.tag = KEYHIDDEN;
    UITapGestureRecognizer* keyHide = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyHideOrShow)] autorelease];
    keyHide.numberOfTapsRequired =1;
    keyHide.numberOfTouchesRequired =1;
    [keyControl addGestureRecognizer:keyHide];
    keyControl.userInteractionEnabled = YES;
    VoiceRecognition* reg = [[VoiceRecognition alloc] initWithFrame:CGRectMake(200, 100, 50 , 25) parentView:self.view];
    [reg.image addAction:@selector(startVoiceInput) target:self];
    self.voiceInput = reg;
    self.voiceInput.hidden = YES;
    reg.owner = self;
    [self.view addSubview:reg];
    [reg release];
}

- (void) newDocument
{
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    
    if([self.documentFloder isEqualToString:@""])
        self.documentFloder = [NSMutableString stringWithFormat:@"/My Mobiles/"];
    
    if (self.titleTextFiled.text == nil) {
        self.titleTextFiled.text = @"";
    }
    if (self.bodyTextField.text == nil) {
        self.bodyTextField.text = @"";
    }
    NSMutableArray* attachmentsGuid = [NSMutableArray array];
    if ([self.attachmentsSourcePaths count]) {
        for (NSString* each in self.attachmentsSourcePaths) {
            NSArray* dir = [each componentsSeparatedByString:@"/"];
            NSString* pathDir = [dir objectAtIndex:[dir count] -2];
            if (![pathDir isEqualToString:ATTACHMENTTEMPFLITER]) {
                [attachmentsGuid addObject:pathDir];
                continue;
            }
            NSString* newAttachmentGuid = [index newAttachment:each documentGUID:self.documentGUID];
            [attachmentsGuid addObject:newAttachmentGuid];
        }
    }
    [dic setObject:self.documentGUID forKey:TypeOfDocumentGUID];
    [dic setObject:attachmentsGuid forKey:TypeOfAttachmentGuids];
    [dic setObject:self.titleTextFiled.text forKey:TypeOfDocumentTitle];
    [dic setObject:self.bodyTextField.text forKey:TypeOfDocumentBody];
    [dic setObject:self.documentFloder forKey:TypeOfDocumentLocation];
    [dic setObject:self.documentTags forKey:TypeOfDocumentTags];
    if (isNewDocument) {
        [index newNoteWithGuidAndData:dic];
    }
    else
    {
        [index editDocumentWithGuidAndData:dic];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MessageOfNewDocument object:nil userInfo:[NSDictionary dictionaryWithObject:[index documentFromGUID:self.documentGUID] forKey:TypeOfWizDocumentData]];
    
}

- (void) postSelectedMessageToPicker
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MessageOfMainPickSelectedView object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:TypeOfMainPickerViewIndex]];
}
-(void) saveDocument
{
    [self newDocument];
    [self postSelectedMessageToPicker];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) cancelSave
{
    [self postSelectedMessageToPicker];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

-(id) initWithAccountId:(NSString*)accountGuid
{
    self = [super init];
    if (self) {
        [self buildInterface];
        self.accountUserId = accountGuid;
        UIBarButtonItem* editButton = [[UIBarButtonItem alloc] initWithTitle:WizStrSave style:UIBarButtonItemStyleDone target:self action:@selector(saveDocument)];
        self.navigationItem.rightBarButtonItem = editButton;
        
        UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:WizStrCancel style:UIBarButtonItemStyleDone target:self action:@selector(cancelSave)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [editButton release];
        [cancelButton release];
    }
    return self;
}

- (void) keyboardWillShow:(NSNotification*) nc
{
    NSDictionary* userInfo = [nc userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3];
    self.bodyTextField.frame = CGRectMake(0.0,31,320,self.view.frame.size.height - kbSize.height - 70);
    [self.keyControl setFrame:CGRectMake( 250, self.view.frame.size.height - kbSize.height - 35, 50, 25)];
    [self.voiceInput setFrame:CGRectMake( 190, self.view.frame.size.height - kbSize.height - 35, 50, 25)];
    self.voiceInput.hidden = NO;
    self.keyControl.hidden = NO;
    [UIView commitAnimations];
    
}
- (void) prepareForEdit:(NSDictionary*)data
{
    NSString* title = [data valueForKey:TypeOfDocumentTitle];
    NSString* body = [data valueForKey:TypeOfDocumentBody];
    NSString* documentGUID_ = [data valueForKey:TypeOfDocumentGUID];
    self.documentGUID = documentGUID_;
    self.titleTextFiled.text = title;
    self.bodyTextField.text = body;
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    WizDocument* doc = [index documentFromGUID:self.documentGUID];

    self.documentTags = [NSMutableString stringWithString:doc.tagGuids];
    self.documentFloder = [NSMutableString stringWithString:doc.location];
    NSArray* attachs = [NSMutableArray arrayWithArray:[index attachmentsByDocumentGUID:doc.guid]];
    if(nil == self.attachmentsSourcePaths)
    {
        self.attachmentsSourcePaths = [NSMutableArray array];
        for (WizDocumentAttach* each in attachs) {
            NSString* filePath = [WizIndex documentFilePath:self.accountUserId documentGUID:each.attachmentGuid];
            NSString* fileNamePath = [filePath stringByAppendingPathComponent:each.attachmentName];
            [self.attachmentsSourcePaths addObject:fileNamePath];
        }
    }
    self.addAttachmentView.tag = HIDDENTTAG;
    self.addDocumentInfoView.tag = NOHIDDENTTAG;
    self.isNewDocument = NO;
}

- (void) prepareForNewDocument
{
    self.documentGUID = [WizGlobals genGUID];
    self.documentTags = [NSMutableString string];
    self.documentFloder = [NSMutableString string];
    if(nil == self.attachmentsSourcePaths)
        self.attachmentsSourcePaths = [NSMutableArray array];
    self.isNewDocument = YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    if(![self startAudioSession])
    {
        NSLog(@"can not recorder");
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.addAttachmentView.tag == HIDDENTTAG) {
        [self addAttachmentsViewAnimation];
    }
    else  if (self.addDocumentInfoView.tag == HIDDENTTAG) {
        [self addDocumentInfoViewAnimation];
    }
    [self displayAttachmentsCount];
}

- (void) viewWillDisappear:(BOOL)animated
{
    if (self.addDocumentInfoView.tag == NOHIDDENTTAG)
    {
        self.addDocumentInfoView.tag = HIDDENTTAG;
    } else
    {
        self.addDocumentInfoView.tag = NOHIDDENTTAG;
    }
    if (self.addAttachmentView.tag == NOHIDDENTTAG) {
        self.addAttachmentView.tag = HIDDENTTAG;
    }
    else
    {
        self.addAttachmentView.tag = NOHIDDENTTAG;
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return NO;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    [self addAttachemntsViewDisappear];
    self.voiceInput.hidden = NO;
    [self addDocumentInfoDisappear];
}

- (void) textViewDidBeginEditing:(UITextView *)textView
{
    [self addAttachemntsViewDisappear];
     self.voiceInput.hidden = NO;
    [self addDocumentInfoDisappear];
}


@end
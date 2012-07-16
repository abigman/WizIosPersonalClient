//
//  WizEditorBaseViewController.m
//  Wiz
//
//  Created by wiz on 12-7-2.
//
//

#import "WizPhoneNotificationMessage.h"
#import "WizEditorBaseViewController.h"
#import "CommonString.h"
#import <AVFoundation/AVFoundation.h>
#import "WizFileManager.h"
#import "NSArray+WizTools.h"
#import "WizSettings.h"
#import "UIImage+WizTools.h"
#import "WizDocument.h"
#import "WizGlobals.h"
#import "UIBarButtonItem+WizTools.h"
#import "DocumentInfoViewController.h"

#import "WizRecoderProcessView.h"

#import "WizImageEditViewController.h"

#define AudioMaxProcess  40

#define WizEditingDocumentModelFileName  @"editingDocumentModel"
#define WizEditingDocumentFileName  @"editing.html"
#define WizEditingDocumentHTMLModelFileName @"editModel.html"
enum WizEditActionSheetTag {
    WizEditActionSheetTagCancelSave = 1000,
    WizEditActionSheetTagResumeEditing = 10001
    };
typedef NSInteger WizEditActionSheetTag;

@interface WizEditorBaseViewController () <UIWebViewDelegate,AVAudioRecorderDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate, WizImageEditDelegate>
{
    NSMutableArray* attachmentsArray;
    
    AVAudioRecorder *audioRecorder;
	AVAudioSession *audioSession;
    NSTimer* audioTimer;
    CGFloat currentRecoderTime;
    //
    //
    UIView* recorderProcessView;
    UILabel* recorderProcessLabel;
    WizRecoderProcessView* recorderProcessLineView;
    
    //
    NSTimer* autoSaveTimer;
    //
}
@property (retain) AVAudioRecorder* audioRecorder;
@property (retain) AVAudioSession* audioSession;
@property (retain) NSTimer* audioTimer;
@end

@implementation WizEditorBaseViewController

@synthesize audioRecorder;
@synthesize audioSession;
@synthesize audioTimer;
@synthesize currentDeleteImagePath;
@synthesize docEdit;
@synthesize sourceDelegate;
@synthesize urlRequest;
- (void) dealloc
{
    //
    [voiceRecognitionView release];
    //
    [audioRecorder release];
    [audioSession release];
    
    //

    [audioTimer release];
    //
    [docEdit release];
    [attachmentsArray release];
    [editorWebView release];
    //
    sourceDelegate = nil;
    //
    [urlRequest release];
    [recorderProcessView release];
    [recorderProcessLabel release];
    [recorderProcessLineView release];
    //
    [super dealloc];
}


//- (void) webViewDidFinishLoad:(UIWebView *)webView
//{
//    NSLog(@"ddd");
//}



- (void) buildRecoderProcessView
{
    recorderProcessView = [[UIView alloc]init];
    recorderProcessView.backgroundColor = [UIColor brownColor];
    recorderProcessLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 80, 35)];
    [recorderProcessView addSubview:recorderProcessLabel];
    recorderProcessLabel.backgroundColor = [UIColor clearColor];
    
    
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
    button.frame = CGRectMake(260, 0.0, 60, 40);
    [button addTarget:self action:@selector(stopRecord) forControlEvents:UIControlEventTouchUpInside];
    [recorderProcessView addSubview:button];
    
    recorderProcessLineView = [[WizRecoderProcessView alloc] initWithFrame:CGRectMake(80, 0.0, 200, 40)];
    recorderProcessLineView.maxProcess = AudioMaxProcess;
    [recorderProcessView addSubview:recorderProcessLineView];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        attachmentsArray = [[NSMutableArray alloc] init];
        editorWebView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        editorWebView.delegate = self;
        //
        [self buildRecoderProcessView];
        autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(saveToLocal) userInfo:nil repeats:YES];
        
        //
        
    }
    return self;
}

- (void) willDeleteImagePhone:(NSString*)sourcePath
{
    WizImageEditViewController* imageEditor = [[WizImageEditViewController alloc] init];
    imageEditor.sourcePath = sourcePath;
    imageEditor.editDelegate = self;
    [self.navigationController pushViewController:imageEditor animated:YES];
    [imageEditor release];
}
- (void) editorImageDone
{
    [editorWebView deleteImage];
}

- (void) willDeleteImagePad:(NSString*)sourcePath
{
    
}
- (void) willDeleteImage:(NSString*)sourcePath
{
    if ([WizGlobals WizDeviceIsPad]) {
        
    }
    else
    {
        [self willDeleteImagePhone:sourcePath];
    }
}


- (NSString*)editingFilePath
{
    static NSString* editingFilePath=nil;
    if (nil == editingFilePath) {
        editingFilePath = [[[[WizFileManager shareManager] editingTempDirectory] stringByAppendingPathComponent:WizEditingDocumentFileName] retain];
    }
    return editingFilePath;
}

- (NSString*) editingIndexFilePath
{
    static NSString* editingFilePath=nil;
    if (nil == editingFilePath) {
        editingFilePath = [[[[WizFileManager shareManager] editingTempDirectory] stringByAppendingPathComponent:@"index.html"] retain];
    }
    return editingFilePath;
}

- (NSString*) editingMobileFilePath
{
    static NSString* editingFilePath=nil;
    if (nil == editingFilePath) {
        editingFilePath = [[[[WizFileManager shareManager] editingTempDirectory] stringByAppendingPathComponent:@"wiz_mobile.html"] retain];
    }
    return editingFilePath;
}

- (NSString*) editingHtmlModelFilePath
{
    static NSString* editingFilePath=nil;
    if (nil == editingFilePath) {
        editingFilePath = [[[[WizFileManager shareManager] editingTempDirectory] stringByAppendingPathComponent:WizEditingDocumentHTMLModelFileName] retain];
    }
    return editingFilePath;
}

- (NSString*) editingDocumentModelFilePath
{
    static NSString* editingFilePath=nil;
    if (nil == editingFilePath) {
        editingFilePath = [[[[WizFileManager shareManager] editingTempDirectory] stringByAppendingPathComponent:WizEditingDocumentModelFileName] retain];
    }
    return editingFilePath;
}


- (void) saveToLocal
{
    NSString* editingFilePath = [self editingDocumentModelFilePath];
    
    NSDictionary* doc = [self.docEdit getModelDictionary];
    
    if (![doc writeToFile:editingFilePath atomically:YES]) {
        [WizGlobals toLog:@"write to editingModelFile error"];
    };
    if ([WizGlobals WizDeviceVersion] < 5) {
        [self autoSaveLessThan5];
    }
    else
    {
        [self autoSaveMoreThan5];
    }
}

- (BOOL) isEditorEnviromentFile:(NSString*)fileName
{
    if ([fileName isEqualToString:@"js"]) {
        return YES;
    }
    else if ([fileName isEqualToString:WizEditingDocumentHTMLModelFileName])
    {
        return YES;
    }
    else if ([fileName isEqualToString:WizEditingDocumentFileName])
    {
        return YES;
    }
    else if ([fileName isEqualToString:WizEditingDocumentModelFileName])
    {
        return YES;
    }
    return NO;
}

- (void) clearEditorEnviromentLessThan5
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    NSString* editorPath = [fileManager editingTempDirectory];
    NSError* error = nil;
    for (NSString* each in [fileManager contentsOfDirectoryAtPath:editorPath error:nil])
    {
        if (![self isEditorEnviromentFile:each] || [each isEqualToString:WizEditingDocumentFileName] ) {
            if (![fileManager removeItemAtPath:[editorPath stringByAppendingPathComponent:each] error:&error]) {
                NSLog(@"error %@",error);
            }
        }
    }
}

- (void) saveToLocal:(NSString*)body
{
    NSString* indexFilePath = [self editingIndexFilePath];
    NSString* moblieFilePath = [self editingMobileFilePath];
    
    NSString* html = [NSString stringWithFormat:@"<html><body>%@</body></html>",body];
    [html writeToFile:indexFilePath atomically:YES encoding:NSUTF16StringEncoding error:nil];
    [html writeToFile:moblieFilePath atomically:YES encoding:NSUTF16StringEncoding error:nil];
}

- (void) autoSaveMoreThan5
{
    NSString* body = [editorWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    [self saveToLocal:body];
}
- (void) autoSaveLessThan5
{
    NSString* body = [editorWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    body = [body stringReplaceUseRegular:@"<wiz>|</wiz>"];
    [self saveToLocal:body];
}


- (void) doSaveDocument
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    NSString* docPath = [fileManager objectFilePath:self.docEdit.guid];
    NSString* indexFilesPath = [docPath stringByAppendingPathComponent:@"index_files"];
    [fileManager ensurePathExists:docPath];
    [fileManager ensurePathExists:indexFilesPath];
    NSArray* content = [fileManager contentsOfDirectoryAtPath:[fileManager editingTempDirectory] error:nil];
    for (NSString* each in content) {
        if (![self isEditorEnviromentFile:each]) {
            NSString* sourcePath = [[fileManager editingTempDirectory] stringByAppendingPathComponent:each];
            NSString* toPath = [docPath stringByAppendingPathComponent:each];
            NSError* error = nil;
            if ([fileManager fileExistsAtPath:toPath]) {
                [fileManager removeItemAtPath:toPath error:nil];
            }
            [fileManager moveItemAtPath:sourcePath toPath:toPath error:&error];
            if (error) {
                NSLog(@"error %@",error);
            }
        }
    }
    NSLog(@"editor doc is %@",self.docEdit.guid);
    [self.docEdit saveWithHtmlBody:@""];
    [self clearEditorEnviromentLessThan5];
}

- (void) saveDocument
{
    [autoSaveTimer invalidate];
    [self saveToLocal];
    [self doSaveDocument];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) changeFonts
{
    NSLog(@"selected");
}

- (void) buildMenu
{
//    UIMenuItem* change = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Changed", nil) action:@selector(changeFonts)];
//    NSMutableArray* array = [NSMutableArray arrayWithArray:[[UIMenuController sharedMenuController] menuItems]];
//    [array addObject:change];
//    [change release];
//    [[UIMenuController sharedMenuController] setMenuItems:array];
    
}

- (void) doSnapPhotoPhone
{
    UIImagePickerController* pick = [self snapPhoto:self];
    [self.navigationController presentModalViewController:pick animated:YES];
}
- (void) doSelectPhotoPhone
{
    UIImagePickerController* pick = [self selectPhoto:self];
    [self.navigationController presentModalViewController:pick animated:YES];
}

- (void) doRecorderPhone
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    recorderProcessView.frame = CGRectMake(0.0 , 0.0, 320, 40);
    [self.view addSubview:recorderProcessView];
    [self startRecord];
}
- (void) doSetDocumentInfo
{
    DocumentInfoViewController* info = [[DocumentInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
    info.doc = self.docEdit;
    info.isEditTheDoc = YES;
    [self.navigationController pushViewController:info animated:YES];
}
- (void) buildPhoneNavigationTools
{
    UIBarButtonItem* snap = [UIBarButtonItem barButtonItem:[UIImage imageNamed:@"attachTakePhotoPad"] hightImage:[UIImage imageNamed:@"edit"] target:self action:@selector(doSnapPhotoPhone)];
    
    UIBarButtonItem* select = [UIBarButtonItem barButtonItem:[UIImage imageNamed:@"attachSelectPhotoPad"] hightImage:[UIImage imageNamed:@"edit"] target:self action:@selector(doSelectPhotoPhone)];
    UIBarButtonItem* recoder = [UIBarButtonItem barButtonItem:[UIImage imageNamed:@"attachRecorderPad"] hightImage:[UIImage imageNamed:@"edit"] target:self action:@selector(doRecorderPhone)];
    
    UIBarButtonItem* info = [UIBarButtonItem barButtonItem:[UIImage imageNamed:@"detail_gray"] hightImage:[UIImage imageNamed:@"edit"] target:self action:@selector(doSetDocumentInfo)];
    
    NSMutableArray* tools = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [tools addObject:info];
    [tools addObject:snap];
    [tools addObject:select];
    [tools addObject:recoder];
    self.navigationItem.rightBarButtonItems = tools;
}


- (void) copyJSModelToEditorEnviromentLessThan5:(NSString*)name  type:(NSString*)type
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    NSString* editPath = [fileManager editingTempDirectory];
    //js
    NSString* jsPath = [[NSBundle mainBundle] pathForResource:name ofType:type];
    NSString* jsEditPath = [editPath stringByAppendingPathComponent:@"js"];
    [fileManager ensurePathExists:jsEditPath];
    NSString* jsFilePath = [jsEditPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",name,type]];
    NSError* error = nil;
    if (![fileManager fileExistsAtPath:jsFilePath]) {
        NSStringEncoding jsEndcoding;
        NSString* jsContent = [NSString stringWithContentsOfFile:jsPath usedEncoding:&jsEndcoding error:&error];
        if (!jsContent) {
            NSLog(@"error %@",error);
        }
        if (![jsContent writeToFile:jsFilePath atomically:YES encoding:jsEndcoding error:&error]) {
            NSLog(@"w e %@",error);
        };
    }
}
- (void) showEditErrorMessage
{
    
}

- (void) buildCommonEditorEnviromentLessThan5
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    [self copyJSModelToEditorEnviromentLessThan5:@"jquery" type:@"js"];
    NSError* error = nil;
    NSString* editorModelPath = [[NSBundle mainBundle] pathForResource:@"editModel" ofType:@"html"];
    NSString* editorModelHtmlPath = [self editingHtmlModelFilePath];
    if ([fileManager fileExistsAtPath:editorModelHtmlPath]) {
        if(![fileManager removeItemAtPath:editorModelHtmlPath error:&error]);
        {
            NSLog(@"error %@",error);
        }
    }
    NSStringEncoding encoding;
    NSString* string = [NSString stringWithContentsOfFile:editorModelPath usedEncoding:&encoding error:&error];
    if (string) {
       if (![string writeToFile:editorModelHtmlPath atomically:YES encoding:encoding error:&error])
       {
           NSLog(@"%@",error);
       }
    }
}

- (BOOL) copySourceFileToEditDirectory:(WizDocument*)doc
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    NSString* documentObjectPath = [fileManager objectFilePath:self.docEdit.guid];
    NSString* editPath = [fileManager editingTempDirectory];
    NSError* error = nil;
    for (NSString* each in [fileManager contentsOfDirectoryAtPath:documentObjectPath error:nil]  ) {
        NSString* sourcePath = [documentObjectPath stringByAppendingPathComponent:each];
        NSString* toPath = [editPath stringByAppendingPathComponent:each];
        if ([fileManager fileExistsAtPath:toPath]) {
            if (![fileManager removeItemAtPath:toPath error:&error]) {
                NSLog(@"error %@",error);
                return NO;
            };
        }
        if(![fileManager copyItemAtPath:sourcePath toPath:toPath error:&error])
        {
            NSLog(@"coyp edit source error error is %@",error);
            return NO;
        }
    }
    return YES;
}

- (BOOL) prepareEditingFileL5:(NSString*)sourcePath
{
    NSStringEncoding contentEncoding;
    NSError* error = nil;
    NSString* content =[NSString stringWithContentsOfFile:sourcePath usedEncoding:&contentEncoding error:&error];
    NSString* editingFile = [self editingFilePath];
    NSRegularExpression* bodyRegular = [NSRegularExpression regularExpressionWithPattern:@"<body[^>]*>[\\s\\S]*</body>" options:NSCaseInsensitivePredicateOption error:nil];
    
    NSRange  sourceRanger = NSMakeRange(0, content.length);
    NSArray* bodys = [bodyRegular matchesInString:content options:NSMatchingReportCompletion range:sourceRanger];
    NSRange bodyRange = NSMakeRange(0, 0);
    for (NSTextCheckingResult* each in bodys) {
        if ([each range].length > bodyRange.length) {
            bodyRange = [each range];
        }
    }
    if (bodyRange.length != 0) {
        content = [content substringWithRange:bodyRange];
    }
    else
    {
        return NO;
    }
    content = [content stringReplaceUseRegular:@"(<[^>]*>)" withString:@"</wiz>$1<wiz>"];
    content = [content substringWithRange:NSMakeRange(6, content.length -6 -5)];
    content = [content stringReplaceUseRegular:@"<wiz></wiz>"];
    NSString* modelFile = [self editingHtmlModelFilePath];
    NSMutableString* modelContent = [NSMutableString stringWithContentsOfFile:modelFile usedEncoding:nil error:&error];
    content  =  [modelContent stringByReplacingOccurrencesOfString:@"<body>IOSWizEditor</body>" withString:content];
    if (![content writeToFile:editingFile useUtf8Bom:YES error:&error])
    {
        NSLog(@"write error%@",error);
        return NO;
    }
    return YES;
}

- (NSURL*) buildEditorEnviromentLessThan5
{
    [self buildCommonEditorEnviromentLessThan5];
    NSURL* ret = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"errorModel" ofType:@"html"]];
    if (self.docEdit)
    {
        if ([self copySourceFileToEditDirectory:self.docEdit])
        {
            if ([self prepareEditingFileL5:[self editingIndexFilePath]] ) {
                ret = [NSURL fileURLWithPath:[self editingFilePath]];
            }
        }
    }
    else
    {
        WizDocument* doc = [[WizDocument alloc] init];
        doc.guid = [WizGlobals genGUID];
        self.docEdit = doc;
        [doc release];
        NSString* url = [[NSBundle mainBundle] pathForResource:@"editModel" ofType:@"html"];
        NSString* toUrl = [[[WizFileManager shareManager] editingTempDirectory] stringByAppendingPathComponent:@"index.html"];
        
        NSString* content = [NSString stringWithContentsOfFile:url usedEncoding:nil error:nil];
        NSError* error = nil;
        [content writeToFile:toUrl atomically:YES encoding:NSUTF16StringEncoding error:&error];
        if (error) {
            NSLog(@"%@",error);
        }
        ret = [NSURL fileURLWithPath:toUrl];
    }
    return ret;
}

- (NSURL*) buildEditorEnviromentMoreThan5
{
    NSURL* ret = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"errorModel" ofType:@"html"]];
    WizFileManager* fileManager = [WizFileManager shareManager];
    NSString* editPath = [fileManager editingTempDirectory];
    NSString* editingFilePath = [editPath stringByAppendingPathComponent:WizEditingDocumentFileName];
    
    NSError* error = nil;
    if (self.docEdit) {
        
        NSString* documentObjectPath = [fileManager objectFilePath:self.docEdit.guid];

        for (NSString* each in [fileManager contentsOfDirectoryAtPath:documentObjectPath error:nil]  ) {
            NSString* sourcePath = [documentObjectPath stringByAppendingPathComponent:each];
            NSString* toPath = [editPath stringByAppendingPathComponent:each];
            
            if ([fileManager fileExistsAtPath:toPath]) {
                [fileManager removeItemAtPath:toPath error:nil];
            }
            if(![fileManager copyItemAtPath:sourcePath toPath:toPath error:&error])
            {
                NSLog(@"error is %@",error);
            }
        }
        NSString* documentIndex = [editPath stringByAppendingPathComponent:@"index.html"];
        if ([fileManager fileExistsAtPath:editingFilePath]) {
            if (![fileManager removeItemAtPath:editingFilePath error:&error]) {
                NSLog(@"error %@",error);
            }
        }
        if (![fileManager moveItemAtPath:documentIndex toPath:editingFilePath error:&error]) {
            NSLog(@"error %@",error);
        }
        ret = [NSURL fileURLWithPath:editingFilePath];
    }
    else
    {
        self.docEdit = [[[WizDocument alloc] init] autorelease];
        NSString* content = [NSString stringWithFormat:@"<html><body></body></html>"];
        if (![content writeToFile:editingFilePath useUtf8Bom:YES error:&error]) {
            NSLog(@"error %@",error);
        }
        ret = [NSURL fileURLWithPath:editingFilePath]; 
    }
    return ret;
}

- (id) initWithWizDocument:(WizDocument*)doc
{
    self = [super init];
    if (self) {
        if (doc) {
            self.docEdit = doc;
        }
        else
        {
            self.docEdit = [[[WizDocument alloc] init] autorelease];
        }
    }
    return self;
}

- (void) postSelectedMessageToPicker
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MessageOfMainPickSelectedView object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:TypeOfMainPickerViewIndex]];
}
- (void) actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == 1) {
        return;
    }
    else if (buttonIndex == 0)
    {
        if (autoSaveTimer) {
            [autoSaveTimer invalidate];
        }
        [self clearEditorEnviromentLessThan5];
        [self postSelectedMessageToPicker];
        [self.navigationController dismissModalViewControllerAnimated:YES];
        
        NSLog(@"self retain count is %d",[self retainCount]);
    }
}
- (void) cancelSaveDocument
{
    [self stopRecord];
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:WizStrAreyousureyouwanttoquit delegate:self cancelButtonTitle:WizStrCancel destructiveButtonTitle:WizStrQuitwithoutsaving otherButtonTitles:nil, nil];
    actionSheet.tag = WizEditActionSheetTagCancelSave;
    [actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
    [actionSheet release];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    [self buildMenu];
    //
    UIBarButtonItem* saveBtn = [[UIBarButtonItem alloc] initWithTitle:WizStrSave style:UIBarButtonItemStyleBordered target:self action:@selector(saveDocument)];
    UIBarButtonItem* cancelBtn = [[UIBarButtonItem alloc] initWithTitle:WizStrCancel style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSaveDocument)];
    
    self.navigationItem.leftBarButtonItem = cancelBtn;
    self.navigationItem.rightBarButtonItem = saveBtn;
    
    [self buildPhoneNavigationTools];
    
    [cancelBtn release];
    [saveBtn release];
    //
    [self.view addSubview:editorWebView];
    [editorWebView loadRequest:self.urlRequest];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL) canRecord
{
    return YES;
}

- (BOOL) canSnapPhotos
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void) updateTime
{
    [self.audioRecorder updateMeters];
    [recorderProcessLineView setCurrentProcess:(AudioMaxProcess - ABS([self.audioRecorder peakPowerForChannel:0]))];
    
    NSLog(@"peak power is %f",[self.audioRecorder peakPowerForChannel:0]);
    currentRecoderTime+=0.1f;
    recorderProcessLabel.text = [WizGlobals timerStringFromTimerInver:currentRecoderTime];
}

- (BOOL) startRecord
{
    NSError* error = nil;
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [settings setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];
    [settings setValue:[NSNumber numberWithInt:1 ] forKey:AVNumberOfChannelsKey];
    [settings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    NSString* audioFileName = [[[WizFileManager shareManager] getAttachmentSourceFileName] stringByAppendingString:@".aif"];
    NSURL* url = [NSURL fileURLWithPath:audioFileName];
    self.audioRecorder = [[[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error ] autorelease];
    if(!self.audioRecorder)
    {
        NSLog(@"%@",error);
        return NO;
    }
    self.audioRecorder.delegate = self;
    self.audioRecorder.meteringEnabled = YES;
    if(![self.audioRecorder prepareToRecord])
    {
        return NO;
    }
    if(![self.audioRecorder record])
    {
        return NO;
    }
    self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    currentRecoderTime = 0.0f;
    return YES;
}
- (void) addAttachmentDone:(NSString*)path
{
    [attachmentsArray addAttachmentBySourceFile:path];
}

- (void) willAddAudioDone:(NSString *)audioPath
{
    [self addAttachmentDone:audioPath];
    recorderProcessView.frame = CGRectMake(-900, 0.0, 0.0, 0.0);
    [editorWebView insertAudio:audioPath];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (BOOL) stopRecord
{
    if (nil == self.audioRecorder || ![self.audioRecorder isRecording]) {
        return YES;
    }
    [self.audioRecorder stop];
    [self.audioTimer invalidate];
    currentRecoderTime = 0.0f;
    [self willAddAudioDone:self.audioRecorder.url.absoluteString];
    return YES;
}


//
- (void) willAddPhotoDone:(NSString *)photoPath
{
    [self addAttachmentDone:photoPath];

    [editorWebView insertImage:photoPath];
}

- (UIImagePickerController*) snapPhoto:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)parentController
{
    UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    if (!parentController) {
        picker.delegate = self;
    }
    else
    {
        picker.delegate = parentController;
    }
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    return [picker autorelease];
}
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    image = [image compressedImage:[[WizSettings defaultSettings] imageQualityValue]];
    NSString* fileNamePath = [[[WizFileManager shareManager] getAttachmentSourceFileName] stringByAppendingString:@".jpg"];
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:fileNamePath atomically:YES];
    [picker dismissModalViewControllerAnimated:YES];
    //2012-2-26 delete
    [self willAddPhotoDone:fileNamePath];
}

- (UIImagePickerController*) selectPhoto:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>) parentController
{
    UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    if (!parentController) {
        picker.delegate = self;
    }
    else
    {
        picker.delegate = parentController;
    }
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    return [picker autorelease];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}
- (void) resumeLastEditong
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    NSString* editingPath = [fileManager editingTempDirectory];
    NSString* editingFile = [editingPath stringByAppendingPathComponent:WizEditingDocumentFileName];
    NSString* editingDocumentModel = [editingPath stringByAppendingPathComponent:WizEditingDocumentModelFileName];
    self.docEdit = [[[WizDocument alloc] initFromDictionaryModel:[NSDictionary dictionaryWithContentsOfFile:editingDocumentModel]] autorelease];
    if ([WizGlobals WizDeviceVersion] < 5) {
        [self prepareEditingFileL5:[self editingIndexFilePath]];
    }
    self.urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:editingFile]];
}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

@end

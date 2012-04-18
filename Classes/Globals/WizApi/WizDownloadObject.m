//
//  WizDownloadObject.m
//  Wiz
//
//  Created by dong zhao on 11-10-31.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "WizDownloadObject.h"
#import "WizIndex.h"
#import "WizGlobals.h"
#import "WizGlobalData.h"
#import "WizSync.h"
#import "WizDocumentsByLocation.h"
#import "WizSyncByTag.h"
#import "WizSyncByLocation.h"
#import "WizSyncByKey.h"
#import "WizGlobalDictionaryKey.h"
#import "Reachability.h"

NSString* SyncMethod_DownloadProcessPartBeginWithGuid = @"DownloadProcessPartBegin";
NSString* SyncMethod_DownloadProcessPartEndWithGuid   = @"DownloadProcessPartEnd";
//
#define DownloadPartSize      256*1024
@interface WizDownloadObject ()
{
    NSString* objType;
    NSString* objGuid;
    NSFileHandle* fileHandle;
}
@property (nonatomic, retain) NSString* objType;
@property (nonatomic, retain) NSString* objGuid;
@property (nonatomic, retain) id owner;
@property (nonatomic, retain) NSFileHandle* fileHandle;
@property (assign) BOOL isLogin;
@property int currentPos;
@end

@implementation WizDownloadObject
@synthesize objGuid;
@synthesize objType;
@synthesize busy;
@synthesize fileHandle;
-(void) dealloc {
    if (nil != fileHandle) {
        [fileHandle closeFile];
        [fileHandle release];
    }
    [objType release];
    [objGuid release];
    [super dealloc];
}

-(void) onError: (id)retObject
{
	busy = NO;
    [super onError:retObject];
}

- (void) downloadNext
{
    int64_t currentPos = [self.fileHandle offsetInFile];
    [self callDownloadObject:self.objGuid startPos:currentPos objType:self.objType partSize:DownloadPartSize];
}
- (void) downloadObject
{
    if (self.busy) {
        return;
    }
    busy = YES;
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    NSString* fileNamePath = [index downloadObjectTempFilePath:self.objGuid];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileNamePath])
        [WizGlobals deleteFile:fileNamePath];
    if (![[NSFileManager defaultManager] createFileAtPath:fileNamePath contents:nil attributes:nil]) {
        
    }
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileNamePath];
    [self.fileHandle seekToFileOffset:0];
    [self downloadNext];
}

- (void) downloadDone
{
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    if ([self.objType isEqualToString:WizDocumentKeyString]) {
        [index setDocumentServerChanged:self.objGuid changed:NO];
    }
    else if ([self.objType isEqualToString:WizAttachmentKeyString])
    {
        [index setAttachmentServerChanged:self.objType changed:NO];
    }
    //
    NSDictionary* ret = [[NSDictionary alloc] initWithObjectsAndKeys:self.objGuid,  @"document_guid",  nil];
    NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:SyncMethod_DownloadObject, @"method",ret,@"ret",[NSNumber numberWithBool:YES], @"succeeded", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:[self notificationName:WizSyncXmlRpcDonlowadDoneNotificationPrefix] object: nil userInfo: userInfo];
	[userInfo release];
    [ret release];
    
}

-(void) onDownloadObject:(id)retObject
{
	
    NSDictionary* obj = retObject;
    NSData* data = [obj valueForKey:@"data"];
    NSNumber* eofPre = [obj valueForKey:@"eof"];
    BOOL eof = [eofPre intValue]? YES:NO;
    NSString* serverMd5 = [obj valueForKey:@"part_md5"];
     NSNumber* objSize = [obj valueForKey:@"obj_size"];
    NSString* localMd5 = [WizGlobals md5:data];
    BOOL succeed = [serverMd5 isEqualToString:localMd5]?YES:NO;
    
    if(!succeed) {
        [self downloadNext];
  
    }
    else
    {
        [self.fileHandle writeData:data];
        if (!eof) {
            [self downloadNext];
        }
        else {
            WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
            [index updateObjectDataByPath:[index downloadObjectTempFilePath:self.objGuid] objectGuid:self.objGuid];
            [self downloadDone];
        }
        [self postSyncDoloadObject:[self.fileHandle offsetInFile] current:[objSize intValue] objectGUID:self.objGuid objectType:self.objType];
    }
}

@end

//@implementation WizDownloadDocument
//
//- (void) downloadOver:(BOOL)unzipIsSucceed
//{
//    [super downloadOver:unzipIsSucceed];
//    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
//    if (unzipIsSucceed) {
//        [index setDocumentServerChanged:self.objGuid changed:NO]; 
//    }
//    NSDictionary* ret = [[NSDictionary alloc] initWithObjectsAndKeys:self.currentDownloadObjectGUID,  @"document_guid",  nil];
//    
//    NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:SyncMethod_DownloadObject, @"method",ret,@"ret",[NSNumber numberWithBool:YES], @"succeeded", nil];
//	[[NSNotificationCenter defaultCenter] postNotificationName:[self notificationName:WizSyncXmlRpcDonlowadDoneNotificationPrefix] object: nil userInfo: userInfo];
//	[userInfo release];
//    [ret release];
//}
//- (BOOL) downloadDocument:(NSString *)documentGUID
//{
//    if (self.busy)
//		return NO;
//	busy = YES;
//    self.objType = @"document";
//    self.objGuid = documentGUID;
//    self.currentPos = 0;
//    self.isLogin = NO;
//    return [self downloadObject];
//}
//- (BOOL) downloadWithoutLogin:(NSURL *)apiUrl kbguid:(NSString *)kbGuid token:(NSString*)token_ documentGUID:(NSString *)documentGUID
//{
//    if (self.busy)
//		return NO;
//	busy = YES;
//    self.apiURL = apiUrl;
//    self.kbguid  =kbGuid;
//    self.token = token_;
//    self.objType = @"document";
//    self.objGuid = documentGUID;
//    self.currentPos = 0;
//    self.isLogin = YES;
//    return [self downloadObject];
//}
//@end
//@implementation WizDownloadAttachment
//- (void) downloadOver:(BOOL)unzipIsSucceed
//{
//    [super downloadOver:unzipIsSucceed];
//    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
//    if (unzipIsSucceed) {
//        [index setAttachmentServerChanged:self.objGuid changed:NO];
//    }
//}
//
//- (BOOL) downloadAttachment:(NSString *)attachmentGUID
//{
//    if (self.busy)
//		return NO;
//	busy = YES;
//    self.objType = @"attachment";
//    self.objGuid = attachmentGUID;
//    self.currentPos = 0;
//    self.isLogin = NO;
//    return [self downloadObject];
//}
//- (BOOL) downloadWithoutLogin:(NSURL *)apiUrl kbguid:(NSString *)kbGuid token:(NSString*)token_ downloadAttachment:(NSString *)attachmentGUID
//{
//    if (self.busy)
//		return NO;
//	busy = YES;
//    self.apiURL = apiUrl;
//    self.kbguid  =kbGuid;
//    self.token = token_;
//    self.objType = @"attachment";
//    self.objGuid = attachmentGUID;
//    self.currentPos = 0;
//    self.isLogin = YES;
//    return [self downloadObject];
//}

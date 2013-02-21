//
//  WizPadAllNotesViewController.m
//  Wiz
//
//  Created by wiz on 12-8-16.
//
//


#import "WizPadAllNotesViewController.h"
#import "WizPadTreeTableHeaderView.h"

#import "WizDbManager.h"
#import "TreeNode.h"
#import "WizPadTreeTableCell.h"
#import "WizPadListCell.h"

#import "WizSettings.h"
#import "NSMutableArray+WizDocuments.h"
#import "WizNotification.h"

#define WizDeletedTagViewTag    7845

#define WizAddNewTagViewTag        2356
#define WizAddNewFolderViewTag      2134

#define WizTreeSectionHeaderViewHeight  30

enum WizPadTreeKeyIndex
{
    WizPadTreeTagIndex = 1,
    WizpadTreeFolderIndex = 0
};
@interface WizPadAllNotesViewController () <WizPadTableHeaderDeleage, WizPadTreeTableCellDelegate, WizPadCellSelectedDocumentDelegate, UIAlertViewDelegate, UITextFieldDelegate>
{
    NSMutableArray*  rootNodes;
    NSMutableArray*  needDisplayNodes;
    
    NSMutableArray* documentsMutableArray;
    TreeNode*  lastSelectedTreeNode;
    
    BOOL  isIgnoreReloadTag;
    BOOL isIgnoreReloadFolder;
}
@property (nonatomic, retain)  NSMutableArray* documentsMutableArray;
@property (nonatomic, retain) TreeNode*  lastSelectedTreeNode;
@property (nonatomic, retain) NSIndexPath* lastDeletedIndexPath;
@property (nonatomic, retain) UIAlertView* inputAlertView;
- (void) reloadFolderTootNode;
- (void) reloadTagRootNode;
@end

@implementation WizPadAllNotesViewController
@synthesize documentsMutableArray;
@synthesize masterTableView;
@synthesize detailTableView;
@synthesize lastSelectedTreeNode;
@synthesize checkDocuementDelegate;
@synthesize lastDeletedIndexPath;
@synthesize inputAlertView;
- (void) changedAlertRemindText:(NSString*)text
{
    if (nil != self.inputAlertView) {
        if (nil == text) {
            self.inputAlertView.message = [NSString stringWithFormat:@"\n\n\n%@",NSLocalizedString(@"Don't input \\,/,:,<,>,*,?,\",&", nil)];
        }
        else
        {
            self.inputAlertView.message = [NSString stringWithFormat:@"\n\n\n%@",text];
        }
    }
}
- (void) dealloc
{
    [WizNotificationCenter removeObserver:self];
    checkDocuementDelegate = nil;
    [lastSelectedTreeNode release];
    [documentsMutableArray release];
    [rootNodes release];
    [inputAlertView release];
    [needDisplayNodes release];
    [masterTableView release];
    [detailTableView release];
    [lastDeletedIndexPath release];
    [super dealloc];
}

- (void) reloadAllDetailData
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:50];
    for (NSArray* eachArray in self.documentsMutableArray) {
        [array addObjectsFromArray:eachArray];
    }
    [self reloadDetailData:array];
}
- (void) onDeleteDocument:(NSNotification*)nc
{
    WizDocument* doc = [WizNotificationCenter getWizDocumentFromNc:nc];
    if (nil == doc)
    {
        NSLog(@"nil");
        return;
    }
    NSIndexPath* indexPath = [self.documentsMutableArray removeDocument:doc];
    if (nil != indexPath) {
        if (WizDeletedSectionIndex == indexPath.row) {
            [self.detailTableView beginUpdates];
            [self.detailTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.detailTableView endUpdates];
        }
        else {
            [self.detailTableView beginUpdates];
            [self.detailTableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.detailTableView endUpdates];
        }
    }
}
- (void)updateDocument:(NSNotification*)nc
{
    NSString* documentGUID = [WizNotificationCenter getDocumentGUIDFromNc:nc];
    if (documentGUID == nil) {
        return;
    }
    WizDocument* doc = [WizDocument documentFromDb:documentGUID];
    if (doc == nil) {
        return;
    }
    NSIndexPath* updatePath = [self.documentsMutableArray updateDocument:doc];
    if (updatePath == nil) {
        return;
    }
    [self.detailTableView beginUpdates];
    [self.detailTableView reloadSections:[NSIndexSet indexSetWithIndex:updatePath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.detailTableView endUpdates];
}
- (id) init
{
    self = [super init];
    if (self) {
        [WizNotificationCenter addObserverForUpdateDocument:self selector:@selector(updateDocument:)];
        [WizNotificationCenter addObserverForDeleteDocument:self selector:@selector(onDeleteDocument:)];
        [WizNotificationCenter addObserverWithKey:self selector:@selector(reloadFolderTootNode) name:MessageTypeOfUpdateFolderTable];
        [WizNotificationCenter addObserverWithKey:self selector:@selector(reloadTagRootNode) name:MessageTypeOfUpdateTagTable];
        [WizNotificationCenter addObserverWithKey:self selector:@selector(reloadAllDetailData) name:MessageTypeOfPadTableViewListChangedOrder];
        rootNodes = [[NSMutableArray alloc] init];
        needDisplayNodes = [[NSMutableArray alloc] init];
        
        [needDisplayNodes addObject:[NSMutableArray array]];
        [needDisplayNodes addObject:[NSMutableArray array]];
        
        TreeNode* tagRootNode = [[[TreeNode alloc] init] autorelease];
        tagRootNode.title   = WizStrTags;
        tagRootNode.keyString = WizTreeViewTagKeyString;
        tagRootNode.strType = WizTreeViewTagKeyString;
        tagRootNode.isExpanded = YES;
        [rootNodes addObject:tagRootNode];
        
        TreeNode* folderRootNode = [[[TreeNode alloc] init] autorelease];
        folderRootNode.title   = WizStrFolders;
        folderRootNode.keyString = WizTreeViewFolderKeyString;
        folderRootNode.strType = WizTreeViewFolderKeyString;
        folderRootNode.isExpanded = YES;
        [rootNodes addObject:folderRootNode];
        
        documentsMutableArray = [[NSMutableArray alloc] init];
        
        isIgnoreReloadFolder = NO;
        isIgnoreReloadTag = NO;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [WizNotificationCenter addObserverForUpdateDocument:self selector:@selector(updateDocument:)];
        [WizNotificationCenter addObserverForDeleteDocument:self selector:@selector(onDeleteDocument:)];
        [WizNotificationCenter addObserverWithKey:self selector:@selector(reloadFolderTootNode) name:MessageTypeOfUpdateFolderTable];
        [WizNotificationCenter addObserverWithKey:self selector:@selector(reloadTagRootNode) name:MessageTypeOfUpdateTagTable];
        [WizNotificationCenter addObserverWithKey:self selector:@selector(reloadAllDetailData) name:MessageTypeOfPadTableViewListChangedOrder];
        rootNodes = [[NSMutableArray alloc] init];
        needDisplayNodes = [[NSMutableArray alloc] init];
        
        [needDisplayNodes addObject:[NSMutableArray array]];
        [needDisplayNodes addObject:[NSMutableArray array]];
        
        TreeNode* tagRootNode = [[[TreeNode alloc] init] autorelease];
        tagRootNode.title   = WizStrTags;
        tagRootNode.keyString = WizTreeViewTagKeyString;
        tagRootNode.strType = WizTreeViewTagKeyString;
        tagRootNode.isExpanded = YES;
        [rootNodes addObject:tagRootNode];
        
        TreeNode* folderRootNode = [[[TreeNode alloc] init] autorelease];
        folderRootNode.title   = WizStrFolders;
        folderRootNode.keyString = WizTreeViewFolderKeyString;
        folderRootNode.strType = WizTreeViewFolderKeyString;
        folderRootNode.isExpanded = YES;
        [rootNodes addObject:folderRootNode];
        
        documentsMutableArray = [[NSMutableArray alloc] init];
        
        isIgnoreReloadFolder = NO;
        isIgnoreReloadTag = NO;
    }
    return self;
}
- (TreeNode*) findRootNode:(NSString*)keyString
{
    if ([rootNodes count] == 0) {
        return nil;
    }
    for (TreeNode* each in rootNodes) {
        if ([each.keyString isEqualToString:keyString]) {
            return each;
        }
    }
    return nil;
}
- (void) addTagTreeNodeToParent:(WizTag*)tag   rootNode:(TreeNode*)root  allTags:(NSArray*)allTags
{
    NSLog(@"allTags is %d",[allTags count]);
    
    TreeNode* node = [[TreeNode alloc] init];
    node.title = getTagDisplayName(tag.title);
    node.keyString = tag.guid;
    node.isExpanded = NO;
    node.strType = WizTreeViewTagKeyString;
    if (tag.parentGUID == nil || [tag.parentGUID isEqual:@""]) {
        [root addChildTreeNode:node];
    }
    else
    {
        TreeNode* parentNode = [root childNodeFromKeyString:tag.parentGUID];
        if(nil != parentNode)
        {
            [parentNode addChildTreeNode:node];
        }
        else
        {
            WizTag* parent = nil;
            for (WizTag* each in allTags) {
                if ([each.guid isEqualToString:tag.parentGUID]) {
                    parent = each;
                }
            }
            if ([parent.parentGUID isEqualToString:tag.guid]) {
                return;
            }
            if (parent) {
                [self addTagTreeNodeToParent:parent rootNode:root allTags:allTags];
            }
            parentNode = [root childNodeFromKeyString:tag.parentGUID];
            [parentNode addChildTreeNode:node];
        }
    }
    [node release];
}

- (void) reloadTagRootNode
{
    if (isIgnoreReloadTag) {
        isIgnoreReloadTag = NO;
        return;
    }
    NSArray* tagArray = [[[WizDbManager shareDbManager] shareDataBase] allTagsForTree];
    TreeNode* tagRootNode = [self findRootNode:WizTreeViewTagKeyString];
    
    [tagRootNode removeAllChildrenNodes];
         
    for (WizTag* each in tagArray) {
        [self addTagTreeNodeToParent:each rootNode:tagRootNode allTags:tagArray];
    }
    NSMutableArray* tagsArray = [needDisplayNodes objectAtIndex:WizPadTreeTagIndex];
    [tagsArray removeAllObjects];
    [tagsArray addObjectsFromArray:[tagRootNode allExpandedChildrenNodes]];
    [self.masterTableView beginUpdates];
    [self.masterTableView reloadSections:[NSIndexSet indexSetWithIndex:WizPadTreeTagIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.masterTableView endUpdates];
}
- (NSString*) restructLoactionKey:(NSArray*)locationArray  maxIndex:(int)index
{
    NSMutableString* key = [NSMutableString string];
    [key appendString:@"/"];
    for (int i =1; i <= index; i++) {
        [key appendFormat:@"%@/",[locationArray objectAtIndex:i]];
    }
    return key;
}

- (void) makeSureParentExisted:(NSArray*)locationArray  rootNode:(TreeNode*)rootNode
{
    for (int i = 1; i < (NSInteger)[locationArray count] -1 ; i++) {
        NSString* key = [self restructLoactionKey:locationArray maxIndex:i];
        NSString* title = [locationArray objectAtIndex:i];
        TreeNode* currentNode = [rootNode childNodeFromKeyString:key];
        if (nil == currentNode) {
            currentNode = [[TreeNode alloc] init];
            currentNode.title = title;
            currentNode.keyString = key;
            currentNode.strType = WizTreeViewFolderKeyString;
            if (1 == i) {
                [rootNode addChildTreeNode:currentNode];
            }
            else
            {
                NSString* parentKey = [self restructLoactionKey:locationArray maxIndex:i-1];
                TreeNode* parentNode = [rootNode childNodeFromKeyString:parentKey];
                [parentNode addChildTreeNode:currentNode];
            }
            [currentNode release];
        }
    }
}
- (void) reloadFolderTootNode
{
    if (isIgnoreReloadFolder) {
        isIgnoreReloadFolder = NO;
        return;
    }
    NSArray* allFolders = [[[WizDbManager shareDbManager] shareDataBase] allLocationsForTree];
    TreeNode* folderRootNode = [self findRootNode:WizTreeViewFolderKeyString];
    [folderRootNode removeAllChildrenNodes];
    for (NSString* folderString in allFolders) {
        if ([folderString isEqualToString:@"/Deleted Items/"]) {
            continue;
        }
        NSArray* breakLocation = [folderString componentsSeparatedByString:@"/"];
        [self makeSureParentExisted:breakLocation rootNode:folderRootNode];
    }
    NSMutableArray* folderArray = [needDisplayNodes objectAtIndex:WizpadTreeFolderIndex];
    [folderArray removeAllObjects];
    [folderArray addObjectsFromArray:[folderRootNode allExpandedChildrenNodes]];

    [self.masterTableView reloadSections:[NSIndexSet indexSetWithIndex:WizpadTreeFolderIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    [self reloadTagRootNode];
    [self reloadFolderTootNode];
    detailTableView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

//
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([tableView isEqual:masterTableView]) {
        return [needDisplayNodes count];
    }
    else
    {
        NSLog(@"))))))section count is %d",[self.documentsMutableArray count]);
        return [self.documentsMutableArray count];
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:masterTableView]) {
        return [[needDisplayNodes objectAtIndex:section] count];
    }
    else
    {
        NSInteger count = UIInterfaceOrientationIsLandscape(self.interfaceOrientation)?3:2;
        if (0 ==  [self.documentsMutableArray count]) {
            return 0;
        }
        NSArray* sectionArray = [self.documentsMutableArray objectAtIndex:section];
        if ([sectionArray count]%count>0) {
            return  [sectionArray count]/count+1;
        }
        else {
            return [sectionArray count]/count;
        }
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:detailTableView]) {
        return PADABSTRACTVELLHEIGTH;
    }
    else
    {
        return 44;
    }
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:masterTableView]) {
        static NSString *CellIdentifier = @"WizPadTreeTableCell";
        WizPadTreeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (nil == cell) {
            cell = [[[WizPadTreeTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.delegate = self;
        }
        TreeNode* node = [[needDisplayNodes objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.strTreeNodeKey = node.keyString;
        [cell showExpandedIndicatory];
        return cell;
    }
    else
    {
        static NSString *CellIdentifier = @"WizPadAbstractCell";
        WizPadListCell *cell = (WizPadListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            static CGSize detailSize;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                detailSize = CGSizeMake(185, 280);
            });
            cell = [[[WizPadListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier detailViewSize:detailSize] autorelease];
            cell.selectedDelegate = self;
        }
        NSUInteger documentsCount= UIInterfaceOrientationIsLandscape(self.interfaceOrientation)?3:2;
        
        NSUInteger needLength = documentsCount*(indexPath.row+1);
        NSArray* sectionArray = [self.documentsMutableArray objectAtIndex:indexPath.section];
        NSArray* cellArray=nil;
        NSRange docRange;
        if ([sectionArray count] < needLength) {
            docRange =  NSMakeRange(documentsCount*indexPath.row, (NSInteger)[sectionArray count]-documentsCount*indexPath.row);
        }
        else {
            docRange = NSMakeRange(documentsCount*indexPath.row, documentsCount);
        }
        cellArray = [sectionArray subarrayWithRange:docRange];
        cell.documents = cellArray;
        [cell updateDoc];
        return cell;
    }
}
- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:masterTableView]) {
        [cell setNeedsDisplay];
    }

}
- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:masterTableView])
    {
        switch (section) {
            case WizpadTreeFolderIndex:
                return [[self findRootNode:WizTreeViewFolderKeyString] title];
            case WizPadTreeTagIndex:
                return [[self findRootNode:WizTreeViewTagKeyString] title];
            default:
                return @"";
        }
    }
    else
    {
        return  [[self.documentsMutableArray objectAtIndex:section]  arrayTitle];
    }
}
- (void) didSelectedHeader:(WizPadTreeTableHeaderView *)header  forTreeNode:(TreeNode *)node
{
    [self onExpandedNode:node];
}
- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:masterTableView])
    {
        TreeNode* treeNode = nil;
        switch (section) {
            case WizpadTreeFolderIndex:
                treeNode = [self findRootNode:WizTreeViewFolderKeyString];
                break;
                
            default:
                treeNode = [self findRootNode:WizTreeViewTagKeyString];
                break;
        }
        WizPadTreeTableHeaderView* titleView = [[WizPadTreeTableHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, WizTreeSectionHeaderViewHeight)];
        titleView.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
        titleView.delegate = self;
        titleView.treeNode = treeNode;
        
        [titleView showExpandedIndicatory];
        
        return [titleView autorelease];
    }
    else
    {
        return nil;
    }
}
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:masterTableView]) {
        return WizTreeSectionHeaderViewHeight;
    }
    else
    {
        return 30;
    }
}

- (void) reloadDetailData:(NSArray*)sourceArray
{
    
    NSLog(@"source count is %d",[sourceArray count]);
    
    NSInteger kOrderIndex = [[WizSettings defaultSettings] userTablelistViewOption];
    [self.documentsMutableArray removeAllObjects];
    [self.documentsMutableArray addObject:sourceArray];
    [self.documentsMutableArray performSelector:@selector(sortDocumentByOrder:) withObject:(id)kOrderIndex];
    [self.detailTableView reloadData];
}

- (void) reloadTagData:(NSString*)tagGuid
{
    [self reloadDetailData:[WizDocument documentsByTag:tagGuid]];
}

- (void) reloadFolderData:(NSString*)folderKey
{
    [self reloadDetailData:[WizDocument documentsByLocation:folderKey]];
}

- (void) onExpandedNode:(TreeNode *)node
{
    NSInteger section = NSNotFound;
    NSInteger row = NSNotFound;
    for (int i = 0 ; i < [needDisplayNodes count]; i++) {
        NSArray* array = [needDisplayNodes objectAtIndex:i];
        BOOL willBreak = NO;
        for (int j = 0; j < [array count]; j++) {
            TreeNode* eachNode = [array objectAtIndex:j];
            if ([eachNode.keyString isEqualToString:node.keyString]) {
                section = i;
                row = j;
                willBreak = YES;
                break;
            }
        }
        if (willBreak) {
            break;
        }
    }
    if (section == NSNotFound) {
        row = 0;
        if ([node.keyString isEqualToString:WizTreeViewTagKeyString]) {
            section = WizPadTreeTagIndex;
        }
        else if ([node.keyString isEqualToString:WizTreeViewFolderKeyString])
        {
            section = WizpadTreeFolderIndex;
        }
    }
    [self onExpandNode:node refrenceIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
}

- (void) onExpandNode:(TreeNode*)node refrenceIndexPath:(NSIndexPath*)indexPath
{
    NSMutableArray* tags = [needDisplayNodes objectAtIndex:indexPath.section];
    
    if (!node.isExpanded) {
        node.isExpanded = YES;
        NSArray*array = [node allExpandedChildrenNodes];
        
        NSInteger startPostion = [tags count] == 0? 0: indexPath.row+1;
        
        NSMutableArray* rows = [NSMutableArray array];
        for (int i = 0; i < [array count]; i++) {
            NSInteger  positionRow = startPostion+ i;
            
            TreeNode* node = [array objectAtIndex:i];
            [tags insertObject:node atIndex:positionRow];
            
            [rows addObject:[NSIndexPath indexPathForRow:positionRow inSection:indexPath.section]];
        }
        
        [masterTableView beginUpdates];
        [masterTableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
        [masterTableView endUpdates];
    }
    else
    {
        node.isExpanded = NO;
        NSMutableArray* deletedIndexPaths = [NSMutableArray array];
        NSMutableArray* deletedNodes = [NSMutableArray array];
        for (int i = indexPath.row; i < [tags count]; i++) {
            TreeNode* displayedNode = [tags objectAtIndex:i];
            if ([node childNodeFromKeyString:displayedNode.keyString]) {
                [deletedIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
                [deletedNodes addObject:displayedNode];
            }
        }
        
        for (TreeNode* each in deletedNodes) {
            [tags removeObject:each];
        }
        
        [masterTableView beginUpdates];
        [masterTableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [masterTableView endUpdates];
    }
    if (indexPath.row >= 0 && indexPath.section >= 0 && [[needDisplayNodes objectAtIndex:indexPath.section] count] >0) {
        [masterTableView beginUpdates];
        [masterTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [masterTableView endUpdates];
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:masterTableView]) {
        TreeNode* node = [[needDisplayNodes objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        self.lastSelectedTreeNode = node;
        switch (indexPath.section) {
            case WizPadTreeTagIndex:
                [self reloadTagData:node.keyString];
                break;
            case WizpadTreeFolderIndex:
                [self reloadFolderData:node.keyString];
                break;
            default:
                break;
        }
    }
    else
    {
        
    }
}

- (void) didPadCellDidSelectedDocument:(WizDocument *)doc
{
    NSInteger checkType = WizPadCheckDocumentSourceTypeOfRecent;
    if ([self.lastSelectedTreeNode.strType isEqualToString:WizTreeViewFolderKeyString]) {
        checkType = WizPadCheckDocumentSourceTypeOfFolder;
    }
    else if ([self.lastSelectedTreeNode.strType isEqualToString:WizTreeViewTagKeyString])
    {
        checkType = WizPadCheckDocumentSourceTypeOfTag;
    }
    
    [self.checkDocuementDelegate checkDocument:checkType keyWords:self.lastSelectedTreeNode.keyString selectedDocument:doc];
}
//
- (NSString*) folderForNewNote
{
    if (self.lastSelectedTreeNode && [self.lastSelectedTreeNode.strType isEqualToString:WizTreeViewFolderKeyString]) {
        return self.lastSelectedTreeNode.keyString;
    }
    return nil;
}
- (NSString*) tagGuidForNewNote
{
    if (self.lastSelectedTreeNode && [self.lastSelectedTreeNode.strType isEqualToString:WizTreeViewTagKeyString]) {
        return self.lastSelectedTreeNode.keyString;
    }
    return nil;
}

- (TreeNode*) findTreeNodeByKey:(NSString*)strKey
{
    
    if ([strKey isEqualToString:WizTreeViewFolderKeyString]) {
        return [self findRootNode:WizTreeViewFolderKeyString];
    }
    else if ([strKey isEqualToString:WizTreeViewTagKeyString])
    {
        return [self findRootNode:WizTreeViewTagKeyString];
    }
    
    TreeNode* node = [[self findRootNode:WizTreeViewFolderKeyString] childNodeFromKeyString:strKey];
    if (node) {
        return node;
    }
    node = [[self findRootNode:WizTreeViewTagKeyString] childNodeFromKeyString:strKey];
    if (node) {
        return node;
    }
    return nil;
}

- (NSInteger) treeNodeDeep:(NSString *)strKey
{
    TreeNode* node = [self findTreeNodeByKey:strKey];
    if (node) {
        return node.deep;
    }
    return 0;
}
- (void) onExpandedNodeByKey:(NSString *)strKey
{
    TreeNode* node = [self findTreeNodeByKey:strKey];
    if (node) {
        [self onExpandedNode:node];
    }
}
- (void) showExpandedIndicatory:(WizPadTreeTableCell *)cell
{
    TreeNode* node = [self findTreeNodeByKey:cell.strTreeNodeKey];
    if ([node.childrenNodes count]) {
        if (!node.isExpanded) {
            [cell.expandedButton setImage:[UIImage imageNamed:@"treePadItemClosed"] forState:UIControlStateNormal];
        }
        else
        {
            [cell.expandedButton setImage:[UIImage imageNamed:@"treePadItemOpened"] forState:UIControlStateNormal];
        }
    }
    else
    {
        [cell.expandedButton setImage:nil forState:UIControlStateNormal];
    }
}
- (void) decorateTreeCell:(WizPadTreeTableCell *)cell
{
    TreeNode* node = [self findTreeNodeByKey:cell.strTreeNodeKey];
    if (node == nil || node.keyString == nil) {
        cell.detailLabel.text = nil;
        cell.titleLabel.text = nil;
        return;
    }
    if ([node.strType isEqualToString:WizTreeViewFolderKeyString]) {
        NSInteger currentCount = [WizObject fileCountOfLocation:node.keyString];
        NSInteger totalCount = [WizObject filecountWithChildOfLocation:node.keyString];
        if (currentCount != totalCount) {
            cell.detailLabel.text = [NSString stringWithFormat:@"%d/%d",currentCount,totalCount];
        }
        else {
            cell.detailLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d notes", nil),currentCount];
        }
        cell.titleLabel.text = NSLocalizedString(node.title, nil) ;
    }
    else if ([node.strType isEqualToString:WizTreeViewTagKeyString])
    {
        NSInteger fileNumber = [WizTag fileCountOfTag:node.keyString];
        NSString* count = [NSString stringWithFormat:NSLocalizedString(@"%d notes", nil),fileNumber];
        cell.detailLabel.text = count;
        cell.titleLabel.text = getTagDisplayName(node.title);
    }
    
}

- (void) deleteTreeNode:(NSIndexPath*)indexPath  useingBlock:(void (^)(TreeNode* node) )blocs  andEndBlocks:(void(^)(void))endBlock
{
    TreeNode* node = [[needDisplayNodes objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [node.parentTreeNode removeChildTreeNode:node];
    if (node.isExpanded) {
        [self onExpandedNode:node];
    }
    NSArray* tags = [node allChildren];
    for (TreeNode* eachNode in tags) {
        blocs(eachNode);
    }
    blocs(node);

    endBlock();
    [[needDisplayNodes objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
    [self.masterTableView beginUpdates];
    [self.masterTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    if (indexPath.row > 0) {
        [self.masterTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row -1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.masterTableView endUpdates];
}

- (BOOL) isAddFolerTreeNodeVaild:(NSString *)title
{
    BOOL isFolderExist = [[[WizDbManager shareDbManager] shareDataBase] isExistFolderWithTitle:title];
    if (isFolderExist) {
        [WizGlobals reportWarningWithString:[NSString stringWithFormat:NSLocalizedString(@"Folder named %@ exists!", nil),NSLocalizedString(title, nil)]];
    }
    return !isFolderExist;
}
- (BOOL) isAddTagTreeNodeVaild:(NSString *)title
{
    BOOL isTagExist = [[[WizDbManager shareDbManager] shareDataBase] isExistTagWithTitle:title];
    NSLog(@"title is %@ exist is %d",title, isTagExist);
    if (isTagExist) {
        [WizGlobals reportWarningWithString:[NSString stringWithFormat:NSLocalizedString(@"Tag named %@ exists!", nil),title]];
    }
    return !isTagExist;
}
- (void) addNodeFromRootNode:(TreeNode*)node  title:(NSString*)title
{
    if ([node.strType isEqualToString:WizTreeViewFolderKeyString]) {
        if (nil == title || [title isEqualToString:@""] || ![self isAddFolerTreeNodeVaild:title]) {
            return;
        }
    }
    else
    {
        if (nil == title || [title isEqualToString:@""] || ![self isAddTagTreeNodeVaild:title]) {
            return;
        }
    }
    
    if (node.isExpanded) {
        [self onExpandedNode:node];
    }
    if ([node.strType isEqualToString:WizTreeViewTagKeyString]) {
        
        NSString* parentGuid = [node.keyString isEqualToString:WizTreeViewTagKeyString] ? nil : node.keyString;
        WizTag* tag = [[WizTag alloc] init];
        tag.guid = [WizGlobals genGUID];
        tag.title = title;
        tag.parentGUID = parentGuid;
        [tag save];
        TreeNode* nodeAdded = [[TreeNode alloc] init];
        nodeAdded.title = title;
        nodeAdded.strType = WizTreeViewTagKeyString;
        nodeAdded.keyString = tag.guid;
        [node addChildTreeNode:nodeAdded];
        [nodeAdded release];
        [tag release];
    }
    else if ([node.strType isEqualToString:WizTreeViewFolderKeyString])
    {
        NSString* parentPath = [node.keyString isEqualToString:WizTreeViewFolderKeyString] ? @"/" : node.keyString;
        
        NSString* path = [NSString stringWithFormat:@"%@%@/",parentPath,title];
        
        [WizObject addLocalFolder:path];
        TreeNode* nodeAdded = [[TreeNode alloc] init];
        nodeAdded.title = title;
        nodeAdded.strType = WizTreeViewFolderKeyString;
        nodeAdded.keyString = path;
        [node addChildTreeNode:nodeAdded];
        [nodeAdded release];
    }
    

    [self onExpandedNode:node];
    
}


- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
         if (self.lastDeletedIndexPath != nil)
         {
            if (alertView.tag == 9090)
            {
                [self deleteTreeNode:self.lastDeletedIndexPath useingBlock:^(TreeNode *node)
                {
                        [WizObject deleteFolder:node.keyString];
                }
                andEndBlocks:^
                {
                        isIgnoreReloadFolder = YES;
                         [WizNotificationCenter postSimpleMessageWithName:MessageTypeOfUpdateFolderTable];
                     }];
            }
            else if (alertView.tag == WizDeletedTagViewTag)
            {
                
                [self deleteTreeNode:self.lastDeletedIndexPath useingBlock:^(TreeNode * node)
                {
                    [WizTag deleteLocalTag:node.keyString];
                    NSLog(@"delete %@",node.keyString);
                }
                        andEndBlocks:^
                {
                            isIgnoreReloadTag = YES;
                            [WizNotificationCenter postSimpleMessageWithName:MessageTypeOfUpdateTagTable];
                } ];
            }
             self.lastDeletedIndexPath = nil;
        }
        else if (self.lastSelectedTreeNode != nil)
        {
            NSString* title = WizStrNoTitle;
            for (UIView* each in [alertView subviews]) {
                if ([each isKindOfClass:[UITextField class]]) {
                    UITextField* textFiled = (UITextField*)each;
                    NSString* str = textFiled.text;
                    if (str) {
                        title = str;
                    }
                }
            }
            [self addNodeFromRootNode:self.lastSelectedTreeNode title:title];
        }
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        masterTableView.frame = CGRectMake(0.0, 0.0, 320, 768 - 108);
        detailTableView.frame = CGRectMake(320, 0.0, 1024-320, 768 - 108);
    }
    else
    {
        masterTableView.frame = CGRectMake(0.0, 0.0, 320, 1024 - 108);
        detailTableView.frame = CGRectMake(320, 0.0, 768-320, 1024 -108);
    }
}
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSLog(@"self orientation is %d",self.interfaceOrientation);
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        masterTableView.frame = CGRectMake(0.0, 0.0, 320, 768 - 108);
        detailTableView.frame = CGRectMake(320, 0.0, 1024-320, 768 - 108);
    }
    else
    {
        masterTableView.frame = CGRectMake(0.0, 0.0, 320, 1024 - 108);
        detailTableView.frame = CGRectMake(320, 0.0, 768-320, 1024 -108);
    }
    [self.detailTableView reloadData];
}


- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.detailTableView]) {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TreeNode* node = [[needDisplayNodes objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        self.lastDeletedIndexPath = indexPath;
        if (indexPath.section  == WizpadTreeFolderIndex) {
            
            if ([node.keyString isEqualToString:@"/My Notes/"]) {
                [WizGlobals reportWarningWithString:[NSString stringWithFormat:NSLocalizedString(@"Deleting %@ is not allowed!", nil),WizStrMyNotes]];
                return;
            }

            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Folder", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"You will delete the folder %@ and notes in it, are you sure?", nil),[WizGlobals folderStringToLocal:node.title]]
                                                           delegate:self cancelButtonTitle:WizStrCancel otherButtonTitles:WizStrDelete, nil];
            alert.tag = 9090;
            [alert show];
            [alert release];


        }
        else if (indexPath.section == WizPadTreeTagIndex)
        {
            
            if ([node.title isEqualToString:WizTagPublic]) {
                [WizGlobals reportWarningWithString:[NSString stringWithFormat:NSLocalizedString(@"Deleting %@ is not allowed!", nil),WizTagPublic]];
                return;
            }
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Tag", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"You will delete the tag %@ , are you sure?", nil), getTagDisplayName(node.title)]
                                                           delegate:self cancelButtonTitle:WizStrCancel otherButtonTitles:WizStrDelete, nil];
            alert.tag = WizDeletedTagViewTag;
            [alert show];
            [alert release];

        }
        
    }
    
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        
    }
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.masterTableView]) {
        return YES;
    }
    return NO;
}

- (void) addNewTreeNodeFrom:(NSString *)strNodeKey
{
    TreeNode* node = [self findRootNode:strNodeKey];
    if (node != nil) {
        self.lastSelectedTreeNode = node;
        [self didSelectedTheNewTreeNodeButton:strNodeKey];
    }

}
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL hasInvailedCharacters = [string checkHasInvaildCharacters];
    
    if (hasInvailedCharacters) {
        [self changedAlertRemindText:[WizGlobalError folderInvalidCharacterErrorString:string]];
        return NO;
    }
    else
    {
        [self changedAlertRemindText:nil];
        return YES;
    }
}
- (void) didSelectedTheNewTreeNodeButton:(NSString *)strTreeNodeKey
{
    TreeNode* node = [self findTreeNodeByKey:strTreeNodeKey];
    
    NSString* strAlertTitle = nil;
    NSString* strAlertPlaceHolder = nil;
    
    NSInteger nAlertViewTag = 0;
    if ([node.strType isEqualToString:WizTreeViewTagKeyString]) {
        strAlertTitle = NSLocalizedString(@"Add Tag", nil);
        strAlertPlaceHolder = NSLocalizedString(@"Tag title", nil);
        nAlertViewTag = WizAddNewTagViewTag;
    }
    else
    {
        strAlertTitle = NSLocalizedString(@"Add Folder", nil);
        strAlertPlaceHolder = NSLocalizedString(@"Folder title", nil);
        nAlertViewTag = WizAddNewFolderViewTag;
    }
    UIAlertView* prompt = [[UIAlertView alloc] initWithTitle:strAlertTitle
                                                     message:@"\n\n\n\n\n"
                                                    delegate:nil
                                           cancelButtonTitle:WizStrCancel
                                           otherButtonTitles:WizStrOK, nil];
    prompt.tag = nAlertViewTag;
    //
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(27.0, 60.0, 230.0,30)];
    [textField setBackgroundColor:[UIColor whiteColor]];
    [textField setPlaceholder:strAlertPlaceHolder];
    [prompt addSubview:textField];
    textField.delegate = self;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [textField release];
    
    //
    [prompt setTransform:CGAffineTransformMakeTranslation(0.0, -100.0)];
    prompt.delegate = self;
    [prompt show];
    
    self.inputAlertView = prompt;
    [self changedAlertRemindText:nil];
    [prompt release];
}

@end

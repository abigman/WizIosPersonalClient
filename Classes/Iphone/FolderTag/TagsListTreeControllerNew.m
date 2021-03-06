//
//  TagsListTreeControllerNew.m
//  Wiz
//
//  Created by dong yishuiliunian on 11-12-21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "TagsListTreeControllerNew.h"
#import "TreeViewBaseController.h"
#import "WizIndex.h"
#import "WizGlobalData.h"
#import "LocationTreeNode.h"
#import "LocationTreeViewCell.h"
#import "FolderListView.h"
#import "TagDocumentListView.h"
#import "WizGlobals.h"
#import "WizPhoneNotificationMessage.h"
#import "CommonString.h"
@implementation TagsListTreeControllerNew

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
- (void) removeBlockLocationNode:(LocationTreeNode*)node
{
    WizIndex* index = [[WizGlobalData sharedData] indexData: self.accountUserId];
    if ([node hasChildren]) {
        NSArray* arr = [node.children copy];
        for (LocationTreeNode* each in arr) {
            [self removeBlockLocationNode:each];
        }
        if (![node hasChildren] && ![index fileCountOfTag:node.locationKey]) {
            [node.parentLocationNode removeChild:node];
        }
        [arr release];
    }
    else
    {
        if (![index fileCountOfTag:node.locationKey]) {
            [node.parentLocationNode removeChild:node];
        }
    }
}



- (void) reloadAllData
{
    NSArray* tagArray = [[[WizGlobalData sharedData] indexData:accountUserId] allTagsForTree];
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    tree = [[LocationTreeNode alloc]init] ;
    tree.deep = 0;
    tree.title = @"/";
    tree.locationKey = @"/";
    tree.hidden = YES;
    tree.expanded =YES;
    for (WizTag* each in tagArray)
    {
        LocationTreeNode* node = [[LocationTreeNode alloc] init];
        NSString* tagName = getTagDisplayName(each.name);
        node.title = tagName;
        node.locationKey = each.guid;
        if (nil != each.parentGUID && ![each.parentGUID isEqualToString:@""]) {
            LocationTreeNode* parent = [LocationTreeNode findNodeByKey:each.parentGUID :self.tree];
            if (nil == parent) {
                WizTag* parentTag = [index tagFromGuid:each.parentGUID];
                LocationTreeNode* nodee = [[LocationTreeNode alloc] init];
                nodee.title = parentTag.name;
                nodee.locationKey = parentTag.guid;
                [tree addChild:parent];
                [nodee addChild:node];
                [nodee release];
                [node release];
                continue;
            }
            else
            {
                [parent addChild:node];
                [node release];
                continue;
            }
        }
        else
        {
            [tree addChild:node];
            [node release];
        }
        
    }
    if (nil == self.displayNodes) {
        self.displayNodes = [NSMutableArray array];
    } else
    {
        [self.displayNodes removeAllObjects];
    }
    [self removeBlockLocationNode:tree];
    [LocationTreeNode getLocationNodes:self.tree :self.displayNodes];
    [self setNodeRow];
    [self.tableView reloadData];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAllData) name:MessageOfTagViewVillReloadData object:nil];
    [self reloadAllData];
    self.closedImage = [UIImage imageNamed:@"treePlus"];
    self.expandImage = [UIImage imageNamed:@"treeCut"];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, [WizGlobals heightForWizTableFooter:[self.displayNodes count]])];
    UIImageView* searchFooter = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tagTableFooter"]];
    [footerView addSubview:searchFooter];
    self.tableView.tableFooterView = footerView;
    footerView.backgroundColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0];
    [searchFooter release];
    [footerView release];
    UITextView* remind = [[UITextView alloc] initWithFrame:CGRectMake(90, 0, 200, 100)];
    remind.text = NSLocalizedString(@"Tap on a tag above to see all notes with that tag. Make your notes easier to find by creating and assinging more tags.", nil);
    remind.backgroundColor = [UIColor clearColor];
    remind.textColor = [UIColor grayColor];
    [searchFooter addSubview:remind];
    [remind release];
}

- (void) setDetail:(LocationTreeViewCell *)cell
{
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d notes", nil),[index fileCountOfTag:cell.treeNode.locationKey]];
    if (![cell.treeNode hasChildren]) {
        cell.imageView.image = [UIImage imageNamed:@"treeTag"];
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MessageOfTagViewVillReloadData object:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WizIndex* index = [[WizGlobalData sharedData] indexData:self.accountUserId];
    WizTag* tag =  [index tagFromGuid:[[self.displayNodes objectAtIndex:indexPath.row] locationKey]];;
    //
    TagDocumentListView* tagView = [[TagDocumentListView alloc] initWithStyle:UITableViewStylePlain];
    tagView.accountUserID = accountUserId;
    tagView.tag = tag;
    [self.navigationController pushViewController:tagView animated:YES];
    [tagView release];
}

@end

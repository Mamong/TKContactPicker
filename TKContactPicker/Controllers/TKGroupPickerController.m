//
//  TKGroupPickerController.m
//  Thumb+
//
//  Created by Jongtae Ahn on 12. 9. 1..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import "TKPeoplePickerController.h"
#import "TKGroupPickerController.h"
#import "TKContactsPickerController.h"
#import "TKGroup.h"

@interface TKGroupPickerController (){
    NSArray *cpsGroups;
}

@end

@implementation TKGroupPickerController
@synthesize groups = _groups;

- (void)reloadGroups
{
    NSMutableArray *groupsTemp = [NSMutableArray array];
    ABAddressBookRef addressBookRef = _addressbook;
    CFArrayRef allGroups = ABAddressBookCopyArrayOfAllGroups(addressBookRef);
    CFIndex groupsCount = ABAddressBookGetGroupCount(addressBookRef);
	for (NSInteger i = 0; i < groupsCount; i++)
    {
        TKGroup *group = [[TKGroup alloc] init];
        ABRecordRef groupRecord = CFArrayGetValueAtIndex(allGroups, i);
        CFStringRef groupName = ABRecordCopyCompositeName(groupRecord);
        CFArrayRef currentGroupCount = ABGroupCopyArrayOfAllMembers(groupRecord);
        group.name = (__bridge NSString*)groupName;
        group.recordID = (int)ABRecordGetRecordID(groupRecord);
        group.membersCount = (int)[(__bridge NSArray*)currentGroupCount count];
        
		[groupsTemp addObject:group];
        //[group release];

        CFRelease(currentGroupCount);
        CFRelease(groupName);
    }
    if (allGroups) CFRelease(allGroups);
        
    // Sorting by name
    NSMutableArray *sortGroups = [NSMutableArray arrayWithArray:groupsTemp];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    self.groups = [NSMutableArray arrayWithArray:[sortGroups sortedArrayUsingDescriptors:sortDescriptors]];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Groups", nil);
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cpsGroups = @[@"All CPS",@"Work",@"Home"];
    
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup:)]];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    
    [self reloadGroups];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	//return 1 + ([_groups count] > 0 ? 1 : 0);
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowNumber;
    switch (section) {
        case 0: {
            rowNumber = 1;
        } break;
        case 1: {
            rowNumber = [cpsGroups count];
        } break;
        default: {
            rowNumber = 1;
        } break;
    }
    return rowNumber;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section==1) {
        return @"CPS";
    }else if(section == 2)
        return @"ON MY IPHONE";
    return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    if (YES) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    switch (indexPath.section) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"Show All Contacts", nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
        } break;
        case 1:{
            
            cell.textLabel.text = [cpsGroups objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = nil;
        }break;
        case 2:{
            cell.textLabel.text = NSLocalizedString(@"All on My iPhone", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", (int)ABAddressBookGetPersonCount(_addressbook)];
        }break;
        default: {
            TKGroup *group = [self.groups objectAtIndex:indexPath.row];
            cell.textLabel.text = group.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%li", (long)group.membersCount];
        } break;
    }
    

	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Hide All Contacts";
    }else{
        if (YES) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

#pragma mark -
#pragma mark Barbutton action

- (IBAction)addGroup:(id)sender
{
    // The future will be added
}

- (IBAction)doneAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tkGroupPickerController:didSelectGroup:)])
        [self.delegate tkGroupPickerController:self didSelectGroup:nil];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
}

//- (void)dealloc
//{
//    [_groups release];
//    [_tableView release];
//	[super dealloc];
//}

@end

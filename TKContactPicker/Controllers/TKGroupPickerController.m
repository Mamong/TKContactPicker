//
//  TKGroupPickerController.m
//  Thumb+
//
//  Created by Jongtae Ahn on 12. 9. 1..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.

//  Altered by Marco       on 15. 11.2..
//  Copyright (c) 2015 ET Inc. All rights reserved.

#import "TKPeoplePickerNavigationController.h"
#import "TKGroupPickerController.h"
#import "TKContactsPickerController.h"

@interface TKGroupPickerController (){
    NSMutableSet *selectValueSet;
    
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

        if(currentGroupCount) CFRelease(currentGroupCount);
        if(groupName) CFRelease(groupName);
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
        selectValueSet = [NSMutableSet setWithObject:@"0-0"];
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    return 1 + ([_groups count] > 0 ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowNumber;
    switch (section) {
        case 0: {
            rowNumber = 1;
        } break;
        default: {
            rowNumber = [_groups count];
        } break;
    }
    return rowNumber;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    switch (indexPath.section) {
        case 0: {
            //cell.textLabel.text = NSLocalizedString(@"All Contacts", nil);
            cell.textLabel.text = [NSString stringWithFormat:@"All Contacts (%i)", (int)ABAddressBookGetPersonCount(_addressbook)];
        } break;
        default: {
            TKGroup *group = [self.groups objectAtIndex:indexPath.row];
            //cell.textLabel.text = group.name;
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (%i)",group.name,group.membersCount];
        } break;
    }
    if ([selectValueSet containsObject:[NSString stringWithFormat:@"%d-%d",indexPath.section,indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *index = [NSString stringWithFormat:@"%d-%d",indexPath.section,indexPath.row];
    if ([selectValueSet containsObject:index]) {
        [selectValueSet removeObject:index];
    }else{
        [selectValueSet addObject:index];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith %@",[NSString stringWithFormat:@"%d",indexPath.section]];
    [selectValueSet filterUsingPredicate:predicate];
    [tableView reloadData];
}
#pragma mark -
#pragma mark Barbutton action

- (IBAction)addGroup:(id)sender
{
    // The future will be added
}

- (IBAction)doneAction:(id)sender
{
    NSMutableArray *groups = [NSMutableArray array];
    for (NSString *index in selectValueSet) {
        NSArray *array = [index componentsSeparatedByString:@"-"];
        NSUInteger row = [[array objectAtIndex:1] integerValue];
        if (![index hasPrefix:@"0"]) {
            [groups addObject:[_groups objectAtIndex:row]];
        }else
            groups = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(tkGroupPickerController:didSelectGroups:)])
        [self.delegate tkGroupPickerController:self didSelectGroups:groups];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
}

@end

//
//  TKContactsMultiPickerController.h
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <malloc/malloc.h>
#import "TKContact.h"
#import "TKGroup.h"
#import "TKGroupPickerController.h"

@class TKContact, TKContactsPickerController;
@protocol TKContactsPickerControllerDelegate <NSObject>
@required
- (void)tkContactsPickerController:(TKContactsPickerController*)picker didFinishPickingDataWithInfo:(NSArray*)contacts;
- (void)tkContactsPickerControllerDidCancel:(TKContactsPickerController*)picker;
@end


@interface TKContactsPickerController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate,TKGroupPickerControllerDelegate>
{
	id _delegate;
    
@private
    TKGroup *_group;
    NSUInteger _selectedCount;
    NSMutableArray *_listContent;
	NSMutableArray *_filteredListContent;
    NSLayoutConstraint *bottomConstraint;
    ABAddressBookRef _addressBook;
}

@property (nonatomic, retain) id<TKContactsPickerControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) TKGroup *group;
@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;
@property(nonatomic,retain)UISearchDisplayController *searchController;


- (id)initWithGroup:(TKGroup*)group;
- (void)reloadAddressBook;

@end

//
//  TKGroupPickerController.h
//  Thumb+
//
//  Created by Jongtae Ahn on 12. 9. 1..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "TKGroup.h"

@class TKGroupPickerController;
@protocol TKGroupPickerControllerDelegate <NSObject>
@required
- (void)tkGroupPickerController:(TKGroupPickerController*)picker didSelectGroup:(TKGroup*)group;
@end

@interface TKGroupPickerController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate> {

}

@property (nonatomic, weak) id<TKGroupPickerControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, assign) ABAddressBookRef addressbook;


- (void)reloadGroups;

@end

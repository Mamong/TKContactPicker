//
//  MCContactDetailViewController.m
//  TKContactPicker
//
//  Created by marco on 10/27/15.
//  Copyright © 2015 TABKO Inc. All rights reserved.
//

#import "TKContactDetailViewController.h"
#import "TKContactCell.h"

@interface TKContactDetailViewController ()

@end

@implementation TKContactDetailViewController

- (id)initWithContact:(TKContact*)contact
{
    if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
        self.displayedContact = contact;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.dataSource = self;
    self.tableView.delegate =self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"TKContactCell" bundle:nil] forCellReuseIdentifier:@"phonecell"];
    
    self.tableView.tableHeaderView = [self headerView];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView*)headerView
{
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100)];
    UIImageView *contactImage = [[UIImageView alloc]initWithFrame:CGRectMake(20, 10, 60, 60)];
    if(self.displayedContact.thumbnail) {
        contactImage.image = self.displayedContact.thumbnail;
    }else{
        contactImage.image = [UIImage imageNamed:@"icon-avatar-60x60"];
    }
    contactImage.layer.masksToBounds = YES;
    contactImage.layer.cornerRadius = 30;

    
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(100, 26, self.tableView.frame.size.width-75, 30)];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.text = self.displayedContact.name;
    
    [backView addSubview:contactImage];
    [backView addSubview:label];
    return backView;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.displayedContact.tel) {
        return 1;
    }
    return [self.displayedContact.tels count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"phonecell";
    TKContactCell *cell = (TKContactCell*)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (self.displayedContact.tel) {
        cell.labelTextLabel.text = self.displayedContact.telLabel;
        cell.phoneTextLabel.text = self.displayedContact.tel;
    }else{
        cell.labelTextLabel.text = [[self.displayedContact.tels objectAtIndex:indexPath.row]valueForKey:@"label"];
        cell.phoneTextLabel.text = [[self.displayedContact.tels objectAtIndex:indexPath.row]valueForKey:@"value"];
    }
    return cell;
}

// support kABPersonPhoneProperty only
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tkContactDetailViewController:didSelectPerson:index:property:identifier:)]) {
        if (self.displayedContact.recordID != 0) {
            ABRecordRef contactRecord = ABAddressBookGetPersonWithRecordID(_addressBook, self.displayedContact.recordID);
            ABMultiValueRef valuesRef = ABRecordCopyValue(contactRecord, kABPersonPhoneProperty);
            ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(valuesRef,indexPath.row);
            [self.delegate tkContactDetailViewController:self didSelectPerson:self.displayedContact index:indexPath.row property:kABPersonPhoneProperty identifier:identifier];
            CFRelease(valuesRef);

        }else
        {
            [self.delegate tkContactDetailViewController:self didSelectPerson:self.displayedContact index:indexPath.row property:kABPersonPhoneProperty identifier:-1];
        }
    }
}


- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    if (action==@selector(copy:))
        return YES;
    else
        return NO;
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    if (action==@selector(copy:)) {//如果操作为复制
        TKContactCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];//黏贴板
        [pasteBoard setString:cell.phoneTextLabel.text];
        //NSLog(@"%@",pasteBoard.string);//获得剪贴板的内容
    }
}

@end

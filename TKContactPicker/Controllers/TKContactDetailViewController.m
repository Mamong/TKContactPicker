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
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(35, 26, self.tableView.frame.size.width-35, 30)];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.text = self.displayedContact.name;
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
    //cell.separatorInset = UIEdgeInsetsMake(<#CGFloat top#>, <#CGFloat left#>, <#CGFloat bottom#>, <#CGFloat right#>)
    //NSAttributedString *attString = [NSAttributedString alloc]initWithString:[[self.displayedPerson.tels objectAtIndex:indexPath.row]valueForKey:@"label"] attributes:<#(nullable NSDictionary<NSString *,id> *)#>
    cell.labelTextLabel.text = [[self.displayedContact.tels objectAtIndex:indexPath.row]valueForKey:@"label"];
    cell.phoneTextLabel.text = [[self.displayedContact.tels objectAtIndex:indexPath.row]valueForKey:@"value"];
    return cell;
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

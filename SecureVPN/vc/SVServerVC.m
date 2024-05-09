//
//  SVServerVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVServerVC.h"
#import "SVNavigationView.h"
#import "UIView+SV.h"
#import "SVFbHandle.h"
#import "SVNTools.h"
#import "SVNManager.h"
#import "SVPosterManager.h"

NSNotificationName const SVVNConnectNoto = @"SVVNConnectNoto";

@interface SVConnectCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *selectImageView;

@end

@implementation SVConnectCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor colorWithHexString:@"#202329"];
        self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sever_bg"]];
        [self.contentView addSubview:self.bgImageView];
        [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.mas_equalTo(0);
        }];
        
        self.iconImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:self.iconImageView];
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(30);
            make.centerX.mas_equalTo(0);
            make.width.mas_equalTo(51);
            make.height.mas_equalTo(40);
        }];
        
        self.nameLabel = [UILabel lbText:@"name" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(-10);
            make.left.right.mas_equalTo(0);
        }];
        
        self.selectImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"server_select"]];
        self.selectImageView.hidden = YES;
        [self.contentView addSubview:self.selectImageView];
        [self.selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.mas_equalTo(0);
        }];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        self.selectImageView.hidden = NO;
    } else {
        self.selectImageView.hidden = YES;
    }
}

@end

@interface SVServerVC () <UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, GADFullScreenContentDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, strong) SVServerModel *model;
@property (nonatomic, assign) BOOL isClickConnect;

@property (nonatomic, strong, nullable) GADInterstitialAd *backInterstitial;

@end

@implementation SVServerVC

- (void)didVC {
    [super didVC];
    [[SVPosterManager sharedInstance] enterServer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (id)initWithModel:(SVServerModel *)model; {
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"#202329"];
    self.isClickConnect = NO;
    self.selectIndex = -1;
    SVNavigationView *navView = [[SVNavigationView alloc] init];
    navView.textLabel.text = @"Select Server";
    [navView.rightButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:navView];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navView.mas_bottom).offset(10);
        make.left.right.bottom.mas_equalTo(0);
    }];
    
    UIButton *connectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    connectButton.titleLabel.font = [UIFont fontWithSize:17 weight:UIFontWeightMedium];
    [connectButton tColor:[UIColor whiteColor]];
    [connectButton bgImage:[UIImage imageNamed:@"button_bg"]];
    [connectButton addTarget:self action:@selector(connectAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:connectButton];
    [connectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(284);
        make.height.mas_equalTo(51);
        make.centerX.mas_equalTo(0);
        if (SVScreenHeight() > 800) {
            make.top.mas_equalTo(726);
        } else {
            make.bottom.mas_equalTo(-SVBottom());
        }
    }];
    [self dataSource];
    if (self.selectIndex >= 0) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectIndex inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (void)connectAction {
    if (self.selectIndex >= 0) {
        self.isClickConnect = YES;
        SVNetInfoModel *model = self.dataSource[self.selectIndex];
        [SVStatisticAnalysis saveEvent:@"click_server" params:@{@"type": model.countryCode}];
        [self displayAdvert];
    } else {
        [UIView sv_tipToast:@"Please select server"];
    }
}

- (void)backAction {
    [self displayAdvert];
}

- (void)displayAdvert {
    [SVStatisticAnalysis saveEvent:@"scene_bk" params:@{@"type": @"server"}];
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    SVAdvertLocationType type = SVAdvertLocationTypeBack;
    if ([manager isCanShowAdvertWithType:type]) {
        if (manager.backInterstitial && [manager isCacheValidWithType:type]) {
            if (manager.isScreenAdShow) return;
            manager.isScreenAdShow = YES;
            self.backInterstitial = manager.backInterstitial;
            manager.backInterstitial = nil;
            self.backInterstitial.fullScreenContentDelegate = self;
            [self.backInterstitial presentFromRootViewController:self];
        } else {
            [self jumpVCWithAnimated:YES];
        }
    } else {
        [self jumpVCWithAnimated:YES];
    }
}

- (void)jumpVCWithAnimated:(BOOL)animated {
    if (self.isClickConnect && self.selectIndex >= 0) {
        self.isClickConnect = NO;
        SVServerModel *model = self.dataSource[self.selectIndex];
        [[NSNotificationCenter defaultCenter] postNotificationName:SVVNConnectNoto object:model];
    }
    [self.navigationController popViewControllerAnimated:animated];
}

#pragma mark - UICollectionViewDelegate && UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SVConnectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVConnectCell" forIndexPath:indexPath];
    SVServerModel *model = self.dataSource[indexPath.row];
    cell.iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"select_%@", model.countryCode]];
    cell.nameLabel.text = model.name;
//    if (self.selectIndex == indexPath.row) {
//        if (!cell.isSelected) {
//            cell.selected = YES;
//        }
//    } else {
//        if (cell.isSelected) {
//            cell.selected = NO;
//        }
//    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *array = collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *selectIndexPath in array) {
        if (selectIndexPath != indexPath) {
            [collectionView deselectItemAtIndexPath:selectIndexPath animated:YES];
        }
    }
    self.selectIndex = indexPath.row;
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.selected = YES;
}

#pragma mark - Getters and Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 20;
        layout.minimumInteritemSpacing = 0;
        layout.itemSize = CGSizeMake(158, 120);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.backgroundColor = self.view.backgroundColor;
        _collectionView.allowsMultipleSelection = NO;
        CGFloat padding = (SVScreenWidth() - 316) / 3;
        [_collectionView setContentInset:UIEdgeInsetsMake(20, padding, 140, padding)];
        [_collectionView registerClass:[SVConnectCell class] forCellWithReuseIdentifier:@"SVConnectCell"];
    }
    return _collectionView;
}

- (NSArray *)dataSource {
    if (!_dataSource) {
        NSArray *models = [SVFirebase getVNModels];
        if (models.count > 0) {
            SVServerModel *autoModel = [SVNTools randomServer];
            autoModel.name = @"Auto Server";
            autoModel.countryCode = @"auto";
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:models.count + 1];
            [array addObject:autoModel];
            [array addObjectsFromArray:models];
            _dataSource = [array copy];
            
            if (self.model && ([SVNManager sharedInstance].vnStatus == NEVPNStatusConnected)) {
                for (int i = 0; i < array.count; i++) {
                    SVServerModel *model = array[i];
                    if ([self.model.ip isEqualToString:model.ip] && [self.model.countryCode isEqualToString:model.countryCode]) {
                        self.selectIndex = i;
                        break;
                    }
                }
            }
        } else {
            _dataSource = @[];
        }
    }
    return _dataSource;
}

#pragma  mark - UINavigationControllerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    if ([manager isCanShowAdvertWithType:SVAdvertLocationTypeBack] && manager.backInterstitial) {
        [self displayAdvert];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - GADFullScreenContentDelegate
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    GADInterstitialAd *advert = (GADInterstitialAd *)ad;
    advert.paidEventHandler = ^(GADAdValue * _Nonnull value) {
        [[SVPosterManager sharedInstance] paidAdWithValue:value];
    };
}

//这里用将要消失
- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    self.backInterstitial = nil;
    [manager setupIsShow:NO type:SVAdvertLocationTypeBack];
    [self jumpVCWithAnimated:NO];
}

//3 点击
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    //保存数据库点击次数
    [[SVPosterManager sharedInstance] setupCckWithType:SVAdvertLocationTypeBack];
}

//1 将要展示
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    //保存数据库展示次数
    [[SVPosterManager sharedInstance] setupCswWithType:SVAdvertLocationTypeBack];
    [SVStatisticAnalysis saveEvent:@"show_bk" params:@{@"type": @"server"}];
}

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    [manager advertLogFailedWithType:SVAdvertLocationTypeBack error:error.localizedDescription];
    self.backInterstitial = nil;
    [self jumpVCWithAnimated:YES];
}

@end

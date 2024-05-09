//
//  SVBrowserVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVBrowserVC.h"
#import <WebKit/WebKit.h>
#import "UIView+SV.h"
#import "NSString+SV.h"
#import "SVTextField.h"
#import "SVPosterManager.h"

@interface SVBrowserCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;

@end

@implementation SVBrowserCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor colorWithHexString:@"#202329"];
        self.iconImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:self.iconImageView];
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.centerX.mas_equalTo(0);
            make.width.height.mas_equalTo(45);
        }];
        
        self.nameLabel = [UILabel lbText:@"name" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(0);
            make.centerX.mas_equalTo(0);
        }];
    }
    return self;
}

@end

typedef NS_ENUM(NSUInteger, SVBrowserStatus) {
    SVBrowserStatusHome = 0,
    SVBrowserStatusWeb,
};

@interface SVBrowserVC () <WKNavigationDelegate, WKUIDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, GADFullScreenContentDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) SVTextField *searchField;
@property (nonatomic, strong) UIButton *searchButton;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *homeButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, assign) SVBrowserStatus browserStatus;

@property (nonatomic, strong, nullable) GADInterstitialAd *backInterstitial;

@end

@implementation SVBrowserVC

- (void)didVC {
    [super didVC];
    [[SVPosterManager sharedInstance] enterBrowser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    self.browserStatus = SVBrowserStatusHome;
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    self.webView.configuration.preferences = [[WKPreferences alloc] init];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)setupUI {
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"#202329"];
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.searchField];
    [self.view addSubview:self.searchButton];
    [self.view addSubview:self.webView];
    [self.view addSubview:self.collectionView];
    
    UIView *barView = [[UIView alloc] init];
    barView.backgroundColor = [UIColor colorWithHexString:@"#323439"];
    barView.layer.cornerRadius = 10;
    barView.layer.masksToBounds = YES;
    [self.view addSubview:barView];
    
    [barView addSubview:self.backButton];
    [barView addSubview:self.homeButton];
    [barView addSubview:self.forwardButton];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(SVStatusHeight());
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(4);
    }];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.mas_bottom).offset(7);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-84);
        make.height.mas_equalTo(50);
    }];
    [self.searchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.searchField);
        make.right.mas_equalTo(-20);
        make.height.width.mas_equalTo(50);
    }];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchField.mas_bottom).offset(20);
        make.left.right.bottom.mas_equalTo(0);
    }];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchField.mas_bottom).offset(0);
        make.left.right.mas_equalTo(0);
        make.bottom.mas_equalTo(-54 - SVBottom());
    }];
    [barView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-SVBottom());
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(54);
    }];
    CGFloat buttonWidth = (SVScreenWidth() - 40) / 3;
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.top.bottom.mas_equalTo(0);
        make.width.mas_equalTo(buttonWidth);
    }];
    [self.homeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.top.bottom.mas_equalTo(0);
        make.width.mas_equalTo(buttonWidth);
    }];
    [self.forwardButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.top.bottom.mas_equalTo(0);
        make.width.mas_equalTo(buttonWidth);
    }];
}

- (void)loadWithUrlString:(NSString *)string {
    if (string.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:[string URLEncode]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)displayAdvert {
    [SVStatisticAnalysis saveEvent:@"scene_bk" params:@{@"type": @"browser"}];
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
    [self.navigationController popViewControllerAnimated:animated];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat progress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        [self.progressView setAlpha:1];
        [self.progressView setProgress:progress animated:YES];
        if (progress >= 1) {
            [UIView animateWithDuration:0.25 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0 animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
//    if (!navigationAction.targetFrame.isMainFrame) {
//        NSString *url = navigationAction.request.URL.absoluteString;
//        if (![url isEqualToString:@"about:blank"]) {
//            [self.webView loadRequest:navigationAction.request];
//        }
//    }
//    decisionHandler(WKNavigationActionPolicyAllow);
//}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSString *url = webView.URL.absoluteString;
    self.searchField.text = url;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    self.forwardButton.enabled = [self.webView canGoForward];
}

#pragma mark - Actions
- (void)backAction {
    //直接返回
    if (self.browserStatus != SVBrowserStatusHome && [self.webView canGoBack]) {
        [self.webView goBack];
        self.forwardButton.enabled = true;
    } else {
        if (self.collectionView.isHidden) {
            self.browserStatus = SVBrowserStatusHome;
        } else {
            [self displayAdvert];
        }
    }
}

- (void)forwardAction {
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (void)homeAction {
    self.browserStatus = SVBrowserStatusHome;
}

- (void)searchActoin {
    if (self.searchField.text.length == 0) return;
    if ([self.searchField isFirstResponder]) {
        [self.searchField resignFirstResponder];
    }
    self.browserStatus = SVBrowserStatusWeb;
    [self loadWithUrlString:self.searchField.text];
    [self.searchButton nImage:[UIImage imageNamed:@"refresh"] hImage:nil];
}

#pragma mark - UICollectionViewDelegate && UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SVBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVBrowserCell" forIndexPath:indexPath];
    NSDictionary *data = self.dataSource[indexPath.row];
    NSString *name = data[@"name"];
    cell.iconImageView.image = [UIImage imageNamed:name];
    cell.nameLabel.text = name;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = self.dataSource[indexPath.row];
    NSString *url = data[@"url"];
    self.searchField.text = url;
    [self searchActoin];
}

#pragma  mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self searchActoin];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.searchButton nImage:[UIImage imageNamed:@"web_search"] hImage:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.searchButton nImage:[UIImage imageNamed:@"refresh"] hImage:nil];
}

#pragma mark - Getters and Setter
- (void)setBrowserStatus:(SVBrowserStatus)browserStatus {
    if (_browserStatus != browserStatus) {
        _browserStatus = browserStatus;
        if (browserStatus == SVBrowserStatusHome) {
            self.searchField.text = @"";
            self.webView.hidden = YES;
            self.collectionView.hidden = NO;
            self.forwardButton.enabled = NO;
            self.progressView.hidden = YES;
            [self.searchButton nImage:[UIImage imageNamed:@"web_search"] hImage:nil];
        } else if (browserStatus == SVBrowserStatusWeb) {
            self.webView.hidden = NO;
            self.collectionView.hidden = YES;
            self.forwardButton.enabled = NO;
            self.progressView.hidden = NO;
            [self.searchButton nImage:[UIImage imageNamed:@"refresh"] hImage:nil];
        }
    }
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.tintColor = [UIColor colorWithHexString:@"#62B5E1"];
        _progressView.trackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
        _progressView.alpha = 0.0;
        _progressView.hidden = YES;
    }
    return _progressView;
}

- (SVTextField *)searchField {
    if (!_searchField) {
        _searchField = [[SVTextField alloc] init];
        _searchField.backgroundColor = [UIColor colorWithHexString:@"#323439"];
        _searchField.layer.cornerRadius = 10;
        _searchField.layer.masksToBounds = YES;
        _searchField.returnKeyType = UIReturnKeySearch;
        _searchField.delegate = self;
        [_searchField setPlaceholderText:@"Search an address..." font:[UIFont pFont:14] color:[[UIColor whiteColor] colorWithAlphaComponent:0.6]];
        _searchField.textRectInsets = UIEdgeInsetsMake(0, 10, 0, 38);
        _searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
        UIImage *clearImage = [UIImage imageNamed:@"web_delete"];
        UIButton *clearButton = [_searchField valueForKey:@"_clearButton"];
        [clearButton setImage:clearImage forState:UIControlStateNormal];
        
    }
    return _searchField;
}

- (UIButton *)searchButton {
    if (!_searchButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button nImage:[UIImage imageNamed:@"web_search"] hImage:nil];
        [button bgColor:[UIColor colorWithHexString:@"#323439"]];
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(searchActoin) forControlEvents:UIControlEventTouchUpInside];
        _searchButton = button;
    }
    return _searchButton;
}

- (WKWebView *)webView {
    if (_webView == nil) {
        _webView = [[WKWebView alloc] init];
        _webView.hidden = YES;
        _webView.backgroundColor = self.view.backgroundColor;
//        [_webView setUIDelegate:self];
        [_webView setNavigationDelegate:self];
    }
    return _webView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button nImage:[UIImage imageNamed:@"back"] hImage:nil];
        [button addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        _backButton = button;
    }
    return _backButton;
}

- (UIButton *)homeButton {
    if (!_homeButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button nImage:[UIImage imageNamed:@"web_home"] hImage:nil];
        [button addTarget:self action:@selector(homeAction) forControlEvents:UIControlEventTouchUpInside];
        _homeButton = button;
    }
    return _homeButton;
}

- (UIButton *)forwardButton {
    if (!_forwardButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button nImage:[UIImage imageNamed:@"forward"] hImage:nil];
        [button addTarget:self action:@selector(forwardAction) forControlEvents:UIControlEventTouchUpInside];
        _forwardButton = button;
    }
    return _forwardButton;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 25;
        layout.minimumInteritemSpacing = 0;
        CGFloat itemWidth = SVScreenWidth() / 3;
        layout.itemSize = CGSizeMake(itemWidth, 77);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.backgroundColor = self.view.backgroundColor;
        [_collectionView setContentInset:UIEdgeInsetsMake(20, 0, 0, 0)];
        [_collectionView registerClass:[SVBrowserCell class] forCellWithReuseIdentifier:@"SVBrowserCell"];
    }
    return _collectionView;
}

- (NSArray *)dataSource {
    if (!_dataSource) {
        _dataSource = @[
            @{@"name": @"Pinterest", @"url": @"https://www.pinterest.com/"},
            @{@"name": @"Instagram", @"url": @"https://www.instagram.com/"},
            @{@"name": @"Youtube", @"url": @"https://www.youtube.com/"},
            @{@"name": @"CNN", @"url": @"https://www.cnn.com/"},
            @{@"name": @"BBC", @"url": @"https://www.bbc.com/"},
            @{@"name": @"Amazon", @"url": @"https://www.amazon.com/"},
            @{@"name": @"Reddit", @"url": @"https://www.reddit.com/"},
            @{@"name": @"Fox News", @"url": @"https://www.foxnews.com/"},
            @{@"name": @"Google", @"url": @"https://www.google.com/"},
            @{@"name": @"Twitter", @"url": @"https://twitter.com/"},
            @{@"name": @"Yahoo", @"url": @"https://www.yahoo.com/"}];
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
    [SVStatisticAnalysis saveEvent:@"show_bk" params:@{@"type": @"browser"}];
}

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    [manager advertLogFailedWithType:SVAdvertLocationTypeBack error:error.localizedDescription];
    self.backInterstitial = nil;
    [self jumpVCWithAnimated:YES];
}

@end

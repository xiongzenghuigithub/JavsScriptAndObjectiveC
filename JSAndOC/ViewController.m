/**
 
    1. JavaScript <--> UIWebView <--> OC
    
    2. WebViewJavascriptBridge： 建立 JS与OC的桥连接
 
    3. WebViewJavascriptBridge基本用法：
 
        > OC 掉 JS 
            》通过bridge调用JS注册了的Handler，并接收JS Handler返回值
 
            eg.
                 id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
                 [_bridge callHandler:@"JS中注册号的Handler名字" data:data responseCallback:^(id response) {
                    NSLog(@"testJavascriptHandler responded: %@", response);
                 }];
 
        > JS 掉 OC
            》OC注册当JS Handler调用时候的回调Block（完成JS调用OC的代码）
            》JS注册一个Handler，返回OC结果值
            》JS代码中调用JS Handler
              
            eg.
                 [_bridge registerHandler:@"JS中注册号的Handler名字"
                 handler:^(id data, WVJBResponseCallback responseCallback)
                 {
                    NSLog(@"testObjcCallback called: %@", data);
                    responseCallback(@"Response from testObjcCallback");
                 }];

 
 
        > JS 掉 JS Handler
            》JS注册一个Handler，返回OC结果值
            》JS代码中调用JS Handler
 
        > OC 向 JS 发送数据
            eg. 在OC代码中：
 
                [_bridge send:@"A string sent from ObjC to JS" responseCallback:^(id response) {
                    NSLog(@"sendMessage got response: %@", response);
                }];
 
        > JS 向 OC 发送数据
            eg. 在JS代码中：
 
                [_bridge send:@"A string sent from ObjC after Webview has loaded."];
 
 */


#import "ViewController.h"

static NSString *const TestHandler = @"testHandler";
static NSString *const MyHandler = @"myHandler";

#import <WebKit/WebKit.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>

@interface ViewController ()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) WebViewJavascriptBridge *bridge;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initWebViewAndBridge];
}

//将 WebView与javaScript 建立联系
- (void)initWebViewAndBridge {
    
    if (_bridge) { return; }
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    
    //TODO: JS 向 OC 发送的数据 回调处理Block块
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback)
    {
        //1. 对JS发来的数据进行处理
        // ...
        
        //2. 反馈给JS的数据
        responseCallback(@"OC端的响应数据");
    }];
    
    [_bridge send:@"在WebView加载之前，OC向JS发送消息:" responseCallback:^(id responseData)
    {
        NSLog(@"objc got response! %@", responseData);
    }];
    
    //TODO: JS 调用 OC
    //1步：OC 注册 JS Handler被调用时候的 回调处理代码
    //2步：JS代码中调用注册了的 JS Handler
    [_bridge registerHandler:@"testObjcCallback"
                     handler:^(id data, WVJBResponseCallback responseCallback)
    {
        //1. 对JS发来的数据进行处理
        //...
        
        //2. 返回JS Handler结果值
        responseCallback(@"OC端的响应数据");
    }];
    
    //在控制器View上添加按钮
    [self renderButtons:_webView];
    
    //初始化 [webView loadHTMLString:] 显示html/JS代码
    [self loadExamplePage:_webView];
    
    // WebView没有加载之后，向JS发送消息
    [_bridge send:@"A string sent from ObjC after Webview has loaded."];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad\n");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad\n");
}

- (void)renderButtons:(UIWebView*)webView {
    
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    UIButton *messageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [messageButton setBackgroundColor:[UIColor redColor]];
    [messageButton setTitle:@"OC向JS发送消息" forState:UIControlStateNormal];
    [messageButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:messageButton aboveSubview:webView];
    messageButton.frame = CGRectMake(10, 414, 100, 35);
    messageButton.titleLabel.font = font;
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setBackgroundColor:[UIColor blackColor]];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(110, 414, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setBackgroundColor:[UIColor grayColor]];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    
    //TODO: 按钮被点击时，让webView对象执行reload方法
    [reloadButton addTarget:self action:@selector(reloadWebView) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(210, 414, 100, 35);
    reloadButton.titleLabel.font = font;
}

#pragma mark - webView加载html
- (void)loadExamplePage:(UIWebView*)webView {
    
    //1.
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    
    //2.
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    
    //3.
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    
    //4.
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

#pragma mark - btn action

//TODO: OC向JS发送消息，并设置回调响应代码
- (void)sendMessage:(id)sender {
    
    [_bridge send:@"A string sent from ObjC to JS" responseCallback:^(id response) {
        NSLog(@"OC got response from JS: %@", response);
    }];
}

//TODO: OC 调用 JS Handler
- (void)callHandler:(id)sender {    //OC调用JS代码中写好并注册了的Handler，完成JS代码操作
    
    NSString *jsHandlerName = nil;
    
    // 构造发送给JS的数据
    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
    
    //2. OC向JS发送数据，并在回调Block中获取到JS反馈回来的数据 ，调用JS Handler
    [_bridge callHandler:jsHandlerName data:data responseCallback:^(id response) {
        NSLog(@"调用JS Handler后，获取返回的数据: %@", response);
    }];
}

- (void)reloadWebView {
    [self.webView reload];
}

@end

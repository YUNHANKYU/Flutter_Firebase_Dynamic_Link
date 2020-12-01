import 'package:dynamic_link_example/detail.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

///
/// https://firebase.google.com/docs/dynamic-links/create-manually
/// 위 링크 살펴보고 파라미터 이해해서 사용하면 될 듯
///

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => HomePage(),
        '/detail': (BuildContext context) => DetailPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String _linkMessage;
  bool _isCreatingLink = false;
  String _testString = "Long Press로 카피하기";

  @override
  void initState() {
    super.initState();
    initDynamicLinks();
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        Navigator.pushNamed(context, deepLink.path);
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError: ' + e.message);
    });

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      Navigator.pushNamed(context, deepLink.path);
    }
  }

  Future<void> _createDynamicLink(bool short) async {
    setState(() {
      _isCreatingLink = true;
    });

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://seoultest.page.link',
      link: Uri.parse('https://asdf.page.link/helloworld'),
      androidParameters: AndroidParameters(
        packageName: 'com.may2nd.dynamic_link_example',
        minimumVersion: 0,
        fallbackUrl: Uri.parse('https://google.com/'),
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.may2nd.dynamic_link_example',
        minimumVersion: '0',

        /// 앱이 설치되지 않았을때 이동할 링크
        fallbackUrl: Uri.parse('https://google.com/'),
      ),

      /// 소셜 게시물에서의 동적 링크 미리보기 부분 설정
      socialMetaTagParameters: SocialMetaTagParameters(
        title: '동정 링크 미리보기 제목',
        description: '동적 링크 미리보기 설명부분! 여기에 적힌 내용이 설명으로 보여집니다.',
        imageUrl: Uri.parse(
            'https://firebasestorage.googleapis.com/v0/b/seoul-e91fb.appspot.com/o/%E1%84%8B%E1%85%AC%E1%84%87%E1%85%AE%E1%84%87%E1%85%A6%E1%86%AB%E1%84%8E%E1%85%B5.png?alt=media&token=d28a24d9-e73c-435c-b748-9fdd3966265f'),
      ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }

    setState(() {
      _linkMessage = url.toString();
      _isCreatingLink = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dynamic Links Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    onPressed: !_isCreatingLink
                        ? () => _createDynamicLink(false)
                        : null,
                    child: const Text('Long Link'),
                  ),
                  RaisedButton(
                    onPressed: !_isCreatingLink
                        ? () => _createDynamicLink(true)
                        : null,
                    child: const Text('Short Link'),
                  ),
                ],
              ),
              _linkMessage != null
                  ? Column(
                      children: [
                        InkWell(
                          child: Text(
                            _linkMessage,
                            style: const TextStyle(color: Colors.blue),
                          ),
                          onTap: () async {
                            await launch(_linkMessage);
                          },
                          onLongPress: () {
                            Clipboard.setData(
                                ClipboardData(text: _linkMessage));
                            print('Copied Link');
                          },
                        ),
                        Text(_testString)
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

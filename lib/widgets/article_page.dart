import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:infomatterapp/repositories/repositories.dart';
import 'package:infomatterapp/models/entry.dart';
import 'package:infomatterapp/blocs/blocs.dart';
import 'package:infomatterapp/widgets/widgets.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class ArticlePage extends StatefulWidget{
  final int type;
  final int index;
  final Entry entry;//1: full-text rss - from server;
  ArticlePage({Key key, this.entry, this.index, this.type}):
      super(key: key);
  @override
  State<ArticlePage> createState() {
    // TODO: implement createState
    return ArticlePageState();
  }
}

class ArticlePageState extends State<ArticlePage> {
  final _key = UniqueKey();


  ArticleBloc articleBloc;

  EntryBloc get entryBloc => BlocProvider.of<EntryBloc>(context);
  Entry get entry => widget.entry;
  int get _index => widget.index;
  int get _type => widget.type;


  String header;
  String colorCSS;

  @override
  void initState() {
    // TODO: implement initState
  if (entry.loadChoice == 1 && entry.form == 1) {
    articleBloc = ArticleBloc(
      entriesRepository: EntriesRepository(entriesApiClient: EntriesApiClient(httpClient: http.Client())),
    );
    articleBloc.dispatch(FetchArticle(entryId: entry.id));
    header = "<div style=\'font-size:18px;\'>" + "<h2>" +  entry.title + "</h2>" + "</div>" + "<div style=\'font-size:16px;\'>" + "<i>" + entry.sourceName + " / " + _timestamp(entry.pubDate) + "</i></div><br>";

  }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroudColor;
    Color fontColor;
    if (Theme.of(context).brightness == Brightness.light) {
      backgroudColor = Colors.white;
      fontColor = Colors.black;
      colorCSS = '<style>'
          'body {background-color: white; margin: 0; padding: 20;}'
          'h1   {color: black;}'
          'h2   {color: black;}'
          'h3   {color: black;}'
          'p    {color: black; font-size :18px; line-height:30px}'
          'a    {color:#F44336; text-decoration: none;}'
          'img  {max-width: 100%; width:auto; height: auto;}'
          'iframe {width:\"640\"; height:\"480\";}'
          '</style>';
    } else {
      backgroudColor = Colors.black;
      fontColor = Colors.white;
      colorCSS = '<style>'
          'body {background-color: black; margin: 0; padding: 20;}'
          'h1   {color: white;}'
          'h2   {color: white;}'
          'h3   {color: white;}'
          'p    {color: white; font-size :18px; line-height:30px}'
          'a    {color:#F44336; text-decoration: none;}'
          'img  {max-width: 100%; width:auto; height: auto;}'
          'iframe {width:\"640\"; height:\"480\";}'
          '</style>';
    }
    if (entry.loadChoice == 1 && entry.form == 1) {
      return BlocBuilder(
        bloc: articleBloc,
        builder: (BuildContext context, ArticleState state) {
          int _stackToView = 1;
          return Scaffold(
            appBar: articleAppBar(),
            body: SingleChildScrollView(
              key: PageStorageKey(entry.id),
              child: Center(
                child: state is ArticleLoaded ? HtmlWidget(
                  header + state.content,
                  webView: true,
                  webViewJs: true,
                  hyperlinkColor: Colors.blue,
                  textPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
//                  bodyPadding: EdgeInsets.all(15.0),
                  textStyle: TextStyle(
                    fontSize: 16.0,
                    color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                    height: 1.3,
                  ),
                )
                    : Container(),
              ),
            ),
          );

        },
      );
    } else {
      return Scaffold(
        appBar: articleAppBar(),
        body: WebViewPage(entry.link),
      );
    }
  }


  Widget articleAppBar() {
    if (_type == 1) {
      return AppBar(
        elevation: 0,
        actions: <Widget>[
          BlocBuilder(
            bloc: BlocProvider.of<EntryBloc>(context),
            builder: (BuildContext context, EntryState state) {
              if (entryBloc.entriesRepository.showStarred2 == true) {
                _onWidgetDidBuild(() {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('已收藏'),
                    action: SnackBarAction(
                      label: '添加到收藏夹',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AddBookmarkDialog(entryId: entryBloc.entriesRepository.lastStarId);
                            }
                        );
                      },
                    ),
                  ));
                  entryBloc.entriesRepository.showStarred2 = false;
                });
              }

              if (state is EntryLoaded)
                return IconButton(
                  icon: state.entries[_index].isStarring ? Icon(Icons.bookmark, color: Theme.of(context).accentColor,) : Icon(Icons.bookmark_border),
                  onPressed: () {
                    if (!state.entries[_index].isStarring) {
                      BlocProvider.of<EntryBloc>(context).dispatch(StarEntry(entryId: state.entries[_index].id, from: 1));
                    } else {
                      BlocProvider.of<EntryBloc>(context).dispatch(UnstarEntry(entryId: state.entries[_index].id, ));
                    }
                  },
                );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(entry.title + '\n' + entry.link);
            },
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () {
              _launchURL(context, entry.link);
            },
          )
        ],
      );
    } else if (_type == 2) {
      return AppBar(
        elevation: 0,
        actions: <Widget>[
          BlocBuilder(
            bloc: BlocProvider.of<SourceEntryBloc>(context),
            builder: (BuildContext context, SourceEntryState state) {
              if (BlocProvider.of<SourceEntryBloc>(context).entriesRepository.showStarred2 == true) {
                _onWidgetDidBuild(() {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('已收藏'),
                    action: SnackBarAction(
                      label: '添加到收藏夹',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AddBookmarkDialog(entryId: BlocProvider.of<SourceEntryBloc>(context).entriesRepository.lastStarId);
                            }
                        );
                      },
                    ),
                  ));
                  BlocProvider.of<SourceEntryBloc>(context).entriesRepository.showStarred2 = false;
                });
              }

              if (state is SourceEntryLoaded)
                return IconButton(
                  icon: state.entries[_index].isStarring ? Icon(Icons.bookmark, color: Theme.of(context).accentColor,) : Icon(Icons.bookmark_border),
                  onPressed: () {
                    if (!state.entries[_index].isStarring) {
                      BlocProvider.of<SourceEntryBloc>(context).dispatch(StarSourceEntry(entryId: state.entries[_index].id, from: 1),);
                    } else {
                      BlocProvider.of<SourceEntryBloc>(context).dispatch(UnstarSourceEntry(entryId: state.entries[_index].id));
                    }
                  },
                );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(entry.title + '\n' + entry.link);
            },
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () {
              _launchURL(context, entry.link);
            },
          )
        ],
      );
    } else if (_type == 3) {
      return AppBar(
        elevation: 0,
        actions: <Widget>[
          BlocBuilder(
            bloc: BlocProvider.of<BookmarkEntryBloc>(context),
            builder: (BuildContext context, BookmarkEntryState state) {
              if (BlocProvider.of<BookmarkEntryBloc>(context).entriesRepository.showStarred2 == true) {
                _onWidgetDidBuild(() {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('已收藏'),
                    action: SnackBarAction(
                      label: '添加到收藏夹',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AddBookmarkDialog(entryId: BlocProvider.of<BookmarkEntryBloc>(context).entriesRepository.lastStarId);
                            }
                        );
                      },
                    ),
                  ));
                  BlocProvider.of<BookmarkEntryBloc>(context).entriesRepository.showStarred2 = false;
                });
              }

              if (state is BookmarkEntryLoaded)
                return IconButton(
                  icon: state.entries[_index].isStarring ? Icon(Icons.bookmark, color: Theme.of(context).accentColor,) : Icon(Icons.bookmark_border),
                  onPressed: () {
                    if (!state.entries[_index].isStarring) {
                      BlocProvider.of<BookmarkEntryBloc>(context).dispatch(StarBookmarkEntry(entryId: state.entries[_index].id, from: 1));
                    } else {
                      BlocProvider.of<BookmarkEntryBloc>(context).dispatch(UnstarBookmarkEntry(entryId: state.entries[_index].id));
                    }
                  },
                );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(entry.title + '\n' + entry.link);
            },
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () {
              _launchURL(context, entry.link);
            },
          )
        ],
      );
    }

  }

  _launchURL(BuildContext context, String url) async {
    try {
      await launch(
        url,
        option: new CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: CustomTabsAnimation(
            startEnter: 'slide_up',
            startExit: 'android:anim/fade_out',
            endEnter: 'android:anim/fade_in',
            endExit: 'slide_down',
          ),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }

  }

  static String _timestamp(String timeUtcStr) {
    DateTime oldDate = DateTime.parse(timeUtcStr);
    String timestamp;
    DateTime currentDate = DateTime.now();
    Duration difference = currentDate.difference(oldDate);
    if (difference.inSeconds < 60) {
      timestamp = 'Now';
    } else if (difference.inMinutes < 60) {
      timestamp = '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      timestamp = '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      timestamp = '${difference.inDays}d';
    }
    return timestamp;
  }

  void _onWidgetDidBuild(Function callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

}

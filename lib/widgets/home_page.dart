import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:dynamic_theme/dynamic_theme.dart';

import 'package:infomatterapp/blocs/blocs.dart';
import 'package:infomatterapp/widgets/widgets.dart';
import 'package:infomatterapp/repositories/repositories.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';


class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  SourceFolderBloc get sourceFolderBloc => BlocProvider.of<SourceFolderBloc>(context);
  BookmarkFolderBloc get bookmarkFolderBloc => BlocProvider.of<BookmarkFolderBloc>(context);
  EntryBloc get entryBloc => BlocProvider.of<EntryBloc>(context);
  BookmarkEntryBloc get bookmarkEntryBloc => BlocProvider.of<BookmarkEntryBloc>(context);

  final _scrollController = ScrollController(); //home
  final _scrollController2 = ScrollController(); //drawer
  final _scrollController3 = ScrollController(); //bookmark
  Completer<void> _refreshCompleter = Completer<void>(); //home
  Completer<void> _refreshCompleter2 = Completer<void>(); //drawer of home
  Completer<void> _refreshCompleter3 = Completer<void>(); //bookmark
  Completer<void> _refreshCompleter4 = Completer<void>(); //drawer of bookmark

  final _scrollThreshold = 50.0;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey3 = new GlobalKey<RefreshIndicatorState>(); //bookmark
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int homeSourceId = -1;
  String homeSourceFolder = '';
  String bookmarkFolder = '';
  
  String appBarText = "全部";

  bool darkModeOn = false;

  bool hideNav = false;

  int _cIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    _scrollController.addListener(_onScroll);
    _scrollController3.addListener(_onScroll3);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // TODO: implement build
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: _cIndex == 0 || _cIndex == 1 ? IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () {
            _scaffoldKey.currentState.openDrawer();
          },
        ) : Container(),
        title: Text(appBarText),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MySearchDelegate(),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: hideNav == false ? 60.0 : 0.0,
          child: hideNav == false ? BottomNavigationBar(
            currentIndex: _cIndex,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                title: Text('首页'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                title: Text('收藏'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                title: Text('发现'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                title: Text('我的'),
              ),
            ],
            onTap: (index) {
              setState(() {
                if (index == _cIndex) {
                  print('same page');
                  if (index == 0) {
                    refresh();
                  } else if (index == 1) {
                    refresh3();
                  }
                }
                if (index == 0) {
                  if (homeSourceFolder == '')
                    appBarText = '全部';
                  else
                    appBarText = homeSourceFolder;
                } else if (index == 1) {
                  appBarText = '收藏';
                } else if (index == 2) {
                  appBarText = '发现';
                } else if (index == 3){
                  appBarText = '我的';
                }
                _cIndex = index;
              });
            },
          ) : Container(),
      ),
      body: _buildBody(),
      drawer: _buildDrawer(),
    );
  }


  Widget _buildBody() {
    if (_cIndex == 0) {
      return BlocBuilder(
        bloc: entryBloc,
        key: PageStorageKey('home'),
        builder: (BuildContext context, EntryState state) {
          if (entryBloc.entriesRepository.showStarred == true) {
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
              entryBloc.entriesRepository.showStarred = false;
            });
          }

          if (state is EntryUninitialized) {
            fetch();
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is EntryError) {
            _refreshCompleter?.complete();
            _refreshCompleter = Completer();

            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () {
                entryBloc.dispatch(Update(sourceId: homeSourceId, folder: homeSourceFolder));
                return _refreshCompleter.future;
              },
              child: ListView(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text('failed to fetch entries'),
                  )
                ],
              ),
            );
          }

//          if (state is EntryUpdated) {
//            _scrollController.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.easeOut);
//            _refreshCompleter?.complete();
//            _refreshCompleter = Completer();
//          }

          if (state is EntryLoaded) {
            _refreshCompleter?.complete();
            _refreshCompleter = Completer();

            if (state.entries.isEmpty) {
              return RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: () {
                  entryBloc.dispatch(Update(sourceId: homeSourceId, folder: homeSourceFolder));
                  return _refreshCompleter.future;
                },
                child: ListView(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Text('no entries'),
                    )
                  ],
                ),
              );
            }

            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () {
                entryBloc.dispatch(Update(sourceId: homeSourceId, folder: homeSourceFolder));
                return _refreshCompleter.future;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics (),
                itemBuilder: (BuildContext context, int index) {
                  return index >= state.entries.length
                      ? BottomLoader()
                      : EntryWidget(entry: state.entries[index], index: index, type: 1,);
                },
                itemCount: state.hasReachedMax
                    ? state.entries.length
                    : state.entries.length + 1,
                controller: _scrollController,
              ),
            );
          }
          return Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width,
          );
        },
      );
    } else if (_cIndex == 1) {
      return BlocBuilder(
        bloc: bookmarkEntryBloc,
        key: PageStorageKey('bookmark'),
        builder: (BuildContext context, BookmarkEntryState state) {
          if (bookmarkEntryBloc.entriesRepository.showStarred == true) {
            _onWidgetDidBuild(() {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text('已收藏'),
                action: SnackBarAction(
                  label: '添加到收藏夹',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AddBookmarkDialog(entryId: bookmarkEntryBloc.entriesRepository.lastStarId);
                        }
                    );
                  },
                ),
              ));
              bookmarkEntryBloc.entriesRepository.showStarred = false;
            });
          }

          if (state is BookmarkEntryUninitialized) {
            fetch3();
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is BookmarkEntryError) {
            _refreshCompleter3?.complete();
            _refreshCompleter3 = Completer();

            return RefreshIndicator(
              key: _refreshIndicatorKey3,
              onRefresh: () {
                bookmarkEntryBloc.dispatch(UpdateBookmarkEntry(sourceId: -2, folder: bookmarkFolder));
                return _refreshCompleter3.future;
              },
              child: ListView(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text('failed to fetch entries'),
                  )
                ],
              ),
            );
          }

//          if (state is EntryUpdated) {
//            _scrollController.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.easeOut);
//            _refreshCompleter3?.complete();
//            _refreshCompleter3 = Completer();
//          }

          if (state is BookmarkEntryLoaded) {
            _refreshCompleter3?.complete();
            _refreshCompleter3 = Completer();

            if (state.entries.isEmpty) {
              return RefreshIndicator(
                key: _refreshIndicatorKey3,
                onRefresh: () {
                  bookmarkEntryBloc.dispatch(UpdateBookmarkEntry(sourceId: -2, folder: bookmarkFolder));
                  return _refreshCompleter3.future;
                },
                child: ListView(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Text('no entries'),
                    )
                  ],
                ),
              );
            }

            return RefreshIndicator(
              key: _refreshIndicatorKey3,
              onRefresh: () {
                bookmarkEntryBloc.dispatch(UpdateBookmarkEntry(sourceId: -2, folder: bookmarkFolder));
                return _refreshCompleter3.future;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics (),
                itemBuilder: (BuildContext context, int index) {
                  return index >= state.entries.length
                      ? BottomLoader()
                      : EntryWidget(entry: state.entries[index], index: index, type: 3,);
                },
                itemCount: state.hasReachedMax
                    ? state.entries.length
                    : state.entries.length + 1,
                controller: _scrollController3,
              ),
            );
          }
          return Container();
        },
      );
    } else if (_cIndex == 2) {
      return SourceCatalog();
    } else if (_cIndex == 3) {
      return MePage();
    }
  }

  Widget _buildDrawer() {
    if (_cIndex == 0)
    return Drawer(
        child: BlocBuilder(
            bloc: sourceFolderBloc,
            builder: (BuildContext context, SourceFolderState state) {
              if (state is SourceFolderUninitialized) {
                sourceFolderBloc.dispatch(FetchSourceFolders());
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state is SourceFolderError) {
                _refreshCompleter2?.complete();
                _refreshCompleter2 = Completer();
                return RefreshIndicator(
                  onRefresh: () {
                    sourceFolderBloc.dispatch(FetchSourceFolders());
                    return _refreshCompleter2.future;
                  },
                  child: ListView(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Text('failed to fetch source folders'),
                      )
                    ],
                  ),
                );
              }

              if (state is SourceFolderLoaded) {
                print('SourceFolderLoaded');
                _refreshCompleter2?.complete();
                _refreshCompleter2 = Completer();
                return RefreshIndicator(
                  onRefresh: () {
                    sourceFolderBloc.dispatch(FetchSourceFolders());
                    return _refreshCompleter2.future;
                  },
                  child: ListView.builder(
                    key: PageStorageKey('SourceFolders'),
                    itemBuilder: (BuildContext context, int index) {
                       if (index == 0) {
                        return ListTile(
                          title: Text("订阅"),
                          trailing: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                                  appBar: AppBar(title: Text('发现'),),
                                  body: SourceCatalog(),
                                )));
                              }
                          ),
                        );
                      }
                      index = index - 1;
                      return GestureDetector(
                        child: ExpansionTile(
                            key: PageStorageKey(sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceFolderName),
                            title: sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceFolderName.length > 0 ?
                            Text(sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceFolderName) :
                            Text("全部"),
                            children: sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceList.map((source){
                              return Container(
                                padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                child: ListTile(
                                  leading: source.photo !=null ? Image.network(source.photo, width: 20, height: 20,) : Container(width: 20, height: 20,),
                                  title: Text(source.name),
                                  onTap: () {
                                    homeSourceId = source.id;
                                    Navigator.of(context).pop();
                                    refresh();
                                    setState(() {
                                      appBarText = source.name;
                                    });
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(context: context, builder: (BuildContext context) => SourceOption(
                                      sourceId: source.id, sourceName: source.name,));
                                  },
                                ),
                              );
                            }).toList()
                        ),
                        onTap: (){
                          homeSourceId = -1;
                          homeSourceFolder = sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceFolderName;
                          Navigator.of(context).pop();
                          refresh();
                          setState(() {
                            setState(() {
                              if (homeSourceFolder.length == 0) {
                                appBarText = '全部';
                              } else {
                                appBarText = homeSourceFolder;
                              }
                            });
                          });
                        },
                        onLongPress: () {
                          if (sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceFolderName != '') {
                            showModalBottomSheet(context: context, builder: (BuildContext context) => SourceFolderOption(
                              sourceFolderName: sourceFolderBloc.sourceFoldersRepository.sourceFolders[index].sourceFolderName,));
                          }
                        },
                      );
                    },
                    itemCount: sourceFolderBloc.sourceFoldersRepository.sourceFolders.length + 1,
                  ),
                );
              }
              return Container(
                width: 0,
                height: 0,
              );
            }
        )
    );
    else if (_cIndex == 1)
      return Drawer(
        child: BlocBuilder(
            bloc: bookmarkFolderBloc,
            builder: (BuildContext context, BookmarkFolderState state) {
              if (state is BookmarkFolderUninitialized) {
                bookmarkFolderBloc.dispatch(FetchBookmarkFolders());
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state is BookmarkFolderError) {
                _refreshCompleter4?.complete();
                _refreshCompleter4 = Completer();
                return RefreshIndicator(
                  onRefresh: () {
                    bookmarkFolderBloc.dispatch(FetchBookmarkFolders());
                    return _refreshCompleter4.future;
                  },
                  child: ListView(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Text('failed to fetch bookmark folders'),
                      )
                    ],
                  ),
                );
              }

              if (state is BookmarkFolderLoaded) {
                _refreshCompleter4?.complete();
                _refreshCompleter4 = Completer();
                return RefreshIndicator(
                  onRefresh: () {
                    bookmarkFolderBloc.dispatch(FetchBookmarkFolders());
                    return _refreshCompleter4.future;
                  },
                  child: ListView.builder(
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return ListTile(
                            title: Text('收藏夹'),
                          );
                        }
                        index = index - 1;
                        return ListTile(
                          leading: Icon(Icons.folder_open),
                          title: bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index].length > 0 ?
                            Text(bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index]):
                            Text('全部'),
                          onTap: () {
                            setState(() {
                              bookmarkFolder = bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index];
                              Navigator.of(context).pop();
                              refresh3();
                              if (bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index].length > 0) {
                                appBarText = bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index];
                              } else {
                                appBarText = '全部';
                              }
                            });

                          },
                          onLongPress: () {
                            if (bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index] != '') {
                              showModalBottomSheet(context: context, builder: (BuildContext context) => BookmarkFolderOption(
                                bookmarkFolderName: bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders[index],));
                            }
                          },
                        );
                      },
                      itemCount: bookmarkFolderBloc.bookmarkFoldersRepository.bookmarkFolders.length + 1,
                  )
                );
              }

            }
        ),
      );
  }

  @override
  void dispose() {
    entryBloc.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      fetch();
    }
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        hideNav = true;
      });
    }
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        hideNav = false;
      });
    }
  }

  void _onScroll3() {

    final maxScroll = _scrollController3.position.maxScrollExtent;
    final currentScroll = _scrollController3.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      fetch3();
    }
    if (_scrollController3.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        hideNav = true;
      });
    }
    if (_scrollController3.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        hideNav = false;
      });
    }
  }

  void fetch() {
    entryBloc.dispatch(Fetch(sourceId: homeSourceId, folder: homeSourceFolder));
  }

  void fetch3() {
    bookmarkEntryBloc.dispatch(FetchBookmarkEntry(sourceId: -2, folder: bookmarkFolder));
  }

  void refresh() {
    _scrollController.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.easeOut);
    _refreshIndicatorKey.currentState.show();
    entryBloc.dispatch(Update(sourceId: homeSourceId, folder: homeSourceFolder));
  }

  void refresh3() {
    _scrollController3.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.easeOut);
    _refreshIndicatorKey3.currentState.show();
    bookmarkEntryBloc.dispatch(UpdateBookmarkEntry(sourceId: -2, folder: bookmarkFolder));
  }

  void changeBrightness() {
    DynamicTheme.of(context).setBrightness(
        Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark);
  }

  void _onWidgetDidBuild(Function callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
}


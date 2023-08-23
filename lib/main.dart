import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer',
        home: MyHomePage(),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  late SharedPreferences prefs;
  WordPair currentWordPair = WordPair.random();
  List<WordPair> wordPairHistory = [];
  List<WordPair> favorites = [];

  MyAppState() {
    _initPrefs();
  }

  void _initPrefs() async {
    SharedPreferences.getInstance().then((prefs) {
      this.prefs = prefs;
      // prefs.clear();
      if (prefs.containsKey('currentWordPair')) {
        currentWordPair =
            _convertStringToWordPair(prefs.getString('currentWordPair')!);
      }
      if (prefs.containsKey('favorites')) {
        favorites = prefs
            .getStringList('favorites')!
            .map((str) => _convertStringToWordPair(str))
            .toList();
      } else {
        prefs.setStringList('favorites', []);
      }
      if (prefs.containsKey('wordPairHistory')) {
        wordPairHistory = prefs
            .getStringList('wordPairHistory')!
            .map((str) => _convertStringToWordPair(str))
            .toList();
      } else {
        prefs.setStringList('wordPairHistory', []);
      }
      notifyListeners();
    });
  }

  WordPair _convertStringToWordPair(String str) {
    var words = str.split(' ');
    return WordPair(words.first, words.last);
  }

  String _convertWordPairToString(WordPair wordPair) {
    return '${wordPair.first} ${wordPair.second}';
  }

  void getNext() {
    wordPairHistory.add(currentWordPair);
    if (wordPairHistory.length > 8) {
      wordPairHistory.removeAt(0);
    }
    currentWordPair = WordPair.random();
    prefs.setString(
        'currentWordPair', _convertWordPairToString(currentWordPair));
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(currentWordPair)) {
      removeFavorite(currentWordPair);
    } else {
      addFavorite(currentWordPair);
    }
  }

  addFavorite(WordPair wordPair) {
    var localFavorites = prefs.getStringList('favorites')!;
    favorites.add(wordPair);
    localFavorites.add(_convertWordPairToString(wordPair));
    prefs.setStringList('favorites', localFavorites);
    notifyListeners();
  }

  removeFavorite(WordPair wordPair) {
    var localFavorites = prefs.getStringList('favorites')!;
    favorites.remove(wordPair);
    localFavorites.remove(_convertWordPairToString(wordPair));
    prefs.setStringList('favorites', localFavorites);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: page,
                ),
              ),
            ),
            BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favorites',
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.currentWordPair;
    // var wordPairHistory = appState.wordPairHistory;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AnimatedWordsHistory(),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => appState.toggleFavorite(),
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => appState.getNext(),
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedWordsHistory extends StatefulWidget {
  @override
  State<AnimatedWordsHistory> createState() => _AnimatedWordsHistoryState();
}

class _AnimatedWordsHistoryState extends State<AnimatedWordsHistory> {
  final GlobalKey<AnimatedListState> _key = GlobalKey();
  final _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedList(
        key: _key,
        initialItemCount: _items.length,
        itemBuilder: (_, index, animation) {
          return Text(
            _items[index],
          );
        },
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regularStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.w200,
    );
    final boldStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.w800,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: AnimatedSize(
        duration: Duration(milliseconds: 250),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pair.first.toLowerCase(),
                style: regularStyle,
              ),
              Text(
                pair.second.toLowerCase(),
                style: boldStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    var textStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
    );

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text(
          'No favorites yet.',
          style: textStyle,
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'You have ${favorites.length} favorites:',
            style: textStyle,
          ),
        ),
        ListBody(
          children: favorites.map((favorite) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      appState.removeFavorite(favorite);
                    },
                    icon: Icon(Icons.delete_outline),
                  ),
                  Text(
                    favorite.asLowerCase,
                    style: textStyle,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

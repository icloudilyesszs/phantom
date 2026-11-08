import 'package:flutter/material.dart';

import '../models/track.dart';
import '../sources/music_source.dart';
import '../sources/sources.dart';
import '../widgets/track_tile.dart';

/// Recherche de morceaux dans les sources en ligne.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  MusicSource _source = Sources.searchable.first;
  List<Track> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _source.search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'La recherche a échoué. Vérifie ta connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = Sources.searchable;
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Titre, artiste…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _results = [];
                      _searched = false;
                    });
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (sources.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in sources)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(s.name),
                        selected: s.id == _source.id,
                        onSelected: (_) {
                          setState(() => _source = s);
                          _search();
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_results.isEmpty) {
      return Center(
        child: Text(_searched ? 'Aucun résultat' : 'Cherche un son 👻'),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) => TrackTile(list: _results, index: i),
    );
  }
}

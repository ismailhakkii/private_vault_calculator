import 'package:flutter/material.dart';
import 'package:private_vault/domain/entities/note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SecretNotesScreen extends StatefulWidget {
  const SecretNotesScreen({super.key});

  @override
  State<SecretNotesScreen> createState() => _SecretNotesScreenState();
}

class _SecretNotesScreenState extends State<SecretNotesScreen> {
  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  static const String _notesKey = 'secret_notes';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey);
      
      if (notesJson != null && notesJson.isNotEmpty) {
        // Convert JSON to Note objects
        final loadedNotes = notesJson.map((noteJson) {
          final Map<String, dynamic> noteMap = json.decode(noteJson);
          return Note.fromMap(noteMap);
        }).toList();
        
        setState(() {
          _notes = loadedNotes;
        });
      } else {
        // Add some initial demo notes if no notes exist
        final demoNotes = [
          Note.create(
            title: 'Önemli Bilgiler',
            content: 'Bu kısımda gizli tutmak istediğim önemli bilgilerimi saklayabilirim. Bankacılık şifreleri, güvenlik kodları ve diğer hassas bilgilerim burada güvende.',
            isFavorite: true,
          ),
          Note.create(
            title: 'Toplantı Notları',
            content: 'Bugünkü toplantıda konuşulan konular:\n- Yeni proje takvimi\n- Bütçe planlaması\n- Ekip görevlendirmeleri',
            isFavorite: false,
          ),
          Note.create(
            title: 'Alışveriş Listesi',
            content: 'Haftalık alışveriş listesi:\n✓ Süt\n✓ Ekmek\n✓ Yumurta\n✓ Meyve\n□ Sebze\n□ Et ürünleri',
            isFavorite: false,
          ),
        ];
        
        setState(() {
          _notes = demoNotes;
        });
        
        // Save demo notes
        await _saveNotes();
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      // If there's an error, still show some demo notes
      final demoNotes = [
        Note.create(
          title: 'Uygulama Kullanımı',
          content: 'Not eklemek için sağ alttaki + butonuna tıklayın.',
          isFavorite: true,
        ),
      ];
      
      setState(() {
        _notes = demoNotes;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = _notes.map((note) => json.encode(note.toMap())).toList();
      await prefs.setStringList(_notesKey, notesJson);
    } catch (e) {
      debugPrint('Error saving notes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notlar kaydedilirken bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return _notes;
    }
    return _notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addNewNote() {
    _showNoteEditor(null);
  }

  void _editNote(Note note) {
    _showNoteEditor(note);
  }

  void _showNoteEditor(Note? existingNote) {
    final titleController = TextEditingController(text: existingNote?.title ?? '');
    final contentController = TextEditingController(text: existingNote?.content ?? '');
    bool isFavorite = existingNote?.isFavorite ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingNote == null ? 'Yeni Not' : 'Notu Düzenle',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : null,
                        ),
                        onPressed: () {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'İçerik',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Create or update note
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          
                          if (title.isEmpty && content.isEmpty) {
                            Navigator.pop(context);
                            return;
                          }
                          
                          if (existingNote == null) {
                            // Create new note
                            final newNote = Note.create(
                              title: title.isEmpty ? 'Başlıksız Not' : title,
                              content: content,
                              isFavorite: isFavorite,
                            );
                            
                            // Add note to list and close sheet
                            Navigator.pop(context);
                            
                            // Update state with new note
                            this.setState(() {
                              _notes = [newNote, ..._notes];
                            });
                            await _saveNotes();
                          } else {
                            // Update existing note
                            final updatedNote = existingNote.copyWith(
                              title: title.isEmpty ? 'Başlıksız Not' : title,
                              content: content,
                              updatedAt: DateTime.now(),
                              isFavorite: isFavorite,
                            );
                            
                            // Close sheet
                            Navigator.pop(context);
                            
                            // Update state with updated note
                            this.setState(() {
                              final noteIndex = _notes.indexWhere((n) => n.id == existingNote.id);
                              if (noteIndex != -1) {
                                final updatedNotesList = List<Note>.from(_notes);
                                updatedNotesList[noteIndex] = updatedNote;
                                _notes = updatedNotesList;
                              }
                            });
                            await _saveNotes();
                          }
                        },
                        child: Text(existingNote == null ? 'Ekle' : 'Güncelle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Force a UI update after modal is closed
      setState(() {});
    });
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notu Sil'),
          content: const Text('Bu notu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                // Remove note from list
                setState(() {
                  _notes = _notes.where((n) => n.id != note.id).toList();
                });
                
                // Save updated notes
                _saveNotes();
                
                Navigator.pop(context);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterNotes,
              decoration: InputDecoration(
                hintText: 'Notları ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: theme.brightness == Brightness.dark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
              ),
            ),
          ),

          // Notes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredNotes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return _buildNoteItem(note);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewNote,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty;
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.note_alt_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Arama sonucu bulunamadı' : 'Henüz not eklenmemiş',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Farklı bir arama terimi deneyin'
                : 'Not eklemek için + butonuna tıklayın',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(Note note) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: note.isFavorite 
            ? BorderSide(color: theme.colorScheme.primary, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: note.isFavorite ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: note.isFavorite 
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            note.isFavorite ? Icons.star : Icons.note,
            color: note.isFavorite 
                ? theme.colorScheme.primary
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showNoteOptions(note);
          },
        ),
        onTap: () {
          _editNote(note);
        },
      ),
    );
  }

  void _showNoteOptions(Note note) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Not Seçenekleri',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(context);
                  _editNote(note);
                },
              ),
              ListTile(
                leading: Icon(
                  note.isFavorite ? Icons.star : Icons.star_border,
                  color: note.isFavorite ? Colors.amber : null,
                ),
                title: Text(
                  note.isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Toggle favorite status
                  setState(() {
                    final noteIndex = _notes.indexWhere((n) => n.id == note.id);
                    if (noteIndex != -1) {
                      final updatedNotes = List<Note>.from(_notes);
                      updatedNotes[noteIndex] = note.copyWith(
                        isFavorite: !note.isFavorite,
                        updatedAt: DateTime.now(),
                      );
                      _notes = updatedNotes;
                      _saveNotes();
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Sil', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNote(note);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
} 
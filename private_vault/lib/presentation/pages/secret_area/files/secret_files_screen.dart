import 'package:flutter/material.dart';
import 'package:private_vault/domain/entities/vault_file.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

class SecretFilesScreen extends StatefulWidget {
  const SecretFilesScreen({super.key});

  @override
  State<SecretFilesScreen> createState() => _SecretFilesScreenState();
}

class _SecretFilesScreenState extends State<SecretFilesScreen> {
  List<VaultFile> _files = [];
  bool _isLoading = false;
  bool _isGridView = true;
  String _currentFolder = '';
  static const String _filesKey = 'secret_files';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load files from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getStringList(_filesKey);
      
      if (filesJson != null && filesJson.isNotEmpty) {
        // Convert JSON to VaultFile objects
        final loadedFiles = filesJson.map((fileJson) {
          final Map<String, dynamic> fileMap = json.decode(fileJson);
          return VaultFile.fromMap(fileMap);
        }).toList();
        
        setState(() {
          _files = loadedFiles;
        });
      } else {
        // Add demo files if no files exist
        final demoFiles = [
          VaultFile(
            id: '1',
            name: 'Banka Bilgileri.pdf',
            path: '/documents/banka_bilgileri.pdf',
            type: FileType.document,
            size: 2500000,
            addedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          VaultFile(
            id: '2',
            name: 'Tatil Fotoğrafları.jpg',
            path: '/images/tatil.jpg',
            type: FileType.image,
            size: 5200000,
            addedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          VaultFile(
            id: '3',
            name: 'Gizli Proje.docx',
            path: '/documents/gizli_proje.docx',
            type: FileType.document,
            size: 1800000,
            addedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          VaultFile(
            id: '4',
            name: 'Aile Video.mp4',
            path: '/videos/aile_video.mp4',
            type: FileType.video,
            size: 15000000,
            addedAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ];

        setState(() {
          _files = demoFiles;
        });
        
        // Save demo files
        await _saveFiles();
      }
    } catch (e) {
      debugPrint('Error loading files: $e');
      
      // Show demo files in case of error
      final demoFile = VaultFile(
        id: '0',
        name: 'Hoş Geldiniz.txt',
        path: '/documents/welcome.txt',
        type: FileType.document,
        size: 1024,
        addedAt: DateTime.now(),
      );
      
      setState(() {
        _files = [demoFile];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = _files.map((file) => json.encode(file.toMap())).toList();
      await prefs.setStringList(_filesKey, filesJson);
    } catch (e) {
      debugPrint('Error saving files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosyalar kaydedilirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addNewFile() async {
    if (kIsWeb) {
      await _addNewFileWeb();
    } else {
      await _addNewFileMobile();
    }
  }
  
  Future<void> _addNewFileMobile() async {
    try {
      // Show file picker
      file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Get file details
        final platformFile = result.files.first;
        final fileName = platformFile.name;
        int fileSize = platformFile.size;
        String? devicePath = platformFile.path; // Dosyanın orijinal yolu alındı

        // Determine file type
        FileType fileType;
        String internalFilePath; // Bu, uygulamanın kendi içindeki yolu temsil edebilir (şu anki gibi)
        
        if (fileName.toLowerCase().endsWith('.jpg') || 
            fileName.toLowerCase().endsWith('.jpeg') || 
            fileName.toLowerCase().endsWith('.png')) {
          fileType = FileType.image;
          internalFilePath = '/images/$fileName';
        } else if (fileName.toLowerCase().endsWith('.mp4') || 
                  fileName.toLowerCase().endsWith('.avi') || 
                  fileName.toLowerCase().endsWith('.mov')) {
          fileType = FileType.video;
          internalFilePath = '/videos/$fileName';
        } else if (fileName.toLowerCase().endsWith('.pdf') || 
                  fileName.toLowerCase().endsWith('.doc') || 
                  fileName.toLowerCase().endsWith('.docx')) {
          fileType = FileType.document;
          internalFilePath = '/documents/$fileName';
        } else {
          fileType = FileType.other;
          internalFilePath = '/other/$fileName';
        }
        
        // Simulate encryption/processing
        await Future.delayed(const Duration(seconds: 1));
        
        // Create new file entity
        final newFile = VaultFile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: fileName,
          path: internalFilePath, // Bu path, uygulamanın iç mantığı için kullanılmaya devam edebilir
          type: fileType,
          size: fileSize,
          addedAt: DateTime.now(),
          thumbnailPath: devicePath, // Orijinal cihaz yolu thumbnailPath'e kaydedildi
        );
        
        // Add file to list
        setState(() {
          _files = [newFile, ..._files];
        });
        
        // Save updated files list
        await _saveFiles();
        
        // Dismiss loading
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newFile.name} başarıyla eklendi'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors that might occur
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog if shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya eklenirken bir hata oluştu: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // For web platform where we can't access the file path directly
  Future<void> _addNewFileWeb() async {
    try {
      // Show options for file type
      final fileType = await _showFileTypeSelector();
      if (fileType == null) return;
      
      // Generate a random file name and size
      final random = math.Random();
      String fileName;
      int fileSize = random.nextInt(10000000) + 500000; // 500KB to 10MB
      String filePath;
      
      switch (fileType) {
        case FileType.document:
          fileName = 'Belge_${DateTime.now().millisecondsSinceEpoch}.pdf';
          filePath = '/documents/$fileName';
          break;
        case FileType.image:
          fileName = 'Resim_${DateTime.now().millisecondsSinceEpoch}.jpg';
          filePath = '/images/$fileName';
          break;
        case FileType.video:
          fileName = 'Video_${DateTime.now().millisecondsSinceEpoch}.mp4';
          filePath = '/videos/$fileName';
          break;
        case FileType.other:
          fileName = 'Dosya_${DateTime.now().millisecondsSinceEpoch}';
          filePath = '/other/$fileName';
          break;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Simulate encryption/processing
      await Future.delayed(const Duration(seconds: 1));
      
      // Create new file entity
      final newFile = VaultFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: filePath,
        type: fileType,
        size: fileSize,
        addedAt: DateTime.now(),
      );
      
      // Add file to list
      setState(() {
        _files = [newFile, ..._files];
      });
      
      // Save updated files list
      await _saveFiles();
      
      // Dismiss loading
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newFile.name} başarıyla eklendi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog if shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya eklenirken bir hata oluştu: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteFile(VaultFile file) async {
    try {
      setState(() {
        _files = _files.where((f) => f.id != file.id).toList();
      });
      
      await _saveFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.name} başarıyla silindi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya silinirken bir hata oluştu: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<FileType?> _showFileTypeSelector() async {
    return showDialog<FileType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Dosya Türünü Seçin'),
        children: [
          _buildFileTypeOption(
            icon: Icons.insert_drive_file,
            title: 'Belge',
            color: Colors.orange.shade600,
            onTap: () => Navigator.pop(context, FileType.document),
          ),
          _buildFileTypeOption(
            icon: Icons.image,
            title: 'Resim',
            color: Colors.blue.shade600,
            onTap: () => Navigator.pop(context, FileType.image),
          ),
          _buildFileTypeOption(
            icon: Icons.video_file,
            title: 'Video',
            color: Colors.red.shade600,
            onTap: () => Navigator.pop(context, FileType.video),
          ),
          _buildFileTypeOption(
            icon: Icons.insert_drive_file,
            title: 'Diğer',
            color: Colors.grey.shade600,
            onTap: () => Navigator.pop(context, FileType.other),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFileTypeOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Header with controls
          _buildHeader(),
          
          // Content
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty 
                    ? _buildEmptyState() 
                    : _isGridView 
                        ? _buildGridView() 
                        : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewFile,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Dosya Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Path display
          Text(
            _currentFolder.isEmpty ? 'Kök Klasör' : _currentFolder,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // File count
              Text(
                '${_files.length} dosya',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // View toggle
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                tooltip: _isGridView ? 'Liste görünümü' : 'Izgara görünümü',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz dosya yok',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Dosya eklemek için + butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildFileGridItem(file);
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildFileListItem(file);
      },
    );
  }

  Widget _buildFileIcon(VaultFile file, {double size = 48.0}) {
    IconData iconData;
    Color iconColor = Theme.of(context).colorScheme.primary;

    switch (file.type) {
      case FileType.image:
        iconData = Icons.image;
        iconColor = Colors.orange.shade700;
        break;
      case FileType.video:
        iconData = Icons.movie;
        iconColor = Colors.red.shade700;
        break;
      case FileType.document:
        if (file.name.toLowerCase().endsWith('.pdf')) {
          iconData = Icons.picture_as_pdf;
          iconColor = Colors.red.shade900;
        } else if (file.name.toLowerCase().endsWith('.doc') || file.name.toLowerCase().endsWith('.docx')) {
          iconData = Icons.description; // Word için daha spesifik bir ikon bulunabilir
          iconColor = Colors.blue.shade700;
        } else if (file.name.toLowerCase().endsWith('.txt')) {
          iconData = Icons.article;
           iconColor = Colors.grey.shade700;
        } else {
          iconData = Icons.insert_drive_file;
        }
        break;
      case FileType.other:
      default:
        iconData = Icons.settings_ethernet_rounded; // Genel bir ikon, rounded versiyonu denenebilir
        iconColor = Colors.teal; // Farklı bir renk
        break;
    }
    return Icon(iconData, size: size, color: iconColor);
  }

  Widget _buildFileGridItem(VaultFile file) {
    final theme = Theme.of(context);
    final bool isImage = file.type == FileType.image && file.thumbnailPath != null && file.thumbnailPath!.isNotEmpty;
    final bool canLoadAsFile = !kIsWeb && (file.thumbnailPath?.startsWith('/') ?? false);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFileActions(file),
        onLongPress: () => _showFileActions(file),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                child: isImage && canLoadAsFile
                    ? Image.file(
                        File(file.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFileIcon(file, size: 40);
                        },
                      )
                    : _buildFileIcon(file, size: 40),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      file.sizeDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      'Eklenme: ${file.addedAt.day}.${file.addedAt.month}.${file.addedAt.year}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListItem(VaultFile file) {
    final theme = Theme.of(context);
    final bool isImage = file.type == FileType.image && file.thumbnailPath != null && file.thumbnailPath!.isNotEmpty;
    final bool canLoadAsFile = !kIsWeb && (file.thumbnailPath?.startsWith('/') ?? false);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () => _showFileActions(file),
        leading: SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              child: isImage && canLoadAsFile
                  ? Image.file(
                      File(file.thumbnailPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFileIcon(file, size: 24);
                      },
                    )
                  : _buildFileIcon(file, size: 24),
            ),
          ),
        ),
        title: Text(file.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${file.typeDisplay} • ${file.sizeDisplay}'),
            Text('Eklenme: ${file.addedAt.day}.${file.addedAt.month}.${file.addedAt.year}', style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showFileActions(file),
        ),
      ),
    );
  }
  
  void _viewFile(VaultFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: _getFileColor(file.type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(file.type),
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text('Dosya Türü: ${file.typeDisplay}'),
            Text('Boyut: ${file.sizeDisplay}'),
            Text('Eklenme Tarihi: ${_formatDate(file.addedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFileActions(VaultFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Görüntüle'),
                onTap: () {
                  Navigator.pop(context);
                  _viewFile(file);
                },
              ),
              if (!kIsWeb && file.thumbnailPath != null && file.thumbnailPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Paylaş'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final xFile = XFile(file.thumbnailPath!);
                      await Share.shareXFiles([xFile], text: file.name);
                    } catch (e) {
                      debugPrint('Paylaşma hatası: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dosya paylaşılamadı: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Yeniden Adlandır'),
                onTap: () {
                  Navigator.pop(context);
                  _renameFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Sil', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteFile(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _renameFile(VaultFile file) {
    final textController = TextEditingController(text: file.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosyayı Yeniden Adlandır'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Dosya Adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isEmpty) return;
              
              final fileIndex = _files.indexWhere((f) => f.id == file.id);
              if (fileIndex != -1) {
                // Get file extension
                final oldNameParts = file.name.split('.');
                final extension = oldNameParts.length > 1 ? '.${oldNameParts.last}' : '';
                
                // Make sure the new name has the same extension
                final newNameWithExtension = newName.endsWith(extension) ? newName : '$newName$extension';
                
                // Update file
                final updatedFile = file.copyWith(name: newNameWithExtension);
                setState(() {
                  final updatedFiles = List<VaultFile>.from(_files);
                  updatedFiles[fileIndex] = updatedFile;
                  _files = updatedFiles;
                });
                
                // Save updated files
                await _saveFiles();
              }
              
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteFile(VaultFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosyayı Sil'),
        content: Text('${file.name} dosyasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.document:
        return Icons.insert_drive_file;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(FileType type) {
    switch (type) {
      case FileType.image:
        return Colors.blue;
      case FileType.video:
        return Colors.red;
      case FileType.document:
        return Colors.orange;
      case FileType.other:
        return Colors.grey;
    }
  }
} 
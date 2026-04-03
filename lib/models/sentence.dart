/// ========================================
/// 绘本句子模型
/// 对应后端 sentences 表
/// ========================================
class Sentence {
  final String id;
  final String pageId;
  final int sentenceOrder;
  final String en;
  final String zh;
  final String? audioUrl;

  const Sentence({
    required this.id,
    required this.pageId,
    required this.sentenceOrder,
    required this.en,
    required this.zh,
    this.audioUrl,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      sentenceOrder: json['sentence_order'] as int? ?? 1,
      en: json['en'] as String? ?? '',
      zh: json['zh'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'sentence_order': sentenceOrder,
      'en': en,
      'zh': zh,
      'audio_url': audioUrl,
    };
  }

  /// 复制并修改
  Sentence copyWith({
    String? id,
    String? pageId,
    int? sentenceOrder,
    String? en,
    String? zh,
    String? audioUrl,
  }) {
    return Sentence(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      sentenceOrder: sentenceOrder ?? this.sentenceOrder,
      en: en ?? this.en,
      zh: zh ?? this.zh,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

/// ========================================
/// 绘本页面模型
/// 对应后端 book_pages 表
/// ========================================
class BookPage {
  final String id;
  final String bookId;
  final int pageNumber;
  final String? imageUrl;
  final List<Sentence> sentences;
  final DateTime? createdAt;

  const BookPage({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    this.imageUrl,
    this.sentences = const [],
    this.createdAt,
  });

  /// 复制并修改
  BookPage copyWith({
    String? id,
    String? bookId,
    int? pageNumber,
    String? imageUrl,
    List<Sentence>? sentences,
    DateTime? createdAt,
  }) {
    return BookPage(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      sentences: sentences ?? this.sentences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookPage.fromJson(Map<String, dynamic> json) {
    final sentences = <Sentence>[];
    if (json['sentences'] is List) {
      for (final s in json['sentences'] as List) {
        sentences.add(Sentence.fromJson(s as Map<String, dynamic>));
      }
    }

    return BookPage(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      pageNumber: json['page_number'] as int? ?? 1,
      imageUrl: json['image_url'] as String?,
      sentences: sentences,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'page_number': pageNumber,
      'image_url': imageUrl,
      'sentences': sentences.map((s) => s.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// ========================================
/// 绘本详情模型
/// 对应后端 books 表（包含页面列表）
/// ========================================
class BookDetail {
  final String id;
  final String userId;
  final String title;
  final int level;
  final int progress;
  final String? coverImage;
  final bool isNew;
  final bool hasAudio;
  final String status;
  final List<BookPage> pages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookDetail({
    required this.id,
    required this.userId,
    required this.title,
    this.level = 1,
    this.progress = 0,
    this.coverImage,
    this.isNew = false,
    this.hasAudio = false,
    this.status = 'draft',
    this.pages = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// 总页数
  int get totalPages => pages.length;

  /// 复制并修改部分字段
  BookDetail copyWith({
    String? id,
    String? userId,
    String? title,
    int? level,
    int? progress,
    String? coverImage,
    bool? isNew,
    bool? hasAudio,
    String? status,
    List<BookPage>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookDetail(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      level: level ?? this.level,
      progress: progress ?? this.progress,
      coverImage: coverImage ?? this.coverImage,
      isNew: isNew ?? this.isNew,
      hasAudio: hasAudio ?? this.hasAudio,
      status: status ?? this.status,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    final pages = <BookPage>[];
    if (json['pages'] is List) {
      for (final p in json['pages'] as List) {
        pages.add(BookPage.fromJson(p as Map<String, dynamic>));
      }
    }

    return BookDetail(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '未命名绘本',
      level: json['level'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      coverImage: json['cover_image'] as String?,
      isNew: json['is_new'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      pages: pages,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'level': level,
      'progress': progress,
      'cover_image': coverImage,
      'is_new': isNew,
      'has_audio': hasAudio,
      'status': status,
      'pages': pages.map((p) => p.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
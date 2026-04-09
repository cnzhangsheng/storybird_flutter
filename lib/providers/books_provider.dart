import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/core/utils/logger.dart';
import 'package:storycoe_flutter/models/book.dart';
import 'package:storycoe_flutter/services/api_service.dart';
import 'package:uuid/uuid.dart';

/// Internal log function using AppLogger
void _log(String message, [dynamic data]) {
  if (kDebugMode) {
    final logMsg = data != null ? '$message: $data' : message;
    log('[BooksProvider] $logMsg');
  }
}

/// Books state
class BooksState {
  final List<Book> myBooks;  // 用户自己的绘本
  final List<Book> likedBooks;  // 喜欢的他人公开绘本
  final bool isLoading;
  final String? error;

  const BooksState({
    this.myBooks = const [],
    this.likedBooks = const [],
    this.isLoading = false,
    this.error,
  });

  /// 所有书籍（用于兼容旧逻辑）
  List<Book> get allBooks => [...myBooks, ...likedBooks];

  BooksState copyWith({
    List<Book>? myBooks,
    List<Book>? likedBooks,
    bool? isLoading,
    String? error,
  }) {
    return BooksState(
      myBooks: myBooks ?? this.myBooks,
      likedBooks: likedBooks ?? this.likedBooks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Books notifier
class BooksNotifier extends StateNotifier<BooksState> {
  BooksNotifier() : super(const BooksState()) {
    // Load books on init
    loadBooks();
  }

  /// Load books from API
  Future<void> loadBooks() async {
    _log('开始加载绘本架');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await booksApi.listBooks();
      _log('API 响应', response);

      // 解析我的绘本
      final myBooksList = response['my_books'] as List? ?? [];
      _log('我的绘本数量: ${myBooksList.length}');
      final myBooks = myBooksList
          .map((json) {
            _log('解析我的绘本: ${json['id']} - ${json['title']}');
            return Book.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      // 解析喜欢的绘本
      final likedBooksList = response['liked_books'] as List? ?? [];
      _log('喜欢的绘本数量: ${likedBooksList.length}');
      final likedBooks = likedBooksList
          .map((json) {
            _log('解析喜欢的绘本: ${json['id']} - ${json['title']}');
            return Book.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      _log('加载完成，我的绘本 ${myBooks.length} 本，喜欢的绘本 ${likedBooks.length} 本');
      state = BooksState(myBooks: myBooks, likedBooks: likedBooks, isLoading: false);
    } catch (e, stackTrace) {
      _log('加载失败: $e');
      _log('堆栈: $stackTrace');
      state = BooksState(myBooks: [], likedBooks: [], isLoading: false, error: '加载绘本失败: $e');
    }
  }

  /// Add a new book
  Future<Book?> addBook({
    required String title,
    String? image,
    int level = 1,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await booksApi.createBook(
        title: title,
        level: level,
        coverImage: image,
      );
      final book = Book.fromJson(response);
      state = state.copyWith(
        myBooks: [book, ...state.myBooks],
        isLoading: false,
      );
      return book;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update a book
  Future<bool> updateBook(Book updatedBook) async {
    try {
      await booksApi.updateBook(
        updatedBook.id,
        title: updatedBook.title,
        level: updatedBook.level,
        progress: updatedBook.progress,
        coverImage: updatedBook.image,
        isNew: updatedBook.isNew,
        hasAudio: updatedBook.hasAudio,
        shareType: updatedBook.shareType,
      );
      // 更新 myBooks 或 likedBooks
      final myBookIndex = state.myBooks.indexWhere((b) => b.id == updatedBook.id);
      final likedBookIndex = state.likedBooks.indexWhere((b) => b.id == updatedBook.id);

      if (myBookIndex != -1) {
        final updatedMyBooks = List<Book>.from(state.myBooks);
        updatedMyBooks[myBookIndex] = updatedBook;
        state = state.copyWith(myBooks: updatedMyBooks);
      } else if (likedBookIndex != -1) {
        final updatedLikedBooks = List<Book>.from(state.likedBooks);
        updatedLikedBooks[likedBookIndex] = updatedBook;
        state = state.copyWith(likedBooks: updatedLikedBooks);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove a book
  Future<bool> removeBook(String bookId) async {
    try {
      await booksApi.deleteBook(bookId);
      state = state.copyWith(
        myBooks: state.myBooks.where((book) => book.id != bookId).toList(),
        likedBooks: state.likedBooks.where((book) => book.id != bookId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Create a new book (for development mode without API)
  Book createBook({
    required String title,
    String? image,
    int level = 1,
    String userId = '',
  }) {
    final book = Book(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      level: level,
      progress: 0,
      image: image,
      isNew: true,
    );
    state = state.copyWith(myBooks: [book, ...state.myBooks]);
    return book;
  }

  /// Update progress
  Future<void> updateProgress(String bookId, int progress) async {
    final book = state.allBooks.firstWhere((b) => b.id == bookId);
    final updatedBook = book.copyWith(progress: progress);
    await updateBook(updatedBook);
  }

  /// Generate book from images
  Future<String?> generateBook({
    String? title,
    required List<String> images,
    int level = 1,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await booksApi.generateBook(
        title: title,
        images: images,
        level: level,
      );
      // Reload books to get the new one
      await loadBooks();
      return response['book_id'] as String?;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }
}

/// Books provider
final booksProvider =
    StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  return BooksNotifier();
});

/// Convenience providers
final myBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksProvider).myBooks;
});

final likedBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksProvider).likedBooks;
});

/// 所有书籍（兼容旧逻辑）
final booksListProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksProvider).allBooks;
});

final booksLoadingProvider = Provider<bool>((ref) {
  return ref.watch(booksProvider).isLoading;
});

final bookByIdProvider = Provider.family<Book?, String>((ref, bookId) {
  return ref.watch(booksProvider).allBooks.firstWhere(
        (book) => book.id == bookId,
        orElse: () => throw StateError('Book not found: $bookId'),
      );
});
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category.dart';
import '../../../wallets/data/repositories/wallet_repository.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../domain/models/transaction_entry.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    ref.watch(supabaseClientProvider),
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class TransactionRepository {
  TransactionRepository(this._client, {bool useMockData = false})
    : _useMockData = useMockData || !AppConstants.hasSupabaseConfig;

  final SupabaseClient _client;
  final bool _useMockData;

  static List<TransactionEntry> get mockTransactions => _mockTransactions;

  static final List<TransactionEntry> _mockTransactions = [
    _mockTransaction(
      id: 'mock-1',
      amount: 45000,
      note: 'Cà phê Cộng',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'cafe',
      day: 19,
      hour: 8,
      minute: 15,
    ),
    _mockTransaction(
      id: 'mock-2',
      amount: 58000,
      note: 'Cơm trưa văn phòng',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'lunch',
      day: 19,
      hour: 12,
      minute: 5,
    ),
    _mockTransaction(
      id: 'mock-3',
      amount: 360000,
      note: 'Shopping',
      categoryId: 'mock-cat-shopping',
      categoryName: 'Mua sắm',
      categoryColor: '#E45CA6',
      imageName: 'shopping',
      day: DateTime.now().subtract(const Duration(days: 1)).day,
      hour: 19,
      minute: 5,
      isImportant: true,
    ),
    _mockTransaction(
      id: 'mock-4',
      amount: 260000,
      note: 'Ride',
      categoryId: 'mock-cat-transport',
      categoryName: 'Đi lại',
      categoryColor: '#2563EB',
      imageName: 'transport',
      day: 8,
      hour: 18,
      minute: 20,
    ),
    _mockTransaction(
      id: 'mock-5',
      amount: 320000,
      note: 'Ăn tối với Linh',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'lunch',
      day: 15,
      hour: 20,
      minute: 10,
    ),
    _mockTransaction(
      id: 'mock-6',
      amount: 38000,
      note: 'Ăn sáng cùng team',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'cafe',
      day: 9,
      hour: 8,
      minute: 2,
    ),
    _mockTransaction(
      id: 'mock-7',
      amount: 690000,
      note: 'Skin care',
      categoryId: 'mock-cat-shopping',
      categoryName: 'Mua sắm',
      categoryColor: '#E45CA6',
      imageName: 'shopping',
      day: 15,
      hour: 20,
      minute: 15,
      isImportant: true,
    ),
    _mockTransaction(
      id: 'mock-8',
      amount: 235000,
      note: 'Weekend market',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'market',
      day: 8,
      hour: 10,
      minute: 25,
    ),
    _mockTransaction(
      id: 'mock-9',
      amount: 310000,
      note: 'Grocery',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'market',
      day: 7,
      hour: 18,
      minute: 45,
    ),
    _mockTransaction(
      id: 'mock-10',
      amount: 260000,
      note: 'Taxi home',
      categoryId: 'mock-cat-transport',
      categoryName: 'Đi lại',
      categoryColor: '#2563EB',
      imageName: 'transport',
      day: 20,
      hour: 21,
      minute: 5,
    ),
    _mockTransaction(
      id: 'mock-11',
      amount: 275000,
      note: 'Dinner',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'lunch',
      day: 6,
      hour: 19,
      minute: 35,
    ),
    _mockTransaction(
      id: 'mock-12',
      amount: 400000,
      note: 'Stationery',
      categoryId: 'mock-cat-shopping',
      categoryName: 'Mua sắm',
      categoryColor: '#E45CA6',
      imageName: 'shopping',
      day: 26,
      hour: 14,
      minute: 10,
    ),
    _mockTransaction(
      id: 'mock-13',
      amount: 220000,
      note: 'Metro',
      categoryId: 'mock-cat-transport',
      categoryName: 'Đi lại',
      categoryColor: '#2563EB',
      imageName: 'transport',
      day: 27,
      hour: 8,
      minute: 30,
    ),
    _mockTransaction(
      id: 'mock-14',
      amount: 385000,
      note: 'Market',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'market',
      day: 5,
      hour: 17,
      minute: 30,
    ),
    _mockTransaction(
      id: 'mock-15',
      amount: 8250000,
      type: TransactionType.income,
      note: 'Salary',
      categoryId: 'mock-cat-salary',
      categoryName: 'Lương',
      categoryColor: '#44D884',
      imageName: 'salary',
      day: 30,
      hour: 9,
    ),
    _mockTransaction(
      id: 'mock-16',
      amount: 150000,
      note: 'Lunch set',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'lunch',
      day: 4,
      hour: 12,
      minute: 5,
    ),
    _mockTransaction(
      id: 'mock-17',
      amount: 240000,
      note: 'Airport ride',
      categoryId: 'mock-cat-transport',
      categoryName: 'Đi lại',
      categoryColor: '#2563EB',
      imageName: 'transport',
      day: 2,
      hour: 7,
    ),
    _mockTransaction(
      id: 'mock-18',
      amount: 124000,
      note: 'Coffee beans',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'cafe',
      day: 3,
      hour: 16,
      minute: 40,
    ),
    _mockTransaction(
      id: 'mock-19',
      amount: 40000,
      note: 'Bánh mì',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'lunch',
      day: 2,
      hour: 7,
      minute: 45,
    ),
    _mockTransaction(
      id: 'mock-20',
      amount: 160000,
      note: 'Trà sữa',
      categoryId: 'mock-cat-food',
      categoryName: 'Ăn uống',
      categoryColor: '#F6B24D',
      imageName: 'cafe',
      day: 1,
      hour: 15,
      minute: 25,
    ),
  ];

  static TransactionEntry _mockTransaction({
    required String id,
    required double amount,
    required String note,
    required String categoryId,
    required String categoryName,
    required String categoryColor,
    required String imageName,
    required int day,
    int hour = 12,
    int minute = 0,
    TransactionType type = TransactionType.expense,
    bool isImportant = false,
  }) {
    return TransactionEntry(
      id: id,
      amount: amount,
      type: type,
      note: note,
      imagePath: 'asset://assets/demo_transactions/$imageName.png',
      transactionDate: _mockDate(day, hour, minute),
      walletId: 'w1',
      walletName: 'Cash Wallet',
      walletColor: '#44D884',
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      isImportant: isImportant,
    );
  }

  static DateTime _mockDate(int day, int hour, int minute) {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final safeDay = day.clamp(1, lastDay).toInt();
    return DateTime(now.year, now.month, safeDay, hour, minute);
  }

  static String _mockImagePathForCategory(
    String categoryId,
    TransactionType type,
  ) {
    final imageName = switch (categoryId) {
      'mock-cat-food' => 'market',
      'mock-cat-transport' => 'transport',
      'mock-cat-shopping' => 'shopping',
      'mock-cat-salary' => 'salary',
      _ when type == TransactionType.income => 'salary',
      _ => 'market',
    };
    return 'asset://assets/demo_transactions/$imageName.png';
  }

  Future<void> clearMockUserData() async {
    if (!_useMockData) return;
    for (final transaction in List<TransactionEntry>.from(_mockTransactions)) {
      final imagePath = transaction.imagePath;
      if (imagePath == null ||
          imagePath.startsWith('http') ||
          imagePath.startsWith('asset://')) {
        continue;
      }
      final image = File(imagePath);
      if (await image.exists()) await image.delete();
    }
    _mockTransactions.clear();
  }

  String get _userId {
    if (_useMockData) {
      return 'mock-user-id';
    }
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return uid;
  }

  Future<List<TransactionEntry>> fetchTransactionsForMonth(
    DateTime month, {
    String? walletId,
    String? categoryId,
  }) async {
    if (_useMockData) {
      final results = _mockTransactions.where((t) {
        final sameMonth =
            t.transactionDate.year == month.year &&
            t.transactionDate.month == month.month;
        final matchWallet = walletId == null || t.walletId == walletId;
        final matchCat = categoryId == null || t.categoryId == categoryId;
        return sameMonth && matchWallet && matchCat;
      }).toList();

      // Sort by importance first, then by date
      results.sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        return b.transactionDate.compareTo(a.transactionDate);
      });
      return results;
    }
    try {
      final uid = _userId;

      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);

      var query = _baseSelect()
          .eq('user_id', uid)
          .gte('transaction_date', start.toUtc().toIso8601String())
          .lt('transaction_date', end.toUtc().toIso8601String());

      if (walletId != null) {
        query = query.eq('wallet_id', walletId);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query
          .order('is_important', ascending: false)
          .order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<List<TransactionEntry>> fetchStarredTransactions() async {
    if (_useMockData) {
      return _mockTransactions.where((t) => t.isImportant).toList()
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    }
    try {
      final uid = _userId;

      // Use the existing _baseSelect() helper to get all required columns
      final rows = await _baseSelect()
          .eq('user_id', uid)
          .eq('is_important', true)
          .order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi truy vấn danh sách yêu thích', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối khi lấy danh sách yêu thích', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<List<TransactionEntry>> searchTransactions(String queryText) async {
    final normalizedQuery = queryText.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    if (_useMockData) {
      return _filterTransactions(_mockTransactions, normalizedQuery);
    }
    try {
      final uid = _userId;

      final rows = await _baseSelect()
          .eq('user_id', uid)
          .order('transaction_date', ascending: false);

      return _filterTransactions(_mapList(rows), normalizedQuery);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Search transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Search transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<List<TransactionEntry>> fetchTransactionsForDay(
    DateTime day, {
    String? walletId,
    String? categoryId,
  }) async {
    if (_useMockData) {
      return _mockTransactions.where((t) {
        final sameDay =
            t.transactionDate.year == day.year &&
            t.transactionDate.month == day.month &&
            t.transactionDate.day == day.day;
        final matchWallet = walletId == null || t.walletId == walletId;
        final matchCat = categoryId == null || t.categoryId == categoryId;
        return sameDay && matchWallet && matchCat;
      }).toList()..sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        return b.transactionDate.compareTo(a.transactionDate);
      });
    }
    try {
      final uid = _userId;

      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      var query = _baseSelect()
          .eq('user_id', uid)
          .gte('transaction_date', start.toUtc().toIso8601String())
          .lt('transaction_date', end.toUtc().toIso8601String());

      if (walletId != null) {
        query = query.eq('wallet_id', walletId);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query
          .order('is_important', ascending: false)
          .order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<TransactionEntry> fetchTransactionById(String transactionId) async {
    if (_useMockData) {
      return _mockTransactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw const AppException(
          'Transaction not found',
          code: 'NOT_FOUND',
        ),
      );
    }
    try {
      final uid = _userId;

      final row = await _baseSelect()
          .eq('id', transactionId)
          .eq('user_id', uid)
          .single();
      return TransactionEntry.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> createTransaction({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    String? merchantName,
    String source = 'manual',
    bool isImportant = false,
  }) async {
    if (_useMockData) {
      final id = 'mock-tx-${DateTime.now().millisecondsSinceEpoch}';

      // Look up wallet and category mock lists
      final wallets = WalletRepository.mockWallets;
      final categories = CategoryRepository.mockCategories;

      final w = wallets.firstWhere(
        (element) => element.id == walletId,
        orElse: () => Wallet(
          id: walletId,
          name: '',
          type: WalletType.cash,
          initialBalance: 0,
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
          icon: null,
          color: null,
        ),
      );
      final c = categories.firstWhere(
        (element) => element.id == categoryId,
        orElse: () => Category(
          id: categoryId,
          name: '',
          type: type,
          icon: null,
          color: null,
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );

      _mockTransactions.add(
        TransactionEntry(
          id: id,
          amount: amount,
          type: type,
          note: note,
          imagePath: _mockImagePathForCategory(categoryId, type),
          transactionDate: transactionDate,
          walletId: walletId,
          walletName: w.name,
          walletColor: w.color,
          categoryId: categoryId,
          categoryName: c.name,
          categoryColor: c.color,
          isImportant: isImportant,
        ),
      );
      return id;
    }
    try {
      final uid = _userId;

      final row = await _client
          .from('transactions')
          .insert({
            'user_id': uid,
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': type.value,
            'note': note,
            'merchant_name': merchantName,
            'transaction_date': transactionDate.toUtc().toIso8601String(),
            'source': source,
            'image_upload_status': 'pending',
            'is_important': isImportant,
          })
          .select('id')
          .single();

      return row['id'] as String;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    bool isImportant = false,
  }) async {
    if (_useMockData) {
      final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        final wallets = WalletRepository.mockWallets;
        final categories = CategoryRepository.mockCategories;

        final w = wallets.firstWhere(
          (element) => element.id == walletId,
          orElse: () => Wallet(
            id: walletId,
            name: '',
            type: WalletType.cash,
            initialBalance: 0,
            isDefault: false,
            isActive: true,
            createdAt: DateTime.now(),
            icon: null,
            color: null,
          ),
        );
        final c = categories.firstWhere(
          (element) => element.id == categoryId,
          orElse: () => Category(
            id: categoryId,
            name: '',
            type: type,
            icon: null,
            color: null,
            isDefault: false,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );

        _mockTransactions[index] = TransactionEntry(
          id: transactionId,
          amount: amount,
          type: type,
          note: note,
          imagePath: _mockTransactions[index].imagePath,
          transactionDate: transactionDate,
          walletId: walletId,
          walletName: w.name,
          walletColor: w.color,
          categoryId: categoryId,
          categoryName: c.name,
          categoryColor: c.color,
          isImportant: isImportant,
        );
      }
      return;
    }
    try {
      final uid = _userId;

      await _client
          .from('transactions')
          .update({
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': type.value,
            'note': note,
            'transaction_date': transactionDate.toUtc().toIso8601String(),
            'is_important': isImportant,
          })
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> toggleTransactionImportance(
    String transactionId,
    bool isImportant,
  ) async {
    if (_useMockData) {
      final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        final t = _mockTransactions[index];
        _mockTransactions[index] = TransactionEntry(
          id: t.id,
          amount: t.amount,
          type: t.type,
          note: t.note,
          imagePath: t.imagePath,
          transactionDate: t.transactionDate,
          walletId: t.walletId,
          walletName: t.walletName,
          walletColor: t.walletColor,
          categoryId: t.categoryId,
          categoryName: t.categoryName,
          categoryColor: t.categoryColor,
          isImportant: isImportant,
        );
      }
      return;
    }
    try {
      final uid = _userId;

      await _client
          .from('transactions')
          .update({'is_important': isImportant})
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_useMockData) {
      _mockTransactions.removeWhere((t) => t.id == transactionId);
      return;
    }
    try {
      final uid = _userId;

      // 1. Fetch transaction to get image path
      final transaction = await fetchTransactionById(transactionId);

      // 2. Delete from database
      await _client
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', uid);

      // 3. Cleanup storage if needed
      if (transaction.imagePath != null) {
        try {
          await _client.storage.from('transaction-images').remove([
            transaction.imagePath!,
          ]);
        } catch (e, st) {
          AppLogger.error(
            'Failed to delete transaction image from storage',
            e,
            st,
          );
        }
      }
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> uploadTransactionImage(
    String transactionId,
    Uint8List bytes,
  ) async {
    if (_useMockData) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$transactionId.jpg');
      await file.writeAsBytes(bytes);
      return file.path;
    }
    try {
      final uid = _userId;

      final path = 'transactions/$uid/$transactionId.jpg';

      await _client.storage
          .from('transaction-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return path;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> updateTransactionImageMetadata({
    required String transactionId,
    required String? imagePath,
    required String status,
  }) async {
    if (_useMockData) {
      final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _mockTransactions[index] = TransactionEntry(
          id: _mockTransactions[index].id,
          amount: _mockTransactions[index].amount,
          type: _mockTransactions[index].type,
          note: _mockTransactions[index].note,
          imagePath: imagePath,
          transactionDate: _mockTransactions[index].transactionDate,
          walletId: _mockTransactions[index].walletId,
          walletName: _mockTransactions[index].walletName,
          walletColor: _mockTransactions[index].walletColor,
          categoryId: _mockTransactions[index].categoryId,
          categoryName: _mockTransactions[index].categoryName,
          categoryColor: _mockTransactions[index].categoryColor,
          isImportant: _mockTransactions[index].isImportant,
        );
      }
      return;
    }
    try {
      final uid = _userId;

      await _client
          .from('transactions')
          .update({'image_path': imagePath, 'image_upload_status': status})
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> getSignedImageUrl(String path) async {
    if (_useMockData) {
      return path;
    }
    try {
      // getSignedImageUrl does not need user session strictly for generating url,
      // but to be consistent with wrapping Má»ŒI public method and duplicate check,
      // let's wrap it. Since _userId isn't required by the client call, we just try/catch.
      return await _client.storage
          .from('transaction-images')
          .createSignedUrl(path, AppConstants.signedUrlTtlSeconds);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  PostgrestFilterBuilder<PostgrestList> _baseSelect() {
    return _client.from('transactions').select('''
          id,
          amount,
          type,
          note,
          image_path,
          transaction_date,
          is_important,
          wallet:wallets!inner(id,name,color),
          category:categories!inner(id,name,color)
        ''');
  }

  List<TransactionEntry> _mapList(dynamic rows) {
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TransactionEntry.fromMap)
        .toList();
  }

  List<TransactionEntry> _filterTransactions(
    Iterable<TransactionEntry> transactions,
    String normalizedQuery,
  ) {
    final filtered = transactions
        .where(
          (transaction) => _matchesSearchQuery(transaction, normalizedQuery),
        )
        .toList();
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return filtered;
  }

  bool _matchesSearchQuery(
    TransactionEntry transaction,
    String normalizedQuery,
  ) {
    final noteMatch =
        transaction.note?.toLowerCase().contains(normalizedQuery) ?? false;
    final categoryMatch = transaction.categoryName.toLowerCase().contains(
      normalizedQuery,
    );
    return noteMatch || categoryMatch;
  }
}

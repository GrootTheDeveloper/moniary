import '../../../shared/utils/currency_formatter.dart';
import 'assistant_models.dart';

class AssistantLanguageConfig {
  const AssistantLanguageConfig._();

  static const weeklyKeywords = [
    'tuan',
    'week',
    'this week',
    'so voi',
    'weekly',
  ];
  static const dailyAverageKeywords = [
    'trung binh',
    'moi ngay',
    'daily',
    'average',
    'per day',
  ];
  static const recurringKeywords = [
    'lap lai',
    'nhieu lan',
    'recurring',
    'repeat',
    'subscription',
    'subscriptions',
    'regular',
  ];
  static const savingKeywords = [
    'cat giam',
    'tiet kiem',
    'giam',
    'save',
    'saving',
    'reduce',
    'lower',
    'cut',
  ];
  static const topCategoryKeywords = [
    'hang muc',
    'danh muc',
    'nhieu nhat',
    'top',
    'category',
    'categories',
    'most',
    'cost',
    'costs',
    'largest',
  ];
  static const monthlyKeywords = [
    'chi tieu',
    'thang nay',
    'da chi',
    'spend',
    'spent',
    'spending',
    'this month',
  ];
  static const userIdentityKeywords = [
    'toi ten la gi',
    'ten toi la gi',
    'ten cua toi',
    'ban biet ten toi',
    'who am i',
    'my name',
  ];
  static const assistantIdentityKeywords = [
    'ban la ai',
    'ban ten gi',
    'tro ly gi',
    'lam duoc gi',
    'giup duoc gi',
    'who are you',
    'what can you do',
    'help me',
  ];
  static const financeKeywords = [
    'tien',
    'thu',
    'chi',
    'vi',
    'ngan sach',
    'hoa don',
    'giao dich',
    'expense',
    'income',
    'wallet',
    'budget',
    'transaction',
    'money',
  ];
  static const exactGreetings = {
    'hi',
    'hello',
    'hey',
    'xin chao',
    'chao',
    'chao ban',
    'alo',
  };

  static String offlineFallback({required String locale}) {
    final isVietnamese = locale.toLowerCase().startsWith('vi');
    return isVietnamese
        ? 'Mình đang không kết nối được AI. Bạn thử lại sau một chút nhé.'
        : 'I cannot reach AI right now. Please try again in a moment.';
  }

  static String geminiPrompt({
    required String question,
    required AssistantQuestionKind kind,
    required String locale,
    required String currencyCode,
    required FinancialAssistantSnapshot? snapshot,
    required String? profileName,
  }) {
    final responseLanguage = locale.toLowerCase().startsWith('vi')
        ? 'tiếng Việt'
        : 'English';
    final cleanName = profileName?.trim();
    final profileContext = cleanName == null || cleanName.isEmpty
        ? 'Tên người dùng: chưa có trong hồ sơ.'
        : 'Tên người dùng trong hồ sơ Moniary: $cleanName.';
    final financialContext = snapshot == null
        ? 'Không có snapshot tài chính đi kèm cho câu hỏi này. Không được tự bịa số liệu tài chính.'
        : _financialSnapshotPrompt(
            snapshot,
            currencyCode: currencyCode,
            locale: locale,
          );

    return '''
Bạn là trợ lý tài chính trong app Moniary. Trả lời bằng $responseLanguage tự nhiên, ngắn gọn, thân thiện, tối đa 4 câu.

Quy tắc nghiệp vụ:
- Có thể chào hỏi, giải thích bạn là ai, trả lời thông tin hồ sơ được cung cấp, và hỗ trợ câu hỏi tài chính trong Moniary.
- Nếu câu hỏi không liên quan đến Moniary/tài chính cá nhân, lịch sự nói bạn chỉ hỗ trợ tài chính trong Moniary và gợi ý một câu hỏi phù hợp.
- Không bịa dữ liệu tài chính, tên người dùng, ví, ngân sách hoặc giao dịch ngoài context bên dưới.
- Nếu thiếu dữ liệu, nói rõ là chưa đủ dữ liệu.
- Khi nhắc tới tiền, dùng đúng nhãn số tiền đã cung cấp trong snapshot. Không tự đổi sang định dạng dấu phẩy khác.

Câu hỏi người dùng: $question
Loại phân tích nội bộ: ${kind.name}
$profileContext

$financialContext
''';
  }

  static String _financialSnapshotPrompt(
    FinancialAssistantSnapshot snapshot, {
    required String currencyCode,
    required String locale,
  }) {
    final topCategoryName = snapshot.topCategoryName ?? 'khong co';
    final recurringLabel = snapshot.recurringLabel ?? 'khong co';
    String amount(num value) =>
        _promptAmount(value, currencyCode: currencyCode, locale: locale);
    return '''
Snapshot tài chính:
- Chi tháng này: ${amount(snapshot.monthlyExpense)}
- Chi tháng trước: ${amount(snapshot.previousMonthExpense)}
- Chi tuần này: ${amount(snapshot.currentWeekExpense)}
- Chi tuần trước: ${amount(snapshot.previousWeekExpense)}
- Trung bình/ngày: ${amount(snapshot.dailyAverage)}
- Danh mục chi nhiều nhất: $topCategoryName
- Số tiền danh mục top: ${amount(snapshot.topCategoryAmount)}
- Tỷ trọng danh mục top: ${(snapshot.topCategoryShare * 100).toStringAsFixed(0)}%
- Khoản lặp lại nổi bật: $recurringLabel
- Số lần lặp lại: ${snapshot.recurringCount}
- Tổng tiền khoản lặp lại: ${amount(snapshot.recurringAmount)}
- Gợi ý tiết kiệm ước tính: ${amount(snapshot.suggestedSaving)}
''';
  }

  static String displaySafeAnswer(String text) {
    return text
        .replaceAll('\u00A0', ' ')
        .replaceAllMapped(
          RegExp(r'(\d),(?=\d{3}(\D|$))'),
          (match) => '${match.group(1)} ',
        )
        .trim();
  }

  static bool looksTruncatedAnswer(String text) {
    final value = text.trim();
    return RegExp(r'\d+,\d{0,2}$').hasMatch(value);
  }

  static String _promptAmount(
    num value, {
    required String currencyCode,
    required String locale,
  }) {
    return displaySafeAnswer(
      formatCurrency(value, currencyCode: currencyCode, locale: locale),
    );
  }
}

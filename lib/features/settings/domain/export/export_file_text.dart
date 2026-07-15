import 'export_filters.dart';

class ExportFileText {
  const ExportFileText({
    required this.xlsxSheetName,
    required this.spreadsheetHeaders,
    required this.pdfTitle,
    required this.pdfGeneratedAtLabel,
    required this.pdfDataTypesLabel,
    required this.pdfTransactionsLabel,
    required this.pdfWalletsLabel,
    required this.pdfCategoriesLabel,
    required this.pdfIncomeTotalLabel,
    required this.pdfExpenseTotalLabel,
    required this.pdfRecentTransactionsLabel,
    required this.pdfIncomeTypeLabel,
    required this.pdfExpenseTypeLabel,
    required this.dataTypeLabels,
  });

  final String xlsxSheetName;
  final List<String> spreadsheetHeaders;
  final String pdfTitle;
  final String pdfGeneratedAtLabel;
  final String pdfDataTypesLabel;
  final String pdfTransactionsLabel;
  final String pdfWalletsLabel;
  final String pdfCategoriesLabel;
  final String pdfIncomeTotalLabel;
  final String pdfExpenseTotalLabel;
  final String pdfRecentTransactionsLabel;
  final String pdfIncomeTypeLabel;
  final String pdfExpenseTypeLabel;
  final Map<ExportDataType, String> dataTypeLabels;
}

import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routePath = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyPolicyTitle)),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadCard(),
              SizedBox(height: 18),
              _PolicySection(
                title: 'Dữ liệu Moniary xử lý',
                items: [
                  'Thông tin tài khoản như tên hiển thị, email, avatar và user ID khi người dùng đăng nhập.',
                  'Dữ liệu tài chính do người dùng nhập gồm ví, danh mục, giao dịch, số tiền, ghi chú và ngày giờ.',
                  'Ảnh giao dịch do người dùng chụp hoặc chọn từ thiết bị.',
                  'Thiết lập ứng dụng như nhắc nhở và tùy chọn hồ sơ.',
                ],
              ),
              _PolicySection(
                title: 'Mục đích sử dụng',
                items: [
                  'Đăng nhập, đồng bộ dữ liệu và khôi phục dữ liệu khi đổi thiết bị.',
                  'Hiển thị lịch chi tiêu, chi tiết giao dịch, bộ lọc và thống kê tháng.',
                  'Lưu ảnh giao dịch trong Supabase Storage private bucket và cấp signed URL khi cần hiển thị.',
                  'Bảo vệ tài khoản, kiểm soát truy cập bằng RLS và hỗ trợ người dùng khi có yêu cầu.',
                ],
              ),
              _PolicySection(
                title: 'Chia sẻ dữ liệu',
                items: [
                  'Moniary không bán dữ liệu cá nhân hoặc dữ liệu tài chính của người dùng.',
                  'Dữ liệu được lưu trên Supabase để cung cấp Auth, Database và Storage cho ứng dụng.',
                  'MVP không đọc vị trí, danh bạ, SMS, email cá nhân hoặc dữ liệu ngân hàng tự động.',
                ],
              ),
              _PolicySection(
                title: 'Xóa dữ liệu',
                items: [
                  'Người dùng có thể xóa từng giao dịch trong app.',
                  'Người dùng có thể xuất dữ liệu CSV trước khi xóa tài khoản.',
                  'Khi xóa tài khoản, Moniary yêu cầu xóa hồ sơ, ví, danh mục, giao dịch và ảnh trong Storage thuộc user ID hiện tại.',
                ],
              ),
              _PolicySection(
                title: 'Khai báo Google Play Data Safety',
                items: [
                  'Personal info: chỉ thu thập khi người dùng đăng nhập bằng email hoặc Google.',
                  'Financial info: thu thập để lưu và hiển thị thu chi cá nhân.',
                  'Photos: chỉ thu thập ảnh người dùng chủ động chụp hoặc chọn.',
                  'Location, Contacts, SMS: không thu thập trong MVP.',
                ],
              ),
              _ContactBox(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moniary bảo vệ dữ liệu chi tiêu cá nhân của bạn.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Nội dung này dùng cho màn hình trong app và làm bản nháp public Privacy Policy trước khi submit Google Play.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: AppTheme.mint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBox extends StatelessWidget {
  const _ContactBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        'Trước khi phát hành, team cần đưa nội dung này lên một URL public và cập nhật email liên hệ chính thức trong Play Console.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

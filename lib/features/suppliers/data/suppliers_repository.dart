import '../../../core/api/api_client.dart';
import '../../../core/models/supplier.dart';
import '../models/supplied_product.dart';

/// صفحة من الموردين مع عددهم الكلي على السيرفر.
typedef SuppliersPage = ({List<Supplier> items, int total});

/// إجمالي المستحقات على الشركة وعدد الموردين اللي ليهم مستحق.
typedef PayablesSummary = ({double total, int count});

/// قراءة وكتابة الموردين من الـ API.
class SuppliersRepository {
  const SuppliersRepository(this._api);

  final ApiClient _api;

  Future<SuppliersPage> fetchPage({
    int page = 1,
    int limit = 100,
    String? search,
    bool? isActive,
    bool hasDue = false,
    String sort = 'name',
  }) async {
    final ApiResponse response = await _api.get(
      '/suppliers',
      query: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (isActive != null) 'isActive': isActive ? 'true' : 'false',
        if (hasDue) 'hasDue': 'true',
      },
    );

    return (
      items: response.list.map(Supplier.fromJson).toList(),
      total: response.total,
    );
  }

  Future<Supplier> fetchOne(String id) async {
    final ApiResponse response = await _api.get('/suppliers/$id');
    return Supplier.fromJson(response.object);
  }

  /// الأصناف اللي المورد وردها فعلًا، محسوبة من أوامر الشراء على السيرفر.
  Future<List<SuppliedProduct>> fetchSuppliedProducts(String id) async {
    final ApiResponse response = await _api.get('/suppliers/$id/products');
    return response.list.map(SuppliedProduct.fromJson).toList();
  }

  /// إجمالي المستحقات على كل الموردين — محسوب على السيرفر.
  Future<PayablesSummary> fetchPayables() async {
    final ApiResponse response = await _api.get('/suppliers/payables');
    final Map<String, dynamic> data = response.object;

    return (
      total: (data['total'] as num?)?.toDouble() ?? 0,
      count: (data['count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Supplier> create({
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
    String? taxNumber,
    int? paymentTermDays,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/suppliers',
      body: _body(
        name: name,
        phone: phone,
        contactPerson: contactPerson,
        email: email,
        address: address,
        taxNumber: taxNumber,
        paymentTermDays: paymentTermDays,
        note: note,
      ),
    );

    return Supplier.fromJson(response.object);
  }

  Future<Supplier> update(
    String id, {
    String? name,
    String? phone,
    String? contactPerson,
    String? email,
    String? address,
    String? taxNumber,
    int? paymentTermDays,
    String? note,
  }) async {
    final ApiResponse response = await _api.patch(
      '/suppliers/$id',
      body: _body(
        name: name,
        phone: phone,
        contactPerson: contactPerson,
        email: email,
        address: address,
        taxNumber: taxNumber,
        paymentTermDays: paymentTermDays,
        note: note,
      ),
    );

    return Supplier.fromJson(response.object);
  }

  /// المورد مبيتمسحش عشان أوامر الشراء القديمة بتشاور عليه، بيتعطّل بس.
  Future<Supplier> setActiveState(String id, {required bool isActive}) async {
    final ApiResponse response = await _api.patch(
      '/suppliers/$id/active',
      body: <String, bool>{'isActive': isActive},
    );

    return Supplier.fromJson(response.object);
  }

  /// سداد دفعة من المستحق. السيرفر بيرفض المبلغ الأكبر من المستحق.
  Future<Supplier> pay(String id, {required double amount, String? note}) async {
    final ApiResponse response = await _api.post(
      '/suppliers/$id/payments',
      body: <String, dynamic>{
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return Supplier.fromJson(response.object);
  }

  /// الحقول الفاضية مبتتبعتش عشان التعديل الجزئي ما يمسحش قيمة موجودة.
  Map<String, dynamic> _body({
    String? name,
    String? phone,
    String? contactPerson,
    String? email,
    String? address,
    String? taxNumber,
    int? paymentTermDays,
    String? note,
  }) =>
      <String, dynamic>{
        'name': ?name,
        'phone': ?phone,
        'contactPerson': ?contactPerson,
        // الإيميل الفاضي بيتبعت null عشان السيرفر يمسحه بدل ما يرفضه.
        if (email != null) 'email': email.isEmpty ? null : email,
        'address': ?address,
        'taxNumber': ?taxNumber,
        'paymentTermDays': ?paymentTermDays,
        'note': ?note,
      };
}

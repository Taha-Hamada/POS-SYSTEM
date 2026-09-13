import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/models/customer.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/features/pos_sale/controllers/cart_controller.dart';
import 'package:pos_system/features/pos_sale/models/cart_discount.dart';

/// سلوك السلة: الكميات، الخصومات، وحدود المخزون.
/// الحسابات نفسها متغطّية في invoice_math_test.
void main() {
  Product product({
    String id = 'p1',
    double price = 100,
    int stock = 50,
    bool trackStock = true,
    bool taxable = true,
  }) =>
      Product(
        id: id,
        name: 'منتج $id',
        sku: id.toUpperCase(),
        price: price,
        cost: price / 2,
        stock: stock,
        minStock: 5,
        unit: 'قطعة',
        colorIndex: 0,
        trackStock: trackStock,
        isTaxable: taxable,
      );

  CartController cart({double taxRate = 0}) =>
      CartController(number: 1, taxRate: taxRate);

  group('إضافة الأصناف', () {
    test('نفس المنتج بيتجمّع في سطر واحد', () {
      final CartController c = cart()
        ..addProduct(product())
        ..addProduct(product());

      expect(c.lines.length, 1);
      expect(c.lines.first.quantity, 2);
      expect(c.itemsCount, 2);
    });

    test('المنتج النافد مبينزلش السلة', () {
      final CartController c = cart();

      expect(c.addProduct(product(stock: 0)), isFalse);
      expect(c.isEmpty, isTrue);
    });

    test('مبنزوّدش فوق الرصيد المتاح', () {
      final CartController c = cart()..addProduct(product(stock: 2));

      expect(c.addProduct(product(stock: 2)), isTrue);
      // الرصيد خلص عند 2
      expect(c.addProduct(product(stock: 2)), isFalse);
      expect(c.lines.first.quantity, 2);
    });

    test('المنتج الخدمي مالوش حد أقصى', () {
      final CartController c = cart();
      final Product bag = product(id: 'bag', stock: 0, trackStock: false);

      expect(c.addProduct(bag), isTrue);
      expect(c.addProduct(bag), isTrue);
      expect(c.lines.first.quantity, 2);
    });
  });

  group('الكميات', () {
    test('إنقاص الكمية لصفر بيشيل السطر', () {
      final CartController c = cart()..addProduct(product());

      c.changeQuantity(c.lines.first, -1);

      expect(c.isEmpty, isTrue);
    });

    test('الزيادة فوق الرصيد بترجع false', () {
      final CartController c = cart()..addProduct(product(stock: 1));

      expect(c.changeQuantity(c.lines.first, 5), isFalse);
      expect(c.lines.first.quantity, 1);
    });
  });

  group('الخصم', () {
    test('خصم بمبلغ ثابت بيتخصم زي ما هو', () {
      final CartController c = cart()
        ..addProduct(product())
        ..setDiscount(const CartDiscount(type: DiscountType.amount, value: 40));

      expect(c.effectiveDiscount, 40);
      expect(c.discount.shortLabel, '');
    });

    test('خصم بنسبة بيتحسب من المجموع الفرعي', () {
      final CartController c = cart()
        ..addProduct(product())
        ..setDiscount(const CartDiscount(type: DiscountType.percent, value: 10));

      expect(c.effectiveDiscount, 10);
      expect(c.discount.shortLabel, ' (10%)');
    });

    test('خصم النسبة بيتحدّث لما السلة تكبر', () {
      final CartController c = cart()
        ..addProduct(product())
        ..setDiscount(const CartDiscount(type: DiscountType.percent, value: 10));

      final double before = c.effectiveDiscount;
      c.addProduct(product(id: 'p2'));

      expect(c.effectiveDiscount, greaterThan(before));
    });

    test('الخصم مبيعديش المجموع الفرعي', () {
      final CartController c = cart()
        ..addProduct(product(price: 50))
        ..setDiscount(const CartDiscount(type: DiscountType.amount, value: 500));

      expect(c.effectiveDiscount, 50);
      expect(c.total, 0);
    });
  });

  group('الضريبة', () {
    test('بتتحسب بالنسبة الجاية من الإعدادات', () {
      final CartController c = cart(taxRate: 0.14)..addProduct(product());

      expect(c.tax, 14);
      expect(c.total, 114);
    });

    test('الأصناف المعفاة مش داخلة في الضريبة', () {
      final CartController c = cart(taxRate: 0.14)
        ..addProduct(product(taxable: false));

      expect(c.tax, 0);
      expect(c.total, 100);
    });

    test('تغيير النسبة بيعيد الحساب', () {
      final CartController c = cart()..addProduct(product());
      expect(c.total, 100);

      c.setTaxRate(0.14);
      expect(c.total, 114);
    });
  });

  group('العميل', () {
    test('السلة بتبدأ بعميل عابر', () {
      expect(cart().customer.isWalkIn, isTrue);
    });

    test('التفضية بترجّع العميل العابر', () {
      final CartController c = cart()
        ..addProduct(product())
        ..setCustomer(const Customer(id: 'c1', name: 'محمد', phone: '0100'));

      c.clear();

      expect(c.customer.isWalkIn, isTrue);
      expect(c.isEmpty, isTrue);
    });
  });

  group('التحويل لطلب السيرفر', () {
    test('السطور بتتبعت بالمعرّف والكمية بس', () {
      final CartController c = cart()
        ..addProduct(product())
        ..addProduct(product());

      final List<Map<String, dynamic>> json =
          c.toInvoiceLines().map((dynamic l) => l.toJson() as Map<String, dynamic>).toList();

      expect(json, hasLength(1));
      expect(json.first['product'], 'p1');
      expect(json.first['quantity'], 2);
      // السعر مش بيتبعت — السيرفر بيحدده عشان محدش يزوّره.
      expect(json.first.containsKey('unitPrice'), isFalse);
    });

    test('مفيش خصم يعني مفيش حقل خصم', () {
      final CartController c = cart()..addProduct(product());

      expect(c.toDiscountInput(), isNull);
    });

    test('الخصم بيتبعت بنوعه وقيمته', () {
      final CartController c = cart()
        ..addProduct(product())
        ..setDiscount(const CartDiscount(type: DiscountType.percent, value: 15));

      expect(c.toDiscountInput()!.toJson(), <String, dynamic>{
        'type': 'percentage',
        'value': 15.0,
      });
    });
  });
}

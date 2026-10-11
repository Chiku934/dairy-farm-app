enum CustomerType {
  retail('RETAIL', 'Retail Customer'),
  wholesale('WHOLESALE', 'Wholesale / B2B');

  final String apiValue;
  final String label;
  const CustomerType(this.apiValue, this.label);

  static CustomerType fromString(String val) {
    return CustomerType.values.firstWhere(
      (e) => e.apiValue == val || e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => CustomerType.retail,
    );
  }
}

enum OrderStatus {
  pending('PENDING', 'Pending'),
  partiallyFulfilled('PARTIALLY_FULFILLED', 'Partially Dispatched'),
  fulfilled('FULFILLED', 'Fulfilled'),
  cancelled('CANCELLED', 'Cancelled');

  final String apiValue;
  final String label;
  const OrderStatus(this.apiValue, this.label);

  static OrderStatus fromString(String val) {
    return OrderStatus.values.firstWhere(
      (e) => e.apiValue == val || e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

enum PaymentMethod {
  cash('CASH', 'Cash'),
  upi('UPI', 'UPI / QR'),
  bankTransfer('BANK_TRANSFER', 'Bank Transfer / NEFT'),
  cheque('CHEQUE', 'Cheque'),
  credit('CREDIT', 'Credit Account');

  final String apiValue;
  final String label;
  const PaymentMethod(this.apiValue, this.label);

  static PaymentMethod fromString(String val) {
    return PaymentMethod.values.firstWhere(
      (e) => e.apiValue == val || e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum ProductType {
  milk('MILK', 'Milk (Pouches)'),
  paneer('PANEER', 'Paneer'),
  khoya('KHOYA', 'Khoya'),
  ghee('GHEE', 'Ghee'),
  dahi('DAHI', 'Dahi / Curd'),
  butter('BUTTER', 'Butter'),
  biogasFertiliser('BIOGAS_FERTILISER', 'Bio Fertiliser');

  final String apiValue;
  final String label;
  const ProductType(this.apiValue, this.label);

  static ProductType fromString(String val) {
    return ProductType.values.firstWhere(
      (e) => e.apiValue == val || e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => ProductType.milk,
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final CustomerType customerType;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.customerType,
    required this.creditLimit,
    required this.currentBalance,
    required this.isActive,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      customerType: CustomerType.fromString(json['customer_type'] as String? ?? json['customerType'] as String? ?? 'RETAIL'),
      creditLimit: (json['credit_limit'] as num? ?? json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num? ?? json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }
}

class SalesOrderItemModel {
  final String id;
  final String orderId;
  final ProductType productType;
  final double packSize;
  final String packUnit;
  final int quantityOrdered;
  final int quantityDispatched;
  final double unitPrice;
  final double totalPrice;

  SalesOrderItemModel({
    required this.id,
    required this.orderId,
    required this.productType,
    required this.packSize,
    required this.packUnit,
    required this.quantityOrdered,
    required this.quantityDispatched,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SalesOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? json['orderId'] as String? ?? '',
      productType: ProductType.fromString(json['product_type'] as String? ?? json['productType'] as String? ?? 'MILK'),
      packSize: (json['pack_size'] as num? ?? json['packSize'] as num?)?.toDouble() ?? 1.0,
      packUnit: json['pack_unit'] as String? ?? json['packUnit'] as String? ?? 'LITRE',
      quantityOrdered: (json['quantity_ordered'] as num? ?? json['quantityOrdered'] as num?)?.toInt() ?? 0,
      quantityDispatched: (json['quantity_dispatched'] as num? ?? json['quantityDispatched'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num? ?? json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num? ?? json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesOrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String? customerName;
  final String orderDate;
  final String deliveryDate;
  final OrderStatus status;
  final double totalAmount;
  final String? notes;
  final List<SalesOrderItemModel> items;

  SalesOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    required this.orderDate,
    required this.deliveryDate,
    required this.status,
    required this.totalAmount,
    this.notes,
    required this.items,
  });

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final itemsRaw = json['items'] as List<dynamic>? ?? [];

    return SalesOrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? json['orderNumber'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
      customerName: customer?['name'] as String? ?? json['customerName'] as String?,
      orderDate: (json['order_date'] as String? ?? json['orderDate'] as String? ?? '').split('T')[0],
      deliveryDate: (json['delivery_date'] as String? ?? json['deliveryDate'] as String? ?? '').split('T')[0],
      status: OrderStatus.fromString(json['status'] as String? ?? 'PENDING'),
      totalAmount: (json['total_amount'] as num? ?? json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      items: itemsRaw.map((i) => SalesOrderItemModel.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }
}

class SalesDispatchModel {
  final String id;
  final String dispatchNumber;
  final String? orderId;
  final String customerId;
  final String? customerName;
  final String recordDate;
  final String? packagingRunId;
  final ProductType productType;
  final int packsSold;
  final double pricePerPack;
  final double totalAmount;
  final double amountReceived;
  final double balanceDue;
  final PaymentMethod paymentMethod;
  final String? notes;

  SalesDispatchModel({
    required this.id,
    required this.dispatchNumber,
    this.orderId,
    required this.customerId,
    this.customerName,
    required this.recordDate,
    this.packagingRunId,
    required this.productType,
    required this.packsSold,
    required this.pricePerPack,
    required this.totalAmount,
    required this.amountReceived,
    required this.balanceDue,
    required this.paymentMethod,
    this.notes,
  });

  factory SalesDispatchModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;

    return SalesDispatchModel(
      id: json['id'] as String,
      dispatchNumber: json['dispatch_number'] as String? ?? json['dispatchNumber'] as String? ?? '',
      orderId: json['order_id'] as String? ?? json['orderId'] as String?,
      customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
      customerName: customer?['name'] as String? ?? json['customerName'] as String?,
      recordDate: (json['record_date'] as String? ?? json['recordDate'] as String? ?? '').split('T')[0],
      packagingRunId: json['packaging_run_id'] as String? ?? json['packagingRunId'] as String?,
      productType: ProductType.fromString(json['product_type'] as String? ?? json['productType'] as String? ?? 'MILK'),
      packsSold: (json['packs_sold'] as num? ?? json['packsSold'] as num?)?.toInt() ?? 0,
      pricePerPack: (json['price_per_pack'] as num? ?? json['pricePerPack'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num? ?? json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountReceived: (json['amount_received'] as num? ?? json['amountReceived'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balance_due'] as num? ?? json['balanceDue'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String? ?? json['paymentMethod'] as String? ?? 'CASH'),
      notes: json['notes'] as String?,
    );
  }
}

class CustomerPaymentModel {
  final String id;
  final String paymentNumber;
  final String customerId;
  final String? customerName;
  final String? dispatchId;
  final String recordDate;
  final double amountReceived;
  final PaymentMethod paymentMethod;
  final String? referenceCode;
  final String? notes;

  CustomerPaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.customerId,
    this.customerName,
    this.dispatchId,
    required this.recordDate,
    required this.amountReceived,
    required this.paymentMethod,
    this.referenceCode,
    this.notes,
  });

  factory CustomerPaymentModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;

    return CustomerPaymentModel(
      id: json['id'] as String,
      paymentNumber: json['payment_number'] as String? ?? json['paymentNumber'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
      customerName: customer?['name'] as String? ?? json['customerName'] as String?,
      dispatchId: json['dispatch_id'] as String? ?? json['dispatchId'] as String?,
      recordDate: (json['record_date'] as String? ?? json['recordDate'] as String? ?? '').split('T')[0],
      amountReceived: (json['amount_received'] as num? ?? json['amountReceived'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String? ?? json['paymentMethod'] as String? ?? 'CASH'),
      referenceCode: json['reference_code'] as String? ?? json['referenceCode'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

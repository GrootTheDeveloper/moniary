"""Vietnamese and English receipt keywords used by extraction rules."""

DATE_KEYWORDS = [
    "ngày",
    "ngay",
    "hóa đơn ngày",
    "lập ngày",
    "giờ in",
    "thời gian",
    "giờ",
    "gio",
    "date",
    "time",
    "printed",
    "issued",
]

SUBTOTAL_KEYWORDS = [
    "tổng tiền hàng",
    "cộng",
    "thành tiền",
    "tạm tính",
    "tam tinh",
    "tong tien hang",
    "subtotal",
    "sub total",
    "sub-total",
    "net amount",
]

VAT_KEYWORDS = [
    "thuế gtgt",
    "gtgt",
    "thuế vat",
    "thuế",
    "thue",
    "vat",
    "tax",
    "gst",
    "hst",
    "sales tax",
]

DISCOUNT_KEYWORDS = [
    "giảm giá",
    "khuyến mãi",
    "ưu đãi",
    "chiết khấu",
    "giam gia",
    "khuyen mai",
    "uu dai",
    "chiet khau",
    "voucher",
    "coupon",
    "discount",
    "promo",
    "promotion",
    "rebate",
]

TOTAL_KEYWORDS = [
    "tổng thanh toán",
    "tổng cộng",
    "tổng",
    "thành tiền thanh toán",
    "khách trả",
    "tiền thanh toán",
    "tổng tiền thanh toán",
    "tong thanh toan",
    "tong cong",
    "tổng phải thanh toán",
    "thanh toán",
    "total",
    "grand total",
    "total amount",
    "amount due",
    "total due",
    "balance due",
]

PAYMENT_KEYWORDS = {
    "cash": ["tiền mặt", "cash", "tien mat"],
    "card": ["thẻ", "visa", "mastercard", "jcb", "atm", "card"],
    "transfer": [
        "chuyển khoản",
        "chuyen khoan",
        "banking",
        "momo",
        "vnpay",
        "zalopay",
    ],
}

CURRENCY_MAP = {
    "đ": "VND",
    "vnd": "VND",
    "vnđ": "VND",
    "₫": "VND",
    "dong": "VND",
    "usd": "USD",
    "$": "USD",
}

ADDRESS_KEYWORDS = [
    "đường",
    "phố",
    "quận",
    "phường",
    "tp.",
    "tỉnh",
    "street",
    "district",
    "ward",
    "city",
    "số ",
]


/// Static ISO 4217 currency catalogue used by the currency picker.
///
/// Each entry carries the ISO code, English display name, symbol,
/// country-flag emoji, and a representative country name.
/// Entries marked [popular] float to the top of the default sort.
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.country,
    this.popular = false,
  });

  /// ISO 4217 three-letter code, e.g. `USD`.
  final String code;

  /// English display name, e.g. `United States Dollar`.
  final String name;

  /// Currency symbol, e.g. `$`.
  final String symbol;

  /// Country-flag emoji, e.g. `🇺🇸`.
  final String flag;

  /// Representative country/region name.
  final String country;

  /// If true the entry appears in the pinned "popular" section.
  final bool popular;
}

/// Complete currency list.  Popular entries come first; the rest are
/// alphabetical by [code].
const List<CurrencyInfo> kCurrencies = [
  // ── Popular ────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'USD',
    name: 'United States Dollar',
    symbol: r'$',
    flag: '🇺🇸',
    country: 'United States',
    popular: true,
  ),
  CurrencyInfo(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    flag: '🇪🇺',
    country: 'European Union',
    popular: true,
  ),
  CurrencyInfo(
    code: 'GBP',
    name: 'British Pound Sterling',
    symbol: '£',
    flag: '🇬🇧',
    country: 'United Kingdom',
    popular: true,
  ),
  CurrencyInfo(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    flag: '🇯🇵',
    country: 'Japan',
    popular: true,
  ),
  CurrencyInfo(
    code: 'VND',
    name: 'Vietnamese Dong',
    symbol: '₫',
    flag: '🇻🇳',
    country: 'Vietnam',
    popular: true,
  ),
  CurrencyInfo(
    code: 'KRW',
    name: 'South Korean Won',
    symbol: '₩',
    flag: '🇰🇷',
    country: 'South Korea',
    popular: true,
  ),
  CurrencyInfo(
    code: 'CNY',
    name: 'Chinese Yuan',
    symbol: '¥',
    flag: '🇨🇳',
    country: 'China',
    popular: true,
  ),
  CurrencyInfo(
    code: 'THB',
    name: 'Thai Baht',
    symbol: '฿',
    flag: '🇹🇭',
    country: 'Thailand',
    popular: true,
  ),

  // ── A ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'AED',
    name: 'UAE Dirham',
    symbol: 'د.إ',
    flag: '🇦🇪',
    country: 'United Arab Emirates',
  ),
  CurrencyInfo(
    code: 'AFN',
    name: 'Afghan Afghani',
    symbol: '؋',
    flag: '🇦🇫',
    country: 'Afghanistan',
  ),
  CurrencyInfo(
    code: 'ALL',
    name: 'Albanian Lek',
    symbol: 'L',
    flag: '🇦🇱',
    country: 'Albania',
  ),
  CurrencyInfo(
    code: 'AMD',
    name: 'Armenian Dram',
    symbol: '֏',
    flag: '🇦🇲',
    country: 'Armenia',
  ),
  CurrencyInfo(
    code: 'ANG',
    name: 'Netherlands Antillean Guilder',
    symbol: 'ƒ',
    flag: '🇨🇼',
    country: 'Curaçao',
  ),
  CurrencyInfo(
    code: 'AOA',
    name: 'Angolan Kwanza',
    symbol: 'Kz',
    flag: '🇦🇴',
    country: 'Angola',
  ),
  CurrencyInfo(
    code: 'ARS',
    name: 'Argentine Peso',
    symbol: r'$',
    flag: '🇦🇷',
    country: 'Argentina',
  ),
  CurrencyInfo(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: r'A$',
    flag: '🇦🇺',
    country: 'Australia',
  ),
  CurrencyInfo(
    code: 'AWG',
    name: 'Aruban Florin',
    symbol: 'ƒ',
    flag: '🇦🇼',
    country: 'Aruba',
  ),
  CurrencyInfo(
    code: 'AZN',
    name: 'Azerbaijani Manat',
    symbol: '₼',
    flag: '🇦🇿',
    country: 'Azerbaijan',
  ),

  // ── B ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'BAM',
    name: 'Bosnia-Herzegovina Convertible Mark',
    symbol: 'KM',
    flag: '🇧🇦',
    country: 'Bosnia and Herzegovina',
  ),
  CurrencyInfo(
    code: 'BBD',
    name: 'Barbadian Dollar',
    symbol: r'Bds$',
    flag: '🇧🇧',
    country: 'Barbados',
  ),
  CurrencyInfo(
    code: 'BDT',
    name: 'Bangladeshi Taka',
    symbol: '৳',
    flag: '🇧🇩',
    country: 'Bangladesh',
  ),
  CurrencyInfo(
    code: 'BGN',
    name: 'Bulgarian Lev',
    symbol: 'лв',
    flag: '🇧🇬',
    country: 'Bulgaria',
  ),
  CurrencyInfo(
    code: 'BHD',
    name: 'Bahraini Dinar',
    symbol: '.د.ب',
    flag: '🇧🇭',
    country: 'Bahrain',
  ),
  CurrencyInfo(
    code: 'BIF',
    name: 'Burundian Franc',
    symbol: 'FBu',
    flag: '🇧🇮',
    country: 'Burundi',
  ),
  CurrencyInfo(
    code: 'BMD',
    name: 'Bermudian Dollar',
    symbol: r'$',
    flag: '🇧🇲',
    country: 'Bermuda',
  ),
  CurrencyInfo(
    code: 'BND',
    name: 'Brunei Dollar',
    symbol: r'B$',
    flag: '🇧🇳',
    country: 'Brunei',
  ),
  CurrencyInfo(
    code: 'BOB',
    name: 'Bolivian Boliviano',
    symbol: 'Bs.',
    flag: '🇧🇴',
    country: 'Bolivia',
  ),
  CurrencyInfo(
    code: 'BRL',
    name: 'Brazilian Real',
    symbol: r'R$',
    flag: '🇧🇷',
    country: 'Brazil',
  ),
  CurrencyInfo(
    code: 'BSD',
    name: 'Bahamian Dollar',
    symbol: r'$',
    flag: '🇧🇸',
    country: 'Bahamas',
  ),
  CurrencyInfo(
    code: 'BTN',
    name: 'Bhutanese Ngultrum',
    symbol: 'Nu.',
    flag: '🇧🇹',
    country: 'Bhutan',
  ),
  CurrencyInfo(
    code: 'BWP',
    name: 'Botswanan Pula',
    symbol: 'P',
    flag: '🇧🇼',
    country: 'Botswana',
  ),
  CurrencyInfo(
    code: 'BYN',
    name: 'Belarusian Ruble',
    symbol: 'Br',
    flag: '🇧🇾',
    country: 'Belarus',
  ),
  CurrencyInfo(
    code: 'BZD',
    name: 'Belize Dollar',
    symbol: r'BZ$',
    flag: '🇧🇿',
    country: 'Belize',
  ),

  // ── C ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: r'C$',
    flag: '🇨🇦',
    country: 'Canada',
  ),
  CurrencyInfo(
    code: 'CDF',
    name: 'Congolese Franc',
    symbol: 'FC',
    flag: '🇨🇩',
    country: 'DR Congo',
  ),
  CurrencyInfo(
    code: 'CHF',
    name: 'Swiss Franc',
    symbol: 'CHF',
    flag: '🇨🇭',
    country: 'Switzerland',
  ),
  CurrencyInfo(
    code: 'CLP',
    name: 'Chilean Peso',
    symbol: r'$',
    flag: '🇨🇱',
    country: 'Chile',
  ),
  CurrencyInfo(
    code: 'COP',
    name: 'Colombian Peso',
    symbol: r'$',
    flag: '🇨🇴',
    country: 'Colombia',
  ),
  CurrencyInfo(
    code: 'CRC',
    name: 'Costa Rican Colón',
    symbol: '₡',
    flag: '🇨🇷',
    country: 'Costa Rica',
  ),
  CurrencyInfo(
    code: 'CUP',
    name: 'Cuban Peso',
    symbol: r'$',
    flag: '🇨🇺',
    country: 'Cuba',
  ),
  CurrencyInfo(
    code: 'CVE',
    name: 'Cape Verdean Escudo',
    symbol: r'$',
    flag: '🇨🇻',
    country: 'Cape Verde',
  ),
  CurrencyInfo(
    code: 'CZK',
    name: 'Czech Koruna',
    symbol: 'Kč',
    flag: '🇨🇿',
    country: 'Czech Republic',
  ),

  // ── D ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'DJF',
    name: 'Djiboutian Franc',
    symbol: 'Fdj',
    flag: '🇩🇯',
    country: 'Djibouti',
  ),
  CurrencyInfo(
    code: 'DKK',
    name: 'Danish Krone',
    symbol: 'kr',
    flag: '🇩🇰',
    country: 'Denmark',
  ),
  CurrencyInfo(
    code: 'DOP',
    name: 'Dominican Peso',
    symbol: r'RD$',
    flag: '🇩🇴',
    country: 'Dominican Republic',
  ),
  CurrencyInfo(
    code: 'DZD',
    name: 'Algerian Dinar',
    symbol: 'د.ج',
    flag: '🇩🇿',
    country: 'Algeria',
  ),

  // ── E ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'EGP',
    name: 'Egyptian Pound',
    symbol: 'E£',
    flag: '🇪🇬',
    country: 'Egypt',
  ),
  CurrencyInfo(
    code: 'ERN',
    name: 'Eritrean Nakfa',
    symbol: 'Nfk',
    flag: '🇪🇷',
    country: 'Eritrea',
  ),
  CurrencyInfo(
    code: 'ETB',
    name: 'Ethiopian Birr',
    symbol: 'Br',
    flag: '🇪🇹',
    country: 'Ethiopia',
  ),

  // ── F ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'FJD',
    name: 'Fijian Dollar',
    symbol: r'FJ$',
    flag: '🇫🇯',
    country: 'Fiji',
  ),
  CurrencyInfo(
    code: 'FKP',
    name: 'Falkland Islands Pound',
    symbol: '£',
    flag: '🇫🇰',
    country: 'Falkland Islands',
  ),

  // ── G ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'GEL',
    name: 'Georgian Lari',
    symbol: '₾',
    flag: '🇬🇪',
    country: 'Georgia',
  ),
  CurrencyInfo(
    code: 'GHS',
    name: 'Ghanaian Cedi',
    symbol: 'GH₵',
    flag: '🇬🇭',
    country: 'Ghana',
  ),
  CurrencyInfo(
    code: 'GIP',
    name: 'Gibraltar Pound',
    symbol: '£',
    flag: '🇬🇮',
    country: 'Gibraltar',
  ),
  CurrencyInfo(
    code: 'GMD',
    name: 'Gambian Dalasi',
    symbol: 'D',
    flag: '🇬🇲',
    country: 'Gambia',
  ),
  CurrencyInfo(
    code: 'GNF',
    name: 'Guinean Franc',
    symbol: 'FG',
    flag: '🇬🇳',
    country: 'Guinea',
  ),
  CurrencyInfo(
    code: 'GTQ',
    name: 'Guatemalan Quetzal',
    symbol: 'Q',
    flag: '🇬🇹',
    country: 'Guatemala',
  ),
  CurrencyInfo(
    code: 'GYD',
    name: 'Guyanaese Dollar',
    symbol: r'GY$',
    flag: '🇬🇾',
    country: 'Guyana',
  ),

  // ── H ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'HKD',
    name: 'Hong Kong Dollar',
    symbol: r'HK$',
    flag: '🇭🇰',
    country: 'Hong Kong',
  ),
  CurrencyInfo(
    code: 'HNL',
    name: 'Honduran Lempira',
    symbol: 'L',
    flag: '🇭🇳',
    country: 'Honduras',
  ),
  CurrencyInfo(
    code: 'HRK',
    name: 'Croatian Kuna',
    symbol: 'kn',
    flag: '🇭🇷',
    country: 'Croatia',
  ),
  CurrencyInfo(
    code: 'HTG',
    name: 'Haitian Gourde',
    symbol: 'G',
    flag: '🇭🇹',
    country: 'Haiti',
  ),
  CurrencyInfo(
    code: 'HUF',
    name: 'Hungarian Forint',
    symbol: 'Ft',
    flag: '🇭🇺',
    country: 'Hungary',
  ),

  // ── I ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'IDR',
    name: 'Indonesian Rupiah',
    symbol: 'Rp',
    flag: '🇮🇩',
    country: 'Indonesia',
  ),
  CurrencyInfo(
    code: 'ILS',
    name: 'Israeli New Shekel',
    symbol: '₪',
    flag: '🇮🇱',
    country: 'Israel',
  ),
  CurrencyInfo(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    flag: '🇮🇳',
    country: 'India',
  ),
  CurrencyInfo(
    code: 'IQD',
    name: 'Iraqi Dinar',
    symbol: 'ع.د',
    flag: '🇮🇶',
    country: 'Iraq',
  ),
  CurrencyInfo(
    code: 'IRR',
    name: 'Iranian Rial',
    symbol: '﷼',
    flag: '🇮🇷',
    country: 'Iran',
  ),
  CurrencyInfo(
    code: 'ISK',
    name: 'Icelandic Króna',
    symbol: 'kr',
    flag: '🇮🇸',
    country: 'Iceland',
  ),

  // ── J ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'JMD',
    name: 'Jamaican Dollar',
    symbol: r'J$',
    flag: '🇯🇲',
    country: 'Jamaica',
  ),
  CurrencyInfo(
    code: 'JOD',
    name: 'Jordanian Dinar',
    symbol: 'د.ا',
    flag: '🇯🇴',
    country: 'Jordan',
  ),

  // ── K ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'KES',
    name: 'Kenyan Shilling',
    symbol: 'KSh',
    flag: '🇰🇪',
    country: 'Kenya',
  ),
  CurrencyInfo(
    code: 'KGS',
    name: 'Kyrgystani Som',
    symbol: 'сом',
    flag: '🇰🇬',
    country: 'Kyrgyzstan',
  ),
  CurrencyInfo(
    code: 'KHR',
    name: 'Cambodian Riel',
    symbol: '៛',
    flag: '🇰🇭',
    country: 'Cambodia',
  ),
  CurrencyInfo(
    code: 'KMF',
    name: 'Comorian Franc',
    symbol: 'CF',
    flag: '🇰🇲',
    country: 'Comoros',
  ),
  CurrencyInfo(
    code: 'KWD',
    name: 'Kuwaiti Dinar',
    symbol: 'د.ك',
    flag: '🇰🇼',
    country: 'Kuwait',
  ),
  CurrencyInfo(
    code: 'KYD',
    name: 'Cayman Islands Dollar',
    symbol: r'CI$',
    flag: '🇰🇾',
    country: 'Cayman Islands',
  ),
  CurrencyInfo(
    code: 'KZT',
    name: 'Kazakhstani Tenge',
    symbol: '₸',
    flag: '🇰🇿',
    country: 'Kazakhstan',
  ),

  // ── L ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'LAK',
    name: 'Laotian Kip',
    symbol: '₭',
    flag: '🇱🇦',
    country: 'Laos',
  ),
  CurrencyInfo(
    code: 'LBP',
    name: 'Lebanese Pound',
    symbol: 'ل.ل',
    flag: '🇱🇧',
    country: 'Lebanon',
  ),
  CurrencyInfo(
    code: 'LKR',
    name: 'Sri Lankan Rupee',
    symbol: 'Rs',
    flag: '🇱🇰',
    country: 'Sri Lanka',
  ),
  CurrencyInfo(
    code: 'LRD',
    name: 'Liberian Dollar',
    symbol: r'L$',
    flag: '🇱🇷',
    country: 'Liberia',
  ),
  CurrencyInfo(
    code: 'LSL',
    name: 'Lesotho Loti',
    symbol: 'L',
    flag: '🇱🇸',
    country: 'Lesotho',
  ),
  CurrencyInfo(
    code: 'LYD',
    name: 'Libyan Dinar',
    symbol: 'ل.د',
    flag: '🇱🇾',
    country: 'Libya',
  ),

  // ── M ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'MAD',
    name: 'Moroccan Dirham',
    symbol: 'د.م.',
    flag: '🇲🇦',
    country: 'Morocco',
  ),
  CurrencyInfo(
    code: 'MDL',
    name: 'Moldovan Leu',
    symbol: 'L',
    flag: '🇲🇩',
    country: 'Moldova',
  ),
  CurrencyInfo(
    code: 'MGA',
    name: 'Malagasy Ariary',
    symbol: 'Ar',
    flag: '🇲🇬',
    country: 'Madagascar',
  ),
  CurrencyInfo(
    code: 'MKD',
    name: 'Macedonian Denar',
    symbol: 'ден',
    flag: '🇲🇰',
    country: 'North Macedonia',
  ),
  CurrencyInfo(
    code: 'MMK',
    name: 'Myanmar Kyat',
    symbol: 'K',
    flag: '🇲🇲',
    country: 'Myanmar',
  ),
  CurrencyInfo(
    code: 'MNT',
    name: 'Mongolian Tugrik',
    symbol: '₮',
    flag: '🇲🇳',
    country: 'Mongolia',
  ),
  CurrencyInfo(
    code: 'MOP',
    name: 'Macanese Pataca',
    symbol: r'MOP$',
    flag: '🇲🇴',
    country: 'Macau',
  ),
  CurrencyInfo(
    code: 'MRU',
    name: 'Mauritanian Ouguiya',
    symbol: 'UM',
    flag: '🇲🇷',
    country: 'Mauritania',
  ),
  CurrencyInfo(
    code: 'MUR',
    name: 'Mauritian Rupee',
    symbol: '₨',
    flag: '🇲🇺',
    country: 'Mauritius',
  ),
  CurrencyInfo(
    code: 'MVR',
    name: 'Maldivian Rufiyaa',
    symbol: 'Rf',
    flag: '🇲🇻',
    country: 'Maldives',
  ),
  CurrencyInfo(
    code: 'MWK',
    name: 'Malawian Kwacha',
    symbol: 'MK',
    flag: '🇲🇼',
    country: 'Malawi',
  ),
  CurrencyInfo(
    code: 'MXN',
    name: 'Mexican Peso',
    symbol: r'MX$',
    flag: '🇲🇽',
    country: 'Mexico',
  ),
  CurrencyInfo(
    code: 'MYR',
    name: 'Malaysian Ringgit',
    symbol: 'RM',
    flag: '🇲🇾',
    country: 'Malaysia',
  ),
  CurrencyInfo(
    code: 'MZN',
    name: 'Mozambican Metical',
    symbol: 'MT',
    flag: '🇲🇿',
    country: 'Mozambique',
  ),

  // ── N ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'NAD',
    name: 'Namibian Dollar',
    symbol: r'N$',
    flag: '🇳🇦',
    country: 'Namibia',
  ),
  CurrencyInfo(
    code: 'NGN',
    name: 'Nigerian Naira',
    symbol: '₦',
    flag: '🇳🇬',
    country: 'Nigeria',
  ),
  CurrencyInfo(
    code: 'NIO',
    name: 'Nicaraguan Córdoba',
    symbol: r'C$',
    flag: '🇳🇮',
    country: 'Nicaragua',
  ),
  CurrencyInfo(
    code: 'NOK',
    name: 'Norwegian Krone',
    symbol: 'kr',
    flag: '🇳🇴',
    country: 'Norway',
  ),
  CurrencyInfo(
    code: 'NPR',
    name: 'Nepalese Rupee',
    symbol: '₨',
    flag: '🇳🇵',
    country: 'Nepal',
  ),
  CurrencyInfo(
    code: 'NZD',
    name: 'New Zealand Dollar',
    symbol: r'NZ$',
    flag: '🇳🇿',
    country: 'New Zealand',
  ),

  // ── O ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'OMR',
    name: 'Omani Rial',
    symbol: 'ر.ع.',
    flag: '🇴🇲',
    country: 'Oman',
  ),

  // ── P ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'PAB',
    name: 'Panamanian Balboa',
    symbol: 'B/.',
    flag: '🇵🇦',
    country: 'Panama',
  ),
  CurrencyInfo(
    code: 'PEN',
    name: 'Peruvian Sol',
    symbol: 'S/.',
    flag: '🇵🇪',
    country: 'Peru',
  ),
  CurrencyInfo(
    code: 'PGK',
    name: 'Papua New Guinean Kina',
    symbol: 'K',
    flag: '🇵🇬',
    country: 'Papua New Guinea',
  ),
  CurrencyInfo(
    code: 'PHP',
    name: 'Philippine Peso',
    symbol: '₱',
    flag: '🇵🇭',
    country: 'Philippines',
  ),
  CurrencyInfo(
    code: 'PKR',
    name: 'Pakistani Rupee',
    symbol: '₨',
    flag: '🇵🇰',
    country: 'Pakistan',
  ),
  CurrencyInfo(
    code: 'PLN',
    name: 'Polish Zloty',
    symbol: 'zł',
    flag: '🇵🇱',
    country: 'Poland',
  ),
  CurrencyInfo(
    code: 'PYG',
    name: 'Paraguayan Guarani',
    symbol: '₲',
    flag: '🇵🇾',
    country: 'Paraguay',
  ),

  // ── Q ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'QAR',
    name: 'Qatari Rial',
    symbol: 'ر.ق',
    flag: '🇶🇦',
    country: 'Qatar',
  ),

  // ── R ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'RON',
    name: 'Romanian Leu',
    symbol: 'lei',
    flag: '🇷🇴',
    country: 'Romania',
  ),
  CurrencyInfo(
    code: 'RSD',
    name: 'Serbian Dinar',
    symbol: 'дин.',
    flag: '🇷🇸',
    country: 'Serbia',
  ),
  CurrencyInfo(
    code: 'RUB',
    name: 'Russian Ruble',
    symbol: '₽',
    flag: '🇷🇺',
    country: 'Russia',
  ),
  CurrencyInfo(
    code: 'RWF',
    name: 'Rwandan Franc',
    symbol: 'RF',
    flag: '🇷🇼',
    country: 'Rwanda',
  ),

  // ── S ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'SAR',
    name: 'Saudi Riyal',
    symbol: 'ر.س',
    flag: '🇸🇦',
    country: 'Saudi Arabia',
  ),
  CurrencyInfo(
    code: 'SBD',
    name: 'Solomon Islands Dollar',
    symbol: r'SI$',
    flag: '🇸🇧',
    country: 'Solomon Islands',
  ),
  CurrencyInfo(
    code: 'SCR',
    name: 'Seychellois Rupee',
    symbol: '₨',
    flag: '🇸🇨',
    country: 'Seychelles',
  ),
  CurrencyInfo(
    code: 'SDG',
    name: 'Sudanese Pound',
    symbol: 'ج.س.',
    flag: '🇸🇩',
    country: 'Sudan',
  ),
  CurrencyInfo(
    code: 'SEK',
    name: 'Swedish Krona',
    symbol: 'kr',
    flag: '🇸🇪',
    country: 'Sweden',
  ),
  CurrencyInfo(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: r'S$',
    flag: '🇸🇬',
    country: 'Singapore',
  ),
  CurrencyInfo(
    code: 'SHP',
    name: 'Saint Helena Pound',
    symbol: '£',
    flag: '🇸🇭',
    country: 'Saint Helena',
  ),
  CurrencyInfo(
    code: 'SLE',
    name: 'Sierra Leonean Leone',
    symbol: 'Le',
    flag: '🇸🇱',
    country: 'Sierra Leone',
  ),
  CurrencyInfo(
    code: 'SOS',
    name: 'Somali Shilling',
    symbol: 'Sh',
    flag: '🇸🇴',
    country: 'Somalia',
  ),
  CurrencyInfo(
    code: 'SRD',
    name: 'Surinamese Dollar',
    symbol: r'$',
    flag: '🇸🇷',
    country: 'Suriname',
  ),
  CurrencyInfo(
    code: 'SSP',
    name: 'South Sudanese Pound',
    symbol: '£',
    flag: '🇸🇸',
    country: 'South Sudan',
  ),
  CurrencyInfo(
    code: 'STN',
    name: 'São Tomé and Príncipe Dobra',
    symbol: 'Db',
    flag: '🇸🇹',
    country: 'São Tomé and Príncipe',
  ),
  CurrencyInfo(
    code: 'SYP',
    name: 'Syrian Pound',
    symbol: '£S',
    flag: '🇸🇾',
    country: 'Syria',
  ),
  CurrencyInfo(
    code: 'SZL',
    name: 'Swazi Lilangeni',
    symbol: 'E',
    flag: '🇸🇿',
    country: 'Eswatini',
  ),

  // ── T ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'TJS',
    name: 'Tajikistani Somoni',
    symbol: 'SM',
    flag: '🇹🇯',
    country: 'Tajikistan',
  ),
  CurrencyInfo(
    code: 'TMT',
    name: 'Turkmenistani Manat',
    symbol: 'T',
    flag: '🇹🇲',
    country: 'Turkmenistan',
  ),
  CurrencyInfo(
    code: 'TND',
    name: 'Tunisian Dinar',
    symbol: 'د.ت',
    flag: '🇹🇳',
    country: 'Tunisia',
  ),
  CurrencyInfo(
    code: 'TOP',
    name: 'Tongan Paʻanga',
    symbol: r'T$',
    flag: '🇹🇴',
    country: 'Tonga',
  ),
  CurrencyInfo(
    code: 'TRY',
    name: 'Turkish Lira',
    symbol: '₺',
    flag: '🇹🇷',
    country: 'Turkey',
  ),
  CurrencyInfo(
    code: 'TTD',
    name: 'Trinidad and Tobago Dollar',
    symbol: r'TT$',
    flag: '🇹🇹',
    country: 'Trinidad and Tobago',
  ),
  CurrencyInfo(
    code: 'TWD',
    name: 'New Taiwan Dollar',
    symbol: r'NT$',
    flag: '🇹🇼',
    country: 'Taiwan',
  ),
  CurrencyInfo(
    code: 'TZS',
    name: 'Tanzanian Shilling',
    symbol: 'TSh',
    flag: '🇹🇿',
    country: 'Tanzania',
  ),

  // ── U ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'UAH',
    name: 'Ukrainian Hryvnia',
    symbol: '₴',
    flag: '🇺🇦',
    country: 'Ukraine',
  ),
  CurrencyInfo(
    code: 'UGX',
    name: 'Ugandan Shilling',
    symbol: 'USh',
    flag: '🇺🇬',
    country: 'Uganda',
  ),
  CurrencyInfo(
    code: 'UYU',
    name: 'Uruguayan Peso',
    symbol: r'$U',
    flag: '🇺🇾',
    country: 'Uruguay',
  ),
  CurrencyInfo(
    code: 'UZS',
    name: 'Uzbekistan Som',
    symbol: 'сўм',
    flag: '🇺🇿',
    country: 'Uzbekistan',
  ),

  // ── V ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'VES',
    name: 'Venezuelan Bolívar',
    symbol: 'Bs.S',
    flag: '🇻🇪',
    country: 'Venezuela',
  ),
  CurrencyInfo(
    code: 'VUV',
    name: 'Vanuatu Vatu',
    symbol: 'VT',
    flag: '🇻🇺',
    country: 'Vanuatu',
  ),

  // ── W ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'WST',
    name: 'Samoan Tala',
    symbol: r'WS$',
    flag: '🇼🇸',
    country: 'Samoa',
  ),

  // ── X ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'XAF',
    name: 'CFA Franc BEAC',
    symbol: 'FCFA',
    flag: '🇨🇲',
    country: 'Central Africa',
  ),
  CurrencyInfo(
    code: 'XCD',
    name: 'East Caribbean Dollar',
    symbol: r'EC$',
    flag: '🇦🇬',
    country: 'East Caribbean',
  ),
  CurrencyInfo(
    code: 'XOF',
    name: 'CFA Franc BCEAO',
    symbol: 'CFA',
    flag: '🇸🇳',
    country: 'West Africa',
  ),
  CurrencyInfo(
    code: 'XPF',
    name: 'CFP Franc',
    symbol: '₣',
    flag: '🇵🇫',
    country: 'French Polynesia',
  ),

  // ── Y ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'YER',
    name: 'Yemeni Rial',
    symbol: '﷼',
    flag: '🇾🇪',
    country: 'Yemen',
  ),

  // ── Z ──────────────────────────────────────────────────────────────
  CurrencyInfo(
    code: 'ZAR',
    name: 'South African Rand',
    symbol: 'R',
    flag: '🇿🇦',
    country: 'South Africa',
  ),
  CurrencyInfo(
    code: 'ZMW',
    name: 'Zambian Kwacha',
    symbol: 'ZK',
    flag: '🇿🇲',
    country: 'Zambia',
  ),
  CurrencyInfo(
    code: 'ZWL',
    name: 'Zimbabwean Dollar',
    symbol: r'Z$',
    flag: '🇿🇼',
    country: 'Zimbabwe',
  ),
];

/// Lookup helper – returns the [CurrencyInfo] for a given ISO code,
/// or a minimal fallback if the code is not in the catalogue.
CurrencyInfo currencyInfoFor(String code) {
  for (final c in kCurrencies) {
    if (c.code == code) return c;
  }
  return CurrencyInfo(
    code: code,
    name: code,
    symbol: code,
    flag: '🏳️',
    country: '',
  );
}

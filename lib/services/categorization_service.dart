class CategorizationService {
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'swiggy',
      'zomato',
      'dominos',
      'pizza',
      'burger',
      'kfc',
      'mcdonalds',
      'mcdonald',
      'subway',
      'cafe',
      'restaurant',
      'food',
      'eat',
      'biryani',
      'dhaba',
      'hotel',
      'bakery',
      'sweet',
      'sweets',
      'bikaner',
      'chai',
      'tea',
      'coffee',
      'starbucks',
      'dunkin',
      'barbeque',
      'bbq',
      'haldiram',
      'amul',
      'milk',
      'dairy',
    ],
    'Groceries': [
      'bigbasket',
      'grofers',
      'blinkit',
      'zepto',
      'dunzo',
      'grocery',
      'supermarket',
      'dmart',
      'reliance fresh',
      'more supermarket',
      'nature basket',
      'vegetables',
      'fruits',
      'kirana',
    ],
    'Transport': [
      'ola',
      'uber',
      'rapido',
      'auto',
      'cab',
      'taxi',
      'metro',
      'bus',
      'irctc',
      'railway',
      'train',
      'flight',
      'indigo',
      'spicejet',
      'airindia',
      'vistara',
      'goair',
      'petrol',
      'fuel',
      'hp petrol',
      'iocl',
      'bpcl',
      'parking',
      'toll',
      'fastag',
    ],
    'Shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'meesho',
      'nykaa',
      'puma',
      'nike',
      'adidas',
      'zara',
      'h&m',
      'westside',
      'shoppers stop',
      'lifestyle',
      'pantaloons',
      'max fashion',
      'decathlon',
      'ikea',
      'croma',
      'reliance digital',
      'vijay sales',
      'apple store',
    ],
    'EMI': [
      'emi',
      'loan',
      'bajaj finserv',
      'hdfc loan',
      'icici loan',
      'axis loan',
      'home loan',
      'car loan',
      'personal loan',
      'lic',
      'insurance premium',
    ],
    'Subscriptions': [
      'netflix',
      'spotify',
      'amazon prime',
      'hotstar',
      'disney',
      'youtube',
      'apple music',
      'google one',
      'microsoft',
      'adobe',
      'dropbox',
      'linkedin',
      'coursera',
      'udemy',
      'subscription',
    ],
    'Utilities': [
      'electricity',
      'bescom',
      'tata power',
      'adani electricity',
      'msedcl',
      'water bill',
      'gas bill',
      'mgl',
      'igl',
      'mahanagar gas',
      'broadband',
      'airtel',
      'jio',
      'bsnl',
      'vodafone',
      'vi ',
      'recharge',
      'dth',
      'tata sky',
      'dish tv',
      'sun direct',
    ],
    'Medical': [
      'pharmacy',
      'medical',
      'hospital',
      'clinic',
      'doctor',
      'apollo',
      'medplus',
      'netmeds',
      'pharmeasy',
      '1mg',
      'healthkart',
      'lab',
      'diagnostic',
      'pathlab',
      'thyrocare',
    ],
    'Housing': [
      'rent',
      'maintenance',
      'society',
      'housing',
      'flat',
      'apartment',
      'pg ',
      'hostel',
      'nobroker',
      'magicbricks',
    ],
    'Entertainment': [
      'bookmyshow',
      'pvr',
      'inox',
      'cinepolis',
      'movie',
      'cinema',
      'theatre',
      'concert',
      'event',
      'gaming',
      'steam',
      'playstation',
      'xbox',
    ],
    'Income': [
      'salary',
      'credit',
      'received',
      'refund',
      'cashback',
      'reward',
      'interest',
      'dividend',
      'freelance',
      'payment received',
      'neft cr',
      'imps cr',
      'upi cr',
    ],
  };

  static const Map<String, String> _subcategoryMap = {
    'swiggy': 'Food Delivery',
    'zomato': 'Food Delivery',
    'dominos': 'Fast Food',
    'kfc': 'Fast Food',
    'mcdonalds': 'Fast Food',
    'mcdonald': 'Fast Food',
    'subway': 'Fast Food',
    'starbucks': 'Cafe',
    'coffee': 'Cafe',
    'ola': 'Cab',
    'uber': 'Cab',
    'rapido': 'Bike Taxi',
    'metro': 'Public Transport',
    'irctc': 'Train',
    'indigo': 'Flight',
    'petrol': 'Fuel',
    'fuel': 'Fuel',
    'netflix': 'Streaming',
    'spotify': 'Music',
    'amazon prime': 'Streaming',
    'hotstar': 'Streaming',
    'airtel': 'Mobile/Internet',
    'jio': 'Mobile/Internet',
    'electricity': 'Electricity',
    'salary': 'Salary',
    'freelance': 'Freelance',
  };

  String categorize(String merchant) {
    final lower = merchant.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Uncategorised';
  }

  String getSubcategory(String merchant) {
    final lower = merchant.toLowerCase();
    for (final entry in _subcategoryMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return '';
  }

  // SMS parsing patterns
  static final List<Map<String, dynamic>> _smsPatterns = [
    {
      'pattern': RegExp(
        r'(?:debited|deducted|spent|paid|payment of|purchase of).{0,20}?(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      'type': 'debit',
    },
    {
      'pattern': RegExp(
        r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?).{0,50}?(?:debited|deducted|spent|paid)',
        caseSensitive: false,
      ),
      'type': 'debit',
    },
    {
      'pattern': RegExp(
        r'(?:credited|received|credit of).{0,20}?(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      'type': 'credit',
    },
    {
      'pattern': RegExp(
        r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?).{0,50}?(?:credited|received)',
        caseSensitive: false,
      ),
      'type': 'credit',
    },
  ];

  static final RegExp _merchantPattern = RegExp(
    r'(?:at|to|from|via|for(?!\s*(?:Rs\.?|INR|₹|dispute|query|help|queries)))\s+([A-Za-z0-9\s&\-\.]+?)(?:\s+on|\s+for|\s+ref|\s+txn|\s+upi|\.|\n|$)',
    caseSensitive: false,
  );

  static final RegExp _merchantPatternSecondary = RegExp(
    r';\s*([A-Za-z0-9\s&\-\.]+?)\s+credited',
    caseSensitive: false,
  );

  static final RegExp _upiPattern = RegExp(
    r'UPI[:\s]+([a-zA-Z0-9@\.\-_]+)',
    caseSensitive: false,
  );

  static final RegExp _accountNoPattern = RegExp(
    r'(?:a/c|acct|account)(?:\s*no\.?|\s*number)?[\s:-]*(?:ending\s+with\s+|ending\s+in\s+)?([xX\*0-9]+)',
    caseSensitive: false,
  );

  static final RegExp _refNoPattern = RegExp(
    r'(?:ref(?:\s*no\.?)?|reference(?:\s*no\.?)?|utr|upi(?:\s*ref)?|txn\s*id)[\s:-]*([a-zA-Z0-9]{6,})',
    caseSensitive: false,
  );

  Map<String, dynamic>? parseSms(String smsBody, String sender) {
    String? amountStr;
    String type = 'debit';

    for (final pattern in _smsPatterns) {
      final match = (pattern['pattern'] as RegExp).firstMatch(smsBody);
      if (match != null) {
        amountStr = match.group(1)?.replaceAll(',', '');
        type = pattern['type'] as String;
        break;
      }
    }

    if (amountStr == null) return null;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // Extract merchant
    String merchant = 'Unknown';
    final merchantMatch = _merchantPattern.firstMatch(smsBody);
    final secondaryMatch = _merchantPatternSecondary.firstMatch(smsBody);
    
    if (secondaryMatch != null && secondaryMatch.group(1) != null && secondaryMatch.group(1)!.trim().isNotEmpty) {
      merchant = secondaryMatch.group(1)?.trim() ?? 'Unknown';
    } else if (merchantMatch != null && merchantMatch.group(1) != null && merchantMatch.group(1)!.trim().isNotEmpty) {
      merchant = merchantMatch.group(1)?.trim() ?? 'Unknown';
    } else {
      final upiMatch = _upiPattern.firstMatch(smsBody);
      if (upiMatch != null) {
        merchant = upiMatch.group(1)?.split('@').first ?? 'Unknown';
      }
    }

    // Determine payment mode
    String paymentMode = 'Bank Transfer';
    final lower = smsBody.toLowerCase();
    if (lower.contains('upi')) {
      paymentMode = 'UPI';
    } else if (lower.contains('credit card') || lower.contains('cc ')) {
      paymentMode = 'Card';
    } else if (lower.contains('debit card') || lower.contains('dc ')) {
      paymentMode = 'Card';
    } else if (lower.contains('atm')) {
      paymentMode = 'ATM';
    } else if (lower.contains('auto') || lower.contains('nach')) {
      paymentMode = 'Auto-debit';
    }

    // Extract Account No
    String accountNo = '';
    final acctMatch = _accountNoPattern.firstMatch(smsBody);
    if (acctMatch != null) {
      accountNo = acctMatch.group(1)?.trim() ?? '';
    }

    // Extract Ref No
    String refNo = '';
    final refMatch = _refNoPattern.firstMatch(smsBody);
    if (refMatch != null) {
      refNo = refMatch.group(1)?.trim() ?? '';
    }

    return {
      'amount': amount,
      'type': type,
      'merchant': merchant,
      'paymentMode': paymentMode,
      'accountNo': accountNo,
      'bankRefNo': refNo,
    };
  }
}

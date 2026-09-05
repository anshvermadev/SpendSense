
============================================================
SPENDSENSE V3 - MOBILE DEPLOYMENT
============================================================

INPUT
-----

Shape:
[1, 128]

Type:
int32


TOKENIZATION
------------

1. Lowercase transaction text
2. Strip leading/trailing whitespace
3. Normalize multiple spaces
4. Convert each character using vocabulary.json
5. Unknown characters = ID 1
6. PAD = ID 0
7. Truncate to 128
8. Post-pad to 128


OUTPUT
------

Output heads:

1. merchant
2. category


DECODE LABELS
-------------

Merchant:
artifacts/merchant_labels.json

Category:
artifacts/category_labels.json


IMPORTANT
---------

Flutter MUST use the exact vocabulary.json.

Do NOT generate vocabulary dynamically.

============================================================

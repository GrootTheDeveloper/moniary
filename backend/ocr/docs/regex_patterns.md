# Receipt OCR Regex Patterns

The backend uses a configurable OCR engine to convert pixels to text. Set
`OCR_ENGINE=auto`, `OCR_ENGINE=paddleocr`, or `OCR_ENGINE=tesseract`.
PaddleOCR is the preferred server-side engine when installed; Tesseract remains
the lightweight fallback. All structured fields are extracted by deterministic
regex and keyword matching after OCR.

## Header

- Vietnamese/English date: `DD/MM/YYYY`, `YYYY-MM-DD`, or
  `ngày DD tháng MM năm YYYY`
- Time: `HH:MM`, optional seconds and AM/PM
- Merchant: first plausible non-address line in the first ten lines

## Items

Supported layouts:

```text
Cà phê sữa đá      2  25.000  50.000
Cà phê sữa đá
2 x 25.000  50.000
Bánh mì thịt       35.000
2x Lorem ipsum     $ 15.00
```

The final form is included for the sample receipt in this repository. Its last
number is treated as the printed line amount; unit price is derived as
`amount / quantity`.

## Totals

The last numeric value on a keyword line is used. Lines are scanned from the
bottom because totals normally appear near the end of a receipt. Keyword
matching is case-insensitive and ignores Vietnamese diacritics.

## Limitations

- Rules depend on OCR line grouping and whitespace.
- Unseen receipt layouts may require another explicit pattern.
- PaddleOCR must be installed separately from `requirements-paddle.txt` when
  `OCR_ENGINE=paddleocr` is used.
- Tesseract must have both `eng` and `vie` language packs when the Tesseract
  fallback is used for bilingual bills.
- Confidence reflects field completeness and arithmetic consistency, not
  OCR word-level confidence.

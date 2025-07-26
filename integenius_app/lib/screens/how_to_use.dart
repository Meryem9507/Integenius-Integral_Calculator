import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // markdownData burada sınıf içinde, method dışında tanımlanmalı:
  static const String markdownData = """
**1. INPUT FUNCTION:** Enter a valid mathematical function to calculate its definite integral.

- For exponentiation use `**`. Example: `x**2`.

**2. EULER'S NUMBER (e):** Use `E` for Euler's number. Example: `E**(2*x)`.

- Avoid using lowercase `e` as it will be interpreted differently.

**3. LOGARITHMS:** Use `ln(x)` for natural logarithms.

- If you need a logarithm with a different base, use `log2(x)` for base 2, `log10(x)` for base 10.

- Example inputs:
  - Natural log: `ln(x)`
  - Base 2 log: `log2(x)`
  - Base 10 log: `log10(x)`

**4. TRIGONOMETRIC FUNCTIONS:** Use standard trigonometric functions such as `sin(x)`, `cos(x)`, `tan(x)`.

- Example: `sin(x)` for the sine of x, `cos(x)` for cosine of x.

**5. INVERSE TRIGONOMETRIC FUNCTIONS:** Use the internal function names such as `atan(x)`, `asin(x)`, `acos(x)`.

- Example: `atan(x)` for the inverse tangent of x.
- Avoid using `arctan(x)`, `arcsin(x)`, or `arccos(x)` as they are not recognized.

**6. PARENTHESES:** Use parentheses `()` to clarify the order of operations.

- Example: `(x + 1)**2` or `sin(x) * cos(x)`.

**7. MULTIPLICATION AND DIVISION:** To specify multiplication, use `*` or simply place variables next to each other. For division, use `/` and use parentheses to clarify the order when dividing.

- Example: `x * sin(x)` or `xsin(x)`.
- Example: `x / sin(x)` or `x/sin(x)`.
- Example: `(x + 1) / (sin(x) + cos(x))`.

**8. EXPONENT RULES:** When using exponentiation, be careful how you enter the expression.

- Always use `**` to represent exponentiation, not `^`.
- To raise a number or constant to a compound expression (like `2*x`), use parentheses.
- ✅ Correct: `E**(2*x)` → means e^(2x)
- ❌ Incorrect: `E**2*x` → means (e^2) * x, not e^(2x)
- Summary:
  - Use `E**(expression)` for exponential expressions involving variables.
  - Never use `^` as it performs bitwise XOR, not exponentiation.

**9. ROOTS AND FRACTIONS IN EXPONENTS:** Always use parentheses when writing fractional exponents.

- Example: `(x**3 + 1)**(1/2)` for the square root of `(x**3 + 1)`.
- ✅ Correct: `(x**3 + 1)**(1/2)`
- ❌ Incorrect: `(x**3 + 1)**1/2` (interpreted as divided by 2)

**10. PARTIAL FRACTIONS INPUT FORMAT:** When entering rational functions for partial fraction decomposition, format input precisely.

- Write numerator and denominator clearly with proper parentheses and explicit multiplication signs `*`.
- Use `**` for exponentiation to indicate powers.
- Enclose each factor of the denominator in parentheses and multiply explicitly.
- Order of denominator factors matters for correct parsing.
- Example: `(2x+1) / ((x-3)**2 * (x+1))`
- Note: swapping denominator order `(2x+1) / ((x+1)*(x-3)**2)` may give incorrect results.
- Summary:
  - Use parentheses around numerator and denominator.
  - Use `**` for powers.
  - Use `*` for multiplication explicitly.
  - Keep denominator factors in correct order.

  **11. POWER OF TRIGONOMETRIC FUNCTIONS:** When entering power of trigonometric functions, make sure the exponent is applied to the entire function using the correct syntax.

- Use ** the exponent for exponentiation and always write the function name before the exponent.
- ✅ Correct format: cos**4(x) means `cos^4(x)`.
- ❌ Avoiding writing: cos**4(x) as it will be interpreted as (cos(x))^4, which might behave differently in symbolic simplifications.
- This ensure the system can apply trigonometric identities (like power-reduction or product-to-sum) properly.

**12. ABSOLUTE VALUES:** When writing functions that include absolute value expressions, make sure to use 'abs(x)' instead of |x|.

- Example: e^-|x| should be written as E**(-abs(x)) or E**-abs(x).

---
""";

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(11, 15, 26, 1.0),
          leading: Padding(
            padding: const EdgeInsets.all(1.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(left: 10, top: 10),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                width: deviceWidth,
                height: deviceHeight * 1 / 8,
                color: const Color.fromRGBO(11, 15, 26, 1.0),
                child: const Center(
                  child: Text(
                    "How to Use the App?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // INTRO TEXT
              Container(
                width: deviceWidth,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: const Text(
                  "This app allows you to calculate definite integrals of mathematical functions. Below is a step-by-step guide on how to use the app:",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Academic',
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              // USER GUIDE
              Container(
                width: deviceWidth,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "User Guide",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Academic',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Follow the instructions below to enter your function correctly.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Academic',
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),

                    // MARKDOWN BODY
                    MarkdownBody(
                      data: markdownData,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Academic',
                          color: Colors.black,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        code: const TextStyle(
                          backgroundColor: Color(0xfff0f0f0),
                          fontFamily: 'Courier',
                          fontSize: 16,
                          color: Color.fromARGB(255, 7, 54, 136),
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // IMAGE
                    Container(
                      width: deviceWidth * 0.9,
                      height: deviceHeight * 0.3,
                      child: Image.asset(
                        "lib/assets/images/integral.jpg",
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Example input for the above integral: (x+2)*E**(3x)\n-----------------------------------------------------------------------\n",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Academic',
                      ),
                      textAlign: TextAlign.justify,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Extra spacing for scrolling comfort
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}





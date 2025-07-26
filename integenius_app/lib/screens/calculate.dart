import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_math_fork/flutter_math.dart';

class CalculateScreen extends StatefulWidget {
  const CalculateScreen({super.key});

  @override
  State<CalculateScreen> createState() => _CalculateScreenState();
}

class _CalculateScreenState extends State<CalculateScreen> {
  final TextEditingController _functionController = TextEditingController();
  final TextEditingController _lowerLimitController = TextEditingController();
  final TextEditingController _upperLimitController = TextEditingController();

  String _latexResult = '';
  List<String> _solutionSteps = [];
  List<String> _methodsUsed = [];

  bool _isLoading = false;
  bool _isImproperIntegral = false;
  bool _isDefiniteIntegral = false;

  String? _errorMessage;

  @override
  void dispose() {
    _functionController.dispose();
    _lowerLimitController.dispose();
    _upperLimitController.dispose();
    super.dispose();
  }

  bool _isValidLimit(String text) {
    if (text.isEmpty) return true;
    if (text == 'oo' || text == '-oo') return true;
    return double.tryParse(text) != null;
  }

  Future<void> _calculateIntegral() async {
    final functionInput = _functionController.text.trim();
    final lowerLimitInput = _lowerLimitController.text.trim();
    final upperLimitInput = _upperLimitController.text.trim();

    if (functionInput.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a function to integrate.';
        _latexResult = '';
        _solutionSteps.clear();
        _methodsUsed.clear();
      });
      return;
    }

    if (!_isValidLimit(lowerLimitInput) || !_isValidLimit(upperLimitInput)) {
      setState(() {
        _errorMessage = 'Limits must be numbers or ∞ (oo) / -∞ (-oo).';
        _latexResult = '';
        _solutionSteps.clear();
        _methodsUsed.clear();
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:5000/calculate');

    final requestData = {
      "function": functionInput,
      "lower_limit": lowerLimitInput.isEmpty ? null : lowerLimitInput,
      "upper_limit": upperLimitInput.isEmpty ? null : upperLimitInput,
    };

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _latexResult = '';
      _solutionSteps.clear();
      _methodsUsed.clear();
      _isImproperIntegral = false;
      _isDefiniteIntegral = false;
    });

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('error')) {
          setState(() {
            _errorMessage = data['error'].toString();
          });
          return;
        }

        setState(() {
          _latexResult = data['result']?.toString() ?? '';
          _solutionSteps = (data['steps'] as List<dynamic>?)
                  ?.whereType<String>()
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
                  .toList() ??
              [];
          _methodsUsed = (data['methods'] as List<dynamic>?)
                  ?.whereType<String>()
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              [];

          _isImproperIntegral = data['is_improper'] ?? false;
          _isDefiniteIntegral = data['is_definite'] ?? true;
          _errorMessage = null;
        });
      } else {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage = errorData['error'] ?? 'Server error occurred.';
          });
        } catch (_) {
          setState(() {
            _errorMessage =
                'HTTP ${response.statusCode}: ${response.reasonPhrase}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          _errorMessage =
              'Could not connect to server. Please check if backend is running.';
        } else if (e.toString().contains('TimeoutException')) {
          _errorMessage = 'Request timed out. Please try again.';
        } else {
          _errorMessage = 'Network error: $e';
        }
      });
    }
  }

  void _clearForm() {
    setState(() {
      _functionController.clear();
      _lowerLimitController.clear();
      _upperLimitController.clear();
      _latexResult = '';
      _solutionSteps.clear();
      _methodsUsed.clear();
      _isImproperIntegral = false;
      _errorMessage = null;
    });
  }

  Widget _buildMethodChips() {
    final Map<String, List<dynamic>> methodStyles = {
      'U-Substitution': [Colors.blue, Icons.swap_horiz],
      'Integration by Parts': [Colors.green, Icons.call_split],
      'Trigonometric Substitution': [Colors.orange, Icons.change_circle],
      'Partial Fractions': [Colors.red, Icons.pie_chart],
      'Trigonometric Identities': [Colors.purple, Icons.functions],
    };

    if (_latexResult.isEmpty && _errorMessage == null) {
      return const SizedBox.shrink();
    }

    if (_methodsUsed.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No specific method was identified for this solution.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    return Padding(
    padding: const EdgeInsets.all(16),
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  _methodsUsed.length == 1 ? 'Method Used:' : 'Methods Used:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _methodsUsed.map((method) {
                final style = methodStyles[method] ??
                    [Colors.grey, Icons.integration_instructions];
                return Chip(
                  avatar: Icon(style[1] as IconData,
                      color: Colors.white, size: 18),
                  label: Text(
                    method,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: style[0] as Color,
                  elevation: 2,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Widget _buildStepsSection() {
    if (_solutionSteps.isEmpty) return const SizedBox.shrink();

    // Filter: error, undefined, null terms are removed
    final filteredSteps = _solutionSteps.where((step) {
      final lowerStep = step.toLowerCase();
      return step.length > 3 &&
          !lowerStep.contains('error') &&
          !lowerStep.contains('undefined') &&
          !lowerStep.contains('null');
    }).toList();

    if (filteredSteps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline,
                      color: Colors.deepPurple, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Solution Steps:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  if (_isImproperIntegral) ...[
                    const SizedBox(width: 8),
                    const Chip(
                      label: Text(
                        'Improper',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ...filteredSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;

                // Markdown-style bold kontrolü
                final isBold = step.startsWith('**') && step.contains(':**');
                var displayText = step;
                if (isBold) {
                  displayText =
                      step.replaceFirst('**', '').replaceFirst(':**', ':');
                }

                final hasLatex = displayText.contains('\\');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isBold
                        ? Colors.deepPurple.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        width: 4,
                        color: isBold
                            ? Colors.deepPurple
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            isBold ? Colors.deepPurple : Colors.grey,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: hasLatex
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Math.tex(
                                  displayText,
                                  textStyle: TextStyle(
                                    fontSize: isBold ? 16 : 14,
                                    fontWeight: isBold
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              )
                            : Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: isBold ? 16 : 14,
                                  fontWeight: isBold
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isBold
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red.shade50,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Error:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header image + back button
              Stack(
                children: [
                  Container(
                    width: deviceWidth,
                    height: deviceHeight * 1 / 6,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("lib/assets/images/header.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 25,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 25,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Integral Calculator",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Academic',
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              // Function input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _functionController,
                  decoration: const InputDecoration(
                    hintText: "Enter the function to integrate",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.functions),
                  ),
                ),
              ),

              // Lower limit + ∞ buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lowerLimitController,
                        decoration: const InputDecoration(
                          labelText: "Lower Limit",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 35,
                          child: ElevatedButton(
                            onPressed: () => _lowerLimitController.text = 'oo',
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('∞',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 50,
                          height: 35,
                          child: ElevatedButton(
                            onPressed: () => _lowerLimitController.text = '-oo',
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('-∞',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upper limit + ∞ buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _upperLimitController,
                        decoration: const InputDecoration(
                          labelText: "Upper Limit",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.keyboard_arrow_up),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 35,
                          child: ElevatedButton(
                            onPressed: () => _upperLimitController.text = 'oo',
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('∞',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 50,
                          height: 35,
                          child: ElevatedButton(
                            onPressed: () => _upperLimitController.text = '-oo',
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('-∞',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Calculate button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _calculateIntegral,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Calculating...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.calculate, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Calculate the Integral',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // Error message
              _buildErrorSection(),

              // Method chips
              _buildMethodChips(),

              // Result display
              if (_latexResult.isNotEmpty && _errorMessage == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome,
                                  color: Colors.green, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Result:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Math.tex(
                                _latexResult,
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Solution steps
              _buildStepsSection(),

              const SizedBox(height: 50),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _clearForm,
          backgroundColor: Colors.deepPurple,
          tooltip: 'Clear all inputs and results',
          child: const Icon(Icons.clear_all, color: Colors.white),
        ),
      ),
    );
  }
}
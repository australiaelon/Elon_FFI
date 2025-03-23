import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'bridge.dart' as ffi;

void main() {
  runApp(const SumCalculatorApp());
}

class SumCalculatorApp extends StatelessWidget {
  const SumCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Sum Calculator',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
        ),
      ),
      home: MainScreen(),
    );
  }
}

class SumResult {
  final int a;
  final int b;
  final int syncResult;
  final int asyncResult;
  final DateTime timestamp;

  SumResult({
    required this.a,
    required this.b,
    required this.syncResult,
    required this.asyncResult,
    required this.timestamp,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _firstNumberController = TextEditingController();
  final TextEditingController _secondNumberController = TextEditingController();
  bool _isCalculating = false;
  String? _errorMessage;
  final List<SumResult> _history = [];
  int _selectedSegment = 0;
  bool _isComparingResults = false;

  @override
  void dispose() {
    _firstNumberController.dispose();
    _secondNumberController.dispose();
    super.dispose();
  }

  void _resetInputs() {
    _firstNumberController.clear();
    _secondNumberController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _calculateSum() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    // Validate inputs
    if (_firstNumberController.text.isEmpty ||
        _secondNumberController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both numbers';
      });
      return;
    }

    int a, b;
    try {
      a = int.parse(_firstNumberController.text);
      b = int.parse(_secondNumberController.text);
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter valid integers';
      });
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final int syncResult = ffi.sum(a, b);
      setState(() {
        _isComparingResults = true;
      });

      final int asyncResult = await ffi.sumAsync(a, b);
      final newResult = SumResult(
        a: a,
        b: b,
        syncResult: syncResult,
        asyncResult: asyncResult,
        timestamp: DateTime.now(),
      );

      setState(() {
        _history.insert(0, newResult); // Add to the beginning of the list
        _isCalculating = false;
        _isComparingResults = false;
      });

      _showCompletionAnimation();

      Future.delayed(const Duration(milliseconds: 1000), () {
        _resetInputs();
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _isComparingResults = false;
        _errorMessage = 'Error calculating sum: ${e.toString()}';
      });
    }
  }

  void _showCompletionAnimation() {
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Sum Calculator'),
        trailing:
            _selectedSegment == 1 && _history.isNotEmpty
                ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Clear'),
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder:
                          (context) => CupertinoActionSheet(
                            title: const Text('Clear History'),
                            message: const Text(
                              'Are you sure you want to clear all calculation history?',
                            ),
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() {
                                    _history.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                isDestructiveAction: true,
                                child: const Text('Clear All'),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                    );
                  },
                )
                : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedSegment,
                thumbColor: CupertinoColors.systemBlue.withOpacity(0.2),
                backgroundColor: CupertinoColors.systemGrey6,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Calculator'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('History'),
                  ),
                },
                onValueChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedSegment = value;
                    });
                    HapticFeedback.selectionClick();
                  }
                },
              ),
            ),
            Expanded(
              child:
                  _selectedSegment == 0
                      ? _buildCalculatorView()
                      : _buildHistoryView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: _firstNumberController,
              placeholder: 'Enter first number',
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: false,
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(
                  CupertinoIcons.number_circle,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8.0),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _secondNumberController,
              placeholder: 'Enter second number',
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: false,
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(
                  CupertinoIcons.number_circle_fill,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8.0),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 14.0,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _isCalculating ? null : _calculateSum,
              child:
                  _isCalculating
                      ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                      : const Text('Calculate Sum'),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _resetInputs,
              child: const Text('Reset'),
            ),
            const SizedBox(height: 24),
            if (_isCalculating && _isComparingResults)
              _buildCalculationProgress(),
            if (_history.isNotEmpty && !_isCalculating) _buildLatestResult(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This app demonstrates Flutter FFI (Foreign Function Interface) capabilities by performing sum operations both synchronously and asynchronously.',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sync',
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '- Direct calculation',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Async',
                          style: TextStyle(
                            color: CupertinoColors.systemGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '- Using isolates for heavy work',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.check_mark,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Synchronous calculation complete',
                  style: TextStyle(color: CupertinoColors.systemGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 8),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Asynchronous calculation in progress...',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestResult() {
    final result = _history.first;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Result',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${result.a} + ${result.b} = ${result.syncResult}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  'Sync',
                  result.syncResult.toString(),
                  CupertinoColors.systemBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Async',
                  result.asyncResult.toString(),
                  CupertinoColors.systemGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_history.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.clock,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No calculations yet',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () {
                  setState(() {
                    _selectedSegment = 0;
                  });
                },
                child: const Text('Go to Calculator'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final result = _history[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${result.a} + ${result.b}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTime(result.timestamp),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResultCard(
                          'Sync',
                          result.syncResult.toString(),
                          CupertinoColors.systemBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildResultCard(
                          'Async',
                          result.asyncResult.toString(),
                          CupertinoColors.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today, ${_formatTimeOnly(dateTime)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTimeOnly(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTimeOnly(dateTime)}';
    }
  }

  String _formatTimeOnly(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

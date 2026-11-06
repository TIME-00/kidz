import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedReport = "daily"; //"daily"
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  Map<String, dynamic> _reportData = {};
  bool _loading = false;

  List<Map<String, dynamic>>? _top10List;
  bool _top10Loading = false;

  final Map<String, String> _reportOptions = {
    "daily": "Daily Sales",
    "monthly": "Monthly Sales",
    "yearly": "Yearly Sales",
    "top10": "Top 10 Best Selling Products",
  };

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    final currentUser = Supabase.instance.client.auth.currentUser;
    final myUserId = currentUser?.id ?? "";

    String dateOrMonth = "";
    if (_selectedReport == "daily") {
      dateOrMonth = _selectedDate;
    } else if (_selectedReport == "monthly") {
      dateOrMonth = _selectedMonth;
    } else {
      dateOrMonth = DateTime.now().year.toString();
    }

    final data = await generateAllInvolvingMeReport(
      reportType: _selectedReport,
      selectedDate: dateOrMonth,
      myUserId: myUserId,
    );

    setState(() {
      _loading = false;
      _reportData = data;
    });
  }

  Future<void> _fetchTop10() async {
    setState(() {
      _top10Loading = true;
      _top10List = null;
    });

    final currentUser = Supabase.instance.client.auth.currentUser;
    final myUserId = currentUser?.id ?? "";

    try {
      final data = await fetchTop10BestSellers(myUserId: myUserId);
      setState(() {
        _top10List = data;
      });
    } catch (e) {
      print("Error fetching top10: $e");
    } finally {
      setState(() {
        _top10Loading = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickMonthCustom(BuildContext context) async {
    final DateTime now = DateTime.now();
    final yearList = List.generate(10, (index) => now.year - 5 + index);
    int tempYear = now.year;
    int tempMonth = now.month;

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Year and Month'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: tempYear,
                    items: yearList.map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text(y.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => tempYear = val);
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: tempMonth,
                    items: List.generate(12, (index) => index + 1).map((m) {
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(m.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => tempMonth = val);
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(DateTime(tempYear, tempMonth));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedReport == "top10" && _top10List == null && !_top10Loading) {
      _fetchTop10();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        title: const Text("Sales Report",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedReport == "top10") {
      return _buildTop10Content();
    }

    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedReport,
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedReport = newValue;
                _reportData.clear();
                _top10List = null;
              });
            }
          },
          items: _reportOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (_selectedReport == "daily") ...[
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedDate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.purple),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_selectedReport == "monthly") ...[
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _pickMonthCustom(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedMonth,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.purple),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_selectedReport == "yearly") ...[
          SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                DateTime.now().year.toString(),
                style: const TextStyle(fontSize: 16, color: Colors.purple),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _loadReport,
            child: const Text(
              "Generate Report",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_loading) const CircularProgressIndicator(),
        if (!_loading && _reportData.isNotEmpty)
          Expanded(
            child: ListView(
              children: _reportData.entries.map((entry) {
                if (entry.key.endsWith("Involving Me")) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      ...entry.value.entries
                          .where((e) => e.key == "Sales")
                          .map((e) {
                        return _buildSection("Sales", e.value);
                      }).toList(),
                    ],
                  );
                }
                return const SizedBox();
              }).toList(),
            ),
          ),
        if (!_loading && _reportData.isEmpty)
          const Text("No sales data available."),
      ],
    );
  }

  // Top 10 界面
  Widget _buildTop10Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<String>(
          value: _selectedReport,
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedReport = newValue;
                _reportData.clear();
                _top10List = null;
              });
            }
          },
          items: _reportOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (_top10Loading)
          const Center(child: CircularProgressIndicator())
        else if (_top10List == null)
          const SizedBox()
        else if (_top10List!.isEmpty)
          const Text("No best selling products found.")
        else
          Expanded(
            child: ListView.builder(
              itemCount: _top10List!.length,
              itemBuilder: (context, index) {
                final product = _top10List![index];
                final productName = product['product_name'] as String;
                final productPrice = product['product_price'] as double;
                final quantitySold = product['quantity_sold'] as int;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                  "Price: RM${productPrice.toStringAsFixed(2)}"),
                              Text("Sold: $quantitySold"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String sectionName, dynamic sectionData) {
    if (sectionData is! Map) return const SizedBox();
    final dataMap = sectionData as Map<String, dynamic>;
    double total = 0.0;
    final totalKey =
        sectionName == "Purchases" ? "Total Purchases" : "Total Sales";
    if (dataMap.containsKey(totalKey)) {
      total = (dataMap[totalKey] ?? 0).toDouble();
    }
    final productEntries = dataMap.entries
        .where((entry) =>
            entry.key != "Total Purchases" && entry.key != "Total Sales")
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        if (productEntries.isEmpty)
          Text("No $sectionName found.")
        else
          ...productEntries.map((entry) {
            final itemMap = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                      "  - Individual Price: RM${itemMap['Individual Price']}"),
                  Text("  - Quantity: ${itemMap['Quantity Sold']}"),
                  Text("  - Total Price: RM${itemMap['Total Price']}"),
                ],
              ),
            );
          }),
        const SizedBox(height: 5),
        Text(
          "$totalKey: RM${total.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

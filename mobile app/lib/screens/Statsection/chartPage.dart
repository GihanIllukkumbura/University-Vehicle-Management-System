import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsPage extends StatefulWidget {
  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  final Stream<QuerySnapshot> refillingsStream = FirebaseFirestore.instance
      .collection('refillings')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('userfillings')
      .snapshots();

  String selectedMonth = '2024-06';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: selectedMonth,
              onChanged: (String? newValue) {
                setState(() {
                  selectedMonth = newValue!;
                });
              },
              items: <String>['2024-06', '2024-05', '2024-04']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: refillingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No data available'));
                }

                // Process data for charts
                var refillings = snapshot.data!.docs
                    .where((doc) {
                  var date = (doc['date'] as Timestamp).toDate();
                  var dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}';
                  return dateString == selectedMonth;
                })
                    .toList();
                refillings.sort((a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp));

                // Calculate total liters filled per day
                Map<String, double> litersFilledPerDay = {};
                refillings.forEach((refilling) {
                  var date = (refilling['date'] as Timestamp).toDate();
                  var dateString = '${date.year}-${date.month}-${date.day}';
                  litersFilledPerDay[dateString] = (litersFilledPerDay[dateString] ?? 0) + (refilling['liters'] as double);
                });

                // Calculate total cost over time
                List<double> totalCostOverTime = [];
                double runningTotal = 0;
                refillings.forEach((refilling) {
                  runningTotal += (refilling['liters'] as double) * (refilling['priceperliter'] as double);
                  totalCostOverTime.add(runningTotal);
                });

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Liters Filled Per Day',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      height: 300,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: refillings.isEmpty
                          ? Center(child: Text('No data available for the selected month'))
                          : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: litersFilledPerDay.isNotEmpty
                              ? litersFilledPerDay.values.reduce((value, element) => value > element ? value : element) + 5
                              : 0,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.blueAccent,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                String date = litersFilledPerDay.keys.toList()[group.x.toInt()];
                                return BarTooltipItem(
                                  '$date\n${rod.y.toString()} liters',
                                  TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: SideTitles(
                              showTitles: true,
                              getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                              margin: 20,
                              getTitles: (double value) {
                                // Get the corresponding date for each bar
                                if (value.toInt() < litersFilledPerDay.length) {
                                  return litersFilledPerDay.keys.toList()[value.toInt()];
                                }
                                return '';
                              },
                              reservedSize: 30, // Adjust as needed
                              interval: 1,
                            ),
                            topTitles: SideTitles(
                              showTitles: true,
                              getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                              margin: 20,
                              getTitles: (double value) {

                                return '';
                              },
                              reservedSize: 30, // Adjust as needed
                              interval: 1,
                            ),



                            leftTitles: SideTitles(
                              showTitles: true,
                              getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                              margin: 20,
                            ),
                            rightTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: litersFilledPerDay.isEmpty
                              ? []
                              : List.generate(
                            litersFilledPerDay.length,
                                (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(y: litersFilledPerDay.values.toList()[index], colors: [Colors.blue]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),



                    // Padding(
                    //   padding: const EdgeInsets.all(16.0),
                    //   child: Text(
                    //     'Total Cost Over Time',
                    //     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    //   ),
                    // ),
                    // Container(
                    //   height: 300,
                    //   padding: EdgeInsets.symmetric(horizontal: 16.0),
                    //   child: refillings.isEmpty
                    //       ? Center(child: Text('No data available for the selected month'))
                    //       : LineChart(
                    //     LineChartData(
                    //       titlesData: FlTitlesData(
                    //         show: true,
                    //         bottomTitles: SideTitles(
                    //           showTitles: true,
                    //           getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                    //           margin: 20,
                    //         ),
                    //         leftTitles: SideTitles(
                    //           showTitles: true,
                    //           getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                    //           margin: 20,
                    //         ),
                    //         rightTitles: SideTitles(
                    //           showTitles: false,
                    //         ),
                    //       ),
                    //       borderData: FlBorderData(show: false),
                    //       gridData: FlGridData(show: true),
                    //       lineBarsData: totalCostOverTime.isEmpty
                    //           ? []
                    //           : [
                    //         LineChartBarData(
                    //           spots: List.generate(
                    //             totalCostOverTime.length,
                    //                 (index) => FlSpot(index.toDouble(), totalCostOverTime[index]),
                    //           ),
                    //           isCurved: true,
                    //           colors: [Colors.blue],
                    //           barWidth: 4,
                    //           isStrokeCapRound: true,
                    //           dotData: FlDotData(show: false),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

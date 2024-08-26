// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:typed_data';

import 'package:SGMCS/providers/data-provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fullscreen_image_viewer/fullscreen_image_viewer.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  static String routeName = "/loan";

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  String formattedDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    DateFormat formatter = DateFormat.yMMMMd('en_US').add_jms();
    return formatter.format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    Provider.of<DataManagementProvider>(context, listen: false)
        .getDriverReport();
  }

  void showReportDetailsDialog(BuildContext context, dynamic report) {
    Uint8List? imageData;
    if (report['attachment'] != null) {
      imageData = base64Decode(report['attachment']);
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Report Details"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  "Driver name: ${report['driver']['username']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Description: ${report['description']}",
                ),
                SizedBox(height: 10),
                Text(
                  "Date Requested: ${formattedDate(report['created_at'])}",
                ),
                SizedBox(
                  height: 10,
                ),
                imageData != null
                    ? InkWell(
                        onTap: () {
                          FullscreenImageViewer.open(
                            context: context,
                            child: Hero(
                              tag: 'hero',
                              child: Image.memory(imageData!),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          height: 200,
                          child: Image.memory(
                            imageData,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Text("No attachment image")
                // Add more fields if needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Loan History",
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: Consumer<DataManagementProvider>(
          builder: (context, reportProvider, child) {
        if (reportProvider == null ||
            reportProvider.personalReportList == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportProvider.personalReportList.isEmpty) {
          return const Center(child: Text("No reports available"));
        }
        return ListView.builder(
          itemCount: reportProvider.personalReportList.length,
          itemBuilder: (context, index) {
            var report = reportProvider.personalReportList[index];
            return Card(
              child: ListTile(
                onTap: () {
                  showReportDetailsDialog(context, report);
                },
                title: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Driver name: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      TextSpan(
                        text: report['driver']['username'],
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Description: ",
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.black),
                          ),
                          TextSpan(
                            text: report['description'],
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Date Requested: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          TextSpan(
                            text: formattedDate(report['created_at']),
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

import 'dart:convert';

import 'package:SGMCS/providers/data-provider.dart';
import 'package:flutter/material.dart';
import 'package:fullscreen_image_viewer/fullscreen_image_viewer.dart';
import 'package:provider/provider.dart';

class AllReportScreen extends StatefulWidget {
  AllReportScreen({Key? key}) : super(key: key);

  @override
  State<AllReportScreen> createState() => _AllReportScreenState();
}

class _AllReportScreenState extends State<AllReportScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataManagementProvider>(context, listen: false).getAllReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "All Reports",
        style: TextStyle(color: Colors.black),
      )),
      body: Consumer<DataManagementProvider>(
        builder: (context, reportManagementProvider, child) {
          if (reportManagementProvider.allReportList.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: reportManagementProvider.allReportList.length,
                  itemBuilder: (context, index) {
                    final user = reportManagementProvider.allReportList[index];

                    // print('USER: ${user}');

                    String roleName = '';
                    switch (user['usertype']) {
                      case 'DRIVER':
                        roleName = 'Driver';
                        break;
                      case 'ADMIN':
                        roleName = 'Admin';
                        break;
                      default:
                        roleName = 'Unknown';
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: user['attachment'] != null
                            ? InkWell(
                                onTap: () {
                                  FullscreenImageViewer.open(
                                    context: context,
                                    child: Hero(
                                      tag: 'hero',
                                      child: Image.memory(
                                          base64Decode(user['attachment'])),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 32,
                                  child: Image.memory(
                                    base64Decode(user['attachment']),
                                  ),
                                ),
                              )
                            : Container(),
                        title:
                            Text("Name : ${user['driver']['name'] ?? 'N/A'}"),
                        subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Phone : ${user['driver']['phone'] ?? 'N/A'}"),
                              Text(
                                  "email : ${user['driver']['email'] ?? 'N/A'}"),

                              Text(
                                  'Description: ${user['description'] ?? 'N/A'}'),
                              // Text('Role: $roleName'),
                            ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}






























// // ignore_for_file: prefer_const_constructors

// import 'package:SGMCS/providers/data-provider.dart';
// import 'package:SGMCS/providers/user-provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class AllReportScreen extends StatefulWidget {
//   AllReportScreen({Key? key}) : super(key: key);

//   @override
//   State<AllReportScreen> createState() => _AllReportScreenState();
// }

// class _AllReportScreenState extends State<AllReportScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Provider.of<DataManagementProvider>(context, listen: false).getAllReport();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Users")),
//       body: Consumer<DataManagementProvider>(
//         builder: (context, reportManagementProvider, child) {
//           if (reportManagementProvider.allReportList) {
//             return Center(child: CircularProgressIndicator());
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Center(
//                     child: Text(
//                       "All Reports",
//                       style: TextStyle(
//                           fontSize: 32,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                           decoration: TextDecoration.underline,
//                           textBaseline: TextBaseline.ideographic),
//                     ),
//                   ),

                
//                   DataTable(
//                     showBottomBorder: true,
//                     showCheckboxColumn: true,
//                     headingTextStyle: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 24,
//                     ),
//                     headingRowHeight: 56,
//                     headingRowColor: MaterialStateProperty.resolveWith<Color?>(
//                         (Set<MaterialState> states) {
//                       if (states.contains(MaterialState.hovered)) {
//                         return Colors.blue.withOpacity(0.3);
//                       }
//                       return Colors.blue
//                           .withOpacity(0.3); // Use the default value.
//                     }),

//                     columns: const [
                     
//                       DataColumn(label: Text('Name')),
//                       DataColumn(label: Text('Email')),
//                       DataColumn(label: Text('Phone')),
//                       DataColumn(label: Text('Role')),
//                       // DataColumn(label: Text('Actions')),
//                     ],
//                     rows: reportManagementProvider.allReportList
//                         .map<DataRow>((user) {
//                       String roleName = '';
//                       switch (user['usertype']) {
//                         case 'DRIVER':
//                           roleName = 'Driver';
//                           break;
//                         case 'ADMIN':
//                           roleName = 'Admin';
//                           break;
//                         // Add other roles if needed
//                       }

//                       return DataRow(
//                         cells: [
//                           DataCell(
//                             Text(
//                               user['username'] ?? '',
//                               maxLines: 5,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           DataCell(Text(user['email'] ?? '')),
//                           DataCell(Text(user['phone'] ?? '')),
//                           DataCell(Text(user['usertype'])),
//                           // DataCell(
//                           //   IconButton(
//                           //     icon: Icon(Icons.delete),
//                           //     onPressed: () {
//                           //       // Add your delete functionality here
//                           //     },
//                           //   ),
//                           // ),
//                         ],
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// ignore_for_file: prefer_const_constructors

import 'package:SGMCS/providers/user-provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AllUsersScreen extends StatefulWidget {
  AllUsersScreen({Key? key}) : super(key: key);

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<UserManagementProvider>(context, listen: false).fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Users")),
      body: Consumer<UserManagementProvider>(
        builder: (context, userManagementProvider, child) {
          if (userManagementProvider.allUsers.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "All Users",
                      style: TextStyle(
                          fontSize: 32,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          textBaseline: TextBaseline.ideographic),
                    ),
                  ),
                  DataTable(
                    showBottomBorder: true,
                    showCheckboxColumn: true,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    headingRowHeight: 56,
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return Colors.blue.withOpacity(0.3);
                      }
                      return Colors.blue
                          .withOpacity(0.3); // Use the default value.
                    }),
                    columns: const [
                      // DataColumn(
                      //   label: Text(
                      //     'Name',
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.blue,
                      //       // fontSize: 16,
                      //     ),
                      //   ),
                      // ),
                      // DataColumn(
                      //   label: Text(
                      //     'Email',
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.blue,
                      //       // fontSize: 16,
                      //     ),
                      //   ),
                      // ),
                      // DataColumn(
                      //   label: Text(
                      //     'Phone',
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.blue,
                      //       // fontSize: 16,
                      //     ),
                      //   ),
                      // ),
                      // DataColumn(
                      //   label: Text(
                      //     'Role',
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.blue,
                      //       fontSize: 16,
                      //     ),
                      //   ),
                      // ),
                      // DataColumn(
                      //   label: Text(
                      //     'Actions',
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.blue,
                      //       fontSize: 16,
                      //     ),
                      //   ),
                      // ),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Role')),
                      // DataColumn(label: Text('Actions')),
                    ],
                    rows: userManagementProvider.allUsers.map<DataRow>((user) {
                      String roleName = '';
                      switch (user['usertype']) {
                        case 'DRIVER':
                          roleName = 'Driver';
                          break;
                        case 'ADMIN':
                          roleName = 'Admin';
                          break;
                        // Add other roles if needed
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              user['username'] ?? '',
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(Text(user['email'] ?? '')),
                          DataCell(Text(user['phone'] ?? '')),
                          DataCell(Text(roleName)),
                          // DataCell(
                          //   IconButton(
                          //     icon: Icon(Icons.delete),
                          //     onPressed: () {
                          //       // Add your delete functionality here
                          //     },
                          //   ),
                          // ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

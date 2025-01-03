// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, unused_element, use_build_context_synchronously, avoid_print, unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:io';
import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/shared-functions/snack_bar.dart';
import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
import 'package:flutter/material.dart';
import 'package:SGMCS/providers/data-provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wtf_sliding_sheet/wtf_sliding_sheet.dart';

class ReportForm extends StatefulWidget {
  @override
  _ReportFormState createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reporterNameController = TextEditingController();
  final TextEditingController _reporterPhoneController =
      TextEditingController();
  final TextEditingController _reportEmailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  int _activeStepIndex = 0;
  List<XFile>? _imageFiles = [];
  XFile? _imageFile;

  bool _isLoading = false;

  List<Step> stepList() => [
        Step(
          state: _activeStepIndex <= 0 ? StepState.editing : StepState.complete,
          isActive: _activeStepIndex >= 0,
          title: const Text(
            'Basic Information',
            style: TextStyle(fontFamily: 'Bebas', letterSpacing: 2),
          ),
          content: Container(
            child: Column(
              children: [
                TextField(
                  controller: _reporterNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Full Name',
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                TextField(
                  controller: _reportEmailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0))),
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                TextField(
                  controller: _reporterPhoneController,
                  keyboardType: TextInputType.phone,

                  // obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Phone',
                  ),
                ),
              ],
            ),
          ),
        ),
        Step(
            state:
                _activeStepIndex <= 1 ? StepState.editing : StepState.complete,
            isActive: _activeStepIndex >= 1,
            title: const Text(
              'Permit Information',
              style: TextStyle(
                fontFamily: 'Bebas',
                letterSpacing: 2,
              ),
            ),
            content: Container(
              child: Column(
                children: [
                  // const SizedBox(
                  //   height: 8,
                  // ),
                  // TextField(
                  //   controller: address,
                  //   decoration: const InputDecoration(
                  //     border: OutlineInputBorder(),
                  //     labelText: 'Present Address',
                  //   ),
                  // ),
                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            )),
        Step(
            state: StepState.complete,
            isActive: _activeStepIndex >= 2,
            title: const Text(
              'Confirm Details',
              style: TextStyle(
                fontFamily: 'Bebas',
                letterSpacing: 2,
              ),
            ),
            content: Container(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Text('Name: ${name.text}'),
                // Text('Email: ${email.text}'),
                // Text('Phone : ${phone.text}'),
                // Text('From : ${_selectedRegion}'),
                // Text('To : ${_selectedRegion2}'),
                // Text('Permit type : ${_selectedPermitType}'),
                // Text('Animal type : ${_selectedAnimalType}'),
                // Text('Total Cattle : ${total.text}'),
              ],
            )))
      ];

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _pickImage(ImageSource.gallery),
          child: Text('Select Image from Gallery'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _takePictureWithCamera(),
          child: Text('Take Picture with Camera'),
        ),
        SizedBox(height: 10),
        _imageFile != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(
                  File(_imageFile!.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            : Container(),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage;
      });
    }
  }

  Future<void> _takePictureWithCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? picture = await _picker.pickImage(source: ImageSource.camera);
    if (picture != null) {
      setState(() {
        _imageFile = picture;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  var userId;

  var usertype;
  getUserId() async {
    var sharedPref = SharedPreferencesManager();
    var localStorage = await sharedPref.getString(AppConstants.user);
    // print("User :: ${jsonDecode(user!)}");

    var user = jsonDecode(localStorage);
    setState(() {
      userId = user['id'];
      usertype = user['usertype'];
      print("user ID :: $userId");
      // _reporterNameController.text = user['username'];
      // _reportEmailController.text = user['email'];
      // _reporterPhoneController.text = user['phone'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complain Form',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _reporterNameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _reporterPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reporter phone';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _reportEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter report email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildImagePicker(),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  var image = await _imageFile!.readAsBytes();
                  var binaryImage = base64Encode(image);
                  if (_formKey.currentState!.validate()) {
                    var data = {
                      "reportername": _reporterNameController.text,
                      "reporterphone": _reporterPhoneController.text,
                      "reporteremail": _reportEmailController.text,
                      "attachment": binaryImage,
                      "description": _descriptionController.text,
                    };
                    Map<String, dynamic> result =
                        await Provider.of<DataManagementProvider>(context,
                                listen: false)
                            .complain(context, data);
                    print("Results :: ${result}");

                    if (result['status']) {
                      print("submited succesfuly  :: ${result}");
                      setState(() {
                        _isLoading = false;
                      });
                      ShowMToast(context).successToast(
                          message: "${result['msg']}",
                          alignment: Alignment.center);

                      Future.delayed(Duration(seconds: 3), () {
                        Navigator.pop(context);
                      });
                      // Navi
                    } else {
                      ShowMToast(context).errorToast(
                          message: "${result}", alignment: Alignment.center);
                      // print("Errors :: ${result}");
                      Future.delayed(Duration(seconds: 3), () {
                        Navigator.pop(context);
                      });
                      print("Errors :: ${result}");
                    }
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.green,
                      )
                    : Text('Submit'),
              ),
            ],
          ),
        ),

        // child: Form(
        //   key: _formKey,
        //   child: Column(
        //     children: [
        //       TextFormField(
        //         controller: _reporterNameController,
        //         decoration: InputDecoration(labelText: 'Name'),
        //         validator: (value) {
        //           if (value == null || value.isEmpty) {
        //             return 'Please enter your name';
        //           }
        //           return null;
        //         },
        //       ),
        //       TextFormField(
        //         controller: _reporterPhoneController,
        //         keyboardType: TextInputType.phone,
        //         decoration: InputDecoration(labelText: 'Phone'),
        //         validator: (value) {
        //           if (value == null || value.isEmpty) {
        //             return 'Please enter reporter phone';
        //           }
        //           return null;
        //         },
        //       ),
        //       TextFormField(
        //         controller: _reportEmailController,
        //         keyboardType: TextInputType.emailAddress,
        //         decoration: InputDecoration(labelText: 'Email'),
        //         validator: (value) {
        //           if (value == null || value.isEmpty) {
        //             return 'Please enter report email';
        //           }
        //           return null;
        //         },
        //       ),
        //       SizedBox(height: 20),
        //       // _image == null
        //       //     ? ElevatedButton(
        //       //         onPressed: () => _getImage(ImageSource.gallery),
        //       //         child: Text('Pick Image from Gallery'),
        //       //       )
        //       //     : Image.file(_image!),
        //       _buildImagePicker(),

        //       SizedBox(height: 20),
        //       TextFormField(
        //         controller: _descriptionController,
        //         keyboardType: TextInputType.multiline,
        //         maxLines: 3,
        //         decoration: InputDecoration(labelText: 'Description',),
        //         validator: (value) {
        //           if (value == null || value.isEmpty) {
        //             return 'Please enter description';
        //           }
        //           return null;
        //         },
        //       ),
        //       SizedBox(height: 20),
        //       ElevatedButton(
        //         onPressed: () async {
        //           var image = await _imageFile!.readAsBytes();

        //           var binaryImage = base64Encode(image);
        //           if (_formKey.currentState!.validate()) {
        //             // Form is valid, submit the data
        //             // You can access form fields using controllers like _reporterNameController.text, etc.
        //             // Also, access the image file using _image variable
        //             // Process the submitted data here
        //             var data = {
        //               "reportername": _reporterNameController.text,
        //               "reporterphone": _reporterPhoneController.text,
        //               "reporteremail": _reportEmailController.text,
        //               "attachment": binaryImage,
        //               "description": _descriptionController.text,
        //             };
        //             Map<String, dynamic> result =
        //                 await Provider.of<DataManagementProvider>(context,
        //                         listen: false)
        //                     .complain(context, data);
        //             if (result['status']) {
        //               print("submited succesfuly  :: ${result}");
        //             } else {
        //               print("Errors :: ${result}");
        //             }
        //           }
        //         },
        //         child: Text('Submit'),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}

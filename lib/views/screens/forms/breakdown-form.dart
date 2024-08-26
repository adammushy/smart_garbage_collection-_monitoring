// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/providers/data-provider.dart';
import 'package:SGMCS/shared-functions/snack_bar.dart';
import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class BreakDownForm extends StatefulWidget {
  const BreakDownForm({super.key});

  @override
  State<BreakDownForm> createState() => _BreakDownFormState();
}

class _BreakDownFormState extends State<BreakDownForm> {
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController total = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reporterNameController = TextEditingController();
  final TextEditingController _reporterPhoneController =
      TextEditingController();
  final TextEditingController _reportEmailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;

  int _activeStepIndex = 0;
  List<XFile>? _imageFiles = [];
  // = [];
  XFile? _imageFile;

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
                    border: OutlineInputBorder(),
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
              'Breakdown Information',
              style: TextStyle(
                fontFamily: 'Bebas',
                letterSpacing: 2,
              ),
            ),
            content: Container(
              child: Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  TextField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    // obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _buildImagePicker(),
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
                Text('Name: ${_reporterNameController.text}'),
                Text('Email: ${_reportEmailController.text}'),
                Text('Phone : ${_reporterPhoneController.text}'),
                Text('Description : ${_descriptionController.text}'),
              ],
            ),
          ),
        ),
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
      _reporterNameController.text = user['username'];
      _reportEmailController.text = user['email'];
      _reporterPhoneController.text = user['phone'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakdown Form'),
      ),
      body: Stepper(
        currentStep: _activeStepIndex,
        steps: stepList(),
        onStepContinue: () async {
          if (_activeStepIndex < (stepList().length - 1)) {
            setState(() {
              _activeStepIndex += 1;
            });
          } else {
            var image = await _imageFile!.readAsBytes();
            var binaryImage = base64Encode(image);
            print("Image :: $binaryImage");

            // Form is valid, submit the data
            // You can access form fields using controllers like _reporterNameController.text, etc.
            // Also, access the image file using _image variable
            // Process the submitted data here
            var data = {
              "driver": userId,
              "attachment": binaryImage,
              "description": _descriptionController.text,
            };
            Map<String, dynamic> result =
                await Provider.of<DataManagementProvider>(context,
                        listen: false)
                    .report(context, data);
            if (result['status']) {
              print("submited succesfuly  :: ${result}");
              ShowMToast(context).successToast(
                  message: "${result['msg']}", alignment: Alignment.center);
              Navigator.pop(context);
            } else {
              ShowMToast(context).errorToast(
                  message: "${result}", alignment: Alignment.center);
              print("Errors :: ${result}");
            }
          }
        },
        onStepCancel: () {
          if (_activeStepIndex > 0) {
            setState(() {
              _activeStepIndex -= 1;
            });
          }
        },
        onStepTapped: (int index) {
          setState(() {
            _activeStepIndex = index;
          });
        },
      ),
    );
  }
}

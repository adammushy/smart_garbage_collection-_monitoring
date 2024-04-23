import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_project_template/providers/data-provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Form'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _reporterNameController,
                decoration: InputDecoration(labelText: 'Reporter Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reporter name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _reporterPhoneController,
                decoration: InputDecoration(labelText: 'Reporter Phone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reporter phone';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _reportEmailController,
                decoration: InputDecoration(labelText: 'Report Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter report email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _image == null
                  ? ElevatedButton(
                      onPressed: () => _getImage(ImageSource.gallery),
                      child: Text('Pick Image from Gallery'),
                    )
                  : Image.file(_image!),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
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
                  var image = await _image!.readAsBytes();

                  var binaryImage = base64Encode(image);
                  if (_formKey.currentState!.validate()) {
                    // Form is valid, submit the data
                    // You can access form fields using controllers like _reporterNameController.text, etc.
                    // Also, access the image file using _image variable
                    // Process the submitted data here
                    var data = {
                      "reportername": _reporterNameController.text,
                      "reporterphone": _reporterPhoneController.text,
                      "reporteremail": _reportEmailController.text,
                      "attachment": binaryImage,
                      "description": _descriptionController.text,
                    };
                    Map<String, dynamic> result =
                        await Provider.of<DataManagementProvider>(context,listen: false)
                            .complain(context, data);
                    if (result['status']) {
                      print("submited succesfuly  :: ${result}");
                    } else {
                      print("Errors :: ${result}");
                    }
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

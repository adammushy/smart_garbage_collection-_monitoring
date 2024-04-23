import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_project_template/providers/user-provider.dart';
import 'package:flutter_project_template/shared-functions/snack_bar.dart';
import 'package:flutter_project_template/views/screens/auth/register_user.dart';
import 'package:flutter_project_template/views/screens/maps/citizenmap.dart';
import 'package:flutter_project_template/views/screens/maps/driversMap2.dart';
import 'package:flutter_project_template/views/screens/maps/driversmap.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({
    Key? key,
  }) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodePassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  bool _obscurePassword = true;
  // final Box _boxLogin = Hive.box("login");
  // final Box _boxAccounts = Hive.box("accounts");

  @override
  Widget build(BuildContext context) {
    // if (_boxLogin.get("loginStatus") ?? false) {
    //   return Home();
    // }

    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 150),
              Text(
                "Welcome back",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                "Login to your account",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 60),
              TextFormField(
                controller: _controllerUsername,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodePassword.requestFocus(),
                // validator: (String? value) {
                //   if (value == null || value.isEmpty) {
                //     return "Please enter username.";
                //   } else if (!_boxAccounts.containsKey(value)) {
                //     return "Username is not registered.";
                //   }

                //   return null;
                // },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerPassword,
                focusNode: _focusNodePassword,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: _obscurePassword
                          ? const Icon(Icons.visibility_outlined)
                          : const Icon(Icons.visibility_off_outlined)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // validator: (String? value) {
                //   if (value == null || value.isEmpty) {
                //     return "Please enter password.";
                //   } else if (value !=
                //       _boxAccounts.get(_controllerUsername.text)) {
                //     return "Wrong password.";
                //   }

                //   return null;
                // },
              ),
              const SizedBox(height: 60),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      // bool validate = _formKey.currentState!.validate();
                      // if (validate) {
                      //   var data = {
                      //     "email": _controllerUsername.text,
                      //     "password": _controllerPassword.text
                      //   };
                      //   print(data);
                      //   Map<String, dynamic> result =
                      //       await Provider.of<UserManagementProvider>(context,
                      //               listen: false)
                      //           .userLogin(data, context);
                      //   print("result :: ${result['usertype']}");

                      //   if (result['usertype'] == 'DRIVER') {
                      //     Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (context) => DriversMap()));
                      //     ShowMToast(context).successToast(
                      //         message: "Successfully log in",
                      //         alignment: Alignment.bottomCenter);
                      //   } else {
                      //     ShowMToast(context).successToast(
                      //         message:
                      //             "Thank you for login but you can't user this platform",
                      //         alignment: Alignment.bottomCenter);
                      //     _controllerUsername.clear();
                      //     _controllerPassword.clear();
                      //   }
                      // }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DriversMap()));
                    },
                    child: const Text("Login"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          _formKey.currentState?.reset();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const Signup();
                              },
                            ),
                          );
                        },
                        child: const Text("Signup"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Align(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("If you are normal citizen "),
                        TextButton(
                          onPressed: () {
                            _formKey.currentState?.reset();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return CitizenMap();
                                },
                              ),
                            );
                          },
                          child: const Text("Proceed"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodePassword.dispose();
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}

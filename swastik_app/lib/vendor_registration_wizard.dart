// lib/screens/vendor_registration_wizard.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VendorRegistrationWizard extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorRegistrationWizard({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorRegistrationWizard> createState() =>
      _VendorRegistrationWizardState();
}

class _VendorRegistrationWizardState extends State<VendorRegistrationWizard> {
  final Color primaryColor = const Color(0xFFE55836);

  // Form Keys
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Step 1 controllers
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  String? selectedCategory;
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Step 2 controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Step 3 docs
  File? businessLicenseFile;
  File? additionalDocFile;
  final TextEditingController gstinController = TextEditingController();

  // Step 4 portfolio
  final ImagePicker _picker = ImagePicker();
  List<File> portfolioImages = [];
  final List<String> selectedServices = [];

  final List<String> servicesList = [
    "Event Planning",
    "On-site Coordination",
    "Custom Packages",
    "Premium Service",
    "Budget-friendly Options",
    "Emergency Support",
  ];

  bool agreeTerms = false;
  bool loading = false;

  int currentStep = 0;

  static const String baseIp = "http://10.240.92.1:5000";
  String get vendorsBase => "$baseIp/api/vendors";

  @override
  void initState() {
    super.initState();
    ownerNameController.text = widget.vendorName;
    _loadVendorFromServer();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") ?? "";
  }

  // ================= LOAD VENDOR DATA ======================
  Future<void> _loadVendorFromServer() async {
    try {
      final res = await http.get(Uri.parse("$vendorsBase/${widget.vendorId}"));
      if (res.statusCode == 200) {
        final v = jsonDecode(res.body)["vendor"] ?? {};

        setState(() {
          businessNameController.text = v["businessName"] ?? "";
          ownerNameController.text = v["ownerName"] ?? widget.vendorName;

          // ✔ FIX: Safe dropdown category
          final category = v["category"];
          final validCategories = [
            "Catering",
            "Decoration",
            "Photography",
            "Venue",
            "Pandit",
            "Makeup"
          ];
          selectedCategory =
          validCategories.contains(category) ? category : null;

          experienceController.text = v["experience"] ?? "";
          descriptionController.text = v["description"] ?? "";

          phoneController.text = v["phone"] ?? "";
          addressController.text = v["address"] ?? "";
          cityController.text = v["city"] ?? "";
          stateController.text = v["state"] ?? "";
          pincodeController.text = v["pincode"] ?? "";
          emailController.text = v["email"] ?? "";

          gstinController.text = v["gstin"] ?? "";
        });
      }
    } catch (_) {}
  }

  // ================= PICKERS (FIXED) ======================
  Future pickLicense() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => businessLicenseFile = File(f.path));
  }

  Future pickDoc() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => additionalDocFile = File(f.path));
  }

  Future pickPortfolio() async {
    final p = await _picker.pickMultiImage();
    // pickMultiImage returns a (possibly empty) List<XFile> on null-safety
    if (p.isNotEmpty) {
      setState(() {
        portfolioImages = p.take(6).map((e) => File(e.path)).toList();
      });
    }
  }

  // ================= STEP 1 ======================
  Future<bool> submitStep1() async {
    if (!_formKeyStep1.currentState!.validate()) return false;

    setState(() => loading = true);

    try {
      final token = await _getToken();

      final res = await http.put(
        Uri.parse("$vendorsBase/register/details/${widget.vendorId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "businessName": businessNameController.text.trim(),
          "ownerName": ownerNameController.text.trim(),
          "category": selectedCategory,
          "experience": experienceController.text.trim(),
          "description": descriptionController.text.trim(),
        }),
      );

      if (res.statusCode == 200) return true;
      show('Step 1 failed: ${res.statusCode}');
      return false;
    } catch (e) {
      show("Step 1 Error: $e");
      return false;
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= STEP 2 ======================
  Future<bool> submitStep2() async {
    if (!_formKeyStep2.currentState!.validate()) return false;

    setState(() => loading = true);

    try {
      final token = await _getToken();

      final res = await http.put(
        Uri.parse("$vendorsBase/register/contact/${widget.vendorId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "phone": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "address": addressController.text.trim(),
          "city": cityController.text.trim(),
          "state": stateController.text.trim(),
          "pincode": pincodeController.text.trim(),
        }),
      );

      if (res.statusCode == 200) return true;

      // If endpoint not found, try alternative: PUT without id and id in body
      if (res.statusCode == 404) {
        try {
          final altRes = await http.put(
            Uri.parse("$vendorsBase/register/contact"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "vendorId": widget.vendorId,
              "phone": phoneController.text.trim(),
              "email": emailController.text.trim(),
              "address": addressController.text.trim(),
              "city": cityController.text.trim(),
              "state": stateController.text.trim(),
              "pincode": pincodeController.text.trim(),
            }),
          );

          if (altRes.statusCode == 200) return true;
          final altBody = altRes.body;
          show('Step 2 failed (alt): ${altRes.statusCode} ${altBody.isNotEmpty ? '- ' + altBody : ''}');
          return false;
        } catch (e) {
          show('Step 2 retry error: $e');
          return false;
        }
      }

      try {
        final body = res.body;
        show('Step 2 failed: ${res.statusCode} ${body.isNotEmpty ? '- ' + body : ''}');
      } catch (_) {
        show('Step 2 failed: ${res.statusCode}');
      }
      return false;
    } catch (e) {
      show("Step 2 Error: $e");
      return false;
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= STEP 3 ======================
  Future<bool> submitStep3() async {
    setState(() => loading = true);

    try {
      final token = await _getToken();

      final req = http.MultipartRequest(
        "PUT",
        Uri.parse("$vendorsBase/register/documents/${widget.vendorId}"),
      );

      req.headers["Authorization"] = "Bearer $token";
      req.fields["gstin"] = gstinController.text.trim();

      if (businessLicenseFile != null) {
        req.files.add(await http.MultipartFile.fromPath(
            "businessLicense", businessLicenseFile!.path));
      }

      if (additionalDocFile != null) {
        req.files.add(await http.MultipartFile.fromPath(
            "additionalDoc", additionalDocFile!.path));
      }

      final resp = await req.send();
      if (resp.statusCode == 200) return true;
      // try to extract body for additional info
      try {
        final body = await resp.stream.bytesToString();
        show('Step 3 failed: ${resp.statusCode} ${body.isNotEmpty ? '- ' + body : ''}');
      } catch (_) {
        show('Step 3 failed: ${resp.statusCode}');
      }
      return false;
    } catch (e) {
      show("Step 3 Error: $e");
      return false;
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= STEP 4 ======================
  Future<bool> submitStep4() async {
    if (portfolioImages.isEmpty) {
      show("Upload at least 1 portfolio image");
      return false;
    }
    if (selectedServices.isEmpty) {
      show("Select at least one service");
      return false;
    }

    setState(() => loading = true);

    try {
      final token = await _getToken();

      final req = http.MultipartRequest(
        "PUT",
        Uri.parse("$vendorsBase/register/portfolio/${widget.vendorId}"),
      );

      req.headers["Authorization"] = "Bearer $token";
      req.fields["services"] = jsonEncode(selectedServices);

      for (var img in portfolioImages) {
        req.files.add(
            await http.MultipartFile.fromPath("portfolio", img.path));
      }

      final resp = await req.send();
      if (resp.statusCode == 200) return true;
      try {
        final body = await resp.stream.bytesToString();
        show('Step 4 failed: ${resp.statusCode} ${body.isNotEmpty ? '- ' + body : ''}');
      } catch (_) {
        show('Step 4 failed: ${resp.statusCode}');
      }
      return false;
    } catch (e) {
      show("Step 4 Error: $e");
      return false;
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= STEP 5 ======================
  Future<bool> submitFinal() async {
    if (!agreeTerms) {
      show("Agree to Terms & Conditions");
      return false;
    }

    setState(() => loading = true);

    try {
      final token = await _getToken();

      final res = await http.post(
        Uri.parse("$vendorsBase/register/submit/${widget.vendorId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) return true;

      // If endpoint not found, try common alternative: POST without id and id in body
      if (res.statusCode == 404) {
        try {
          final altRes = await http.post(
            Uri.parse("$vendorsBase/register/submit"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"vendorId": widget.vendorId}),
          );
          if (altRes.statusCode == 200) return true;
          final altBody = altRes.body;
          show('Submit failed (alt): ${altRes.statusCode} ${altBody.isNotEmpty ? '- ' + altBody : ''}');
          return false;
        } catch (e) {
          show('Submit retry error: $e');
          return false;
        }
      }

      // show server response when submit fails for other status codes
      try {
        final body = res.body;
        show('Submit failed: ${res.statusCode} ${body.isNotEmpty ? '- ' + body : ''}');
      } catch (_) {
        show('Submit failed: ${res.statusCode}');
      }
      return false;
    } catch (e) {
      show("Final Submit Error: $e");
      return false;
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI HELPERS ======================
  void show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration input(String h) {
    return InputDecoration(
      hintText: h,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget uploadButton(Function() pick) {
    return ElevatedButton.icon(
      onPressed: pick,
      icon: const Icon(Icons.upload),
      label: const Text("Upload"),
    );
  }

  Widget preview(File file, Function() onRemove) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        right: 5,
        top: 5,
        child: InkWell(
          onTap: onRemove,
          child: const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.black54,
            child: Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      )
    ],
  );

  Widget addPortfolioBox(Function() pick) => GestureDetector(
    onTap: pick,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Icon(Icons.cloud_upload),
    ),
  );

  Widget reviewRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(
          flex: 3,
          child: Text("$k:",
              style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(flex: 5, child: Text(v.isNotEmpty ? v : "-")),
    ]),
  );

  Widget header(String t, String s, IconData i) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(i, color: Colors.orange, size: 26),
        const SizedBox(width: 8),
        Text(t,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600)),
      ]),
      Text(s, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 12),
    ],
  );

  // ===========================================================
  // ===================== BUILD ===============================
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    final steps = [
      // STEP 1
      Step(
        title: const Text("Business"),
        content: Form(
          key: _formKeyStep1,
          child: Column(
            children: [
              header("Business Details", "Tell us about your business",
                  Icons.apartment),
              TextFormField(
                  controller: businessNameController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  decoration: input("Business Name")),
              const SizedBox(height: 12),
              TextFormField(
                  controller: ownerNameController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  decoration: input("Owner Name")),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                initialValue: selectedCategory,
                items: [
                  "Catering",
                  "Decoration",
                  "Photography",
                  "Venue",
                  "Pandit",
                  "Makeup"
                ]
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (String? v) => setState(() => selectedCategory = v),
                decoration: input("Category"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: experienceController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  keyboardType: TextInputType.number,
                  decoration: input("Experience")),
              const SizedBox(height: 12),
              TextFormField(
                  controller: descriptionController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  minLines: 2,
                  maxLines: 4,
                  decoration: input("Description")),
            ],
          ),
        ),
        isActive: currentStep == 0,
        state: currentStep > 0 ? StepState.complete : StepState.indexed,
      ),

      // STEP 2
      Step(
        title: const Text("Contact"),
        content: Form(
          key: _formKeyStep2,
          child: Column(
            children: [
              header("Contact Details", "How customers reach you",
                  Icons.phone),
              TextFormField(
                  controller: phoneController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  decoration: input("Phone")),
              const SizedBox(height: 12),
              TextFormField(
                  controller: emailController,
                  validator: (v) => v!.contains("@") ? null : "Invalid Email",
                  decoration: input("Email")),
              const SizedBox(height: 12),
              TextFormField(
                  controller: addressController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  decoration: input("Address")),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: cityController,
                          validator: (v) =>
                          v!.isEmpty ? "Required" : null,
                          decoration: input("City"))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextFormField(
                          controller: stateController,
                          validator: (v) =>
                          v!.isEmpty ? "Required" : null,
                          decoration: input("State"))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: pincodeController,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  keyboardType: TextInputType.number,
                  decoration: input("Pincode")),
            ],
          ),
        ),
        isActive: currentStep == 1,
        state: currentStep > 1 ? StepState.complete : StepState.indexed,
      ),

      // STEP 3
      Step(
        title: const Text("Documents"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header("Upload Documents", "GST, License, etc.",
                Icons.document_scanner),
            TextFormField(
                controller: gstinController,
                decoration: input("GSTIN (Optional)")),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text("Business License"),
                      const SizedBox(height: 8),
                      businessLicenseFile == null
                          ? uploadButton(pickLicense)
                          : preview(businessLicenseFile!, () {
                        setState(() => businessLicenseFile = null);
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      const Text("Additional Doc"),
                      const SizedBox(height: 8),
                      additionalDocFile == null
                          ? uploadButton(pickDoc)
                          : preview(additionalDocFile!, () {
                        setState(() => additionalDocFile = null);
                      }),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
        isActive: currentStep == 2,
        state: currentStep > 2 ? StepState.complete : StepState.indexed,
      ),

      // STEP 4
      Step(
        title: const Text("Portfolio"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header("Portfolio & Services", "Show your work",
                Icons.photo_library),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8),
              itemBuilder: (c, i) {
                if (i < portfolioImages.length) {
                  return preview(portfolioImages[i], () {
                    setState(() => portfolioImages.removeAt(i));
                  });
                }
                return addPortfolioBox(pickPortfolio);
              },
            ),
            const SizedBox(height: 12),
            const Text("Services You Offer"),
            ...servicesList.map((s) {
              bool sel = selectedServices.contains(s);
              return CheckboxListTile(
                value: sel,
                activeColor: primaryColor,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedServices.add(s);
                    } else {
                      selectedServices.remove(s);
                    }
                  });
                },
                title: Text(s),
              );
            })
          ],
        ),
        isActive: currentStep == 3,
        state: currentStep > 3 ? StepState.complete : StepState.indexed,
      ),

      // STEP 5
      Step(
        title: const Text("Review"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header("Review & Submit",
                "Verify before final submission",
                Icons.check_circle_outline),
            reviewRow("Business Name", businessNameController.text),
            reviewRow("Owner", ownerNameController.text),
            reviewRow("Category", selectedCategory ?? "-"),
            reviewRow("Experience", experienceController.text),
            reviewRow("Phone", phoneController.text),
            reviewRow("Email", emailController.text),
            reviewRow("Location",
                "${cityController.text}, ${stateController.text}"),

            const SizedBox(height: 10),
            const Text("Portfolio Preview"),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: portfolioImages
                    .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      f,
                      height: 100,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Checkbox(
                    value: agreeTerms,
                    activeColor: primaryColor,
                    onChanged: (v) {
                      setState(() => agreeTerms = v!);
                    }),
                const Expanded(
                    child: Text(
                        "I agree to Terms & Conditions and Privacy Policy.")),
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                bool ok = await submitFinal();
                if (ok) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Submitted"),
                      content: const Text(
                          "Your application is under review."),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text("OK"))
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Application",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        isActive: currentStep == 4,
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Registration"),
        backgroundColor: primaryColor,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: currentStep,
        steps: steps,
        onStepContinue: () async {
          if (currentStep < 4) {
            bool ok = false;

            // STEP 1: Attempt server save, but allow local progression if form valid
            if (currentStep == 0) {
              ok = await submitStep1();
              if (!ok) {
                if (_formKeyStep1.currentState != null && _formKeyStep1.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally — could not save to server. Continuing.')));
                  ok = true;
                }
              }
            }

            // STEP 2: Attempt server save, fallback to local progression when form valid
            if (currentStep == 1) {
              ok = await submitStep2();
              if (!ok) {
                if (_formKeyStep2.currentState != null && _formKeyStep2.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally — could not save to server. Continuing.')));
                  ok = true;
                }
              }
            }

            // STEP 3: Attempt document upload. If upload fails, allow progression
            // when user has provided at least GSTIN or one document.
            if (currentStep == 2) {
              ok = await submitStep3();
              if (!ok) {
                if (gstinController.text.trim().isNotEmpty || businessLicenseFile != null || additionalDocFile != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally — could not upload documents. Continuing.')));
                  ok = true;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a document or enter GSTIN.')));
                }
              }
            }

            // STEP 4: Attempt portfolio upload. If upload fails, allow progression
            // when portfolio images and services are present locally.
            if (currentStep == 3) {
              ok = await submitStep4();
              if (!ok) {
                if (portfolioImages.isNotEmpty && selectedServices.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally — could not upload portfolio. Continuing.')));
                  ok = true;
                }
              }
            }

            if (ok) {
              setState(() => currentStep++);
            }
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() => currentStep--);
          }
        },
      ),
    );
  }
}

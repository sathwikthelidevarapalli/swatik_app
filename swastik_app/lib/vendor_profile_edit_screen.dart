// Part 1/3 - Imports + state + init + loaders
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class VendorProfileEditScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorProfileEditScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorProfileEditScreen> createState() =>
      _VendorProfileEditScreenState();
}

class _VendorProfileEditScreenState extends State<VendorProfileEditScreen>
    with SingleTickerProviderStateMixin {
  static const baseIp = "http://10.240.92.1:5000";

  late TabController tabController;

  // Basic controllers
  final businessC = TextEditingController();
  final categoryC = TextEditingController();
  final locationC = TextEditingController();
  final phoneC = TextEditingController();
  final descC = TextEditingController();

  bool loading = true;

  // Gallery state
  List<dynamic> gallery = [];
  bool galleryLoading = false;

  // Packages state
  List<dynamic> packages = [];
  bool packagesLoading = false;

  // Verification state
  Map<String, dynamic> verification = {};
  bool verificationLoading = false;

  // Availability state
  bool availabilityLoading = false;
  DateTime selectedDate = DateTime.now();
  List<String> unavailable = []; // vendor unavailable days (ISO 'yyyy-MM-dd')
  List<String> booked = []; // booked dates (optional)
  // Local UI map for per-date status: 'available' | 'unavailable' | 'half'
  Map<String, String> dateStatus = {}; // key = 'yyyy-MM-dd'

  final ImagePicker _picker = ImagePicker();

  // Pricing UI state
  bool showAddPackageScreen = false;
  final TextEditingController pkgNameC = TextEditingController();
  final TextEditingController pkgPriceC = TextEditingController();
  final TextEditingController pkgDescC = TextEditingController();
  List<TextEditingController> featureControllers = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    await Future.wait([
      _loadProfile(),
      _loadGallery(),
      _loadPackages(),
      _loadVerification(),
      _loadAvailability(),
    ]);
    setState(() => loading = false);
  }

  // ----------------------------
  // BASIC PROFILE
  // ----------------------------
  Future<void> _loadProfile() async {
    try {
      final res = await http
          .get(Uri.parse("$baseIp/api/vendors/profile/${widget.vendorId}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        businessC.text = data["businessName"] ?? "";
        categoryC.text = data["category"] ?? "";
        locationC.text = data["location"] ?? "";
        phoneC.text = data["phone"] ?? "";
        descC.text = data["description"] ?? "";
      }
    } catch (e) {
      debugPrint("Load profile error: $e");
    }
  }

  Future<void> _saveProfile() async {
    final body = jsonEncode({
      "businessName": businessC.text.trim(),
      "category": categoryC.text.trim(),
      "location": locationC.text.trim(),
      "phone": phoneC.text.trim(),
      "description": descC.text.trim(),
    });

    try {
      final res = await http.put(
        Uri.parse("$baseIp/api/vendors/profile/basic/${widget.vendorId}"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile updated")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Update failed")));
      }
    } catch (e) {
      debugPrint("Save profile error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Update error")));
    }
  }

  // ----------------------------
  // GALLERY
  // ----------------------------
  Future<void> _loadGallery() async {
    setState(() => galleryLoading = true);
    try {
      final res = await http
          .get(Uri.parse("$baseIp/api/vendors/gallery/${widget.vendorId}"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        gallery = data["photos"] ?? [];
      }
    } catch (e) {
      debugPrint("Gallery load error: $e");
    }
    setState(() => galleryLoading = false);
  }

  Future<void> _uploadPhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseIp/api/vendors/gallery/upload/${widget.vendorId}"),
      );
      req.files.add(await http.MultipartFile.fromPath("photo", picked.path));
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        await _loadGallery();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Upload failed")));
      }
    } catch (e) {
      debugPrint("Upload photo error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Upload error")));
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseIp/api/vendors/gallery/delete/$photoId"),
      );
      if (res.statusCode == 200) {
        await _loadGallery();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Delete failed")));
      }
    } catch (e) {
      debugPrint("Delete photo error: $e");
    }
  }

// Part 2/3 - Packages UI + gallery UI + packages load/save
  // ----------------------------
  // PACKAGES (PRICING)
  // ----------------------------
  Future<void> _loadPackages() async {
    setState(() => packagesLoading = true);
    try {
      final res = await http
          .get(Uri.parse("$baseIp/api/vendors/packages/${widget.vendorId}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        packages = data["packages"] ?? [];
      }
    } catch (e) {
      debugPrint("Packages load error: $e");
    }
    setState(() => packagesLoading = false);
  }

  Future<void> _deletePackage(String packageId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseIp/api/vendors/packages/$packageId"),
      );
      if (res.statusCode == 200) {
        await _loadPackages();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Delete failed")));
      }
    } catch (e) {
      debugPrint("Delete package error: $e");
    }
  }

  // ----------------------------
  // VERIFICATION
  // ----------------------------
  Future<void> _loadVerification() async {
    setState(() => verificationLoading = true);
    try {
      final res = await http
          .get(
          Uri.parse("$baseIp/api/vendors/verification/${widget.vendorId}"));
      if (res.statusCode == 200) {
        verification = jsonDecode(res.body) ?? {};
      }
    } catch (e) {
      debugPrint("Verification load error: $e");
    }
    setState(() => verificationLoading = false);
  }

  Future<void> _uploadDocument(String docType) async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery); // allow images for docs
      if (picked == null) return;

      final req = http.MultipartRequest(
        "POST",
        Uri.parse(
            "$baseIp/api/vendors/verification/upload/${widget
                .vendorId}/$docType"),
      );
      req.files.add(await http.MultipartFile.fromPath("file", picked.path));
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        await _loadVerification();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Uploaded")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Upload failed")));
      }
    } catch (e) {
      debugPrint("Doc upload error: $e");
    }
  }

  // ----------------------------
  // AVAILABILITY
  // ----------------------------
  Future<void> _loadAvailability() async {
    setState(() => availabilityLoading = true);
    try {
      final res = await http
          .get(
          Uri.parse("$baseIp/api/vendors/availability/${widget.vendorId}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data["unavailable"] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
            [];
        unavailable = list;
        // Reset local dateStatus and mark unavailable dates
        dateStatus = {};
        for (final d in unavailable) {
          dateStatus[d] = 'unavailable';
        }
      }
    } catch (e) {
      debugPrint("Availability load error: $e");
    }
    setState(() => availabilityLoading = false);
  }

  Future<void> _addUnavailableDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    final iso = DateFormat('yyyy-MM-dd').format(picked);

    try {
      final res = await http.post(
        Uri.parse("$baseIp/api/vendors/availability/${widget.vendorId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": iso}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _loadAvailability();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to add date")));
      }
    } catch (e) {
      debugPrint("Add unavailable date error: $e");
    }
  }

  Future<void> _removeUnavailableDate(String date) async {
    try {
      final encDate = Uri.encodeComponent(date);
      final res = await http.delete(Uri.parse(
          "$baseIp/api/vendors/availability/${widget.vendorId}/$encDate"));
      if (res.statusCode == 200) {
        await _loadAvailability();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to remove")));
      }
    } catch (e) {
      debugPrint("Remove unavailable date error: $e");
    }
  }

  // ----------------------------
  // UI BUILD
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _basicTab(),
                _galleryTab(),
                _pricingTab(),
                _verifyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Header & Tabs (UI similar to screenshot)
  // ----------------------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFF5C00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "Profile Management",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: 0.75,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.black),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.orange,
        onTap: (i) {
          // no-op
        },
        tabs: const [
          Tab(text: "Basic"),
          Tab(text: "Gallery"),
          Tab(text: "Pricing"),
          Tab(text: "Verify"),
        ],
      ),
    );
  }

  // ----------------------------
  // BASIC TAB
  // ----------------------------
  Widget _basicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _cardContainer(children: [
          _field("Business Name", businessC),
          _field("Category", categoryC),
          _field("Location", locationC),
          _field("Phone", phoneC),
          _field("Description", descC, maxLines: 3),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Save Changes"),
          ),
        ),
      ]),
    );
  }

  Widget _cardContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              maxLines: maxLines,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ]),
    );
  }

  // ----------------------------
  // GALLERY TAB
  // ----------------------------
  Widget _galleryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Photo Gallery",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A00),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${gallery.length} photos",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              galleryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gallery.length + 1,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  if (i == gallery.length) return _addPhotoTile();
                  final g = gallery[i];
                  final url = g["url"] ?? "";
                  final id = g["_id"] ?? "";
                  return _photoTile(url, id);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _tipCard("Vendors with 6+ photos get 40% more bookings!"),
      ]),
    );
  }

  Widget _photoTile(String imgUrl, String photoId) {
    // Ensure URL is clean and always correct
    String cleaned = imgUrl.replaceAll("\\", "/");

    // Make final URL
    if (!cleaned.startsWith("http")) {
      cleaned = "$baseIp/$cleaned";
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(cleaned),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // DELETE BUTTON
        Positioned(
          right: 8,
          top: 8,
          child: GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) =>
                    AlertDialog(
                      title: const Text("Delete photo?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel")),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete")),
                      ],
                    ),
              );
              if (ok == true) _deletePhoto(photoId);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration:
              const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.delete, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _uploadPhoto,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.upload, color: Colors.orange, size: 30),
                SizedBox(height: 8),
                Text(
                    "Add Photo", style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            )),
      ),
    );
  }

  Widget _tipCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.lightbulb, color: Colors.orange),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]),
    );
  }

// Part 3/3 - Pricing Add-screen save + Verify tab + Availability + dispose

  // ----------------------------
  // PRICING UI (add package full screen and helpers)
  // ----------------------------
  Widget _pricingTab() {
    return showAddPackageScreen
        ? _addPackageFullScreen()
        : _pricingListScreen();
  }

  Widget _pricingListScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Pricing Packages",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${packages.length} packages",
                        style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                packagesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                    children: packages.map((p) {
                      final id = p["_id"]?.toString() ?? "";
                      final title = p["title"]?.toString() ?? "";
                      final price = p["price"] ?? 0;
                      final desc = p["description"]?.toString() ?? "";
                      final features =
                      List<String>.from(p["features"] ?? <String>[]);

                      return _packageCard(id, title, price, desc, features);
                    }).toList()),

                const SizedBox(height: 12),

                // ADD BUTTON
                OutlinedButton(
                  onPressed: () {
                    // Reset form
                    pkgNameC.clear();
                    pkgPriceC.clear();
                    pkgDescC.clear();
                    featureControllers =
                    [TextEditingController(), TextEditingController()];
                    setState(() => showAddPackageScreen = true);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                  ),
                  child: const Text(
                    "+ Add New Package",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPackageFullScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Orange Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 40, 10, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFF5C00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => showAddPackageScreen = false);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Add New Package",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FORM CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _pkgInput("Package Name", pkgNameC),
                _pkgInput(
                    "Package Price", pkgPriceC, type: TextInputType.number),
                _pkgInput("Package Description", pkgDescC, maxLines: 3),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Features",
                        style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          featureControllers.add(TextEditingController());
                        });
                      },
                      child: const Text("+ Add Feature",
                          style: TextStyle(color: Colors.orange)),
                    )
                  ],
                ),

                const SizedBox(height: 8),

                // FEATURES LIST
                Column(
                  children: List.generate(featureControllers.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: featureControllers[i],
                              decoration: InputDecoration(
                                hintText: "Feature ${i + 1}",
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                featureControllers.removeAt(i);
                              });
                            },
                            child: const Icon(Icons.delete, color: Colors.red),
                          )
                        ],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            showAddPackageScreen = false;
                            pkgNameC.clear();
                            pkgPriceC.clear();
                            pkgDescC.clear();
                            featureControllers.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                        ),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveNewPackage,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: const Text("Save Package"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageCard(String id, String title, dynamic price, String desc,
      List<String> features) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("₹$price",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.orange)),
                      const SizedBox(height: 6),
                      Text(desc, style: const TextStyle(color: Colors.black54)),
                    ]),
              ),

              /// DELETE PACKAGE BUTTON
              IconButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        AlertDialog(
                          title: const Text("Delete package?"),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text("Cancel")),
                            ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text("Delete")),
                          ],
                        ),
                  );

                  if (ok == true) _deletePackage(id);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
              )
            ],
          ),

          const SizedBox(height: 8),
          const Divider(),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.map((f) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  // INPUT FIELD FOR ADD PACKAGE SCREEN
  Widget _pkgInput(String label, TextEditingController c,
      {int maxLines = 1, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: type,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewPackage() async {
    if (pkgNameC.text.isEmpty || pkgPriceC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    final features = featureControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final body = jsonEncode({
      "title": pkgNameC.text.trim(),
      "price": int.tryParse(pkgPriceC.text.trim()) ?? 0,
      "description": pkgDescC.text.trim(),
      "features": features,
    });

    try {
      final res = await http.post(
        Uri.parse("$baseIp/api/vendors/packages/${widget.vendorId}"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _loadPackages();
        setState(() => showAddPackageScreen = false);

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Package saved")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
            const SnackBar(content: Text("Failed to save package")));
      }
    } catch (e) {
      debugPrint("Save package error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error saving package")));
    }
  }

  // ----------------------------
  // VERIFY TAB & AVAILABILITY UI
  // ----------------------------
  Widget _verifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: verificationLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Document Verification",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Document Cards
              _verificationCard(
                title: "Business License",
                status:
                verification["businessLicense"]?["status"] ?? "pending",
                subtitle: verification["businessLicense"]?["file"] != null
                    ? "Document uploaded"
                    : "Upload business license",
                onUpload: () => _uploadDocument("businessLicense"),
              ),
              const SizedBox(height: 10),
              _verificationCard(
                title: "GST Certificate",
                status: verification["gst"]?["status"] ?? "pending",
                subtitle: verification["gst"]?["gstin"] ?? "",
                onUpload: () => _uploadDocument("gst"),
              ),
              const SizedBox(height: 10),
              _verificationCard(
                title: "Address Proof",
                status:
                verification["addressProof"]?["status"] ?? "pending",
                subtitle: verification["addressProof"]?["file"] != null
                    ? "Document uploaded"
                    : "Upload address proof",
                onUpload: () => _uploadDocument("addressProof"),
              ),
              const SizedBox(height: 16),
              _tipCard(
                  'Complete verification to get the "Verified Vendor" badge and increase trust!'),
              const SizedBox(height: 20),

              // Availability
              const Text("Availability Calendar",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _availabilityCard(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _verificationCard({
    required String title,
    required String status,
    required String subtitle,
    required VoidCallback onUpload,
  }) {
    Color borderCol;
    if (status == "verified")
      borderCol = Colors.green.shade100;
    else if (status == "pending")
      borderCol = Colors.orange.shade50;
    else
      borderCol = Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: borderCol,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (status == "verified")
                    Icon(Icons.check_circle, color: Colors.green.shade700)
                  else
                    if (status == "pending")
                      Icon(Icons.hourglass_top, color: Colors.orange.shade700)
                    else
                      Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ]),
        ),
        ElevatedButton(
          onPressed: onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text("Upload"),
        ),
      ]),
    );
  }

  Widget _availabilityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Manage Availability",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          const Text(
            "Mark when you are available or unavailable.",
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Calendar
          _calendar(),
          const SizedBox(height: 14),

          // ---------------------------
          // FULL-WIDTH STACKED BUTTONS
          // ---------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markAvailable(selectedDate),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                "Mark Available",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markHalfDay(selectedDate),
              icon: const Icon(Icons.wb_sunny, color: Colors.white),
              label: const Text(
                "Mark Half Day",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markUnavailable(selectedDate),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text(
                "Mark Unavailable",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statusBox("Booked", booked.length, Colors.green),
              _statusBox("Unavailable", unavailable.length, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendar() {
    // TableCalendar used to allow per-day decorations (red/green)
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: selectedDate,
      headerStyle: const HeaderStyle(formatButtonVisible: false),
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      onDaySelected: (day, focusedDay) {
        setState(() => selectedDate = day);
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final key = DateFormat('yyyy-MM-dd').format(day);
          if (dateStatus[key] == 'unavailable') {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${day.day}'),
            );
          }
          if (dateStatus[key] == 'available') {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${day.day}'),
            );
          }
          if (dateStatus[key] == 'half') {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${day.day}'),
            );
          }

          return Container(
            margin: const EdgeInsets.all(6),
            alignment: Alignment.center,
            child: Text('${day.day}'),
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          return Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }

  Future<void> _markUnavailable(DateTime date) async {
    String day = DateFormat('yyyy-MM-dd').format(date);

    try {
      final res = await http.post(
        Uri.parse("$baseIp/api/vendors/availability/${widget.vendorId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": day}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!unavailable.contains(day)) unavailable.add(day);
        dateStatus[day] = 'unavailable';
        setState(() {});
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
            const SnackBar(content: Text("Failed to mark unavailable")));
      }
    } catch (e) {
      debugPrint("Mark unavailable error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(
          const SnackBar(content: Text("Error marking unavailable")));
    }
  }

  Future<void> _markAvailable(DateTime date) async {
    String day = DateFormat('yyyy-MM-dd').format(date);

    try {
      final encDay = Uri.encodeComponent(day);
      final res = await http.delete(
        Uri.parse(
            "$baseIp/api/vendors/availability/${widget.vendorId}/$encDay"),
      );

      if (res.statusCode == 200) {
        unavailable.remove(day);
        dateStatus[day] = 'available';
        setState(() {});
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
            const SnackBar(content: Text("Failed to mark available")));
      }
    } catch (e) {
      debugPrint("Mark available error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(
          const SnackBar(content: Text("Error marking available")));
    }
  }

  // Mark half-day (local UI only). If you want server persistence, we can add an API.
  Future<void> _markHalfDay(DateTime date) async {
    final day = DateFormat('yyyy-MM-dd').format(date);
    // For now, mark locally only
    dateStatus[day] = 'half';
    // Remove from server-stored unavailable if previously present (optional)
    if (unavailable.contains(day)) {
      try {
        final encDay = Uri.encodeComponent(day);
        final res = await http.delete(
          Uri.parse("$baseIp/api/vendors/availability/${widget.vendorId}/$encDay"),
        );
        if (res.statusCode == 200) {
          unavailable.remove(day);
        }
      } catch (_) {}
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as half-day (local)")));
  }

  Widget _statusBox(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
    );
  }

// Dispose controllers
  @override
  void dispose() {
    businessC.dispose();
    categoryC.dispose();
    locationC.dispose();
    phoneC.dispose();
    descC.dispose();
    pkgNameC.dispose();
    pkgPriceC.dispose();
    pkgDescC.dispose();
    for (final c in featureControllers) {
      c.dispose();
    }
    tabController.dispose();
    super.dispose();
  }
}

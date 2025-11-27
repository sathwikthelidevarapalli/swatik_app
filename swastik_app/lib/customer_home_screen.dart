// lib/screens/customer_home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ai_assistant_screen.dart';
import 'vendor_search_results_screen.dart';

const String apiBase = "http://10.240.92.1:5000";

class CustomerHomeScreen extends StatefulWidget {
  final String userName;

  const CustomerHomeScreen({super.key, required this.userName});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

// ------------------- Category Vendors Screen -------------------

class CategoryVendorsScreen extends StatefulWidget {
  final String category;
  final String location;
  final String userName;

  const CategoryVendorsScreen({super.key, required this.category, required this.location, required this.userName});

  @override
  State<CategoryVendorsScreen> createState() => _CategoryVendorsScreenState();
}

class _CategoryVendorsScreenState extends State<CategoryVendorsScreen> {
  final Color primaryColorLocal = const Color(0xFFE55836);
  bool isLoading = false;
  List<Map<String, dynamic>> vendors = [];
  String sortBy = 'Popularity';
  // optional per-category accents (Catering keeps primaryColorLocal)
  final Map<String, Color> _categoryAccent = {
    // Use a single accent color (orange) for all categories to keep UI consistent
    'Decoration': Color(0xFFE55836),
    'Photography': Color(0xFFE55836),
    'Venues': Color(0xFFE55836),
    'Pandit': Color(0xFFE55836),
    'Makeup': Color(0xFFE55836),
  };

  // controller for the location search field and current location state
  late TextEditingController _searchController;
  late String currentLocation;

  @override
  void initState() {
    super.initState();
    currentLocation = widget.location;
    _searchController = TextEditingController(text: currentLocation);
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchVendors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchVendors() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('$apiBase/api/vendors?location=${Uri.encodeComponent(currentLocation)}&category=${Uri.encodeComponent(widget.category)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = decoded is Map ? (decoded['vendors'] ?? decoded) : decoded;
        vendors = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        vendors = [];
      }
    } catch (e) {
      vendors = [];
    }
    _applySort();
    setState(() => isLoading = false);
  }

  void _applySort() {
    if (sortBy == 'Popularity') {
      vendors.sort((a, b) => ((b['rating'] ?? 0)).toString().compareTo(((a['rating'] ?? 0)).toString()));
    } else if (sortBy == 'Price: Low to High') {
      vendors.sort((a, b) {
        final pa = int.tryParse((a['price'] ?? '').toString()) ?? 0;
        final pb = int.tryParse((b['price'] ?? '').toString()) ?? 0;
        return pa.compareTo(pb);
      });
    } else if (sortBy == 'Price: High to Low') {
      vendors.sort((a, b) {
        final pa = int.tryParse((a['price'] ?? '').toString()) ?? 0;
        final pb = int.tryParse((b['price'] ?? '').toString()) ?? 0;
        return pb.compareTo(pa);
      });
    } else if (sortBy == 'Rating') {
      vendors.sort((a, b) => ((b['rating'] ?? 0)).toString().compareTo(((a['rating'] ?? 0)).toString()));
    }
  }

  Widget _vendorCard(Map<String, dynamic> v) {
    final img = (v['imageUrl'] ?? '').toString();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (img.isNotEmpty)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(img, height: 160, width: double.infinity, fit: BoxFit.cover))
          else
            Container(height: 160, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(v['category'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.star, color: Colors.orange, size: 14), const SizedBox(width: 6), Text('${v['rating'] ?? '-'}', style: TextStyle(color: Colors.grey.shade600))]),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text(v['location'] ?? '', style: TextStyle(color: Colors.grey.shade600))) , const Spacer(), Text('₹${v['price']}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColorLocal))]),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the same orange accent for all categories
    final accent = primaryColorLocal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.category), const SizedBox(height: 4), Text('Browse ${widget.category} Services', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)))]),
        actions: [
          IconButton(icon: const Icon(Icons.map_outlined), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          // optional hero for non-catering categories to match unique UI per category
          if (widget.category != 'Catering')
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(widget.category, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accent)),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _searchController,
              // allow Enter/Done to trigger a search for all categories
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                final loc = value.trim();
                setState(() {
                  currentLocation = loc;
                });
                fetchVendors();
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.category == 'Catering' ? 'Enter your location' : 'Search by service, location, or budget',
                border: InputBorder.none,
                // add a tappable search icon so users can tap to search
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final loc = _searchController.text.trim();
                    setState(() {
                      currentLocation = loc;
                    });
                    fetchVendors();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            // Prevent overflow by allowing chips to scroll horizontally when space is limited
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Wrap(spacing: 8, children: [
                    Chip(label: const Text('Filters'), backgroundColor: Colors.orange.shade50),
                    Chip(label: Text(widget.category), backgroundColor: Colors.orange.shade50),
                    if (widget.location.trim().isNotEmpty) Chip(label: Text(widget.location), backgroundColor: Colors.orange.shade50),
                  ])
                ]),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: sortBy,
              items: const [
                DropdownMenuItem(value: 'Popularity', child: Text('Popularity')),
                DropdownMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                DropdownMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
                DropdownMenuItem(value: 'Rating', child: Text('Rating')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  sortBy = v;
                  _applySort();
                });
              },
            )
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : vendors.isEmpty
                    ? Center(child: Text('Found 0 vendors in ${widget.category}', style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.separated(
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _vendorCard(vendors[i]),
                      ),
          ),
        ]),
      ),
    );
  }
}
// ------------------- Customer Messages Screen (in-file) -------------------

class CustomerMessagesScreen extends StatefulWidget {
  final String userName;

  const CustomerMessagesScreen({super.key, required this.userName});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  final Color primaryColorLocal = const Color(0xFFE55836);
  bool isLoadingMessages = false;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchMessages());
  }

  Future<void> fetchMessages() async {
    setState(() => isLoadingMessages = true);

    try {
      final uri = Uri.parse('$apiBase/api/messages?user=${Uri.encodeComponent(widget.userName)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = decoded is Map ? (decoded['conversations'] ?? decoded['messages'] ?? decoded) : decoded;
        messages = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        messages = [];
      }
    } catch (e) {
      messages = [];
    }

    setState(() => isLoadingMessages = false);
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColorLocal,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (q) {
                  // simple client-side filter could be implemented later
                },
              ),
            ),
          ),
        ),
      ),
      body: isLoadingMessages
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
              ? Center(child: Text('No conversations yet', style: TextStyle(color: Colors.grey.shade600)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final vendor = (m['vendorName'] ?? m['name'] ?? 'Unknown').toString();
                    final last = (m['lastMessage'] ?? m['message'] ?? '').toString();
                    final ts = (m['timestamp'] ?? m['time'] ?? '').toString();
                    final unread = (m['unreadCount'] ?? m['unread'] ?? 0) is int ? (m['unreadCount'] ?? m['unread'] ?? 0) : int.tryParse((m['unreadCount'] ?? m['unread'] ?? '0').toString()) ?? 0;
                    final img = (m['vendorImageUrl'] ?? m['imageUrl'] ?? '').toString();

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () {
                          // TODO: open chat screen for this conversation
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: img.isNotEmpty
                            ? ClipOval(
                                child: Image.network(img, width: 48, height: 48, fit: BoxFit.cover),
                              )
                            : CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.shade200,
                                child: Text(_initials(vendor), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                        title: Text(vendor, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(ts, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 6),
                            if (unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12)),
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

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final Color primaryColor = const Color(0xFFE55836);

  // baseUrl is now at file scope: `apiBase`

  late String userName;
  String userLocation = "   ";
  bool isLoading = false;

  List<Map<String, dynamic>> vendors = [];

  // Categories to display (may be reordered based on selected location)
  late List<Map<String, dynamic>> displayedCategories;
    final List<Map<String, dynamic>> categories = [
    {
      'name': 'Catering',
      'vendors': 0,
      'icon': Icons.food_bank_outlined,
      'color': Color(0xFFE55836)
    },
    {
      'name': 'Decoration',
      'vendors': 0,
      'icon': Icons.flare_outlined,
      'color': Color(0xFFE55836)
    },
    {
      'name': 'Photography',
      'vendors': 0,
      'icon': Icons.camera_alt_outlined,
      'color': Color(0xFFE55836)
    },
    {
      'name': 'Venues',
      'vendors': 0,
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFFE55836)
    },
    {
      'name': 'Pandit',
      'vendors': 0,
      'icon': Icons.music_note_outlined,
      'color': Color(0xFFE55836)
    },
    {
      'name': 'Makeup',
      'vendors': 0,
      'icon': Icons.brush_outlined,
      'color': Color(0xFFE55836)
    },
  ];

  final TextEditingController _locationController = TextEditingController();

  // Vendors will be loaded from backend; no local sample data.

  // Bookings are fetched from backend; no local sample data.

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    _locationController.text = userLocation;

    // initialize displayedCategories with the base categories order
    displayedCategories = List<Map<String, dynamic>>.from(categories);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchVendorsByLocation(userLocation);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // Fetch vendors
  Future<void> fetchVendorsByLocation(String location) async {
    setState(() => isLoading = true);

    try {
      final uri = Uri.parse("$apiBase/api/vendors?location=${Uri.encodeComponent(location)}");
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        List<dynamic> list = decoded is Map ? decoded['vendors'] : decoded;

        vendors = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        vendors = [];
      }
    } catch (e) {
      vendors = [];
    }

    _updateCategoryCounts();
    // create a sorted copy of categories for display by vendor count (descending)
    displayedCategories = List<Map<String, dynamic>>.from(categories);
    displayedCategories.sort((a, b) {
      final ai = (a['vendors'] is int) ? a['vendors'] as int : int.tryParse(a['vendors'].toString()) ?? 0;
      final bi = (b['vendors'] is int) ? b['vendors'] as int : int.tryParse(b['vendors'].toString()) ?? 0;
      return bi.compareTo(ai);
    });
    setState(() => isLoading = false);
  }

  void _updateCategoryCounts() {
    for (var c in categories) {
      c['vendors'] = vendors
          .where((v) => v['category'].toString().toLowerCase() == c['name'].toString().toLowerCase())
          .length;
    }
  }

  List<Map<String, dynamic>> _recommended({int limit = 6}) {
    final filtered = vendors.where((v) => (v['location'] ?? '').toLowerCase() == userLocation.toLowerCase()).toList();

    filtered.sort((a, b) => ((b['rating'] ?? 0)).compareTo(a['rating'] ?? 0));

    return filtered.take(limit).toList();
  }

  List<Map<String, dynamic>> _topRated({int limit = 6}) {
    final filtered = vendors.where((v) => (v['location'] ?? '').toLowerCase() == userLocation.toLowerCase()).toList();

    filtered.sort((a, b) => ((b['rating'] ?? 0)).compareTo(a['rating'] ?? 0));

    return filtered.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommended = _recommended();
    final topRated = _topRated();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildAIFab(context),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Browse by Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildCategoryGrid(),

                    const SizedBox(height: 20),
                    _buildSectionHeader(title: "Recommended For You"),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildHorizontalVendorList(recommended),

                    const SizedBox(height: 20),
                    _buildSectionHeader(title: "Top-rated in ${userLocation.trim().isEmpty ? 'your area' : userLocation}"),
                    isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildVerticalVendorList(topRated),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SLIVER APPBAR
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
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
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'Hey ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              TextSpan(text: userName, style: TextStyle(color: Colors.orange.shade50, fontSize: 22, fontWeight: FontWeight.bold)),
                              TextSpan(text: ' 👋', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Let's plan something amazing",
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // top-right small action icons (messages, bookings)
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => CustomerMessagesScreen(userName: userName)),
                                    );
                                  },
                            ),
                          ),
                          // badge
                          Positioned(
                            right: 4,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyBookingsScreen(userName: userName),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 12),

              // Search bar (prominent)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                          hintText: 'Search by service, location, or budge',
                          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                                          onSubmitted: (val) {
                                            if (val.trim().isEmpty) return;
                                            userLocation = val.trim();
                                            _locationController.text = userLocation;
                                            // navigate to search results screen that calls backend /api/vendors?city=...
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => VendorSearchResultsScreen(city: userLocation),
                                              ),
                                            );
                                          },
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      itemCount: displayedCategories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) {
        final c = displayedCategories[i];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryVendorsScreen(
                  category: c['name'].toString(),
                  location: userLocation,
                  userName: userName,
                ),
              ),
            );
          },
          child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(color: c['color'].withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(c['icon'], size: 26, color: c['color']),
                ),
                const SizedBox(height: 10),
                Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text("${c['vendors']} vendors", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  // Vertical vendor list for sections like Top-rated
  Widget _buildVerticalVendorList(List<Map<String, dynamic>> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildVerticalVendorCard(list[i]),
    );
  }

  Widget _buildVerticalVendorCard(Map<String, dynamic> v) {
    final img = v['imageUrl'] ?? 'https://placehold.co/600x400/ccc?text=No+Image';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(img, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              if ((v['isVerified'] ?? false) == true)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              if ((v['isAvailable'] ?? false) == true)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Available', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(v['category'], style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Text("${v['rating']} (${v['reviews']} reviews)", style: TextStyle(color: Colors.grey.shade600)),
                    const Spacer(),
                    Text("₹${v['price']}/plate", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(v['location'] ?? '', style: TextStyle(color: Colors.grey.shade600))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Text("View all", style: TextStyle(color: primaryColor)),
      ],
    );
  }

  Widget _buildHorizontalVendorList(List<Map<String, dynamic>> list) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, i) => _buildVendorCard(list[i]),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> v) {
    final img = v['imageUrl'] ?? 'https://placehold.co/600x400/ccc?text=No+Image';
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(img, height: 160, width: 260, fit: BoxFit.cover),
              ),
              if ((v['isVerified'] ?? false) == true)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              if ((v['isAvailable'] ?? false) == true)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Available', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(v['category'], style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text("${v['rating']} (${v['reviews']} reviews)", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 6),
                Text("₹${v['price']}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFab(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: primaryColor,
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AIAssistantScreen()),
        );
      },
    );
  }

  }

// ------------------- My Bookings Screen (in-file) -------------------

class MyBookingsScreen extends StatefulWidget {
  final String userName;

  const MyBookingsScreen({super.key, required this.userName});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColorLocal = const Color(0xFFE55836);
  bool isLoadingBookings = false;
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchBookings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRateDialog(Map<String, dynamic> booking) {
    final TextEditingController _feedback = TextEditingController();
    int _rating = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setState2) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rate ${booking['vendorName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('How was your experience with this vendor?'),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return IconButton(
                        icon: Icon(idx <= _rating ? Icons.star : Icons.star_border, color: Colors.amber),
                        onPressed: () => setState2(() => _rating = idx),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Text('Share your feedback (Optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedback,
                    maxLines: 3,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColorLocal),
                      onPressed: () {
                        // In real app: send rating to server
                        Navigator.pop(ctx);
                      },
                      child: const Text('Submit Rating'),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> fetchBookings() async {
    setState(() => isLoadingBookings = true);

    try {
      final uri = Uri.parse('$apiBase/api/bookings?user=${Uri.encodeComponent(widget.userName)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = decoded is Map ? (decoded['bookings'] ?? decoded) : decoded;
        bookings = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        bookings = [];
      }
    } catch (e) {
      bookings = [];
    }

    setState(() => isLoadingBookings = false);
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = bookings.where((b) => (b['status'] ?? '').toString() != 'Completed').toList();
    final past = bookings.where((b) => (b['status'] ?? '').toString() == 'Completed').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColorLocal,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('My Bookings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.separated(
                    itemCount: upcoming.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final b = upcoming[i];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(b['imageUrl'], width: 70, height: 70, fit: BoxFit.cover)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b['vendorName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(b['category'], style: TextStyle(color: Colors.grey.shade600)),
                                        const SizedBox(height: 6),
                                        Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 6), Text(b['date'], style: TextStyle(color: Colors.grey.shade600))]),
                                        Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 6), Text(b['location'], style: TextStyle(color: Colors.grey.shade600))]),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text('₹${b['price']}', style: TextStyle(color: primaryColorLocal, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(b['id'], style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.call, color: Colors.orange),
                                      label: const Text('Call', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.orange),
                                      label: const Text('Chat', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ListView.separated(
                    itemCount: past.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final b = past[i];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(b['imageUrl'], width: 70, height: 70, fit: BoxFit.cover)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['vendorName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(b['category'], style: TextStyle(color: Colors.grey.shade600)),
                                    const SizedBox(height: 8),
                                    Text('₹${b['price']}', style: TextStyle(color: primaryColorLocal, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColorLocal),
                                onPressed: () => _openRateDialog(b),
                                child: const Text('Rate Vendor'),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

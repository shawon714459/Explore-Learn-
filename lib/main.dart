import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExploreAndLearnApp());
}

class ExploreAndLearnApp extends StatelessWidget {
  const ExploreAndLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explore & Learn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D111A),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // ডিফল্ট ওয়ালেট পেজ

  final List<Widget> _pages = [
    const Center(child: Text("Explore Section", style: TextStyle(color: Colors.white, fontSize: 18))),
    const Center(child: Text("Quiz & Tasks", style: TextStyle(color: Colors.white, fontSize: 18))),
    const WalletScreen(),
    const Center(child: Text("User Profile", style: TextStyle(color: Colors.white, fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _balance = 0;
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final List<Map<String, dynamic>> _coinPacks = [
    {'id': 'coin_pack_50', 'coins': 50, 'price': '\$0.51'},
    {'id': 'coin_pack_100', 'coins': 100, 'price': '\$1.01'},
    {'id': 'coin_pack_200', 'coins': 200, 'price': '\$2.01'},
    {'id': 'coin_pack_300', 'coins': 300, 'price': '\$3.01'},
    {'id': 'coin_pack_400', 'coins': 400, 'price': '\$4.01'},
    {'id': 'coin_pack_500', 'coins': 500, 'price': '\$5.01'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () => _subscription.cancel(), onError: (error) {});
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = prefs.getInt('coin_balance') ?? 0;
    });
  }

  Future<void> _addCoins(int count) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance += count;
    });
    await prefs.setInt('coin_balance', _balance);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased) {
        for (var pack in _coinPacks) {
          if (pack['id'] == purchase.productID) {
            _addCoins(pack['coins']);
            break;
          }
        }
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  void _buyProduct(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('গুগল প্লে বিলিং সংযোগ পাওয়া যায়নি!')),
      );
      return;
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails({productId});

    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('প্রোডাক্টটি পাওয়া যায়নি!')),
      );
      return;
    }

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: response.productDetails.first);
    _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Wallet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildBalanceCard(),
            const SizedBox(height: 16),
            Expanded(child: _buildCoinGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text('$_balance', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ],
          ),
          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildCoinGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _coinPacks.length,
      itemBuilder: (context, index) {
        final pack = _coinPacks[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.layers, color: Colors.amber, size: 40),
              Text('${pack['coins']} Coins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(pack['price'], style: const TextStyle(fontSize: 14, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E8F0),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _buyProduct(pack['id']),
                  child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

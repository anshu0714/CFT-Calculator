import 'package:cft_calculator/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_party_page.dart';
import 'party_details_page.dart';
import 'models.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Party> _parties = [];

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  // Load parties from shared preferences
  Future<void> _loadParties() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedParties = prefs.getString('parties');
    if (storedParties != null) {
      setState(() {
        _parties = List<Party>.from(
          (json.decode(storedParties) as List<dynamic>).map(
            (item) => Party.fromJson(item),
          ),
        );
      });
    }
  }

  // Save parties to shared preferences
  Future<void> _saveParties() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedParties =
        json.encode(_parties.map((party) => party.toJson()).toList());
    await prefs.setString('parties', encodedParties);
  }

  // Add a new party and save to local storage
  void _addParty(String name, String number, String email) {
    setState(() {
      _parties.add(Party(
        name: name,
        number: number,
        email: email,
        tableSheets: [],
      ));
    });
    _saveParties();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 32,
              height: 300,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'ANALYTICS',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14.0),
                    child: Text(
                      'Party Ledger',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _parties.length,
                    itemBuilder: (context, index) {
                      final party = _parties[index];
                      final String displayedEmail =
                          (party.email == "No email address provided" ||
                                  party.email.isEmpty)
                              ? party.number
                              : party.email.toLowerCase();
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        title: Text(
                          party.name
                              .split(' ')
                              .map((word) => word.isNotEmpty
                                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                  : '')
                              .join(' '),
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          displayedEmail,
                          style: TextStyle(color: Colors.black54),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartyDetailsPage(
                                party: party,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPartyPage(onAddParty: _addParty),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.person_add, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'ADD PARTY',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}

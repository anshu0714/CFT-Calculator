import 'package:cft_calculator/load_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PartyDetailsPage extends StatelessWidget {
  final Party party;

  const PartyDetailsPage({
    required this.party,
    super.key,
  });

  void _makeCall(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
      _saveCallDetails(number);
    } else {
      print('Could not launch $callUri');
    }
  }

  // Method to save call details to local storage
  Future<void> _saveCallDetails(String number) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_called_number_${party.name}', number);
  }

  // Method to get saved call details from local storage
  Future<String?> _getLastCalledNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_called_number_${party.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(width: 10),
            Column(
              children: [
                Text(
                  party.name
                      .split(' ')
                      .map((word) => word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                          : '')
                      .join(' '),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_outlined),
            onPressed: () => _makeCall(party.number),
          ),
        ],
      ),
      body: Column(
        children: [
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadPage(
                              partyName: party.name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'LOAD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        _sendOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 49, 83, 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'SEND ORDER',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<String?>(
            future: _getLastCalledNumber(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData && snapshot.data != null) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Last Called: ${snapshot.data}'),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  // Handling send order for the specific party
  void _sendOrder() {
    print('Order sent for ${party.name}');
  }
}

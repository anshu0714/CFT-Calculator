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
      _saveCallDetails(number); // Save the number after making the call
    } else {
      // ignore: avoid_print
      print('Could not launch $callUri');
    }
  }

  // Method to save call details to local storage
  Future<void> _saveCallDetails(String number) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'last_called_number_${party.name}', number);
  }

  // Method to get saved call details from local storage
  Future<String?> _getLastCalledNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('last_called_number_${party.name}'); 
  }

  @override
  Widget build(BuildContext context) {
    // Check and format the email
    final String displayedEmail = party.email == "No email address provided"
        ? party.email
        : party.email.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.teal),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  party.name.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  displayedEmail, // Display the formatted email
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        iconTheme:
            IconThemeData(color: Colors.white), // Makes the back arrow white
        actions: [
          IconButton(
            icon: Icon(Icons.phone, color: Colors.white),
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoadPage(
                            partyName: party.name, // New page for table preview
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'LOAD',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle SEND ORDER action for this specific party
                      _sendOrder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'SEND ORDER',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Optionally show last called number from local storage
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

  // Handle sending the order for the specific party
  void _sendOrder() {
    // You can implement the logic to send the order, specific to the party
    print('Order sent for ${party.name}');
  }
}

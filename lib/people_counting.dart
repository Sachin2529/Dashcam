import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PeopleCountWidget extends StatefulWidget {
  @override
  _PeopleCountWidgetState createState() => _PeopleCountWidgetState();
}

class _PeopleCountWidgetState extends State<PeopleCountWidget> {
  final DatabaseReference _peopleRef = FirebaseDatabase.instance.ref('bus/people_count');
  int _peopleCount = 0;

  @override
  void initState() {
    super.initState();
    _peopleRef.onValue.listen((event) {
      final int count = event.snapshot.value as int? ?? 0;
      setState(() {
        _peopleCount = count;
      });
    });
  }

  void _showPeopleCountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("People Count"),
        content: Text("Current People in Bus: $_peopleCount"),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: _showPeopleCountDialog,
        child: Icon(Icons.people),
        tooltip: 'Show People Count',
      ),
    );
  }
}

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:while_app/view/social/community_detail.dart';
import '../../resources/components/message/apis.dart';
import '../../resources/components/message/helper/dialogs.dart';
import '../../resources/components/message/models/chat_user.dart';

late Size mq;

//home screen -- where all available contacts are shown
class CommunityScreen extends StatefulWidget {
  CommunityScreen({super.key, required this.isSearching, required this.value});
  bool isSearching;
  final String value;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // for storing all users

  // for storing searched items

  // for storing search status
  final List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    bool isSearching = widget.isSearching;
    if (widget.value != '') {
      log(widget.value);
      _searchList.clear();

      for (var i in _list) {
        if (i.name.toLowerCase().contains(widget.value.toLowerCase()) ||
            i.email.toLowerCase().contains(widget.value.toLowerCase())) {
          _searchList.add(i);
          setState(() {
            _searchList;
          });
        }
      }
    }

    mq = MediaQuery.of(context).size;
    return Scaffold(
        //floating button to add new user
        backgroundColor: Colors.deepPurple[100],
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton(
              onPressed: () {
                _addCommunityDialog();
              },
              child: const Icon(Icons.add_comment_rounded)),
        ),

        //body
        body: StreamBuilder(
            stream: APIs.getCommunityId(),

            //get id of only known users
            builder: (context, snapshot) {
              log('Function called ///////////////');
              return (snapshot.connectionState == ConnectionState.waiting)
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var data = snapshot.data!.docs[index].data();
                        var name = '';

                        communityData() async {
                          var datas = await FirebaseFirestore.instance
                              .collection('communities')
                              .doc(data['id'])
                              .get();

                          name = datas['name'];

                          log(name);
                        }

                        log(data.toString());
                        return FutureBuilder(
                          future: communityData(),
                          builder: (context, snapshots) {
                            return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: mq.width * .04, vertical: 4),
                                color: Colors.blue.shade100,
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityDetailScreen(
                                        userImage: '',
                                        userName: name,
                                        id: data['id'],
                                      ),
                                    ));
                                  },
                                  title: Text(
                                    name,
                                    textAlign: TextAlign.center,
                                  ),
                                  subtitle:
                                      Text(name, textAlign: TextAlign.center),
                                ));
                          },
                        );
                      },
                    );
            }));
  }

  // for adding new chat user
  void _addCommunityDialog() {
    String name = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding:
            const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        //title
        title: const Row(
          children: [
            Icon(
              Icons.person_add,
              color: Colors.blue,
              size: 28,
            ),
            Text('Add Community')
          ],
        ),

        //content
        content: TextFormField(
          maxLines: null,
          onChanged: (value) => name = value,
          decoration: InputDecoration(
              hintText: 'Community Name',
              prefixIcon: const Icon(Icons.email, color: Colors.blue),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
        ),

        //actions
        actions: [
          //cancel button
          MaterialButton(
              onPressed: () {
                //hide alert dialog
                Navigator.pop(context);
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.blue, fontSize: 16))),

          //add button
          MaterialButton(
              onPressed: () async {
                //hide alert dialog
                Navigator.pop(context);
                if (name.isNotEmpty) {
                  await APIs.addCommunity(name).then((value) {
                    if (!value) {
                      Dialogs.showSnackbar(
                          context, 'Community does not Exists!');
                    }
                  });
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ))
        ],
      ),
    );
  }
}

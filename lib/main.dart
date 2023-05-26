import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rive/rive.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Number ',
      home: Welcome(),
    );
  }
}

class Welcome extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _submitPhoneNumber() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDisplay(
            number: _numberController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 249, 167, 142),
        // backgroundColor: const Color.fromARGB(255, 249, 167, 142),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 218, 127, 100),
          title: const Text('PENZI'),
        ),
        body: Stack(
          children: [
            Positioned(
              width: MediaQuery.of(context).size.width * 1.7,
              bottom: 200,
              left: 100,
              child: Image.asset("assets/RiveAssets/Spline.png"),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: SizedBox(),
              ),
            ),
            RiveAnimation.asset("assets/RiveAssets/shapes.riv"),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
                child: SizedBox(),
              ),
            ),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    SizedBox(
                      width: 250,
                      child: Column(
                        children: [
                          Text(
                            "Hello & welcome to Penzi",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontFamily: "Poppins",
                              height: 1.2,
                            ),
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          Text(
                            "Penzi has over 500 matches located all over the country ready to find love. Text the word 'PENZI' in the chats to get started.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      margin: const EdgeInsets.only(
                          top: 0, bottom: 0, left: 5, right: 15),
                      child: TextFormField(
                        controller: _numberController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 18, color: Colors.black),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                              left: 15, top: 8, right: 15, bottom: 0),
                          labelText: 'Enter phone number',
                          hintText: '254...',
                          fillColor: Color.fromARGB(255, 236, 217, 217),
                          filled: true,
                          icon: Icon(Icons.phone, color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusColor: Colors.black,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a phone number";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 26.20,
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 0,
                        bottom: 30,
                        left: 0,
                        right: 0,
                      ),
                      child: ElevatedButton(
                        onPressed: _submitPhoneNumber,
                        child: Text('Join Penzi'),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0),
                            ),
                            backgroundColor: Color.fromARGB(255, 218, 127, 100),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            textStyle: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagePair {
  final String userMessage;
  final String systemMessage;

  MessagePair({required this.userMessage, required this.systemMessage});
}

class ChatDisplay extends StatefulWidget {
  final String number;

  const ChatDisplay({Key? key, required this.number}) : super(key: key);

  @override
  State<ChatDisplay> createState() => _ChatDisplayState();
}

class _ChatDisplayState extends State<ChatDisplay> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _messageController = TextEditingController();
  String? _messageSent;
  String? _apiResponse;
  ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  String errorMessage = "";
  Timer? loadingTimer;
  var _postsJson = [];

  List<MessagePair> _messages = [];
  @override
  void initState() {
    super.initState();
    _loadConversation();
    _scrollToBottom();
  }

  Future<void> _loadConversation() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    loadingTimer = Timer(Duration(seconds: 20), () {
      setState(() {
        isLoading = false;
        errorMessage = "Cant connect to server. Please try again later.";
      });
    });

    try {
      final response = await http.post(
        Uri.parse('http://3.8.159.233:8000/usermessage/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': widget.number}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        List<MessagePair> fetchedMessages = [];
        for (var pair in jsonData) {
          fetchedMessages.add(MessagePair(
            userMessage: pair['user_message'],
            systemMessage: pair['sys_message'],
          ));
        }
        setState(() {
          _postsJson = jsonData;
          _messages = fetchedMessages;
          isLoading = false;
          _scrollToBottom();
        });
      } else {
        print("Error");
      }
    } catch (e) {
      setState(() {
        errorMessage =
            "Cant connect to server. Please check your internet connection or try again later.";
      });
    } finally {
      loadingTimer?.cancel();

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _sendData() async {
    final phoneNumber = widget.number;
    final message = _messageController.text;
    final response = await http.post(
      Uri.parse('http://3.8.159.233:8000/request/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber, 'message': message}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _scrollToBottom();

      final userMessage = message;
      final systemMessage = responseData;
      final newMessage =
          MessagePair(userMessage: userMessage, systemMessage: systemMessage);
      setState(() {
        _messages.add(newMessage);
      });
    } else {
      setState(() {
        _messageSent = null;
        _apiResponse = 'An error occurred';
      });
    }
  }

  final message = "";
  void _submitPhoneNumber() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Welcome(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 249, 167, 142),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 218, 127, 100),
        title: Text('${widget.number}'),
        actions: [
          IconButton(
            onPressed: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
            tooltip: "Scroll to Bottom",
            icon: const Icon(
              Icons.arrow_downward,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 200,
            left: 100,
            child: Image.asset("assets/RiveAssets/Spline.png"),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: SizedBox(),
            ),
          ),
          RiveAnimation.asset("assets/RiveAssets/shapes.riv"),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: SizedBox(),
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final pair = _messages[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                                top: 10.0, bottom: 10.0, right: 150, left: 20),
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 7),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 241, 227, 227),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: Offset(
                                      4, 4), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Text(
                              "${pair.userMessage} ",
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                top: 10.0, bottom: 10.0, left: 150, right: 20),
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 7),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 249, 167, 142),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(41, 0, 0, 0)
                                      .withOpacity(0.15),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: Offset(
                                      4, 8), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Text(
                              "${pair.systemMessage}\n",
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 218, 127, 100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(
                                top: 0, bottom: 0, left: 5, right: 5),
                            child: TextFormField(
                              controller: _messageController,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                    left: 15, top: 8, right: 15, bottom: 0),
                                labelText: 'Chat',
                                fillColor: Color.fromARGB(255, 236, 217, 217),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 10, 4, 3),
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                focusColor: Colors.black,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 50,
                        width: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              _sendData();
                            }
                            await Future.delayed(Duration(milliseconds: 500));
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Icon(Icons.send),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(50.0),
                            ),
                            backgroundColor: Color.fromARGB(255, 244, 64, 61),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.1),
              child: Center(
                child: SpinKitCircle(
                  color: Color.fromARGB(255, 244, 64, 61),
                  size: 50.0,
                ),
              ),
            ),
          if (errorMessage != "")
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.only(
                          top: 0, bottom: 10.0, left: 0, right: 0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(fontSize: 14.0, color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _loadConversation,
                      child: Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                        ),
                        backgroundColor: Color.fromARGB(255, 244, 64, 61),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

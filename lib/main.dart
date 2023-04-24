import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Example',
      home: MqttPage(),
    );
  }
}

class MqttPage extends StatefulWidget {
  @override
  _MqttPageState createState() => _MqttPageState();
}

class _MqttPageState extends State<MqttPage> {
  final String _serverUri = 'broker-cn.emqx.io';
  final String _clientId = 'tinyclown1972_asdasd';
  final String _subscribeTopic = 'stat/heater_tasmota_AB75DC/RESULT';
  final String _publishTopic = 'cmnd/heater_tasmota_AB75DC/Power';
  final String _willTopic = 'tinyclown1972_test_will';
  final int _port = 1883;
  bool showImage = false;
  String connectStates = "Not Connect";

  late MqttServerClient _client;
  bool _isConnected = false;
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() async {
    _client = MqttServerClient(_serverUri, _clientId);
    _client.port = _port;

    // Set callback functions
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.onUnsubscribed = _onUnsubscribed;
    _client.onSubscribeFail = _onSubscribeFail;
    _client.pongCallback = _pong;
    _client.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .keepAliveFor(60)
        .withWillTopic(_willTopic)
        .withWillMessage('My will message')
        .startClean();

    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _client.disconnect();
    }
  }

  void _onConnected() {
    _isConnected = true;
    connectStates = "Connected!";
    print('Client connected');
    _client.subscribe(_subscribeTopic, MqttQos.exactlyOnce);
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String message =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      if(c[0].topic == _subscribeTopic){
        try{
            // process incoming msg
            Map<String, dynamic> data = jsonDecode(message);
            final String msg = data['POWER'];
            print('POWER: ${msg}');
            if(msg == "ON" || msg == "on" || msg == "On"){
              setState(() {
                showImage = true;
              });
            }else {
              setState(() {
                showImage = false;
              });
            }
          }
        catch(e,s) {
          final String msg = message;
          if(msg == "ON" || msg == "on" || msg == "On"){
            setState(() {
              showImage = true;
            });
          }else{
            setState(() {
              showImage = false;
            });
          }
        }
        finally{
          // do nothing!
        }
      }
      // print('Topic: ${c[0].topic}, payload: $message');
    });
    final message = MqttClientPayloadBuilder().addString("").payload!;
    _client.publishMessage(_publishTopic, MqttQos.exactlyOnce, message);
  }

  void _onDisconnected() {
    _isConnected = false;
    print('Client disconnected');
    _connect();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _onUnsubscribed(String? topic) {
    print('Unsubscribed from $topic');
    _connect();
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe to $topic');
    _connect();
  }

  void _pong() {
    print('Ping response client callback invoked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boiler'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(connectStates),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: GestureDetector(
                  onTap: (){
                    if(showImage){
                      final message = MqttClientPayloadBuilder().addString("OFF").payload!;
                      _client.publishMessage(_publishTopic, MqttQos.exactlyOnce, message);
                    }else{
                      final message = MqttClientPayloadBuilder().addString("ON").payload!;
                      _client.publishMessage(_publishTopic, MqttQos.exactlyOnce, message);
                    }
                  },
                  child: showImage ? Image.asset(
                    'images/switchOn.png',
                    // fit: BoxFit.fitHeight,
                    key: ValueKey('onImage'),
                    width: 256, // 指定图片宽度为 200
                    height: 256, // 指定图片高度为 200
                  ) : Image.asset(
                    'images/switchOff.png',
                    // fit: BoxFit.fitHeight,
                    key: ValueKey('offImage'),
                    width: 256, // 指定图片宽度为 200
                    height: 256, // 指定图片高度为 200
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final message =
                    MqttClientPayloadBuilder().addString("ON").payload!;
                    _client.publishMessage(_publishTopic, MqttQos.exactlyOnce, message);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 8.0,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Turn On',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                ElevatedButton(
                  onPressed: () {
                    final message =
                    MqttClientPayloadBuilder().addString("OFF").payload!;
                    _client.publishMessage(_publishTopic, MqttQos.exactlyOnce, message);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 8.0,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Turn Off',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

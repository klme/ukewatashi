import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

/// BLE情報 加速度係数
//static const double bleMgLSB = 0.0039;

String gssUuid(String code) => '0000$code-0000-1000-8000-00805f9b34fb';

final GSS_SERV__BATTERY = gssUuid('2a00');
final GSS_CHAR__BATTERY_LEVEL = gssUuid('2aa6');

/// BLE情報 サービスUUID
const bleServiceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";

/// BLE情報 送信UUID
const bleSendUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

/// BLE情報 通知(受信)UUID
const bleNotifyUUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

//最大伝送バイト
const WOODEMI_MTU_WUART = 247;

class PeripheralDetailPage extends StatefulWidget {
  final String deviceId;

  PeripheralDetailPage(this.deviceId);

  @override
  State<StatefulWidget> createState() {
    return _PeripheralDetailPageState();
  }
}


class _PeripheralDetailPageState extends State<PeripheralDetailPage> {
  @override
  void initState() {
    super.initState();
    QuickBlue.setConnectionHandler(_handleConnectionChange);
    QuickBlue.setServiceHandler(_handleServiceDiscovery);
    QuickBlue.setValueHandler(_handleValueChange);
  }

  @override
  void dispose() {
    super.dispose();
    QuickBlue.setValueHandler(null);
    QuickBlue.setServiceHandler(null);
    QuickBlue.setConnectionHandler(null);
  }

  void _handleConnectionChange(String deviceId, BlueConnectionState state) {
    print('_handleConnectionChange $deviceId, $state');
  }

  void _handleServiceDiscovery(String deviceId, String serviceId, List<String> characteristicIds) {
    print('_handleServiceDiscovery $deviceId, $serviceId, $characteristicIds');
  }
var receieveValue = [];
  void _handleValueChange(String deviceId, String characteristicId, Uint8List value) {
    setState(() {
    receieveValue.add(value);
    });
    print('_handleValueChange $deviceId, $characteristicId, $value');

  }




  final serviceUUID = TextEditingController(text: bleServiceUUID);
  final characteristicUUID =
      TextEditingController(text: bleNotifyUUID);
  final binaryCode = TextEditingController(
      text: hex.encode([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PeripheralDetailPage'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('connect'),
                onPressed: () {
                  QuickBlue.connect(widget.deviceId);
                },
              ),
              RaisedButton(
                child: Text('disconnect'),
                onPressed: () {
                  QuickBlue.disconnect(widget.deviceId);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('discoverServices'),
                onPressed: () {
                  QuickBlue.discoverServices(widget.deviceId);
                },
              ),
            ],
          ),
          RaisedButton(
            child: Text('setNotifiable'),
            onPressed: () {
              var notify  = QuickBlue.setNotifiable(widget.deviceId, bleServiceUUID, bleNotifyUUID,BleInputProperty.indication);
              var value = Uint8List.fromList([0x91,0x35]);
              QuickBlue.writeValue(widget.deviceId, bleServiceUUID, bleSendUUID,value, BleOutputProperty.withResponse);

            },
          ),
          TextField(
            controller: serviceUUID,
            decoration: InputDecoration(
              labelText: 'ServiceUUID',
            ),
          ),
          TextField(
            controller: characteristicUUID,
            decoration: InputDecoration(
              labelText: 'CharacteristicUUID',
            ),
          ),
          TextField(
            controller: binaryCode,
            decoration: InputDecoration(
              labelText: 'Binary code',
            ),
          ),
          RaisedButton(
            child: Text('getLog'),
            onPressed: () {
              var value = Uint8List.fromList([0x91,0x31]);
              QuickBlue.writeValue(
                  widget.deviceId, bleServiceUUID, bleSendUUID,
                  value, BleOutputProperty.withResponse);
            },
          ),
          RaisedButton(
            child: Text('readValue battery'),
            onPressed: () async {
              await QuickBlue.readValue(
                  widget.deviceId,
                  GSS_SERV__BATTERY,
                  GSS_CHAR__BATTERY_LEVEL);
            },
          ),
          RaisedButton(
            child: Text('requestMtu'),
            onPressed: () async {
              var mtu = await QuickBlue.requestMtu(widget.deviceId, WOODEMI_MTU_WUART);
              print('requestMtu $mtu');
            },
          ),Scrollbar(
                      child: ListView.builder(
                        itemBuilder: (BuildContext context, int index) {
                          return _listItem(receieveValue[index]);
                        },
                        itemCount: receieveValue.length,
                      ),
                    ),
        ], 
      ),
    );
  }
 /*Widget _buildListView2() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title:
              Text('${receieveValue.last},${receieveValue.length}'),
          subtitle: Text("受け取ったデータ"),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount:receieveValue.length,
      ),
    );
  }*/


/// リストアイテム
  Widget _listItem(String message) {
    return Container(
      decoration: new BoxDecoration(
          border:
              new Border(bottom: BorderSide(width: 1.0, color: Colors.grey))),
      child: ListTile(
        title: Text(
          message,
          style: TextStyle(color: Colors.black, fontSize: 16.0),
        ),
      ),
    );
  }
}
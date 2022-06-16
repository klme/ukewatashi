import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'calculation.dart';
import 'home_class.dart';
import 'rive_class.dart';
import 'util/date_helper.dart';
import '../util/display_helper.dart';

/// BLE情報 加速度係数
const double bleMgLSB = 0.0039;

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

double deviceX = 0;
double deviceY = 0;
double deviceZ = 0;
double tof = 0;
double tof_latest = 0;

double headTilt = 0;
double c2c7 = 0;
double c7t3t8 = 0;
double t3t8t12 = 0;
double t8t12l3 = 0;
double t12l3s = 0;

double c2c7sva = 0;
int HP = 0;
int ToFtrust = 0;

/// 表示中のイラストイメージNo
int imageNo = 5;

final int additionValue = 1;

int messageType = 5;
var angle = [0, 0, 0];
var partScore = [0, 0, 0];
var partDamage = [0, 0, 0];

  /// RiveAnimation関連
final imageMaxCount = 13;
final riveFilePath = 'assets/rivs/shisei_0930.riv';

/// Riveファイルがロードされたか
late bool isRiveFileLoaded = false;

late Artboard artBoard;

/// Rive Animation 定数
const String StateMachine = 'State Machine Master';
const String NormalNeck = 'NormalNeck';
const String DamageNeck = 'DamageNeck';
const String NormalBack = 'NormalBack';
const String DamageBack = 'DamageBack';
const String NormalWaist = 'NormalWaist';
const String DamageWaist = 'DamageWaist';
const String NeckGlowOFF = 'NeckGlowOFF';
const String NeckGlowON = 'NeckGlowON';
const String BackGlowOFF = 'BackGlowOFF';
const String BackGlowON = 'BackGlowON';
const String WaistGlowOFF = 'WaistGlowOFF';
const String WaistGlowON = 'WaistGlowON';
const String NeckEffectOFF = 'NeckEffectOFF';
const String NeckEffectFlash = 'NeckEffectFlash';
const String BackEffectOFF = 'BackEffectOFF';
const String BackEffectFlash = 'BackEffectFlash';
const String WaistEffectOFF = 'WaistEffectOFF';
const String WaistEffectFlash = 'WaistEffectFlash';

  /// NormalMovementカスタムコントローラー
late NormalMovementController _normalMovementController;

  /// ダメージ色変更エフェクトOFFトリガー
List<SMITrigger> _damageEffectOFFTriggerList = <SMITrigger>[];

/// ダメージ色変更エフェクトONトリガー
List<SMITrigger> _damageEffectONTriggerList = <SMITrigger>[];

/// グローエフェクトONトリガー
List<SMITrigger> _glowEffectONTriggerList = <SMITrigger>[];

/// グローエフェクトOFFトリガー
List<SMITrigger> _glowEffectOFFTriggerList = <SMITrigger>[];

/// 稲妻エフェクトOFFトリガー
List<SMITrigger> _lightningEffectOFFTriggerList = <SMITrigger>[];

/// 稲妻エフェクトONトリガー
List<SMITrigger> _lightningEffectONTriggerList = <SMITrigger>[];

/// 稲妻エフェクトフラグ
List<bool> isLightningEffect = [];

/// 背骨ダメージアラートフラグ
List<bool> isAlertEffect = [];

/// 背骨ダメージエフェクトの直筋の発火時間
late int latestFireTime;

/// アニメーションを発火させるインターバル
final int animationInterval = 2;


final Calculator _calculator = new Calculator();
final Coefficients _coefficients = new Coefficients();

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
    loadRiveFile();
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
var preDataToF = [];
var preDataC2C7 = [];
  void _handleValueChange(String deviceId, String characteristicId, Uint8List value) {
    setState(() {
    deviceX = _getValue(value[3], value[4]) * bleMgLSB*(-1);
    deviceY = _getValue(value[5], value[6]) * bleMgLSB*(-1);
    deviceZ = -_getValue(value[7], value[8]) * bleMgLSB;
    tof = _getValue(value[9], value[10]);

    if(tof>=8190){
      if(ToFtrust>-5){
        ToFtrust--;
      }
    }else{
      if(ToFtrust<0){
        ToFtrust++;
      }
    }


    _calculator.run(deviceX, deviceY, deviceZ, tof, _coefficients);
    preDataToF.add(tof);
    if(preDataToF.length > 4){
      preDataToF.removeAt(0);
      tof = preDataToF.reduce((value, element) => value+element)/preDataToF.length;
    }
    
    headTilt = _calculator.headTilt;
    c2c7 = _calculator.c2c7;
    preDataC2C7.add(c2c7);
    if(preDataC2C7.length > 4 ){
      preDataC2C7.removeAt(0);
      c2c7 = preDataC2C7.reduce((value, element) => value+element)/preDataC2C7.length;
    }

    c7t3t8 = _calculator.c7t3t8;
    t3t8t12 = _calculator.t3t8t12;
    t8t12l3 = _calculator.t8t12l3;
    t12l3s = _calculator.t12l3s;
    c2c7sva = _calculator.c2c7sva;
    HP = _calculator.HP;
    angle[0] = _calculator.c2c7.round();
    angle[1] = _calculator.c7t3t8.round();
    angle[2] = _calculator.t12l3s.round();

    for (int ix = 0; ix < IllustrationKeys.tofMax.length; ix++) {
      var tofMin = IllustrationKeys.tofMin[ix];
      var tofMax = IllustrationKeys.tofMax[ix];
      var c2c7Min = IllustrationKeys.c2c7Min[ix];
      var c2c7Max = IllustrationKeys.c2c7Max[ix];
      var isTof = false;
      var isC2C7 = false;
      if (tof >= tofMin && tof < tofMax) {
        isTof = true;
      }
      if (c2c7Min == -1 && c2c7Max == -1) {
        isC2C7 = true;
      } else if (c2c7Min != -1 && c2c7Max != -1) {
        if (c2c7 >= c2c7Min && c2c7 < c2c7Max) {
          isC2C7 = true;
        }
      } else if (c2c7Min != -1) {
        if (c2c7 >= c2c7Min) {
          isC2C7 = true;
        }
      } else if (c2c7Max != -1) {
        if (c2c7 < c2c7Max) {
          isC2C7 = true;
        }
      }

      if (isTof == true && isC2C7 == true) {
        imageNo = ix + 1;
        break;
      }
    }
  var logValue = [
        deviceX.toStringAsFixed(2),
        deviceY.toStringAsFixed(2),
        deviceZ.toStringAsFixed(2),
        tof.toStringAsFixed(1),
        c2c7.toStringAsFixed(1),
        c7t3t8.toStringAsFixed(1),
        t12l3s.toStringAsFixed(1)
      ];

    // ダメージゲージ／スコア 加算計算
    if (c2c7sva <= 4) {
      partScore[0] += additionValue*15;
    } else {
      partDamage[0] += additionValue*15;
    }
    for (int i = 1; i < partScore.length; i++) {
      if (angle[i] >= DamageThreshold.safeStart[i] &&
          angle[i] <= DamageThreshold.safeEnd[i]) {
        partScore[i] += additionValue*15;
      } else {
        partDamage[i] += additionValue*15;
      }
    }

    for (int i = 0; i < partScore.length; i++) {
      if (partScore[i] < 0) {
        partScore[i] = 0;
      } else if (partScore[i] > 1000) {
        partScore[i] = 1000;
      }
      if (partDamage[i] < 0) {
        partDamage[i] = 0;
      } else if (partDamage[i] > 1000) {
        partDamage[i] = 1000;
      }
    }
    
    messageType = IllustrationKeys.type[imageNo - 1];
    if (messageType == 3) {
      /// 3の場合は出し別けなので再評価
      if (c2c7sva > IllustrationKeys.c3c7svaThreshold[0]) {
        messageType = 3;
      } else if (c2c7sva < IllustrationKeys.c3c7svaThreshold[1]) {
        messageType = 5;
      } else {
        messageType = 4;
      }
    
    }
    


    toMove(imageNo);
    //drawNeckLightningEffect(messageType);
    /*drawLightningEffect(1, angle[1]);
    drawLightningEffect(2, angle[2]);*/
    /*drawDamageAlertEffect(_coefficients.damageRate, 0);
    drawDamageAlertEffect(_coefficients.damageRate, 1);
    drawDamageAlertEffect(_coefficients.damageRate, 2);*/
    receieveValue.add(logValue);
    });
    print('_handleValueChange $deviceId, $characteristicId, $value');

  }

toMove(int index) {
    _normalMovementController.toMove(index);
}

/// アラート文言：メッセージテキストゲッター
  getMessageText() {
    var message = "";
    message = IllustrationKeys.message[messageType - 1];
    return message;
  }

  /// アラート文言：テキストカラーゲッター
  getMessageColor() {
    var color = Colors.black;
    if (messageType == 1) {
      color = Colors.red;
    } else if (messageType == 2) {
      color = Colors.orange;
    } else if (messageType == 3) {
      color = Colors.red;
    } else if (messageType == 4) {
      color = Colors.orange;
    } else if (messageType == 5) {
      color = Colors.blue;
    }else if(messageType == 6){
      color = Colors.blueGrey;
    }
    return color;
  }

  /// アラート文言：背景カラーゲッター
  getMessageBackgroundColor() {
    var color = Colors.white;
    if (messageType == 1) {
      color = Color(0xFFFFDDDD).withOpacity(0.8);
    } else if (messageType == 2) {
      color = Color(0xFFFFFFDD).withOpacity(0.8);
    } else if (messageType == 3) {
      color = Color(0xFFFFDDDD).withOpacity(0.8);
    } else if (messageType == 4) {
      color = Color(0xFFFFFFDD).withOpacity(0.8);
    } else if (messageType == 5) {
      color = Color(0xFFDDDDFF).withOpacity(0.8);
    } else if (messageType == 6) {
      color = Color(0xDDDDDDDD).withOpacity(0.8);
    }
    return color;
  }

double getDamage(int ix) {
    return partDamage[ix] / 1000;
  }

  /// ダメージゲージ背景色ゲッター
  Color getDamageGaugeBackgroundColor(double damage) {
    var color = Colors.black12;
    return color;
  }

  /// ダメージゲージ色ゲッター
  AlwaysStoppedAnimation<Color> getDamageGaugeColor(double damage) {
    int r = (damage * 255).toInt();
    int b = 255 - r;
    int g = (sin(damage * 180 * pi / 180) * 230).toInt();
    var color = Color.fromARGB(255, r, g, b);
    return AlwaysStoppedAnimation<Color>(color);
  }

  drawDamageAlertEffect(double damageRate, int index) {
    if (isAlertEffect[index] == false) {
      if (getDamage(index) > damageRate) {
        var now = DateTime.now();
        if (DateHelper.dateTimeToEpoch(now) >
            (latestFireTime + animationInterval)) {
          isAlertEffect[index] = true;
          latestFireTime = DateHelper.dateTimeToEpoch(now);
          _damageEffectONTriggerList[index].fire();
          _glowEffectONTriggerList[index].fire();
        }
      }
    }
  }

  int Efcnt = 0;
/// 首稲妻エフェクト描画
  drawNeckLightningEffect(messageType) {
    if (isLightningEffect[0] == false) {
      if (messageType == 1) {
        Efcnt++;
        if(Efcnt>60){
        _lightningEffectONTriggerList[0].fire();
        _damageEffectONTriggerList[0].fire();
        _glowEffectONTriggerList[0].fire();
        isLightningEffect[0] = true;
        }else{
          _lightningEffectOFFTriggerList[0].fire();
          _damageEffectOFFTriggerList[0].fire();
          _glowEffectOFFTriggerList[0].fire();
          isLightningEffect[0] = false;
        }
      }
    } else {
      if (messageType != 1) {
        _lightningEffectOFFTriggerList[0].fire();
        _damageEffectOFFTriggerList[0].fire();
        _glowEffectOFFTriggerList[0].fire();
        isLightningEffect[0] = false;
        Efcnt = Efcnt -10;
      }
    }
  }

 
  var Wcnt = [0,0,0];

  /// 背中、腰稲妻エフェクト描画
  void drawLightningEffect(int index, int angle) {
    if (isLightningEffect[index] == false) {
      if (!Calculation.isInSafeZoneRange(index, angle, _coefficients)) {
        Wcnt[index]++;
        if(Wcnt[index]>30){
        _lightningEffectONTriggerList[index].fire();
        _damageEffectONTriggerList[index].fire();
        _glowEffectONTriggerList[index].fire();
        isLightningEffect[index] = true;
        }
      } else {
        if(Wcnt[index]>0){
          Wcnt[index]= Wcnt[index] - 10;
        }
        
        _lightningEffectOFFTriggerList[index].fire();
        _damageEffectOFFTriggerList[index].fire();
        _glowEffectOFFTriggerList[index].fire();
      }
    } else {
      if (Calculation.isInSafeZoneRange(index, angle, _coefficients)) {
        _lightningEffectOFFTriggerList[index].fire();
        _damageEffectOFFTriggerList[index].fire();
        _glowEffectOFFTriggerList[index].fire();
        isLightningEffect[index] = false;
        Wcnt[index] = 0;
      } else {
        _lightningEffectONTriggerList[index].fire();
        _damageEffectONTriggerList[index].fire();
        _glowEffectONTriggerList[index].fire();
        
      }
    }
  }

void loadRiveFile() async {
    final bytes = await rootBundle.load(riveFilePath);
    final file = RiveFile.import(bytes);
    print("loadRive!");
    if (file != null) {
      artBoard = file.mainArtboard;

      final effectController =
          StateMachineController.fromArtboard(artBoard, StateMachine);
      artBoard.addController(effectController!);
      _normalMovementController = NormalMovementController();
      artBoard.addController(_normalMovementController);
      isLightningEffect = [false, false, false];
      isAlertEffect = [false, false, false];
      latestFireTime = DateHelper.dateTimeToEpoch(DateTime.now());
      _damageEffectOFFTriggerList = [
        effectController.findInput<bool>(NormalNeck) as SMITrigger,
        effectController.findInput<bool>(NormalBack) as SMITrigger,
        effectController.findInput<bool>(NormalWaist) as SMITrigger
      ];
      _damageEffectONTriggerList = [
        effectController.findInput<bool>(DamageNeck) as SMITrigger,
        effectController.findInput<bool>(DamageBack) as SMITrigger,
        effectController.findInput<bool>(DamageWaist) as SMITrigger
      ];
      _glowEffectOFFTriggerList = [
        effectController.findInput<bool>(NeckGlowOFF) as SMITrigger,
        effectController.findInput<bool>(BackGlowOFF) as SMITrigger,
        effectController.findInput<bool>(WaistGlowOFF) as SMITrigger
      ];
      _glowEffectONTriggerList = [
        effectController.findInput<bool>(NeckGlowON) as SMITrigger,
        effectController.findInput<bool>(BackGlowON) as SMITrigger,
        effectController.findInput<bool>(WaistGlowON) as SMITrigger
      ];
      _lightningEffectOFFTriggerList = [
        effectController.findInput<bool>(NeckEffectOFF) as SMITrigger,
        effectController.findInput<bool>(BackEffectOFF) as SMITrigger,
        effectController.findInput<bool>(WaistEffectOFF) as SMITrigger
      ];
      _lightningEffectONTriggerList = [
        effectController.findInput<bool>(NeckEffectFlash) as SMITrigger,
        effectController.findInput<bool>(BackEffectFlash) as SMITrigger,
        effectController.findInput<bool>(WaistEffectFlash) as SMITrigger
      ];
    }
    isRiveFileLoaded = true;
    debugPrint("loadRiveFileed");
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
        title: Text('測定結果'),
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
          Container(
      height: Display.getOptimizedSize(context, 280),
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children:[ 
        Container(
            width: Display.getOptimizedSize(context, 280),
            height: Display.getOptimizedSize(context, 280),
            child:isRiveFileLoaded == true
            ?Rive(artboard: artBoard,fit: BoxFit.cover,): Container(),
                ),
                ],
              ),
          ),
        _buildListView2(),
        ],
      ),
    );
  }

 Widget _buildListView2() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title:
              Text(receieveValue[index].toString()),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount:receieveValue.length,
      ),
    );
  }

 Widget _debgListView1() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title:
              Text(receieveValue[index].toString()),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount:receieveValue.length,
      ),
    );
  }

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
  double _getValue(v1, v2) {
    var v = (v1 << 8) | v2;
    var bd = ByteData(2);
    bd.setUint16(0, v);
    var f = bd.getInt16(0, Endian.big);
    return f.toDouble();
  }

}
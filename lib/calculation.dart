import 'dart:math';

class Coefficients {
  var a0 = 6.04E+01;
  var a1 = 2.34E-01;
  var a2 = -7.15E-02;
  var a3 = 1.74E+02;
  var a4 = -7.32E-04;
  var a5 = -6.20E-06;
  var b0 = 3.36E-04;
  var a6 = 1.65E+02;
  var a7 = 1.03E-03;
  var a8 = 1.14E-05;
  var b1 = -2.94E-04;
  var a9 = 1.67E+02;
  var a10 = 1.73E-03;
  var a11 = 1.75E-05;
  var b2 = -4.37E-04;
  var a12 = 1.81E+02;
  var a13 = -1.27E-03;
  var a14 = -2.35E-05;
  var b3 = 6.98E-05;
  var HP = 100;
  var height = 172.0;
  var damageRate = 0.7;
  var safeZoneStart = [0, 177, 170];
  var safeZoneEnd = [0, 180, 180];
}

/// 美姿勢メガネ 計算式クラス
///
class Calculation {
  /// 正規化
  static double _normY(double x, double y, double z) {
    double vLength = sqrt(x * x + y * y + z * z);
    double Y = y / vLength;
    return Y;
  }

  /// 頭の傾きの計算
  static double calcHeadTilt(double ax, double ay, double az) {
    var y = _normY(ax, ay, az);
    var headTilt = acos(y) * (180 / pi);
    return headTilt;
  }

  /// C2C7角の計算
  static double calcC2C7(
      double a1, double a2, double a0, double headTilt, double d) {
    var c2c7 = a1 * headTilt + a2 * d + a0;
    return c2c7;
  }

  /// 上位胸椎後弯角 C7T3T8角 の計算
  static double calcC7T3T8(
      double a3, double a4, double a5, double headTilt, double d, double b0) {
    var c7t3t8 = a4 * headTilt * headTilt + a5 * d * d + b0 * headTilt * d + a3;
    while (c7t3t8 >= 360) {
      c7t3t8 = (c7t3t8 - 360);
    }
    while (c7t3t8 <= 0) {
      c7t3t8 = c7t3t8 + 180;
    }
    if (c7t3t8 >= 180) {
      c7t3t8 = -(c7t3t8 - 180);
    }
    return c7t3t8;
  }

  /// 胸椎後弯角 T3T8T12角の計算
  static double calcT3T8T12(
      double a6, double a7, double a8, double headTilt, double d, double b1) {
    var t3t8t12 =
        a7 * headTilt * headTilt + a8 * d * d + b1 * headTilt * d + a6;
    while (t3t8t12 >= 360) {
      t3t8t12 = (t3t8t12 - 360);
    }
    while (t3t8t12 <= 0) {
      t3t8t12 = t3t8t12 + 180;
    }
    if (t3t8t12 >= 180) {
      t3t8t12 = -(t3t8t12 - 180);
    }
    return t3t8t12;
  }

  /// 腰椎前弯角 T8T12L3角の計算
  static double calcT8T12L3(
      double a9, double a10, double a11, double headTilt, double d, double b2) {
    var t8t12l3 =
        a10 * headTilt * headTilt + a11 * d * d + b2 * headTilt * d + a9;
    while (t8t12l3 >= 360) {
      t8t12l3 = (t8t12l3 - 360);
    }
    while (t8t12l3 <= 0) {
      t8t12l3 = t8t12l3 + 180;
    }
    if (t8t12l3 >= 180) {
      t8t12l3 = -(t8t12l3 - 180);
    }
    return t8t12l3;
  }

  /// T12L3S角の計算
  static double calcT12L3S(double a12, double a13, double a14, double headTilt,
      double d, double b3) {
    var t12l3s =
        a13 * headTilt * headTilt + a14 * d * d + b3 * headTilt * d + a12;
    while (t12l3s >= 360) {
      t12l3s = (t12l3s - 360);
    }
    while (t12l3s <= 0) {
      t12l3s = t12l3s + 180;
    }
    if (t12l3s >= 180) {
      t12l3s = -(t12l3s - 180);
    }
    return t12l3s;
  }

  /// neckLengthの計算
  static double calcNeckLength(double height) {
    // double neckLength = 8 + (height - 150) * (1 / 10);
    // TODO 8.5cm固定値を指定
    double neckLength = 8.5;
    return neckLength;
  }

  /// c2c7svaの計算
  static double calcC2C7SVA(double height, c2c7) {
    var c2c7sva = calcNeckLength(height) * sin(c2c7 * pi / 180);
    return c2c7sva;
  }

  /// 首（c2c7）セーフゾーン終点値のの計算
  static double calcC2C7SafeEnd(double height) {
    double value = asin(4 / calcNeckLength(height)) * 180 / pi;
    return value;
  }

  /// HP値計算
  static int calcHP(int HP, double c2c7sva) {
    if (c2c7sva >= 4.0) {
      HP--;
    }
    return HP;
  }

  // セーフゾーン内か判定
  static bool isInSafeZoneRange(
      int index, int angle, Coefficients coefficients) {
    var result;
    if (angle >= coefficients.safeZoneStart[index] &&
        angle <= coefficients.safeZoneEnd[index]) {
      result = true;
    } else {
      result = false;
    }
    return result;
  }
}

/// 美姿勢メガネ 計算実行クラス
class Calculator {
  double tof_latest = 0;

  double headTilt = 0;
  double c2c7 = 0;
  double c7t3t8 = 0;
  double t3t8t12 = 0;
  double t8t12l3 = 0;
  double t12l3s = 0;

  double c2c7sva = 0;
  double c2c7SafeEnd = 0;

  int HP = 0;

  /// 初期化処理
  void initialize(int hp) {
    HP = hp;
    print(HP);
  }

  /// 実行
  void run(x, y, z, tof, Coefficients coefficients) {
    try {
      if (tof >= 8190) {
        tof = tof_latest;
      } else {
        tof_latest = tof;
      }

      headTilt = Calculation.calcHeadTilt(x, y, z);

      c2c7 = Calculation.calcC2C7(
        coefficients.a1,
        coefficients.a2,
        coefficients.a0,
        headTilt,
        tof,
      );

      c7t3t8 = Calculation.calcC7T3T8(
        coefficients.a3,
        coefficients.a4,
        coefficients.a5,
        headTilt,
        tof,
        coefficients.b0,
      );

      t3t8t12 = Calculation.calcT3T8T12(
        coefficients.a6,
        coefficients.a7,
        coefficients.a8,
        headTilt,
        tof,
        coefficients.b1,
      );

      t8t12l3 = Calculation.calcT8T12L3(
        coefficients.a9,
        coefficients.a10,
        coefficients.a11,
        headTilt,
        tof,
        coefficients.b2,
      );

      t12l3s = Calculation.calcT12L3S(
        coefficients.a12,
        coefficients.a13,
        coefficients.a14,
        headTilt,
        tof,
        coefficients.b3,
      );

      c2c7sva = Calculation.calcC2C7SVA(
        coefficients.height,
        c2c7,
      );
      c2c7SafeEnd = Calculation.calcC2C7SafeEnd(
        coefficients.height,
      );

      HP = Calculation.calcHP(
        HP,
        c2c7sva,
      );
    } catch (e) {
      print(e);
    }
  }
}

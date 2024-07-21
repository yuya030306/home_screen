import 'package:flutter/material.dart';

class HowToUseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('このアプリの使い方'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '''アプリの概要
このアプリは、1日に何か目標を決めてその目標を達成できるようにしたい人に向けたアプリである。目標達成率を向上させ、ユーザーのQOLを上げることを目的としています。

アプリの使用方法
〇アラームの設定
１．アラーム設定画面より、翌日の起床時刻を設定してください。（アラーム設定画面にはホーム画面の「アラームを設定」ボタンをタップすることで遷移することができます。）

〇目標の設定
１．翌日、アラーム設定時刻に起床したらアプリを起動し、アラーム設定画面より目標選択画面に遷移してください。

２．目標選択画面でMyTaskから今日達成したい目標を１つ選択してください。（あとから目標を編集することはできないのでよく考えて入力しましょう。）

3．目標入力画面でその日の目標の数値（どのくらいの時間、どのくらいの数等）と、いつまでにやるかを入力し、「この内容で追加」ボタンを押します。

4．目標の設定が完了したので、目標達成に向けて精一杯取り組みましょう。
＊目標をさらに追加したい場合は、下記の手順で目標選択画面に遷移し３、４の手順で目標を追加して下さい。
ホーム画面：目標を入力ボタン→ 目標管理画面：目標を追加ボタン → 目標選択画面

〇MyTaskの設定方法
目標選択画面下部のMyTaskを編集ボタンを押します。
MyTask編集画面下部に、MyTaskに追加したい目標の内容と、それに対応する単位を入力し、MyTaskを追加ボタンを押します。

〇達成した記録を入力
1．目標の設定の手順4で設定した時刻の5分前になると通知が来ますので、5分以内に達成した記録を入力し、達成した様子を写真に収めましょう。写真の撮影は右上のカメラマークのボタンから行うことができます。

過去の記録の閲覧
1．記録した写真と数値はカレンダー画面から確認することができます。
2．記録した数値のグラフをグラフ画面で確認することができます。カテゴリごとに、週間、月間で表示できます。

〇フレンドの追加・削除・申請の承認
下記の手順でフレンド申請画面に遷移してください。
設定：「フレンド追加確認」→ フレンド一覧：フレンドを追加する → フレンド申請
2．ユーザー名を入力して、フレンド申請を送信してください。承認されるとフレンド一覧に表示されるようになります。
3．フレンド承認待ちになっているユーザーは「✓」で承認、「×」で拒否できます。
4．フレンド一覧の「×」ボタンでフレンドを削除できます。

〇フレンド内でのランキングの閲覧
ホーム画面の「ランキング」ボタンからランキング画面に遷移してください。
カテゴリーごとに月間のランキングを表示できます。過去の月のランキングも閲覧可能です。

〇プロフィールの編集
下記の手順でプロフィール編集画面に遷移してください。
設定：プロフィール → プロフィール画面：プロフィールを編集 → プロフィール編集画面
ユーザー名とアイコンを編集可能です。

〇ログアウト
設定の「ログアウト」ボタンからログアウトできます。''',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    paint.color = Colors.orange.shade200;

    path.reset();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

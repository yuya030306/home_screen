import 'package:flutter/material.dart';

class HowToUseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('このアプリの使い方'),
        backgroundColor: Colors.orange,
      ),
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16), // 上部に余白を追加してボタン全体を下にずらす
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'アプリの概要\nこのアプリは、1日に何か目標を決めてその目標を達成できるようにしたい人に向けたアプリである。目標達成率を向上させ、ユーザーのQOLを上げることを目的としています。',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildItemButton(context, 'アラームの設定', '''
アラーム設定画面より、翌日の起床時刻を設定してください。（アラーム設定画面にはホーム画面の「アラームを設定」ボタンをタップすることで遷移することができます。）
'''),
                      SizedBox(height: 16),
                      _buildItemButton(context, '目標の設定', '''
１．翌日、アラーム設定時刻に起床したらアプリを起動し、アラーム設定画面より目標選択画面に遷移してください。
２．目標選択画面でMyTaskから今日達成したい目標を１つ選択してください。（あとから目標を編集することはできないのでよく考えて入力しましょう。）
３．目標入力画面でその日の目標の数値（どのくらいの時間、どのくらいの数等）と、いつまでにやるかを入力し、「この内容で追加」ボタンを押します。
４．目標の設定が完了したので、目標達成に向けて精一杯取り組みましょう。
＊目標をさらに追加したい場合は、下記の手順で目標選択画面に遷移し３、４の手順で目標を追加して下さい。
ホーム画面：目標を入力ボタン→ 目標管理画面：目標を追加ボタン → 目標選択画面
'''),
                      SizedBox(height: 16),
                      _buildItemButton(context, '達成した記録を入力', '''
目標の設定の手順４で設定した時刻の５分前になると通知が来ますので、５分以内に達成した記録を入力し、達成した様子を写真に収めましょう。写真の撮影は右上のカメラマークのボタンから行うことができます。
'''),
                      SizedBox(height: 16),
                      _buildItemButton(context, '過去の記録の閲覧', '''
１．記録した写真と数値はカレンダー画面から確認することができます。
２．記録した数値のグラフをグラフ画面で確認することができます。カテゴリごとに、週間、月間で表示できます。
'''),
                      SizedBox(height: 16),
                      _buildItemButton(context, 'フレンドの追加・削除・申請の承認', '''
１．下記の手順でフレンド申請画面に遷移してください。
設定：「フレンド追加確認」→ フレンド一覧：フレンドを追加する → フレンド申請
２．ユーザー名を入力して、フレンド申請を送信してください。承認されるとフレンド一覧に表示されるようになります。
３．フレンド承認待ちになっているユーザーは「✓」で承認、「×」で拒否できます。
４．フレンド一覧の「×」ボタンでフレンドを削除できます。
'''),
                      SizedBox(height: 16),
                      _buildItemButton(context, 'フレンド内でのランキングの閲覧', '''
ホーム画面の「ランキング」ボタンからランキング画面に遷移してください。カテゴリーごとに月間のランキングを表示できます。過去の月のランキングも閲覧可能です。
'''),
                      SizedBox(height: 16),
                      _buildItemButton(context, 'プロフィールの編集', '''
下記の手順でプロフィール編集画面に遷移してください。
設定：プロフィール → プロフィール画面：プロフィールを編集 → プロフィール編集画面
ユーザー名とアイコンを編集可能です。
'''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemButton(
      BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _showDescriptionDialog(context, title, description);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          ),
          child: Text(title, style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  void _showDescriptionDialog(
      BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title:
              Text(title, style: TextStyle(color: Colors.orange, fontSize: 20)),
          content: SingleChildScrollView(
            child: Text(description,
                style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
          actions: [
            TextButton(
              child: Text('閉じる', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    paint.color = Colors.orange.shade200;

    path.reset();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.6, size.width, size.height * 0.5);
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

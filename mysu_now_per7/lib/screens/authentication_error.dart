class AuthenticationError {
  String loginErrorMsg(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'wrong-password':
      case 'user-not-found':
        return 'メールアドレスまたはパスワードが間違っています。';
      case 'user-disabled':
        return 'このユーザーアカウントは無効化されています。';
      case 'too-many-requests':
        return '試行回数が多すぎます。後でもう一度試してください。';
      case 'operation-not-allowed':
        return 'この操作は許可されていません。';
      case 'network-request-failed':
        return 'インターネット接続がありません。接続を確認してください。';
      default:
        return '不明なエラーが発生しました。';
    }
  }

  String registerErrorMsg(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return '有効なメールアドレスを入力してください。';
      case 'email-already-in-use':
        return '既に登録済みのメールアドレスです。';
      case 'error':
        return 'メールアドレスとパスワードを入力してください。';
      case 'network-request-failed':
        return 'インターネット接続がありません。接続を確認してください。';
      default:
        return errorCode;
    }
  }
}

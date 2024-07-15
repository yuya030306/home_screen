class AuthenticationError {
  String loginErrorMsg(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'user-not-found':
        return 'ユーザーが見つかりません。';
      case 'user-disabled':
        return 'このユーザーアカウントは無効化されています。';
      case 'too-many-requests':
        return '試行回数が多すぎます。後でもう一度試してください。';
      case 'operation-not-allowed':
        return 'この操作は許可されていません。';
      default:
        return '不明なエラーが発生しました。';
    }
  }

  String registerErrorMsg(String errorCode) {
    switch (errorCode) {
      case 'ERROR_INVALID_EMAIL':
        return '有効なメールアドレスを入力してください。';
      case 'ERROR_EMAIL_ALREADY_IN_USE':
        return '既に登録済みのメールアドレスです。';
      case 'error':
        return 'メールアドレスとパスワードを入力してください。';
      default:
        return errorCode;
    }
  }
}

class AuthenticationError {
  String loginErrorMsg(String errorCode) {
    switch (errorCode) {
      case 'ERROR_INVALID_EMAIL':
        return '有効なメールアドレスを入力してください。';
      case 'ERROR_USER_NOT_FOUND':
        return 'メールアドレスかパスワードが間違っています。';
      case 'ERROR_WRONG_PASSWORD':
        return 'メールアドレスかパスワードが間違っています。';
      case 'error':
        return 'メールアドレスとパスワードを入力してください。';
      default:
        return errorCode;
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

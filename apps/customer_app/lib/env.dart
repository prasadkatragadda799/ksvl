/// Build-time config, overridable via `--dart-define` (Vercel sets these as
/// build environment variables — see vercel.json). Defaults match the
/// ksvl-naturals Firebase project so local `flutter run` works unconfigured.
class Env {
  Env._();

  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyCiJCD3o4JTP0wQWS8h-h826YAoDh5bTiw',
  );
  static const firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:604154597035:web:6ffed3a2d690d5f780f1ee',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '604154597035',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'ksvl-naturals',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'ksvl-naturals.firebaseapp.com',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'ksvl-naturals.firebasestorage.app',
  );

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDALPvPiay0_oC5ZrGoLMncE3skEqp4g6k',
  );

  /// 2Factor.in SMS OTP key — set only via the Vercel/CI environment
  /// (never commit a real value here). Called directly from the client
  /// per an explicit call to accept that tradeoff instead of proxying
  /// through a Cloud Function.
  static const twoFactorApiKey = String.fromEnvironment('TWO_FACTOR_API_KEY');
  static const twoFactorOtpTemplate = String.fromEnvironment(
    'TWO_FACTOR_OTP_TEMPLATE',
    defaultValue: 'OTP1',
  );
}

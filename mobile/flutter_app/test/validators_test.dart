import 'package:flutter_test/flutter_test.dart';
import 'package:gozar_vpn/services/validators.dart';

void main() {
  const allowedDomain = 'persiangames.online';

  group('Validators', () {
    group('isAllowedSubscriptionUrl', () {
      test('accepts valid subscription URL from allowed domain', () {
        expect(
          Validators.isAllowedSubscriptionUrl(
            'https://persiangames.online/subscription',
            allowedDomain,
          ),
          isTrue,
        );
      });

      test('accepts http URL from allowed domain', () {
        expect(
          Validators.isAllowedSubscriptionUrl(
            'http://persiangames.online/api/v1/subscription',
            allowedDomain,
          ),
          isTrue,
        );
      });

      test('rejects URL from different domain', () {
        expect(
          Validators.isAllowedSubscriptionUrl(
            'https://example.com/subscription',
            allowedDomain,
          ),
          isFalse,
        );
      });

      test('rejects URL without scheme', () {
        expect(
          Validators.isAllowedSubscriptionUrl(
            'persiangames.online/subscription',
            allowedDomain,
          ),
          isFalse,
        );
      });

      test('rejects subdomain of allowed domain', () {
        expect(
          Validators.isAllowedSubscriptionUrl(
            'https://sub.persiangames.online/subscription',
            allowedDomain,
          ),
          isFalse,
        );
      });
    });

    group('validateLink', () {
      test('accepts vless link with allowed domain', () {
        final result = Validators.validateLink(
          'vless://uuid@persiangames.online:443?security=tls',
          allowedDomain,
        );
        expect(result.valid, isTrue);
      });

      test('accepts vless link with subdomain of allowed domain', () {
        final result = Validators.validateLink(
          'vless://uuid@server.persiangames.online:443?security=tls',
          allowedDomain,
        );
        expect(result.valid, isTrue);
      });

      test('rejects vless link with different domain', () {
        final result = Validators.validateLink(
          'vless://uuid@example.com:443?security=tls',
          allowedDomain,
        );
        expect(result.valid, isFalse);
        expect(result.message, contains('must end with'));
      });

      test('accepts trojan link with allowed domain', () {
        final result = Validators.validateLink(
          'trojan://password@persiangames.online:443?security=tls',
          allowedDomain,
        );
        expect(result.valid, isTrue);
      });

      test('rejects trojan link with different domain', () {
        final result = Validators.validateLink(
          'trojan://password@badhost.com:443',
          allowedDomain,
        );
        expect(result.valid, isFalse);
      });

      test('rejects empty link', () {
        final result = Validators.validateLink('', allowedDomain);
        expect(result.valid, isFalse);
        expect(result.message, 'Empty link');
      });

      test('rejects unsupported scheme', () {
        final result = Validators.validateLink(
          'http://persiangames.online/config',
          allowedDomain,
        );
        expect(result.valid, isFalse);
        expect(result.message, 'Unsupported scheme');
      });
    });
  });
}

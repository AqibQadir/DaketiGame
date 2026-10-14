import json
import plistlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import configure_push as setup


class PushConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.android = self.root / 'google-services.json'
        self.ios = self.root / 'GoogleService-Info.plist'
        self.android.write_text(json.dumps({
            'project_info': {'project_id': 'test-project', 'project_number': '123'},
            'client': [{'client_info': {'mobilesdk_app_id': '1:123:android:test',
                                      'android_client_info': {'package_name': 'test.app'}},
                        'api_key': [{'current_key': 'public-test-key'}]}]}))
        with self.ios.open('wb') as stream:
            plistlib.dump({'BUNDLE_ID': 'test.app', 'API_KEY': 'public-test-key',
                          'GOOGLE_APP_ID': '1:123:ios:test', 'GCM_SENDER_ID': '123',
                          'PROJECT_ID': 'test-project'}, stream)
        (self.root / 'config').mkdir()
        (self.root / 'config/providers.example.json').write_text(
            json.dumps({'FACEBOOK_ENABLED': False, 'FIREBASE_ENABLED': False}))

    def test_public_configs_extract_different_platform_app_ids(self):
        android = setup.android_config(self.android, 'test.app')
        ios = setup.ios_config(self.ios, 'test.app')
        self.assertNotEqual(android['FIREBASE_APP_ID'], ios['FIREBASE_APP_ID'])
        self.assertEqual(android['FIREBASE_PROJECT_ID'], ios['FIREBASE_PROJECT_ID'])

    def test_wrong_app_identifiers_and_server_key_are_rejected(self):
        with self.assertRaises(ValueError):
            setup.android_config(self.android, 'other.app')
        with self.assertRaises(ValueError):
            setup.ios_config(self.ios, 'other.app')
        self.android.write_text(json.dumps({'type': 'service_account', 'private_key': 'fake-test-key'}))
        with self.assertRaises(ValueError):
            setup.android_config(self.android, 'test.app')

    def test_generated_configs_enable_firebase_and_refuse_overwrite(self):
        with patch.object(setup, 'ROOT', self.root), patch.object(setup, 'app_identifiers', return_value=('test.app', 'test.app')):
            setup.configure(self.android, self.ios)
            destination = self.root / 'config/providers.android.local.json'
            config = json.loads(destination.read_text())
            self.assertTrue(config['FIREBASE_ENABLED'])
            self.assertFalse(config['FACEBOOK_ENABLED'])
            self.assertEqual(destination.stat().st_mode & 0o777, 0o600)
            before = destination.read_text()
            with self.assertRaises(ValueError):
                setup.configure(self.android, self.ios)
            self.assertEqual(destination.read_text(), before)

    def test_mismatched_projects_write_nothing(self):
        with self.ios.open('rb') as stream:
            data = plistlib.load(stream)
        data['PROJECT_ID'] = 'other-project'
        with self.ios.open('wb') as stream:
            plistlib.dump(data, stream)
        with patch.object(setup, 'ROOT', self.root), patch.object(setup, 'app_identifiers', return_value=('test.app', 'test.app')):
            with self.assertRaises(ValueError):
                setup.configure(self.android, self.ios)
        self.assertEqual(list((self.root / 'config').glob('*.local.json')), [])


if __name__ == '__main__':
    unittest.main()

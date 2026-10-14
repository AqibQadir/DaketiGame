#!/usr/bin/env python3
"""Import public Firebase app configuration without copying server credentials."""
import argparse
import json
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def required(data, key):
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f'Missing Firebase configuration field: {key}')
    return value.strip()


def android_config(path, package):
    data = json.loads(Path(path).read_text())
    if 'private_key' in data or data.get('type') == 'service_account':
        raise ValueError('Use google-services.json, not a service-account key.')
    clients = [c for c in data.get('client', [])
               if c.get('client_info', {}).get('android_client_info', {}).get('package_name') == package]
    if len(clients) != 1:
        raise ValueError(f'Expected one Firebase Android client for {package}.')
    client = clients[0]
    keys = client.get('api_key', [])
    if not keys:
        raise ValueError('Missing Android Firebase API key.')
    info = data.get('project_info', {})
    return {
        'FIREBASE_API_KEY': required(keys[0], 'current_key'),
        'FIREBASE_APP_ID': required(client['client_info'], 'mobilesdk_app_id'),
        'FIREBASE_SENDER_ID': required(info, 'project_number'),
        'FIREBASE_PROJECT_ID': required(info, 'project_id'),
    }


def ios_config(path, bundle):
    with Path(path).open('rb') as stream:
        data = plistlib.load(stream)
    if required(data, 'BUNDLE_ID') != bundle:
        raise ValueError(f'Firebase iOS bundle must match {bundle}.')
    return {
        'FIREBASE_API_KEY': required(data, 'API_KEY'),
        'FIREBASE_APP_ID': required(data, 'GOOGLE_APP_ID'),
        'FIREBASE_SENDER_ID': required(data, 'GCM_SENDER_ID'),
        'FIREBASE_PROJECT_ID': required(data, 'PROJECT_ID'),
        'FIREBASE_IOS_BUNDLE_ID': bundle,
    }


def app_identifiers():
    gradle = (ROOT / 'android/app/build.gradle.kts').read_text()
    project = (ROOT / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
    package = re.search(r'applicationId\s*=\s*"([^"]+)"', gradle)
    bundles = set(re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', project))
    bundles = {b for b in bundles if not b.endswith('.RunnerTests')}
    if package is None or len(bundles) != 1:
        raise ValueError('Cannot determine unique app identifiers from the project.')
    return package.group(1), bundles.pop()


def configure(android=None, ios=None, force=False):
    if not android and not ios:
        raise ValueError('Supply --android and/or --ios with the Firebase client file paths.')
    package, bundle = app_identifiers()
    configs = {}
    if android:
        configs['android'] = android_config(android, package)
    if ios:
        configs['ios'] = ios_config(ios, bundle)
    if len(configs) == 2:
        for key in ('FIREBASE_PROJECT_ID', 'FIREBASE_SENDER_ID'):
            if configs['android'][key] != configs['ios'][key]:
                raise ValueError('Android and iOS must use the same Firebase project.')
    outputs = {platform: ROOT / f'config/providers.{platform}.local.json' for platform in configs}
    # Validate all inputs and destinations before writing any configuration.
    if not force and any(path.exists() for path in outputs.values()):
        raise ValueError('A platform configuration already exists. Use --force to replace it.')
    base = json.loads((ROOT / 'config/providers.example.json').read_text())
    for platform, values in configs.items():
        values = {**base, **values, 'FIREBASE_ENABLED': True}
        outputs[platform].write_text(json.dumps(values, indent=2) + '\n')
        outputs[platform].chmod(0o600)
        print(f'Created {outputs[platform].relative_to(ROOT)}')
        print(f'Run: flutter run --dart-define-from-file=config/providers.{platform}.local.json -d <device-id>')
    print('Client setup prepared. Backend FCM credentials, iOS APNs setup, and device delivery tests are still required.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--android', help='Path to Firebase google-services.json')
    parser.add_argument('--ios', help='Path to Firebase GoogleService-Info.plist')
    parser.add_argument('--force', action='store_true', help='Replace existing generated platform configurations')
    args = parser.parse_args()
    try:
        configure(args.android, args.ios, args.force)
    except (ValueError, OSError, KeyError, TypeError, plistlib.InvalidFileException):
        # Do not echo source content or parser errors that might contain keys.
        parser.exit(1, 'Firebase setup failed. Check client file format, app identifiers, matching projects, and existing output files. No server credentials should be used.\n')


if __name__ == '__main__':
    main()

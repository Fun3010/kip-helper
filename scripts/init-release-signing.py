"""Create the project's permanent signing key once. Never print passwords.

Usage: python scripts/init-release-signing.py --jdk <JDK directory>
Back up .private/ and android/key.properties outside the project afterwards.
"""
import argparse
import os
from pathlib import Path
import secrets
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--jdk', required=True, type=Path)
args = parser.parse_args()
keytool = args.jdk / 'bin' / ('keytool.exe' if os.name == 'nt' else 'keytool')
private = root / '.private'
keystore = private / 'kip-helper-release.jks'
properties = root / 'android/key.properties'
if not keytool.is_file():
    raise SystemExit('JDK keytool not found.')
if keystore.exists() or properties.exists():
    raise SystemExit('Signing files already exist; refusing to replace a permanent key.')

def restrict(path, directory=False):
    if os.name == 'nt':
        identity = subprocess.check_output(['whoami'], text=True).strip()
        access = f'{identity}:(OI)(CI)F' if directory else f'{identity}:F'
        subprocess.run(['icacls', str(path), '/inheritance:r', '/grant:r', access],
                       check=True, stdout=subprocess.DEVNULL)
    else:
        path.chmod(0o700 if directory else 0o600)

private.mkdir(exist_ok=True)
restrict(private, directory=True)
password = secrets.token_urlsafe(36)
env = os.environ.copy()
env['KIP_RELEASE_PASSWORD'] = password
subprocess.run([
    str(keytool), '-genkeypair', '-noprompt', '-keystore', str(keystore),
    '-storetype', 'JKS', '-alias', 'kip-helper-release', '-keyalg', 'RSA',
    '-keysize', '3072', '-validity', '10000', '-dname', 'CN=KIP Helper',
    '-storepass:env', 'KIP_RELEASE_PASSWORD', '-keypass:env', 'KIP_RELEASE_PASSWORD',
], env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
restrict(keystore)
with properties.open('x', encoding='ascii') as target:
    target.write('storeFile=../.private/kip-helper-release.jks\n'
                 'keyAlias=kip-helper-release\n'
                 f'storePassword={password}\nkeyPassword={password}\n')
restrict(properties)
subprocess.run([
    str(keytool), '-exportcert', '-rfc', '-keystore', str(keystore),
    '-alias', 'kip-helper-release', '-storepass:env', 'KIP_RELEASE_PASSWORD',
    '-file', str(root / 'docs/release-certificate.pem'),
], env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print('Permanent signing key created. Passwords were not printed.')
print('Back up .private/kip-helper-release.jks and android/key.properties securely.')
print('docs/release-certificate.pem is the public certificate, not the private key.')
